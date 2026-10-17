extends Node
## DialogueManager: authored interview state machine (Autoload "DialogueManager").
##
## Runs the dialogue graph from data/dialogue.json for one patient at a time:
## lists the current state's choices, accepts a choice id or bounded free
## text (IntentMatcher), records a transcript with timestamps, and forwards
## rapport deltas to PatientManager. All lines go through
## EventBus.dialogue_line_added, so subtitles and the transcript never depend
## on audio. Choices may list `records_observations`: asking them records
## those authored observations as witnessed (provenance "interview:<choice>").
## Each question costs QUESTION_MINUTES of shift time. InterviewScreen is the UI.

const CLARIFY_TEMPLATE: String = "Could you clarify? Did you mean: %s?"
const QUESTION_MINUTES: int = 2

var active_patient_id: String = ""
## Observation ids newly recorded by the most recent question (for the UI).
var last_recorded_observations: Array[String] = []

var _matcher: IntentMatcher = null
var _current_state: Dictionary = {} ## patient_id -> state id
var _transcripts: Dictionary = {}   ## patient_id -> [{speaker, text, at_minutes}]


func _ready() -> void:
	SaveManager.register_provider("dialogue", self)
	_matcher = IntentMatcher.new(ContentRegistry.get_lexicon())


func start_dialogue(patient_id: String) -> bool:
	var dialogue: Dictionary = ContentRegistry.get_dialogue(patient_id)
	if dialogue.is_empty():
		push_warning("DialogueManager: no dialogue authored for '%s'" % patient_id)
		return false
	active_patient_id = patient_id
	if not _current_state.has(patient_id):
		_current_state[patient_id] = dialogue["states"][0]["id"]
	EventBus.dialogue_started.emit(patient_id)
	return true


func end_dialogue() -> void:
	if active_patient_id.is_empty():
		return
	var ended: String = active_patient_id
	active_patient_id = ""
	EventBus.dialogue_ended.emit(ended)


## Current choices as [{id, label}] for the active patient.
func get_choices() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice: Dictionary in _state_choices():
		result.append({"id": choice["id"], "label": choice["label"]})
	return result


## Selects a choice. Returns the authored response text, or "" if invalid.
func select_choice(choice_id: String) -> String:
	for choice: Dictionary in _state_choices():
		if choice["id"] == choice_id:
			_apply_choice(choice, choice["label"])
			return choice["response"]
	push_warning("DialogueManager: choice '%s' is not available" % choice_id)
	return ""


## Free-text question. Returns {status, response, choice_id, candidates}.
func submit_free_text(text: String) -> Dictionary:
	var result: Dictionary = _matcher.match_text(text, _state_choices())
	if result["status"] == "matched":
		var response: String = ""
		for choice: Dictionary in _state_choices():
			if choice["id"] == result["choice_id"]:
				response = choice["response"]
				_apply_choice(choice, text)
				break
		result["response"] = response
		return result

	_add_line("physician", text)
	TimeManager.advance(QUESTION_MINUTES, "interview")
	if result["status"] == "clarify":
		var labels: Array[String] = []
		for choice: Dictionary in _state_choices():
			if choice["id"] in result["candidates"]:
				labels.append("\"%s\"" % choice["label"])
		result["response"] = CLARIFY_TEMPLATE % " or ".join(labels)
	else:
		result["response"] = ContentRegistry.get_dialogue(active_patient_id).get("fallback_response", "")
	_add_line("system", result["response"])
	return result


## Classifies text without changing state (used by tests and UI hints).
func classify(patient_id: String, text: String) -> Dictionary:
	var dialogue: Dictionary = ContentRegistry.get_dialogue(patient_id)
	var state_id: String = _current_state.get(patient_id, dialogue.get("states", [{}])[0].get("id", ""))
	return _matcher.match_text(text, _find_state(dialogue, state_id).get("choices", []))


func get_transcript(patient_id: String) -> Array:
	return _transcripts.get(patient_id, []).duplicate(true)


func _apply_choice(choice: Dictionary, physician_text: String) -> void:
	var patient_id: String = active_patient_id
	_add_line("physician", physician_text)
	_add_line("patient", choice["response"])
	_current_state[patient_id] = choice["next"]
	PatientManager.adjust_rapport(patient_id, float(choice.get("rapport_delta", 0.0)))
	last_recorded_observations.clear()
	for observation_id: String in choice.get("records_observations", []):
		if PatientManager.record_observation(patient_id, observation_id, "interview:" + str(choice["id"])):
			last_recorded_observations.append(observation_id)
	TimeManager.advance(QUESTION_MINUTES, "interview")


func _state_choices() -> Array:
	if active_patient_id.is_empty():
		return []
	var dialogue: Dictionary = ContentRegistry.get_dialogue(active_patient_id)
	return _find_state(dialogue, _current_state.get(active_patient_id, "")).get("choices", [])


func _find_state(dialogue: Dictionary, state_id: String) -> Dictionary:
	for state: Dictionary in dialogue.get("states", []):
		if state["id"] == state_id:
			return state
	return {}


func _add_line(speaker: String, text: String) -> void:
	if not _transcripts.has(active_patient_id):
		_transcripts[active_patient_id] = []
	_transcripts[active_patient_id].append({"speaker": speaker, "text": text, "at_minutes": TimeManager.total_minutes})
	EventBus.dialogue_line_added.emit(active_patient_id, speaker, text)


# --- Save provider ------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"current_state": _current_state.duplicate(true), "transcripts": _transcripts.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	reset_state()
	_current_state = data.get("current_state", {}).duplicate(true)
	_transcripts = data.get("transcripts", {}).duplicate(true)


func reset_state() -> void:
	active_patient_id = ""
	_current_state.clear()
	_transcripts.clear()
