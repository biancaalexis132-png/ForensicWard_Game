class_name CampusBackdrop
extends Node3D
## Ground-level exterior only. No new story access, zone or clinical effects.
var _campus: Node3D
var _sun: DirectionalLight3D

func _ready() -> void:
	_campus = load("res://assets/exports/exterior/ENV_CampusGrounds.glb").instantiate()
	add_child(_campus)
	for node: Node in _campus.find_children("*", "GeometryInstance3D", true, false):
		node.layers = 2
		node.visibility_range_end = 130.0
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-35, -25, 0)
	_sun.light_cull_mask = 2
	_sun.shadow_enabled = false
	add_child(_sun)
	EventBus.zone_changed.connect(_update)
	EventBus.shift_changed.connect(_update)
	_update()

func _update(_first: Variant = null, _second: Variant = null) -> void:
	var director: ZoneDirector = get_tree().get_first_node_in_group(ZoneDirector.GROUP) as ZoneDirector
	var ground: bool = director != null and ContentRegistry.get_zone(director.current_zone_id).get("level") == "ground"
	visible = ground
	for shape: Node in _campus.find_children("*", "CollisionShape3D", true, false):
		shape.set_deferred("disabled", not ground)
	_sun.light_energy = 0.55 if TimeManager.get_shift() == "day" else 0.035
