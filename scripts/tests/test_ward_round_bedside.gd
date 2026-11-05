extends TestCase
## Ward-round patients on the ward: the staging data, who sits in which room,
## approaching a patient, the next patient arriving when a plan is accepted,
## and reloading. Staging only; the cases themselves are tested in
## test_ward_rounds.gd.

const WardRoundTests = preload("res://scripts/tests/test_ward_rounds.gd")
var _main: Main


func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	WardRounds.reset_state()
	ClinicalRules.build_mode = ClinicalRules.MODE_PROTOTYPE
	super.after_each()


func _start_main(chapter_id: String) -> WardRoundBedside:
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	var director: ChapterDirector = _main.get_node("ChapterDirector")
	if chapter_id != director.get_chapter_id():
		director.load_save_data({"current": chapter_id, "chapters": {}})
	var bedside: WardRoundBedside = _main.get_node("World").find_child(WardRoundBedside.NODE_NAME, true, false)
	if bedside != null:
		bedside.refresh()
	return bedside


func _all_case_ids() -> Array[String]:
	var ids: Array[String] = []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WardRounds.DATA_PATH))
	for case: Dictionary in data["cases"]:
		ids.append(str(case["id"]))
	return ids


func _accept(case_id: String) -> void:
	var solved: Dictionary = WardRoundTests._solve(WardRounds.get_case(case_id))
	for lab_id: String in solved["labs"]:
		WardRounds.order_lab(case_id, lab_id)
	check_eq(WardRounds.submit_plan(case_id, solved["plan"])["outcome"], "accepted", case_id + " accepted")


func test_staging_data_is_valid_and_every_patient_has_a_model() -> void:
	var data: Dictionary = WardRoundBedside.load_data()
	check(not data.is_empty(), "bedside data loads and validates")
	check(ContentRegistry.get_zone(str(data["zone"])).size() > 0, "bedside zone exists")
	var visuals: Dictionary = CampaignCastVisuals.load_data()["characters"]
	for case_id: String in data["patients"]:
		check(not WardRounds.get_case(case_id).is_empty(), "staged case exists: " + case_id)
		var character_id: String = data["patients"][case_id]
		check(visuals.has(character_id), "model catalogued for " + character_id)
		check(ResourceLoader.exists(str(visuals.get(character_id, {}).get("scene", ""))), "model file exists for " + character_id)
	# Every ward-round patient has a model on the ward.
	for case_id: String in _all_case_ids():
		check(data["patients"].has(case_id), "patient is staged: " + case_id)
	var broken: Dictionary = data.duplicate(true)
	broken["slots"] = [{"id": "room_01", "label": "", "position": [0, 0], "yaw_degrees": "east"}]
	broken["patients"] = {"wr_ch1_ortiz": ""}
	var errors: Array[String] = WardRoundBedside.validate(broken)
	check_contains(errors, "needs a label", "missing label named")
	check_contains(errors, "position must be [x, y, z]", "bad position named")
	check_contains(errors, "yaw_degrees must be a number", "bad yaw named")
	check_contains(errors, "has no character id", "missing character named")


func test_waiting_patients_sit_in_the_patient_rooms() -> void:
	var bedside: WardRoundBedside = _start_main("ch1")
	check(bedside != null, "bedside staging is in the clinical wing")
	if bedside == null:
		return
	check_eq(bedside.occupancy(), {"room_01": "wr_ch1_ortiz", "room_02": "wr_ch1_natarajan"}, "first two admissions take the rooms")
	for slot_id: String in ["room_01", "room_02"]:
		var patient: WardCharacter = bedside.occupant(slot_id)
		check_eq(patient.kind, WardCharacter.Kind.WARD_ROUND, slot_id + ": ward-round patient")
		check(patient.seated, slot_id + ": seated on the bed")
		check(patient.visual_error.is_empty(), slot_id + ": model loaded")
		check(patient.performer != null, slot_id + ": animated")
	var ortiz: WardCharacter = bedside.occupant("room_01")
	check_eq(ortiz.get_node("Interactable").prompt, "See Daniel Ortiz (ward round)", "prompt names the patient")
	# Inside Room 01, on the bed's near edge, facing the door (-X).
	var at: Vector3 = ortiz.global_position
	check(at.x > 3.6 and at.x < 3.9 and at.z < -4.0 and at.z > -5.6, "Ortiz sits on the edge of the Room 01 bed")
	check(ortiz.global_basis.z.dot(Vector3.RIGHT) > 0.9, "Ortiz faces the door")


