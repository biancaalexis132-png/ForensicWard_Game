extends TestCase
## Integration tests against the real Main scene: movement, collision,
## interaction ray, doors, access, documents, UI mode and world save/load
## (MVP acceptance tests 1-2).

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


func test_main_scene_boots_with_valid_content() -> void:
	await wait_physics_frames(2)
	check(_player().input_enabled, "player has control after boot")
	check(not _info_panel().is_open, "no blocking error panel")


func test_walks_forward_with_move_forward() -> void:
	await wait_physics_frames(5) # Settle onto the floor.
	var start: Vector3 = _player().global_position
	Input.action_press("move_forward")
	await wait_physics_frames(60)
	Input.action_release("move_forward")
	var moved: Vector3 = _player().global_position - start
	check(moved.z < -1.0, "moved at least 1 m forward (-z), got %s" % moved)
	check(absf(_player().global_position.y) < 0.1, "stays on the floor, y=%.3f" % _player().global_position.y)


func test_walls_block_movement() -> void:
	# Hallway A at z = -4: the west wall (x = -2) is solid there.
	_player().place(Vector3(0.0, 0.05, -3.5), deg_to_rad(90.0)) # Facing -x.
	Input.action_press("move_forward")
	await wait_physics_frames(150)
	Input.action_release("move_forward")
	check(_player().global_position.x > -1.9, "stopped by the wall, x=%.2f" % _player().global_position.x)


func test_ray_focuses_door_and_e_opens_it() -> void:
	var prompts: Array[String] = []
	var on_focus: Callable = func(prompt: String) -> void: prompts.append(prompt)
	EventBus.interaction_focus_changed.connect(on_focus)
	_player().place(Vector3(-0.6, 0.05, -6.0), deg_to_rad(90.0)) # Facing the office door.
	await wait_physics_frames(4)
	EventBus.interaction_focus_changed.disconnect(on_focus)
	check_contains(prompts, "Open office door", "door prompt shown")

	var press: InputEventAction = InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	# Injected input is flushed on the next process frame.
	await runner.get_tree().process_frame
	await runner.get_tree().process_frame
	check(_door("OfficeDoor").is_open, "E opened the office door")


func test_open_door_panel_actually_swings_clear() -> void:
	var door: Door = _door("OfficeDoor")
	var panel: Node3D = door.get_node("Hinge/Panel")
	var closed_x: float = panel.global_position.x
	door.load_save_data({"open": true}) # Instant open (no tween).
	await wait_physics_frames(2)
	# Closed, the panel sits in the wall plane (x = -2); open, it swings into the office.
	check(absf(closed_x - (-2.0)) < 0.05, "closed panel in the doorway, x=%.2f" % closed_x)
	check(panel.global_position.x < -2.3, "open panel swung into the office, x=%.2f" % panel.global_position.x)


func test_archive_door_needs_nurse_badge() -> void:
	var archive: Door = _door("ArchiveDoor")
	_interact(archive.get_node("Hinge/Panel/Interactable"))
	check(not archive.is_open, "locked without access")
	_interact(_main.get_node("HospitalGreybox/Characters/NurseBennett/Interactable"))
	check(_info_panel().is_open, "nurse conversation panel opened")
	check(TrustManager.has_access("access_records_archive"), "nurse granted archive access")
	_info_panel().close()
	_interact(archive.get_node("Hinge/Panel/Interactable"))
	check(archive.is_open, "archive opens with the badge")


func test_ward_zero_stays_sealed() -> void:
	var door: Door = _door("WardZeroDoor")
	_interact(door.get_node("Hinge/Panel/Interactable"))
	check(not door.is_open, "W0-B cannot be opened in Sprint 1")


func test_panel_takes_and_returns_control() -> void:
	_interact(_main.get_node("HospitalGreybox/Rooms/Office/EHRTerminal/Interactable"))
	check(_info_panel().is_open, "EHR placeholder panel open")
	check(not _player().input_enabled, "player frozen while panel open")
	check(TimeManager.is_paused(), "clock paused while panel open")
	_info_panel().close()
	check(_player().input_enabled, "control restored after closing")
	check(not TimeManager.is_paused(), "clock resumes")


func test_ehr_terminal_opens_record_once_per_day() -> void:
	var terminal: Node = _main.get_node("HospitalGreybox/Rooms/Office/EHRTerminal/Interactable")
	_interact(terminal)
	_info_panel().close()
	_interact(terminal)
	_info_panel().close()
	check_eq(PatientManager.get_state("pt_elias_ward")["audit"].size(), 1, "record-open event not duplicated")


func test_document_pickup_records_clue_with_provenance() -> void:
	var pickup: CluePickup = _main.get_node("HospitalGreybox/Rooms/RecordsArchive/WardRoster1968")
	_interact(pickup.get_node("Interactable"))
	check(EvidenceManager.has_clue("clue_roster"), "roster acquired")
	check_eq(EvidenceManager.get_acquisition("clue_roster")["method"], "pickup:WardRoster1968", "provenance recorded")
	check(not pickup.visible, "document removed from the desk")


func test_world_state_survives_save_and_load() -> void:
	_interact(_door("OfficeDoor").get_node("Hinge/Panel/Interactable"))
	_player().place(Vector3(-5.0, 0.05, -6.0), 1.0)
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check(not _door("OfficeDoor").is_open, "reset closes the door")
	check(_player().global_position.distance_to(Vector3(-5.0, 0.05, -6.0)) > 1.0, "reset moves player to spawn")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check(_door("OfficeDoor").is_open, "door state restored")
	check(_player().global_position.distance_to(Vector3(-5.0, 0.05, -6.0)) < 0.01, "player position restored")


func _player() -> FirstPersonController:
	return _main.get_node("Player")


func _info_panel() -> InfoPanel:
	return _main.get_node("InfoPanel")


func _door(door_name: String) -> Door:
	return _main.get_node("HospitalGreybox/Doors/" + door_name)


func _interact(interactable: Interactable) -> void:
	interactable.interact(_player())
