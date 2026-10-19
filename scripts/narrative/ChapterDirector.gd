class_name ChapterDirector
extends Node
## ChapterDirector: runs the current chapter's story data
## (ContentRegistry.get_story(chapter_id)) and keeps every chapter's state.
##
## - Objectives: shown in order; the current one is the first that is neither
##   complete nor expired (e.g. day-shift tasks once the night begins).
## - Beats: fire once when their condition holds, optionally after a delay
##   in game minutes (scheduled through TimeManager, so delays are saved).
## - Staff lines: what a staff member says now (first matching line).
## - Sign-out: ends the day shift (handover quality changes trust) or, at
##   night, completes the chapter.
## - Chapters: story state (who you talked to, flags, fired and pending beats)
##   is kept per chapter id. A start_chapter action moves on; the earlier
##   chapter's state stays readable (chapter_completed / chapter_flag
##   conditions) and its beats never fire again.
## Conditions and actions are StoryLogic's closed vocabulary. The director
## never changes clinical state; chart entries are audit records only.
## Saved as the "chapter" provider:
##     {"current": chapter_id, "chapters": {chapter_id: {talked_to, flags, fired, pending}}}
## Lives in Main (group "chapter_director").

const PROVIDER_KEY: String = "chapter"
const GROUP: String = "chapter_director"
const SCHEDULE_PREFIX: String = "story:"

var _chapter_id: String = ""
## State of every chapter other than the current one: chapter_id -> state.
var _archive: Dictionary = {}
var _talked_to: Array[String] = []
var _flags: Array[String] = []
var _fired: Array[String] = []
var _pending: Array[String] = []
var _objective_id: String = ""
var _evaluating: bool = false
var _active_interaction: String = ""


func _ready() -> void:
	add_to_group(GROUP)
	_set_current(ContentRegistry.get_start_chapter_id(), {})
	SaveManager.register_provider(PROVIDER_KEY, self)
	EventBus.interacted.connect(_on_interacted)
	EventBus.scheduled_event_fired.connect(_on_scheduled_event)
	EventBus.shift_signout_requested.connect(sign_out)
	EventBus.story_option_selected.connect(_on_story_option_selected)
	EventBus.ui_panel_closed.connect(func(panel_id: String) -> void:
		if panel_id == "info":
			_active_interaction = "")
	for signal_name: String in ["observation_recorded", "patient_note_saved", "clinical_action_committed",
			"clue_acquired", "hypothesis_updated", "shift_started", "trust_changed", "zone_changed"]:
		var argc: int = 0
		for info: Dictionary in EventBus.get_signal_list():
			if info["name"] == signal_name:
				argc = info["args"].size()
		EventBus.connect(signal_name, evaluate.unbind(argc))
	EventBus.game_loaded.connect(func(_slot: int) -> void:
		_active_interaction = ""
		evaluate())
	evaluate.call_deferred()


func _exit_tree() -> void:
	SaveManager.unregister_provider(PROVIDER_KEY)


# --- Queries --------------------------------------------------------------------

func get_chapter_id() -> String:
	return _chapter_id


## True once the chapter's own sign-out completed it.
func has_completed(chapter_id: String) -> bool:
	return StoryLogic.CHAPTER_COMPLETE_FLAG in get_chapter_flags(chapter_id)


## Flags of any chapter, current or earlier ([] if it never started).
func get_chapter_flags(chapter_id: String) -> Array:
	if chapter_id == _chapter_id:
		return _flags.duplicate()
	return _archive.get(chapter_id, {}).get("flags", []).duplicate()


func get_current_objective() -> Dictionary:
	if not ContentRegistry.is_valid:
		return {}
	var state: Dictionary = _story_state()
	for objective: Dictionary in _story().get("objectives", []):
		if objective.has("expires_when") and StoryLogic.evaluate(objective["expires_when"], state):
			continue
		if not StoryLogic.evaluate(objective["complete_when"], state):
			return objective
	return {}


## Read-only story state for other evaluators (AnomalyLedger): flags of the
## current chapter and every earlier one, in StoryLogic.evaluate()'s shape.
func get_story_context() -> Dictionary:
	return _story_state().duplicate(true)


