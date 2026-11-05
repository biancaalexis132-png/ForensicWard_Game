extends TestCase
## Case file: Tab opens it; it shows the current objective and where it
## happens, the choices the player has recorded (established, still open or
## care, in the approved response's own words), and the evidence, with
## buttons to the evidence board and the clinical journal. It keeps no state.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"

var _main: Main
var _notices: Array[String] = []


func before_each() -> void:
	super.before_each()
	_notices.clear()
	EventBus.notification_requested.connect(_on_notice)
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	EventBus.notification_requested.disconnect(_on_notice)
	AudioDirector.cancel_pending_events()
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func _on_notice(text: String) -> void:
	_notices.append(text)


func _director() -> ChapterDirector:
	return _main.get_node("ChapterDirector")


func _screen() -> CaseFileScreen:
	EventBus.ui_panel_requested.emit(CaseFileScreen.PANEL_ID, {})
	return _main.get_node("CaseFileScreen")


func _press(action: String) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


func _approach(character_id: String) -> void:
	var actor: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character(character_id)
	check(actor != null, "actor placed: " + character_id)
	if actor != null:
		actor.get_node("Interactable").interact(_main.get_node("Player"))


func _choose(text: String) -> void:
	for button: Node in _main.get_node("InfoPanel").find_children("*", "Button", true, false):
		if text in button.text:
			button.pressed.emit()
			return
	check(false, "displayed choice missing: " + text)


# --- Data ---------------------------------------------------------------------------

func test_case_file_data_is_valid_and_verbatim() -> void:
	check_eq(CaseFile.validate(), [] as Array[String], "every note names a real choice and copies its response")
	check(CaseFile.entries().size() > 50, "chapters 2 to 5 are covered")
	for status: String in CaseFile.STATUSES:
		check(CaseFile.entries().any(func(e: Dictionary) -> bool: return e["status"] == status), "some notes are " + status)


func test_personal_moments_stay_out_of_the_case_file() -> void:
	for entry: Dictionary in CaseFile.entries():
		check(not "contact_" in entry["flag"] and not "call_" in entry["flag"], "personal choice excluded: " + entry["flag"])
		check(entry["flag"] != StoryLogic.CHAPTER_COMPLETE_FLAG, "chapter completion is not a note")


# --- Screen -----------------------------------------------------------------------

func test_new_game_shows_the_first_objective_and_who_to_see() -> void:
	await runner.get_tree().process_frame
	var screen: CaseFileScreen = _screen()
	check(screen.is_open, "opens")
	check("Report to the charge nurse" in screen.get_now_text(), "current objective: " + screen.get_now_text())
	check("With Nurse Naomi Bennett" in screen.get_now_text(), "says who to see")
	check(screen.get_note_texts().is_empty(), "no notes before any choice")
	check("Collected 0 of" in screen.get_evidence_text(), "evidence count: " + screen.get_evidence_text())
	check("migration error" in screen.get_evidence_text(), "ordinary explanations still open are listed")


func test_tab_opens_the_case_file_which_leads_to_the_board() -> void:
	await runner.get_tree().process_frame
	_press("journal")
	await runner.get_tree().process_frame
	var screen: CaseFileScreen = _main.get_node_or_null("CaseFileScreen")
	check(screen != null and screen.is_open, "Tab opens the case file")
	check(not (_main.get_node("Player") as FirstPersonController).input_enabled, "player frozen")
	(screen.find_child("EvidenceBoardButton", true, false) as Button).pressed.emit()
	await runner.get_tree().process_frame
	check(not screen.is_open, "case file closes")
	check((_main.get_node("EvidenceBoard") as EvidenceBoard).is_open, "evidence board opens from the case file")
	_press("journal")
	await runner.get_tree().process_frame
	check(not (_main.get_node("EvidenceBoard") as EvidenceBoard).is_open, "Tab closes the board")
	_press("journal")
	await runner.get_tree().process_frame
	check(screen.is_open, "Tab opens the case file again")
	_press("journal")
	await runner.get_tree().process_frame
	check(not screen.is_open, "and Tab closes it")


func test_recorded_choice_becomes_a_note_with_a_notice() -> void:
	await runner.get_tree().process_frame
	check(_director().start_chapter("ch2"), "chapter 2 starts")
	_approach("staff_bennett")
	(_main.get_node("InfoPanel") as InfoPanel).close()
	var target: ImportedInteractable = (_main.get_node("World") as AuthoredWorld).get_interactable("NS_NoticeBoard")
	target.interactable.interact(_main.get_node("Player"))
	_choose("Retain responsibility")
	check("Case file updated" in _notices, "a notice says the case file changed: %s" % [_notices])
	(_main.get_node("InfoPanel") as InfoPanel).close()
	var screen: CaseFileScreen = _screen()
	var notes: Array[String] = screen.get_note_texts()
	check_eq(notes.size(), 1, "one note")
	check(notes.size() == 1 and notes[0].begins_with("You retain responsibility"), "in the response's own words")
	check("At Maintenance export comparison" in screen.get_now_text(), "next place: " + screen.get_now_text())
	screen.set_filter("open")
	check(screen.get_note_texts().is_empty(), "a care note is not listed as open")
	screen.set_filter("care")
	check_eq(screen.get_note_texts().size(), 1, "listed under care")