func test_approaching_a_patient_opens_their_case() -> void:
	var bedside: WardRoundBedside = _start_main("ch1")
	var requests: Array = []
	var record: Callable = func(panel_id: String, data: Dictionary) -> void: requests.append([panel_id, data])
	EventBus.ui_panel_requested.connect(record)
	bedside.occupant("room_02").get_node("Interactable").interacted.emit(null)
	EventBus.ui_panel_requested.disconnect(record)
	check_eq(requests, [[WardRoundScreen.PANEL_ID, {"case_id": "wr_ch1_natarajan", "at_bedside": true}]], "ward-round screen opens on Natarajan")
	check(bedside.occupant("room_02").performer.is_engaged(), "she turns to the conversation")


func test_next_patient_takes_the_room_when_a_plan_is_accepted() -> void:
	var bedside: WardRoundBedside = _start_main("ch1")
	var notices: Array[String] = []
	var record: Callable = func(text: String) -> void: notices.append(text)
	EventBus.notification_requested.connect(record)
	_accept("wr_ch1_ortiz")
	check_eq(bedside.occupancy(), {"room_01": "wr_ch1_hughes", "room_02": "wr_ch1_natarajan"}, "Hughes takes Room 01; Natarajan stays")
	check_contains(notices, "Owen Hughes is waiting in Room 01", "arrival announced")
	_accept("wr_ch1_natarajan")
	check_eq(bedside.occupancy(), {"room_01": "wr_ch1_hughes", "room_02": "wr_ch1_morales"}, "Morales takes Room 02")
	_accept("wr_ch1_hughes")
	check_eq(bedside.occupancy(), {"room_01": "wr_ch1_haddad", "room_02": "wr_ch1_morales"}, "Haddad takes Room 01")
	_accept("wr_ch1_morales")
	_accept("wr_ch1_haddad")
	EventBus.notification_requested.disconnect(record)
	check(bedside.occupancy().is_empty(), "rooms empty once every plan is accepted")


func test_rooms_follow_a_loaded_game() -> void:
	var bedside: WardRoundBedside = _start_main("ch1")
	_accept("wr_ch1_natarajan")
	var saved: Dictionary = WardRounds.to_save_data()
	WardRounds.reset_state()
	bedside.refresh()
	check_eq(bedside.occupancy()["room_01"], "wr_ch1_ortiz", "fresh state: Ortiz in Room 01")
	WardRounds.load_save_data(saved)
	bedside.refresh()
	check(not "wr_ch1_natarajan" in bedside.occupancy().values(), "accepted patient is not on the ward after loading")
	check_eq(bedside.occupancy().size(), 2, "both rooms filled after loading")


func test_validated_build_seats_only_approved_patients() -> void:
	ClinicalRules.build_mode = ClinicalRules.MODE_VALIDATED
	var bedside: WardRoundBedside = _start_main("ch1")
	_accept("wr_ch1_ortiz")
	check_eq(bedside.occupancy(), {"room_02": "wr_ch1_natarajan"}, "draft cases never come to the ward in the validated build")
	ClinicalRules.build_mode = ClinicalRules.MODE_PROTOTYPE


func test_chapter_two_patients_follow_once_chapter_one_is_done() -> void:
	var bedside: WardRoundBedside = _start_main("ch2")
	for case_id: String in WardRounds.open_case_ids("ch1"):
		_accept(case_id)
	check_eq(bedside.occupancy(), {"room_01": "wr_ch2_kim", "room_02": "wr_ch2_lebel"}, "chapter 2's first two take the rooms")
	_accept("wr_ch2_kim")
	_accept("wr_ch2_lebel")
	check_eq(bedside.occupancy(), {"room_01": "wr_ch2_brennan", "room_02": "wr_ch2_kowalczyk"}, "then Brennan and Kowalczyk")
	for slot_id: String in ["room_01", "room_02"]:
		check(bedside.occupant(slot_id).visual_error.is_empty(), slot_id + ": model loaded")


