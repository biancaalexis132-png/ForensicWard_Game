class_name RoomSounds
extends Node
## Positional room sound: fixtures hum overhead and workstations whir where they
## stand, so ordinary hospital spaces have a directional baseline that the bed
## ambience alone cannot give. Settings in data/room_sounds.json.
##
## Sources are found in the loaded world (ceiling lights and EHR workstations);
## only the max_active nearest within each cue's range play, and they fade in and
## out as the player moves. In silent_locations (the historical wing and Ward Zero)
## every source fades out: the hum stopping is part of what changes there.
## Each source keeps its own pitch and loop position, so neighbours never phase.
##
## Cosmetic only. Headless runs (tests, CI) choose sources but play nothing, like
## AudioZoneTracker: there is no audio device, and a stream left playing at quit
## is reported as a leak.

const DATA_PATH: String = "res://data/room_sounds.json"
const CUES_PATH: String = "res://audio/cues.json"
const SILENT_DB: float = -60.0

var target: Node3D = null
var world: AuthoredWorld = null
var drive_audio: bool = DisplayServer.get_name() != "headless"
## Overrides AudioDirector's location (tests).
var location_override: String = ""

var _settings: Dictionary = {}
var _cues: Dictionary = {}
var _elapsed: float = 0.0
## Source key -> {"player": AudioStreamPlayer3D or null, "kind": String, "position": Vector3}
var _active: Dictionary = {}


func _ready() -> void:
	_settings = load_settings()
	var cues: Variant = JSON.parse_string(FileAccess.get_file_as_string(CUES_PATH))
	_cues = cues.get("cues", {}) if cues is Dictionary else {}


static func load_settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return parsed if parsed is Dictionary else {}


## Problems with data/room_sounds.json ([] when valid).
static func validate() -> Array[String]:
	var problems: Array[String] = []
	var settings: Dictionary = load_settings()
	var cues: Variant = JSON.parse_string(FileAccess.get_file_as_string(CUES_PATH))
	var known: Dictionary = cues.get("cues", {}) if cues is Dictionary else {}
	if not settings.get("sources") is Dictionary or settings["sources"].is_empty():
		return ["[room_sounds.json] needs a sources object."]
	if int(settings.get("max_active", 0)) < 1 or int(settings.get("max_active", 0)) > 16:
		problems.append("[room_sounds.json] max_active must be 1 to 16 (each source is a playing stream).")
	for kind: String in settings["sources"]:
		if not kind in ["ceiling_light", "workstation"]:
			problems.append("[room_sounds.json] sources.%s: unknown kind (ceiling_light, workstation)." % kind)
		var cue_id: String = str(settings["sources"][kind].get("cue", ""))
		if not known.has(cue_id):
			problems.append("[room_sounds.json] sources.%s: unknown cue '%s'." % [kind, cue_id])
		elif not bool(known[cue_id].get("loop", false)) or not known[cue_id].has("max_distance"):
			problems.append("[room_sounds.json] sources.%s: cue '%s' must loop and set max_distance." % [kind, cue_id])
	return problems


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= float(_settings.get("update_seconds", 0.5)):
		_elapsed = 0.0
		update_now()


## The sources that should play now: [{key, kind, position}], nearest first.
func wanted_sources() -> Array[Dictionary]:
	var chosen: Array[Dictionary] = []
	if target == null or not is_instance_valid(target) or world == null or not is_instance_valid(world):
		return chosen
	var location: String = location_override if not location_override.is_empty() else AudioDirector.get_location()
	if location in _settings.get("silent_locations", []):
		return chosen
	var here: Vector3 = target.global_position
	var candidates: Array[Dictionary] = []
	var sources: Dictionary = _settings.get("sources", {})
	if sources.has("ceiling_light"):
		var reach: float = _range("ceiling_light")
		for light: Light3D in world.get_lights():
			if is_instance_valid(light) and light.is_inside_tree() and light.is_visible_in_tree() and light.light_energy > 0.0:
				_consider(candidates, "ceiling_light", light, here, reach)
	if sources.has("workstation"):
		var reach: float = _range("workstation")
		for node: Node in world.find_children("*", "ImportedInteractable", true, false):
			var interactable: ImportedInteractable = node as ImportedInteractable
			if interactable != null and interactable.kind == "ehr_terminal" and interactable.is_inside_tree():
				_consider(candidates, "workstation", interactable.get_parent() as Node3D, here, reach)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["distance"] < b["distance"])
	for candidate: Dictionary in candidates.slice(0, int(_settings.get("max_active", 8))):
		chosen.append(candidate)
	return chosen


func update_now() -> void:
	var wanted: Array[Dictionary] = wanted_sources()
	var keep: Dictionary = {}
	for source: Dictionary in wanted:
		keep[source["key"]] = true
		if not _active.has(source["key"]):
			_active[source["key"]] = {"kind": source["kind"], "position": source["position"], "player": _start(source)}
	for key: String in _active.keys():
		if not keep.has(key):
			_stop(_active[key]["player"])
			_active.erase(key)


func get_active_keys() -> Array:
	return _active.keys()


func stop_all() -> void:
	for key: String in _active.keys():
		var player: AudioStreamPlayer3D = _active[key]["player"]
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_active.clear()


func _exit_tree() -> void:
	stop_all()


func _range(kind: String) -> float:
	var cue_id: String = str(_settings["sources"][kind].get("cue", ""))
	return float(_cues.get(cue_id, {}).get("max_distance", 5.0))


func _consider(candidates: Array[Dictionary], kind: String, node: Node3D, here: Vector3, reach: float) -> void:
	if node == null:
		return
	var position: Vector3 = node.global_position
	var distance: float = position.distance_to(here)
	if distance <= reach:
		candidates.append({"key": "%s:%s" % [kind, node.get_path()], "kind": kind, "position": position, "distance": distance})


func _start(source: Dictionary) -> AudioStreamPlayer3D:
	if not drive_audio:
		return null
	var config: Dictionary = _settings["sources"][source["kind"]]
	var cue: Dictionary = _cues.get(str(config["cue"]), {})
	var stream: AudioStream = load(str(cue.get("stream", ""))) as AudioStream
	if stream == null:
		return null
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.name = "RoomSound"
	player.stream = stream
	player.bus = str(cue.get("bus", "SFX"))
	player.max_distance = float(cue.get("max_distance", 5.0))
	player.unit_size = float(cue.get("unit_size", 1.0))
	player.attenuation_filter_cutoff_hz = 5000.0
	# Seeded by the source, so a fixture always sounds the same.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(source["key"])
	var spread: float = float(config.get("pitch_spread", 0.0))
	player.pitch_scale = 1.0 + rng.randf_range(-spread, spread)
	player.volume_db = SILENT_DB
	add_child(player)
	player.global_position = source["position"]
	player.play(rng.randf_range(0.0, maxf(stream.get_length() - 0.1, 0.0)))
	var tween: Tween = player.create_tween()
	tween.tween_property(player, "volume_db", float(config.get("volume_db", -18.0)), float(_settings.get("fade_seconds", 1.2)))
	return player


func _stop(player: AudioStreamPlayer3D) -> void:
	if not is_instance_valid(player):
		return
	var tween: Tween = player.create_tween()
	tween.tween_property(player, "volume_db", SILENT_DB, float(_settings.get("fade_seconds", 1.2)))
	tween.tween_callback(player.stop)
	tween.tween_callback(player.queue_free)
