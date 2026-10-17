extends TestCase
## Integration tests against the real Main scene with the Blender-built
## Chapter 1 ward (AuthoredWorld): movement, collision, interaction ray,
## imported doors and access, props, characters, lights, environment states
## and world save/load. Blender (x, y, z) maps to Godot (x, z, -y).

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"

var _main: Node3D = null


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	super.after_each()
	if is_instance_valid(_main):
		Input.action_release("move_forward")
		_main.free()
	runner.get_tree().paused = false


func test_world_assembles_without_unresolved_content() -> void:
	await wait_physics_frames(2)
	check(_world().unresolved.is_empty(), "every configured node exists: %s" % str(_world().unresolved))
	check(_player().input_enabled, "player has control after boot")
	check(not _info_panel().is_open, "no blocking error panel")
	var spawn: Vector3 = _player().global_position
	check(spawn.distance_to(Vector3(0.0, 0.0, -1.6)) < 0.2, "player spawns at MARK_PlayerSpawn, got %s" % spawn)


func test_lights_are_built_from_markers() -> void:
	var lights: Array[Light3D] = _world().get_lights()
	check(lights.size() >= 15, "at least 15 lights from LIGHTMARK markers, got %d" % lights.size())
	check(lights.all(func(l: Light3D) -> bool: return l.shadow_enabled), "all lights cast shadows")
	check(lights.any(func(l: Light3D) -> bool: return l is FlickerLight), "W0-B end of the corridor flickers")


func test_walks_forward_down_the_corridor() -> void:
	await wait_physics_frames(5)
	var start: Vector3 = _player().global_position
	Input.action_press("move_forward")
	await wait_physics_frames(60)
	Input.action_release("move_forward")
	var moved: Vector3 = _player().global_position - start
	check(moved.z < -1.0, "moved at least 1 m north (-z), got %s" % moved)
	check(absf(_player().global_position.y) < 0.1, "stays on the imported floor, y=%.3f" % _player().global_position.y)


func test_imported_walls_block_movement() -> void:
	_player().place(Vector3(0.0, 0.05, -3.0), deg_to_rad(90.0)) # Facing west (-x).
	Input.action_press("move_forward")
	await wait_physics_frames(150)
	Input.action_release("move_forward")
	check(_player().global_position.x > -1.45, "stopped by the corridor wall, x=%.2f" % _player().global_position.x)


func test_ray_focuses_imported_door_and_e_opens_it() -> void:
	var prompts: Array[String] = []
	var on_focus: Callable = func(prompt: String) -> void: prompts.append(prompt)
	EventBus.interaction_focus_changed.connect(on_focus)
	_player().place(Vector3(-0.6, 0.05, -5.0), deg_to_rad(90.0)) # Facing the office door.
	await wait_physics_frames(4)
	EventBus.interaction_focus_changed.disconnect(on_focus)
	check_contains(prompts, "Open office door", "door prompt shown")
	var press: InputEventAction = InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	await runner.get_tree().process_frame
	await runner.get_tree().process_frame
	check(_world().get_door("door_office").is_open, "E opened the office door")


func test_imported_door_leaf_swings_and_collision_follows() -> void:
	var door: ImportedDoor = _world().get_door("door_office")
	var leaf: Node3D = door.get_leaves()[0]
	var closed_y: float = leaf.rotation.y
	door.set_open(true, false)
	await wait_physics_frames(2)
	check(absf(leaf.rotation.y - closed_y) > deg_to_rad(80.0), "leaf rotated open")
	# Imported shapes keep the hinge as origin; measure the collision geometry itself.
	var shape: CollisionShape3D = leaf.find_children("*", "CollisionShape3D", true, false).filter(
			func(n: Node) -> bool: return n.get_parent() is StaticBody3D)[0]
	var centre: Vector3 = _shape_world_centre(shape)
	check(centre.x < -1.7, "leaf collider swung into the office, centre x=%.2f" % centre.x)


func test_archive_door_needs_nurse_badge() -> void:
	var archive: ImportedDoor = _world().get_door("door_archive")
	_interact(archive.get_leaves()[0].get_node("Interactable"))
	check(not archive.is_open, "locked without access")
	var nurse: WardCharacter = _world().get_character("staff_bennett")
	check(nurse != null, "Nurse Bennett is at the nursing station")
	_interact(nurse.get_node("Interactable"))
	check(TrustManager.has_access("access_records_archive"), "nurse granted archive access")
	_info_panel().close()
	_interact(archive.get_leaves()[0].get_node("Interactable"))
	check(archive.is_open, "archive opens with the badge")


