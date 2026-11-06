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


func test_historic_dressing_follows_zone_lifecycle_without_revealing_it() -> void:
	await runner.get_tree().process_frame
	var world: AuthoredWorld = _main.get_node("World")
	var zones: ZoneDirector = _main.get_node("ZoneDirector")
	var zone_id: String = "zone_historic_sublevel"
	check(not world.has_zone(zone_id), "historic dressing does not preload another floor")
	var before: Dictionary = SaveManager.capture_state()
	var root: Node3D = world.build_zone(zone_id, AuthoredWorld.load_zone_scenes(zone_id))
	var holder: Node = root.get_node_or_null("SetDressing")
	check(holder != null, "historic dressing is attached when the zone is built")
	if holder == null:
		return
	var expected: int = SetDressing.entries(zone_id).size()
	check(expected > 0, "the historic floor has authored dressing")
	check_eq(holder.get_child_count(), expected, "every historic prop is placed once")
	world.build_zone(zone_id, AuthoredWorld.load_zone_scenes(zone_id))
	check_eq(root.find_children("SetDressing", "Node3D", false, false).size(), 1, "repeated build does not stack props")
	var active_zone: String = zones.current_zone_id
	zones.current_zone_id = zone_id
	var plan: Dictionary = FloorPlan.snapshot(world, _main.get_node("Player"), zones)
	zones.current_zone_id = active_zone
	for prop: Node3D in holder.get_children():
		var at: Vector3 = prop.global_position
		check(not FloorPlan.room_at(plan["floors"], Vector2(at.x, at.z)).is_empty(), "%s stays inside the historic floor" % prop.name)
		check(prop.find_children("*", "Interactable", true, false).is_empty(), "%s is decorative" % prop.name)
		check(prop.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s adds no collision" % prop.name)
		for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
			var bounds: AABB = mesh.global_transform * mesh.get_aabb()
			check(bounds.position.y > 0.5 and bounds.end.y < 3.0, "%s keeps clear of floor and ceiling" % prop.name)
		for door: Dictionary in plan["doors"]:
			check(Vector2(at.x, at.z).distance_to(door["position"]) >= 0.6, "%s keeps clear of %s" % [prop.name, door["label"]])
	var after: Dictionary = SaveManager.capture_state()
	# Loading geometry legitimately adds default door snapshots to the zone cache.
	before.erase("zones")
	after.erase("zones")
	check_eq(after, before, "building historic dressing changes no progression or care state")
	check_eq(zones.current_zone_id, active_zone, "reviewing geometry does not change the player's floor")
	var current_plan: Dictionary = FloorPlan.snapshot(world, _main.get_node("Player"), zones)
	check_eq(current_plan["zone_id"], active_zone, "the current map remains on the player's floor")
	world.unload_zone(zone_id)
	check(not world.has_zone(zone_id), "historic props unload with their zone")
	root = world.build_zone(zone_id, AuthoredWorld.load_zone_scenes(zone_id))
	check_eq(root.get_node("SetDressing").get_child_count(), expected, "streaming back restores one copy of each prop")
