extends TestCase
## Actual playable opening through imported props, displayed buttons and saves.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
var _main: Main


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	ContentRegistry.load_all(ContentRegistry.DATA_DIR)
	SaveManager.delete_save(98)
	super.after_each()


func _director() -> ChapterDirector:
	return _main.get_node("ChapterDirector")


func _world() -> AuthoredWorld:
	return _main.get_node("World")


func _use(node_name: String) -> void:
	var controller: ImportedInteractable = _world().get_interactable(node_name)
	check(controller != null, "wired prop: " + node_name)
	if controller != null:
		controller.interactable.interact(_main.get_node("Player"))


func _talk() -> void:
	_world().get_character("staff_bennett").get_node("Interactable").interact(_main.get_node("Player"))


func _close() -> void:
	(_main.get_node("InfoPanel") as InfoPanel).close()


func _choose(text_fragment: String) -> void:
	for node: Node in _main.get_node("InfoPanel").find_children("*", "Button", true, false):
		if text_fragment in node.text:
			node.pressed.emit()
			return
	check(false, "displayed choice not found: " + text_fragment)


func _enter_opening() -> void:
	_use("NS_NoticeBoard")
	_close()
	_use("NS_NoticeBoard")
	_choose("next day shift")
	await runner.get_tree().process_frame
	check_eq(_director().get_chapter_id(), "ch2", "entered real Chapter 2")


func test_next_shift_requires_explicit_choice_and_preserves_clinical_records() -> void:
	_use("NS_NoticeBoard")
	_close()
	_use("NS_NoticeBoard")
	check_eq(_director().get_chapter_id(), "ch1", "sign-out does not auto-enter next chapter")
	var patient: String = JSON.stringify(PatientManager.to_save_data())
	var evidence: String = JSON.stringify(EvidenceManager.to_save_data())
	_choose("next day shift")
	await runner.get_tree().process_frame
	check_eq(_director().get_chapter_id(), "ch2", "explicit continuation")
	check(_director().has_completed("ch1"), "prior chapter completion retained")
	check_eq(TimeManager.get_day(), 2, "next day")
	check_eq(TimeManager.get_shift(), "day", "morning handoff")
	check_eq(JSON.stringify(PatientManager.to_save_data()), patient, "no new clinical finding or record")
	check_eq(JSON.stringify(EvidenceManager.to_save_data()), evidence, "no new evidence inferred")
	check_eq(_world().chapter_id, "ch2", "world wiring follows chapter")
	check(_world().unresolved.is_empty(), "all real prop markers resolve")
	check_eq(_world().get_interactable("NS_NoticeBoard").kind, "story_terminal", "board becomes worklist")
	check(_world().get_interactable("W0B_AccessPanel") == null, "no Chapter 1 access-log replay")
	check(_world().get_character("pt_elias_ward") != null, "existing patient remains approachable")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_handoff", "fresh handoff objective")


func test_opening_is_playable_in_order_without_invented_findings() -> void:
	await _enter_opening()
	var patient: String = JSON.stringify(PatientManager.to_save_data())
	var evidence: String = JSON.stringify(EvidenceManager.to_save_data())
	_use("AR_Document_WardRoster1968")
	EventBus.story_option_selected.emit("interaction_ch2_export", "record_unresolved")
	check(not _director().has_flag("ch2_discrepancy_recorded"), "cannot bypass work ownership")
	_talk()
	_close()
	_use("NS_Terminal_EHR")
	check((_main.get_node("EHRScreen") as EHRScreen).is_open, "existing EHR still works")
	(_main.get_node("EHRScreen") as EHRScreen).close()
	check_eq(PatientManager.get_state("pt_elias_ward")["audit"].size(), 1, "EHR logs one record-open event")
	check(PatientManager.get_state("pt_elias_ward")["observations"].is_empty(), "opening EHR creates no finding")
	patient = JSON.stringify(PatientManager.to_save_data())
	_use("NS_NoticeBoard")
	check(not _director().has_flag("ch2_clinical_work_owned"), "opening worklist alone does not assign work")
	_choose("Retain responsibility")
	_close()
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_export", "next: source comparison")
	_use("AR_Document_WardRoster1968")
	_choose("unresolved")
	_close()
	_use("OF_Document_TransferSummary")
	_choose("Submit preservation")
	_close()
	_talk()
	_choose("Acknowledge")
	check(_director().has_flag("ch2_opening_complete"), "actual slice can finish")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_clock_review", "opening advances to source review")
	check(not _director().has_completed("ch2"), "opening is not the whole chapter")
	check_eq(JSON.stringify(PatientManager.to_save_data()), patient, "clinical state unchanged by audit")
	check_eq(JSON.stringify(EvidenceManager.to_save_data()), evidence, "request is not authenticated evidence")
	check(_world().get_door("door_w0b").is_locked(), "actual Ward Zero door remains locked")
	check(_world().get_door("door_ward_entry").is_locked(), "ward entry remains controlled")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save completed opening")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "reload completed opening")
	check(_director().has_flag("ch2_opening_complete"), "completion persists")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_clock_review", "opening stays complete and source review remains pending")


