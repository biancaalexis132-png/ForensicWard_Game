class_name ZoneDirector
extends Node
## ZoneDirector: which zones of the hospital are loaded, and moving the
## player between them (data/zones.json, F0 audit section 6).
##
## Only the current zone and the same-level neighbours it needs are built,
## so zones on another level (whose floor plans overlap this one) are never
## loaded at the same time:
##   seamless  Same level, joined by a door. The zone behind the door is
##             streamed on a worker thread when the player is near a door
##             they may open, or the door is open; the zone that holds the
##             door is always loaded with its neighbour. Walking across the
##             zone bounds changes the current zone with no fade.
##   fade      Lift or hatch between levels. Fade out, pause the clock, free
##             every loaded zone, build the target (streamed while fading),
##             place the player on the arrival, fade in.
## Access comes from TrustManager access grants (the door's own
## required_access, or the connection's), never from trust values.
##
## Doors keep their state when their zone is freed: ZoneDirector holds
## zone id -> {persist id -> state} and gives it back when the zone is
## built again. Saved as the "zones" provider.
##
## With the "perf_log" setting on, memory and frame figures are written to
## user://perf_log.csv before and after every transition.

signal transition_finished()

const SAVE_KEY: String = "zones"
const GROUP: String = "zone_director"
const TIME_PAUSE_REASON: String = "zone_transition"
const CHECK_SECONDS: float = 0.25
## Metres from a seamless connection's anchor at which the zone behind it starts streaming.
const PRELOAD_RADIUS: float = 10.0
const PERF_LOG_PATH: String = "user://perf_log.csv"

## Each half of a fade transition. Tests set 0.
var fade_seconds: float = 0.35
## Stream environments on a worker thread. Off in headless runs (tests, CI):
## Godot's dummy renderer does not create meshes thread-safely, so there the
## same queue is loaded on the main thread instead.
var stream_on_threads: bool = DisplayServer.get_name() != "headless"
var current_zone_id: String = ""
var in_transition: bool = false

var _world: AuthoredWorld = null
var _player: FirstPersonController = null
var _objects: Dictionary = {}  ## zone id -> {persist id -> state}, as last captured
var _loading: Dictionary = {}  ## zone id -> environment paths streaming on a worker thread
var _elapsed: float = 0.0
var _fade: ColorRect = null


## Called by Main once the world has built its start zone.
func setup(world: AuthoredWorld, player: FirstPersonController) -> void:
	add_to_group(GROUP)
	_world = world
	_player = player
	current_zone_id = world.start_zone_id
	_build_fade_overlay()
	SaveManager.register_provider(SAVE_KEY, self)
	if _world.has_zone(current_zone_id):
		_wire_zone(current_zone_id)


func _exit_tree() -> void:
	SaveManager.unregister_provider(SAVE_KEY)
	# Collect any worker-thread loads so none outlives the scene; nothing new is loaded.
	for paths: Array in _loading.values():
		for path: String in paths:
			if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				ResourceLoader.load_threaded_get(path)
	_loading.clear()


func _process(delta: float) -> void:
	if _world == null or in_transition:
		return
	_elapsed += delta
	if _elapsed >= CHECK_SECONDS:
		_elapsed = 0.0
		update_now()


## Tracks the current zone from the player's position, streams the
## neighbours it needs and builds those that finished loading.
func update_now() -> void:
	if _world == null or in_transition:
		return
	var here: String = zone_at(_player.global_position)
	if not here.is_empty() and here != current_zone_id:
		var previous: String = current_zone_id
		current_zone_id = here
		EventBus.zone_changed.emit(current_zone_id, previous)
	for zone_id: String in required_zones():
		if not _world.has_zone(zone_id):
			_request(zone_id)
	_poll_streaming()


# --- Queries --------------------------------------------------------------------

## The loaded zone whose bounds contain `position`, on the current level.
## The current zone wins on a shared edge. "" when outside every zone.
func zone_at(position: Vector3) -> String:
	var level: String = _level(current_zone_id)
	var candidates: Array[String] = [current_zone_id]
	candidates.append_array(_world.get_zone_ids())
	for zone_id: String in candidates:
		if _world.has_zone(zone_id) and _level(zone_id) == level and _contains(ContentRegistry.get_zone(zone_id), position):
			return zone_id
	return ""