func has_flag(flag: String) -> bool:
	return flag in _flags


func has_fired(beat_id: String) -> bool:
	return beat_id in _fired


## The line a staff member says right now, or {} for their default intro.
func get_staff_line(staff_id: String) -> Dictionary:
	if not ContentRegistry.is_valid:
		return {}
	for line: Dictionary in _story().get("staff_lines", []):
		if line["staff_id"] == staff_id and StoryLogic.evaluate(line["when"], _story_state()):
			return line
	return {}


## True when a story interaction is open for this interactable right now, so a
## patient's story scene shows instead of a clinical interview.
func has_open_interaction(interactable_id: String) -> bool:
	if not ContentRegistry.is_valid:
		return false
	for interaction: Dictionary in _story().get("interactions", []):
		if interaction["interactable_id"] != interactable_id:
			continue
		if interaction.has("expires_when") and StoryLogic.evaluate(interaction["expires_when"], _story_state()):
			continue
		if StoryLogic.evaluate(interaction["when"], _story_state()):
			return true
	return false


## The closing summary: the final choice's response, then each decision line
## that applies to this playthrough.
func _campaign_end_panel(response: String) -> Dictionary:
	var end: Dictionary = _story()["campaign_end"]
	var lines: Array[String] = [response, "", end["body"]]
	for line: Dictionary in end["lines"]:
		if StoryLogic.evaluate(line["when"], _story_state()):
			lines.append("• " + str(line["text"]))
	return {"title": end["title"], "body": "\n".join(lines)}


# --- Story progression -------------------------------------------------------------

## Re-checks beats and the current objective. Called on every relevant event.
func evaluate() -> void:
	if _evaluating or not ContentRegistry.is_valid:
		return
	_evaluating = true
	for beat: Dictionary in _story().get("beats", []):
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
		if flag == StoryLogic.CHAPTER_COMPLETE_FLAG:
			EventBus.chapter_completed.emit(_chapter_id)
		evaluate()


## Moves to another chapter. The current chapter's state is kept, and the
## new chapter resumes its own state if it was started before. Returns false
## for an unknown or unplayable chapter, or the chapter already running.
func start_chapter(chapter_id: String) -> bool:
	if chapter_id == _chapter_id or not ContentRegistry.is_chapter_playable(chapter_id):
		if chapter_id != _chapter_id:
			push_warning("ChapterDirector: chapter '%s' is not playable" % chapter_id)
		return false
	_archive[_chapter_id] = _current_state()
	_set_current(chapter_id, _archive.get(chapter_id, {}))
	_archive.erase(chapter_id)
	EventBus.chapter_started.emit(chapter_id)
	evaluate()
	return true


## Signs out at the handover board. Day: hand over and start the night shift.
## Night: complete the chapter. Returns the summary text shown to the player.
func sign_out() -> String:
	var story: Dictionary = _story()
	if not story.has("sign_out"):
		push_warning("ChapterDirector: chapter '%s' has no sign-out" % _chapter_id)
		return ""
	var config: Dictionary = story["sign_out"]
	var body: String
	if has_flag(StoryLogic.CHAPTER_COMPLETE_FLAG):
		body = "You have already signed out. %s is complete.\n\n%s" % [story["title"], _shift_summary()]
	elif TimeManager.get_shift() == "day":
		body = _hand_over(config)
		TimeManager.advance_to_next_shift()
		body += "\n\n[b]The night shift has begun.[/b] (%s)" % TimeManager.get_clock_string()
	else:
		set_flag(StoryLogic.CHAPTER_COMPLETE_FLAG)
		body = "[b]End of %s[/b] (playable slice)\n\n%s\n\n%s" % [story["title"],
				_shift_summary(), _relationship_summary()]
	var panel: Dictionary = {"title": config["title"], "body": body}
	var next_chapter: String = str(story.get("next_chapter", ""))
	if has_completed(_chapter_id) and ContentRegistry.is_chapter_playable(next_chapter):
		_active_interaction = "continue:" + _chapter_id
		panel["interaction_id"] = _active_interaction
		panel["options"] = [{"id": "continue", "label": "Return for the next day shift"}]
	EventBus.ui_panel_requested.emit("info", panel)
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
	for patient_id: String in ContentRegistry.get_patient_ids().filter(PatientManager.is_admitted):
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
		"start_chapter":
			# Deferred: the current chapter finishes this evaluation first.
			start_chapter.call_deferred(value)
		"safe_return":
			_safe_return.call_deferred(value["connection"], value["from"])


