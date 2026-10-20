class_name FloorPlan
extends RefCounted
## Read-only projection of the current loaded zone. Never loads or reveals another floor.

static func snapshot(world: AuthoredWorld, player: Node3D, zones: ZoneDirector) -> Dictionary:
	var zone_id: String = zones.current_zone_id
	var zone: Dictionary = ContentRegistry.get_zone(zone_id)
	var result: Dictionary = {"zone_id": zone_id, "title": zone.get("title", ""),
			"level": zone.get("level", ""), "floors": [], "doors": [], "stations": [],
			"player": Vector2(player.global_position.x, player.global_position.z), "yaw": player.global_rotation.y}
	var root: Node3D = world.get_zone_root(zone_id)
	if root == null:
		return result
	for environment: Node in root.get_children():
		if not environment is Node3D or environment.scene_file_path.is_empty():
			continue
		var room_bounds: Rect2 = Rect2()
		var found: bool = false
		for mesh: Node in environment.find_children("*", "MeshInstance3D", true, false):
			if not ("floor" in str(mesh.name).to_lower() or "_Architecture" in str(mesh.name)) or "ceiling" in str(mesh.name).to_lower():
				continue
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			var rect: Rect2 = Rect2(Vector2(box.position.x, box.position.z), Vector2(box.size.x, box.size.z))
			if rect.size.x < 0.1 or rect.size.y < 0.1:
				continue
			room_bounds = room_bounds.merge(rect) if found else rect
			found = true
		if found:
			result["floors"].append({"rect": room_bounds,
					"label": environment.scene_file_path.get_file().get_basename().trim_prefix("ENV_").to_snake_case().capitalize()})
	for object: Node in world.get_persistent_nodes(zone_id):
		if object is ImportedDoor:
			var door_root: Node3D = object.get_parent() as Node3D
			result["doors"].append({"position": Vector2(door_root.global_position.x, door_root.global_position.z),
					"label": object.display_name, "locked": object.is_locked(), "open": object.is_open})
	for station: Node in root.find_children("*", "Node3D", true, false):
		if "Terminal_EHR" in str(station.name):
			result["stations"].append(Vector2(station.global_position.x, station.global_position.z))
	return result
