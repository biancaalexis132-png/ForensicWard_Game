extends TestCase

const PATIENT: String = "pt_elias_ward"

func test_real_signed_note_indexes_once_and_keeps_chart_ownership() -> void:
	var plan: String = "[b]Player text stays literal[/b]"
	var id: String = PatientManager.save_note(PATIENT, [] as Array[String], [] as Array[String], plan)
	check(not id.is_empty(), "real chart note saved")
	var notes: Array = PatientManager.get_notes(PATIENT)
	var evidence: Dictionary = EvidenceManager.to_save_data()
	EventBus.patient_note_saved.emit(PATIENT, id)
	EventBus.patient_note_saved.emit(PATIENT, "missing")
	check_eq(CaseJournal.get_entries_for_patient(PATIENT).size(), 1, "duplicate and missing note signals do not create entries")
	check(plan in CaseJournal.get_all_entries()[0]["content"], "journal resolves the real note")
	check(not CaseJournal.to_save_data()["entries"][0].has("content"), "signed content remains chart-owned")
	check_eq(PatientManager.get_notes(PATIENT), notes, "journal does not alter signed chart")
	check_eq(EvidenceManager.to_save_data(), evidence, "no evidence or story promotion")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save indexed journal")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load indexed journal")
	check_eq(CaseJournal.get_all_entries().size(), 1, "load reconciliation does not duplicate")

func test_legacy_chart_reconciliation_and_real_order_are_idempotent() -> void:
	PatientManager.save_note(PATIENT, [] as Array[String], [] as Array[String], "Recorded plan")
	PatientManager.perform_action(PATIENT, "request_medical_review", [] as Array[String])
	check_eq(CaseJournal.get_all_entries().size(), 2, "signed note and real order are indexed")
	CaseJournal.reset_state()
	EventBus.game_loaded.emit(TEST_SAVE_SLOT)
	EventBus.game_loaded.emit(TEST_SAVE_SLOT)
	check_eq(CaseJournal.get_all_entries().size(), 2, "legacy chart can rebuild references once")
	var event_id: String = PatientManager.action_event_id(PATIENT, "request_medical_review")
	EventBus.clinical_action_committed.emit(PATIENT, "request_medical_review", event_id)
	check_eq(CaseJournal.get_all_entries().size(), 2, "repeated clinical action stays one entry")
	check("Request medical team review" in CaseJournal.get_all_entries()[1]["content"], "order resolves approved authored description")

func test_map_projects_only_current_loaded_floor_without_state_changes() -> void:
	var main: Main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(main)
	await runner.get_tree().process_frame
	var world: AuthoredWorld = main.get_node("World")
	var zones: ZoneDirector = main.get_node("ZoneDirector")
	var before: Dictionary = SaveManager.capture_state()
	var loaded: Array[String] = world.get_zone_ids()
	var plan: Dictionary = FloorPlan.snapshot(world, main.get_node("Player"), zones)
	check_eq(plan["zone_id"], "zone_clinical_wing", "current floor")
	check(plan["floors"].size() >= 5, "actual imported room floors are projected")
	check(plan["doors"].size() > 0, "real door locations and access shown")
	check(plan["stations"].size() >= 2, "real EHR stations shown")
	check(not "Ward Zero" in str(plan), "restricted floor is not revealed")
	check_eq(world.get_zone_ids(), loaded, "map loads no extra zones")
	check_eq(SaveManager.capture_state(), before, "map changes no game state")
	main.free()