## Moves the player out through a connection, but only from the named zone, so
## a replayed beat can never send anyone the other way.
func _safe_return(connection_id: String, from_zone: String) -> void:
	var zones: ZoneDirector = get_tree().get_first_node_in_group(ZoneDirector.GROUP) if is_inside_tree() else null
	if zones != null and zones.current_zone_id == from_zone:
		zones.use_connection(connection_id, from_zone)


func _update_objective() -> void:
	var objective: Dictionary = get_current_objective()
	var objective_id: String = objective.get("id", "")
	if objective_id == _objective_id:
		return
	_objective_id = objective_id
	EventBus.objective_changed.emit(objective_id, objective.get("text", ""))


func _story() -> Dictionary:
	return ContentRegistry.get_story(_chapter_id)


func _story_state() -> Dictionary:
	var chapters: Dictionary = {}
	for chapter_id: String in _archive:
		chapters[chapter_id] = {"flags": _archive[chapter_id].get("flags", [])}
	chapters[_chapter_id] = {"flags": _flags}
	# Location belongs to ZoneDirector's existing save provider. Read it here
	# instead of keeping a second copy that can drift on same-zone loads.
	var zones: Node = get_tree().get_first_node_in_group(ZoneDirector.GROUP) if is_inside_tree() else null
	var zone: String = zones.current_zone_id if zones != null else str(ContentRegistry.get_world().get("start_zone", ""))
	return {"talked_to": _talked_to, "flags": _flags, "chapters": chapters, "zone": zone}


func _current_state() -> Dictionary:
	return {"talked_to": _talked_to.duplicate(), "flags": _flags.duplicate(),
			"fired": _fired.duplicate(), "pending": _pending.duplicate()}


func _set_current(chapter_id: String, state: Dictionary) -> void:
	_active_interaction = ""
	_chapter_id = chapter_id
	_talked_to.assign(state.get("talked_to", []))
	_flags.assign(state.get("flags", []))
	_fired.assign(state.get("fired", []))
	_pending.assign(state.get("pending", []))
	_objective_id = "-"  # Force the next evaluate() to announce the objective.


func _on_interacted(interactable_id: String) -> void:
	# The prop's local signal has already opened sign-out before this event.
	# Retain the continuation choice it just displayed.
	for entry: Dictionary in ContentRegistry.get_world(_chapter_id).get("interactables", []):
		if entry["node"] == interactable_id and entry["type"] == "shift_signout":
			return
	_active_interaction = ""
	var fallback: Dictionary = {}
	var opened: bool = false
	for interaction: Dictionary in _story().get("interactions", []):
		if interaction["interactable_id"] != interactable_id:
			continue
		if interaction.has("expires_when") and StoryLogic.evaluate(interaction["expires_when"], _story_state()):
			if interaction.has("completed_body"):
				fallback = {"title": interaction["title"], "body": interaction["completed_body"]}
			continue
		if not StoryLogic.evaluate(interaction["when"], _story_state()):
			if fallback.is_empty():
				fallback = {"title": interaction["title"], "body": interaction["unavailable_body"]}
			continue
		_active_interaction = interaction["id"]
		var panel: Dictionary = interaction.duplicate(true)
		panel["interaction_id"] = _active_interaction
		EventBus.ui_panel_requested.emit("info", panel)
		opened = true
		break
	if not opened and not fallback.is_empty() and not interactable_id.begins_with("character:"):
		EventBus.ui_panel_requested.emit("info", fallback)
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
	for beat: Dictionary in _story().get("beats", []):
		if beat["id"] == beat_id and not beat_id in _fired:
			_fire(beat)
	evaluate()


