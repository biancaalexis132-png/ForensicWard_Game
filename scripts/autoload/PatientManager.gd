extends Node
## PatientManager: mutable per-patient run state (Autoload "PatientManager").
##
## Patient *definitions* are immutable authored content (ContentRegistry).
## This manager owns what changes during play:
##   location, rapport, recorded observations (with provenance), assessment
##   fields, structured notes, narrative flags and a ledger of processed
##   event ids.
##
## Every state-changing call is keyed by a stable event_id. Replaying an
## event id is a no-op, so opening the same record twice or re-triggering a
## scene never duplicates events (MVP acceptance test 4).

const MUTABLE_ROOTS: Array[String] = ["assessment", "flags"]
const NOTE_PLAN_MAX_CHARS: int = 600

var _state: Dictionary = {} ## patient_id -> state Dictionary


func _ready() -> void:
	SaveManager.register_provider("patients", self)
	reset_state()


# --- Queries ------------------------------------------------------------------------

func get_definition(patient_id: String) -> Dictionary:
	return ContentRegistry.get_patient(patient_id)


## True once the patient's authored arrival shift has begun. Later arrivals
## keep state from a new game but stay off the census until then.
func is_admitted(patient_id: String) -> bool:
	return int(get_definition(patient_id).get("arrival_shift", 1)) <= TimeManager.get_shift_day()


## A deep copy, so callers can't mutate state behind the manager's back.
func get_state(patient_id: String) -> Dictionary:
	return _state.get(patient_id, {}).duplicate(true)


func get_location(patient_id: String) -> String:
	return _state.get(patient_id, {}).get("location", "")


func get_notes(patient_id: String) -> Array:
	return _state.get(patient_id, {}).get("notes", []).duplicate(true)


func has_processed(patient_id: String, event_id: String) -> bool:
	return event_id in _state.get(patient_id, {}).get("processed_events", [])


# --- Commands ------------------------------------------------------------------------

## Logs a record-opened audit event once per patient per day.
## Returns true only the first time.
func open_record(patient_id: String) -> bool:
	var event_id: String = "evt_record_opened_%s_d%d" % [patient_id, TimeManager.get_day()]
	if not _begin_event(patient_id, event_id):
		return false
	_append_audit(patient_id, {"event_id": event_id, "type": "record_opened", "at_minutes": TimeManager.total_minutes})
	EventBus.patient_record_opened.emit(patient_id, event_id)
	return true


## Records an authored observation as witnessed, with provenance.
## Returns false if unknown or already recorded.
func record_observation(patient_id: String, observation_id: String, recorded_by: String) -> bool:
	if not _find_authored_observation(patient_id, observation_id).is_empty():
		var observations: Dictionary = _state[patient_id]["observations"]
		if observations.has(observation_id):
			return false
		observations[observation_id] = {
			"recorded_by": recorded_by,
			"at_minutes": TimeManager.total_minutes,
			"verified": false,
		}
		EventBus.observation_recorded.emit(patient_id, observation_id)
		return true
	push_warning("PatientManager: unknown observation '%s' for %s" % [observation_id, patient_id])
	return false


## Saves a structured progress note. Notes are append-only: a saved note is
## never edited, which keeps the audit trail honest (GDD §9).
##   findings:       observation ids the physician cites; each must be recorded
##   considerations: differential tags kept under consideration (not diagnoses)
##   plan:           the physician's own free text, trimmed and length-limited
## Returns the new note id, or "" if the note is invalid.
func save_note(patient_id: String, findings: Array[String], considerations: Array[String], plan: String) -> String:
	if not _state.has(patient_id):
		push_error("PatientManager: unknown patient '%s'" % patient_id)
		return ""
	var state: Dictionary = _state[patient_id]
	var allowed_tags: Array = get_definition(patient_id)["differential_tags"]
	for finding: String in findings:
		if not state["observations"].has(finding):
			push_warning("PatientManager: note cites unrecorded observation '%s'" % finding)
			return ""
	for tag: String in considerations:
		if not tag in allowed_tags:
			push_warning("PatientManager: note cites unknown consideration '%s'" % tag)
			return ""
	var text: String = plan.strip_edges().left(NOTE_PLAN_MAX_CHARS)
	if findings.is_empty() and considerations.is_empty() and text.is_empty():
		return ""
	var notes: Array = state["notes"]
	var note_id: String = "note_%s_%03d" % [patient_id, notes.size() + 1]
	if not _begin_event(patient_id, "evt_" + note_id):
		return ""
	var sorted_findings: Array[String] = findings.duplicate()
	sorted_findings.sort()
	var sorted_considerations: Array[String] = considerations.duplicate()
	sorted_considerations.sort()
	notes.append({
		"id": note_id,
		"author": "player",
		"at_minutes": TimeManager.total_minutes,
		"day": TimeManager.get_shift_day(),
		"shift": TimeManager.get_shift(),
		"findings": sorted_findings,
		"considerations": sorted_considerations,
		"plan": text,
	})
	_append_audit(patient_id, {"event_id": "evt_" + note_id, "type": "note_saved", "at_minutes": TimeManager.total_minutes})
	EventBus.patient_note_saved.emit(patient_id, note_id)
	return note_id