func test_w0b_and_ward_entry_stay_locked() -> void:
	for door_id: String in ["door_w0b", "door_ward_entry"]:
		var door: ImportedDoor = _world().get_door(door_id)
		_interact(door.get_leaves()[0].get_node("Interactable"))
		check(not door.is_open, "%s stays locked in Chapter 1" % door_id)
	check(_world().get_door("door_ward_entry").get_leaves().size() == 2, "ward entry is a double door")


func test_ehr_terminal_opens_record_once_per_day() -> void:
	var terminal: Interactable = _world().get_interactable("OF_Terminal_EHR").interactable
	_interact(terminal)
	var ehr: EHRScreen = _main.get_node("EHRScreen")
	check(ehr.is_open, "EHR screen open")
	check(not _player().input_enabled, "player frozen while the EHR is open")
	ehr.close()
	check(_player().input_enabled, "control returns when the EHR closes")
	_interact(terminal)
	ehr.close()
	check_eq(PatientManager.get_state("pt_elias_ward")["audit"].size(), 1, "record-open event not duplicated")


func test_roster_document_pickup_records_provenance() -> void:
	var controller: ImportedInteractable = _world().get_interactable("AR_Document_WardRoster1968")
	_interact(controller.interactable)
	check(EvidenceManager.has_clue("clue_roster"), "roster acquired")
	check_eq(EvidenceManager.get_acquisition("clue_roster")["method"], "pickup:AR_Document_WardRoster1968",
			"provenance recorded")
	check(not _world().find_world_node("AR_Document_WardRoster1968").visible, "document removed from the desk")


func test_all_three_chapter1_clues_are_reachable() -> void:
	for node_name: String in ["OF_Document_TransferSummary", "AR_Document_WardRoster1968", "W0B_AccessPanel"]:
		_interact(_world().get_interactable(node_name).interactable)
		_info_panel().close()
	check_eq(EvidenceManager.get_acquired_ids(), ["clue_access", "clue_roster", "clue_transfer"] as Array[String],
			"transfer summary, roster and door log collected")


func test_elias_is_seated_in_interview_room() -> void:
	var elias: WardCharacter = _world().get_character("pt_elias_ward")
	check(elias != null and elias.seated, "Elias is placed seated")
	var p: Vector3 = elias.global_position
	check(p.x > 1.6 and p.x < 5.4 and p.z < -10.1 and p.z > -13.9, "Elias is inside Interview Room A, at %s" % p)


func test_environment_states_toggle_and_persist() -> void:
	var open_node: Node3D = _world().find_world_node("OBS_Shutter_Open")
	var closed_node: Node3D = _world().find_world_node("OBS_Shutter_Closed")
	var seal: Node3D = _world().find_world_node("W0B_Seal_Sealed")
	check(open_node.visible and not closed_node.visible and seal.visible, "authored defaults applied")
	WorldStateManager.set_state("interviewA_observation_shutter", "closed")
	WorldStateManager.set_state("w0b_seal", "removed")
	check(closed_node.visible and not open_node.visible, "shutter closed")
	check(not seal.visible, "seal removed (state with no node hides the group)")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check(open_node.visible and seal.visible, "reset restores authored defaults")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check(closed_node.visible and not seal.visible, "states restored from save")


func test_world_state_survives_save_and_load() -> void:
	_world().get_door("door_office").set_open(true, false)
	_player().place(Vector3(-4.0, 0.05, -4.0), 1.0)
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check(not _world().get_door("door_office").is_open, "reset closes the door")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check(_world().get_door("door_office").is_open, "door state restored")
	check(_player().global_position.distance_to(Vector3(-4.0, 0.05, -4.0)) < 0.01, "player position restored")


func _shape_world_centre(shape_node: CollisionShape3D) -> Vector3:
	var points: PackedVector3Array = PackedVector3Array()
	if shape_node.shape is ConcavePolygonShape3D:
		points = (shape_node.shape as ConcavePolygonShape3D).get_faces()
	elif shape_node.shape is ConvexPolygonShape3D:
		points = (shape_node.shape as ConvexPolygonShape3D).points
	if points.is_empty():
		return shape_node.global_position
	var sum: Vector3 = Vector3.ZERO
	for p: Vector3 in points:
		sum += p
	return shape_node.global_transform * (sum / points.size())


func _world() -> AuthoredWorld:
	return _main.get_node("World")


func _player() -> FirstPersonController:
	return _main.get_node("Player")


func _info_panel() -> InfoPanel:
	return _main.get_node("InfoPanel")


func _interact(interactable: Interactable) -> void:
	interactable.interact(_player())
