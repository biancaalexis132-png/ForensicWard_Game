class_name WardRoundScoring
extends RefCounted
## WardRoundScoring: the debrief score for an accepted ward-round plan.
##
## The weights come from the owner's case bible (scoring framework):
##   Patient safety 40% | Diagnostic reasoning 25% | Rapport and communication 20%
##   | Appropriate resource use 15%.
## "A correct diagnosis cannot override unsafe or dismissive behaviour": if any
## submission held an unsafe or dismissive item, the grade is capped at
## GRADE_CAPPED however high the total is.
##
## Every judgement comes from the case's own verdicts (WardRoundCatalog); this
## file adds no clinical content. The point deductions are game tuning, pending
## the owner's review, and never decide whether a plan is accepted.
##
## Action budget: each patient's tests budget is the number of required and
## helpful tests plus BUDGET_SLACK. It is soft. Going over it costs resource
## points, but a test can always be ordered, so a required test is never locked.
##
## history: one entry per submission, oldest first, {"labs": [lab ids ordered
## when it was sent], "plan": [plan item keys], "revealed": [bedside questions
## answered by then]}. The last entry is the accepted plan.
##
## bedside (optional, {} when the catalog has no bedside block):
## {"opening": the chosen opening entry, "repaired": bool}. A rushed opening
## costs rapport (less if repaired); a direct one costs a little; a plan sent
## before the history and mental state were heard costs reasoning.

const WEIGHTS: Dictionary = {"safety": 0.40, "reasoning": 0.25, "rapport": 0.20, "resources": 0.15}
const LABELS: Dictionary = {"safety": "Patient safety", "reasoning": "Diagnostic reasoning",
		"rapport": "Rapport and communication", "resources": "Appropriate resource use"}
const AREAS: Array[String] = ["safety", "reasoning", "rapport", "resources"]
const BUDGET_SLACK: int = 2

## Point deductions (out of 100 per area).
const UNSAFE_PENALTY: int = 50
const MISSED_REQUIRED_PENALTY: int = 25
const NOT_INDICATED_PENALTY: int = 15
const EXTRA_ATTEMPT_PENALTY: int = 10
const EXTRA_ATTEMPT_CAP: int = 30
const HARMFUL_OPENING_PENALTY: int = 40
const REPAIRED_OPENING_PENALTY: int = 20
const DIRECT_OPENING_PENALTY: int = 10
const UNHEARD_PENALTY: int = 15
## Bedside questions that should be heard before a plan goes in.
const HEAR_BEFORE_PLAN: Dictionary = {"history": "the history", "mental_state": "the mental state"}
const DISMISSIVE_PENALTY: int = 50
const NO_EXPLANATION_PENALTY: int = 30
const WASTED_TEST_PENALTY: int = 20
const OVER_BUDGET_PENALTY: int = 20
## Diagnostic reasoning: share of required tests ordered before the first
## submission, then share of helpful tests ordered by the accepted plan.
const REQUIRED_FIRST_SHARE: float = 0.6
const HELPFUL_SHARE: float = 0.4

const GRADES: Array = [[85, "Excellent"], [70, "Good"], [50, "Satisfactory"], [0, "Needs work"]]
const GRADE_CAPPED: String = "Needs work"
const CAP_TOTAL: int = 49

## The intervention that tells the patient what you think and what happens next.
const EXPLAIN_ITEM: String = "int:explain_plan"


## The tests budget for a case.
static func budget(case: Dictionary) -> int:
	var count: int = BUDGET_SLACK
	for lab: Dictionary in case.get("labs", {}).values():
		if lab["verdict"] in ["required", "helpful"]:
			count += 1
	return count


## Items the intervention catalog marks as dismissive (rapport "harms").
static func dismissive_items(intervention_catalog: Array) -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in intervention_catalog:
		if str(entry.get("rapport", "")) == "harms":
			result.append("int:" + str(entry["id"]))
	return result


