class_name ChapterDirector
extends Node
## ChapterDirector: runs a chapter's story data (ContentRegistry.get_story()).
##
## - Objectives: shown in order; the current one is the first that is neither
##   complete nor expired (e.g. day-shift tasks once the night begins).
## - Beats: fire once when their condition holds, optionally after a delay
##   in game minutes (scheduled through TimeManager, so delays are saved).
## - Staff lines: what a staff member says now (first matching line).
## - Sign-out: ends the day shift (handover quality changes trust) or, at
##   night, completes the chapter.
## Conditions and actions are StoryLogic's closed vocabulary. The director
## never changes clinical state; chart entries are audit records only.
## Saved as the "chapter" provider. Lives in Main (group "chapter_director").

const PROVIDER_KEY: String = "chapter"
const GROUP: String = "chapter_director"
const SCHEDULE_PREFIX: String = "story:"

var _talked_to: Array[String] = []
var _flags: Array[String] = []
var _fired: Array[String] = []
var _pending: Array[String] = []
var _objective_id: String = ""
var _evaluating: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	SaveManager.register_provider(PROVIDER_KEY, self)
	EventBus.interacted.connect(_on_interacted)
	EventBus.scheduled_event_fired.connect(_on_scheduled_event)
	EventBus.shift_signout_requested.connect(sign_out)
	for signal_name: String in ["observation_recorded", "patient_note_saved", "clinical_action_committed",
			"clue_acquired", "hypothesis_updated", "shift_started", "trust_changed"]:
		var argc: int = 0
		for info: Dictionary in EventBus.get_signal_list():
			if info["name"] == signal_name:
				argc = info["args"].size()
		EventBus.connect(signal_name, evaluate.unbind(argc))
	EventBus.game_loaded.connect(func(_slot: int) -> void: evaluate())
	evaluate.call_deferred()


func _exit_tree() -> void:
	SaveManager.unregister_provider(PROVIDER_KEY)


# --- Queries --------------------------------------------------------------------

func get_current_objective() -> Dictionary:
	if not ContentRegistry.is_valid:
		return {}
	var state: Dictionary = _story_state()
	for objective: Dictionary in ContentRegistry.get_story()["objectives"]:
		if objective.has("expires_when") and StoryLogic.evaluate(objective["expires_when"], state):
			continue
		if not StoryLogic.evaluate(objective["complete_when"], state):
			return objective
	return {}


func has_flag(flag: String) -> bool:
	return flag in _flags


func has_fired(beat_id: String) -> bool:
	return beat_id in _fired


## The line a staff member says right now, or {} for their default intro.
func get_staff_line(staff_id: String) -> Dictionary:
	if not ContentRegistry.is_valid:
		return {}
	for line: Dictionary in ContentRegistry.get_story()["staff_lines"]:
		if line["staff_id"] == staff_id and StoryLogic.evaluate(line["when"], _story_state()):
			return line
	return {}


# --- Story progression -------------------------------------------------------------

## Re-checks beats and the current objective. Called on every relevant event.
func evaluate() -> void:
	if _evaluating or not ContentRegistry.is_valid:
		return
	_evaluating = true
	for beat: Dictionary in ContentRegistry.get_story()["beats"]:
		var beat_id: String = beat["id"]
		if beat_id in _fired or beat_id in _pending or not StoryLogic.evaluate(beat["when"], _story_state()):
			continue
		var delay: int = int(beat.get("delay_minutes", 0))
		if delay > 0:
			_pending.append(beat_id)
			TimeManager.schedule(TimeManager.total_minutes + delay, SCHEDULE_PREFIX + beat_id)
		else:
			_fire(beat)
	_evaluating = false
	_update_objective()


func set_flag(flag: String) -> void:
	if not flag in _flags:
		_flags.append(flag)
		_flags.sort()
		evaluate()


## Signs out at the handover board. Day: hand over and start the night shift.
## Night: complete the chapter. Returns the summary text shown to the player.
func sign_out() -> String:
	var config: Dictionary = ContentRegistry.get_story()["sign_out"]
	var body: String
	if has_flag("chapter_complete"):
		body = "You have already signed out. Chapter 1 is complete.\n\n" + _shift_summary()
	elif TimeManager.get_shift() == "day":
		body = _hand_over(config)
		TimeManager.advance_to_next_shift()
		body += "\n\n[b]The night shift has begun.[/b] (%s)" % TimeManager.get_clock_string()
	else:
		set_flag("chapter_complete")
		body = "[b]End of %s[/b] (playable slice)\n\n%s\n\n%s" % [ContentRegistry.get_story()["title"],
				_shift_summary(), _relationship_summary()]
		EventBus.chapter_completed.emit(str(ContentRegistry.get_story()["chapter"]))
	EventBus.ui_panel_requested.emit("info", {"title": config["title"], "body": body})
	return body


# --- Internals ----------------------------------------------------------------------

