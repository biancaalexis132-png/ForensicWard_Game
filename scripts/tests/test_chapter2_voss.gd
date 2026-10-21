extends TestCase
## Chapter 2 Scene 04: Voss's institutional review through the real staff actor,
## displayed buttons and saves. Scope, permissions and follow-up are recorded;
## the source request, credential audit and W0-B restriction stay pending.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const RECORDS: String = "AR_Document_WardRoster1968"
const OFFICE: String = "OF_Document_TransferSummary"
const VOSS_FLAGS: Array[String] = ["ch2_voss_scope_recorded", "ch2_voss_permissions_recorded",
		"ch2_voss_followup_written_process", "ch2_voss_followup_independent_review"]
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


func _talk(staff_id: String) -> void:
	var actor: Node = _world().get_character(staff_id)
	check(actor != null, "real staff actor placed: " + staff_id)
	if actor != null:
		actor.get_node("Interactable").interact(_main.get_node("Player"))


func _choose(text: String) -> void:
	for button: Node in _main.get_node("InfoPanel").find_children("*", "Button", true, false):
		if text in button.text:
			button.pressed.emit()
			return
	check(false, "displayed choice missing: " + text)


## Story choices on screen (the panel's own close button excluded).
func _buttons() -> Array[String]:
	var labels: Array[String] = []
	for button: Node in _main.get_node("InfoPanel").find_children("*", "Button", true, false):
		if button.name != "CloseButton" and (button as Button).is_visible_in_tree():
			labels.append((button as Button).text)
	return labels


func _close() -> void:
	(_main.get_node("InfoPanel") as InfoPanel).close()


func _body() -> String:
	return (_main.get_node("InfoPanel/Root/Panel/Margin/VBox/Body") as RichTextLabel).get_parsed_text()


func _commit(prop: String, choice: String) -> void:
	_use(prop)
	_choose(choice)
	_close()


func _say(choice: String) -> void:
	_talk("staff_voss")
	_choose(choice)
	_close()


func _objective() -> String:
	return _director().get_current_objective().get("id", "")


func _finish_records_review() -> void:
	_use("NS_NoticeBoard")
	_close()
	_use("NS_NoticeBoard")
	_choose("next day shift")
	await runner.get_tree().process_frame
	check_eq(_director().get_chapter_id(), "ch2", "actual chapter continuation")
	_talk("staff_bennett")
	_close()
	_commit("NS_NoticeBoard", "Retain responsibility")
	_commit(RECORDS, "unresolved")
	_commit(OFFICE, "Submit preservation")
	_talk("staff_bennett")
	_choose("Acknowledge the outstanding")
	_close()
	_commit(RECORDS, "Keep the correction unknown")
	_commit(RECORDS, "Retain the repeated row")
	_commit(OFFICE, "Leave independence unestablished")
	_commit(OFFICE, "Keep preservation confirmation")
	_commit(RECORDS, "Prioritize clock authority")
	_talk("staff_bennett")
	_choose("Acknowledge the records follow-up")
	_close()
	check(_director().has_flag("ch2_records_review_complete"), "records review completed through real props")
	check_eq(_objective(), "obj_ch2_voss_scope", "Voss review is the next objective")


## Everything the conversation must leave untouched, as canonical text.
func _untouched_state() -> Dictionary:
	return {"patient": _canonical(PatientManager.to_save_data()), "evidence": _canonical(EvidenceManager.to_save_data()),
			"trust": _canonical(TrustManager.to_save_data())}


func _check_boundaries(before: Dictionary, label: String) -> void:
	check_eq(_untouched_state(), before, label + ": clinical records, evidence and access unchanged")
	check(_director().has_flag("ch2_sources_requested"), label + ": source request still recorded")
	check(_world().get_door("door_w0b").is_locked(), label + ": W0-B remains locked")
	check(not _director().has_completed("ch2"), label + ": Chapter 2 not falsely completed")


