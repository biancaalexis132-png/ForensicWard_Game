extends TestCase
## The full Elias encounter (EncounterManager, EncounterScreen, EncounterStage):
## valid data, a history taken across every domain with the sitter's facts in
## the chart, an examination that records the findings, bedside orders that
## place the EHR orders through ClinicalOrders, Bennett's challenge to an
## antipsychotic, lab results and the lorazepam reassessment on the clock,
## save and load, the validated-build fallback, and the staged room.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const ELIAS: String = "pt_elias_ward"
const HISTORY_STEPS: Array[String] = ["hx_onset", "hx_intake", "hx_sleep", "hx_medications", "hx_psych", "hx_medical",
		"hx_substances", "hx_family", "hx_social", "hx_risk"]

var _main: Node3D = null


func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func _do(steps: Array[String]) -> void:
	for step: String in steps:
		check(not EncounterManager.perform_step(ELIAS, step).is_empty(), "step runs: " + step)


func _witness_catatonic_signs() -> void:
	_do(["open_introduce", "hx_intake", "ex_arm_raise"])


func test_shipped_encounter_is_valid_and_pending_review() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/elias_encounter.json"))
	check_eq(EncounterManager.validate(data), [] as Array[String], "valid")
	check_eq(str(data["clinical_review_status"]), "PENDING_PSYCHIATRIST_REVIEW", "no approval is assumed")
	var labs: Array = WardRounds.lab_catalog().map(func(l: Dictionary) -> String: return l["id"])
	for item: Dictionary in data["orders"]["items"]:
		if item.has("lab_id"):
			check(item["lab_id"] in labs, "lab is in the ward-round catalog: " + item["lab_id"])
			check(data["orders"]["lab_results"].has(item["lab_id"]), "lab has a result: " + item["lab_id"])
		if item.has("ehr_order"):
			check(not ContentRegistry.get_order(item["ehr_order"]).is_empty(), "EHR order exists: " + item["ehr_order"])
	var observations: Array = ContentRegistry.get_patient(ELIAS)["presentation"]["observations"].map(func(o: Dictionary) -> String: return o["id"])
	for step: Dictionary in data["steps"]:
		for observation: String in step.get("records_observations", []):
			check(observation in observations, "authored observation: " + observation)
	check(EncounterManager.validate({"patient_id": "x"}).size() > 0, "an incomplete file is refused")


func test_history_needs_an_introduction_and_covers_every_domain() -> void:
	check(EncounterManager.perform_step(ELIAS, "hx_onset").is_empty(), "no history before the introduction")
	_do(["open_introduce"])
	check(not EncounterManager.is_history_complete(ELIAS), "not complete yet")
	_do(HISTORY_STEPS)
	check(EncounterManager.is_history_complete(ELIAS), "every domain covered")
	check(GameState.get_flag("elias_history_complete"), "flag set for later chapters")
	var facts: Array = EncounterManager.recorded_facts(ELIAS).map(func(f: Dictionary) -> String: return f["id"])
	check("fact_haloperidol" in facts, "the jail haloperidol is drawn out")
	var audit: Array = PatientManager.get_state(ELIAS)["audit"].map(func(e: Dictionary) -> String: return str(e.get("text", "")))
	check_contains(audit, "Haloperidol 5 mg", "the fact is in the chart with its source")
	check(EncounterManager.perform_step(ELIAS, "hx_onset").is_empty(), "a step is done once")


func test_examination_records_findings_and_opens_orders() -> void:
	_do(["open_introduce"])
	check(not EncounterManager.orders_open(ELIAS), "orders wait for the findings")
	_do(["hx_intake", "ex_observe", "ex_arm_raise", "ex_tone"])
	var recorded: Dictionary = PatientManager.get_state(ELIAS)["observations"]
	for finding: String in ["obs_mutism", "obs_posturing", "obs_immobility", "obs_staring", "obs_waxy_flexibility"]:
		check(recorded.has(finding), "recorded: " + finding)
	check(EncounterManager.orders_open(ELIAS), "orders open")
	var presented: Dictionary = EncounterManager.perform_step(ELIAS, "ex_pulse")
	check_eq(presented["performs"], "exam_pulse", "the psychiatrist performs it")
	check(presented["beats"][0].has("shown") and not presented["beats"][0].has("text"), "Elias's response is shown, not spoken")


func test_bedside_orders_place_the_ehr_orders_once() -> void:
	_witness_catatonic_signs()
	var result: Dictionary = EncounterManager.give_orders(ELIAS, ["eo_medical_review", "eo_lab_ck", "eo_fluid_chart"] as Array[String])
	check("ord_medical_team_review" in result["ehr"], "medical review placed through the EHR order")
	check("ord_catatonia_assessment" in result["ehr"], "the bedside exam is the structured assessment")
	check(not result["challenge"], "no challenge without an antipsychotic")
	var actions: Array = PatientManager.get_state(ELIAS)["audit"].filter(func(e: Dictionary) -> bool: return e["type"] == "clinical_action")
	check_eq(actions.size(), 2, "two clinical actions committed")
	check(GameState.get_flag("elias_orders_given"), "flag set")
	check(EncounterManager.give_orders(ELIAS, ["eo_lab_cbc"] as Array[String]).is_empty(), "orders are given once")
	check(not EncounterManager.labs_ready(ELIAS), "results are not back at once")
	TimeManager.advance(EncounterManager.LAB_DELAY_MINUTES + 1, "test")
	check(EncounterManager.labs_ready(ELIAS), "results back later in the shift")
	check_eq(EncounterManager.lab_results(ELIAS).size(), 1, "only the ordered lab")


