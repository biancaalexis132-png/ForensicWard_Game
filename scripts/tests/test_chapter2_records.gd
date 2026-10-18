extends TestCase
## Real Chapter 2 source review, including unsupported inference and saved care.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const RECORDS: String = "AR_Document_WardRoster1968"
const OFFICE: String = "OF_Document_TransferSummary"
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


func _use(prop: String) -> void:
	var world: AuthoredWorld = _main.get_node("World")
	var target: ImportedInteractable = world.get_interactable(prop)
	check(target != null, "real prop resolves: " + prop)
	if target != null:
		target.interactable.interact(_main.get_node("Player"))


func _talk() -> void:
	var world: AuthoredWorld = _main.get_node("World")
	world.get_character("staff_bennett").get_node("Interactable").interact(_main.get_node("Player"))


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


func _finish_opening() -> void:
	_use("NS_NoticeBoard")
	_close()
	_use("NS_NoticeBoard")
	_choose("next day shift")
	await runner.get_tree().process_frame
	check_eq(_director().get_chapter_id(), "ch2", "actual chapter continuation")
	_talk()
	_close()
	_commit("NS_NoticeBoard", "Retain responsibility")
	_commit(RECORDS, "unresolved")
	_commit(OFFICE, "Submit preservation")
	_talk()
	_choose("Acknowledge the outstanding")
	_close()
	check(_director().has_flag("ch2_opening_complete"), "real opening completed")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_clock_review", "fresh review objective")


func _review_sources() -> void:
	_commit(RECORDS, "Keep the correction unknown")
	_commit(RECORDS, "Retain the repeated row")
	_commit(OFFICE, "Leave independence unestablished")
	_commit(OFFICE, "Keep preservation confirmation")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_review_memo", "all source questions reviewed")


func _complete_review(choice: String, flag: String) -> void:
	# Reuse existing authored findings to prove populated records survive.
	check(PatientManager.record_observation("pt_elias_ward", "obs_mutism", "physician"), "record existing authored finding")
	check(not PatientManager.save_note("pt_elias_ward", ["obs_mutism"] as Array[String], [] as Array[String],
			"Fixture: follow-up remains assigned.").is_empty(), "existing clinical note fixture")
	var patient: String = _canonical(PatientManager.to_save_data())
	var evidence: String = _canonical(EvidenceManager.to_save_data())
	await _finish_opening()
	_review_sources()
	_commit(RECORDS, choice)
	check(_director().has_flag(flag), "selected follow-up retained")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_review_return", "handoff remains explicit")
	_talk()
	_choose("Acknowledge the records follow-up")
	_close()
	check(_director().has_flag("ch2_records_review_complete"), "records slice can complete")
	check(_director().get_current_objective().is_empty(), "current authored objectives complete")
	check(not _director().has_completed("ch2"), "does not falsely finish full Chapter 2")
	check_eq(_canonical(PatientManager.to_save_data()), patient, "populated clinical notes/findings/audit retained exactly")
	check_eq(_canonical(EvidenceManager.to_save_data()), evidence, "no independent evidence or authentication invented")
	check((_main.get_node("World") as AuthoredWorld).get_door("door_w0b").is_locked(), "restricted door remains locked")
	var saved: String = _canonical(SaveManager.capture_state())
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save completed review")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load completed review")
	await runner.get_tree().process_frame
	check_eq(_canonical(SaveManager.capture_state()), saved, "full completed-review save roundtrip")


func test_clock_focused_followup_completes_with_clinical_state_intact() -> void:
	await _complete_review("Prioritize clock authority", "ch2_followup_clock_authority")
	check(not _director().has_flag("ch2_followup_source_lineage"), "one chosen emphasis")


func test_lineage_focused_followup_preserves_the_same_required_questions() -> void:
	await _complete_review("Prioritize source lineage", "ch2_followup_source_lineage")
	check(not _director().has_flag("ch2_followup_clock_authority"), "alternative emphasis retained")


