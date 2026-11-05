class_name ClinicalWorkup
extends RefCounted
## ClinicalWorkup: a story patient's medication and laboratory work-up
## (data/clinical_workups/<name>.json), written in the ward-round case format
## and judged by WardRoundCatalog against the ward-round catalogs.
##
## A work-up is draft teaching content until the owner approves it. It is
## locked unless both the file and its case are APPROVED, in every build mode,
## prototype included: a locked work-up returns no lab result and no verdict.
## Results are qualitative text only; nothing here invents a dose, a number
## or a threshold, and nothing here changes story state.

const DIR: String = "res://data/clinical_workups/"
const WARD_ROUNDS_PATH: String = "res://data/ward_rounds.json"
const APPROVED: String = "APPROVED"
const LOCKED_REASON: String = "Drafted and awaiting clinical review; switched off in every build."


## Every work-up file in DIR, keyed by patient id.
static func load_all() -> Dictionary:
	var result: Dictionary = {}
	for file_name: String in DirAccess.get_files_at(DIR):
		if file_name.ends_with(".json") and not file_name.begins_with("._"):
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + file_name))
			if data is Dictionary and data.get("patient_id") is String:
				result[data["patient_id"]] = data
	return result


## The work-up file for one patient ({} when there is none).
static func load_workup(patient_id: String) -> Dictionary:
	return load_all().get(patient_id, {})


## Problems in one work-up file ([] when valid). Its case is checked with
## WardRoundCatalog.validate against the ward-round lab, medication and
## intervention catalogs, so every id it uses must already exist there.
static func validate(data: Variant, chapter_ids: Array = []) -> Array[String]:
	if not data is Dictionary:
		return ["clinical_workup: expected an object"] as Array[String]
	var errors: Array[String] = []
	if not data.get("patient_id") is String or str(data["patient_id"]).is_empty():
		errors.append("clinical_workup: patient_id must be text")
	if not data.get("cases") is Array or (data["cases"] as Array).size() != 1:
		errors.append("clinical_workup: cases must hold exactly one case")
		return errors
	var catalogs: Variant = JSON.parse_string(FileAccess.get_file_as_string(WARD_ROUNDS_PATH))
	if not catalogs is Dictionary:
		errors.append("clinical_workup: cannot read the ward-round catalogs")
		return errors
	var combined: Dictionary = {
		"schema_version": data.get("schema_version"),
		"clinical_review_status": data.get("clinical_review_status"),
		"lab_catalog": catalogs["lab_catalog"],
		"medication_catalog": catalogs["medication_catalog"],
		"intervention_catalog": catalogs["intervention_catalog"],
		"cases": data["cases"],
	}
	for error: String in WardRoundCatalog.validate(combined, chapter_ids):
		errors.append(error.replace("ward_rounds", "clinical_workup"))
	return errors


## True only when the owner has approved both the file and its case.
static func is_approved(patient_id: String) -> bool:
	return _is_approved(load_workup(patient_id))


## The patient's case, with catalog defaults filled in, or {} when locked.
static func approved_case(patient_id: String) -> Dictionary:
	var data: Dictionary = load_workup(patient_id)
	if not _is_approved(data):
		return {}
	var catalogs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WARD_ROUNDS_PATH))
	return WardRoundCatalog.with_defaults(data["cases"][0], catalogs["intervention_catalog"])


## {result, flag, verdict, teaching} for one lab, or {} while locked.
static func lab_result(patient_id: String, lab_id: String) -> Dictionary:
	var case: Dictionary = approved_case(patient_id)
	return {} if case.is_empty() else WardRoundCatalog.lab_result(case, lab_id)


## The attending's judgement of labs and a plan, or {} while locked.
static func evaluate(patient_id: String, labs: Array, plan: Array, labels: Dictionary = {}) -> Dictionary:
	var case: Dictionary = approved_case(patient_id)
	return {} if case.is_empty() else WardRoundCatalog.evaluate(case, labs, plan, labels)


static func _is_approved(data: Dictionary) -> bool:
	if data.is_empty() or data.get("clinical_review_status") != APPROVED:
		return false
	var cases: Variant = data.get("cases")
	return cases is Array and (cases as Array).size() == 1 \
			and cases[0] is Dictionary and cases[0].get("clinical_review_status") == APPROVED
