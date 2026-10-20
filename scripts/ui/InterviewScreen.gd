class_name InterviewScreen
extends CanvasLayer
## InterviewScreen: the cinematic patient interview (GDD §9).
##
## Cuts between the interview-room cameras authored in Blender (CAM_IR_*,
## imported as Camera3D nodes) and restores the player's camera on close.
## The player picks one of the authored choices. The choice is applied once,
## immediately (DialogueManager: state, findings, time), then presented: the
## psychiatrist's spoken question, then the response, each voiced through
## AudioDirector with its subtitle. A mute patient's response is the narrator
## describing what is observed. Choices stay disabled until the response ends
## or the player skips (Space / Enter / the Skip button). Every line is also in
## the transcript: nothing depends on audio.
## Typed questions (DialogueManager free text) are a development tool only:
## the field appears with the `--dev-free-text` argument, never in normal play.
##
## Shot rules (deterministic):
##   open, clarify, fallback    -> establishing shot
##   patient answers            -> over-the-shoulder onto the patient
## The close-up and reverse (onto the psychiatrist) cameras exist in the
## room but stay unused until character models replace the capsule
## stand-ins: a close-up of a capsule, or of an empty chair, reads as a bug.

const PANEL_ID: String = "interview"
const SHOT_ESTABLISHING: String = "CAM_IR_Establishing"
const SHOT_ON_PATIENT: String = "CAM_IR_OTS_OnPatient"
const DEV_FREE_TEXT_ARG: String = "--dev-free-text"

var is_open: bool = false
var patient_id: String = ""
var current_shot: String = ""

var _world: Node = null
var _previous_camera: Camera3D = null
var _name_label: Label
var _transcript: RichTextLabel
var _choices: VBoxContainer
var _question: LineEdit
var _ask_row: HBoxContainer
var _end_button: Button
var _skip_button: Button
var _conversation: ConversationPlayer
## The choice whose question and response are being presented ("" when idle).
var presenting_choice: String = ""


func _ready() -> void:
	layer = 8
	_build()
	visible = false
	EventBus.dialogue_line_added.connect(_on_line_added)
	_conversation = ConversationPlayer.new()
	_conversation.name = "Conversation"
	add_child(_conversation)


## Whether typed questions are offered (development only).
static func free_text_enabled() -> bool:
	return DEV_FREE_TEXT_ARG in OS.get_cmdline_user_args()


# --- Panel protocol (Main) ---------------------------------------------------------

## data: {"patient_id": String, "world": Node (holds the CAM_IR_* cameras)}
func open(data: Dictionary) -> void:
	patient_id = str(data.get("patient_id", ""))
	_world = data.get("world", null)
	if not DialogueManager.start_dialogue(patient_id):
		EventBus.notification_requested.emit("No interview is authored for this patient yet.")
		EventBus.ui_panel_closed.emit(PANEL_ID)
		return
	visible = true
	is_open = true
	_previous_camera = get_viewport().get_camera_3d()
	var patient: Dictionary = ContentRegistry.get_patient(patient_id)
	_name_label.text = "%s, %d   ·   Interview Room A" % [patient.get("name", patient_id), patient.get("age", 0)]
	_transcript.text = ""
	for line: Dictionary in DialogueManager.get_transcript(patient_id):
		_append_line(line["speaker"], line["text"])
	_set_name_tag_visible(false)
	_cut_to(SHOT_ESTABLISHING)
	_rebuild_choices()
	_question.text = ""
	_ask_row.visible = free_text_enabled()
	_skip_button.visible = false
	if _ask_row.visible:
		_question.grab_focus()
	elif _choices.get_child_count() > 0:
		(_choices.get_child(0) as Control).grab_focus()


func close() -> void:
	if not is_open:
		return
	_conversation.cancel()
	presenting_choice = ""
	DialogueManager.end_dialogue()
	visible = false
	is_open = false
	if is_instance_valid(_previous_camera):
		_previous_camera.make_current()
	_set_name_tag_visible(true)
	current_shot = ""
	EventBus.ui_panel_closed.emit(PANEL_ID)


# --- Actions (buttons call these; so do tests) -----------------------------------

## Applies the choice once, then presents its question and response. A choice
## made while another is still being presented skips that presentation.
func ask_choice(choice_id: String) -> void:
	var available: bool = DialogueManager.get_choices().any(
			func(choice: Dictionary) -> bool: return choice["id"] == choice_id)
	if not available:
		DialogueManager.select_choice(choice_id)  # Reports the unavailable choice.
		return
	var label: String = ""
	for choice: Dictionary in DialogueManager.get_choices():
		if choice["id"] == choice_id:
			label = choice["label"]
	var response: String = DialogueManager.select_choice(choice_id)
	_after_answer("matched")
	_present(choice_id, label, response)


## The voiced question and response for a choice, in order.
func presentation_for(choice_id: String, label: String, response: String) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	var question_line: String = AudioDirector.find_choice_line(patient_id, choice_id)
	if not question_line.is_empty():
		parts.append({"speaker": "player", "text": AudioDirector.get_line(question_line)["text"], "line_id": question_line})
	else:
		parts.append_array(VoiceScript.segments(label, "player"))
	parts.append_array(VoiceScript.segments(response, patient_id))
	return parts