# --- Save provider ----------------------------------------------------------------------

func to_save_data() -> Dictionary:
	var chapters: Dictionary = {}
	for chapter_id: String in _archive:
		chapters[chapter_id] = _archive[chapter_id].duplicate(true)
	chapters[_chapter_id] = _current_state()
	return {"current": _chapter_id, "chapters": chapters}


func load_save_data(data: Dictionary) -> void:
	reset_state()
	var chapters: Dictionary = data.get("chapters", {})
	var current: String = str(data.get("current", ContentRegistry.get_start_chapter_id()))
	for chapter_id: String in chapters:
		if chapter_id != current:
			var state: Dictionary = chapters[chapter_id]
			_archive[chapter_id] = {"talked_to": state.get("talked_to", []), "flags": state.get("flags", []),
					"fired": state.get("fired", []), "pending": state.get("pending", [])}
	_set_current(current, chapters.get(current, {}))


func reset_state() -> void:
	_archive.clear()
	_set_current(ContentRegistry.get_start_chapter_id(), {})
	if is_inside_tree():
		evaluate.call_deferred()


func _on_story_option_selected(interaction_id: String, option_id: String) -> void:
	if interaction_id.is_empty() or interaction_id != _active_interaction:
		return
	if interaction_id == "continue:" + _chapter_id and option_id == "continue":
		var next_chapter: String = str(_story().get("next_chapter", ""))
		_active_interaction = ""
		if has_completed(_chapter_id) and start_chapter(next_chapter):
			var target: int = TimeManager.total_minutes - TimeManager.get_minute_of_day() + TimeManager.DAY_SHIFT_START
			if target <= TimeManager.total_minutes:
				target += TimeManager.MINUTES_PER_DAY
			TimeManager.advance(target - TimeManager.total_minutes, "chapter_transition")
		return
	for interaction: Dictionary in _story().get("interactions", []):
		if interaction["id"] != interaction_id or not StoryLogic.evaluate(interaction["when"], _story_state()):
			continue
		if interaction.has("expires_when") and StoryLogic.evaluate(interaction["expires_when"], _story_state()):
			continue
		for option: Dictionary in interaction["options"]:
			if option["id"] != option_id:
				continue
			_active_interaction = ""
			for access_id: String in option.get("grants_access", []):
				TrustManager.grant_access(access_id, "story:" + interaction_id)
			for access_id: String in option.get("revokes_access", []):
				TrustManager.revoke_access(access_id)
			if option.has("flag"):
				set_flag(option["flag"])
			var panel: Dictionary = {"title": interaction["title"], "body": option["response"]}
			# A choice that completes the chapter offers the next one, as sign-out does.
			if option.get("flag", "") == StoryLogic.CHAPTER_COMPLETE_FLAG \
					and ContentRegistry.is_chapter_playable(str(_story().get("next_chapter", ""))):
				_active_interaction = "continue:" + _chapter_id
				panel["interaction_id"] = _active_interaction
				panel["options"] = [{"id": "continue", "label": "Return for the next day shift"}]
			elif option.get("flag", "") == StoryLogic.CHAPTER_COMPLETE_FLAG and _story().has("campaign_end"):
				panel = _campaign_end_panel(option["response"])
			elif option.has("next_interaction"):
				panel = _follow_on_panel(option["next_interaction"], option["response"], panel)
			EventBus.ui_panel_requested.emit("info", panel)
			return


## The next scene after a choice, opened in the same panel under the choice's
## response. Falls back to the plain response when that scene is not open.
func _follow_on_panel(interaction_id: String, response: String, plain: Dictionary) -> Dictionary:
	for next: Dictionary in _story().get("interactions", []):
		if next["id"] != interaction_id or not StoryLogic.evaluate(next["when"], _story_state()):
			continue
		if next.has("expires_when") and StoryLogic.evaluate(next["expires_when"], _story_state()):
			continue
		_active_interaction = interaction_id
		var panel: Dictionary = next.duplicate(true)
		panel["interaction_id"] = interaction_id
		panel["body"] = response + "\n\n" + str(next["body"])
		return panel
	return plain
