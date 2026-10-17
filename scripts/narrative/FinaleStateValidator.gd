class_name FinaleStateValidator
extends RefCounted
## Pure Chapter 5 finale contract validation. This class owns no run state,
## save provider, clinical content, events, RNG, or supernatural effects.

static func validate_state(value: Variant, clinical_task_catalog: Variant,
		required_task_ids: Variant) -> Dictionary:
	var errors: Array[String] = []
	errors.append_array(_shape_errors(value, FinaleStateSchemas.STATE, "finale"))
	errors.append_array(_shape_errors(clinical_task_catalog, FinaleStateSchemas.CLINICAL_TASK_CATALOG,
			"clinical_task_catalog"))
	errors.append_array(_shape_errors(required_task_ids, FinaleStateSchemas.REQUIRED_TASK_IDS, "required_task_ids"))
	if not errors.is_empty():
		return _report(errors)

	var required_seen: Dictionary = {}
	for i: int in required_task_ids.size():
		var task_id: String = required_task_ids[i]
		if required_seen.has(task_id):
			errors.append("required_task_ids[%d]: duplicate required task '%s'." % [i, task_id])
		required_seen[task_id] = true
		if not clinical_task_catalog.has(task_id):
			errors.append("required_task_ids[%d]: unknown clinical task '%s'." % [i, task_id])
		elif clinical_task_catalog[task_id]["clinical_review_status"] != "APPROVED":
			errors.append("required_task_ids[%d]: clinical task '%s' is not approved." % [i, task_id])

	var tasks_by_id: Dictionary = {}
	for i: int in value["clinical_tasks"].size():
		var task: Dictionary = value["clinical_tasks"][i]
		var task_id: String = task["task_id"]
		if tasks_by_id.has(task_id):
			errors.append("finale.clinical_tasks[%d].task_id: duplicate task '%s'." % [i, task_id])
		else:
			tasks_by_id[task_id] = task
		if not clinical_task_catalog.has(task_id):
			errors.append("finale.clinical_tasks[%d].task_id: unknown clinical task '%s'." % [i, task_id])
		elif clinical_task_catalog[task_id]["clinical_review_status"] != "APPROVED":
			errors.append("finale.clinical_tasks[%d].task_id: clinical task '%s' is not approved." % [i, task_id])

	for task_id: String in required_seen:
		if not tasks_by_id.has(task_id):
			errors.append("finale.clinical_tasks: missing required task '%s'." % task_id)

	var evidence_by_id: Dictionary = {}
	for i: int in value["evidence"].size():
		var item: Dictionary = value["evidence"][i]
		var evidence_id: String = item["evidence_id"]
		if evidence_by_id.has(evidence_id):
			errors.append("finale.evidence[%d].evidence_id: duplicate evidence '%s'." % [i, evidence_id])
		else:
			evidence_by_id[evidence_id] = item
		var has_derivation: bool = not item["derived_from"].is_empty()
		if has_derivation and item.has("source_id"):
			errors.append("finale.evidence[%d].source_id: derived evidence cannot claim a new acquisition source." % i)
		elif not has_derivation and not item.has("source_id"):
			errors.append("finale.evidence[%d].source_id: original evidence needs an acquisition source id." % i)
		var dependency_seen: Dictionary = {}
		for j: int in item["derived_from"].size():
			var dependency_id: String = item["derived_from"][j]
			if dependency_seen.has(dependency_id):
				errors.append("finale.evidence[%d].derived_from[%d]: duplicate dependency '%s'." % [
						i, j, dependency_id])
			dependency_seen[dependency_id] = true

	for i: int in value["evidence"].size():
		var item: Dictionary = value["evidence"][i]
		for j: int in item["derived_from"].size():
			var dependency_id: String = item["derived_from"][j]
			if not evidence_by_id.has(dependency_id):
				errors.append("finale.evidence[%d].derived_from[%d]: unknown evidence '%s'." % [
						i, j, dependency_id])
	var visit_states: Dictionary = {}
	for evidence_id: String in evidence_by_id:
		_visit_evidence(evidence_id, evidence_by_id, visit_states, errors)

	var gates_satisfied: bool = _gates_satisfied(value, required_seen, tasks_by_id)
	if value["decision"] != "none" and not gates_satisfied:
		errors.append("finale.decision: an ending can be selected only after required gates are satisfied.")
	if value["completed"] and value["decision"] == "none":
		errors.append("finale.completed: a completed finale needs an institutional decision.")
	if value["completed"] and not gates_satisfied:
		errors.append("finale.completed: required gates are not satisfied.")
	return _report(errors)


## Returns all three responsible pathways only after the required gates pass.
## Eligibility intentionally has no protagonist, relationship, belief, or patient input.
static func get_available_endings(value: Variant, clinical_task_catalog: Variant,
		required_task_ids: Variant) -> Array[String]:
	var validation: Dictionary = validate_state(value, clinical_task_catalog, required_task_ids)
	if not validation["errors"].is_empty():
		return []
	var required_seen: Dictionary = {}
	for task_id: String in required_task_ids:
		required_seen[task_id] = true
	var tasks_by_id: Dictionary = {}
	for task: Dictionary in value["clinical_tasks"]:
		tasks_by_id[task["task_id"]] = task
	if not _gates_satisfied(value, required_seen, tasks_by_id):
		return []
	return FinaleStateSchemas.ENDINGS.duplicate()


## Returns unique original acquisition source IDs that are both authenticated
## and accepted in review. This does not prove real-world source independence.
static func get_unique_authenticated_source_ids(evidence: Array) -> Array[String]:
	var sources: Dictionary = {}
	for item: Dictionary in evidence:
		if item["derived_from"].is_empty() and item["authentication_status"] == "authenticated" \
				and item["review_status"] == "accepted" and item.has("source_id"):
			sources[item["source_id"]] = true
	var result: Array[String] = []
	result.assign(sources.keys())
	result.sort()
	return result


static func _gates_satisfied(state: Dictionary, required_task_ids: Dictionary, tasks_by_id: Dictionary) -> bool:
	for task_id: String in required_task_ids:
		if not tasks_by_id.has(task_id) or not tasks_by_id[task_id]["outcome"] in ["completed", "safely_escalated"]:
			return false
	for evidence: Dictionary in state["evidence"]:
		if evidence["authentication_status"] == "pending" or evidence["review_status"] == "pending":
			return false
	return state["report_status"] == "reviewed"


static func _shape_errors(value: Variant, schema: Dictionary, path: String) -> Array[String]:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	ContentValidator.validate_value(value, schema, path, errors, warnings)
	for warning: String in warnings:
		errors.append(warning.replace("(ignored)", "(not allowed)"))
	return errors


static func _visit_evidence(evidence_id: String, evidence_by_id: Dictionary,
		visit_states: Dictionary, errors: Array[String]) -> void:
	var visit_state: int = int(visit_states.get(evidence_id, 0))
	if visit_state == 2:
		return
	if visit_state == 1:
		errors.append("finale.evidence: derivation cycle includes '%s'." % evidence_id)
		return
	visit_states[evidence_id] = 1
	var item: Dictionary = evidence_by_id[evidence_id]
	for dependency_id: String in item["derived_from"]:
		if evidence_by_id.has(dependency_id):
			_visit_evidence(dependency_id, evidence_by_id, visit_states, errors)
	visit_states[evidence_id] = 2


static func _report(errors: Array[String]) -> Dictionary:
	return {"errors": errors, "warnings": [] as Array[String]}
