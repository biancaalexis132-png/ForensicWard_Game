class_name CaseJournal
extends Node
## CaseJournal: separates clinical documentation from evidence/hypotheses.
## Clinical notes, plans, observations go here. Evidence stays on EvidenceBoard.

const SAVE_PROVIDER_KEY: String = "case_journal"

var _entries: Array[Dictionary] = [] # {id, patient_id, type, content, author, at_minutes, day, shift, tags}

func _ready() -> void:
	add_to_group("save_provider")
	if SaveManager:
		SaveManager.register_provider(SAVE_PROVIDER_KEY, self)


func add_clinical_entry(patient_id: String, entry_type: String, content: String, tags: Array = []) -> String:
	var entry_id: String = "cj_%d_%03d" % [TimeManager.total_minutes, _entries.size() + 1]
	_entries.append({
		"id": entry_id,
		"patient_id": patient_id,
		"type": entry_type, # assessment, plan, note, handoff
		"content": content,
		"author": "player",
		"at_minutes": TimeManager.total_minutes,
		"day": TimeManager.get_shift_day(),
		"shift": TimeManager.get_shift(),
		"tags": tags.duplicate()
	})
	EventBus.notification_requested.emit("Journal entry added")
	return entry_id


func get_entries_for_patient(patient_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _entries:
		if entry.get("patient_id") == patient_id:
			result.append(entry.duplicate(true))
	return result


func get_all_entries() -> Array[Dictionary]:
	return _entries.duplicate(true)


func to_save_data() -> Dictionary:
	return {"entries": _entries.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	_entries = data.get("entries", []).duplicate(true)


func reset_state() -> void:
	_entries.clear()
