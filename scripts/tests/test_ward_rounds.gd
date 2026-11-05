extends TestCase
## Ward rounds: the catalog, the attending's judgement, admission with each
## chapter, the chapter gate, save/load, the validated-build switch and the
## screen. The cases are draft teaching content; nothing here approves them.

const DATA: String = "res://data/ward_rounds.json"
var _main: Main


func before_each() -> void:
	super.before_each()
	WardRounds.enforce_gate = true


func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	WardRounds.enforce_gate = false
	WardRounds.load_catalog(WardRounds.DATA_PATH)
	ClinicalRules.build_mode = ClinicalRules.MODE_PROTOTYPE
	super.after_each()


func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))


## Labs and plan built from the answer key: one item per requires_one_of
## group, every required option, the labs those need, and a preferred or
## acceptable action for every current medication.
static func _solve(case: Dictionary) -> Dictionary:
	var plan: Array = []
	for group: Array in case.get("requires_one_of", []):
		if not group[0] in plan:
			plan.append(group[0])
	for key: String in case["options"]:
		if case["options"][key]["verdict"] == "required" and not key in plan:
			plan.append(key)
	for med: Dictionary in case["presentation"]["current_medications"]:
		var has_action: bool = false
		for action: String in WardRoundCatalog.MED_ACTIONS:
			has_action = has_action or ("%s:%s" % [action, med["id"]]) in plan
		if has_action:
			continue
		for verdict: String in ["preferred", "acceptable"]:
			for action: String in WardRoundCatalog.MED_ACTIONS:
				var key: String = "%s:%s" % [action, med["id"]]
				if not has_action and case["options"][key]["verdict"] == verdict:
					plan.append(key)
					has_action = true
	var labs: Array = []
	for lab_id: String in case["labs"]:
		if case["labs"][lab_id]["verdict"] == "required":
			labs.append(lab_id)
	for key: Variant in plan:
		for lab_id: Variant in case.get("requires_labs_for", {}).get(key, []):
			if not lab_id in labs:
				labs.append(lab_id)
	return {"labs": labs, "plan": plan}


func _start_main(chapter_id: String) -> ChapterDirector:
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	var director: ChapterDirector = _main.get_node("ChapterDirector")
	if chapter_id != director.get_chapter_id():
		director.load_save_data({"current": chapter_id, "chapters": {}})
	return director


## The owner approved these ten on 2026-11-03 (docs/clinical_review_log.md);
## every later case stays pending until the owner approves it there.
const OWNER_APPROVED: Array[String] = ["wr_ch1_ortiz", "wr_ch1_natarajan", "wr_ch2_kim", "wr_ch2_lebel",
		"wr_ch3_wrobel", "wr_ch3_adeyemi", "wr_ch4_petrova", "wr_ch4_okafor", "wr_ch5_delaney", "wr_ch5_lindqvist"]


func test_catalog_is_valid_and_only_owner_approved_cases_are_approved() -> void:
	var data: Dictionary = _data()
	check_eq(WardRoundCatalog.validate(data, ContentRegistry.get_chapter_ids()), [] as Array[String], "catalog validates")
	var per_chapter: Dictionary = {}
	for case: Dictionary in data["cases"]:
		var expected: String = "APPROVED" if case["id"] in OWNER_APPROVED else "PENDING_PSYCHIATRIST_REVIEW"
		check_eq(case["clinical_review_status"], expected, "%s review status" % case["id"])
		per_chapter[case["chapter"]] = int(per_chapter.get(case["chapter"], 0)) + 1
	# Two first-wave, two second-wave and one or two third-wave (case bible) patients.
	var expected_counts: Dictionary = {"ch1": 5, "ch2": 6, "ch3": 6, "ch4": 6, "ch5": 5}
	for chapter_id: String in ContentRegistry.get_chapter_ids():
		check_eq(per_chapter.get(chapter_id, 0), expected_counts.get(chapter_id, 0), "%s admits its patients" % chapter_id)
	var text: String = FileAccess.get_file_as_string(DATA)
	check(not RegEx.create_from_string("\\d+(\\.\\d+)?\\s*(mg|mcg|microgram|g/day|mmol)").search(text), "no doses or numeric thresholds in the cases")


