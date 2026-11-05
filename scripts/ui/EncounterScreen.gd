class_name EncounterScreen
extends CanvasLayer
## EncounterScreen: the full bedside encounter (EncounterManager) in the
## interview room. Replaces the short interview for a patient that has an
## encounter playable in this build (Main routes the "interview" panel here).
##
## Sections: Introduction, History (asked of the patient first; the informant
## answers what he cannot), Examination (performed on screen by the
## psychiatrist through EncounterStage), Orders (given at the bedside and
## written to the chart), and the Reassessment when a consequence calls the
## player back. A mute patient's non-responses are shown by his model and as
## a short caption in the transcript; they are never narrated aloud.
## Every line is also in the transcript: nothing depends on audio.

const PANEL_ID: String = "encounter"
const SHOWN_SECONDS: float = 2.4
const SECTION_REASSESS: String = "reassess"
const VERDICT_TEXT: Dictionary = {
	"required": "Needed", "preferred": "Best choice", "helpful": "Helpful", "acceptable": "Acceptable",
	"not_yet": "Not yet", "unsafe": "Unsafe",
}

var is_open: bool = false
var patient_id: String = ""
var section: String = "open"
var presenting: bool = false

var _world: Node = null
var _previous_camera: Camera3D = null
var _stage: EncounterStage = null
var _conversation: ConversationPlayer
var _token: int = 0
var _skip_shown: bool = false
var _selected_orders: Dictionary = {}

var _title: Label
var _draft_badge: Control
var _transcript: RichTextLabel
var _tabs: HBoxContainer
var _steps: VBoxContainer
var _side: RichTextLabel
var _skip_button: Button


func _ready() -> void:
	layer = 8
	_build()
	visible = false
	_conversation = ConversationPlayer.new()
	_conversation.name = "Conversation"
	add_child(_conversation)
	EncounterManager.encounter_changed.connect(func(_id: String) -> void:
		if is_open:
			_refresh())


# --- Panel protocol (Main) ---------------------------------------------------------

## data: {"patient_id": String, "world": Node (the interview room's cameras and markers)}
func open(data: Dictionary) -> void:
	patient_id = str(data.get("patient_id", ""))
	_world = data.get("world", null)
	if not EncounterManager.is_playable(patient_id):
		EventBus.ui_panel_closed.emit(PANEL_ID)
		return
	visible = true
	is_open = true
	PatientManager.open_record(patient_id)
	DialogueManager.start_dialogue(patient_id)
	_previous_camera = get_viewport().get_camera_3d()
	var patient: Dictionary = ContentRegistry.get_patient(patient_id)
	_title.text = "%s, %d   ·   Interview Room A" % [patient.get("name", patient_id), patient.get("age", 0)]
	_draft_badge.visible = EncounterManager.is_draft(patient_id)
	if _world != null:
		_stage = EncounterStage.new()
		_stage.name = "EncounterStage"
		_world.add_child(_stage)
		_stage.begin(patient_id, EncounterManager.informant(patient_id).get("id", ""))
	section = _default_section()
	_rebuild_transcript()
	_refresh()


func close() -> void:
	if not is_open:
		return
	_token += 1
	_conversation.cancel()
	presenting = false
	DialogueManager.end_dialogue()
	visible = false
	is_open = false
	if is_instance_valid(_stage):
		_stage.end()
		_stage.queue_free()
	_stage = null
	if is_instance_valid(_previous_camera):
		_previous_camera.make_current()
	EventBus.ui_panel_closed.emit(PANEL_ID)


# --- Actions (buttons call these; so do tests) -----------------------------------

func show_section(section_id: String) -> void:
	section = section_id
	_refresh()


## Performs a step and presents it. Returns false if it could not be done.
func do_step(step_id: String) -> bool:
	if presenting:
		skip_all()
	var result: Dictionary = EncounterManager.perform_step(patient_id, step_id)
	if result.is_empty():
		return false
	_present(result)
	return true


func toggle_order(item_id: String, selected: bool) -> void:
	if selected:
		_selected_orders[item_id] = true
	else:
		_selected_orders.erase(item_id)


func selected_orders() -> Array[String]:
	var ids: Array[String] = []
	for item: Dictionary in EncounterManager.order_items(patient_id):
		if _selected_orders.has(item["id"]):
			ids.append(item["id"])
	return ids


