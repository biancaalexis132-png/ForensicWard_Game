extends TestCase

func test_profile_confirm_cancel_and_note_identity_are_independent_of_clinical_state() -> void:
	var before: Dictionary = PatientManager.to_save_data()
	var draft: Dictionary = ProtagonistProfile.get_profile()
	draft["name"] = "Dr Zoë 林"
	draft["skin_tone"] = "deep"
	draft["relationship"] = "independent"
	check(ProtagonistProfile.apply_draft(draft), "valid Unicode identity and independent-life path")
	check_eq(PatientManager.to_save_data(), before, "identity changes no patient findings or competence")
	var id: String = PatientManager.save_note("pt_elias_ward", [] as Array[String], [] as Array[String], "Signed plan")
	check(not id.is_empty(), "real signed note")
	draft = ProtagonistProfile.get_profile()
	draft["name"] = "Dr Changed"
	check(ProtagonistProfile.apply_draft(draft), "edit identity")
	check_eq(PatientManager.get_notes("pt_elias_ward")[0]["author_name"], "Dr Zoë 林", "historical author snapshot does not change")
	var profile: Dictionary = ProtagonistProfile.get_profile()
	draft["professional_role"] = "other_role"
	check(not ProtagonistProfile.apply_draft(draft), "role remains psychiatrist")
	check_eq(ProtagonistProfile.get_profile(), profile, "invalid draft is atomic")
	var panel: ProtagonistScreen = load("res://scenes/ui/ProtagonistScreen.tscn").instantiate()
	runner.add_child(panel)
	panel.open()
	panel._draft["name"] = "Cancelled name"
	panel.close()
	check_eq(ProtagonistProfile.get_profile(), profile, "cancel discards draft")
	panel.free()

func test_profile_choice_ledger_deduplicates_and_survives_json() -> void:
	EventBus.story_choice_committed.emit("ch1", "interaction_test", "option_test")
	EventBus.story_choice_committed.emit("ch1", "interaction_test", "option_test")
	check_eq(ProtagonistProfile.get_profile()["choices"].size(), 1, "one committed choice event")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save profile")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load profile")
	check_eq(ProtagonistProfile.get_profile()["choices"].size(), 1, "no replay on load")

func test_v3_migration_preserves_campaign_and_rejects_bad_profile_before_mutation() -> void:
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "baseline save")
	var path: String = SaveManager.get_slot_path(TEST_SAVE_SLOT)
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var old_state: Dictionary = document["state"].duplicate(true)
	document["state"].erase("protagonist")
	document["state"].erase("continuing_practice")
	document["save_version"] = 3
	_write_document(path, document)
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "v3 migrates")
	check_eq(SaveManager.capture_state()["patients"], old_state["patients"], "patient notes unchanged")
	check_eq(SaveManager.capture_state().get("chapter"), old_state.get("chapter"), "chapter/ending state unchanged")
	check(not ProtagonistProfile.get_profile()["configured"], "legacy run does not force a creator")
	document["save_version"] = 4
	document["state"]["protagonist"] = ProtagonistProfile.default_data()
	document["state"]["protagonist"]["professional_role"] = "not_psychiatrist"
	_write_document(path, document)
	var before: Dictionary = SaveManager.capture_state()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), ERR_INVALID_DATA, "malformed profile rejected")
	check_eq(SaveManager.capture_state(), before, "failed load preserves every live provider")

func _write_document(path: String, document: Dictionary) -> void:
	document["state"] = JSON.parse_string(JSON.stringify(document["state"]))
	document["checksum"] = JSON.stringify(document["state"], "", true).sha256_text()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(document))
	file.close()

func _approved_fixture() -> Dictionary:
	var definition: Dictionary = ContinuingPractice.get_definition("cp_001")
	definition["clinical_review_status"] = "APPROVED"
	definition["patient"]["clinical_review_status"] = "APPROVED"
	for encounter: Dictionary in definition["encounters"]:
		encounter["clinical_review_status"] = "APPROVED"
		encounter["dialogue"]["clinical_review_status"] = "APPROVED"
	return definition

func test_practice_five_encounters_followup_and_handoff_across_variants() -> void:
	var pending: PracticeCase = PracticeCase.new(ContinuingPractice.get_definition("cp_001"))
	check(not pending.accept(true), "shipped pending case cannot become clinical play")
	var case: PracticeCase = PracticeCase.new(_approved_fixture())
	check(not case.accept(false), "post-campaign only")
	check(case.accept(true), "reviewed post-campaign case accepted")
	for encounter: int in range(1, 6):
		check(case.record("interview", "transcript_%d" % encounter, "interview_%d" % encounter), "interview recorded")
		check(not case.record("interview", "same", "interview_%d" % encounter), "duplicate rejected")
		check(not case.finish_encounter(), "signed note required")
		check(case.record("note", "note_%d" % encounter, "note_%d" % encounter), "note reference recorded")
		var restored: PracticeCase = PracticeCase.new(_approved_fixture())
		check(restored.load_save_data(JSON.parse_string(JSON.stringify(case.to_save_data()))), "each encounter JSON round trip")
		case = restored
		check(case.finish_encounter(), "encounter completes")
	check_eq(case.to_save_data()["status"], "followup_cycle_complete", "five-encounter arc completes")
	check(not case.finish_encounter(), "completion is idempotent")

func test_practice_task_acknowledgment_source_and_consent_boundaries() -> void:
	var case: PracticeCase = PracticeCase.new(_approved_fixture())
	case.accept(true)
	check(case.add_task("followup", "Outstanding question", "Duty psychiatrist", "Next day shift"), "accountable task")
	check(not case.tasks_accounted_for(), "pending task blocks closure")
	check(not case.update_task("followup", "handoff_acknowledged"), "cannot acknowledge an unsent handoff")
	case.update_task("followup", "handoff_pending")
	case.update_task("followup", "handoff_acknowledged")
	check(case.tasks_accounted_for(), "acknowledged handoff has a named owner and review point")
	check_eq(case.to_save_data()["tasks"][0]["status"], "handoff_acknowledged", "handoff is not recorded as resolved")
	check(not case.can_contact_collateral(), "no consent by default")
	case.set_collateral_consent(true)
	check(case.can_contact_collateral(), "consent explicit")
	case.set_collateral_consent(false)
	check(not case.can_contact_collateral(), "withdrawal respected")
	check(not case.record_source("source_cp001_family", "CHART_RECORD", true), "unavailable collateral cannot become verified evidence")
	check(case.record_source("source_cp001_family", "UNAVAILABLE"), "unavailable source remains explicit")
	check(case.add_task("safety", "Unfinished safety question", "Duty psychiatrist", "Now", true), "safety hold")
	case.update_task("safety", "handoff_pending")
	case.update_task("safety", "handoff_acknowledged")
	check(not case.tasks_accounted_for(), "acknowledgment cannot override a safety hold")

func test_pending_worklist_and_creator_open_without_changing_run_state() -> void:
	var main: Main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(main)
	await runner.get_tree().process_frame
	var before: Dictionary = SaveManager.capture_state()
	for route: String in ["protagonist", "continuing_practice"]:
		EventBus.ui_panel_requested.emit(route, {})
		var panel: CanvasLayer = main._top_panel()
		check(panel != null and panel.get("is_open"), "panel routed through existing lifecycle")
		check(not (main.get_node("Player") as FirstPersonController).input_enabled, "modal blocks movement")
		panel.call("close")
	check_eq(SaveManager.capture_state(), before, "view/cancel does not create clinical or profile state")
	main.free()