func test_every_case_has_a_reachable_accepted_plan_and_rejects_doing_nothing() -> void:
	for case: Dictionary in _data()["cases"]:
		var solved: Dictionary = _solve(case)
		var review: Dictionary = WardRoundCatalog.evaluate(case, solved["labs"], solved["plan"])
		check_eq(review["outcome"], "accepted", "%s: answer key is accepted (%s)" % [case["id"], str(review["problems"])])
		var nothing: Array = case["presentation"]["current_medications"].map(func(med: Dictionary) -> String: return "continue:" + med["id"])
		check_eq(WardRoundCatalog.evaluate(case, [], nothing)["outcome"], "revise", "%s: no labs and no change is sent back" % case["id"])
		var unsafe: Array = case["options"].keys().filter(func(key: String) -> bool:
			return case["options"][key]["verdict"] in ["unsafe", "not_indicated"])
		check(not unsafe.is_empty(), "%s has at least one wrong choice to learn from" % case["id"])
		for key: String in unsafe:
			var with_mistake: Array = solved["plan"].filter(func(item: String) -> bool: return item.get_slice(":", 1) != key.get_slice(":", 1) or not key.get_slice(":", 0) in WardRoundCatalog.MED_ACTIONS)
			with_mistake.append(key)
			check_eq(WardRoundCatalog.evaluate(case, solved["labs"], with_mistake)["outcome"], "revise", "%s: %s sends the plan back" % [case["id"], key])


func test_attending_explains_each_problem() -> void:
	var case: Dictionary = {}
	for entry: Dictionary in _data()["cases"]:
		if entry["id"] == "wr_ch2_lebel":
			case = entry
	var review: Dictionary = WardRoundCatalog.evaluate(case, ["glucose_lipids"], ["continue:lithium", "continue:ibuprofen", "start:sertraline"])
	check_eq(review["outcome"], "revise", "toxic lithium plan sent back")
	var items: Array = review["problems"].map(func(problem: Dictionary) -> String: return problem["item"])
	for expected: String in ["lab:lithium_level", "lab:bmp", "continue:lithium", "continue:ibuprofen", "start:sertraline", "int:medical_transfer"]:
		check(expected in items, "problem named: " + expected)
	check(review["notes"].any(func(note: Dictionary) -> bool: return note["item"] == "lab:glucose_lipids"), "unneeded lab is noted, not counted against the plan")
	check_eq(WardRoundCatalog.lab_result(case, "uds")["result"], WardRoundCatalog.NORMAL_RESULT, "unlisted lab reads normal")
	var wrobel: Dictionary = _data()["cases"].filter(func(entry: Dictionary) -> bool: return entry["id"] == "wr_ch3_wrobel")[0]
	var early: Dictionary = WardRoundCatalog.evaluate(wrobel, [], ["reduce:clozapine"])
	check(early["problems"].any(func(problem: Dictionary) -> bool:
		return problem["item"] == "reduce:clozapine" and "Order" in problem["reason"]), "a change that needs a level asks for the lab first")


func test_validator_names_broken_cases() -> void:
	var data: Dictionary = _data()
	var case: Dictionary = data["cases"][3]
	case["labs"]["no_such_lab"] = {"verdict": "required", "result": "x", "flag": "normal"}
	case["options"].erase("reduce:lithium")
	case["requires_one_of"].append(["start:haloperidol"])
	case["options"]["start:not_a_drug"] = {"verdict": "acceptable", "feedback": "x"}
	data["cases"][4]["id"] = data["cases"][3]["id"]
	var errors: Array[String] = WardRoundCatalog.validate(data, ContentRegistry.get_chapter_ids())
	for fragment: String in ["unknown lab 'no_such_lab'", "'reduce:lithium' missing", "requires_one_of: 'start:haloperidol'",
			"unknown medication 'not_a_drug'", "be unique"]:
		check_contains(errors, fragment, "validator reports " + fragment)


