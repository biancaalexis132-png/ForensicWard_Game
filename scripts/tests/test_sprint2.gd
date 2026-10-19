extends TestCase
## Sprint 2: interview -> observation capture -> EHR note -> clinical action,
## through the real Main scene, the InterviewScreen and the EHRScreen
## (GDD §13 MVP loop: "chooses structured or typed recognized question;
## observes one catatonia-related finding; opens EHR; saves structured note;
## chooses one clinically meaningful action; receives deterministic state
## update").

const PENDING_FIXTURE_DIR: String = "user://test_pending_rule"
const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const ELIAS: String = "pt_elias_ward"

var _main: Node3D = null


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	super.after_each()
	if is_instance_valid(_main):
		_main.free()


# --- Interview ------------------------------------------------------------------

func test_approaching_elias_opens_cinematic_interview() -> void:
	var player_camera: Camera3D = _main.get_viewport().get_camera_3d()
	_approach_elias()
	check(_interview().is_open, "interview screen open")
	check(not _player().input_enabled, "player frozen during the interview")
	check_eq(_interview().current_shot, InterviewScreen.SHOT_ESTABLISHING, "opens on the establishing shot")
	check(_main.get_viewport().get_camera_3d().name == InterviewScreen.SHOT_ESTABLISHING,
			"the Blender interview camera is current")
	check_contains(_interview().get_choice_labels(), "food and fluids", "authored topics listed")
	_interview().close()
	check(_main.get_viewport().get_camera_3d() == player_camera, "player camera restored")
	check(_player().input_enabled, "control returns after the interview")


func test_typed_question_records_finding_with_provenance() -> void:
	_approach_elias()
	var minutes_before: int = TimeManager.total_minutes
	var result: Dictionary = _interview().ask_text("Is he eating?")
	check_eq(result.get("choice_id", ""), "ask_intake", "typed question matched the nutrition topic")
	var observations: Dictionary = PatientManager.get_state(ELIAS)["observations"]
	check(observations.has("obs_mutism"), "mutism witnessed during the interview")
	check_eq(observations["obs_mutism"]["recorded_by"], "interview:ask_intake", "provenance names the question")
	check_eq(_interview().current_shot, InterviewScreen.SHOT_ON_PATIENT, "cuts to the patient for the answer")
	check_eq(TimeManager.total_minutes - minutes_before, DialogueManager.QUESTION_MINUTES, "a question costs time")
	check("Is he eating?" in _interview().get_transcript_text(), "transcript shows the question")


func test_unmatched_question_falls_back_without_recording() -> void:
	_approach_elias()
	var result: Dictionary = _interview().ask_text("What is your favourite colour?")
	check_eq(result["status"], "fallback", "polite fallback")
	check(PatientManager.get_state(ELIAS)["observations"].is_empty(), "nothing recorded")
	check_eq(_interview().current_shot, InterviewScreen.SHOT_ESTABLISHING, "back to the wide shot")


func test_structured_choice_moves_dialogue_and_records_posturing() -> void:
	_approach_elias()
	_interview().ask_choice("assess_motor")
	check(PatientManager.get_state(ELIAS)["observations"].has("obs_posturing"), "posturing witnessed")
	check_contains(_interview().get_choice_labels(), "Return to general questions", "moved to the assessment state")
	_interview().ask_choice("assess_motor")  # Not available in this state: no duplicate.
	check_eq(PatientManager.get_state(ELIAS)["observations"].size(), 1, "observation recorded once")


func test_esc_closes_interview_not_pause_menu() -> void:
	_approach_elias()
	_press_action("pause")
	await runner.get_tree().process_frame
	check(not _interview().is_open, "Esc ended the interview")
	check(not (_main.get_node("PauseMenu") as PauseMenu).is_open, "pause menu stayed closed")


# --- EHR ----------------------------------------------------------------------------

