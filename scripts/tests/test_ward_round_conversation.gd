extends TestCase
## Ward-round bedside conversation: the opening sets trust, history and mental
## state need some trust, answers fill the chart, and the debrief counts it.
## Answers are each case's own draft lines (or its chart text); nothing here
## approves any wording.

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


func _census_text(screen: WardRoundScreen) -> String:
	for i: int in screen._census.item_count:
		if screen._census.get_item_metadata(i) == CASE_ID:
			return screen._census.get_item_text(i)
	return ""


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
	check((screen.find_child("BedsideReplies", true, false) as RichTextLabel).get_parsed_text().contains(case["opening_reactions"]["warm"]), "the patient's own reaction is shown")
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
	check(screen.ask("history").contains(case["bedside_lines"]["history"]), "history in the patient's words after repairing")
	check(_chart_text(screen).contains(case["presentation"]["history"]), "the chart gets the full history")
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


func test_every_patient_answers_in_their_own_words() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WardRounds.DATA_PATH))
	for case: Dictionary in data["cases"]:
		var lines: Dictionary = case.get("bedside_lines", {})
		check_eq(str(lines.get("review_status", "")), "APPROVED", "%s lines approved by Bi" % case["id"])
		for question: String in ["history", "mental_state"]:
			check(not str(lines.get(question, "")).is_empty(), "%s has a %s line" % [case["id"], question])
	var bedside: Dictionary = data["bedside"]
	var errors: String = "\n".join(WardRoundCatalog.validate_bedside_lines({"review_status": "maybe", "diagnosis": "x", "history": " "}, bedside, "c"))
	check(errors.contains("review_status must be one of"), "bad status named")
	check(errors.contains("c.bedside_lines.diagnosis: not a bedside question"), "unknown question named")
	check(errors.contains("c.bedside_lines.history: expected a non-empty line"), "blank line named")
	check(not WardRoundCatalog.validate_bedside_lines({"review_status": "APPROVED"}, {}, "c").is_empty(), "lines need the bedside block")


func test_spoken_lines_are_quoted_and_the_chart_keeps_its_text() -> void:
	var screen: WardRoundScreen = _screen()
	var case: Dictionary = WardRounds.get_case(CASE_ID)
	screen.open_bedside("warm")
	var reply: String = screen.ask("mental_state")
	check_eq(reply, "Daniel: “%s”" % case["bedside_lines"]["mental_state"], "spoken line, first name and quotes")
	check(_chart_text(screen).contains(case["presentation"]["mental_status"]), "the chart keeps the clinician's account")
	check_eq(screen.ask("observations"), case["presentation"]["vitals"], "no line, so the chart text")
	screen.close()
	var silent: Dictionary = WardRounds.get_case("wr_ch3_adeyemi")
	check(str(silent["bedside_lines"]["history"]).begins_with("("), "a patient who cannot answer has a described response")
	check_eq(WardRounds.bedside_line("wr_ch3_adeyemi", "history"), silent["bedside_lines"]["history"], "described responses have no quotes")
	check_eq(WardRounds.bedside_line(CASE_ID, "observations"), "", "no line for observations")


func test_the_patient_answers_when_you_explain_the_plan() -> void:
	var screen: WardRoundScreen = _screen()
	var case: Dictionary = WardRounds.get_case(CASE_ID)
	check_eq(case["plan_response"]["review_status"], "APPROVED", "plan responses approved by Bi")
	screen.open_bedside("warm")
	check_eq(_submit_solved(screen)["outcome"], "accepted", "accepted without an explanation")
	check_eq(WardRounds.plan_response(CASE_ID), "", "no response when the plan was not explained")
	check(screen.replay(), "replay")
	screen.open_bedside("warm")
	screen.set_intervention("explain_plan", true)
	check_eq(_submit_solved(screen)["outcome"], "accepted", "accepted with an explanation")
	var expected: String = "Daniel: “%s”" % case["plan_response"]["line"]
	check_eq(WardRounds.plan_response(CASE_ID), expected, "the patient answers in their own words")
	check(screen._review.get_parsed_text().contains(expected), "shown with the attending's reply")
	check((screen.find_child("DebriefText", true, false) as RichTextLabel).get_parsed_text().contains(expected), "shown in the debrief")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WardRounds.DATA_PATH))
	for entry: Dictionary in data["cases"]:
		check(not str(entry.get("plan_response", {}).get("line", "")).is_empty(), "%s has a plan response" % entry["id"])
	data["cases"][0]["plan_response"] = {"review_status": "PENDING_PSYCHIATRIST_REVIEW", "line": ""}
	check("\n".join(WardRoundCatalog.validate(data)).contains("plan_response: needs a review_status and a non-empty line"), "a blank response is refused")
	screen.close()


