extends TestCase
## Elias's medication and laboratory work-up: the draft validates against the
## ward-round catalogs, follows the approved Okafor catatonia logic, and stays
## locked in every build mode until the owner approves it. Nothing here
## approves it.

const ELIAS: String = "pt_elias_ward"


func after_each() -> void:
	ClinicalRules.build_mode = ClinicalRules.MODE_PROTOTYPE
	super.after_each()


func test_draft_validates_against_ward_round_catalogs() -> void:
	var data: Dictionary = ClinicalWorkup.load_workup(ELIAS)
	check(not data.is_empty(), "Elias has a work-up file")
	check_eq(ClinicalWorkup.validate(data, ContentRegistry.get_chapter_ids()), [] as Array[String], "work-up validates")
	check_eq(data["cases"][0]["chapter"], "ch1", "work-up belongs to chapter 1")


func test_draft_is_pending_and_locked_in_every_build() -> void:
	var data: Dictionary = ClinicalWorkup.load_workup(ELIAS)
	check_eq(data["clinical_review_status"], "PENDING_PSYCHIATRIST_REVIEW", "file awaits review")
	check_eq(data["cases"][0]["clinical_review_status"], "PENDING_PSYCHIATRIST_REVIEW", "case awaits review")
	for mode: String in [ClinicalRules.MODE_PROTOTYPE, ClinicalRules.MODE_VALIDATED]:
		ClinicalRules.build_mode = mode
		check(not ClinicalWorkup.is_approved(ELIAS), "locked in %s build" % mode)
		check(ClinicalWorkup.approved_case(ELIAS).is_empty(), "no case in %s build" % mode)
		check(ClinicalWorkup.lab_result(ELIAS, "ck").is_empty(), "no CK result in %s build" % mode)
		check(ClinicalWorkup.evaluate(ELIAS, ["ck"], ["start:lorazepam"]).is_empty(), "no verdict in %s build" % mode)
	var order: Dictionary = {"id": "ord_test_ck", "action_id": "evaluate_catatonia", "workup_lab": "ck"}
	check(ClinicalOrders.result_for(ELIAS, order).is_empty(), "no order result while locked")


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