func test_open_questions_and_earlier_chapters_stay_in_view() -> void:
	await runner.get_tree().process_frame
	check(_director().start_chapter("ch2"), "chapter 2 starts")
	_director().set_flag("ch2_discrepancy_recorded")
	_director().set_flag("ch2_witness_account_recorded")
	_director().set_flag("ch2_contact_partner")
	check(_director().start_chapter("ch3"), "chapter 3 starts")
	_director().set_flag("ch3_levels_noted")
	var screen: CaseFileScreen = _screen()
	check_eq(screen.get_note_texts().size(), 3, "earlier chapter's notes kept, personal choice left out")
	check(screen.get_note_texts()[0].begins_with("Logged: current and historic"), "newest chapter first")
	screen.set_filter("open")
	var open: Array[String] = screen.get_note_texts()
	check_eq(open.size(), 2, "two still open")
	check(open.any(func(t: String) -> bool: return t.begins_with("Comparison recorded as unresolved")), "chapter 2 discrepancy still open")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	screen.set_filter("all")
	check_eq(screen.get_note_texts().size(), 3, "rebuilt from saved story state")


func test_objective_place_follows_unmet_parts() -> void:
	await runner.get_tree().process_frame
	check(_director().start_chapter("ch3"), "chapter 3 starts")
	check_eq(CaseFile.objective_place(_director()), "With Nurse Naomi Bennett", "inspection notice is Bennett's")
	for flag: String in ["ch3_coverage_confirmed", "ch3_audit_summary_read", "ch3_scope_clarified"]:
		_director().set_flag(flag)
	check(CaseFile.objective_place(_director()).begins_with("With ") and "Hale" in CaseFile.objective_place(_director()), "then Hale's briefing: " + CaseFile.objective_place(_director()))
	for flag: String in ["ch3_question_confirmed", "ch3_briefing_complete"]:
		_director().set_flag(flag)
	check_eq(CaseFile.objective_place(_director()), "At Stairwell fuse board (inspection log)", "then the stair")


func test_objective_target_points_at_the_same_place() -> void:
	await runner.get_tree().process_frame
	check(_director().start_chapter("ch3"), "chapter 3 starts")
	check_eq(CaseFile.objective_target(_director()), {"character": "staff_bennett"}, "the map points at Bennett")
	for flag: String in ["ch3_coverage_confirmed", "ch3_audit_summary_read", "ch3_scope_clarified", "ch3_question_confirmed", "ch3_briefing_complete"]:
		_director().set_flag(flag)
	check(CaseFile.objective_target(_director()).has("node"), "then at the fuse board prop: %s" % [CaseFile.objective_target(_director())])
	check_eq(CaseFile.objective_target(null), {}, "no director, no target")


func test_ending_closes_with_the_players_record() -> void:
	await runner.get_tree().process_frame
	check_eq(CaseFile.record_summary(_director()), "", "nothing noted: no record paragraph")
	check(_director().start_chapter("ch2"), "chapter 2 starts")
	_director().set_flag("ch2_discrepancy_recorded")
	_director().set_flag("ch2_witness_account_recorded")
	check(_director().start_chapter("ch3"), "chapter 3 starts")
	_director().set_flag("ch3_levels_noted")
	_director().set_flag("ch3_coverage_confirmed")
	var counts: Dictionary = {"established": 0, "open": 0, "care": 0}
	for note: Dictionary in CaseFile.noted(_director()):
		counts[note["status"]] += 1
	var record: String = CaseFile.record_summary(_director())
	check(record.begins_with("Your record: %d " % counts["established"]), "counts what the case file shows: " + record)
	check("%d question" % counts["open"] in record and "%d care decision" % counts["care"] in record, "open questions and care decisions counted")
	check("1 care decision that kept patients first" in record, "singular reads naturally")
	var more_open: bool = counts["open"] > counts["established"]
	check((CaseFile.RECORD_MORE_OPEN in record) == more_open, "the open-questions line only when more stayed open")
	check((CaseFile.RECORD_MORE_SETTLED in record) == (counts["established"] > counts["open"]), "the settled line only when more were settled")
	check(not CaseFile.RECORD_EVERY_CARE_STEP in record, "not every care step taken yet")
	check(_director().start_chapter("ch5"), "chapter 5 starts")
	_director().set_flag("ch5_brief_coverage")
	_director().set_flag("ch5_care_escalated")
	record = CaseFile.record_summary(_director())
	check(CaseFile.RECORD_EVERY_CARE_STEP in record, "every care step taken: the care line joins the others")
	var panel: Dictionary = _director()._campaign_end_panel("Closing response.")
	check(str(panel["body"]).ends_with(record), "the end-of-campaign panel closes with the record")
