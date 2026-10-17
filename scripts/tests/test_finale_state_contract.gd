extends TestCase
## Pure Chapter 5 ending-state contract tests. All clinical records are
## synthetic identifiers; no clinical content or runtime state is authored.

const APPROVED_TASKS: Dictionary = {
	"task_test_rounds": {"clinical_review_status": "APPROVED"},
	"task_test_handover": {"clinical_review_status": "APPROVED"},
	"task_test_pending": {"clinical_review_status": "PENDING_PSYCHIATRIST_REVIEW"},
}
const REQUIRED_TASKS: Array[String] = ["task_test_rounds", "task_test_handover"]


func test_incomplete_state_is_valid_but_has_no_endings() -> void:
	var state: Dictionary = _base_state()
	state["clinical_tasks"][0]["outcome"] = "pending"
	check(_validate(state)["errors"].is_empty(), "in-progress state is structurally valid")
	check(FinaleStateValidator.get_available_endings(state, APPROVED_TASKS, REQUIRED_TASKS).is_empty(),
			"incomplete clinical responsibility keeps endings unavailable")


func test_all_three_endings_are_available_after_required_gates() -> void:
	var state: Dictionary = _ready_state()
	check_eq(FinaleStateValidator.get_available_endings(state, APPROVED_TASKS, REQUIRED_TASKS),
			FinaleStateSchemas.ENDINGS, "all responsible endings are available")


func test_profile_relationship_belief_patient_and_corridor_fields_cannot_gate_endings() -> void:
	var state: Dictionary = _ready_state()
	for field: String in ["protagonist_profile", "relationship_scores", "supernatural_belief",
			"patient_diagnosis", "corridor_loop_revealed"]:
		state[field] = "arbitrary test value"
		check_contains(_validate(state)["errors"], "not allowed", "unrecognized %s field is rejected" % field)
	check(FinaleStateValidator.get_available_endings(_ready_state(), APPROVED_TASKS, REQUIRED_TASKS).size() == 3,
			"all pathways are available without profile, relationship, belief, patient, or corridor inputs")


func test_required_clinical_task_must_be_approved() -> void:
	var state: Dictionary = _ready_state()
	state["clinical_tasks"].append({"task_id": "task_test_pending", "outcome": "completed"})
	var result: Dictionary = FinaleStateValidator.validate_state(state, APPROVED_TASKS,
			["task_test_pending"] as Array[String])
	check_contains(result["errors"], "is not approved", "pending clinical content cannot satisfy the gate")
	check(FinaleStateValidator.get_available_endings(state, APPROVED_TASKS,
			["task_test_pending"] as Array[String]).is_empty(), "unapproved task blocks ending eligibility")


func test_missing_required_task_blocks_endings() -> void:
	var state: Dictionary = _ready_state()
	state["clinical_tasks"].pop_back()
	check_contains(_validate(state)["errors"], "missing required task", "missing task is reported")
	check(FinaleStateValidator.get_available_endings(state, APPROVED_TASKS, REQUIRED_TASKS).is_empty(),
			"missing clinical responsibility blocks endings")


func test_safely_escalated_approved_task_resolves_gate() -> void:
	var state: Dictionary = _ready_state()
	state["clinical_tasks"][1]["outcome"] = "safely_escalated"
	check(_validate(state)["errors"].is_empty(), "approved safe escalation is accepted")
	check_eq(FinaleStateValidator.get_available_endings(state, APPROVED_TASKS, REQUIRED_TASKS).size(), 3,
			"escalation is a valid alternative to completion")


func test_evidence_authentication_and_review_are_separate_gates() -> void:
	var state: Dictionary = _ready_state()
	state["evidence"][0]["review_status"] = "unresolved"
	check_eq(FinaleStateValidator.get_unique_authenticated_source_ids(state["evidence"]), [] as Array[String],
			"authenticated but unresolved evidence is not counted as accepted corroboration")
	check(FinaleStateValidator.get_available_endings(state, APPROVED_TASKS, REQUIRED_TASKS).size() == 3,
			"explicitly reviewed unresolved evidence does not erase a responsible ending")
	state["evidence"][0]["authentication_status"] = "pending"
	check(FinaleStateValidator.get_available_endings(state, APPROVED_TASKS, REQUIRED_TASKS).is_empty(),
			"unreviewed authentication keeps the review gate open")


func test_copies_and_derived_artifacts_do_not_add_independent_sources() -> void:
	var state: Dictionary = _ready_state()
	state["evidence"].append({
		"evidence_id": "evidence_test_copy",
		"source_id": "source_test_camera",
		"derived_from": [],
		"authentication_status": "authenticated",
		"review_status": "accepted",
	})
	state["evidence"].append({
		"evidence_id": "evidence_test_export",
		"derived_from": ["evidence_test_camera"],
		"authentication_status": "authenticated",
		"review_status": "accepted",
	})
	check(_validate(state)["errors"].is_empty(), "source copies and derived export have valid lineage")
	check_eq(FinaleStateValidator.get_unique_authenticated_source_ids(state["evidence"]),
			["source_test_camera"] as Array[String], "same-source copy/export still counts as one source")


