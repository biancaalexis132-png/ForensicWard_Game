extends TestCase
## Ward-round debrief: the case bible's weighted score, the soft tests budget,
## the cap for unsafe or dismissive choices, and replaying a case. The score is
## built only from each case's own verdicts; nothing here approves a case.

const SOLVER = preload("res://scripts/tests/test_ward_rounds.gd")
const CATALOG: Array = [
	{"id": "explain_plan", "label": "Explain", "rapport": "builds", "default_verdict": "acceptable", "default_feedback": "Builds trust."},
	{"id": "dismiss_as_feigned", "label": "Dismiss", "rapport": "harms", "default_verdict": "unsafe", "default_feedback": "No."},
	{"id": "challenge_beliefs", "label": "Argue", "rapport": "harms", "default_verdict": "not_indicated", "default_feedback": "No."},
]
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


## A small case: two required tests, two helpful, one not needed; one required
## intervention; one unsafe medication.
func _case() -> Dictionary:
	var case: Dictionary = {"labs": {
			"a": {"verdict": "required", "result": "x", "flag": "normal"},
			"b": {"verdict": "required", "result": "x", "flag": "normal"},
			"c": {"verdict": "helpful", "result": "x", "flag": "normal"},
			"d": {"verdict": "helpful", "result": "x", "flag": "normal"},
			"e": {"verdict": "not_needed", "result": "x", "flag": "normal"}},
		"options": {"int:close_observation": {"verdict": "required", "feedback": "Needed."},
			"start:haloperidol": {"verdict": "unsafe", "feedback": "Unsafe here."},
			"start:clozapine": {"verdict": "not_indicated", "feedback": "Not yet."}}}
	return WardRoundCatalog.with_defaults(case, CATALOG)


func test_a_clean_first_time_plan_scores_full_marks() -> void:
	var case: Dictionary = _case()
	check_eq(WardRoundScoring.budget(case), 6, "budget is required plus helpful tests plus two")
	var scored: Dictionary = WardRoundScoring.score(case,
			[{"labs": ["a", "b", "c", "d"], "plan": ["int:close_observation", "int:explain_plan"]}], CATALOG)
	check_eq(scored["areas"], {"safety": 100, "reasoning": 100, "rapport": 100, "resources": 100}, "every area full")
	check_eq(scored["total"], 100, "total 100")
	check_eq(scored["grade"], "Excellent", "excellent")
	check(not scored["capped"], "not capped")
	check(WardRoundScoring.score(case, [], CATALOG).is_empty(), "nothing to score before a submission")


func test_each_area_loses_points_for_its_own_mistakes() -> void:
	var case: Dictionary = _case()
	# First plan: no tests, missing the required intervention, a not-indicated start.
	# Accepted second plan: all tests plus the unneeded one, no explanation.
	var scored: Dictionary = WardRoundScoring.score(case, [
			{"labs": [], "plan": ["start:clozapine"]},
			{"labs": ["a", "b", "c", "d", "e"], "plan": ["int:close_observation"]}], CATALOG)
	check_eq(scored["areas"]["safety"], 75, "missing the required intervention once costs safety")
	# 0.6 * 0 (required before first plan) + 0.4 * 1 = 40, minus 15 not indicated, minus 10 extra attempt.
	check_eq(scored["areas"]["reasoning"], 15, "late essential tests, a not-indicated start and a second attempt cost reasoning")
	check_eq(scored["areas"]["rapport"], 70, "no explanation costs rapport")
	check_eq(scored["areas"]["resources"], 80, "an unneeded test costs resources")
	check_eq(scored["total"], roundi(0.4 * 75 + 0.25 * 15 + 0.2 * 70 + 0.15 * 80), "weighted 40/25/20/15")
	var texts: Array = scored["findings"].map(func(f: Dictionary) -> String: return f["text"])
	check(texts.any(func(t: String) -> bool: return t.contains("0 of 2")), "debrief counts essential tests before the first plan")
	check(texts.any(func(t: String) -> bool: return t.contains("attempt 2")), "debrief names the attempt")


