class_name FloorPlan
extends RefCounted
## Read-only projection of the current loaded zone. Never loads or reveals another floor.

## With a director, "objective" says where the current objective is: {"label",
## "position", "room"} when it is on this floor, {"label", "elsewhere": true}
## when it is not, and {} when the objective names no place.
static func snapshot(world: AuthoredWorld, player: Node3D, zones: ZoneDirector, director: ChapterDirector = null) -> Dictionary:
	var zone_id: String = zones.current_zone_id
	var zone: Dictionary = ContentRegistry.get_zone(zone_id)
	var result: Dictionary = {"zone_id": zone_id, "title": zone.get("title", ""),
			"level": zone.get("level", ""), "floors": [], "doors": [], "stations": [],
			"player": Vector2(player.global_position.x, player.global_position.z), "yaw": player.global_rotation.y,
			"people": [], "here": "", "objective": {}}
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
					"label": environment.scene_file_path.get_file().get_basename().trim_prefix("ENV_").trim_suffix("_20m").to_snake_case().capitalize()})
	for object: Node in world.get_persistent_nodes(zone_id):
		if object is ImportedDoor:
			var door_root: Node3D = object.get_parent() as Node3D
			result["doors"].append({"position": Vector2(door_root.global_position.x, door_root.global_position.z),
					"label": object.display_name, "locked": object.is_locked(), "open": object.is_open})
	for station: Node in root.find_children("*", "Node3D", true, false):
		if "Terminal_EHR" in str(station.name):
			result["stations"].append(Vector2(station.global_position.x, station.global_position.z))
	result["here"] = room_at(result["floors"], result["player"])
	# Staff and story patients standing in this floor's rooms (ward-round
	# patients are many and stay in their rooms, so they are left off).
	var ids: Array[String] = ContentRegistry.get_staff_ids()
	ids.append_array(ContentRegistry.get_patient_ids())
	for character_id: String in ids:
		var actor: WardCharacter = world.get_character(character_id)
		if actor == null or not actor.is_visible_in_tree():
			continue
		var at: Vector2 = Vector2(actor.global_position.x, actor.global_position.z)
		var room: String = room_at(result["floors"], at)
		if room.is_empty():
			continue
		var data: Dictionary = ContentRegistry.get_staff(character_id)
		if data.is_empty():
			data = ContentRegistry.get_patient(character_id)
		result["people"].append({"id": character_id, "name": str(data.get("name", character_id)), "position": at, "room": room})
	result["objective"] = _objective(world, root, result, director)
	return result


static func _objective(world: AuthoredWorld, root: Node3D, plan: Dictionary, director: ChapterDirector) -> Dictionary:
	var label: String = CaseFile.objective_place(director)
	var target: Dictionary = CaseFile.objective_target(director)
	if label.is_empty() or target.is_empty():
		return {}
	var points: Array[Vector2] = []
	if target.has("character"):
		for person: Dictionary in plan["people"]:
			if person["id"] == target["character"]:
				points.append(person["position"])
	elif target.has("node"):
		var controller: ImportedInteractable = world.get_interactable(str(target["node"]))
		if controller != null and root.is_ancestor_of(controller):
			var prop: Node3D = controller.get_parent() as Node3D
			points.append(Vector2(prop.global_position.x, prop.global_position.z))
	elif target.has("type"):
		for controller: Node in root.find_children("InteractableController", "ImportedInteractable", true, false):
			if (controller as ImportedInteractable).kind == target["type"]:
				var prop: Node3D = controller.get_parent() as Node3D
				points.append(Vector2(prop.global_position.x, prop.global_position.z))
	elif target.has("zone") and target["zone"] == plan["zone_id"]:
		return {"label": label, "here": true}
	if points.is_empty():
		return {"label": label, "elsewhere": true}
	var nearest: Vector2 = points[0]
	for point: Vector2 in points:
		if point.distance_to(plan["player"]) < nearest.distance_to(plan["player"]):
			nearest = point
	return {"label": label, "position": nearest, "room": room_at(plan["floors"], nearest)}


## The smallest room containing the point ("" when none does): rooms off a
## corridor overlap its bounds, and the room is the more useful answer.
static func room_at(floors: Array, point: Vector2) -> String:
	var best: String = ""
	var best_area: float = INF
	for floor: Dictionary in floors:
		var rect: Rect2 = floor["rect"]
		if rect.grow(0.05).has_point(point) and rect.get_area() < best_area:
			best = floor["label"]
			best_area = rect.get_area()
	return best