## Gives the selected orders; the psychiatrist says them aloud to the sitter.
func give_orders() -> Dictionary:
	var ids: Array[String] = selected_orders()
	var result: Dictionary = EncounterManager.give_orders(patient_id, ids)
	if result.is_empty():
		return result
	_selected_orders.clear()
	var labels: Array[String] = []
	for id: String in ids:
		labels.append(str(EncounterManager.get_order_item(patient_id, id)["label"]).to_lower())
	var sitter: String = str(EncounterManager.informant(patient_id).get("id", ""))
	var beats: Array = [{"speaker": sitter, "text": "Got it, Doctor. I'll let the charge nurse know and get it all on the chart."}]
	if result.get("challenge", false):
		var hold: Dictionary = EncounterManager.definition(patient_id)["consequences"]["antipsychotic_hold"]
		beats.append({"speaker": hold["speaker"], "text": hold["text"]})
	_present({"player": "Tom, here's the plan: %s." % "; ".join(labels), "beats": beats, "performs": "talk_to_sitter", "patient_performs": ""})
	return result


func resolve_challenge(choice_id: String) -> String:
	var reply: String = EncounterManager.resolve_challenge(patient_id, choice_id)
	if not reply.is_empty():
		var hold: Dictionary = EncounterManager.definition(patient_id)["consequences"]["antipsychotic_hold"]
		_present({"player": "", "beats": [{"speaker": hold["speaker"], "text": reply}], "performs": "", "patient_performs": ""})
	return reply


## Ends the line being spoken (or the caption being shown); the next one follows.
func skip_line() -> void:
	_skip_shown = true
	_conversation.skip_line()


## Ends the whole presentation now.
func skip_all() -> void:
	_token += 1
	_conversation.cancel()
	presenting = false
	_skip_button.visible = false
	if is_instance_valid(_stage):
		_stage.settle()
	_refresh()


func is_presenting() -> bool:
	return presenting


func get_transcript_text() -> String:
	return _transcript.get_parsed_text()


func get_step_labels() -> Array[String]:
	var labels: Array[String] = []
	for step: Dictionary in _visible_steps():
		labels.append(step["label"])
	return labels


# --- Presentation -------------------------------------------------------------------

func _present(result: Dictionary) -> void:
	_token += 1
	var token: int = _token
	presenting = true
	_skip_button.visible = true
	_refresh()
	if is_instance_valid(_stage) and not str(result.get("performs", "")).is_empty():
		_stage.perform(str(result["performs"]), str(result.get("patient_performs", "")))
	var player_line: String = str(result.get("player", ""))
	if not player_line.is_empty():
		_append("player", player_line)
		await _speak("player", player_line)
		if token != _token:
			return
	for beat: Dictionary in result.get("beats", []):
		var speaker: String = str(beat.get("speaker", ""))
		if is_instance_valid(_stage):
			_stage.beat(speaker, str(beat.get("act", "")))
		if beat.has("shown"):
			_append_shown(speaker, str(beat["shown"]))
			await _hold_shown()
			if token != _token:
				return
		if beat.has("text"):
			_append(speaker, str(beat["text"]))
			await _speak(speaker, str(beat["text"]))
			if token != _token:
				return
	presenting = false
	_skip_button.visible = false
	if is_instance_valid(_stage):
		_stage.settle()
	_refresh()


func _speak(speaker: String, text: String) -> void:
	var parts: Array[Dictionary] = [{"speaker": speaker, "text": text, "line_id": AudioDirector.find_line(speaker, text)}]
	if is_instance_valid(_stage):
		_stage.speaking(speaker)
	await _conversation.play(parts)


func _hold_shown() -> void:
	_skip_shown = false
	var waited: float = 0.0
	while waited < SHOWN_SECONDS and not _skip_shown and is_open:
		await get_tree().create_timer(0.1, false).timeout
		waited += 0.1


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or not presenting:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		skip_line()
		get_viewport().set_input_as_handled()


# --- Transcript ---------------------------------------------------------------------

