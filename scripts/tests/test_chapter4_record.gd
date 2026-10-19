extends TestCase
## Chapter 4 Scenes 01, 02, 03 and 05: separate incident files, the corrected
## summary, Rahman's clinical boundary and the outside review of the originals.

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


const PROP: String = "Corridor_CCTV_5"
const SECURITY: String = "zone_security_admin"


func _reach_lobby() -> void:
	await _reach_witness()
	_talk_tech("Did you actually see anyone")
	_talk_tech("Ask which work orders")
	check_eq(_objective(), "obj_ch2_lobby_escort", "lobby inspection follows the witness")


func _zones() -> ZoneDirector:
	return _main.get_node("ZoneDirector")


func _player() -> FirstPersonController:
	return _main.get_node("Player")


func _enter_security() -> void:
	_player().place(Vector3(0.0, 0.05, -18.5), 0.0)
	_zones().update_now()
	for i: int in 600:
		if _world().has_zone(SECURITY):
			break
		await runner.get_tree().process_frame
		_zones().update_now()
	check(_world().has_zone(SECURITY), "security wing streams once the pass opens the route")
	var entry: ImportedDoor = _world().get_door("door_ward_entry")
	if not entry.is_open:
		entry.get_leaves()[0].get_node("Interactable").interact(_player())
	check(entry.is_open, "ward entry opens on the escorted pass")
	_player().place(Vector3(0.0, 0.05, -38.5), PI)
	await wait_physics_frames(2)
	_zones().update_now()
	check_eq(_zones().current_zone_id, SECURITY, "player stands in the security corridor")


func _leave_security() -> void:
	_player().place(Vector3(0.0, 0.05, -10.0), PI)
	await wait_physics_frames(2)
	_zones().update_now()
	check_eq(_zones().current_zone_id, "zone_clinical_wing", "back in the clinical wing")


func _reach_wrong_day() -> void:
	await _reach_lobby()
	_talk_hale("Accept an escorted look")
	await _enter_security()
	_commit(PROP, "Note the time")
	_commit(PROP, "Document the state")
	await _leave_security()
	_talk_hale("return the escorted pass")
	check_eq(_objective(), "obj_ch2_wrongday_frame", "wrong-day file follows the lobby")


func _reach_hours() -> void:
	await _reach_wrong_day()
	_commit(RECORDS, "belongs in the authorized incident record")
	_commit(RECORDS, "Preserve the separate source versions")
	check_eq(_objective(), "obj_ch2_hours_report", "closing beat follows the wrong-day file")


func _bennett(choice: String) -> void:
	_approach("staff_bennett")
	_choose(choice)
	_close()


func _finish_ch2() -> void:
	await _reach_hours()
	_commit(RECORDS, "Then the report should say that")
	_approach("staff_bennett")
	_choose("records we can't reconcile yet")
	_choose("Leave it for now")
	_choose("Head out")
	check(_director().has_completed("ch2"), "Chapter 2 complete")
	_choose("Return for the next day shift")
	await runner.get_tree().process_frame
	check_eq(_director().get_chapter_id(), "ch3", "Chapter 3 starts from Chapter 2's close")
	check_eq(TimeManager.get_shift(), "day", "a new day shift")
	check_eq(_objective(), "obj_ch3_notice", "Chapter 3 opens on the inspection notice")


func _notice(choice: String) -> void:
	_approach("staff_bennett")
	_choose(choice)
	_close()


const HISTORIC: String = "zone_historic_sublevel"
const WARD_ZERO: String = "zone_ward_zero"


func _briefed() -> void:
	await _finish_ch2()
	_notice("Confirm who covers")
	_notice("Read the audit summary")
	_notice("Only the part related to clinical transfers")
	_talk_hale("What is the specific clinical question")
	_talk_hale("Review the boundaries")
	check_eq(_objective(), "obj_ch3_descent", "descent follows the briefing")


func _connect(connection_id: String, from_zone: String) -> void:
	check(_zones().use_connection(connection_id, from_zone), "%s used" % connection_id)
	while _zones().in_transition:
		await runner.get_tree().process_frame


func _descend() -> void:
	await _briefed()
	check(not _zones().use_connection("conn_service_hatch", SECURITY), "hatch locked before the team pass")
	_talk_hale("Go down with the team")
	check(TrustManager.has_access("access_maintenance"), "team pass covers the hatch")
	await _enter_security()
	await _connect("conn_service_hatch", SECURITY)
	check_eq(_zones().current_zone_id, HISTORIC, "down the stair to the historic sublevel")