func test_j_opens_ehr_and_shows_chart_tabs() -> void:
	_press_action("ehr")
	await runner.get_tree().process_frame
	check(_ehr().is_open, "J opens the EHR")
	check_eq(_ehr().patient_id, ELIAS, "first patient selected")
	check("competency restoration transfer" in _ehr().get_tab_text("Summary"), "legal status shown")
	check("Not yet witnessed by you" in _ehr().get_tab_text("Observations"), "reports kept apart from witnessed findings")
	check("record opened" in _ehr().get_tab_text("Audit"), "opening the chart is audited")
	check("NOT clinically validated" in _ehr()._banner.text, "prototype banner states the review status")
	_press_action("ehr")
	await runner.get_tree().process_frame
	check(not _ehr().is_open, "J closes it again")


func test_note_requires_recorded_findings_and_is_append_only() -> void:
	_open_ehr()
	check(_ehr().get_finding_choices().is_empty(), "no findings offered before they are witnessed")
	check_eq(_ehr().submit_note(), "", "an empty note is not saved")
	_ehr().close()
	_approach_elias()
	_interview().ask_choice("ask_intake")
	_interview().close()
	_open_ehr()
	check_eq(_ehr().get_finding_choices(), ["obs_mutism"] as Array[String], "witnessed finding offered")
	_ehr().set_note_selection(["obs_mutism"], ["catatonia", "medical_or_neurologic_cause"],
			"Review intake chart with nursing.")
	var note_id: String = _ehr().submit_note()
	check_eq(note_id, "note_pt_elias_ward_001", "note saved")
	var note: Dictionary = PatientManager.get_notes(ELIAS)[0]
	check_eq(note["findings"], ["obs_mutism"], "cited findings stored")
	check_eq(note["considerations"], ["catatonia", "medical_or_neurologic_cause"], "considerations stored")
	check_eq(note["author"], "player", "author recorded")
	check("Under consideration: catatonia" in _ehr().get_tab_text("Notes"), "note listed in the chart")
	check("note saved" in _ehr().get_tab_text("Audit"), "note audited")


func test_note_cannot_cite_unwitnessed_finding() -> void:
	var findings: Array[String] = ["obs_posturing"]
	var none: Array[String] = []
	check_eq(PatientManager.save_note(ELIAS, findings, none, ""), "", "unwitnessed finding rejected")
	var bad: Array[String] = ["schizophrenia"]
	check_eq(PatientManager.save_note(ELIAS, none, bad, ""), "", "consideration outside the authored differential rejected")
	check(PatientManager.get_notes(ELIAS).is_empty(), "nothing saved")


func test_catatonia_assessment_needs_both_findings() -> void:
	_open_ehr()
	var result: Dictionary = _ehr().commit_action("evaluate_catatonia")
	check(result["rule_ids"].is_empty(), "no rule applies without the findings")
	check(not PatientManager.get_state(ELIAS)["assessment"].get("started", false), "chart unchanged")
	check(_ehr().get_action_button("evaluate_catatonia").disabled, "one commit per shift day")
	check("No rule applied" in _ehr().get_tab_text("Orders"), "outcome explained")


func test_full_mvp_loop_updates_chart_deterministically() -> void:
	var first: Dictionary = await _run_mvp_loop()
	SaveManager.reset_all()
	var second: Dictionary = await _run_mvp_loop()
	check_eq(first, second, "same inputs give identical patient state")
	var state: Dictionary = first
	check(state["assessment"].get("started", false), "approved rule applied its non-medical effect")
	check_eq(state["audit"].filter(func(e: Dictionary) -> bool: return e["type"] == "clinical_action").size(), 1,
			"one clinical action audited")
	var action_entry: Dictionary = state["audit"].filter(func(e: Dictionary) -> bool: return e["type"] == "clinical_action")[0]
	check_eq(action_entry["rule_ids"], ["clinical_rule_catatonia_escalation_v1"], "rule id recorded")
	check(action_entry["review_flags"].is_empty(), "approved rule use needs no review flag")


func test_validated_build_refuses_pending_rule_from_ehr() -> void:
	ClinicalRules.build_mode = ClinicalRules.MODE_VALIDATED
	_open_ehr()
	check("switched off" in _ehr()._banner.text, "validated banner")
	_load_pending_rule_fixture()
	_ehr().commit_action("request_medical_review")
	_restore_content()
	check(not PatientManager.get_state(ELIAS)["assessment"].get("medical_review_requested", false), "pending rule not applied")
	check("Review flag" in _ehr().get_tab_text("Orders"), "refusal shown to the player")