func test_patients_admit_with_their_chapter_and_gate_its_close() -> void:
	var director: ChapterDirector = _start_main("ch1")
	check_eq(WardRounds.admitted_case_ids(), ["wr_ch1_ortiz", "wr_ch1_natarajan", "wr_ch1_hughes", "wr_ch1_morales", "wr_ch1_haddad"] as Array[String], "chapter 1 admits its five patients")
	check(not WardRounds.can_close_chapter("ch1"), "chapter 1 cannot close with open cases")
	check(not director.sign_out().is_empty(), "day hand-over is not gated")
	check_eq(TimeManager.get_shift(), "night", "night shift started")
	check(director.sign_out().is_empty(), "night sign-out is blocked")
	check(not director.has_completed("ch1"), "chapter stays open")
	check(WardRounds.blocked_message("ch1").contains("Daniel Ortiz"), "notice names the patients")
	for id: String in WardRounds.admitted_case_ids():
		var solved: Dictionary = _solve(WardRounds.get_case(id))
		check(not WardRounds.submit_plan(id, solved["plan"]).is_empty(), "submission accepted for judging")
		if not solved["labs"].is_empty():
			check_eq(WardRounds.status(id), "open", "%s: plan without its required labs is sent back" % id)
		for lab_id: String in solved["labs"]:
			check(WardRounds.order_lab(id, lab_id), "lab ordered: " + lab_id)
		if WardRounds.status(id) != "accepted":
			check_eq(WardRounds.submit_plan(id, solved["plan"])["outcome"], "accepted", "%s accepted after the labs" % id)
			check_eq(WardRounds.attempts(id), 2, "two submissions counted")
		check(not WardRounds.order_lab(id, "cbc"), "accepted case is locked")
	check(WardRounds.can_close_chapter("ch1"), "chapter can close")
	check(not director.sign_out().is_empty(), "night sign-out completes")
	check(director.has_completed("ch1"), "chapter 1 complete")
	director.start_chapter("ch2")
	check_eq(WardRounds.admitted_case_ids().size(), 11, "chapter 2 adds six more, chapter 1's stay on the ward")
	check_eq(WardRounds.open_case_ids("ch2").size(), 6, "chapter 2's patients are open")


func test_story_choice_that_completes_a_chapter_is_gated() -> void:
	# Chapter 3 closes from a choice once the report is submitted.
	var director: ChapterDirector = _start_main("ch1")
	director.load_save_data({"current": "ch3", "chapters": {"ch3": {"flags": ["ch3_report_submitted"]}}})
	director._active_interaction = "interaction_ch3_close"
	director._on_story_option_selected("interaction_ch3_close", "log")
	check(not director.has_completed("ch3"), "a completing choice waits for the ward round")
	check_eq(director._active_interaction, "interaction_ch3_close", "the choice can be made again")
	for id: String in WardRounds.open_case_ids("ch3"):
		var solved: Dictionary = _solve(WardRounds.get_case(id))
		for lab_id: String in solved["labs"]:
			WardRounds.order_lab(id, lab_id)
		check_eq(WardRounds.submit_plan(id, solved["plan"])["outcome"], "accepted", id + " accepted")
	director._on_story_option_selected("interaction_ch3_close", "log")
	check(director.has_completed("ch3"), "the choice completes the chapter once the plans are accepted")


func test_progress_saves_and_loads() -> void:
	_start_main("ch2")
	check(WardRounds.order_lab("wr_ch2_lebel", "lithium_level"), "lab ordered")
	WardRounds.submit_plan("wr_ch2_lebel", ["continue:lithium", "continue:ibuprofen"])
	var solved: Dictionary = _solve(WardRounds.get_case("wr_ch2_kim"))
	for lab_id: String in solved["labs"]:
		WardRounds.order_lab("wr_ch2_kim", lab_id)
	check_eq(WardRounds.submit_plan("wr_ch2_kim", solved["plan"])["outcome"], "accepted", "Kim accepted")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "saved")
	SaveManager.reset_all()
	check_eq(WardRounds.ordered_labs("wr_ch2_lebel"), [], "reset clears progress")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "loaded")
	check_eq(WardRounds.ordered_labs("wr_ch2_lebel"), ["lithium_level"], "ordered labs restored")
	check_eq(WardRounds.attempts("wr_ch2_lebel"), 1, "attempts restored")
	check_eq(WardRounds.last_review("wr_ch2_lebel")["outcome"], "revise", "last review restored")
	check_eq(WardRounds.status("wr_ch2_kim"), "accepted", "accepted plan restored")
	check(not WardRounds.validate_save_data({"cases": {"wr_ch2_kim": {"labs": [], "plan": [], "status": "approved", "attempts": 1}}}), "bad status rejected")


