class_name ClinicalOrders
extends RefCounted
## ClinicalOrders: what the EHR Orders tab shows about each catalog order
## (data/order_catalog.json) for one patient, derived from saved state.
##
## Status comes from PatientManager's processed events and audit trail, so it
## survives save and load and cannot be placed twice in one shift day. Placing
## goes through PatientManager.perform_action: one audited event, the action's
## time cost, and only the effects an approved ClinicalRules rule allows.
## Nothing here sets story flags or simulates a result.

const AVAILABLE: String = "available"
const NEEDS_PREREQUISITES: String = "needs_prerequisites"
const COMPLETED: String = "completed"
const AWAITING_RESPONSE: String = "awaiting_response"
const REVIEW_BLOCKED: String = "review_blocked"


## {state, can_place, label, reason, missing: Array[String]} for one order.
static func status(patient_id: String, order: Dictionary) -> Dictionary:
	var action: Dictionary = ContentRegistry.get_action(order["action_id"])
	var missing: Array[String] = missing_prerequisites(patient_id, order)
	var placed_today: bool = PatientManager.has_processed(patient_id,
			PatientManager.action_event_id(patient_id, order["action_id"]))
	var result: Dictionary = {"state": AVAILABLE, "can_place": not placed_today, "label": "Available",
			"reason": "", "missing": missing}
	if not is_action_approved(action) and ClinicalRules.build_mode == ClinicalRules.MODE_VALIDATED:
		result.merge({"state": REVIEW_BLOCKED, "can_place": false, "label": "Awaiting clinical review",
				"reason": "This order awaits clinical review and is switched off in this build."}, true)
	elif order["completion"] == "awaiting_response" and not history(patient_id, order).is_empty():
		result.merge({"state": AWAITING_RESPONSE, "label": "Requested, awaiting response",
				"reason": "Placed once today. The request stays open; no result is simulated." if placed_today else ""}, true)
	elif placed_today:
		result.merge({"state": COMPLETED, "label": "Completed today", "reason": "Already placed this shift day."}, true)
	elif not missing.is_empty():
		result.merge({"state": NEEDS_PREREQUISITES, "label": "Findings needed",
				"reason": str(order["prerequisites"]["explanation"])}, true)
	return result


## Prerequisite findings the player has not yet witnessed and recorded.
static func missing_prerequisites(patient_id: String, order: Dictionary) -> Array[String]:
	var recorded: Dictionary = PatientManager.get_state(patient_id).get("observations", {})
	var missing: Array[String] = []
	for observation_id: String in order.get("prerequisites", {}).get("observations", []):
		if not recorded.has(observation_id):
			missing.append(observation_id)
	return missing


## Audit entries for this order's action, oldest first.
static func history(patient_id: String, order: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry: Dictionary in PatientManager.get_state(patient_id).get("audit", []):
		if entry.get("type", "") == "clinical_action" and entry.get("action_id", "") == order["action_id"]:
			entries.append(entry)
	return entries


## An action is approved when it and every rule it triggers are approved.
static func is_action_approved(action: Dictionary) -> bool:
	if action.get("clinical_review_status", "") != "APPROVED":
		return false
	for rule: Dictionary in ContentRegistry.get_rules():
		if rule["trigger_action"] == action.get("id", "") and rule["review_status"] != "APPROVED":
			return false
	return true
