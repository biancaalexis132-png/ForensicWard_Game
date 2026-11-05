extends TestCase
## Elias's medication and laboratory work-up: the draft validates against the
## ward-round catalogs, agrees with the approved bedside encounter, and
## opens only when both the file and its case are APPROVED (owner
## approved 2026-11-05).

const ELIAS: String = "pt_elias_ward"


func after_each() -> void:
	ClinicalRules.build_mode = ClinicalRules.MODE_PROTOTYPE
	super.after_each()


func test_draft_validates_against_ward_round_catalogs() -> void:
	var data: Dictionary = ClinicalWorkup.load_workup(ELIAS)
	check(not data.is_empty(), "Elias has a work-up file")
	check_eq(ClinicalWorkup.validate(data, ContentRegistry.get_chapter_ids()), [] as Array[String], "work-up validates")
	check_eq(data["cases"][0]["chapter"], "ch1", "work-up belongs to chapter 1")


func test_approved_work_up_is_open_in_every_build() -> void:
	var data: Dictionary = ClinicalWorkup.load_workup(ELIAS)
	check_eq(data["clinical_review_status"], "APPROVED", "owner approved the file (2026-11-05)")
	check_eq(data["cases"][0]["clinical_review_status"], "APPROVED", "owner approved the case")
	for mode: String in [ClinicalRules.MODE_PROTOTYPE, ClinicalRules.MODE_VALIDATED]:
		ClinicalRules.build_mode = mode
		check(ClinicalWorkup.is_approved(ELIAS), "open in %s build" % mode)
		check_eq(ClinicalWorkup.lab_result(ELIAS, "ck")["result"], "1,150 U/L (raised).", "CK result in %s build" % mode)
		check_eq(ClinicalWorkup.evaluate(ELIAS, ["ck", "bmp", "cbc"],
				["start:lorazepam", "int:nutrition_hydration", "int:close_observation"])["outcome"], WardRoundCatalog.ACCEPTED, "plan judged in %s build" % mode)


func test_pending_copy_stays_locked() -> void:
	var data: Dictionary = ClinicalWorkup.load_workup(ELIAS).duplicate(true)
	check(ClinicalWorkup._is_approved(data), "approved file opens")
	data["cases"][0]["clinical_review_status"] = "PENDING_PSYCHIATRIST_REVIEW"
	check(not ClinicalWorkup._is_approved(data), "a pending case stays locked")
	data["cases"][0]["clinical_review_status"] = "APPROVED"
	data["clinical_review_status"] = "PENDING_PSYCHIATRIST_REVIEW"
	check(not ClinicalWorkup._is_approved(data), "a pending file stays locked")


func test_order_result_needs_a_placed_order() -> void:
	var order: Dictionary = {"id": "ord_test_ck", "action_id": "evaluate_catatonia", "workup_lab": "ck"}
	if ClinicalOrders.history(ELIAS, order).is_empty():
		check(ClinicalOrders.result_for(ELIAS, order).is_empty(), "no result before the order is placed")
	check(ClinicalOrders.result_for(ELIAS, {"id": "ord_x", "action_id": "evaluate_catatonia"}).is_empty(),
			"no result for an order without a lab")


func test_work_up_agrees_with_the_bedside_encounter() -> void:
	# Bi asked for the work-up and the approved bedside encounter to agree
	# (2026-11-05). These are the encounter's facts and order verdicts.
	var case: Dictionary = ClinicalWorkup.load_workup(ELIAS)["cases"][0]
	check("T 37.6 °C, HR 108" in str(case["presentation"]["vitals"]), "vitals match the encounter")
	check("Haloperidol" in str(case["presentation"]["history"]), "recent haloperidol is in the history")
	var labs: Dictionary = {"ck": "required", "bmp": "required", "cbc": "required", "lft": "helpful",
			"tsh": "helpful", "urinalysis": "helpful", "uds": "helpful", "collateral": "helpful"}
	for lab_id: String in labs:
		check_eq(case["labs"][lab_id]["verdict"], labs[lab_id], "%s verdict matches the encounter" % lab_id)
	check_eq(case["labs"]["ck"]["result"], "1,150 U/L (raised).", "CK result matches the encounter")
	var options: Dictionary = {"start:lorazepam": "preferred", "start:haloperidol": "unsafe",
			"start:olanzapine": "unsafe", "start:risperidone": "unsafe", "start:quetiapine": "unsafe",
			"start:aripiprazole": "unsafe", "int:nutrition_hydration": "required", "int:close_observation": "required"}
	for key: String in options:
		check_eq(case["options"][key]["verdict"], options[key], "%s verdict matches the encounter" % key)


func test_approved_copy_would_judge_a_plan() -> void:
	# A copy marked approved in memory only shows the judging works once the
	# owner signs off. The file on disk is never changed.
	var case: Dictionary = ClinicalWorkup.load_workup(ELIAS)["cases"][0].duplicate(true)
	var labs: Array = []
	for lab_id: String in case["labs"]:
		if case["labs"][lab_id]["verdict"] == "required":
			labs.append(lab_id)
	var plan: Array = ["start:lorazepam", "int:nutrition_hydration", "int:close_observation"]
	check_eq(WardRoundCatalog.evaluate(case, labs, plan)["outcome"], WardRoundCatalog.ACCEPTED, "safe plan accepted")
	var unsafe: Dictionary = WardRoundCatalog.evaluate(case, labs, plan + ["start:haloperidol"])
	check_eq(unsafe["outcome"], WardRoundCatalog.REVISE, "haloperidol sends the plan back")
	check_eq(WardRoundCatalog.evaluate(case, [], plan)["outcome"], WardRoundCatalog.REVISE, "missing labs send it back")
	check_eq(WardRoundCatalog.lab_result(case, "uds")["result"], "Negative.", "UDS result")
