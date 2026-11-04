class_name WardRoundCatalog
extends RefCounted
## WardRoundCatalog: checks data/ward_rounds.json and judges a submitted plan.
##
## A ward-round case is a patient admitted with a chapter. The player reads the
## presentation, orders labs (results come back at once) and submits a plan:
## an action on each current medication (continue, reduce, hold, stop), any new
## medications to start, and any interventions. The attending accepts the plan
## or asks for a revision, with a reason for every item that needs one.
##
## Verdicts come only from the case data, which is draft teaching content
## pending the psychiatrist's review. Nothing here invents a dose, a threshold
## or a result: results are the qualitative text the case lists, and anything
## the case does not list is judged by the fixed defaults below.
##
## Plan items are strings "<action>:<id>":
##   continue/reduce/hold/stop:<current medication id>
##   start:<medication_catalog id>
##   int:<intervention_catalog id>
##
## Defaults for unlisted items: an unlisted lab reads "Within normal limits."
## and counts as not needed; an unlisted start is not indicated; an unlisted
## intervention is not needed (noted, not a reason to revise), unless the
## intervention catalog gives it a default_verdict (not_indicated or unsafe)
## and default_feedback, as for dismissive choices that are wrong for anyone.
##
## A presentation may carry a triage_label: the referral's working label,
## which can be incomplete or misleading. It is shown, never judged.

const SCHEMA_VERSION: int = 1
const LAB_VERDICTS: Array[String] = ["required", "helpful", "not_needed"]
const LAB_FLAGS: Array[String] = ["normal", "abnormal", "critical"]
const OPTION_VERDICTS: Array[String] = ["preferred", "acceptable", "required", "not_indicated", "unsafe"]
## Catalog default verdicts may only send a plan back, never require an item
## everywhere; "acceptable" is allowed only for an item that builds rapport.
const DEFAULT_VERDICTS: Array[String] = ["not_indicated", "unsafe"]
## rapport: "builds" (explaining the plan) or "harms" (dismissive choices),
## used by WardRoundScoring. A harmful item must carry a default verdict.
const RAPPORT_VALUES: Array[String] = ["builds", "harms"]
const MED_ACTIONS: Array[String] = ["continue", "reduce", "hold", "stop"]
const REVIEW_STATUSES: Array[String] = ["PENDING_PSYCHIATRIST_REVIEW", "APPROVED", "REJECTED"]
const NORMAL_RESULT: String = "Within normal limits."

const ACCEPTED: String = "accepted"
const REVISE: String = "revise"


