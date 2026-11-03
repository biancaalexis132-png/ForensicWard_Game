extends TestCase
## Ward-round bedside conversation: the opening sets trust, history and mental
## state need some trust, answers fill the chart, and the debrief counts it.
## Answers are each case's own chart text; nothing here approves any wording.

const SOLVER = preload("res://scripts/tests/test_ward_rounds.gd")
const CASE_ID: String = "wr_ch1_ortiz"
var _main: Main


func before_each() -> void:
	super.before_each()
	WardRounds.enforce_gate = true


func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	WardRounds.enforce_gate = false
	WardRounds.load_catalog(WardRounds.DATA_PATH)
	super.after_each()


func _screen() -> WardRoundScreen:
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	EventBus.ui_panel_requested.emit(WardRoundScreen.PANEL_ID, {"case_id": CASE_ID})
	return _main.get_node("WardRoundScreen")


func _chart_text(screen: WardRoundScreen) -> String:
	var parts: PackedStringArray = []
	for label: RichTextLabel in screen.find_child("Chart", true, false).find_children("*", "RichTextLabel", true, false):
		parts.append(label.get_parsed_text())
	return "\n".join(parts)


func _submit_solved(screen: WardRoundScreen) -> Dictionary:
	var solved: Dictionary = SOLVER._solve(WardRounds.get_case(CASE_ID))
	for lab_id: String in solved["labs"]:
		screen.order_lab(lab_id)
	for key: String in solved["plan"]:
		var parts: PackedStringArray = key.split(":")
		if parts[0] == "start":
			screen.set_start(parts[1], true)
		elif parts[0] == "int":
			screen.set_intervention(parts[1], true)
		else:
			screen.set_med_action(parts[1], parts[0])
	return screen.submit()


func test_bedside_block_is_valid_and_problems_are_named() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WardRounds.DATA_PATH))
	check(WardRoundCatalog.validate(data).is_empty(), "catalog with the bedside block is valid")
	check_eq(data["bedside"]["review_status"], "PENDING_PSYCHIATRIST_REVIEW", "bedside wording is pending review")
	var broken: Dictionary = data["bedside"].duplicate(true)
	broken["openings"][0]["trust"] = 5
	broken["questions"][0]["field"] = "diagnosis"
	broken.erase("repair")
	var errors: String = "\n".join(WardRoundCatalog.validate_bedside(broken))
	check(errors.contains("trust 0 to 2"), "bad trust named")
	check(errors.contains("field (history, mental_status, vitals)"), "a field outside the chart is refused")
	check(errors.contains("repair: needs a label"), "missing repair named")


func test_a_warm_opening_lets_answers_fill_the_chart() -> void:
	var screen: WardRoundScreen = _screen()
	check_eq(screen._tabs.current_tab, WardRoundScreen.TABS.find("Bedside"), "a new patient opens at the bedside")
	var case: Dictionary = WardRounds.get_case(CASE_ID)
	check(not _chart_text(screen).contains(case["presentation"]["history"]), "history not on the chart before asking")
	check(_chart_text(screen).contains("Not yet heard"), "chart says what is still to ask")
	check(screen.ask("history").is_empty(), "no questions before an opening")
	(screen.find_child("Open_warm", true, false) as Button).pressed.emit()
	check(WardRounds.bedside_trust(CASE_ID) == 2, "warm opening gives full trust")
	(screen.find_child("Ask_history", true, false) as Button).pressed.emit()
	check(_chart_text(screen).contains(case["presentation"]["history"]), "history added to the chart")
	check((screen.find_child("BedsideReplies", true, false) as RichTextLabel).get_parsed_text().contains("relaxes a little"), "the patient's response is shown")
	check((screen.find_child("Ask_history", true, false) as Button).disabled, "a question is asked once")
	check(screen.open_bedside("rushed").is_empty(), "the opening cannot be changed")
	screen.select_case("wr_ch1_natarajan")
	screen.select_case(CASE_ID)
	check_eq(screen._tabs.current_tab, WardRoundScreen.TABS.find("Chart"), "a patient already spoken to opens at the chart")


func test_a_rushed_opening_holds_back_answers_until_repaired() -> void:
	var screen: WardRoundScreen = _screen()
	var case: Dictionary = WardRounds.get_case(CASE_ID)
	screen.open_bedside("rushed")
	check(screen.ask("history").contains("short answer"), "low trust gives a short reply")
	check(not WardRounds.is_revealed(CASE_ID, "history"), "nothing revealed")
	check(screen.ask("observations") == case["presentation"]["vitals"], "observations need no trust")
	var mend: Button = screen.find_child("Repair", true, false)
	check(mend != null, "repair offered after a short reply")
	mend.pressed.emit()
	check_eq(WardRounds.bedside_trust(CASE_ID), 1, "repair raises trust")
	check(screen.ask("history") == case["presentation"]["history"], "history after repairing")
	check(screen.find_child("Repair", true, false) == null, "no repair once trust is back")


func test_debrief_counts_the_conversation() -> void:
	var screen: WardRoundScreen = _screen()
	screen.open_bedside("rushed")
	screen.repair()
	screen.ask("history")
	# The first plan goes in before the mental state was heard.
	check_eq(_submit_solved(screen)["outcome"], "accepted", "accepted")
	var scored: Dictionary = WardRounds.score(CASE_ID)
	var texts: String = "\n".join(scored["findings"].map(func(f: Dictionary) -> String: return f["text"]))
	check(texts.contains("rushed opening, though you slowed down"), "repaired rushed opening noted")
	check(texts.contains("before you had heard the mental state"), "unheard mental state noted")
	check(not texts.contains("before you had heard the history"), "heard history not flagged")
	var rapport: int = scored["areas"]["rapport"]
	check(screen.replay(), "replay")
	check_eq(WardRounds.bedside_opening(CASE_ID), "", "replay clears the conversation")
	check(not WardRounds.is_revealed(CASE_ID, "history"), "replay hides the history again")
	screen.open_bedside("warm")
	for question: String in ["history", "mental_state", "observations"]:
		screen.ask(question)
	screen.set_intervention("explain_plan", true)
	check_eq(_submit_solved(screen)["outcome"], "accepted", "replay accepted")
	scored = WardRounds.score(CASE_ID)
	check(scored["areas"]["rapport"] > rapport, "a warm opening scores better rapport")
	texts = "\n".join(scored["findings"].map(func(f: Dictionary) -> String: return f["text"]))
	check(texts.contains("introduced yourself"), "warm opening praised")


func test_conversation_saves_and_loads() -> void:
	var screen: WardRoundScreen = _screen()
	screen.open_bedside("direct")
	screen.ask("mental_state")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "saved")
	SaveManager.reset_all()
	check_eq(WardRounds.bedside_opening(CASE_ID), "", "reset clears the conversation")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "loaded")
	check_eq(WardRounds.bedside_opening(CASE_ID), "direct", "opening restored")
	check(WardRounds.is_revealed(CASE_ID, "mental_status"), "answer restored")
	check(not WardRounds.is_revealed(CASE_ID, "history"), "unasked stays unasked")
	check(not WardRounds.validate_save_data({"cases": {CASE_ID: {"labs": [], "plan": [], "status": "open", "attempts": 0, "asked": "x"}}}), "a broken conversation is rejected")
	screen.close()