func test_going_over_the_budget_costs_points_but_never_blocks() -> void:
	var case: Dictionary = _case()
	case["labs"]["f"] = {"verdict": "not_needed", "result": "x", "flag": "normal"}
	case["labs"]["g"] = {"verdict": "not_needed", "result": "x", "flag": "normal"}
	var scored: Dictionary = WardRoundScoring.score(case,
			[{"labs": ["a", "b", "c", "d", "e", "f", "g"], "plan": ["int:close_observation", "int:explain_plan"]}], CATALOG)
	# Three unneeded tests (60) and one over the budget of 6 (20).
	check_eq(scored["areas"]["resources"], 20, "unneeded and over-budget tests both cost resources")
	check_eq(scored["tests"], 7, "seven tests counted")


func test_unsafe_or_dismissive_choices_cap_the_grade() -> void:
	var case: Dictionary = _case()
	var clean_plan: Dictionary = {"labs": ["a", "b", "c", "d"], "plan": ["int:close_observation", "int:explain_plan"]}
	var unsafe: Dictionary = WardRoundScoring.score(case,
			[{"labs": ["a", "b", "c", "d"], "plan": ["start:haloperidol"]}, clean_plan], CATALOG)
	check(unsafe["capped"], "an unsafe submission caps")
	check_eq(unsafe["grade"], "Needs work", "capped grade")
	check(unsafe["total"] <= WardRoundScoring.CAP_TOTAL, "capped total")
	var argued: Dictionary = WardRoundScoring.score(case,
			[{"labs": ["a", "b", "c", "d"], "plan": ["int:challenge_beliefs"]}, clean_plan], CATALOG)
	check(argued["capped"], "a dismissive submission caps even though it is only not indicated")
	check_eq(argued["areas"]["rapport"], 50, "dismissive choice costs rapport")
	check_eq(argued["areas"]["reasoning"], 90, "a dismissive item is not counted again as not indicated")


func test_explaining_the_plan_is_welcome_on_every_case() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WardRounds.DATA_PATH))
	check(WardRoundCatalog.validate(data).is_empty(), "catalog with rapport tags is valid")
	for id: String in WardRounds.admitted_case_ids() + ["wr_ch1_ortiz", "wr_ch5_bell"]:
		var verdict: String = WardRoundCatalog.option_verdict(WardRounds.get_case(id), "int:explain_plan")["verdict"]
		check(verdict in ["preferred", "acceptable"], "%s welcomes an explanation" % id)
	var broken: Dictionary = data.duplicate(true)
	for entry: Dictionary in broken["intervention_catalog"]:
		if entry["id"] == "challenge_beliefs":
			entry["rapport"] = "rude"
		if entry["id"] == "neurology_referral":
			entry["rapport"] = "harms"
	var errors: String = "\n".join(WardRoundCatalog.validate(broken))
	check(errors.contains("challenge_beliefs: rapport must be one of"), "bad rapport value named")
	check(errors.contains("neurology_referral: a harmful item needs a default_verdict"), "harmful item without a verdict named")


func test_every_case_can_score_excellent() -> void:
	for id: String in _all_case_ids():
		var case: Dictionary = WardRounds.get_case(id)
		var solved: Dictionary = SOLVER._solve(case)
		var labs: Array = solved["labs"].duplicate()
		for lab_id: String in case["labs"]:
			if case["labs"][lab_id]["verdict"] == "helpful" and not lab_id in labs:
				labs.append(lab_id)
		var plan: Array = solved["plan"].duplicate()
		if not "int:explain_plan" in plan:
			plan.append("int:explain_plan")
		check_eq(WardRoundCatalog.evaluate(case, labs, plan)["outcome"], "accepted", "%s accepts the ideal plan" % id)
		var scored: Dictionary = WardRoundScoring.score(case, [{"labs": labs, "plan": plan}], WardRounds.intervention_catalog())
		check_eq(scored["grade"], "Excellent", "%s can reach Excellent (%d)" % [id, scored["total"]])


