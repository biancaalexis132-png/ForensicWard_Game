class_name PracticeCase
extends RefCounted
## Deterministic, non-medical case lifecycle. Notes remain in PatientManager.
const SOURCE_TYPES: Array[String] = ["PATIENT_REPORTED", "STAFF_REPORTED", "DIRECT_OBSERVATION", "CHART_RECORD", "UNAVAILABLE"]
var definition: Dictionary
var _state: Dictionary = defaults()

static func defaults() -> Dictionary:
	return {"status": "available", "encounter": 0, "encounters": {}, "events": [], "tasks": [], "sources": [], "consent": false}

func _init(case_definition: Dictionary = {}) -> void:
	definition = case_definition.duplicate(true)

func ready_for_play() -> bool:
	if definition.get("clinical_review_status") != "APPROVED" or definition.get("no_automatic_medical_effects") != true:
		return false
	if definition.get("encounters", []).size() != 5 or definition.get("patient", {}).get("clinical_review_status") != "APPROVED":
		return false
	for encounter: Dictionary in definition["encounters"]:
		if encounter.get("clinical_review_status") != "APPROVED" or not encounter.get("dialogue") is Dictionary or encounter["dialogue"].get("clinical_review_status") != "APPROVED":
			return false
	return true

func accept(campaign_complete: bool) -> bool:
	if not campaign_complete or not ready_for_play() or _state["status"] != "available":
		return false
	_state["status"] = "accepted"
	_state["encounter"] = 1
	return true

func record(kind: String, reference: String, event_id: String) -> bool:
	if not _state["status"] in ["accepted", "active"] or kind not in ["interview", "note"] or reference.is_empty() or event_id.is_empty() or event_id in _state["events"]:
		return false
	var key: String = str(_state["encounter"])
	var encounter: Dictionary = _state["encounters"].get(key, {})
	if encounter.has(kind):
		return false
	encounter[kind] = reference
	_state["encounters"][key] = encounter
	_state["events"].append(event_id)
	_state["status"] = "active"
	return true

func finish_encounter() -> bool:
	if _state["status"] != "active":
		return false
	var encounter: Dictionary = _state["encounters"].get(str(_state["encounter"]), {})
	if not encounter.has("interview") or not encounter.has("note") or not tasks_accounted_for():
		return false
	encounter["completed"] = true
	if int(_state["encounter"]) == 5:
		_state["status"] = "followup_cycle_complete"
	else:
		_state["encounter"] = int(_state["encounter"]) + 1
		_state["status"] = "accepted"
	return true

func add_task(id: String, description: String, owner: String, review_point: String, safety_blocking: bool = false) -> bool:
	if not _state["status"] in ["accepted", "active", "on_hold"] or id.is_empty() or description.strip_edges().is_empty() or owner.strip_edges().is_empty() or review_point.strip_edges().is_empty():
		return false
	for task: Dictionary in _state["tasks"]:
		if task["id"] == id:
			return false
	_state["tasks"].append({"id": id, "description": description.left(512), "owner": owner.left(96),
			"review_point": review_point.left(128), "status": "pending", "safety_blocking": safety_blocking})
	return true

func update_task(id: String, status: String) -> bool:
	if status not in ["completed", "handoff_pending", "handoff_acknowledged"]:
		return false
	for task: Dictionary in _state["tasks"]:
		if task["id"] == id:
			if task["status"] == "completed" or (status == "handoff_acknowledged" and task["status"] != "handoff_pending"):
				return false
			task["status"] = status
			return true
	return false

func tasks_accounted_for() -> bool:
	for task: Dictionary in _state["tasks"]:
		if task["status"] != "completed" and (task["status"] != "handoff_acknowledged" or task["safety_blocking"]):
			return false
	return true

func set_hold(hold: bool) -> void:
	if _state["status"] in ["accepted", "active", "on_hold"]:
		_state["status"] = "on_hold" if hold else "active"

func record_source(source_id: String, source_type: String, verified: bool = false) -> bool:
	var known: bool = false
	for source: Dictionary in definition.get("source_catalog", []):
		if source.get("id") == source_id and source.get("type") == source_type:
			known = true
	if not known or source_id.is_empty() or source_type not in SOURCE_TYPES or (verified and source_type != "DIRECT_OBSERVATION"):
		return false
	for source: Dictionary in _state["sources"]:
		if source["id"] == source_id:
			return false
	_state["sources"].append({"id": source_id, "type": source_type, "verified": verified})
	return true

func set_collateral_consent(consent: bool) -> void:
	_state["consent"] = consent

func can_contact_collateral() -> bool:
	return bool(_state["consent"])

func to_save_data() -> Dictionary:
	return _state.duplicate(true)

static func valid_state(data: Variant) -> bool:
	if not data is Dictionary or not data.get("status") in ["available", "accepted", "active", "on_hold", "followup_cycle_complete"]:
		return false
	if not (data.get("encounter") is int or data.get("encounter") is float) or int(data["encounter"]) < 0 or int(data["encounter"]) > 5 or float(data["encounter"]) != int(data["encounter"]):
		return false
	if not data.get("encounters") is Dictionary or not data.get("events") is Array or not data.get("tasks") is Array or not data.get("sources") is Array or not data.get("consent") is bool:
		return false
	var seen: Dictionary = {}
	for event: Variant in data["events"]:
		if not event is String or event.is_empty() or seen.has(event):
			return false
		seen[event] = true
	for key: Variant in data["encounters"]:
		if not str(key).is_valid_int() or int(key) < 1 or int(key) > 5 or not data["encounters"][key] is Dictionary:
			return false
		for kind: Variant in data["encounters"][key]:
			if kind not in ["interview", "note", "completed"]:
				return false
			if kind == "completed":
				if not data["encounters"][key][kind] is bool:
					return false
			elif not data["encounters"][key][kind] is String:
				return false
	seen.clear()
	for task: Variant in data["tasks"]:
		if not task is Dictionary or not task.get("safety_blocking") is bool or not task.get("status") in ["pending", "completed", "handoff_pending", "handoff_acknowledged"]:
			return false
		for key: String in ["id", "description", "owner", "review_point"]:
			if not task.get(key) is String or task[key].strip_edges().is_empty():
				return false
		if seen.has(task["id"]):
			return false
		seen[task["id"]] = true
	for source: Variant in data["sources"]:
		if not source is Dictionary or not source.get("id") is String or not source.get("verified") is bool or source.get("type") not in SOURCE_TYPES:
			return false
		if source["verified"] and source["type"] != "DIRECT_OBSERVATION":
			return false
	return true

func load_save_data(data: Dictionary) -> bool:
	if not valid_state(data):
		return false
	_state = data.duplicate(true)
	_state["encounter"] = int(_state["encounter"])
	return true
