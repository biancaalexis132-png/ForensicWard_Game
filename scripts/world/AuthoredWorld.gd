class_name AuthoredWorld
extends Node3D
## AuthoredWorld: assembles a playable level from Blender-exported
## environments, wired up by a data file (ContentRegistry.get_world()).
##
## On _ready it:
##   1. instances every environment .glb at the origin (shared frame),
##   2. turns LIGHTMARK_* markers into downward SpotLight3Ds (hints in extras),
##   3. adds ImportedDoor controllers to door roots (extras.category == "door"),
##   4. adds ImportedInteractable controllers to the configured prop nodes,
##   5. spawns WardCharacters at their MARK_* markers,
##   6. applies WorldStateManager states to state-tagged nodes,
##   7. creates the "PlayerSpawn" Marker3D that Main uses.
## Anything the config names but the environments lack is collected in
## `unresolved` and reported, so content errors are visible, not silent.

const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")
const LIGHT_ENERGY: float = 2.2
const LIGHT_ANGLE_DEG: float = 80.0

var unresolved: Array[String] = []

var _doors: Dictionary[String, ImportedDoor] = {}
var _interactables: Dictionary[String, ImportedInteractable] = {}
var _characters: Dictionary[String, WardCharacter] = {}
var _state_nodes: Array[Node3D] = []
var _lights: Array[Light3D] = []


func _ready() -> void:
	if not ContentRegistry.is_valid:
		return
	var config: Dictionary = ContentRegistry.get_world()
	for path: String in config["environments"]:
		var packed: PackedScene = load(path)
		if packed == null:
			unresolved.append("environment " + path)
			continue
		add_child(packed.instantiate())
	_build_lights(config.get("flicker_lights", []))
	_build_doors(config["doors"])
	_build_interactables(config["interactables"])
	_build_characters(config["characters"])
	_collect_state_nodes()
	_build_spawn(config["spawn_marker"])
	EventBus.environment_state_changed.connect(func(_g: String, _s: String) -> void: _apply_states())
	EventBus.game_loaded.connect(func(_slot: int) -> void: _apply_states())
	_apply_states()
	for item: String in unresolved:
		push_error("AuthoredWorld: unresolved %s" % item)


# --- Queries (used by tests and story scripting) -------------------------------

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


# --- Builders -------------------------------------------------------------------

func _build_lights(flicker_names: Array) -> void:
	for marker: Node in find_children("LIGHTMARK_*", "", true, false):
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


func _build_doors(door_config: Dictionary) -> void:
	for node: Node in find_children("Door_*", "Node3D", true, false):
		var extras: Dictionary = node.get_meta("extras", {})
		if extras.get("category", "") != "door":
			continue
		var door_id: String = str(extras.get("door_id", ""))
		var controller: ImportedDoor = ImportedDoor.new()
		controller.name = "DoorController"
		node.add_child(controller)
		controller.setup(node, door_config.get(door_id, {}))
		_doors[controller.door_id] = controller
	for door_id: String in door_config:
		if not _doors.has(door_id):
			unresolved.append("door " + door_id)


func _build_interactables(entries: Array) -> void:
	for entry: Dictionary in entries:
		var target: Node3D = find_world_node(entry["node"])
		if target == null:
			unresolved.append("interactable node " + str(entry["node"]))
			continue
		var controller: ImportedInteractable = ImportedInteractable.new()
		controller.name = "InteractableController"
		target.add_child(controller)
		controller.setup(target, entry)
		_interactables[target.name] = controller


func _build_characters(entries: Array) -> void:
	for entry: Dictionary in entries:
		var marker: Node3D = find_world_node(entry["marker"])
		if marker == null:
			unresolved.append("character marker " + str(entry["marker"]))
			continue
		var character: WardCharacter = CHARACTER_SCENE.instantiate()
		character.kind = WardCharacter.Kind.STAFF if entry["kind"] == "staff" else WardCharacter.Kind.PATIENT
		character.character_id = entry["character_id"]
		character.seated = bool(entry.get("seated", false))
		character.name = "Character_" + str(entry["character_id"])
		add_child(character)
		var xf: Transform3D = marker.global_transform
		# Seat markers sit at seat height; characters stand on the floor plane.
		character.global_transform = Transform3D(xf.basis.orthonormalized(), Vector3(xf.origin.x, 0.0, xf.origin.z))
		_characters[character.character_id] = character


func _build_spawn(marker_name: String) -> void:
	var marker: Node3D = find_world_node(marker_name)
	var spawn: Marker3D = Marker3D.new()
	spawn.name = "PlayerSpawn"
	add_child(spawn)
	if marker == null:
		unresolved.append("spawn marker " + marker_name)
		return
	spawn.global_transform = marker.global_transform


func _collect_state_nodes() -> void:
	for node: Node in find_children("*", "Node3D", true, false):
		var extras: Dictionary = node.get_meta("extras", {})
		if extras.has("state_group"):
			_state_nodes.append(node)


func _apply_states() -> void:
	for node: Node3D in _state_nodes:
		var extras: Dictionary = node.get_meta("extras", {})
		node.visible = WorldStateManager.is_node_visible(str(extras["state_group"]), str(extras.get("state", "")),
				bool(extras.get("default_visible", true)))
