class_name AuthoredWorld
extends Node3D
## AuthoredWorld: assembles the playable level from Blender-exported
## environments, one zone at a time (data/zones.json), wired up by the
## chapter's world file (ContentRegistry.get_world()).
##
## On _ready it builds the chapter's start zone and creates the
## "PlayerSpawn" Marker3D that Main uses. ZoneDirector builds and frees
## other zones later. Building a zone:
##   1. instances every environment .glb of the zone under "Zone_<id>"
##      (shared frame, at the origin),
##   2. turns LIGHTMARK_* markers into downward SpotLight3Ds (hints in extras),
##   3. adds ImportedDoor controllers to door roots (extras.category == "door"),
##   4. adds ImportedInteractable controllers to the configured prop nodes,
##   5. spawns WardCharacters at their MARK_* markers,
##   6. applies WorldStateManager states to state-tagged nodes.
## World file entries belong to the start zone unless they name a "zone".
## Anything the config names but the zone lacks is collected in
## `unresolved` and reported, so content errors are visible, not silent.

const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")
const LIGHT_ENERGY: float = 2.2
const LIGHT_ANGLE_DEG: float = 80.0
const ZONE_ROOT_PREFIX: String = "Zone_"

var unresolved: Array[String] = []
var start_zone_id: String = ""
var chapter_id: String = ""

var _config: Dictionary = {}
var _zone_roots: Dictionary[String, Node3D] = {}
var _doors: Dictionary[String, ImportedDoor] = {}
var _interactables: Dictionary[String, ImportedInteractable] = {}
var _characters: Dictionary[String, WardCharacter] = {}
var _state_nodes: Array[Node3D] = []
var _lights: Array[Light3D] = []


func _ready() -> void:
	if not ContentRegistry.is_valid:
		return
	configure_chapter(ContentRegistry.get_start_chapter_id())
	EventBus.environment_state_changed.connect(func(_g: String, _s: String) -> void: _apply_states())
	EventBus.game_loaded.connect(func(_slot: int) -> void: _apply_states())


## Loads a zone's environment scenes on the calling thread. ZoneDirector
## streams them on a worker thread instead when it has time to.
static func load_zone_scenes(zone_id: String) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for path: String in ContentRegistry.get_zone(zone_id).get("environments", []):
		scenes.append(load(path) as PackedScene)
	return scenes


## Instances a zone from its loaded scenes (in zones.json order) and wires
## the chapter's doors, props and characters that live in it.
func build_zone(zone_id: String, scenes: Array[PackedScene]) -> Node3D:
	if _zone_roots.has(zone_id):
		return _zone_roots[zone_id]
	var root: Node3D = Node3D.new()
	root.name = ZONE_ROOT_PREFIX + zone_id
	add_child(root)
	_zone_roots[zone_id] = root
	var paths: Array = ContentRegistry.get_zone(zone_id).get("environments", [])
	for i: int in scenes.size():
		if scenes[i] == null:
			_report("environment " + str(paths[i] if i < paths.size() else i))
			continue
		root.add_child(scenes[i].instantiate())
	_build_lights(root, _config.get("flicker_lights", []))
	_build_doors(root, zone_id, _config.get("doors", {}))
	_build_interactables(zone_id, _config.get("interactables", []))
	_build_characters(root, zone_id, _config.get("characters", []))
	_collect_state_nodes(root)
	_apply_states()
	return root


## Frees a zone and forgets every controller in it. The caller saves its
## persistent state first (ZoneDirector does).
func unload_zone(zone_id: String) -> void:
	var root: Node3D = _zone_roots.get(zone_id, null)
	if root == null:
		return
	_zone_roots.erase(zone_id)
	for door_id: String in _doors.keys():
		if root.is_ancestor_of(_doors[door_id]):
			_doors.erase(door_id)
	for node_name: String in _interactables.keys():
		if root.is_ancestor_of(_interactables[node_name]):
			_interactables.erase(node_name)
	for character_id: String in _characters.keys():
		if root.is_ancestor_of(_characters[character_id]):
			_characters.erase(character_id)
	_state_nodes = _state_nodes.filter(func(n: Node3D) -> bool: return not root.is_ancestor_of(n))
	_lights = _lights.filter(func(l: Light3D) -> bool: return not root.is_ancestor_of(l))
	remove_child(root)
	root.queue_free()


# --- Queries (used by ZoneDirector, tests and story scripting) -------------------

func has_zone(zone_id: String) -> bool:
	return _zone_roots.has(zone_id)


## Zones currently built, sorted.
func get_zone_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_zone_roots.keys())
	ids.sort()
	return ids


func get_zone_root(zone_id: String) -> Node3D:
	return _zone_roots.get(zone_id, null)


## Saveable objects (doors) inside one built zone.
func get_persistent_nodes(zone_id: String) -> Array[Node]:
	var root: Node3D = _zone_roots.get(zone_id, null)
	var nodes: Array[Node] = []
	if root != null:
		for node: Node in get_tree().get_nodes_in_group("persistent_world"):
			if root.is_ancestor_of(node):
				nodes.append(node)
	return nodes


func get_door(door_id: String) -> ImportedDoor:
	return _doors.get(door_id, null)


func get_interactable(node_name: String) -> ImportedInteractable:
	return _interactables.get(node_name, null)


func get_character(character_id: String) -> WardCharacter:
	return _characters.get(character_id, null)


func get_lights() -> Array[Light3D]:
	return _lights


func find_world_node(node_name: String) -> Node3D:
	return find_child(node_name, true, false) as Node3D


func find_zone_node(zone_id: String, node_name: String) -> Node3D:
	var root: Node3D = _zone_roots.get(zone_id, null)
	return root.find_child(node_name, true, false) as Node3D if root != null else null


