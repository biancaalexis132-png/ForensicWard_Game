extends TestCase
## Chapter 2 Scene 07: An Incomplete Witness. The technician's recollection is
## recorded as reported; it never becomes an observation, clue or anomaly.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const RECORDS: String = "AR_Document_WardRoster1968"
const OFFICE: String = "OF_Document_TransferSummary"
const MARA: String = "pt_mara_ellis"
const MODULES: Array[String] = ["ask_sleep", "ask_mood_history", "ask_alternatives", "ask_safety", "ask_collateral"]
var _main: Main


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	ContentRegistry.load_all(ContentRegistry.DATA_DIR)
	super.after_each()


func _director() -> ChapterDirector:
	return _main.get_node("ChapterDirector")


func _world() -> AuthoredWorld:
	return _main.get_node("World")


func _use(prop: String) -> void:
	var target: ImportedInteractable = _world().get_interactable(prop)
	check(target != null, "real prop resolves: " + prop)
	if target != null:
		target.interactable.interact(_main.get_node("Player"))


func _approach(character_id: String) -> void:
	var actor: WardCharacter = _world().get_character(character_id)
	check(actor != null, "actor placed: " + character_id)
	if actor != null:
		actor.get_node("Interactable").interact(_main.get_node("Player"))


func _choose(text: String) -> void:
	for button: Node in _main.get_node("InfoPanel").find_children("*", "Button", true, false):
		if text in button.text:
			button.pressed.emit()
			return
	check(false, "displayed choice missing: " + text)


func _close() -> void:
	(_main.get_node("InfoPanel") as InfoPanel).close()


func _body() -> String:
	return (_main.get_node("InfoPanel/Root/Panel/Margin/VBox/Body") as RichTextLabel).get_parsed_text()


func _commit(prop: String, choice: String) -> void:
	_use(prop)
	_choose(choice)
	_close()


func _say(choice: String) -> void:
	_approach("staff_voss")
	_choose(choice)
	_close()


func _ask(choice_id: String) -> void:
	check(not DialogueManager.select_choice(choice_id).is_empty(), "interview choice available: " + choice_id)


func _present(character_id: String) -> bool:
	var actor: WardCharacter = _world().get_character(character_id)
	return actor != null and actor.is_present() and actor.get_node("Interactable").enabled


func _objective() -> String:
	return _director().get_current_objective().get("id", "")


func _reach_mara() -> void:
	_use("NS_NoticeBoard")
	_close()
	_use("NS_NoticeBoard")
	_choose("next day shift")
	await runner.get_tree().process_frame
	_approach("staff_bennett")
	_close()
	_commit("NS_NoticeBoard", "Retain responsibility")
	_commit(RECORDS, "unresolved")
	_commit(OFFICE, "Submit preservation")
	_approach("staff_bennett")
	_choose("Acknowledge the outstanding")
	_close()
	_commit(RECORDS, "Keep the correction unknown")
	_commit(RECORDS, "Retain the repeated row")
	_commit(OFFICE, "Leave independence unestablished")
	_commit(OFFICE, "Keep preservation confirmation")
	_commit(RECORDS, "Prioritize clock authority")
	_approach("staff_bennett")
	_choose("Acknowledge the records follow-up")
	_close()
	check(_present("pt_elias_ward") and not _present(MARA), "before Scene 03 Elias holds the interview room")
	_say("State only what is established")
	_say("Record the missing permissions")
	_say("Request the written escalation process")
	check_eq(_objective(), "obj_ch2_mara_interview", "Mara's interview follows Voss's review")
	check(_present(MARA) and not _present("pt_elias_ward"), "Mara is seated in Interview Room A")


func _interview() -> void:
	_approach(MARA)
	check_eq(DialogueManager.active_patient_id, MARA, "approaching Mara opens her interview")
	_ask("explain_limits")
	_ask("ask_origin")
	_ask("ask_explanation")
	for module: String in MODULES:
		_ask(module)
	_ask("close_interview")
	DialogueManager.end_dialogue()


func _note() -> String:
	var findings: Array[String] = []
	findings.assign(PatientManager.get_state(MARA)["observations"].keys())
	return PatientManager.save_note(MARA, findings, ["sleep_disturbance_with_fatigue"] as Array[String],
			"Sleep and function support; complete risk formulation; clarify legal question against the order; medication reconciliation.")


