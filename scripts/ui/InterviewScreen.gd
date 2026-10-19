class_name InterviewScreen
extends CanvasLayer
## InterviewScreen: the cinematic patient interview (GDD §9).
##
## Cuts between the interview-room cameras authored in Blender (CAM_IR_*,
## imported as Camera3D nodes) and restores the player's camera on close.
## The player picks a listed topic or types a question; DialogueManager
## matches typed text to authored intents and answers with a clarification
## or a polite fallback otherwise. Findings a question records appear as a
## notification and in the EHR. Every line is shown as text: nothing
## depends on audio.
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

var is_open: bool = false
var patient_id: String = ""
var current_shot: String = ""

var _world: Node = null
var _previous_camera: Camera3D = null
var _name_label: Label
var _transcript: RichTextLabel
var _choices: VBoxContainer
var _question: LineEdit
var _end_button: Button


func _ready() -> void:
	layer = 8
	_build()
	visible = false
	EventBus.dialogue_line_added.connect(_on_line_added)


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
	_question.grab_focus()


func close() -> void:
	if not is_open:
		return
	DialogueManager.end_dialogue()
	visible = false
	is_open = false
	if is_instance_valid(_previous_camera):
		_previous_camera.make_current()
	_set_name_tag_visible(true)
	current_shot = ""
	EventBus.ui_panel_closed.emit(PANEL_ID)


# --- Actions (buttons call these; so do tests) -----------------------------------

func ask_choice(choice_id: String) -> void:
	DialogueManager.select_choice(choice_id)
	_after_answer("matched")


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
	var ask_row: HBoxContainer = HBoxContainer.new()
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
	right.add_child(UIStyle.label("Topics", 17, UIStyle.MUTED))
	_choices = VBoxContainer.new()
	_choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_choices)
	_end_button = UIStyle.button("End interview  (Esc)")
	_end_button.pressed.connect(close)
	right.add_child(_end_button)
	row.add_child(right)