func test_validated_build_plays_only_approved_cases() -> void:
	_start_main("ch1")
	ClinicalRules.build_mode = ClinicalRules.MODE_VALIDATED
	check_eq(WardRounds.admitted_case_ids(), ["wr_ch1_ortiz", "wr_ch1_natarajan"] as Array[String], "only owner-approved cases play in the validated build")
	check_eq(WardRounds.open_case_ids("ch1"), ["wr_ch1_ortiz", "wr_ch1_natarajan"] as Array[String], "pending cases never gate the validated build")
	check(not WardRounds.order_lab("wr_ch1_hughes", "ck"), "no orders on a hidden pending case")
	check(WardRounds.order_lab("wr_ch1_ortiz", "cbc"), "orders on an approved case")


func test_screen_orders_labs_and_submits_through_the_ehr() -> void:
	_start_main("ch1")
	var flagged: Array = []
	var on_flag: Callable = func(rule_id: String, _reason: String) -> void: flagged.append(rule_id)
	EventBus.clinical_review_flagged.connect(on_flag)
	EventBus.ui_panel_requested.emit("ehr", {})
	var ehr: EHRScreen = _main.get_node("EHRScreen") if _main.has_node("EHRScreen") else _main.find_children("*", "EHRScreen", true, false)[0]
	var button: Button = ehr.find_child("WardRound", true, false)
	check(button.visible and button.text.contains("5 to review"), "EHR shows the ward round with five to review")
	ehr.open_ward_round()
	var screen: WardRoundScreen = _main.get_node("WardRoundScreen")
	check(screen.is_open and not ehr.is_open, "ward round replaces the chart")
	check_eq(screen.case_id, "wr_ch1_ortiz", "first open patient selected")
	check(not screen.find_child("DraftBadge", true, false).visible, "no draft badge on an owner-approved case")
	screen.select_case("wr_ch1_hughes")
	check(screen.find_child("DraftBadge", true, false).visible, "draft badge on a case pending review")
	screen.select_case("wr_ch1_ortiz")
	check(screen._submit.disabled, "from the EHR alone, a patient on the ward is not seen yet")
	# The player has been to the bedside.
	WardRounds.mark_seen("wr_ch1_ortiz")
	screen.select_case("wr_ch1_ortiz")
	var case: Dictionary = WardRounds.get_case("wr_ch1_ortiz")
	var solved: Dictionary = _solve(case)
	for lab_id: String in solved["labs"]:
		(screen.find_child("Order_" + lab_id, true, false) as Button).pressed.emit()
		check(screen.find_child("Result_" + lab_id, true, false) != null, "result shown for " + lab_id)
	for key: String in solved["plan"]:
		var parts: PackedStringArray = key.split(":")
		if parts[0] == "start":
			(screen.find_child("Start_" + parts[1], true, false) as BaseButton).button_pressed = true
		elif parts[0] == "int":
			(screen.find_child("Int_" + parts[1], true, false) as BaseButton).button_pressed = true
		else:
			screen.set_med_action(parts[1], parts[0])
	(screen.find_child("Submit", true, false) as Button).pressed.emit()
	check_eq(WardRounds.status("wr_ch1_ortiz"), "accepted", "accepted from the screen")
	check((screen.find_child("Review", true, false) as RichTextLabel).get_parsed_text().contains("plan accepted"), "attending reply shown")
	screen.select_case("wr_ch1_natarajan")
	screen.select_case("wr_ch1_ortiz")
	check((screen.find_child("Review", true, false) as RichTextLabel).get_parsed_text().contains("plan accepted"), "reply shown again when the patient is reopened")
	check((screen.find_child("Submit", true, false) as Button).disabled, "accepted plan is locked")
	check(not "ward_round_draft" in flagged, "an approved case is not flagged")
	WardRounds.submit_plan("wr_ch1_hughes", [])
	check("ward_round_draft" in flagged, "a pending case's submission is flagged for clinical review")
	EventBus.clinical_review_flagged.disconnect(on_flag)
	screen.close()
	EventBus.ui_panel_requested.emit("ehr", {})
	check(button.text.contains("4 to review"), "EHR count drops")