## Adds a system entry to a chart's audit trail (e.g. a transfer request
## logged by the hospital system). It is a record of an event, never an
## observation or result. Deduped by event_id; returns true if new.
func add_chart_entry(patient_id: String, event_id: String, type: String, by: String, text: String) -> bool:
	if not _begin_event(patient_id, event_id):
		return false
	_append_audit(patient_id, {"event_id": event_id, "type": type, "by": by, "text": text,
			"at_minutes": TimeManager.total_minutes})
	EventBus.patient_state_changed.emit(patient_id, "audit", event_id)
	return true


## The dedupe id an EHR action gets today (one commit per shift day).
func action_event_id(patient_id: String, action_id: String) -> String:
	return "evt_d%d_%s_%s" % [TimeManager.get_shift_day(), action_id, patient_id]


## Commits an authored clinical action (data/clinical_rules.json "actions")
## from the EHR, citing the recorded findings. One commit per action per
## patient per shift day; repeats return {}. Costs the action's time.
func perform_action(patient_id: String, action_id: String, finding_ids: Array[String]) -> Dictionary:
	var action: Dictionary = ContentRegistry.get_action(action_id)
	if action.is_empty() or action["patient_id"] != patient_id:
		push_error("PatientManager: action '%s' is not offered for %s" % [action_id, patient_id])
		return {}
	var event: Dictionary = {
		"event_id": action_event_id(patient_id, action_id),
		"type": "clinical_action",
		"patient_id": patient_id,
		"action_id": action_id,
		"at_minutes": TimeManager.total_minutes,
		"payload": {"finding_ids": finding_ids.duplicate()},
	}
	var result: Dictionary = commit_clinical_action(event)
	if not result.is_empty():
		TimeManager.advance(int(action["time_minutes"]), "clinical_action:" + action_id)
	return result


## Commits a coded clinical action event, e.g.
##   {"event_id": "evt_day1_assess_catatonia", "type": "clinical_action",
##    "patient_id": "pt_elias_ward", "action_id": "evaluate_catatonia",
##    "payload": {"finding_ids": ["obs_mutism", "obs_posturing"]}}
## ClinicalRules decides the structured effects; this manager applies them.
## Returns the ClinicalRules result, or {} if the event was a duplicate/invalid.
func commit_clinical_action(event: Dictionary) -> Dictionary:
	var patient_id: String = str(event.get("patient_id", ""))
	var event_id: String = str(event.get("event_id", ""))
	var action_id: String = str(event.get("action_id", ""))
	if event_id.is_empty() or action_id.is_empty():
		push_error("PatientManager: clinical action needs event_id and action_id: %s" % event)
		return {}
	if not _begin_event(patient_id, event_id):
		return {}

	var result: Dictionary = ClinicalRules.evaluate(patient_id, get_state(patient_id), event)
	for effect: Dictionary in result["effects"]:
		apply_effect(effect["path"], effect["set"])
	_append_audit(patient_id, {"event_id": event_id, "type": "clinical_action", "action_id": action_id,
			"at_minutes": TimeManager.total_minutes, "rule_ids": result["rule_ids"],
			"review_flags": result["review_flags"].map(func(f: Dictionary) -> String: return f["reason"])})
	EventBus.clinical_action_committed.emit(patient_id, action_id, event_id)
	return result


