extends Node
## EncounterManager (autoload): the full bedside encounter with a patient
## (data/elias_encounter.json): introduction, history from the patient and an
## informant, a physical examination the psychiatrist performs on screen, and
## verbal orders given at the bedside that are written to the chart.
##
## Clinical governance: the encounter is draft content. While it is
## PENDING_PSYCHIATRIST_REVIEW it plays only in the prototype build (the
## validated build falls back to the approved InterviewScreen choices), and
## every step raises clinical_review_flagged once. Orders that wrap an EHR
## catalog order (`ehr_order`) place only through ClinicalOrders and
## PatientManager.perform_action, exactly as the EHR does; the others are
## chart entries with no clinical effect. Lab results and the lorazepam
## reassessment are authored text, shown after the game clock reaches them.
##
## Saved under "encounters": {patient_id: {done, orders, challenge, labs, reassessment}}.

signal encounter_changed(patient_id: String)
## The encounter screen listens: a scheduled consequence happened.
signal consequence_ready(patient_id: String, kind: String)

const DATA_PATHS: Array[String] = ["res://data/elias_encounter.json"]
const PROVIDER_KEY: String = "encounters"
const APPROVED: String = "APPROVED"
const STEP_MINUTES: int = 2
const ORDERS_MINUTES: int = 5
const LAB_DELAY_MINUTES: int = 90
const EVENT_LABS: String = "encounter_labs:"
const EVENT_REASSESS: String = "encounter_reassess:"
## Orders open once the patient's mutism and posturing are witnessed (the
## catatonia assessment order's own prerequisites).
const ORDER_GATE_OBSERVATIONS: Array[String] = ["obs_mutism", "obs_posturing"]
const MEDICATION_VERDICT_UNSAFE: String = "unsafe"

var _definitions: Dictionary = {}  ## patient_id -> encounter definition
## Tests of the older short interview set this so Elias opens it instead; reset_state clears it.
var short_interview_only: bool = false
var _state: Dictionary = {}        ## patient_id -> runtime state
var _flagged: Dictionary = {}      ## step ids already flagged for review this run


func _ready() -> void:
	for path: String in DATA_PATHS:
		load_definition(path)
	SaveManager.register_provider(PROVIDER_KEY, self)
	EventBus.scheduled_event_fired.connect(_on_scheduled_event)


## Loads and checks one encounter file. Returns the errors (none loaded on error).
func load_definition(path: String) -> Array[String]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var errors: Array[String] = validate(parsed)
	if not errors.is_empty():
		for error: String in errors:
			push_error("EncounterManager %s: %s" % [path, error])
		return errors
	_definitions[str(parsed["patient_id"])] = parsed
	return errors