func test_validated_build_applies_approved_catatonia_rule() -> void:
	ClinicalRules.build_mode = ClinicalRules.MODE_VALIDATED
	_approach_elias()
	_interview().ask_choice("ask_intake")
	_interview().ask_choice("assess_motor")
	_interview().close()
	_open_ehr()
	_ehr().commit_action("evaluate_catatonia")
	check(PatientManager.get_state(ELIAS)["assessment"].get("started", false), "approved rule applied")


func test_medical_review_request_is_logged_without_simulated_result() -> void:
	_open_ehr()
	var result: Dictionary = _ehr().commit_action("request_medical_review")
	check_eq(result["rule_ids"], ["clinical_rule_medical_review_request_v1"], "placeholder rule matched")
	var assessment: Dictionary = PatientManager.get_state(ELIAS)["assessment"]
	check_eq(assessment.keys(), ["medical_review_requested"], "only the request flag is set")


func test_notes_and_findings_survive_save_and_load() -> void:
	_approach_elias()
	_interview().ask_choice("ask_intake")
	_interview().close()
	var findings: Array[String] = ["obs_mutism"]
	var none: Array[String] = []
	PatientManager.save_note(ELIAS, findings, none, "Plan text")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check(PatientManager.get_notes(ELIAS).is_empty(), "reset clears notes")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check_eq(PatientManager.get_notes(ELIAS).size(), 1, "note restored")
	check(PatientManager.get_state(ELIAS)["observations"].has("obs_mutism"), "finding restored")
	check_eq(DialogueManager.get_transcript(ELIAS).size(), 2, "interview transcript restored")


# --- Helpers ----------------------------------------------------------------------

func _run_mvp_loop() -> Dictionary:
	await runner.get_tree().process_frame
	_approach_elias()
	_interview().ask_text("Is he eating?")
	_interview().ask_choice("assess_motor")
	_interview().close()
	_open_ehr()
	_ehr().set_note_selection(["obs_mutism", "obs_posturing"], ["catatonia"], "Structured assessment next.")
	_ehr().submit_note()
	_ehr().commit_action("evaluate_catatonia")
	_ehr().close()
	var state: Dictionary = PatientManager.get_state(ELIAS)
	state["clock"] = TimeManager.total_minutes
	return state


func _approach_elias() -> void:
	var elias: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character(ELIAS)
	(elias.get_node("Interactable") as Interactable).interact(_player())


func _open_ehr() -> void:
	EventBus.ui_panel_requested.emit("ehr", {})


func _press_action(action: String) -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)


func _player() -> FirstPersonController:
	return _main.get_node("Player")


func _interview() -> InterviewScreen:
	return _main.get_node("InterviewScreen")


func _ehr() -> EHRScreen:
	return _main.get_node("EHRScreen")


## Loads the shipped content with the medical review rule set back to pending,
## so rule governance stays tested now that every shipped rule is approved.
func _load_pending_rule_fixture() -> void:
	var problems: Array[String] = []
	var docs: Dictionary = ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)
	for rule: Dictionary in docs["clinical_rules"]["data"]["rules"]:
		if rule["id"] == "clinical_rule_medical_review_request_v1":
			rule["review_status"] = "PENDING_PSYCHIATRIST_REVIEW"
	DirAccess.make_dir_recursive_absolute(PENDING_FIXTURE_DIR)
	for key: String in docs:
		var file: FileAccess = FileAccess.open(PENDING_FIXTURE_DIR.path_join(docs[key]["file"]), FileAccess.WRITE)
		file.store_string(JSON.stringify(docs[key]["data"], "\t"))
		file.close()
	check(ContentRegistry.load_all(PENDING_FIXTURE_DIR), "pending-rule fixture validates: %s" % str(ContentRegistry.errors))


func _restore_content() -> void:
	for file_name: String in DirAccess.get_files_at(PENDING_FIXTURE_DIR):
		DirAccess.remove_absolute(PENDING_FIXTURE_DIR.path_join(file_name))
	DirAccess.remove_absolute(PENDING_FIXTURE_DIR)
	ContentRegistry.load_all(ContentRegistry.DATA_DIR)