func test_unsupported_inferences_give_feedback_without_advancing_or_mutating_state() -> void:
	await _finish_opening()
	var patient: String = _canonical(PatientManager.to_save_data())
	var evidence: String = _canonical(EvidenceManager.to_save_data())
	var stages: Array = [
		[RECORDS, "Apply a four-minute", "Keep the correction unknown", "obj_ch2_clock_review"],
		[RECORDS, "Classify the repeated minute", "Retain the repeated row", "obj_ch2_order_review"],
		[OFFICE, "Count another copy", "Leave independence unestablished", "obj_ch2_dependency_review"],
		[OFFICE, "Mark the originals as preserved", "Keep preservation confirmation", "obj_ch2_preservation_review"],
	]
	for stage: Array in stages:
		var state: String = _canonical(_director().to_save_data())
		_commit(stage[0], stage[1])
		check_eq(_canonical(_director().to_save_data()), state, "unsupported inference does not set any progress flag")
		check_eq(_director().get_current_objective().get("id", ""), stage[3], "safe retry remains on current task")
		check_eq(_canonical(PatientManager.to_save_data()), patient, "feedback cannot change clinical state")
		check_eq(_canonical(EvidenceManager.to_save_data()), evidence, "feedback cannot promote evidence")
		_commit(stage[0], stage[2])


func test_partial_review_and_preexisting_opening_saves_resume_without_replaying_work() -> void:
	await _finish_opening()
	# Same provider shape as an opening-only save: no review flags yet.
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save at prior increment boundary")
	_commit(RECORDS, "Keep the correction unknown")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load opening-only save")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_clock_review", "new task does not auto-complete")
	check(not _director().has_flag("ch2_clock_reviewed"), "review choice rolls back to saved boundary")
	_commit(RECORDS, "Keep the correction unknown")
	var state: String = _canonical(SaveManager.capture_state())
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save mid-review")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load mid-review from Chapter 1")
	await runner.get_tree().process_frame
	check_eq(_canonical(SaveManager.capture_state()), state, "mid-review exact roundtrip")
	_use(RECORDS)
	check("export" in _body().to_lower(), "same prop now offers export-order task")
	_choose("Retain the repeated row")
	_close()
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_dependency_review", "loaded task advances normally")


func test_committed_memo_is_read_only_and_stale_options_cannot_change_emphasis() -> void:
	await _finish_opening()
	_review_sources()
	_commit(RECORDS, "Prioritize clock authority")
	var state: String = _canonical(_director().to_save_data())
	_use(RECORDS)
	check("unresolved memo" in _body().to_lower(), "completed prop displays retained memo")
	check(not "Prioritize" in _body(), "old choice text is not offered as a new decision")
	EventBus.story_option_selected.emit("interaction_ch2_review_memo", "prioritize_lineage")
	check_eq(_canonical(_director().to_save_data()), state, "memo cannot be rewritten by stale choice")
	_close()
	_use(OFFICE)
	check("outstanding" in _body().to_lower(), "completed workstation still gives request status")


func test_expired_interaction_rechecks_eligibility_before_committing() -> void:
	await _finish_opening()
	_use(RECORDS)
	_director().set_flag("ch2_clock_reviewed")  # Simulate another event completing the displayed step.
	var state: String = _canonical(_director().to_save_data())
	EventBus.story_option_selected.emit("interaction_ch2_clock_review", "retain_unknown")
	check_eq(_canonical(_director().to_save_data()), state, "expired displayed choice does not reapply work")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_order_review", "next stage remains current")


func test_expiry_conditions_validate_and_feedback_options_need_no_progress_flag() -> void:
	var problems: Array[String] = []
	var docs: Dictionary = ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)
	check(problems.is_empty(), "authored documents parse")
	var clean: Dictionary = ContentValidator.validate_documents(docs)
	check(clean["errors"].is_empty(), "feedback-only choices are valid: " + str(clean["errors"]))
	var story: Dictionary = docs[ContentRegistry.STORY_KEY + "ch2"]["data"]
	story["interactions"][4]["expires_when"] = {"zone": "zone_unknown_review"}
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "zone_unknown_review", "expiry reference checked")
	check_contains(report["errors"], "expires_when", "error points to expiry field")


func _canonical(data: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))
