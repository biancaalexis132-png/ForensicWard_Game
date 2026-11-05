extends TestCase
## Elias's medication and laboratory work-up: the draft validates against the
## ward-round catalogs, follows the approved Okafor catatonia logic, and
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
		check_eq(ClinicalWorkup.lab_result(ELIAS, "ck")["result"], "Mildly raised.", "CK result in %s build" % mode)
		check_eq(ClinicalWorkup.evaluate(ELIAS, ["ck", "bmp", "cbc", "uds", "collateral"],
				["start:lorazepam", "int:nutrition_hydration"])["outcome"], WardRoundCatalog.ACCEPTED, "plan judged in %s build" % mode)


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


func test_draft_follows_approved_catatonia_logic() -> void:
	var case: Dictionary = ClinicalWorkup.load_workup(ELIAS)["cases"][0]
	var okafor: Dictionary = {}
	var ward: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ClinicalWorkup.WARD_ROUNDS_PATH))
	for entry: Dictionary in ward["cases"]:
		if entry["id"] == "wr_ch4_okafor":
			okafor = entry
	check_eq(okafor.get("clinical_review_status"), "APPROVED", "Okafor is the approved model")
	for key: String in okafor["options"]:
		check_eq(case["options"].get(key, {}).get("verdict"), okafor["options"][key]["verdict"], "%s verdict matches Okafor" % key)
	for lab_id: String in ["ck", "bmp"]:
		check_eq(case["labs"][lab_id]["verdict"], "required", "%s required as for Okafor" % lab_id)


func test_approved_copy_would_judge_a_plan() -> void:
	# A copy marked approved in memory only shows the judging works once the
	# owner signs off. The file on disk is never changed.
	var case: Dictionary = ClinicalWorkup.load_workup(ELIAS)["cases"][0].duplicate(true)
	var labs: Array = []
	for lab_id: String in case["labs"]:
		if case["labs"][lab_id]["verdict"] == "required":
			labs.append(lab_id)
	var plan: Array = ["start:lorazepam", "int:nutrition_hydration"]
	check_eq(WardRoundCatalog.evaluate(case, labs, plan)["outcome"], WardRoundCatalog.ACCEPTED, "safe plan accepted")
	var unsafe: Dictionary = WardRoundCatalog.evaluate(case, labs, plan + ["start:haloperidol"])
	check_eq(unsafe["outcome"], WardRoundCatalog.REVISE, "haloperidol sends the plan back")
	check_eq(WardRoundCatalog.evaluate(case, [], plan)["outcome"], WardRoundCatalog.REVISE, "missing labs send it back")
	check_eq(WardRoundCatalog.lab_result(case, "uds")["result"], "Negative for all substances screened.", "UDS result")