## The current zone plus the same-level neighbours it needs right now.
func required_zones() -> Array[String]:
	var zones: Array[String] = [current_zone_id]
	for connection: Dictionary in ContentRegistry.get_connections_of(current_zone_id):
		if connection["transition"] != "seamless":
			continue
		var other: String = _other_end(connection, current_zone_id)["zone"]
		if ContentRegistry.get_zone(other)["status"] != "built" or other in zones:
			continue
		if connection["door_zone"] == other or _door_needs_neighbour(connection):
			zones.append(other)
	return zones


func get_loaded_zone_ids() -> Array[String]:
	return _world.get_zone_ids()


## True while a zone is streaming on a worker thread.
func is_streaming(zone_id: String) -> bool:
	return _loading.has(zone_id)


## Saved door state of a zone, live if it is loaded.
func get_zone_objects(zone_id: String) -> Dictionary:
	if _world.has_zone(zone_id):
		_capture(zone_id)
	return _objects.get(zone_id, {}).duplicate(true)


# --- Transitions ----------------------------------------------------------------

## Uses a fade connection from the current zone. Returns false (and shows
## the locked message) when it cannot be used; otherwise the transition runs
## and `transition_finished` follows.
## `from_zone` is the zone whose end the player used (default: the current zone).
func use_connection(connection_id: String, from_zone: String = "") -> bool:
	var connection: Dictionary = ContentRegistry.get_connection(connection_id)
	if connection.is_empty() or in_transition or connection["transition"] != "fade":
		return false
	var arrival_end: Dictionary = _other_end(connection, current_zone_id if from_zone.is_empty() else from_zone)
	if arrival_end.is_empty():
		return false
	if not TrustManager.has_access(str(connection.get("required_access", ""))):
		EventBus.notification_requested.emit(str(connection.get("locked_message", "Locked.")))
		return false
	if ContentRegistry.get_zone(arrival_end["zone"])["status"] != "built":
		EventBus.notification_requested.emit("%s: not accessible." % ContentRegistry.get_zone(arrival_end["zone"])["title"])
		return false
	_run_fade(connection, arrival_end)
	return true


func _run_fade(connection: Dictionary, arrival_end: Dictionary) -> void:
	in_transition = true
	_log_performance("before", connection["id"])
	TimeManager.push_pause(TIME_PAUSE_REASON)
	_player.set_input_enabled(false)
	var previous: String = current_zone_id
	var target: String = arrival_end["zone"]
	var needed: Array[String] = [target]
	for connection_of_target: Dictionary in ContentRegistry.get_connections_of(target):
		if connection_of_target["transition"] == "seamless" and connection_of_target["door_zone"] != target:
			needed.append(connection_of_target["door_zone"])
	for zone_id: String in needed:
		_request(zone_id)
	await _fade_to(1.0)
	# Never two levels at once: free everything before building the target.
	for zone_id: String in _world.get_zone_ids():
		_unload(zone_id)
	for zone_id: String in needed:
		while _streaming_status(zone_id) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
	current_zone_id = target
	for zone_id: String in needed:
		_build_now(zone_id)
	var arrival: Dictionary = arrival_end["arrival"]
	var position: Array = arrival["position"]
	_player.place(Vector3(position[0], position[1], position[2]), deg_to_rad(float(arrival.get("yaw_degrees", 0.0))))
	for zone_id: String in required_zones():
		_build_now(zone_id)
	EventBus.zone_changed.emit(current_zone_id, previous)
	await _fade_to(0.0)
	TimeManager.pop_pause(TIME_PAUSE_REASON)
	in_transition = false
	_log_performance("after", connection["id"])
	transition_finished.emit()


func _fade_to(alpha: float) -> void:
	if fade_seconds <= 0.0:
		_fade.modulate.a = alpha
		return
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, fade_seconds)
	await tween.finished


func _build_fade_overlay() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = 50
	add_child(layer)
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