## Every problem in the catalog, as readable messages ([] when valid).
static func validate(data: Variant, chapter_ids: Array = []) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary:
		return ["ward_rounds: expected an object"] as Array[String]
	var version: Variant = data.get("schema_version")
	if not (version is int or version is float) or int(version) != SCHEMA_VERSION:
		errors.append("ward_rounds: schema_version must be %d" % SCHEMA_VERSION)
	if not str(data.get("clinical_review_status", "")) in REVIEW_STATUSES:
		errors.append("ward_rounds: clinical_review_status must be one of %s" % str(REVIEW_STATUSES))
	var labs: Dictionary = _catalog(data, "lab_catalog", errors)
	var meds: Dictionary = _catalog(data, "medication_catalog", errors)
	var interventions: Dictionary = _catalog(data, "intervention_catalog", errors)
	for entry: Dictionary in interventions.values():
		var rapport: String = str(entry.get("rapport", ""))
		if entry.has("rapport") and not rapport in RAPPORT_VALUES:
			errors.append("ward_rounds.intervention_catalog.%s: rapport must be one of %s" % [entry["id"], str(RAPPORT_VALUES)])
		var allowed: Array[String] = DEFAULT_VERDICTS.duplicate()
		if rapport == "builds":
			allowed.append("acceptable")
		if entry.has("default_verdict") and (not str(entry["default_verdict"]) in allowed
				or not entry.get("default_feedback") is String or str(entry["default_feedback"]).is_empty()):
			errors.append("ward_rounds.intervention_catalog.%s: default_verdict must be one of %s, with default_feedback" % [entry["id"], str(allowed)])
		if rapport == "harms" and not entry.has("default_verdict"):
			errors.append("ward_rounds.intervention_catalog.%s: a harmful item needs a default_verdict" % entry["id"])
	if data.has("bedside"):
		errors.append_array(validate_bedside(data["bedside"]))
	if not data.get("cases") is Array or (data["cases"] as Array).is_empty():
		errors.append("ward_rounds: cases must be a non-empty array")
		return errors
	var ids: Dictionary = {}
	for i: int in data["cases"].size():
		var case: Variant = data["cases"][i]
		var path: String = "ward_rounds.cases[%d]" % i
		if not case is Dictionary:
			errors.append(path + ": expected an object")
			continue
		var id: String = str(case.get("id", ""))
		if not id.begins_with("wr_") or ids.has(id):
			errors.append(path + ": id '%s' must start with 'wr_' and be unique" % id)
		ids[id] = true
		path = "ward_rounds.%s" % id
		if case.has("plan_response"):
			var response: Variant = case["plan_response"]
			if not response is Dictionary or not str(response.get("review_status", "")) in REVIEW_STATUSES \
					or not response.get("line") is String or str(response["line"]).strip_edges().is_empty():
				errors.append(path + ".plan_response: needs a review_status and a non-empty line")
		if case.has("bedside_lines"):
			errors.append_array(validate_bedside_lines(case["bedside_lines"], data.get("bedside", {}), path))
		if not chapter_ids.is_empty() and not case.get("chapter") in chapter_ids:
			errors.append(path + ": unknown chapter '%s'" % str(case.get("chapter")))
		if not str(case.get("clinical_review_status", "")) in REVIEW_STATUSES:
			errors.append(path + ": clinical_review_status missing or unknown")
		for field: String in ["teaching"]:
			if not case.get(field) is String or str(case[field]).is_empty():
				errors.append(path + ": %s must be text" % field)
		var patient: Variant = case.get("patient")
		if not patient is Dictionary or not patient.get("name") is String or not (patient.get("age") is float or patient.get("age") is int):
			errors.append(path + ": patient needs a name and an age")
		var presentation: Variant = case.get("presentation")
		var current: Array[String] = []
		if not presentation is Dictionary:
			errors.append(path + ": presentation missing")
		else:
			for field: String in ["reason", "history", "mental_status", "vitals"]:
				if not presentation.get(field) is String or str(presentation[field]).is_empty():
					errors.append(path + ".presentation: %s must be text" % field)
			if presentation.has("triage_label") and (not presentation["triage_label"] is String or str(presentation["triage_label"]).is_empty()):
				errors.append(path + ".presentation: triage_label must be text when present")
			if not presentation.get("current_medications") is Array:
				errors.append(path + ".presentation: current_medications must be an array")
			else:
				for med: Variant in presentation["current_medications"]:
					if not med is Dictionary or not med.get("id") is String or not med.get("label") is String:
						errors.append(path + ".presentation.current_medications: each needs an id and a label")
					elif med["id"] in current:
						errors.append(path + ".presentation.current_medications: '%s' listed twice" % med["id"])
					else:
						current.append(med["id"])
		var case_labs: Variant = case.get("labs")
		if not case_labs is Dictionary:
			errors.append(path + ": labs must be an object")
		else:
			for lab_id: String in case_labs:
				var lab: Variant = case_labs[lab_id]
				if not labs.has(lab_id):
					errors.append(path + ".labs: unknown lab '%s'" % lab_id)
				if not lab is Dictionary or not str(lab.get("verdict", "")) in LAB_VERDICTS \
						or not lab.get("result") is String or not str(lab.get("flag", "")) in LAB_FLAGS:
					errors.append(path + ".labs.%s: needs verdict, result and flag" % lab_id)
		var options: Variant = case.get("options")
		if not options is Dictionary:
			errors.append(path + ": options must be an object")
			continue
		for key: String in options:
			var option: Variant = options[key]
			if not option is Dictionary or not str(option.get("verdict", "")) in OPTION_VERDICTS \
					or not option.get("feedback") is String or str(option["feedback"]).is_empty():
				errors.append(path + ".options.%s: needs a verdict and feedback" % key)
			var problem: String = _option_problem(key, current, meds, interventions)
			if not problem.is_empty():
				errors.append(path + ".options.%s: %s" % [key, problem])
		for med_id: String in current:
			for action: String in MED_ACTIONS:
				if not options.has("%s:%s" % [action, med_id]):
					errors.append(path + ".options: '%s:%s' missing (every current medication needs all four actions judged)" % [action, med_id])
		var groups: Variant = case.get("requires_one_of", [])
		if not groups is Array:
			errors.append(path + ": requires_one_of must be an array of arrays")
		else:
			for group: Variant in groups:
				if not group is Array or (group as Array).is_empty():
					errors.append(path + ".requires_one_of: each group must be a non-empty array")
					continue
				for key: Variant in group:
					if not options.has(key) or not str(options[key]["verdict"]) in ["preferred", "acceptable", "required"]:
						errors.append(path + ".requires_one_of: '%s' must be a listed preferred, acceptable or required option" % str(key))
		var needs: Variant = case.get("requires_labs_for", {})
		if not needs is Dictionary:
			errors.append(path + ": requires_labs_for must be an object")
		else:
			for key: String in needs:
				if not options.has(key):
					errors.append(path + ".requires_labs_for: '%s' is not a listed option" % key)
				for lab_id: Variant in needs[key]:
					if not labs.has(lab_id):
						errors.append(path + ".requires_labs_for.%s: unknown lab '%s'" % [key, str(lab_id)])
	return errors


