extends Node
## ClinicalRules: deterministic clinical rule evaluation (Autoload "ClinicalRules").
##
## evaluate() receives a patient state snapshot and a coded action event and
## returns structured results. It changes nothing itself:
##     {"effects": [{"path": String, "set": Variant}],
##      "alerts": [{"id", "severity", "message"}],
##      "review_flags": [{"rule_id", "reason"}],
##      "rule_ids": [matched rule ids]}
##
## Governance (GDD §8, §17; handoff "Do not activate PENDING clinical rules"):
## - Rules not marked APPROVED never apply in "validated" build mode.
## - In "prototype" mode, unapproved rules may apply ONLY their
##   non_medical_effects (e.g. "assessment started"), and each use is flagged.
## - medical_effects have no executable vocabulary yet; they are never applied.
## - This manager never unlocks narrative content. Story systems subscribe
##   to EventBus.clinical_action_committed instead.
##
## Build mode comes from Project Settings: forensic_ward/clinical/build_mode.

const BUILD_MODE_SETTING: String = "forensic_ward/clinical/build_mode"
const MODE_PROTOTYPE: String = "prototype"
const MODE_VALIDATED: String = "validated"

## Non-medical effect id -> patient field it sets (relative to patients.<id>.).
const NON_MEDICAL_EFFECT_FIELDS: Dictionary = {
	"mark_assessment_started": ["assessment.started", true],
	"mark_medical_review_requested": ["assessment.medical_review_requested", true],
}

var build_mode: String = MODE_PROTOTYPE


func _ready() -> void:
	build_mode = str(ProjectSettings.get_setting(BUILD_MODE_SETTING, MODE_PROTOTYPE))
	if not build_mode in [MODE_PROTOTYPE, MODE_VALIDATED]:
		push_error("ClinicalRules: unknown build mode '%s'; using validated (safest)" % build_mode)
		build_mode = MODE_VALIDATED
	for effect_id: String in ContentSchemas.NON_MEDICAL_EFFECTS:
		assert(NON_MEDICAL_EFFECT_FIELDS.has(effect_id), "Effect '%s' has no implementation" % effect_id)


func evaluate(patient_id: String, patient_state: Dictionary, event: Dictionary) -> Dictionary:
	var result: Dictionary = {"effects": [], "alerts": [], "review_flags": [], "rule_ids": []}
	var action_id: String = str(event.get("action_id", ""))
	var payload: Dictionary = event.get("payload", {})
	var findings: Array = payload.get("finding_ids", [])

	for rule: Dictionary in ContentRegistry.get_rules():
		if rule["patient_id"] != patient_id or rule["trigger_action"] != action_id:
			continue
		if not _condition_met(rule["condition"], patient_state, findings):
			continue

		var approved: bool = rule["review_status"] == "APPROVED"
		if not approved and build_mode == MODE_VALIDATED:
			_flag(result, rule["id"], "Rule is %s; not applied in validated build mode." % rule["review_status"])
			continue
		if rule["review_status"] == "REJECTED":
			_flag(result, rule["id"], "Rule is REJECTED; not applied.")
			continue

		result["rule_ids"].append(rule["id"])
		if not approved:
			_flag(result, rule["id"], "Unreviewed rule applied in prototype mode (non-medical effects only).")
		for effect_id: String in rule["non_medical_effects"]:
			var field: Array = NON_MEDICAL_EFFECT_FIELDS[effect_id]
			result["effects"].append({"path": "patients.%s.%s" % [patient_id, field[0]], "set": field[1]})
		if not rule["medical_effects"].is_empty():
			_flag(result, rule["id"], "medical_effects present but no approved medical effect vocabulary exists; ignored.")
	return result


## A condition holds when every listed observation has been recorded in state
## or is documented in this action's finding_ids.
func _condition_met(condition: Dictionary, patient_state: Dictionary, findings: Array) -> bool:
	var recorded: Dictionary = patient_state.get("observations", {})
	for observation_id: String in condition.get("observations_present", []):
		if not recorded.has(observation_id) and not observation_id in findings:
			return false
	return true


func _flag(result: Dictionary, rule_id: String, reason: String) -> void:
	result["review_flags"].append({"rule_id": rule_id, "reason": reason})
	EventBus.clinical_review_flagged.emit(rule_id, reason)