# --- Building and freeing zones -------------------------------------------------

func _request(zone_id: String) -> void:
	if _loading.has(zone_id) or _world.has_zone(zone_id):
		return
	var paths: Array[String] = []
	for path: String in ContentRegistry.get_zone(zone_id)["environments"]:
		paths.append(path)
		if stream_on_threads and ResourceLoader.load_threaded_request(path) != OK:
			push_warning("ZoneDirector: cannot stream %s; it will load on the main thread" % path)
	_loading[zone_id] = paths


func _streaming_status(zone_id: String) -> int:
	for path: String in _loading.get(zone_id, []):
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return ResourceLoader.THREAD_LOAD_IN_PROGRESS
	return ResourceLoader.THREAD_LOAD_LOADED


## Builds the zones that finished streaming and are still needed.
func _poll_streaming() -> void:
	var needed: Array[String] = required_zones()
	for zone_id: String in _loading.keys():
		if _streaming_status(zone_id) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var scenes: Array[PackedScene] = _take_streamed(zone_id)
			if zone_id in needed and not _world.has_zone(zone_id):
				_build(zone_id, scenes)


## Collects a zone's streamed scenes (blocking if still loading) and forgets the request.
func _take_streamed(zone_id: String) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for path: String in _loading.get(zone_id, []):
		var status: int = ResourceLoader.load_threaded_get_status(path)
		var scene: PackedScene = null
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			scene = ResourceLoader.load_threaded_get(path) as PackedScene
		scenes.append(scene if scene != null else load(path) as PackedScene)
	_loading.erase(zone_id)
	return scenes


## Builds a zone now, from its stream if one is running.
func _build_now(zone_id: String) -> void:
	if _world.has_zone(zone_id):
		return
	var scenes: Array[PackedScene] = _take_streamed(zone_id) if _loading.has(zone_id) \
			else AuthoredWorld.load_zone_scenes(zone_id)
	_build(zone_id, scenes)


func _build(zone_id: String, scenes: Array[PackedScene]) -> void:
	_world.build_zone(zone_id, scenes)
	_apply_objects(zone_id)
	_wire_zone(zone_id)


func _unload(zone_id: String) -> void:
	_capture(zone_id)
	_world.unload_zone(zone_id)


func _capture(zone_id: String) -> void:
	var states: Dictionary = {}
	for node: Node in _world.get_persistent_nodes(zone_id):
		states[node.get_persist_id()] = node.to_save_data()
	_objects[zone_id] = states


func _apply_objects(zone_id: String) -> void:
	var states: Dictionary = _objects.get(zone_id, {})
	for node: Node in _world.get_persistent_nodes(zone_id):
		node.load_save_data(states.get(node.get_persist_id(), {}))


## Lift and hatch nodes become usable; connection doors load the zone behind them before opening.
func _wire_zone(zone_id: String) -> void:
	for connection: Dictionary in ContentRegistry.get_connections_of(zone_id):
		if connection["transition"] == "seamless":
			if connection["door_zone"] == zone_id and _world.get_door(connection["door_id"]) != null:
				var other: String = _other_end(connection, zone_id)["zone"]
				_world.get_door(connection["door_id"]).before_open = _build_now.bind(other)
			continue
		for end: Dictionary in connection["ends"]:
			if end["zone"] == zone_id:
				_add_connection_point(zone_id, connection, end)


func _add_connection_point(zone_id: String, connection: Dictionary, end: Dictionary) -> void:
	var target: Node3D = _world.find_zone_node(zone_id, end["node"])
	if target == null:
		_world.unresolved.append("connection node " + str(end["node"]))
		push_error("ZoneDirector: %s has no node %s in %s" % [connection["id"], end["node"], zone_id])
		return
	var interactable: Interactable = Interactable.new()
	interactable.name = "ConnectionPoint"
	interactable.interactable_id = connection["id"]
	var prompt: String = str(end.get("prompt", "Use " + str(end["node"])))
	var access: String = str(connection.get("required_access", ""))
	interactable.prompt_provider = func() -> String:
		return prompt + ("" if TrustManager.has_access(access) else " (locked)")
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	var aabb: AABB = ImportedInteractable.mesh_aabb(target)
	box.size = Vector3(maxf(aabb.size.x + 0.12, 0.3), maxf(aabb.size.y + 0.12, 0.3), maxf(aabb.size.z + 0.12, 0.3))
	shape.shape = box
	shape.position = aabb.get_center()
	interactable.add_child(shape)
	target.add_child(interactable)
	var connection_id: String = connection["id"]
	interactable.interacted.connect(func(_interactor: Node) -> void: use_connection(connection_id, zone_id))