func _reach_analyst() -> void:
	await _reach_mara()
	await _interview()
	check(not _note().is_empty(), "Mara's note saved")
	_commit(OFFICE, "Refer the date question to Records on its own")
	check_eq(_objective(), "obj_ch2_analyst_candidates", "analyst follows Mara's referral")


func _talk_hale(choice: String) -> void:
	_approach("staff_hale")
	_choose(choice)
	_close()


func _reach_hale() -> void:
	await _reach_analyst()
	check(not _present("staff_hale"), "Hale not here before the analyst's check")
	_commit(RECORDS, "Log all four")
	_commit(RECORDS, "Request a neutral second review")
	check(_present("staff_hale"), "Hale waits in the office")
	check_eq(_objective(), "obj_ch2_hale_scope", "Hale's scene follows the analyst")


func _talk_tech(choice: String) -> void:
	_approach("staff_facilities_tech")
	_choose(choice)
	_close()


func _reach_witness() -> void:
	await _reach_hale()
	check(not _present("staff_facilities_tech"), "technician not here before Hale's follow-up")
	_talk_hale("Ask how the restricted designation")
	_talk_hale("permitted summary")
	check(_present("staff_facilities_tech"), "technician at the interview room door")
	check_eq(_objective(), "obj_ch2_witness_account", "witness follows Hale")


func _run_witness(choice: String, flag: String) -> void:
	await _reach_witness()
	var evidence: String = _canonical(EvidenceManager.to_save_data())
	var anomalies: String = _canonical(SaveManager.capture_state().get("anomalies", {}))
	var patients: String = _canonical(PatientManager.to_save_data())
	var flags: Array = _director().get_chapter_flags("ch2")
	_talk_tech("So someone took the old lift")
	check_eq(_director().get_chapter_flags("ch2"), flags, "leading question records nothing")
	_talk_tech("Did you actually see anyone")
	check(_director().has_flag("ch2_witness_account_recorded"), "account recorded as reported")
	flags = _director().get_chapter_flags("ch2")
	_talk_tech("Record that the lift moved")
	check_eq(_director().get_chapter_flags("ch2"), flags, "movement cannot be recorded")
	_talk_tech(choice)
	check(_director().has_flag(flag), "follow-up recorded: " + flag)
	check_eq(_objective(), "obj_ch2_lobby_escort", "witness scene hands on to the escorted lobby inspection")
	check(not _director().has_completed("ch2"), "Chapter 2 not falsely completed")
	check_eq(_canonical(EvidenceManager.to_save_data()), evidence, "no clue or evidence created")
	check_eq(_canonical(SaveManager.capture_state().get("anomalies", {})), anomalies, "no anomaly state changed")
	check_eq(_canonical(PatientManager.to_save_data()), patients, "no clinical change")
	check(_world().get_door("door_w0b").is_locked(), "W0-B remains locked")
	var saved: String = _canonical(SaveManager.capture_state())
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save after the choice")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load after the choice")
	await runner.get_tree().process_frame
	check_eq(_canonical(SaveManager.capture_state()), saved, "post-choice roundtrip exact")
	_approach("staff_facilities_tech")
	check("didn't see anything" in _body(), "technician gives read-only status")
	_close()


func test_work_orders_followup() -> void:
	await _run_witness("Ask which work orders", "ch2_witness_work_orders")


func test_as_reported_followup() -> void:
	await _run_witness("Keep the recollection exactly", "ch2_witness_as_reported")


func test_timing_followup() -> void:
	await _run_witness("Ask when they heard it", "ch2_witness_timing")


func test_interrupted_witness_conversation_resumes_after_load() -> void:
	await _reach_witness()
	_talk_tech("Did you actually see anyone")
	_approach("staff_facilities_tech")
	check("Anything else" in _body(), "follow-up step displayed")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save with the choice on screen")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load mid-conversation")
	await runner.get_tree().process_frame
	EventBus.story_option_selected.emit("interaction_ch2_witness_followup", "work_orders")
	check(not _director().has_flag("ch2_witness_work_orders"), "pre-load choice rejected")
	check_eq(_objective(), "obj_ch2_witness_followup", "resumes at the follow-up step")
	_talk_tech("Ask which work orders")
	check(_director().has_flag("ch2_witness_work_orders"), "resumed conversation completes")


func _canonical(data: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))
