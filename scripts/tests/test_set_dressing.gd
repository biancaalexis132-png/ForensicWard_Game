extends TestCase
## Set dressing: the clinical corridor gets its wall-mounted detail, nothing
## lands in a doorway or on the floor where people walk, and it changes no state.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"

var _main: Main


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	AudioDirector.cancel_pending_events()
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func test_data_is_valid() -> void:
	check_eq(SetDressing.validate(), [] as Array[String], "set_dressing.json is valid")


func test_corridor_is_dressed_without_blocking_anything() -> void:
	await runner.get_tree().process_frame
	var before: Dictionary = SaveManager.capture_state()
	var world: AuthoredWorld = _main.get_node("World")
	var root: Node3D = world.get_zone_root("zone_clinical_wing")
	var holder: Node = root.get_node_or_null("SetDressing")
	check(holder != null, "the clinical wing has set dressing")
	var expected: int = SetDressing.entries("zone_clinical_wing").size()
	check_eq(holder.get_child_count() if holder != null else 0, expected, "every listed prop is placed")
	var plan: Dictionary = FloorPlan.snapshot(world, _main.get_node("Player"), _main.get_node("ZoneDirector"))
	for prop: Node in (holder.get_children() if holder != null else []):
		var at: Vector3 = (prop as Node3D).global_position
		check(at.y > 1.0, "%s is off the floor (y %.2f)" % [prop.name, at.y])
		check(not FloorPlan.room_at(plan["floors"], Vector2(at.x, at.z)).is_empty(), "%s is inside the wing" % prop.name)
		check(prop.find_children("*", "Interactable", true, false).is_empty(), "%s is not interactive" % prop.name)
		for door: Dictionary in plan["doors"]:
			var near: bool = Vector2(at.x, at.z).distance_to(door["position"]) < 0.6
			check(not near, "%s keeps clear of %s" % [prop.name, door["label"]])
	check_eq(SaveManager.capture_state(), before, "dressing changes no game state")
