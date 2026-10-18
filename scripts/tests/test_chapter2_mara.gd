extends TestCase
## Chapter 2 Scene 03: Mara Ellis's owner-approved introduction. A clinical
## interview through the existing dialogue system, an EHR note, then a separate
## Records referral. Her records question never becomes evidence or a diagnosis.

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


func test_mara_is_not_on_the_census_before_her_arrival() -> void:
	check(not PatientManager.is_admitted(MARA), "day 1: Mara has not arrived")
	check(PatientManager.is_admitted("pt_elias_ward"), "Elias is on the day 1 census")
	check(_world().get_character(MARA) == null, "no Mara actor in Chapter 1")


func test_full_scene_records_patient_report_note_and_separate_referral() -> void:
	await _reach_mara()
	check(PatientManager.is_admitted(MARA), "Mara arrives on day 2")
	var evidence: String = _canonical(EvidenceManager.to_save_data())
	var elias: String = _canonical(PatientManager.get_state("pt_elias_ward"))
	await _interview()
	var recorded: Dictionary = PatientManager.get_state(MARA)["observations"]
	check_eq(recorded.size(), 6, "every module recorded once")
	check_eq(_objective(), "obj_ch2_mara_note", "interview complete; documentation next")
	_use(OFFICE)
	var offered: bool = false
	for button: Node in _main.get_node("InfoPanel").find_children("*", "Button", true, false):
		offered = offered or "Refer the date question" in button.text
	check(not offered, "referral waits for the clinical note")
	_close()
	EventBus.story_option_selected.emit("interaction_ch2_mara_referral", "refer_question")
	check(not _director().has_flag("ch2_mara_records_referred"), "undisplayed referral rejected")
	check(not _note().is_empty(), "append-only EHR note saved")
	check_eq(_objective(), "obj_ch2_mara_referral", "referral follows the note")
	var flags: Array = _director().get_chapter_flags("ch2")
	_commit(OFFICE, "Attach your clinical assessment")
	_commit(OFFICE, "Add the date conflict to the W0-B")
	check_eq(_director().get_chapter_flags("ch2"), flags, "unsupported referrals set nothing")
	_commit(OFFICE, "Refer the date question to Records on its own")
	check(_director().has_flag("ch2_mara_records_referred"), "separate referral recorded")
	check_eq(_objective(), "obj_ch2_analyst_candidates", "Mara's scene hands on to the analyst")
	check(not _director().has_completed("ch2"), "Chapter 2 not falsely completed")
	check_eq(_canonical(EvidenceManager.to_save_data()), evidence, "Mara's question adds no clue or evidence")
	check_eq(_canonical(PatientManager.get_state("pt_elias_ward")), elias, "Elias's record untouched")
	check(not PatientManager.get_state(MARA)["audit"].any(
			func(entry: Dictionary) -> bool: return entry["type"] == "clinical_action"), "no clinical action or treatment")
	check(_world().get_door("door_w0b").is_locked(), "W0-B remains locked")
	check(_present("pt_elias_ward") and not _present(MARA), "Elias returns once Mara's scene ends")
	var saved: String = _canonical(SaveManager.capture_state())
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save after referral")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load after referral")
	await runner.get_tree().process_frame
	check_eq(_canonical(SaveManager.capture_state()), saved, "post-referral roundtrip exact")
	check(_present("pt_elias_ward") and not _present(MARA), "presence restored from the save")
	check_eq(PatientManager.get_notes(MARA).size(), 1, "note preserved, not duplicated")


func test_interrupted_interview_resumes_from_its_saved_state() -> void:
	await _reach_mara()
	_approach(MARA)
	_ask("role_clarity")
	_ask("ask_origin")
	_ask("ask_explanation")
	_ask("ask_sleep")
	_ask("ask_safety")
	DialogueManager.end_dialogue()
	var saved: String = _canonical(SaveManager.capture_state())
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save mid-interview")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load mid-interview from a fresh game")
	await runner.get_tree().process_frame
	check_eq(_canonical(SaveManager.capture_state()), saved, "mid-interview roundtrip exact")
	check(_present(MARA) and not _present("pt_elias_ward"), "Mara still in the interview room after load")
	check_eq(_objective(), "obj_ch2_mara_interview", "interview objective still open")
	check_eq(PatientManager.get_state(MARA)["observations"].size(), 3, "recorded findings kept")
	_approach(MARA)
	var choices: Array[String] = []
	for choice: Dictionary in DialogueManager.get_choices():
		choices.append(choice["id"])
	check("ask_mood_history" in choices and not "role_clarity" in choices, "resumes at the remaining modules")
	_ask("ask_sleep")
	check_eq(PatientManager.get_state(MARA)["observations"].size(), 3, "repeated question records nothing twice")
	for module: String in ["ask_mood_history", "ask_alternatives", "ask_collateral"]:
		_ask(module)
	DialogueManager.end_dialogue()
	check_eq(_objective(), "obj_ch2_mara_note", "resumed interview completes")


func test_saves_from_before_mara_existed_still_load() -> void:
	await _reach_mara()
	var data: Dictionary = PatientManager.to_save_data()
	var elias: String = _canonical(data["pt_elias_ward"])
	data.erase(MARA)
	PatientManager.load_save_data(data)
	check_eq(_canonical(PatientManager.get_state("pt_elias_ward")), elias, "existing patient state restored")
	check(PatientManager.get_state(MARA)["observations"].is_empty(), "Mara starts fresh when an older save lacks her")
	check(PatientManager.get_notes(MARA).is_empty(), "no note invented for her")


func test_presence_conditions_validate_like_story_conditions() -> void:
	var problems: Array[String] = []
	var docs: Dictionary = ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)
	check(problems.is_empty(), "authored documents parse")
	check(ContentValidator.validate_documents(docs)["errors"].is_empty(), "shipped presence conditions are valid")
	var world: Dictionary = docs[ContentRegistry.WORLD_KEY + "ch2"]["data"]
	world["characters"][-1]["present_when"] = {"not": {"flag_typo": "x"}}
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "present_when", "bad presence condition is reported")


func _canonical(data: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))
