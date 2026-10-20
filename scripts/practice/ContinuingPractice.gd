extends Node
## Optional post-campaign worklist. Pending clinical content is reviewable, never activated.
var _definitions: Dictionary = {}
var _cases: Dictionary = {}

static func default_data() -> Dictionary:
	return {"cases": {}}

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/continuing_practice/cp001.json"))
	if _valid_definition(parsed):
		_definitions[parsed["id"]] = parsed
	else:
		push_error("Invalid Continuing Practice case catalog")
	for case_id: String in _definitions:
		var definition: Dictionary = _definitions[case_id]
		if PracticeCase.new(definition).ready_for_play() and ContentRegistry.register_practice_patient(definition):
			PatientManager.ensure_patient_state(definition["patient"]["id"])
	SaveManager.register_provider("continuing_practice", self)
	EventBus.patient_note_saved.connect(_on_note_saved)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)

func _valid_definition(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema_version") != 1 or data.get("id") != "cp_001" or not data.get("patient") is Dictionary or not data.get("encounters") is Array or data["encounters"].size() != 5:
		return false
	var ids: Dictionary = {}
	for encounter: Variant in data["encounters"]:
		if not encounter is Dictionary or not encounter.get("id") is String or not encounter.get("dialogue") is Dictionary or not encounter.get("title") is String or ids.has(encounter["id"]):
			return false
		ids[encounter["id"]] = true
	return data.get("no_automatic_medical_effects") == true and data.get("clinical_review_status") in ["PENDING", "APPROVED", "REJECTED"]

func get_definition(case_id: String) -> Dictionary:
	return _definitions.get(case_id, {}).duplicate(true)

func case_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_definitions.keys())
	result.sort()
	return result

func get_case(case_id: String) -> PracticeCase:
	if not _definitions.has(case_id):
		return null
	if not _cases.has(case_id):
		_cases[case_id] = PracticeCase.new(_definitions[case_id])
	return _cases[case_id]

func accept_case(case_id: String) -> bool:
	var case: PracticeCase = get_case(case_id)
	if case == null:
		return false
	var director: ChapterDirector = get_tree().get_first_node_in_group(ChapterDirector.GROUP) as ChapterDirector
	return case.accept(director != null and director.has_completed("ch5"))

func _on_note_saved(patient_id: String, note_id: String) -> void:
	for case_id: String in _cases:
		var case: PracticeCase = _cases[case_id]
		if case.definition["patient"]["id"] != patient_id:
			continue
		for note: Dictionary in PatientManager.get_notes(patient_id):
			if note["id"] == note_id:
				case.record("note", note_id, "note:" + note_id)

func _on_dialogue_ended(patient_id: String) -> void:
	if not DialogueManager.is_interview_complete(patient_id):
		return
	for case_id: String in _cases:
		var case: PracticeCase = _cases[case_id]
		if case.definition["patient"]["id"] == patient_id:
			var encounter: int = int(case.to_save_data()["encounter"])
			case.record("interview", "%s:%d" % [patient_id, encounter], "interview:%s:%d" % [case_id, encounter])

func can_close_shift() -> bool:
	for case: PracticeCase in _cases.values():
		if not case.tasks_accounted_for():
			return false
		var data: Dictionary = case.to_save_data()
		if data["status"] in ["active", "on_hold"]:
			var encounter: Dictionary = data["encounters"].get(str(data["encounter"]), {})
			if not encounter.is_empty() and (not encounter.has("interview") or not encounter.has("note")):
				return false
	return true

func to_save_data() -> Dictionary:
	var states: Dictionary = {}
	for id: String in _cases:
		var data: Dictionary = _cases[id].to_save_data()
		if data != PracticeCase.defaults():
			states[id] = data
	return {"cases": states}

func validate_save_data(data: Variant) -> bool:
	if not data is Dictionary or not data.get("cases") is Dictionary:
		return false
	for id: Variant in data["cases"]:
		if not id is String or not _definitions.has(id) or not PracticeCase.valid_state(data["cases"][id]):
			return false
		if data["cases"][id]["status"] != "available" and not PracticeCase.new(_definitions[id]).ready_for_play():
			return false
	return true

func load_save_data(data: Dictionary) -> void:
	if not validate_save_data(data):
		return
	_cases.clear()
	for id: String in data["cases"]:
		get_case(id).load_save_data(data["cases"][id])

func reset_state() -> void:
	_cases.clear()


func definition_for_patient(patient_id: String) -> Dictionary:
	for definition: Dictionary in _definitions.values():
		if definition["patient"]["id"] == patient_id:
			return definition
	return {}

func current_dialogue(patient_id: String) -> Dictionary:
	var definition: Dictionary = definition_for_patient(patient_id)
	if definition.is_empty():
		return {}
	var case: PracticeCase = get_case(definition["id"])
	if not case.ready_for_play() or case.to_save_data()["status"] == "available":
		return {}
	return definition["encounters"][clampi(int(case.to_save_data()["encounter"]) - 1, 0, 4)]["dialogue"]

func is_admitted(patient_id: String) -> bool:
	var definition: Dictionary = definition_for_patient(patient_id)
	if definition.is_empty():
		return true
	return get_case(definition["id"]).to_save_data()["status"] != "available"