func test_partial_opening_save_rebuilds_correct_world_and_objective() -> void:
	await _enter_opening()
	_talk()
	_close()
	_use("NS_NoticeBoard")
	_choose("Retain responsibility")
	_close()
	var state: String = _canonical(SaveManager.capture_state())
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save mid-opening")
	SaveManager.reset_all()
	await runner.get_tree().process_frame
	check_eq(_world().chapter_id, "ch1", "new game restores Chapter 1 wiring")
	check_eq(_world().get_interactable("NS_NoticeBoard").kind, "shift_signout", "old board works again")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load Chapter 2 from Chapter 1")
	await runner.get_tree().process_frame
	check_eq(_world().chapter_id, "ch2", "correct world on load")
	check_eq(_director().get_current_objective().get("id", ""), "obj_ch2_export", "pending objective restored")
	check_eq(_canonical(SaveManager.capture_state()), state, "entire save roundtrip unchanged")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "same-chapter load")
	check_eq(_canonical(SaveManager.capture_state()), state, "same-chapter reload idempotent")


func test_loading_chapter1_after_opening_restores_legacy_interactions() -> void:
	check_eq(SaveManager.save_game(98), OK, "save Chapter 1")
	await _enter_opening()
	check_eq(SaveManager.load_game(98), OK, "return to Chapter 1 save")
	await runner.get_tree().process_frame
	check_eq(_director().get_chapter_id(), "ch1", "chapter restored")
	check_eq(_world().chapter_id, "ch1", "world restored")
	check_eq(_world().get_interactable("OF_Document_TransferSummary").kind, "clue_pickup", "original document interaction restored")
	check_eq(_director().get_current_objective().get("id", ""), "obj_meet_bennett", "original objective restored")


func test_story_choice_replay_and_stale_load_cannot_finish_work() -> void:
	await _enter_opening()
	_talk()
	_close()
	_use("NS_NoticeBoard")
	_choose("Retain responsibility")
	var state: String = JSON.stringify(_director().to_save_data())
	EventBus.story_option_selected.emit("interaction_ch2_worklist", "retain_review")
	check_eq(JSON.stringify(_director().to_save_data()), state, "double click is idempotent")
	_close()
	_use("AR_Document_WardRoster1968")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save with open choice")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "restore clears pending UI authorization")
	EventBus.story_option_selected.emit("interaction_ch2_export", "record_unresolved")
	check(not _director().has_flag("ch2_discrepancy_recorded"), "old panel cannot mutate loaded state")


func test_closed_choices_cannot_commit_and_next_shift_is_always_morning() -> void:
	_use("NS_NoticeBoard")
	_close()
	_use("NS_NoticeBoard")
	_close()
	EventBus.story_option_selected.emit("continue:ch1", "continue")
	check_eq(_director().get_chapter_id(), "ch1", "closing continuation cancels its authorization")
	TimeManager.jump_to_shift(3, "day")
	_use("NS_NoticeBoard")
	_choose("next day shift")
	await runner.get_tree().process_frame
	check_eq(TimeManager.get_day(), 4, "late continuation uses following morning")
	check_eq(TimeManager.get_shift(), "day", "never starts Chapter 2 at night")
	_talk()
	_close()
	_use("NS_NoticeBoard")
	_close()
	EventBus.story_option_selected.emit("interaction_ch2_worklist", "retain_review")
	check(not _director().has_flag("ch2_clinical_work_owned"), "closed worklist cannot assign work")


func test_story_interactions_validate_references_and_options() -> void:
	var problems: Array[String] = []
	var docs: Dictionary = ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)
	check(problems.is_empty(), "real content parses")
	var story: Dictionary = docs[ContentRegistry.STORY_KEY + "ch2"]["data"]
	story["interactions"][0]["interactable_id"] = "MISSING_PROP"
	story["interactions"][1]["when"] = {"zone": "zone_missing"}
	story["interactions"][2]["options"].append(story["interactions"][2]["options"][0].duplicate(true))
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "MISSING_PROP", "missing interaction target rejected")
	check_contains(report["errors"], "zone_missing", "condition refs checked")
	check_contains(report["errors"], "duplicate", "duplicate option IDs rejected")


func _canonical(data: Dictionary) -> String:
	# Godot's JSON reader represents numbers as floats; compare normalized
	# serialized state so 1860 vs 1860.0 does not hide an actual state difference.
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))