func test_antipsychotic_is_challenged_by_the_charge_nurse() -> void:
	_witness_catatonic_signs()
	var trust: float = TrustManager.get_value("staff_bennett", "trust")
	check(EncounterManager.give_orders(ELIAS, ["eo_haloperidol"] as Array[String])["challenge"], "challenged")
	check_eq(EncounterManager.challenge_state(ELIAS), "pending", "Bennett is asking")
	check(not EncounterManager.resolve_challenge(ELIAS, "insist").is_empty(), "she answers")
	check_eq(EncounterManager.challenge_state(ELIAS), "held_by_nursing", "nursing holds it")
	check(TrustManager.get_value("staff_bennett", "trust") < trust, "trust falls")
	check(GameState.get_flag("elias_antipsychotic_held_by_nursing"), "flag set")
	check_eq(EncounterManager.resolve_challenge(ELIAS, "rescind"), "", "resolved once")


func test_lorazepam_brings_the_player_back_to_a_changed_patient() -> void:
	_witness_catatonic_signs()
	EncounterManager.give_orders(ELIAS, ["eo_lorazepam_challenge"] as Array[String])
	check_eq(EncounterManager.reassessment_state(ELIAS), "pending", "scheduled")
	check(EncounterManager.perform_step(ELIAS, "re_drink").is_empty(), "not before the call")
	TimeManager.advance(60, "test")
	check_eq(EncounterManager.reassessment_state(ELIAS), "ready", "the sitter calls")
	_do(["re_observe", "re_drink"])
	var last: Dictionary = EncounterManager.perform_step(ELIAS, "re_arm")
	check_eq(EncounterManager.reassessment_state(ELIAS), "done", "reassessed")
	check(GameState.get_flag("elias_lorazepam_response_seen"), "flag set")
	check_eq(str(last["beats"][-1]["speaker"]), "staff_sitter_adler", "Tom closes the scene")


func test_encounter_survives_save_and_load() -> void:
	_witness_catatonic_signs()
	EncounterManager.give_orders(ELIAS, ["eo_lorazepam_challenge", "eo_lab_bmp"] as Array[String])
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "saved")
	SaveManager.reset_all()
	check(not EncounterManager.is_done(ELIAS, "open_introduce"), "reset")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "loaded")
	check(EncounterManager.is_done(ELIAS, "ex_arm_raise"), "steps restored")
	check_eq(EncounterManager.given_orders(ELIAS), ["eo_lorazepam_challenge", "eo_lab_bmp"] as Array[String], "orders restored")
	check_eq(EncounterManager.reassessment_state(ELIAS), "pending", "reassessment still pending")


func test_validated_build_keeps_the_approved_interview() -> void:
	ClinicalRules.build_mode = ClinicalRules.MODE_VALIDATED
	check(not EncounterManager.is_playable(ELIAS), "draft encounter is off")
	check(EncounterManager.perform_step(ELIAS, "open_introduce").is_empty(), "and cannot be driven")
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	await wait_physics_frames(2)
	EventBus.ui_panel_requested.emit("interview", {"patient_id": ELIAS})
	check((_main.get_node("InterviewScreen") as InterviewScreen).is_open, "the approved interview opens")
	check(_main.get_node_or_null("EncounterScreen") == null, "no encounter screen")


func test_encounter_screen_stages_the_room() -> void:
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	await wait_physics_frames(2)
	EventBus.ui_panel_requested.emit("interview", {"patient_id": ELIAS})
	var screen: EncounterScreen = _main.get_node_or_null("EncounterScreen") as EncounterScreen
	check(screen != null and screen.is_open, "the encounter opens instead of the short interview")
	if screen == null:
		return
	check(not (_main.get_node("InterviewScreen") as InterviewScreen).is_open, "not the interview")
	check(_main.find_child("EncounterPsychiatrist", true, false) != null, "the player's psychiatrist is in the room")
	check(_main.find_child("Character_staff_sitter_adler", true, false) != null, "the sitter is in the room")
	check(screen.do_step("open_introduce"), "introduce")
	check(screen.is_presenting(), "presenting")
	for i: int in 30:
		if not screen.is_presenting():
			break
		screen.skip_line()
		await wait_physics_frames(4)
	check(not screen.is_presenting(), "every line can be skipped through")
	check("Tom" in screen.get_transcript_text(), "the sitter answers in the transcript")
	screen.skip_all()
	screen.show_section("exam")
	check(screen.get_step_labels().size() >= 8, "the examination steps are offered")
	check(screen.do_step("ex_arm_raise"), "lift the arm")
	await wait_physics_frames(30)
	screen.skip_all()
	screen.close()
	check(not screen.is_open, "closed")
	check(_main.find_child("EncounterPsychiatrist", true, false) == null or \
			_main.find_child("EncounterPsychiatrist", true, false).is_queued_for_deletion(), "the psychiatrist leaves with the screen")