func test_case_bible_adaptation_referral_labels_and_respectful_choices() -> void:
	# The referral's working label shows on the chart and is never judged.
	_start_main("ch1")
	var screen_data: Dictionary = WardRounds.get_case("wr_ch1_haddad")
	check_eq(screen_data["presentation"]["triage_label"], "Possible psychotic relapse", "referral label kept")
	EventBus.ui_panel_requested.emit(WardRoundScreen.PANEL_ID, {"case_id": "wr_ch1_haddad"})
	var screen: WardRoundScreen = _main.get_node("WardRoundScreen")
	var chart_text: String = ""
	for label: Node in screen.find_children("*", "RichTextLabel", true, false):
		chart_text += (label as RichTextLabel).get_parsed_text()
	check(chart_text.contains("Referred as") and chart_text.contains("Possible psychotic relapse"), "chart shows the referral label")
	screen.close()
	# Dismissive choices are wrong for every patient, approved ones included.
	for id: String in ["wr_ch1_ortiz", "wr_ch4_reyes"]:
		var case: Dictionary = WardRounds.get_case(id)
		var solved: Dictionary = _solve(case)
		var plan: Array = solved["plan"].duplicate()
		plan.append("int:dismiss_as_feigned")
		var review: Dictionary = WardRoundCatalog.evaluate(case, solved["labs"], plan)
		check_eq(review["outcome"], "revise", id + ": recording symptoms as put on sends the plan back")
		check(not WardRoundCatalog.evaluate(case, solved["labs"], solved["plan"])["outcome"] == "revise", id + ": the plan without it is accepted")
	var bad: Dictionary = _data()
	bad["intervention_catalog"].append({"id": "x_required_everywhere", "label": "X", "default_verdict": "required", "default_feedback": "X"})
	bad["cases"][0]["presentation"]["triage_label"] = ""
	var errors: Array[String] = WardRoundCatalog.validate(bad, ContentRegistry.get_chapter_ids())
	check_contains(errors, "default_verdict must be one of", "a catalog default can only send a plan back")
	check_contains(errors, "triage_label must be text", "empty referral label named")


func test_day_handover_lists_the_ward_round() -> void:
	var director: ChapterDirector = _start_main("ch1")
	var id: String = "wr_ch1_ortiz"
	var solved: Dictionary = _solve(WardRounds.get_case(id))
	for lab_id: String in solved["labs"]:
		WardRounds.order_lab(id, lab_id)
	check_eq(WardRounds.submit_plan(id, solved["plan"])["outcome"], "accepted", "Ortiz accepted")
	var body: String = director.sign_out()
	check(body.contains("Ward round"), "handover has a ward round section")
	check(body.contains("Daniel Ortiz: plan accepted (debrief %d" % WardRounds.best_score(id)), "accepted patient with the debrief")
	check(body.contains("Priya Natarajan: no accepted plan yet."), "open patient named")
	director.load_save_data({"current": "ch2", "chapters": {}})
	check(not WardRounds.follow_up(id).is_empty(), "checked in on Ortiz in chapter 2")
	var lines: String = "\n".join(WardRounds.handover_lines("ch2"))
	check(lines.contains("Daniel Ortiz: you checked in on them."), "check-in listed")
	check(not lines.contains("Priya Natarajan"), "an earlier open patient is not repeated")
	check(lines.contains("Harold Kim: no accepted plan yet."), "this chapter's patients listed")