func test_earlier_patients_wait_on_the_chairs_for_a_check_in() -> void:
	var bedside: WardRoundBedside = _start_main("ch1")
	_accept("wr_ch1_ortiz")
	check(bedside.check_in_occupancy().is_empty(), "nobody is due a check-in in their own chapter")
	for slot_id: String in ["seat_01", "seat_02", "seat_03"]:
		check(bedside.find_child("CheckInChair_" + slot_id, false, false) != null, slot_id + ": chair stands by the ward entrance")
	_main.free()
	WardRounds.reset_state()
	bedside = _start_main("ch2")
	for case_id: String in WardRounds.open_case_ids("ch1"):
		_accept(case_id)
	check_eq(bedside.check_in_occupancy(), {"seat_01": "wr_ch1_ortiz", "seat_02": "wr_ch1_natarajan", "seat_03": "wr_ch1_hughes"},
			"in chapter 2 the first three chapter 1 patients take the chairs, oldest first")
	check_eq(bedside.occupancy(), {"room_01": "wr_ch2_kim", "room_02": "wr_ch2_lebel"}, "the rooms still hold chapter 2's admissions")
	var patient: WardCharacter = bedside.occupant("seat_01")
	check(patient.seated and patient.visual_error.is_empty(), "Ortiz sits on the chair with his model")
	var requests: Array = []
	var record: Callable = func(panel_id: String, data: Dictionary) -> void: requests.append([panel_id, data])
	EventBus.ui_panel_requested.connect(record)
	patient.get_node("Interactable").interacted.emit(null)
	EventBus.ui_panel_requested.disconnect(record)
	check_eq(requests, [[WardRoundScreen.PANEL_ID, {"case_id": "wr_ch1_ortiz", "at_bedside": true}]], "approaching him opens his case")
	var notices: Array[String] = []
	var note: Callable = func(text: String) -> void: notices.append(text)
	EventBus.notification_requested.connect(note)
	check(not WardRounds.follow_up("wr_ch1_ortiz").is_empty(), "checking in on Ortiz")
	EventBus.notification_requested.disconnect(note)
	check_eq(bedside.check_in_occupancy(), {"seat_01": "wr_ch1_morales", "seat_02": "wr_ch1_natarajan", "seat_03": "wr_ch1_hughes"},
			"once checked in he leaves and the next patient takes the chair")
	check_contains(notices, "Lucia Morales is waiting in the seats by the ward entrance", "arrival announced")


func test_check_in_chairs_follow_a_loaded_game() -> void:
	var bedside: WardRoundBedside = _start_main("ch2")
	for case_id: String in WardRounds.open_case_ids("ch1"):
		_accept(case_id)
	for case_id: String in ["wr_ch1_ortiz", "wr_ch1_natarajan", "wr_ch1_hughes", "wr_ch1_morales"]:
		WardRounds.follow_up(case_id)
	check_eq(bedside.check_in_occupancy().values(), ["wr_ch1_haddad"], "only Haddad is still due, and keeps her chair")
	var saved: Dictionary = WardRounds.to_save_data()
	WardRounds.reset_state()
	bedside.refresh()
	check(bedside.check_in_occupancy().is_empty(), "fresh state: nobody accepted, so nobody on the chairs")
	WardRounds.load_save_data(saved)
	bedside.refresh()
	check_eq(bedside.check_in_occupancy(), {"seat_01": "wr_ch1_haddad"}, "loaded: Haddad is back on a chair")


func test_check_in_staging_is_validated() -> void:
	var data: Dictionary = WardRoundBedside.load_data()
	var broken: Dictionary = data.duplicate(true)
	broken["check_in"]["chair_scene"] = "res://missing_chair.glb"
	broken["check_in"]["slots"].append({"id": "room_01", "label": "x", "position": [0, 0, 0], "yaw_degrees": 0})
	var errors: Array[String] = WardRoundBedside.validate(broken)
	check_contains(errors, "check_in.chair_scene must name a scene that exists", "missing chair named")
	check_contains(errors, "slot ids must be unique", "a chair cannot reuse a room's id")
	broken["check_in"] = []
	check_contains(WardRoundBedside.validate(broken), "check_in must be an object", "bad check_in named")