# --- Builders -------------------------------------------------------------------

func _belongs_to(entry: Dictionary, zone_id: String) -> bool:
	return str(entry.get("zone", start_zone_id)) == zone_id


func _report(item: String) -> void:
	unresolved.append(item)
	push_error("AuthoredWorld: unresolved %s" % item)


func _build_lights(root: Node3D, flicker_names: Array) -> void:
	for marker: Node in root.find_children("LIGHTMARK_*", "", true, false):
		var extras: Dictionary = marker.get_meta("extras", {})
		var light: Light3D = FlickerLight.new() if marker.name in flicker_names else SpotLight3D.new()
		if light is FlickerLight:
			(light as FlickerLight).base_energy = LIGHT_ENERGY * 0.8
			(light as FlickerLight).omni_range = float(extras.get("range_m", 6.0))
		else:
			var spot: SpotLight3D = light
			spot.spot_range = float(extras.get("range_m", 6.0))
			spot.spot_angle = LIGHT_ANGLE_DEG
			spot.spot_attenuation = 0.8
			spot.rotation_degrees.x = -90.0  # Point down.
			spot.light_energy = LIGHT_ENERGY * float(extras.get("energy_hint", 1.0))
		light.name = "Light"
		light.light_color = Color.html(str(extras.get("color", "#FFF4E5")))
		light.shadow_enabled = true
		light.shadow_bias = 0.06
		light.shadow_normal_bias = 1.5
		marker.add_child(light)
		_lights.append(light)


func _build_doors(root: Node3D, zone_id: String, door_config: Dictionary) -> void:
	var found: Dictionary = {}
	for node: Node in root.find_children("Door_*", "Node3D", true, false):
		var extras: Dictionary = node.get_meta("extras", {})
		if extras.get("category", "") != "door":
			continue
		var door_id: String = str(extras.get("door_id", ""))
		var controller: ImportedDoor = ImportedDoor.new()
		controller.name = "DoorController"
		node.add_child(controller)
		controller.setup(node, door_config.get(door_id, {}))
		_doors[controller.door_id] = controller
		found[controller.door_id] = true
	for door_id: String in door_config:
		if _belongs_to(door_config[door_id], zone_id) and not found.has(door_id):
			_report("door " + door_id)


func _build_interactables(zone_id: String, entries: Array) -> void:
	for entry: Dictionary in entries:
		if not _belongs_to(entry, zone_id):
			continue
		var target: Node3D = find_zone_node(zone_id, entry["node"])
		if target == null:
			_report("interactable node " + str(entry["node"]))
			continue
		var controller: ImportedInteractable = ImportedInteractable.new()
		controller.name = "InteractableController"
		target.add_child(controller)
		controller.setup(target, entry)
		_interactables[target.name] = controller


func _build_characters(root: Node3D, zone_id: String, entries: Array) -> void:
	for entry: Dictionary in entries:
		if not _belongs_to(entry, zone_id):
			continue
		var marker: Node3D = find_zone_node(zone_id, entry["marker"])
		if marker == null:
			_report("character marker " + str(entry["marker"]))
			continue
		var character: WardCharacter = CHARACTER_SCENE.instantiate()
		character.kind = WardCharacter.Kind.STAFF if entry["kind"] == "staff" else WardCharacter.Kind.PATIENT
		character.character_id = entry["character_id"]
		character.seated = bool(entry.get("seated", false))
		character.name = "Character_" + str(entry["character_id"])
		root.add_child(character)
		var xf: Transform3D = marker.global_transform
		# Seat markers sit at seat height; characters stand on the floor plane.
		character.global_transform = Transform3D(xf.basis.orthonormalized(), Vector3(xf.origin.x, 0.0, xf.origin.z))
		_characters[character.character_id] = character


## The spawn marker is copied to a node of the world itself, so it survives
## the start zone being unloaded and rebuilt.
func _build_spawn(zone_id: String, marker_name: String) -> void:
	var marker: Node3D = find_zone_node(zone_id, marker_name)
	var spawn: Marker3D = Marker3D.new()
	spawn.name = "PlayerSpawn"
	add_child(spawn)
	if marker == null:
		_report("spawn marker " + marker_name)
		return
	spawn.global_transform = marker.global_transform


func _collect_state_nodes(root: Node3D) -> void:
	for node: Node in root.find_children("*", "Node3D", true, false):
		var extras: Dictionary = node.get_meta("extras", {})
		if extras.has("state_group"):
			_state_nodes.append(node)


func _apply_states() -> void:
	for node: Node3D in _state_nodes:
		var extras: Dictionary = node.get_meta("extras", {})
		node.visible = WorldStateManager.is_node_visible(str(extras["state_group"]), str(extras.get("state", "")),
				bool(extras.get("default_visible", true)))


## Reuses the authored ward assets with the selected chapter's interaction wiring.
## The world provider calls this before zones restore their saved door state.
func configure_chapter(next_chapter: String) -> bool:
	var config: Dictionary = ContentRegistry.get_world(next_chapter)
	if config.is_empty() or chapter_id == next_chapter:
		return false
	for zone_id: String in get_zone_ids():
		unload_zone(zone_id)
	var spawn: Node = get_node_or_null("PlayerSpawn")
	if spawn != null:
		remove_child(spawn)
		spawn.queue_free()
	unresolved.clear()
	chapter_id = next_chapter
	_config = config
	start_zone_id = _config["start_zone"]
	build_zone(start_zone_id, load_zone_scenes(start_zone_id))
	_build_spawn(start_zone_id, _config["spawn_marker"])
	return true