## Lab result text and flag for a case ({result, flag, verdict, teaching}).
## Fields of a case's presentation a bedside question can reveal.
const BEDSIDE_FIELDS: Array[String] = ["history", "mental_status", "vitals"]


## Problems in the optional bedside conversation block ([] when valid).
static func validate_bedside(bedside: Variant) -> Array[String]:
	var errors: Array[String] = []
	var path: String = "ward_rounds.bedside"
	if not bedside is Dictionary:
		return [path + ": expected an object"] as Array[String]
	if not str(bedside.get("review_status", "")) in REVIEW_STATUSES:
		errors.append(path + ": review_status must be one of %s" % str(REVIEW_STATUSES))
	for field: String in ["openings", "questions"]:
		if not bedside.get(field) is Array or (bedside[field] as Array).is_empty():
			errors.append("%s.%s: expected a non-empty array" % [path, field])
			return errors
	var seen: Dictionary = {}
	for entry: Variant in bedside["openings"]:
		if not entry is Dictionary or not entry.get("id") is String or seen.has(entry["id"]) \
				or not entry.get("label") is String or not entry.get("response") is String \
				or not (entry.get("trust") is int or entry.get("trust") is float) or int(entry["trust"]) < 0 or int(entry["trust"]) > 2 \
				or (entry.has("rapport") and not str(entry["rapport"]) in RAPPORT_VALUES):
			errors.append("%s.openings: each needs a unique id, label, response, trust 0 to 2 and an optional rapport" % path)
			continue
		seen[entry["id"]] = true
	for entry: Variant in bedside["questions"]:
		if not entry is Dictionary or not entry.get("id") is String or seen.has(entry["id"]) \
				or not entry.get("label") is String or not str(entry.get("field", "")) in BEDSIDE_FIELDS \
				or not entry.get("needs_trust") is bool:
			errors.append("%s.questions: each needs a unique id, label, field (%s) and needs_trust" % [path, ", ".join(BEDSIDE_FIELDS)])
			continue
		seen[entry["id"]] = true
	if not bedside.get("repair") is Dictionary or not bedside["repair"].get("label") is String \
			or not bedside["repair"].get("response") is String:
		errors.append(path + ".repair: needs a label and a response")
	if not bedside.get("low_trust_response") is String:
		errors.append(path + ": low_trust_response must be a string")
	return errors