static func validate(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary:
		return ["encounter must be an object"]
	for key: String in ["patient_id", "clinical_review_status", "informant", "sections", "history_domains", "steps", "history_facts", "orders", "consequences", "flags"]:
		if not data.has(key):
			errors.append("missing " + key)
	if not errors.is_empty():
		return errors
	var sections: Array = data["sections"].map(func(s: Dictionary) -> String: return str(s["id"]))
	var domains: Array = data["history_domains"].map(func(d: Dictionary) -> String: return str(d["id"]))
	var ids: Dictionary = {}
	for step: Dictionary in data["steps"]:
		var id: String = str(step.get("id", ""))
		if id.is_empty() or ids.has(id):
			errors.append("step id missing or repeated: " + id)
		ids[id] = true
		if not str(step.get("section", "")) in sections:
			errors.append("unknown section in " + id)
		if step.has("domain") and not str(step["domain"]) in domains:
			errors.append("unknown domain in " + id)
		if str(step.get("label", "")).is_empty() or str(step.get("player", "")).is_empty():
			errors.append("step needs label and player line: " + id)
		if not step.get("beats", null) is Array or step["beats"].is_empty():
			errors.append("step needs beats: " + id)
		for fact: String in step.get("records_facts", []):
			if not data["history_facts"].has(fact):
				errors.append("unknown fact %s in %s" % [fact, id])
	for step: Dictionary in data["steps"]:
		for required: String in step.get("requires", []):
			if not ids.has(required):
				errors.append("unknown requirement %s in %s" % [required, step["id"]])
	for domain: String in domains:
		if not data["steps"].any(func(s: Dictionary) -> bool: return s.get("domain", "") == domain):
			errors.append("no step covers domain " + domain)
	var groups: Array = data["orders"].get("groups", []).map(func(g: Dictionary) -> String: return str(g["id"]))
	var order_ids: Dictionary = {}
	for item: Dictionary in data["orders"].get("items", []):
		if order_ids.has(item.get("id", "")) or not str(item.get("group", "")) in groups:
			errors.append("order id repeated or group unknown: " + str(item.get("id", "")))
		order_ids[item.get("id", "")] = true
		if not str(item.get("verdict", "")) in ["required", "preferred", "helpful", "acceptable", "not_yet", "unsafe"]:
			errors.append("unknown verdict for " + str(item.get("id", "")))
	return errors


# --- Queries --------------------------------------------------------------------

func has_encounter(patient_id: String) -> bool:
	return _definitions.has(patient_id)


## True when the encounter may play in this build (approved, or a prototype build).
func is_playable(patient_id: String) -> bool:
	if short_interview_only or not _definitions.has(patient_id):
		return false
	var status: String = str(_definitions[patient_id]["clinical_review_status"])
	return status == APPROVED or (status != "REJECTED" and ClinicalRules.build_mode == ClinicalRules.MODE_PROTOTYPE)


func is_draft(patient_id: String) -> bool:
	return _definitions.has(patient_id) and str(_definitions[patient_id]["clinical_review_status"]) != APPROVED


func definition(patient_id: String) -> Dictionary:
	return _definitions.get(patient_id, {})


func informant(patient_id: String) -> Dictionary:
	return definition(patient_id).get("informant", {})


func get_step(patient_id: String, step_id: String) -> Dictionary:
	for step: Dictionary in definition(patient_id).get("steps", []):
		if step["id"] == step_id:
			return step
	for step: Dictionary in reassessment(patient_id).get("steps", []):
		if step["id"] == step_id:
			return step
	return {}


func is_done(patient_id: String, step_id: String) -> bool:
	return step_id in _patient(patient_id)["done"]


## The section's steps whose requirements are met, in file order, with a done flag.
func steps_for(patient_id: String, section: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for step: Dictionary in definition(patient_id).get("steps", []):
		if step["section"] != section:
			continue
		var ready: bool = step.get("requires", []).all(func(r: String) -> bool: return is_done(patient_id, r))
		if ready:
			result.append({"id": step["id"], "label": step["label"], "done": is_done(patient_id, step["id"]), "domain": step.get("domain", "")})
	return result


## {domain_id: {label, covered}} in file order.
func history_coverage(patient_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for domain: Dictionary in definition(patient_id).get("history_domains", []):
		var covered: bool = definition(patient_id)["steps"].any(func(s: Dictionary) -> bool:
				return s.get("domain", "") == domain["id"] and is_done(patient_id, s["id"]))
		result.append({"id": domain["id"], "label": domain["label"], "covered": covered})
	return result


func is_history_complete(patient_id: String) -> bool:
	return history_coverage(patient_id).all(func(d: Dictionary) -> bool: return d["covered"])


func is_exam_complete(patient_id: String) -> bool:
	return definition(patient_id).get("steps", []).filter(func(s: Dictionary) -> bool: return s["section"] == "exam") \
			.all(func(s: Dictionary) -> bool: return is_done(patient_id, s["id"]))


## Facts the player has drawn out, with provenance, in the order recorded.
func recorded_facts(patient_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var facts: Dictionary = definition(patient_id).get("history_facts", {})
	for fact_id: String in _patient(patient_id)["facts"]:
		var fact: Dictionary = facts.get(fact_id, {}).duplicate()
		fact["id"] = fact_id
		result.append(fact)
	return result


## Orders are offered once mutism and posturing are witnessed.
func orders_open(patient_id: String) -> bool:
	var recorded: Dictionary = PatientManager.get_state(patient_id).get("observations", {})
	return ORDER_GATE_OBSERVATIONS.all(func(o: String) -> bool: return recorded.has(o))


func order_items(patient_id: String) -> Array:
	return definition(patient_id).get("orders", {}).get("items", [])


func order_groups(patient_id: String) -> Array:
	return definition(patient_id).get("orders", {}).get("groups", [])


func get_order_item(patient_id: String, item_id: String) -> Dictionary:
	for item: Dictionary in order_items(patient_id):
		if item["id"] == item_id:
			return item
	return {}


func given_orders(patient_id: String) -> Array[String]:
	var result: Array[String] = []
	result.assign(_patient(patient_id)["orders"])
	return result


func orders_given(patient_id: String) -> bool:
	return not _patient(patient_id)["orders"].is_empty()


## "" (none), "pending" (the nurse is asking), "rescinded", "held_by_nursing".
func challenge_state(patient_id: String) -> String:
	return str(_patient(patient_id)["challenge"])


## "none", "pending" (scheduled), "ready" (the sitter called), "done".
func reassessment_state(patient_id: String) -> String:
	return str(_patient(patient_id)["reassessment"])


func reassessment(patient_id: String) -> Dictionary:
	return definition(patient_id).get("consequences", {}).get("lorazepam_reassessment", {})


func labs_ready(patient_id: String) -> bool:
	return bool(_patient(patient_id)["labs"])


## [{lab_id, label, result}] for ordered labs once they are back.
func lab_results(patient_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not labs_ready(patient_id):
		return result
	var texts: Dictionary = definition(patient_id)["orders"].get("lab_results", {})
	for item_id: String in given_orders(patient_id):
		var item: Dictionary = get_order_item(patient_id, item_id)
		var lab: String = str(item.get("lab_id", ""))
		if not lab.is_empty() and texts.has(lab):
			result.append({"lab_id": lab, "label": item["label"], "result": texts[lab]})
	return result


## Teaching feedback for the orders given plus the required/preferred ones missed.
func order_feedback(patient_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var given: Array[String] = given_orders(patient_id)
	for item: Dictionary in order_items(patient_id):
		var chosen: bool = item["id"] in given
		if chosen or item["verdict"] in ["required", "preferred"]:
			result.append({"id": item["id"], "label": item["label"], "verdict": item["verdict"],
					"given": chosen, "feedback": item["feedback"]})
	return result


# --- Actions --------------------------------------------------------------------

## Performs one step once: records its findings and facts, costs time, and
## returns {player, beats, performs, patient_performs} for presentation.
## Returns {} when the step is unknown, already done or not yet available.
func perform_step(patient_id: String, step_id: String) -> Dictionary:
	if not is_playable(patient_id):
		return {}
	var step: Dictionary = get_step(patient_id, step_id)
	if step.is_empty() or is_done(patient_id, step_id):
		return {}
	if not step.get("requires", []).all(func(r: String) -> bool: return is_done(patient_id, r)):
		return {}
	var is_reassess: bool = reassessment(patient_id).get("steps", []).any(func(s: Dictionary) -> bool: return s["id"] == step_id)
	if is_reassess and reassessment_state(patient_id) != "ready":
		return {}
	var state: Dictionary = _patient(patient_id)
	state["done"].append(step_id)
	for observation_id: String in step.get("records_observations", []):
		PatientManager.record_observation(patient_id, observation_id, "encounter:" + step_id)
	for fact_id: String in step.get("records_facts", []):
		if not fact_id in state["facts"]:
			state["facts"].append(fact_id)
			var fact: Dictionary = definition(patient_id)["history_facts"][fact_id]
			PatientManager.add_chart_entry(patient_id, "evt_enc_fact_%s_%s" % [patient_id, fact_id], "history",
					str(fact.get("source", "")), "%s (%s)" % [fact["text"], fact.get("reliability", "")])
	if step.has("rapport_delta"):
		PatientManager.adjust_rapport(patient_id, float(step["rapport_delta"]))
	_flag_for_review(patient_id, step_id)
	TimeManager.advance(STEP_MINUTES, "encounter")
	var flags: Dictionary = definition(patient_id)["flags"]
	if is_history_complete(patient_id):
		GameState.set_flag(flags["history_complete"])
	if is_exam_complete(patient_id):
		GameState.set_flag(flags["exam_complete"])
	if is_reassess and reassessment(patient_id)["steps"].all(func(s: Dictionary) -> bool: return is_done(patient_id, s["id"])):
		state["reassessment"] = "done"
		GameState.set_flag(flags["lorazepam_response_seen"])
		PatientManager.add_chart_entry(patient_id, "evt_enc_reassessed_" + patient_id, "encounter_reassessment",
				"player", "Re-examined after the lorazepam challenge: tracking with his eyes, drank most of a cup, said \"Thank you\"; arm no longer stays raised. (Draft content, pending clinical review.)")
	var beats: Array = step["beats"].duplicate(true)
	if is_reassess and state["reassessment"] == "done":
		beats.append({"speaker": str(informant(patient_id).get("id", "")), "text": str(reassessment(patient_id).get("sitter_close", ""))})
	encounter_changed.emit(patient_id)
	return {"player": str(step.get("player", "")), "beats": beats,
			"performs": str(step.get("performs", "")), "patient_performs": str(step.get("patient_performs", ""))}


## Gives the bedside orders once. Each is written to the chart; orders that
## wrap an EHR catalog order are placed through it. Returns
## {placed: [item ids], ehr: [order ids placed], challenge: bool}.
func give_orders(patient_id: String, item_ids: Array[String]) -> Dictionary:
	if not is_playable(patient_id) or not orders_open(patient_id) or orders_given(patient_id) or item_ids.is_empty():
		return {}
	var state: Dictionary = _patient(patient_id)
	var placed: Array[String] = []
	var ehr: Array[String] = []
	var challenge: bool = false
	for item_id: String in item_ids:
		var item: Dictionary = get_order_item(patient_id, item_id)
		if item.is_empty() or item_id in placed:
			continue
		placed.append(item_id)
		PatientManager.add_chart_entry(patient_id, "evt_enc_order_%s_%s" % [patient_id, item_id], "bedside_order",
				"player", "Bedside order: %s." % item["label"])
		if item.has("ehr_order") and _place_ehr_order(patient_id, str(item["ehr_order"])):
			ehr.append(str(item["ehr_order"]))
		if item["group"] == "medication" and item["verdict"] == MEDICATION_VERDICT_UNSAFE:
			challenge = true
	state["orders"] = placed
	# The examination at the bedside is the structured catatonia assessment.
	var assessment: String = str(definition(patient_id)["orders"].get("catatonia_assessment_order", ""))
	if not assessment.is_empty() and _place_ehr_order(patient_id, assessment):
		ehr.append(assessment)
	var flags: Dictionary = definition(patient_id)["flags"]
	GameState.set_flag(flags["orders_given"])
	if challenge:
		state["challenge"] = "pending"
		GameState.set_flag(flags["antipsychotic_ordered"])
	if placed.any(func(id: String) -> bool: return not str(get_order_item(patient_id, id).get("lab_id", "")).is_empty()):
		TimeManager.schedule(TimeManager.total_minutes + ORDERS_MINUTES + LAB_DELAY_MINUTES, EVENT_LABS + patient_id)
	_flag_for_review(patient_id, "orders")
	TimeManager.advance(ORDERS_MINUTES, "encounter_orders")
	_maybe_schedule_reassessment(patient_id)
	encounter_changed.emit(patient_id)
	return {"placed": placed, "ehr": ehr, "challenge": challenge}


## The charge nurse questions an antipsychotic order. "rescind" cancels it;
## "insist" makes nursing hold it. Returns the nurse's reply, or "".
func resolve_challenge(patient_id: String, choice_id: String) -> String:
	if challenge_state(patient_id) != "pending":
		return ""
	var hold: Dictionary = definition(patient_id)["consequences"]["antipsychotic_hold"]
	for choice: Dictionary in hold["choices"]:
		if choice["id"] != choice_id:
			continue
		var state: Dictionary = _patient(patient_id)
		state["challenge"] = "rescinded" if choice_id == "rescind" else "held_by_nursing"
		TrustManager.adjust(str(hold["speaker"]), "trust", float(choice.get("trust_delta", 0)), "encounter_antipsychotic_" + choice_id)
		if choice.has("chart_entry"):
			PatientManager.add_chart_entry(patient_id, "evt_enc_held_" + patient_id, "nursing_hold", str(hold["speaker"]), str(choice["chart_entry"]))
			GameState.set_flag(definition(patient_id)["flags"]["antipsychotic_held_by_nursing"])
		else:
			PatientManager.add_chart_entry(patient_id, "evt_enc_rescinded_" + patient_id, "order_cancelled", "player", "Antipsychotic order cancelled before administration.")
		encounter_changed.emit(patient_id)
		return str(choice["reply"])
	return ""


# --- Internals ------------------------------------------------------------------

func _place_ehr_order(patient_id: String, order_id: String) -> bool:
	var order: Dictionary = ContentRegistry.get_order(order_id)
	if order.is_empty() or not ClinicalOrders.status(patient_id, order)["can_place"]:
		return false
	var findings: Array[String] = []
	findings.assign(PatientManager.get_state(patient_id).get("observations", {}).keys())
	findings.sort()
	return not PatientManager.perform_action(patient_id, str(order["action_id"]), findings).is_empty()


func _maybe_schedule_reassessment(patient_id: String) -> void:
	var state: Dictionary = _patient(patient_id)
	var lorazepam: bool = state["orders"].any(func(id: String) -> bool:
			return str(get_order_item(patient_id, id).get("medication_id", "")) == "lorazepam")
	if lorazepam and state["reassessment"] == "none":
		state["reassessment"] = "pending"
		TimeManager.schedule(TimeManager.total_minutes + int(reassessment(patient_id).get("delay_minutes", 45)), EVENT_REASSESS + patient_id)


func _on_scheduled_event(event_id: String, _payload: Dictionary) -> void:
	if event_id.begins_with(EVENT_LABS):
		var patient_id: String = event_id.trim_prefix(EVENT_LABS)
		if not _definitions.has(patient_id):
			return
		_patient(patient_id)["labs"] = true
		for lab: Dictionary in lab_results(patient_id):
			PatientManager.add_chart_entry(patient_id, "evt_enc_lab_%s_%s" % [patient_id, lab["lab_id"]], "lab_result",
					"laboratory", "%s: %s (Draft result, pending clinical review.)" % [lab["label"], lab["result"]])
		EventBus.notification_requested.emit("Lab results for %s are back in the EHR." % ContentRegistry.get_patient(patient_id).get("name", patient_id))
		consequence_ready.emit(patient_id, "labs")
		encounter_changed.emit(patient_id)
	elif event_id.begins_with(EVENT_REASSESS):
		var patient_id: String = event_id.trim_prefix(EVENT_REASSESS)
		if not _definitions.has(patient_id) or reassessment_state(patient_id) != "pending":
			return
		_patient(patient_id)["reassessment"] = "ready"
		var call: Dictionary = reassessment(patient_id).get("call", {})
		EventBus.notification_requested.emit("%s: \"%s\"" % [str(informant(patient_id).get("name", "")), str(call.get("text", ""))])
		consequence_ready.emit(patient_id, "reassessment")
		encounter_changed.emit(patient_id)


func _flag_for_review(patient_id: String, item: String) -> void:
	if not is_draft(patient_id) or _flagged.has(patient_id + ":" + item):
		return
	_flagged[patient_id + ":" + item] = true
	EventBus.clinical_review_flagged.emit("encounter:%s:%s" % [patient_id, item], "Draft encounter content pending psychiatrist review")


func _patient(patient_id: String) -> Dictionary:
	if not _state.has(patient_id):
		_state[patient_id] = {"done": [], "facts": [], "orders": [], "challenge": "", "labs": false, "reassessment": "none"}
	return _state[patient_id]


# --- Save provider --------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"patients": _state.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	reset_state()
	var patients: Variant = data.get("patients", {})
	if not patients is Dictionary:
		return
	for patient_id: String in patients:
		var entry: Variant = patients[patient_id]
		if not entry is Dictionary or not _definitions.has(patient_id):
			continue
		var state: Dictionary = _patient(patient_id)
		for key: String in ["done", "facts", "orders"]:
			if entry.get(key) is Array:
				state[key] = entry[key].filter(func(v: Variant) -> bool: return v is String)
		for key: String in ["challenge", "reassessment"]:
			if entry.get(key) is String:
				state[key] = entry[key]
		state["labs"] = bool(entry.get("labs", false))


func reset_state() -> void:
	short_interview_only = false
	_state.clear()
	_flagged.clear()
