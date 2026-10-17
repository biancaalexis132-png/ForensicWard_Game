class_name StoryLogic
extends RefCounted
## StoryLogic: the small, closed vocabulary that story data
## (data/story_*.json) may use, with validation and evaluation.
##
## A condition is an object with exactly one key:
##   {"talked_to": staff_id}
##   {"observations_recorded": {"patient_id": id, "min": n}}
##   {"note_saved": patient_id}
##   {"action_committed": patient_id}
##   {"clue_acquired": clue_id}
##   {"hypothesis_supported": hypothesis_id}   status "supported"
##   {"shift": "day" | "night"}
##   {"day": n}                                 shift day
##   {"flag": story_flag}
##   {"trust_at_least": {"staff_id", "axis", "value"}}
##   {"all": [conditions]}, {"any": [conditions]}
## An action is an object with exactly one key:
##   {"audio_event": event_id}       EventBus.narrative_event_fired
##   {"notify": text}
##   {"flag": story_flag}
##   {"chart_entry": {"patient_id", "type", "by", "text"}}   EHR audit entry
##   {"world_state": {"group", "state"}}
## Evaluation is read-only. Narrative state never changes clinical state:
## chart entries are audit records, not observations or results.

const CONDITIONS: Array[String] = ["talked_to", "observations_recorded", "note_saved", "action_committed",
		"clue_acquired", "hypothesis_supported", "shift", "day", "flag", "trust_at_least", "all", "any"]
const ACTIONS: Array[String] = ["audio_event", "notify", "flag", "chart_entry", "world_state"]
## Same axes as TrustManager.AXES; duplicated because content is validated
## before the TrustManager autoload exists.
const TRUST_AXES: Array[String] = ["respect", "trust", "suspicion"]


## Validates a condition. `refs` holds id sets: patients, clues, hypotheses, staff.
static func check_condition(condition: Variant, path: String, refs: Dictionary, errors: Array[String]) -> void:
	if not condition is Dictionary or condition.size() != 1:
		errors.append("%s: a condition is an object with exactly one key (one of %s)." % [path, ", ".join(CONDITIONS)])
		return
	var kind: String = condition.keys()[0]
	var value: Variant = condition[kind]
	var at: String = "%s.%s" % [path, kind]
	match kind:
		"talked_to":
			_check_ref(value, refs["staff"], "staff", at, errors)
		"note_saved", "action_committed":
			_check_ref(value, refs["patients"], "patient", at, errors)
		"clue_acquired":
			_check_ref(value, refs["clues"], "clue", at, errors)
		"hypothesis_supported":
			_check_ref(value, refs["hypotheses"], "hypothesis", at, errors)
		"observations_recorded":
			if not value is Dictionary or not value.has("patient_id") or not value.has("min"):
				errors.append("%s: needs {\"patient_id\", \"min\"}." % at)
			else:
				_check_ref(value["patient_id"], refs["patients"], "patient", at + ".patient_id", errors)
		"shift":
			if not value in ["day", "night"]:
				errors.append("%s: must be \"day\" or \"night\"." % at)
		"day":
			if not (value is int or value is float) or int(value) < 1:
				errors.append("%s: must be a day number from 1." % at)
		"flag":
			if not value is String or (value as String).is_empty():
				errors.append("%s: must be a flag name." % at)
		"trust_at_least":
			if not value is Dictionary or not value.has("staff_id") or not value.get("axis", "") in TRUST_AXES \
					or not (value.get("value") is int or value.get("value") is float):
				errors.append("%s: needs {\"staff_id\", \"axis\" (respect/trust/suspicion), \"value\"}." % at)
			else:
				_check_ref(value["staff_id"], refs["staff"], "staff", at + ".staff_id", errors)
		"all", "any":
			if not value is Array or value.is_empty():
				errors.append("%s: must be a non-empty list of conditions." % at)
			else:
				for i: int in value.size():
					check_condition(value[i], "%s[%d]" % [at, i], refs, errors)
		_:
			errors.append("%s: unknown condition '%s'. Use one of: %s." % [path, kind, ", ".join(CONDITIONS)])


static func check_action(action: Variant, path: String, refs: Dictionary, errors: Array[String]) -> void:
	if not action is Dictionary or action.size() != 1:
		errors.append("%s: an action is an object with exactly one key (one of %s)." % [path, ", ".join(ACTIONS)])
		return
	var kind: String = action.keys()[0]
	var value: Variant = action[kind]
	var at: String = "%s.%s" % [path, kind]
	match kind:
		"audio_event", "notify", "flag":
			if not value is String or (value as String).is_empty():
				errors.append("%s: must be non-empty text." % at)
		"chart_entry":
			if not value is Dictionary or not value.has_all(["patient_id", "type", "by", "text"]):
				errors.append("%s: needs {\"patient_id\", \"type\", \"by\", \"text\"}." % at)
			else:
				_check_ref(value["patient_id"], refs["patients"], "patient", at + ".patient_id", errors)
		"world_state":
			if not value is Dictionary or not value.has_all(["group", "state"]):
				errors.append("%s: needs {\"group\", \"state\"}." % at)
		_:
			errors.append("%s: unknown action '%s'. Use one of: %s." % [path, kind, ", ".join(ACTIONS)])


## Evaluates a condition against live game state. `story` supplies the
## director's own state: {"talked_to": Array, "flags": Array}.
static func evaluate(condition: Dictionary, story: Dictionary) -> bool:
	var kind: String = condition.keys()[0]
	var value: Variant = condition[kind]
	match kind:
		"talked_to":
			return value in story.get("talked_to", [])
		"observations_recorded":
			return PatientManager.get_state(value["patient_id"]).get("observations", {}).size() >= int(value["min"])
		"note_saved":
			return not PatientManager.get_notes(value).is_empty()
		"action_committed":
			return PatientManager.get_state(value).get("audit", []).any(
					func(entry: Dictionary) -> bool: return entry["type"] == "clinical_action")
		"clue_acquired":
			return EvidenceManager.has_clue(value)
		"hypothesis_supported":
			return EvidenceManager.get_hypothesis(value).get("status", "") == "supported"
		"shift":
			return TimeManager.get_shift() == value
		"day":
			return TimeManager.get_shift_day() == int(value)
		"flag":
			return value in story.get("flags", [])
		"trust_at_least":
			return TrustManager.get_value(value["staff_id"], value["axis"]) >= float(value["value"])
		"all":
			return value.all(func(c: Dictionary) -> bool: return evaluate(c, story))
		"any":
			return value.any(func(c: Dictionary) -> bool: return evaluate(c, story))
	return false


static func _check_ref(id: Variant, known: Dictionary, kind: String, path: String, errors: Array[String]) -> void:
	if not id is String or not known.has(id):
		var choices: Array = known.keys()
		choices.sort()
		errors.append("%s: unknown %s id '%s'. Known ids: %s." % [path, kind, str(id), ", ".join(choices)])