func test_debrief_shows_after_acceptance_and_replay_keeps_the_chapter_open() -> void:
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	var id: String = "wr_ch1_ortiz"
	var case: Dictionary = WardRounds.get_case(id)
	var solved: Dictionary = SOLVER._solve(case)
	# Approached on the ward (a patient there is seen before the plan opens).
	EventBus.ui_panel_requested.emit(WardRoundScreen.PANEL_ID, {"case_id": id, "at_bedside": true})
	var screen: WardRoundScreen = _main.get_node("WardRoundScreen")
	check_eq(screen.case_id, id, "Ortiz open")
	var meter: Label = screen.find_child("Budget", true, false)
	check(meter.text.contains("0 of a budget of %d" % WardRounds.tests_budget(id)), "budget shown before any test")
	for lab_id: String in solved["labs"]:
		screen.order_lab(lab_id)
	meter = screen.find_child("Budget", true, false)
	check(meter.text.begins_with("Tests ordered: %d" % solved["labs"].size()), "budget counts orders")
	check(not (screen.find_child("Replay", true, false) as Button).visible, "no replay before acceptance")
	WardRounds.submit_plan(id, ["start:clozapine"])  # Not indicated: sent back, counted in the debrief.
	var plan: Array = solved["plan"].duplicate()
	_enter_plan(screen, plan)
	screen.set_start("clozapine", false)
	check_eq(screen.submit()["outcome"], "accepted", "accepted on the second attempt")
	var review: String = (screen.find_child("Review", true, false) as RichTextLabel).get_parsed_text()
	check(review.contains("Debrief:"), "debrief total in the attending's reply")
	check_eq(screen._tabs.current_tab, WardRoundScreen.TABS.find("Debrief"), "debrief tab opens on acceptance")
	review = (screen.find_child("DebriefText", true, false) as RichTextLabel).get_parsed_text()
	check(review.contains("Patient safety (40%)") and review.contains("Appropriate resource use (15%)"), "every area shown with its weight")
	check(review.contains("Accepted on attempt 2"), "the sent-back plan counts")
	var first: int = WardRounds.score(id)["total"]
	check_eq(WardRounds.best_score(id), first, "best score recorded")
	var replay: Button = screen.find_child("Replay", true, false)
	check(replay.visible, "replay offered once accepted")
	replay.pressed.emit()
	check(WardRounds.is_replaying(id), "replaying")
	check_eq(WardRounds.status(id), "accepted", "the case stays accepted, so the chapter stays open")
	check(not id in WardRounds.open_case_ids("ch1"), "replay does not gate the chapter")
	check_eq(WardRounds.ordered_labs(id), [], "replay clears the tests")
	check(not (screen.find_child("Submit", true, false) as Button).disabled, "plan can be submitted again")
	check(WardRounds.score(id).is_empty(), "no score while replaying")
	for lab_id: String in case["labs"]:
		if case["labs"][lab_id]["verdict"] in ["required", "helpful"] or lab_id in solved["labs"]:
			screen.order_lab(lab_id)
	_enter_plan(screen, plan + ["int:explain_plan"])
	check_eq(screen.submit()["outcome"], "accepted", "replay accepted")
	check(WardRounds.score(id)["total"] > first, "a better run scores higher")
	check_eq(WardRounds.best_score(id), WardRounds.score(id)["total"], "best score updated")
	check(SaveManager.save_game(TEST_SAVE_SLOT) == OK, "saved")
	var best: int = WardRounds.best_score(id)
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "loaded")
	check_eq(WardRounds.best_score(id), best, "best score restored")
	check_eq(WardRounds.score(id)["total"], best, "debrief restored from the saved history")
	check(WardRounds.validate_save_data({"cases": {id: {"labs": [], "plan": [], "status": "accepted", "attempts": 1}}}), "older saves without history still load")
	check(not WardRounds.validate_save_data({"cases": {id: {"labs": [], "plan": [], "status": "accepted", "attempts": 1, "history": [3]}}}), "a broken history is rejected")
	screen.close()


func _enter_plan(screen: WardRoundScreen, plan: Array) -> void:
	for key: String in plan:
		var parts: PackedStringArray = key.split(":")
		if parts[0] == "start":
			screen.set_start(parts[1], true)
		elif parts[0] == "int":
			screen.set_intervention(parts[1], true)
		else:
			screen.set_med_action(parts[1], parts[0])


func _all_case_ids() -> Array[String]:
	var ids: Array[String] = []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WardRounds.DATA_PATH))
	for case: Dictionary in data["cases"]:
		ids.append(case["id"])
	return ids