## Problems in a case's own spoken bedside answers ([] when valid): a review
## status, then non-empty lines keyed by the bedside block's question ids.
static func validate_bedside_lines(lines: Variant, bedside: Variant, case_path: String) -> Array[String]:
	var path: String = case_path + ".bedside_lines"
	if not lines is Dictionary:
		return [path + ": expected an object"] as Array[String]
	if not bedside is Dictionary or not bedside.get("questions") is Array:
		return [path + ": needs the catalog's bedside block"] as Array[String]
	var errors: Array[String] = []
	if not str(lines.get("review_status", "")) in REVIEW_STATUSES:
		errors.append(path + ": review_status must be one of %s" % str(REVIEW_STATUSES))
	var question_ids: Array = (bedside["questions"] as Array).map(func(q: Variant) -> String: return str(q.get("id", "")) if q is Dictionary else "")
	for key: Variant in lines:
		if key == "review_status":
			continue
		if not key in question_ids:
			errors.append("%s.%s: not a bedside question (%s)" % [path, key, ", ".join(question_ids)])
		elif not lines[key] is String or str(lines[key]).strip_edges().is_empty():
			errors.append("%s.%s: expected a non-empty line" % [path, key])
	return errors


static func lab_result(case: Dictionary, lab_id: String) -> Dictionary:
	var lab: Dictionary = case.get("labs", {}).get(lab_id, {})
	if lab.is_empty():
		return {"result": NORMAL_RESULT, "flag": "normal", "verdict": "not_needed", "teaching": ""}
	return {"result": lab["result"], "flag": lab["flag"], "verdict": lab["verdict"],
			"teaching": str(lab.get("teaching", ""))}


## Verdict and feedback for one plan item, with the defaults for unlisted items.
## The case with the intervention catalog's default verdicts filled in for
## interventions the case does not judge itself. The case data is not changed.
static func with_defaults(case: Dictionary, intervention_catalog: Array) -> Dictionary:
	var result: Dictionary = case.duplicate(true)
	for entry: Dictionary in intervention_catalog:
		var key: String = "int:" + str(entry["id"])
		if entry.has("default_verdict") and not result["options"].has(key):
			result["options"][key] = {"verdict": entry["default_verdict"], "feedback": entry["default_feedback"]}
	return result


static func option_verdict(case: Dictionary, key: String) -> Dictionary:
	var option: Dictionary = case.get("options", {}).get(key, {})
	if not option.is_empty():
		return {"verdict": option["verdict"], "feedback": option["feedback"]}
	if key.begins_with("start:"):
		return {"verdict": "not_indicated", "feedback": "There is no indication for this medication in this presentation."}
	if key.begins_with("int:"):
		return {"verdict": "not_needed", "feedback": "Not needed for this patient."}
	return {"verdict": "acceptable", "feedback": ""}