func _inside() -> void:
	await _descend()
	_commit("SW_FuseBoard", "So the drawing might differ")
	_commit("MC_FuseBoard_Isolated", "Wait for clearance")
	await _connect("conn_w0_threshold", HISTORIC)
	for choice: String in ["Compare the current map", "Check the authorized signage", "Document the entrance", "Verify the return route"]:
		_commit("W0T_EnamelPlate", choice)
	check_eq(_objective(), "obj_ch3_alcove", "alcove follows the entry")


func _returned() -> void:
	await _inside()
	_commit("W0C_Radiator_0", "Preserve the discrepancy")
	_commit("W0C_ClockA", "Is it the same tile")
	_commit("W0C_ClockA", "record the ambiguity exactly")
	await _connect("conn_w0_threshold", WARD_ZERO)
	await _connect("conn_service_hatch", HISTORIC)
	await _leave_security()
	_talk_hale("Return the team pass")
	check_eq(_objective(), "obj_ch3_debrief", "debrief follows the return")


func _voss(choice: String) -> void:
	_approach("staff_voss")
	_choose(choice)
	_close()


func _unchanged(flags: Array, why: String) -> void:
	check_eq(_director().get_chapter_flags("ch3"), flags, why)


func _finish_ch3() -> void:
	await _returned()
	_talk_hale("shouldn't call that a physical loop")
	_notice("The survey raised more questions")
	_commit(OFFICE, "reliable contradiction")
	for choice_text: String in ["Mark the difference", "Request a controlled measurement", "Confirm the area stays restricted"]:
		_commit(RECORDS, choice_text)
	_voss("Submit the report")
	_use(OFFICE)
	_choose("Log the photograph for authorized review")
	check(_director().has_completed("ch3"), "Chapter 3 complete")
	_choose("Return for the next day shift")
	await runner.get_tree().process_frame
	check_eq(_director().get_chapter_id(), "ch4", "Chapter 4 starts")
	check_eq(_objective(), "obj_ch4_meeting", "Chapter 4 opens on Voss's meeting")


func _rahman(choice: String) -> void:
	_approach("staff_rahman")
	_choose(choice)
	_close()


func _run_ch4(meeting: String, flag: String) -> void:
	await _finish_ch3()
	var patients: String = _canonical(PatientManager.to_save_data())
	var evidence: String = _canonical(EvidenceManager.to_save_data())
	var access: String = _canonical(TrustManager.to_save_data())
	var flags: Array = _director().get_chapter_flags("ch4")
	_voss("Propose one combined")
	check_eq(_director().get_chapter_flags("ch4"), flags, "cases stay separate")
	_voss(meeting)
	check(_director().has_flag(flag), "meeting emphasis: " + flag)
	flags = _director().get_chapter_flags("ch4")
	_commit(OFFICE, "Leave \"confirmed mapping error\"")
	_commit(OFFICE, "anomalous geometry confirmed")
	check_eq(_director().get_chapter_flags("ch4"), flags, "only supported wording is final")
	_commit(OFFICE, "State the observed contradiction")
	flags = _director().get_chapter_flags("ch4")
	_rahman("Suggest the corridor report")
	check_eq(_director().get_chapter_flags("ch4"), flags, "distress is not building evidence")
	_rahman("old psychiatric diagnosis")
	flags = _director().get_chapter_flags("ch4")
	_commit(RECORDS, "Exclude the original")
	check_eq(_director().get_chapter_flags("ch4"), flags, "no original excluded")
	_commit(RECORDS, "preserve them both")
	check(_director().has_flag("ch4_paper_trail_preserved"), "contradiction preserved")
	check_eq(_objective(), "obj_ch4_test_pass", "door check follows the review")
	check(not _director().has_completed("ch4"), "Chapter 4 not falsely complete")
	check_eq(_canonical(PatientManager.to_save_data()), patients, "no clinical change")
	check_eq(_canonical(EvidenceManager.to_save_data()), evidence, "no evidence created")
	check_eq(_canonical(TrustManager.to_save_data()), access, "no access granted")
	var saved: String = _state()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save in Chapter 4")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load in Chapter 4")
	await runner.get_tree().process_frame
	check_eq(_state(), saved, "Chapter 4 roundtrip exact")


func test_transparent_findings() -> void:
	await _run_ch4("Preserve transparent findings", "ch4_meeting_transparent")


func test_access_restrictions() -> void:
	await _run_ch4("Focus on the access restrictions", "ch4_meeting_restrictions")


func test_outside_expertise() -> void:
	await _run_ch4("Request outside expertise", "ch4_meeting_outside_expertise")


func _state() -> String:
	var state: Dictionary = SaveManager.capture_state()
	var position: Array = state["world"]["player"]["position"]
	position[1] = snappedf(float(position[1]), 0.01)
	return _canonical(state)


func _canonical(data: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))