## Scores a case from its submission history. Returns {} if there is none.
## {total: int, grade: String, capped: bool, areas: {area: int},
##  findings: [{area, text, good: bool}], budget: int, tests: int}
static func score(case: Dictionary, history: Array, intervention_catalog: Array, labels: Dictionary = {},
		bedside: Dictionary = {}) -> Dictionary:
	if history.is_empty():
		return {}
	var dismissive: Array[String] = dismissive_items(intervention_catalog)
	var findings: Array[Dictionary] = []
	var final: Dictionary = history[history.size() - 1]
	var final_labs: Array = final.get("labs", [])
	var final_plan: Array = final.get("plan", [])
	var options: Dictionary = case.get("options", {})

	# Every distinct item ever submitted, by its verdict.
	var unsafe: Array[String] = []
	var not_indicated: Array[String] = []
	var harmful: Array[String] = []
	var missed_required: Array[String] = []
	for submission: Dictionary in history:
		var plan: Array = submission.get("plan", [])
		for key: Variant in plan:
			var item: String = str(key)
			var verdict: String = WardRoundCatalog.option_verdict(case, item)["verdict"]
			if item in dismissive:
				_add(harmful, item)
			if verdict == "unsafe":
				_add(unsafe, item)
			elif verdict == "not_indicated" and not item in dismissive:
				_add(not_indicated, item)
		for key: String in options:
			if options[key]["verdict"] == "required" and not key in plan:
				_add(missed_required, key)

	# Patient safety.
	var safety: int = 100
	for item: String in unsafe:
		safety -= UNSAFE_PENALTY
		findings.append({"area": "safety", "good": false, "text": "Unsafe choice submitted: %s." % WardRoundCatalog.describe_item(item, labels)})
	for item: String in missed_required:
		safety -= MISSED_REQUIRED_PENALTY
		findings.append({"area": "safety", "good": false, "text": "A plan went in without %s." % WardRoundCatalog.describe_item(item, labels)})
	if unsafe.is_empty() and missed_required.is_empty():
		findings.append({"area": "safety", "good": true, "text": "No unsafe choice, and nothing essential left out."})

	# Diagnostic reasoning.
	var case_labs: Dictionary = case.get("labs", {})
	var required: Array[String] = []
	var helpful: Array[String] = []
	for lab_id: String in case_labs:
		match case_labs[lab_id]["verdict"]:
			"required": required.append(lab_id)
			"helpful": helpful.append(lab_id)
	var first_labs: Array = history[0].get("labs", [])
	var required_first: int = required.filter(func(id: String) -> bool: return id in first_labs).size()
	var helpful_done: int = helpful.filter(func(id: String) -> bool: return id in final_labs).size()
	var required_share: float = 1.0 if required.is_empty() else float(required_first) / required.size()
	var helpful_share: float = 1.0 if helpful.is_empty() else float(helpful_done) / helpful.size()
	var reasoning: float = 100.0 * (REQUIRED_FIRST_SHARE * required_share + HELPFUL_SHARE * helpful_share)
	if required_first < required.size():
		findings.append({"area": "reasoning", "good": false, "text": "Essential tests ordered before the first plan: %d of %d." % [required_first, required.size()]})
	elif not required.is_empty():
		findings.append({"area": "reasoning", "good": true, "text": "Every essential test was ordered before the first plan."})
	if helpful_done < helpful.size():
		var missing: Array = helpful.filter(func(id: String) -> bool: return not id in final_labs)
		findings.append({"area": "reasoning", "good": false, "text": "Useful tests not ordered: %s." % ", ".join(missing.map(func(id: String) -> String: return WardRoundCatalog.describe_item("lab:" + id, labels)))})
	for item: String in not_indicated:
		reasoning -= NOT_INDICATED_PENALTY
		findings.append({"area": "reasoning", "good": false, "text": "Not indicated for this patient: %s." % WardRoundCatalog.describe_item(item, labels)})
	if not bedside.is_empty():
		var heard: Array = history[0].get("revealed", [])
		for question: String in HEAR_BEFORE_PLAN:
			if not question in heard:
				reasoning -= UNHEARD_PENALTY
				findings.append({"area": "reasoning", "good": false, "text": "The first plan went in before you had heard %s at the bedside." % HEAR_BEFORE_PLAN[question]})
	var extra: int = history.size() - 1
	if extra > 0:
		reasoning -= mini(extra * EXTRA_ATTEMPT_PENALTY, EXTRA_ATTEMPT_CAP)
		findings.append({"area": "reasoning", "good": false, "text": "Accepted on attempt %d." % history.size()})
	else:
		findings.append({"area": "reasoning", "good": true, "text": "Accepted on the first attempt."})

	# Rapport and communication.
	var rapport: int = 100
	for item: String in harmful:
		rapport -= DISMISSIVE_PENALTY
		findings.append({"area": "rapport", "good": false, "text": "Dismissive choice submitted: %s." % WardRoundCatalog.describe_item(item, labels)})
	if EXPLAIN_ITEM in final_plan:
		findings.append({"area": "rapport", "good": true, "text": "You explained the working diagnosis and plan to the patient."})
	else:
		rapport -= NO_EXPLANATION_PENALTY
		findings.append({"area": "rapport", "good": false, "text": "The plan did not include explaining it to the patient."})

	if not bedside.is_empty():
		var opening: Dictionary = bedside.get("opening", {})
		if str(opening.get("rapport", "")) == "harms":
			if bool(bedside.get("repaired", false)):
				rapport -= REPAIRED_OPENING_PENALTY
				findings.append({"area": "rapport", "good": false, "text": "A rushed opening, though you slowed down and rebuilt some trust."})
			else:
				rapport -= HARMFUL_OPENING_PENALTY
				findings.append({"area": "rapport", "good": false, "text": "A rushed opening cost the patient's trust."})
		elif int(opening.get("trust", 0)) >= 2:
			findings.append({"area": "rapport", "good": true, "text": "You introduced yourself and explained why you were there."})
		elif not opening.is_empty():
			rapport -= DIRECT_OPENING_PENALTY
			findings.append({"area": "rapport", "good": false, "text": "You went straight to questions without explaining why you were there."})

	# Appropriate resource use.
	var allowed: int = budget(case)
	var wasted: Array = final_labs.filter(func(id: Variant) -> bool: return WardRoundCatalog.lab_result(case, str(id))["verdict"] == "not_needed")
	var over: int = maxi(0, final_labs.size() - allowed)
	var resources: int = 100 - WASTED_TEST_PENALTY * wasted.size() - OVER_BUDGET_PENALTY * over
	if not wasted.is_empty():
		findings.append({"area": "resources", "good": false, "text": "Tests this presentation did not need: %s." % ", ".join(wasted.map(func(id: Variant) -> String: return WardRoundCatalog.describe_item("lab:" + str(id), labels)))})
	if over > 0:
		findings.append({"area": "resources", "good": false, "text": "%d tests ordered against a budget of %d." % [final_labs.size(), allowed]})
	if wasted.is_empty() and over == 0:
		findings.append({"area": "resources", "good": true, "text": "%d tests ordered within a budget of %d." % [final_labs.size(), allowed]})

	var areas: Dictionary = {"safety": clampi(safety, 0, 100), "reasoning": clampi(roundi(reasoning), 0, 100),
			"rapport": clampi(rapport, 0, 100), "resources": clampi(resources, 0, 100)}
	var total: float = 0.0
	for area: String in AREAS:
		total += WEIGHTS[area] * areas[area]
	var capped: bool = not unsafe.is_empty() or not harmful.is_empty()
	var total_int: int = roundi(total)
	if capped:
		total_int = mini(total_int, CAP_TOTAL)
	return {"total": total_int, "grade": GRADE_CAPPED if capped else grade_for(total_int), "capped": capped,
			"areas": areas, "findings": findings, "budget": allowed, "tests": final_labs.size()}


static func grade_for(total: int) -> String:
	for row: Array in GRADES:
		if total >= int(row[0]):
			return str(row[1])
	return GRADE_CAPPED


static func _add(list: Array[String], item: String) -> void:
	if not item in list:
		list.append(item)
