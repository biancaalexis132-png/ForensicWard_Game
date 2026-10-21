class_name ImportedDoor
extends Node
## ImportedDoor: gameplay controller for a door imported from Blender.
##
## Added as a child of an imported door root (e.g. "Door_Archive"), whose
## glTF extras carry door_id and required_access. Every child node with
## "_Leaf" in its name is a leaf whose origin is the hinge: opening rotates it
## about Y. Each leaf gets an Interactable sized to its mesh. The leaf's
## imported "-colonly" StaticBody3D is its child, so collision follows the
## swing. Open/closed state is saved through Main's "persistent_world" group.

var door_id: String = ""
var display_name: String = "Door"
var required_access: String = ""
var locked_message: String = "Locked."
var open_angle_degrees: float = 100.0
## Room name on the plaques above a configured door, "" for none. Defaults to
## the display name without "door"; a chapter's "sign" overrides it.
var sign_text: String = ""
var swing_seconds: float = 0.6
var is_open: bool = false
## Optional Callable run just before the player opens the door. ZoneDirector
## sets it on connection doors so the zone behind is loaded first.
var before_open: Callable = Callable()

var _leaves: Array[Node3D] = []
var _closed_rotations: Array[float] = []
var _tweens: Array[Tween] = []


## Configures from the door root's extras plus world config. Call after adding to the tree.
func setup(door_root: Node3D, config: Dictionary) -> void:
	var extras: Dictionary = door_root.get_meta("extras", {})
	door_id = str(extras.get("door_id", door_root.name.to_snake_case()))
	required_access = str(extras.get("required_access", ""))
	# Doors the chapter does not configure read "Records Office door", not "Door_RecordsOffice".
	display_name = str(config.get("display_name", door_root.name.trim_prefix("Door_").capitalize() + " door"))
	locked_message = str(config.get("locked_message", "%s: locked." % display_name))
	open_angle_degrees = float(config.get("open_angle_degrees", 100.0))
	for child: Node in door_root.get_children():
		if child is Node3D and "_Leaf" in child.name and not child.name.ends_with("_COL"):
			_add_leaf(child)
	if _leaves.is_empty():
		push_warning("ImportedDoor %s: no leaf nodes found" % door_root.name)
	elif not config.is_empty():
		sign_text = str(config.get("sign", default_sign(display_name)))
		if not sign_text.is_empty():
			_add_signs(door_root)
	add_to_group("persistent_world")


## "Records archive door" -> "Records Archive"; "Ward entry doors" -> "Ward Entry".
static func default_sign(name: String) -> String:
	var words: PackedStringArray = name.split(" ", false)
	if not words.is_empty() and words[-1].to_lower() in ["door", "doors"]:
		words.remove_at(words.size() - 1)
	var titled: PackedStringArray = []
	for word: String in words:
		titled.append(word if word == word.to_upper() else word.capitalize())
	return " ".join(titled)


## A plaque on each face of the door, centred just above the frame.
func _add_signs(door_root: Node3D) -> void:
	var bounds: AABB = AABB()
	for index: int in _leaves.size():
		var leaf: Node3D = _leaves[index]
		var local: AABB = (leaf as MeshInstance3D).get_aabb() if leaf is MeshInstance3D else AABB(Vector3(0, 0, -0.03), Vector3(1, 2.1, 0.06))
		var placed: AABB = leaf.transform * local
		bounds = placed if index == 0 else bounds.merge(placed)
	# The door faces along its thinner horizontal axis.
	var normal: Vector3 = Vector3.FORWARD if bounds.size.z <= bounds.size.x else Vector3.RIGHT
	var depth: float = minf(bounds.size.z, bounds.size.x)
	var top: Vector3 = bounds.get_center() + Vector3(0.0, bounds.size.y * 0.5 + SIGN_GAP_METERS, 0.0)
	for side: float in [1.0, -1.0]:
		var plaque: Node3D = _make_plaque()
		plaque.name = "Sign" if side > 0.0 else "SignBack"
		door_root.add_child(plaque)
		plaque.position = top + normal * side * (depth * 0.5 + 0.03)
		plaque.look_at(door_root.to_global(plaque.position + normal * side), Vector3.UP)
		plaque.rotate_object_local(Vector3.UP, PI) # Label3D faces +Z.


const SIGN_GAP_METERS: float = 0.12
const SIGN_HEIGHT_METERS: float = 0.16


func _make_plaque() -> Node3D:
	var plaque: Node3D = Node3D.new()
	var label: Label3D = Label3D.new()
	label.name = "Label"
	label.text = sign_text
	label.font_size = 56
	label.pixel_size = 0.0022
	label.outline_size = 0
	label.modulate = Color(0.95, 0.95, 0.92)
	label.double_sided = false
	label.position.z = 0.006
	plaque.add_child(label)
	var plate: MeshInstance3D = MeshInstance3D.new()
	plate.name = "Plate"
	var box: BoxMesh = BoxMesh.new()
	var width: float = maxf(0.4, sign_text.length() * 0.075 + 0.12)
	box.size = Vector3(width, SIGN_HEIGHT_METERS, 0.01)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.13, 0.22, 0.32)
	material.roughness = 0.6
	box.material = material
	plate.mesh = box
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plaque.add_child(plate)
	return plaque


func _add_leaf(leaf: Node3D) -> void:
	_leaves.append(leaf)
	_closed_rotations.append(leaf.rotation.y)
	_tweens.append(null)
	var interactable: Interactable = Interactable.new()
	interactable.name = "Interactable"
	interactable.interactable_id = door_id
	interactable.prompt_provider = get_prompt
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	var aabb: AABB = (leaf as MeshInstance3D).get_aabb() if leaf is MeshInstance3D else AABB(Vector3(0, 0, -0.03), Vector3(1, 2.1, 0.06))
	box.size = Vector3(aabb.size.x, aabb.size.y, maxf(aabb.size.z, 0.06) + 0.3)
	shape.shape = box
	shape.position = aabb.get_center()
	interactable.add_child(shape)
	leaf.add_child(interactable)
	interactable.interacted.connect(_on_interacted)


func is_locked() -> bool:
	return not TrustManager.has_access(required_access)


func get_prompt() -> String:
	if is_locked():
		return "%s (locked)" % display_name
	return ("Close " if is_open else "Open ") + display_name.to_lower()


func get_persist_id() -> String:
	return "door:" + door_id


func to_save_data() -> Dictionary:
	return {"open": is_open}


func load_save_data(data: Dictionary) -> void:
	set_open(bool(data.get("open", false)), false)


func set_open(open: bool, animate: bool) -> void:
	is_open = open
	# Double doors: the right leaf mirrors the left.
	for i: int in _leaves.size():
		var direction: float = -1.0 if _leaves[i].name.ends_with("_R") else 1.0
		var target: float = _closed_rotations[i] + (deg_to_rad(open_angle_degrees) * direction if open else 0.0)
		if _tweens[i] != null and _tweens[i].is_valid():
			_tweens[i].kill()
		if animate and not Settings.get_value("reduce_motion"):
			_tweens[i] = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_tweens[i].tween_property(_leaves[i], "rotation:y", target, swing_seconds)
		else:
			_leaves[i].rotation.y = target


func get_leaves() -> Array[Node3D]:
	return _leaves


func _on_interacted(_interactor: Node) -> void:
	if is_locked():
		EventBus.notification_requested.emit(locked_message)
		return
	if not is_open and before_open.is_valid():
		before_open.call()
	set_open(not is_open, true)