func test_distinct_acquisition_sources_remain_distinct() -> void:
	var state: Dictionary = _ready_state()
	state["evidence"].append({
		"evidence_id": "evidence_test_marker",
		"source_id": "source_test_physical_marker",
		"derived_from": [],
		"authentication_status": "authenticated",
		"review_status": "accepted",
	})
	check_eq(FinaleStateValidator.get_unique_authenticated_source_ids(state["evidence"]),
			["source_test_camera", "source_test_physical_marker"] as Array[String],
			"distinct raw acquisition source IDs remain distinct without claiming independent origins")


func test_duplicate_task_ids_and_lineage_edges_are_rejected() -> void:
	var state: Dictionary = _ready_state()
	state["clinical_tasks"].append(state["clinical_tasks"][0].duplicate(true))
	check_contains(_validate(state)["errors"], "duplicate task", "duplicate clinical task ID")
	state = _ready_state()
	state["evidence"][0]["derived_from"] = ["evidence_test_camera", "evidence_test_camera"]
	check_contains(_validate(state)["errors"], "duplicate dependency", "duplicate evidence lineage edge")


func test_broken_or_cyclic_evidence_lineage_is_rejected() -> void:
	var state: Dictionary = _ready_state()
	state["evidence"][0]["derived_from"] = ["evidence_missing"]
	check_contains(_validate(state)["errors"], "unknown evidence", "dangling derivation")
	state = _ready_state()
	state["evidence"][0]["derived_from"] = ["evidence_test_derived"]
	state["evidence"].append({
		"evidence_id": "evidence_test_derived",
		"derived_from": ["evidence_test_camera"],
		"authentication_status": "authenticated",
		"review_status": "accepted",
	})
	check_contains(_validate(state)["errors"], "derivation cycle", "cyclic derivation")


func test_duplicate_ids_and_invalid_decisions_are_rejected() -> void:
	var state: Dictionary = _ready_state()
	state["evidence"].append(state["evidence"][0].duplicate(true))
	check_contains(_validate(state)["errors"], "duplicate evidence", "duplicate evidence ID")
	state = _ready_state()
	state["decision"] = "secret_ending"
	check_contains(_validate(state)["errors"], "not allowed", "unknown ending")


func test_decision_and_completion_require_satisfied_gates() -> void:
	var state: Dictionary = _base_state()
	state["decision"] = "restricted_access"
	check_contains(_validate(state)["errors"], "only after required gates", "early decision rejected")
	state = _ready_state()
	state["completed"] = true
	check_contains(_validate(state)["errors"], "needs an institutional decision", "completion needs a decision")
	state["decision"] = "independent_review"
	check(_validate(state)["errors"].is_empty(), "completed decision after gates is valid")


func test_validation_is_deterministic_and_does_not_mutate_inputs() -> void:
	var state: Dictionary = _ready_state()
	var before: String = JSON.stringify(state)
	var patient_before: String = JSON.stringify(PatientManager.get_state("pt_elias_ward"))
	var save_state_before: String = JSON.stringify(SaveManager.capture_state())
	var seed_before: int = SaveManager.run_seed
	var first: Dictionary = _validate(state)
	var second: Dictionary = _validate(state)
	check_eq(JSON.stringify(first), JSON.stringify(second), "same input has same validation report")
	check_eq(JSON.stringify(state), before, "validator does not mutate finale state")
	check_eq(JSON.stringify(PatientManager.get_state("pt_elias_ward")), patient_before,
			"validation does not mutate clinical patient state")
	check_eq(JSON.stringify(SaveManager.capture_state()), save_state_before, "validation does not mutate saved providers")
	check_eq(SaveManager.run_seed, seed_before, "validation does not mutate run seed")
	check_eq(JSON.stringify(APPROVED_TASKS), JSON.stringify({
			"task_test_rounds": {"clinical_review_status": "APPROVED"},
			"task_test_handover": {"clinical_review_status": "APPROVED"},
			"task_test_pending": {"clinical_review_status": "PENDING_PSYCHIATRIST_REVIEW"},
	}), "validator does not mutate clinical catalog")


func _validate(state: Dictionary) -> Dictionary:
	return FinaleStateValidator.validate_state(state, APPROVED_TASKS, REQUIRED_TASKS)


func _ready_state() -> Dictionary:
	var state: Dictionary = _base_state()
	for task: Dictionary in state["clinical_tasks"]:
		task["outcome"] = "completed"
	state["report_status"] = "reviewed"
	return state


func _base_state() -> Dictionary:
	return {
		"schema_version": FinaleStateSchemas.VERSION,
		"clinical_tasks": [
			{"task_id": "task_test_rounds", "outcome": "pending"},
			{"task_id": "task_test_handover", "outcome": "pending"},
		],
		"evidence": [{
			"evidence_id": "evidence_test_camera",
			"source_id": "source_test_camera",
			"derived_from": [],
			"authentication_status": "authenticated",
			"review_status": "accepted",
		}],
		"report_status": "not_started",
		"decision": "none",
		"completed": false,
	}