## Judges a plan. labs: lab ids ordered so far. plan: plan item keys.
## Returns {outcome: "accepted"|"revise", problems: [{item, reason}],
## notes: [{item, reason}], good: [{item, reason}], teaching: String}.
## labels: display names for lab ids and medication/intervention ids (optional).
static func evaluate(case: Dictionary, labs: Array, plan: Array, labels: Dictionary = {}) -> Dictionary:
	var problems: Array[Dictionary] = []
	var notes: Array[Dictionary] = []
	var good: Array[Dictionary] = []
	var case_labs: Dictionary = case.get("labs", {})
	for lab_id: String in case_labs:
		var verdict: String = case_labs[lab_id]["verdict"]
		if verdict == "required" and not lab_id in labs:
			problems.append({"item": "lab:" + lab_id,
					"reason": "Order this before the plan can be accepted. %s" % str(case_labs[lab_id].get("teaching", ""))})
		elif verdict == "helpful" and not lab_id in labs:
			notes.append({"item": "lab:" + lab_id, "reason": "Worth ordering as part of the work-up."})
	for lab_id: Variant in labs:
		if lab_result(case, lab_id)["verdict"] == "not_needed":
			notes.append({"item": "lab:" + str(lab_id), "reason": "Not needed for this presentation."})
	for key: Variant in plan:
		var judged: Dictionary = option_verdict(case, key)
		match judged["verdict"]:
			"unsafe":
				problems.append({"item": key, "reason": "Unsafe. " + judged["feedback"]})
			"not_indicated":
				problems.append({"item": key, "reason": "Not indicated. " + judged["feedback"]})
			"not_needed":
				notes.append({"item": key, "reason": judged["feedback"]})
			_:
				if not str(judged["feedback"]).is_empty():
					good.append({"item": key, "reason": judged["feedback"]})
		for lab_id: Variant in case.get("requires_labs_for", {}).get(key, []):
			if not lab_id in labs:
				problems.append({"item": key, "reason": "Order %s before this can go ahead." % describe_item("lab:" + str(lab_id), labels)})
	var options: Dictionary = case.get("options", {})
	for key: String in options:
		if options[key]["verdict"] == "required" and not key in plan:
			problems.append({"item": key, "reason": "Missing. " + str(options[key]["feedback"])})
	for group: Array in case.get("requires_one_of", []):
		var met: bool = false
		for key: Variant in group:
			met = met or key in plan
		if not met and not (group.size() == 1 and options.get(group[0], {}).get("verdict") == "required"):
			problems.append({"item": group[0], "reason": "The plan needs one of: %s." % ", ".join(group.map(func(key: Variant) -> String: return describe_item(key, labels)))})
	return {"outcome": ACCEPTED if problems.is_empty() else REVISE, "problems": problems, "notes": notes,
			"good": good, "teaching": str(case.get("teaching", ""))}


## "hold:lithium" -> "Hold Lithium"; "int:medical_transfer" -> its label.
## labels maps ids (lab, medication or intervention) to display names.
static func describe_item(key: Variant, labels: Dictionary = {}) -> String:
	var parts: PackedStringArray = str(key).split(":", true, 1)
	if parts.size() < 2:
		return str(key)
	var subject: String = str(labels.get(parts[1], parts[1].replace("_", " ").capitalize()))
	if parts[0] in ["int", "lab"]:
		return subject
	return "%s %s" % [parts[0].capitalize(), subject]


static func _catalog(data: Dictionary, field: String, errors: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	if not data.get(field) is Array:
		errors.append("ward_rounds: %s must be an array" % field)
		return result
	for entry: Variant in data[field]:
		if not entry is Dictionary or not entry.get("id") is String or not entry.get("label") is String:
			errors.append("ward_rounds.%s: each entry needs an id and a label" % field)
		elif result.has(entry["id"]):
			errors.append("ward_rounds.%s: '%s' listed twice" % [field, entry["id"]])
		else:
			result[entry["id"]] = entry
	return result


static func _option_problem(key: String, current: Array[String], meds: Dictionary, interventions: Dictionary) -> String:
	var parts: PackedStringArray = key.split(":", true, 1)
	if parts.size() != 2:
		return "must be '<action>:<id>'"
	if parts[0] in MED_ACTIONS:
		return "" if parts[1] in current else "'%s' is not a current medication" % parts[1]
	if parts[0] == "start":
		if parts[1] in current:
			return "'%s' is already a current medication" % parts[1]
		return "" if meds.has(parts[1]) else "unknown medication '%s'" % parts[1]
	if parts[0] == "int":
		return "" if interventions.has(parts[1]) else "unknown intervention '%s'" % parts[1]
	return "unknown action '%s'" % parts[0]