func _hand_over(config: Dictionary) -> String:
	var missing: Array[String] = []
	for patient_id: String in config["handover_patients"]:
		var today: Array = PatientManager.get_notes(patient_id).filter(
				func(note: Dictionary) -> bool: return int(note["day"]) == TimeManager.get_shift_day())
		if today.is_empty():
			missing.append(ContentRegistry.get_patient(patient_id).get("name", patient_id))
	var changes: Array = config["documented_trust"] if missing.is_empty() else config["undocumented_trust"]
	for change: Dictionary in changes:
		TrustManager.adjust(change["staff_id"], change["axis"], float(change["delta"]), "handover")
	var lines: PackedStringArray = ["[b]Day shift handover[/b]", "", _shift_summary(), ""]
	if missing.is_empty():
		lines.append("Handover documented for every patient on your list.")
	else:
		lines.append("No note today for: %s." % ", ".join(missing))
		lines.append(config["undocumented_message"])
	return "\n".join(lines)


func _shift_summary() -> String:
	var lines: PackedStringArray = []
	for patient_id: String in ContentRegistry.get_patient_ids():
		var state: Dictionary = PatientManager.get_state(patient_id)
		var actions: int = state["audit"].filter(func(e: Dictionary) -> bool: return e["type"] == "clinical_action").size()
		lines.append("%s: %d finding(s) witnessed, %d note(s), %d clinical action(s)." % [
				ContentRegistry.get_patient(patient_id)["name"], state["observations"].size(), state["notes"].size(), actions])
	lines.append("Evidence collected: %d of %d." % [EvidenceManager.get_acquired_ids().size(), ContentRegistry.get_clue_ids().size()])
	for hypothesis_id: String in ContentRegistry.get_hypothesis_ids():
		var hypothesis: Dictionary = EvidenceManager.get_hypothesis(hypothesis_id)
		lines.append("Hypothesis \"%s\": %s." % [hypothesis["title"], hypothesis["status"]])
	return "\n".join(lines)


func _relationship_summary() -> String:
	var lines: PackedStringArray = ["[b]Staff[/b]"]
	for staff_id: String in ContentRegistry.get_staff_ids():
		var vector: Dictionary = TrustManager.get_vector(staff_id)
		lines.append("%s: respect %d, trust %d, suspicion %d" % [ContentRegistry.get_staff(staff_id)["name"],
				int(vector["respect"]), int(vector["trust"]), int(vector["suspicion"])])
	return "\n".join(lines)


func _fire(beat: Dictionary) -> void:
	_fired.append(beat["id"])
	_pending.erase(beat["id"])
	for action: Dictionary in beat["actions"]:
		_run_action(action, beat["id"])
	EventBus.story_beat_fired.emit(beat["id"])


func _run_action(action: Dictionary, beat_id: String) -> void:
	var kind: String = action.keys()[0]
	var value: Variant = action[kind]
	match kind:
		"audio_event":
			EventBus.narrative_event_fired.emit(value, {})
		"notify":
			EventBus.notification_requested.emit(value)
		"flag":
			if not value in _flags:
				_flags.append(value)
				_flags.sort()
		"chart_entry":
			PatientManager.add_chart_entry(value["patient_id"], "evt_%s_%s" % [beat_id, value["patient_id"]],
					value["type"], value["by"], value["text"])
		"world_state":
			WorldStateManager.set_state(value["group"], value["state"])


func _update_objective() -> void:
	var objective: Dictionary = get_current_objective()
	var objective_id: String = objective.get("id", "")
	if objective_id == _objective_id:
		return
	_objective_id = objective_id
	EventBus.objective_changed.emit(objective_id, objective.get("text", ""))


func _story_state() -> Dictionary:
	return {"talked_to": _talked_to, "flags": _flags}


func _on_interacted(interactable_id: String) -> void:
	if not interactable_id.begins_with("character:"):
		return
	var character_id: String = interactable_id.trim_prefix("character:")
	if ContentRegistry.get_staff(character_id).is_empty() or character_id in _talked_to:
		return
	_talked_to.append(character_id)
	_talked_to.sort()
	evaluate()


func _on_scheduled_event(event_id: String, _payload: Dictionary) -> void:
	if not event_id.begins_with(SCHEDULE_PREFIX):
		return
	var beat_id: String = event_id.trim_prefix(SCHEDULE_PREFIX)
	for beat: Dictionary in ContentRegistry.get_story()["beats"]:
		if beat["id"] == beat_id and not beat_id in _fired:
			_fire(beat)
	evaluate()


# --- Save provider ----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"talked_to": _talked_to.duplicate(), "flags": _flags.duplicate(),
			"fired": _fired.duplicate(), "pending": _pending.duplicate()}


func load_save_data(data: Dictionary) -> void:
	reset_state()
	_talked_to.assign(data.get("talked_to", []))
	_flags.assign(data.get("flags", []))
	_fired.assign(data.get("fired", []))
	_pending.assign(data.get("pending", []))


func reset_state() -> void:
	_talked_to.clear()
	_flags.clear()
	_fired.clear()
	_pending.clear()
	_objective_id = "-"  # Force the next evaluate() to announce the objective.
	if is_inside_tree():
		evaluate.call_deferred()