# --- Helpers --------------------------------------------------------------------

## A seamless connection's door is in the current zone: the zone behind is
## needed when the door is open, or when the player may open it and is near.
func _door_needs_neighbour(connection: Dictionary) -> bool:
	var door: ImportedDoor = _world.get_door(connection["door_id"])
	if door == null:
		return false
	if door.is_open:
		return true
	var anchor: Array = connection["anchor_xz"]
	var p: Vector3 = _player.global_position
	return not door.is_locked() and Vector2(p.x, p.z).distance_to(Vector2(anchor[0], anchor[1])) <= PRELOAD_RADIUS


func _other_end(connection: Dictionary, zone_id: String) -> Dictionary:
	var ends: Array = connection["ends"]
	if ends[0]["zone"] == zone_id:
		return ends[1]
	if ends[1]["zone"] == zone_id:
		return ends[0]
	return {}


func _level(zone_id: String) -> String:
	return str(ContentRegistry.get_zone(zone_id).get("level", ""))


static func _contains(zone: Dictionary, position: Vector3) -> bool:
	for rect: Dictionary in zone.get("bounds", []):
		if position.x >= rect["min_xz"][0] and position.x <= rect["max_xz"][0] \
				and position.z >= rect["min_xz"][1] and position.z <= rect["max_xz"][1]:
			return true
	return false


## Memory and frame figures; written to PERF_LOG_PATH when the setting is on.
func sample_performance() -> Dictionary:
	return {
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"objects_in_frame": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"frame_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
	}


func _log_performance(label: String, connection_id: String) -> void:
	if not Settings.get_value("perf_log"):
		return
	var exists: bool = FileAccess.file_exists(PERF_LOG_PATH)
	var file: FileAccess = FileAccess.open(PERF_LOG_PATH, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	var sample: Dictionary = sample_performance()
	if not exists:
		file.store_line("unix_time,label,connection,zone," + ",".join(sample.keys()))
	var values: PackedStringArray = [str(Time.get_unix_time_from_system()), label, connection_id, current_zone_id]
	for key: String in sample:
		values.append(str(sample[key]))
	file.store_line(",".join(values))


# --- Save provider ("zones") ------------------------------------------------------

func to_save_data() -> Dictionary:
	for zone_id: String in _world.get_zone_ids():
		_capture(zone_id)
	return {"current": current_zone_id, "objects": _objects.duplicate(true)}


## Runs after the "world" provider has placed the player (providers load in
## key order), so the neighbours it needs are worked out from there. Loading
## builds what the save needs directly; it never plays a transition.
func load_save_data(data: Dictionary) -> void:
	_objects = data.get("objects", {}).duplicate(true)
	var target: String = str(data.get("current", ""))
	if ContentRegistry.get_zone(target).get("status", "") != "built":
		target = _world.start_zone_id
	_enter_directly(target)


func reset_state() -> void:
	_objects = {}
	_enter_directly(_world.start_zone_id)


func _enter_directly(target: String) -> void:
	var previous: String = current_zone_id
	for zone_id: String in _world.get_zone_ids():
		if _level(zone_id) != _level(target):
			_world.unload_zone(zone_id)
	current_zone_id = target
	for zone_id: String in _world.get_zone_ids():
		_apply_objects(zone_id)
	# The current zone first: its doors decide which neighbours are needed.
	_build_now(current_zone_id)
	for zone_id: String in required_zones():
		_build_now(zone_id)
	if previous != current_zone_id:
		EventBus.zone_changed.emit(current_zone_id, previous)