func test_checking_in_on_a_patient_from_an_earlier_chapter() -> void:
	var screen: WardRoundScreen = _screen()
	var case: Dictionary = WardRounds.get_case(CASE_ID)
	check_eq(case["follow_up"]["review_status"], "APPROVED", "follow-up lines approved by Bi")
	screen.open_bedside("warm")
	check_eq(_submit_solved(screen)["outcome"], "accepted", "accepted")
	check(not WardRounds.can_follow_up(CASE_ID), "no check-in in the same chapter")
	check_eq(screen.follow_up(), "", "nothing to say yet")
	(_main.get_node("ChapterDirector") as ChapterDirector).load_save_data({"current": "ch2", "chapters": {}})
	check(WardRounds.can_follow_up(CASE_ID), "a later chapter has begun")
	screen.close()
	EventBus.ui_panel_requested.emit(WardRoundScreen.PANEL_ID, {"case_id": CASE_ID})
	check_eq(screen._tabs.current_tab, WardRoundScreen.TABS.find("Bedside"), "a patient to check in on opens at the bedside")
	check(_census_text(screen).contains("check in"), "the census says who to check in on")
	(screen.find_child("FollowUp", true, false) as Button).pressed.emit()
	var expected: String = "Daniel: “%s”" % case["follow_up"]["line"]
	check_eq((screen.find_child("FollowUpLine", true, false) as RichTextLabel).get_parsed_text(), expected, "they say how they are getting on")
	check(screen.find_child("FollowUp", true, false) == null, "a check-in happens once")
	check(not _census_text(screen).contains("check in"), "census mark cleared")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "saved")
	SaveManager.reset_all()
	check_eq(WardRounds.followed_up_line(CASE_ID), "", "reset clears the check-in")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "loaded")
	check_eq(WardRounds.followed_up_line(CASE_ID), expected, "check-in restored")
	check(not WardRounds.validate_save_data({"cases": {CASE_ID: {"labs": [], "plan": [], "status": "open", "attempts": 0, "followed_up": "yes"}}}), "a broken check-in is rejected")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WardRounds.DATA_PATH))
	for entry: Dictionary in data["cases"]:
		check(not str(entry.get("follow_up", {}).get("line", "")).is_empty(), "%s has a follow-up line" % entry["id"])
	data["cases"][0]["follow_up"] = {"review_status": "maybe", "line": "x"}
	check("\n".join(WardRoundCatalog.validate(data)).contains("follow_up: needs a review_status and a non-empty line"), "a bad follow-up is refused")
	screen.close()


func test_each_patient_reacts_to_the_opening_in_their_own_way() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WardRounds.DATA_PATH))
	for entry: Dictionary in data["cases"]:
		var reactions: Dictionary = entry.get("opening_reactions", {})
		check_eq(str(reactions.get("review_status", "")), "PENDING_PSYCHIATRIST_REVIEW", "%s reactions pending review" % entry["id"])
		for opening: String in ["warm", "direct", "rushed"]:
			check(not str(reactions.get(opening, "")).is_empty(), "%s reacts to %s" % [entry["id"], opening])
	var errors: String = "\n".join(WardRoundCatalog.validate_opening_reactions({"review_status": "APPROVED", "friendly": "x", "warm": ""}, data["bedside"], "c"))
	check(errors.contains("c.opening_reactions.friendly: not a bedside opening"), "unknown opening named")
	check(errors.contains("c.opening_reactions.warm: expected a non-empty line"), "blank reaction named")
	var screen: WardRoundScreen = _screen()
	var case: Dictionary = WardRounds.get_case(CASE_ID)
	check_eq(screen.open_bedside("rushed"), "(He glances at the window and folds his arms.) Then don't waste your time on me.", "a reaction starting with a description keeps its own wording")
	check_eq(WardRounds.bedside_trust(CASE_ID), 0, "trust still comes from the opening")
	check_eq(WardRounds.bedside_line(CASE_ID, "history").get_slice(":", 0), "Daniel", "spoken lines still name the patient")
	screen.close()