func _run_review(choice: String, flag: String, other_flag: String) -> void:
	check(PatientManager.record_observation("pt_elias_ward", "obs_mutism", "physician"), "record existing authored finding")
	check(not PatientManager.save_note("pt_elias_ward", ["obs_mutism"] as Array[String], [] as Array[String],
			"Fixture: follow-up remains assigned.").is_empty(), "existing clinical note fixture")
	await _finish_records_review()
	var before: Dictionary = _untouched_state()
	# Each step offers unsupported claims that give feedback and change nothing.
	var steps: Array = [
		["Say someone deliberately", "Say the export proves", "State only what is established", "obj_ch2_voss_scope", "ch2_voss_scope_recorded"],
		["inspect W0-B yourself", "direct access to the raw source", "Record the missing permissions", "obj_ch2_voss_permissions", "ch2_voss_permissions_recorded"],
		["urgent patient-safety", "", choice, "obj_ch2_voss_followup", flag],
	]
	for step: Array in steps:
		for feedback: String in [step[0], step[1]]:
			if feedback.is_empty():
				continue
			# Talking registers Voss as talked-to on first contact; only flags count as progress.
			var flags: Array = _director().get_chapter_flags("ch2")
			_say(feedback)
			check_eq(_director().get_chapter_flags("ch2"), flags, "unsupported claim sets no flag: " + feedback)
			check_eq(_objective(), step[3], "conversation stays on the current step")
		_say(step[2])
		check(_director().has_flag(step[4]), "step recorded: " + step[4])
		_check_boundaries(before, step[4])
	check(not _director().has_flag(other_flag), "only the chosen follow-up is recorded")
	check_eq(_objective(), "obj_ch2_mara_interview", "Voss review hands on to Mara's interview")
	# Post-choice save/load restores the decision exactly.
	var saved: String = _canonical(SaveManager.capture_state())
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save after the follow-up choice")
	SaveManager.reset_all()
	check_eq(_director().get_chapter_id(), "ch1", "reset returns to a fresh game")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load after the follow-up choice")
	await runner.get_tree().process_frame
	check_eq(_canonical(SaveManager.capture_state()), saved, "post-choice save roundtrip is exact")
	check_eq(_world().chapter_id, "ch2", "Chapter 2 wiring restored")
	_check_boundaries(before, "after load")
	_talk("staff_voss")
	check("in writing" in _body(), "Voss gives the read-only follow-up status")
	check(_buttons().is_empty(), "no decision is offered again")
	var state: String = _canonical(_director().to_save_data())
	EventBus.story_option_selected.emit("interaction_ch2_voss_followup", other_flag.trim_prefix("ch2_voss_followup_"))
	check_eq(_canonical(_director().to_save_data()), state, "stale option cannot rewrite the saved follow-up")
	_close()


func test_voss_waits_for_records_memo_and_grants_nothing() -> void:
	_use("NS_NoticeBoard")
	_close()
	_use("NS_NoticeBoard")
	_choose("next day shift")
	await runner.get_tree().process_frame
	var trust: String = _canonical(TrustManager.to_save_data())
	_talk("staff_voss")
	check("Clinical work first" in _body(), "Voss defers to clinical work before the memo")
	check(_buttons().is_empty(), "no review choices before the records memo")
	_close()
	for flag: String in VOSS_FLAGS:
		check(not _director().has_flag(flag), "no Voss progress early: " + flag)
	check_eq(_objective(), "obj_ch2_handoff", "opening objective unchanged by early talk")
	check_eq(_canonical(TrustManager.to_save_data()), trust, "talking to Voss grants no access")
	EventBus.story_option_selected.emit("interaction_ch2_voss_scope", "state_scope")
	check(not _director().has_flag("ch2_voss_scope_recorded"), "undisplayed scope choice is rejected")


func test_written_process_followup_records_scope_permissions_and_keeps_request_pending() -> void:
	await _run_review("Request the written escalation process", "ch2_voss_followup_written_process",
			"ch2_voss_followup_independent_review")


func test_independent_reconciliation_followup_keeps_the_same_boundaries() -> void:
	await _run_review("Propose an independent records reconciliation", "ch2_voss_followup_independent_review",
			"ch2_voss_followup_written_process")


func test_interrupted_conversation_resumes_at_the_saved_step() -> void:
	await _finish_records_review()
	var before: Dictionary = _untouched_state()
	# Walking away (closing the panel) abandons the displayed choice.
	_talk("staff_voss")
	check("actually established" in _body(), "Voss opens the scope step")
	_close()
	EventBus.story_option_selected.emit("interaction_ch2_voss_scope", "state_scope")
	check(not _director().has_flag("ch2_voss_scope_recorded"), "closed conversation cannot be answered later")
	_say("State only what is established")
	# Save with the next step on screen, then load: the open choice must not survive.
	_talk("staff_voss")
	check("separate the owners" in _body(), "permissions step displayed")
	var saved: String = _canonical(SaveManager.capture_state())
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save mid-conversation")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load mid-conversation from a fresh game")
	await runner.get_tree().process_frame
	check_eq(_canonical(SaveManager.capture_state()), saved, "mid-conversation roundtrip is exact")
	EventBus.story_option_selected.emit("interaction_ch2_voss_permissions", "list_permissions")
	check(not _director().has_flag("ch2_voss_permissions_recorded"), "pre-load choice cannot be applied after load")
	check(_director().has_flag("ch2_voss_scope_recorded"), "recorded scope survives the interruption")
	check_eq(_objective(), "obj_ch2_voss_permissions", "resumes at the permissions step")
	_check_boundaries(before, "interrupted")
	_talk("staff_voss")
	check(not "actually established" in _body(), "scope step is not replayed")
	_choose("Record the missing permissions")
	_close()
	# A loaded earlier save rolls back only what it predates.
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "reload the interrupted save")
	await runner.get_tree().process_frame
	check(not _director().has_flag("ch2_voss_permissions_recorded"), "later choice rolls back to the saved boundary")
	_say("Record the missing permissions")
	_talk("staff_voss")
	_close()
	EventBus.story_option_selected.emit("interaction_ch2_voss_followup", "written_process")
	check(not _director().has_flag("ch2_voss_followup_written_process"), "closed follow-up step stays open")
	check_eq(_objective(), "obj_ch2_voss_followup", "follow-up remains the current task")
	_say("Propose an independent records reconciliation")
	check(_director().has_flag("ch2_voss_followup_independent_review"), "resumed conversation completes normally")
	_check_boundaries(before, "resumed")


func _canonical(data: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))