func _rebuild_transcript() -> void:
	_transcript.text = ""
	for section_info: Dictionary in EncounterManager.definition(patient_id).get("sections", []):
		for step: Dictionary in EncounterManager.definition(patient_id)["steps"]:
			if step["section"] == section_info["id"] and EncounterManager.is_done(patient_id, step["id"]):
				_append_step(step)
	for step: Dictionary in EncounterManager.reassessment(patient_id).get("steps", []):
		if EncounterManager.is_done(patient_id, step["id"]):
			_append_step(step)


func _append_step(step: Dictionary) -> void:
	if not str(step.get("player", "")).is_empty():
		_append("player", str(step["player"]))
	for beat: Dictionary in step["beats"]:
		if beat.has("shown"):
			_append_shown(str(beat["speaker"]), str(beat["shown"]))
		if beat.has("text"):
			_append(str(beat["speaker"]), str(beat["text"]))


func _append(speaker: String, text: String) -> void:
	var safe: String = text.replace("[", "[lb]")
	_transcript.append_text("[b]%s:[/b] %s\n" % [ConversationPlayer._speaker_name(speaker), safe])


func _append_shown(_speaker: String, text: String) -> void:
	_transcript.append_text("[i][color=#%s]%s[/color][/i]\n" % [UIStyle.ACCENT.to_html(false), text.replace("[", "[lb]")])


# --- Layout -------------------------------------------------------------------------

func _default_section() -> String:
	if EncounterManager.reassessment_state(patient_id) == "ready":
		return SECTION_REASSESS
	if not EncounterManager.is_done(patient_id, "open_introduce"):
		return "open"
	return "history"


func _visible_steps() -> Array[Dictionary]:
	if section == SECTION_REASSESS:
		var result: Array[Dictionary] = []
		for step: Dictionary in EncounterManager.reassessment(patient_id).get("steps", []):
			result.append({"id": step["id"], "label": step["label"], "done": EncounterManager.is_done(patient_id, step["id"])})
		return result
	return EncounterManager.steps_for(patient_id, section)


func _refresh() -> void:
	for child: Node in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	var sections: Array = EncounterManager.definition(patient_id).get("sections", []).duplicate()
	if EncounterManager.reassessment_state(patient_id) in ["ready", "done"]:
		sections.append({"id": SECTION_REASSESS, "label": "Reassessment"})
	for info: Dictionary in sections:
		var tab: Button = UIStyle.secondary_button(str(info["label"]), 16)
		tab.name = "Tab_" + str(info["id"])
		tab.toggle_mode = true
		tab.button_pressed = info["id"] == section
		var id: String = str(info["id"])
		tab.pressed.connect(func() -> void: show_section(id))
		_tabs.add_child(tab)
	for child: Node in _steps.get_children():
		_steps.remove_child(child)
		child.queue_free()
	if section == "plan":
		_build_orders()
	else:
		for step: Dictionary in _visible_steps():
			var button: Button = UIStyle.button(("✓  " if step["done"] else "") + str(step["label"]))
			button.name = "Step_" + str(step["id"])
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.disabled = step["done"] or presenting
			var step_id: String = str(step["id"])
			button.pressed.connect(func() -> void: do_step(step_id))
			_steps.add_child(button)
		if _steps.get_child_count() == 0:
			_steps.add_child(UIStyle.label("Introduce yourself first.", 16, UIStyle.MUTED))
	_side.text = _side_text()


