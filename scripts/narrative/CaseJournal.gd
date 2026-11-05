extends Node
## CaseJournal: separates clinical documentation from evidence/hypotheses.
## Clinical notes, plans, observations go here. Evidence stays on EvidenceBoard.

const SAVE_PROVIDER_KEY: String = "case_journal"

var _entries: Array[Dictionary] = [] # {id, patient_id, type, content, author, at_minutes, day, shift, tags}

func _ready() -> void:
	add_to_group("save_provider")
	if SaveManager:
		SaveManager.register_provider(SAVE_PROVIDER_KEY, self)
	EventBus.patient_note_saved.connect(_on_note_saved)
	EventBus.clinical_action_committed.connect(_on_action_committed)
	EventBus.game_loaded.connect(_reconcile.unbind(1))


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
		"tags": tags.duplicate(true)
	})
	EventBus.notification_requested.emit("Journal entry added")
	return entry_id


func get_entries_for_patient(patient_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _entries:
		if entry.get("patient_id") == patient_id:
			result.append(_resolve(entry))
	return result


func get_all_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _entries:
		result.append(_resolve(entry))
	return result


func to_save_data() -> Dictionary:
	return {"entries": _entries.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	_entries.clear()
	for entry: Dictionary in data.get("entries", []):
		_entries.append(entry.duplicate(true))


func reset_state() -> void:
	_entries.clear()


## The chart owns signed notes and action outcomes. The journal stores stable
## references only; replayed signals and legacy-save reconciliation are idempotent.
func _on_note_saved(patient_id: String, note_id: String) -> void:
	for note: Dictionary in PatientManager.get_notes(patient_id):
		if note.get("id") == note_id:
			_index(patient_id, "note", note_id, note, true)
			return


func _on_action_committed(patient_id: String, _action_id: String, event_id: String) -> void:
	for event: Dictionary in PatientManager.get_state(patient_id).get("audit", []):
		if event.get("event_id") == event_id and event.get("type") == "clinical_action":
			_index(patient_id, "action", event_id, event, true)
			return


func _index(patient_id: String, kind: String, source_id: String, source: Dictionary, notify: bool) -> void:
	var id: String = "chart:%s:%s:%s" % [patient_id, kind, source_id]
	for entry: Dictionary in _entries:
		if entry.get("id") == id:
			return
	var at: int = int(source.get("at_minutes", 0))
	_entries.append({"id": id, "patient_id": patient_id, "type": kind,
			"source_id": source_id, "source_kind": "patient_chart", "author": source.get("author", "player"),
			"at_minutes": at, "day": TimeManager.shift_day_for(at), "shift": TimeManager.shift_for(at), "tags": []})
	if notify:
		EventBus.notification_requested.emit("Journal entry added")


func _reconcile() -> void:
	for patient_id: String in ContentRegistry.get_patient_ids():
		for note: Dictionary in PatientManager.get_notes(patient_id):
			_index(patient_id, "note", str(note["id"]), note, false)
		for event: Dictionary in PatientManager.get_state(patient_id).get("audit", []):
			if event.get("type") == "clinical_action":
				_index(patient_id, "action", str(event["event_id"]), event, false)


func _resolve(entry: Dictionary) -> Dictionary:
	var result: Dictionary = entry.duplicate(true)
	if not entry.has("source_id"):
		return result
	var patient_id: String = entry["patient_id"]
	if entry["type"] == "note":
		for note: Dictionary in PatientManager.get_notes(patient_id):
			if note["id"] == entry["source_id"]:
				result["content"] = "Findings: %s\nConsiderations: %s\n\n%s" % [
						", ".join(note.get("findings", [])), ", ".join(note.get("considerations", [])), note.get("plan", "")]
	else:
		for event: Dictionary in PatientManager.get_state(patient_id).get("audit", []):
			if event.get("event_id") == entry["source_id"]:
				var action: Dictionary = ContentRegistry.get_action(str(event.get("action_id", "")))
				result["content"] = str(action.get("label", "")) + "\n\n" + str(action.get("description", ""))
	if not result.has("content"):
		result["content"] = "Chart source unavailable."
	return result