## Applies one structured effect like "patients.pt_elias_ward.assessment.started".
## Only fields under MUTABLE_ROOTS can be written this way.
func apply_effect(path: String, value: Variant) -> bool:
	var parts: PackedStringArray = path.split(".")
	if parts.size() < 4 or parts[0] != "patients" or not _state.has(parts[1]) or not parts[2] in MUTABLE_ROOTS:
		push_error("PatientManager: effect path '%s' is not writable" % path)
		return false
	var node: Dictionary = _state[parts[1]][parts[2]]
	for i: int in range(3, parts.size() - 1):
		if not node.has(parts[i]) or not node[parts[i]] is Dictionary:
			node[parts[i]] = {}
		node = node[parts[i]]
	node[parts[parts.size() - 1]] = value
	EventBus.patient_state_changed.emit(parts[1], ".".join(parts.slice(2)), value)
	return true


## Moves a patient. A patient has exactly one location, so contradictions like
## "ICU and Ward Zero at once" are impossible by construction. Automatic
## (story-driven) transfers are blocked while the authored
## `must_not_auto_transfer_if` flag is set, and the block is flagged for review.
func set_location(patient_id: String, location: String, reason: String, automatic: bool = false) -> bool:
	if not _state.has(patient_id) or not location in ContentSchemas.PATIENT_LOCATIONS:
		push_error("PatientManager: invalid location change %s -> %s" % [patient_id, location])
		return false
	var blocking_flag: String = get_definition(patient_id).get("must_not_auto_transfer_if", "")
	if automatic and not blocking_flag.is_empty() and blocking_flag in _state[patient_id]["flags"]:
		EventBus.clinical_review_flagged.emit("transfer_guard",
				"Blocked automatic transfer of %s to %s (%s): patient is %s." % [patient_id, location, reason, blocking_flag])
		return false
	var previous: String = _state[patient_id]["location"]
	if previous == location:
		return true
	_state[patient_id]["location"] = location
	EventBus.patient_location_changed.emit(patient_id, previous, location)
	return true


func set_flag(patient_id: String, flag: String, enabled: bool) -> void:
	if not _state.has(patient_id):
		return
	var flags: Array = _state[patient_id]["flags"]
	if enabled and not flag in flags:
		flags.append(flag)
		flags.sort()
	elif not enabled:
		flags.erase(flag)


func adjust_rapport(patient_id: String, delta: float) -> void:
	if not _state.has(patient_id) or is_zero_approx(delta):
		return
	var value: float = clampf(_state[patient_id]["rapport"] + delta, -100.0, 100.0)
	_state[patient_id]["rapport"] = value
	EventBus.rapport_changed.emit(patient_id, value)


# --- Internals --------------------------------------------------------------------------

func _begin_event(patient_id: String, event_id: String) -> bool:
	if not _state.has(patient_id):
		push_error("PatientManager: unknown patient '%s'" % patient_id)
		return false
	var processed: Array = _state[patient_id]["processed_events"]
	if event_id in processed:
		return false
	processed.append(event_id)
	return true


func _append_audit(patient_id: String, entry: Dictionary) -> void:
	_state[patient_id]["audit"].append(entry)


func _find_authored_observation(patient_id: String, observation_id: String) -> Dictionary:
	var definition: Dictionary = get_definition(patient_id)
	if definition.is_empty():
		return {}
	for observation: Dictionary in definition["presentation"]["observations"]:
		if observation["id"] == observation_id:
			return observation
	return {}


func _initial_state(definition: Dictionary) -> Dictionary:
	var flags: Array = definition.get("narrative_flags", []).duplicate()
	return {
		"location": definition["current_location"],
		"rapport": float(definition["initial_rapport"]),
		"observations": {},
		"assessment": {},
		"notes": [],
		"flags": flags,
		"processed_events": [],
		"audit": [],
	}


# --- Save provider -----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return _state.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	reset_state()
	for patient_id: String in data:
		if _state.has(patient_id):
			var saved: Dictionary = data[patient_id]
			var state: Dictionary = _state[patient_id]
			for key: String in state:
				if saved.has(key) and typeof(saved[key]) == typeof(state[key]):
					state[key] = saved[key]
				elif saved.has(key) and key == "rapport":
					state[key] = float(saved[key])
		else:
			push_warning("PatientManager: save references unknown patient '%s' (skipped)" % patient_id)


func reset_state() -> void:
	_state.clear()
	if not ContentRegistry.is_valid:
		return
	for patient_id: String in ContentRegistry.get_patient_ids():
		_state[patient_id] = _initial_state(ContentRegistry.get_patient(patient_id))