func _build_orders() -> void:
	var state: String = EncounterManager.challenge_state(patient_id)
	if state == "pending":
		var hold: Dictionary = EncounterManager.definition(patient_id)["consequences"]["antipsychotic_hold"]
		_steps.add_child(UIStyle.label("Nurse Bennett is asking about the antipsychotic.", 17, UIStyle.WARNING))
		for choice: Dictionary in hold["choices"]:
			var button: Button = UIStyle.button(str(choice["label"]))
			button.name = "Challenge_" + str(choice["id"])
			button.disabled = presenting
			var choice_id: String = str(choice["id"])
			button.pressed.connect(func() -> void: resolve_challenge(choice_id))
			_steps.add_child(button)
		return
	if EncounterManager.orders_given(patient_id):
		_steps.add_child(UIStyle.label("Orders given and written to the chart.", 17, UIStyle.GOOD))
		var feedback: RichTextLabel = UIStyle.rich_text(true)
		for entry: Dictionary in EncounterManager.order_feedback(patient_id):
			var mark: String = "✓" if entry["given"] else "○"
			feedback.append_text("%s [b]%s[/b] (%s%s): %s\n" % [mark, entry["label"], VERDICT_TEXT.get(entry["verdict"], entry["verdict"]),
					"" if entry["given"] else ", not ordered", entry["feedback"]])
		_steps.add_child(feedback)
		return
	if not EncounterManager.orders_open(patient_id):
		_steps.add_child(UIStyle.label("Take the history and examine him first: you need to have seen his mutism and posturing yourself.", 16, UIStyle.MUTED))
		return
	_steps.add_child(UIStyle.label(str(EncounterManager.definition(patient_id)["orders"].get("intro", "")), 16, UIStyle.MUTED))
	for group: Dictionary in EncounterManager.order_groups(patient_id):
		_steps.add_child(UIStyle.label(str(group["label"]), 17, UIStyle.ACCENT))
		for item: Dictionary in EncounterManager.order_items(patient_id):
			if item["group"] != group["id"]:
				continue
			var box: CheckBox = CheckBox.new()
			box.name = "Order_" + str(item["id"])
			box.text = str(item["label"])
			box.add_theme_font_size_override("font_size", 16)
			box.button_pressed = _selected_orders.has(item["id"])
			var item_id: String = str(item["id"])
			box.toggled.connect(func(on: bool) -> void: toggle_order(item_id, on))
			_steps.add_child(box)
	var give: Button = UIStyle.primary_button("Give orders")
	give.name = "GiveOrders"
	give.disabled = presenting
	give.pressed.connect(func() -> void: give_orders())
	_steps.add_child(give)


func _side_text() -> String:
	var lines: Array[String] = ["[b]History[/b]"]
	for domain: Dictionary in EncounterManager.history_coverage(patient_id):
		lines.append("%s %s" % ["✓" if domain["covered"] else "○", domain["label"]])
	var recorded: Dictionary = PatientManager.get_state(patient_id).get("observations", {})
	lines.append("\n[b]Findings[/b]")
	if recorded.is_empty():
		lines.append("[color=#%s]None yet[/color]" % UIStyle.MUTED.to_html(false))
	for observation_id: String in recorded:
		lines.append("• " + UIStyle.humanize(observation_id.trim_prefix("obs_")))
	if EncounterManager.labs_ready(patient_id):
		lines.append("\n[b]Results[/b]")
		for lab: Dictionary in EncounterManager.lab_results(patient_id):
			lines.append("• %s: %s" % [lab["label"], lab["result"]])
	return "\n".join(lines)


func _build() -> void:
	var root: Control = UIStyle.make_root(self, 0.0)
	_title = UIStyle.label("", 20)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.offset_top = 24
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 6)
	root.add_child(_title)
	_draft_badge = UIStyle.chip("Draft clinical content: pending psychiatrist review", UIStyle.WARNING, 15)
	_draft_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_draft_badge.offset_left = 24
	_draft_badge.offset_top = 22
	root.add_child(_draft_badge)

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style(0.9))
	panel.anchor_left = 0.03
	panel.anchor_top = 0.55
	panel.anchor_right = 0.97
	panel.anchor_bottom = 0.97
	root.add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)

	_transcript = UIStyle.rich_text()
	_transcript.scroll_following = true
	_transcript.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_transcript.size_flags_stretch_ratio = 1.4
	row.add_child(_transcript)

	var middle: VBoxContainer = VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_stretch_ratio = 1.3
	_tabs = HBoxContainer.new()
	middle.add_child(_tabs)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_steps = VBoxContainer.new()
	_steps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_steps)
	middle.add_child(scroll)
	var buttons: HBoxContainer = HBoxContainer.new()
	_skip_button = UIStyle.button("Skip line  (Space)")
	_skip_button.name = "SkipLine"
	_skip_button.visible = false
	_skip_button.pressed.connect(skip_line)
	buttons.add_child(_skip_button)
	var end: Button = UIStyle.button("Leave the room  (Esc)")
	end.pressed.connect(close)
	buttons.add_child(end)
	middle.add_child(buttons)
	row.add_child(middle)

	_side = UIStyle.rich_text()
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.size_flags_stretch_ratio = 0.8
	row.add_child(_side)