## Ends the line being spoken; the next one follows.
func skip_line() -> void:
	_conversation.skip_line()


func is_presenting() -> bool:
	return _conversation.is_playing


func _present(choice_id: String, label: String, response: String) -> void:
	_set_choices_enabled(false)
	_skip_button.visible = true
	_skip_button.grab_focus()
	var token: String = choice_id + str(Time.get_ticks_usec())
	presenting_choice = token
	await _conversation.play(presentation_for(choice_id, label, response))
	if presenting_choice != token or not is_open:
		return  # Replaced by another choice or the interview closed.
	presenting_choice = ""
	_skip_button.visible = false
	_set_choices_enabled(true)
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Control).grab_focus()


func _set_choices_enabled(enabled: bool) -> void:
	for child: Node in _choices.get_children():
		if child is Button:
			(child as Button).disabled = not enabled


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or not _conversation.is_playing:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		skip_line()
		get_viewport().set_input_as_handled()


## Typed question. Returns DialogueManager's result {status, response, ...}.
func ask_text(text: String) -> Dictionary:
	if text.strip_edges().is_empty():
		return {}
	var result: Dictionary = DialogueManager.submit_free_text(text)
	_question.text = ""
	_after_answer(result["status"])
	return result


func get_choice_labels() -> Array[String]:
	var labels: Array[String] = []
	for choice: Dictionary in DialogueManager.get_choices():
		labels.append(choice["label"])
	return labels


func get_transcript_text() -> String:
	return _transcript.get_parsed_text()


# --- Internals ------------------------------------------------------------------

func _after_answer(status: String) -> void:
	_cut_to(SHOT_ON_PATIENT if status == "matched" else SHOT_ESTABLISHING)
	if status == "matched":
		for observation_id: String in DialogueManager.last_recorded_observations:
			EventBus.notification_requested.emit("Finding recorded in the EHR: " +
					UIStyle.humanize(observation_id.trim_prefix("obs_")))
	_rebuild_choices()


func _cut_to(shot: String) -> void:
	if _world == null:
		return
	var camera: Camera3D = _world.find_child(shot, true, false) as Camera3D
	if camera == null:
		return  # Greybox rooms have no authored cameras: keep the player's view.
	camera.make_current()
	current_shot = shot


## The floating name above the patient duplicates the on-screen title.
func _set_name_tag_visible(shown: bool) -> void:
	if _world == null:
		return
	var tag: Node3D = _world.find_child("Character_" + patient_id, true, false)
	if tag != null and tag.has_node("NameLabel"):
		(tag.get_node("NameLabel") as Node3D).visible = shown


func _rebuild_choices() -> void:
	for child: Node in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for choice: Dictionary in DialogueManager.get_choices():
		var button: Button = UIStyle.button(choice["label"])
		button.name = "Choice_" + str(choice["id"])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = _conversation != null and _conversation.is_playing
		var choice_id: String = choice["id"]
		button.pressed.connect(func() -> void: ask_choice(choice_id))
		_choices.add_child(button)


func _on_line_added(line_patient_id: String, speaker: String, text: String) -> void:
	if is_open and line_patient_id == patient_id:
		_append_line(speaker, text)


func _append_line(speaker: String, text: String) -> void:
	var safe: String = text.replace("[", "[lb]")
	match speaker:
		"physician":
			_transcript.append_text("[b]You:[/b] %s\n" % safe)
		"patient":
			_transcript.append_text("[b]%s:[/b] %s\n\n" % [ContentRegistry.get_patient(patient_id).get("name", "Patient"), safe])
		_:
			_transcript.append_text("[i][color=#%s]%s[/color][/i]\n\n" % [UIStyle.MUTED.to_html(false), safe])


func _build() -> void:
	var root: Control = UIStyle.make_root(self, 0.0)
	_name_label = UIStyle.label("", 20)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_name_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_name_label.offset_top = 24
	_name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_name_label.add_theme_constant_override("outline_size", 6)
	root.add_child(_name_label)

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style(0.9))
	panel.anchor_left = 0.04
	panel.anchor_top = 0.6
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.97
	root.add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)

	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	_transcript = UIStyle.rich_text()
	_transcript.scroll_following = true
	left.add_child(_transcript)
	_ask_row = HBoxContainer.new()
	var ask_row: HBoxContainer = _ask_row
	_question = LineEdit.new()
	_question.placeholder_text = "Type a question, e.g. \"Is he eating?\"  (Enter to ask)"
	_question.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_question.add_theme_font_size_override("font_size", 17)
	_question.text_submitted.connect(func(text: String) -> void: ask_text(text))
	ask_row.add_child(_question)
	var ask: Button = UIStyle.button("Ask")
	ask.pressed.connect(func() -> void: ask_text(_question.text))
	ask_row.add_child(ask)
	left.add_child(ask_row)
	row.add_child(left)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(UIStyle.label("Choose what to say", 17, UIStyle.MUTED))
	_choices = VBoxContainer.new()
	_choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_choices)
	_skip_button = UIStyle.button("Skip line  (Space)")
	_skip_button.name = "SkipLine"
	_skip_button.pressed.connect(skip_line)
	right.add_child(_skip_button)
	_end_button = UIStyle.button("End interview  (Esc)")
	_end_button.pressed.connect(close)
	right.add_child(_end_button)
	row.add_child(right)
