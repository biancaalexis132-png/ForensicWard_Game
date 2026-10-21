class_name InfoPanel
extends CanvasLayer
## InfoPanel: a modal information panel with optional authored story choices (terminal screens, documents,
## conversations, content error reports). Main opens and closes it; Esc or
## the Close button closes it. Body text supports BBCode.
##
## Voice: when the body has recorded lines (VoiceScript finds them by speaker
## and text), they play in order with subtitles: staff in their own voices,
## descriptive text by the narrator. `voice_speaker` names the default voice
## (a staff member's id for their own lines); otherwise the narrator. Space or
## Enter skips a line; closing the panel stops its voice. The text stays on
## screen either way, so nothing depends on audio. `"voiced": false` shows the
## text without playing it (a line the player has already heard).
##
## Documents: when data carries a `clue_id` whose paper image exists
## (DocumentViewer.image_path), the page is shown at the left and the text
## panel moves to the right. Without an image the panel shows the text alone,
## as before. The image is loaded on open and released on close.

const PANEL_ID: String = "info"

@onready var _title: Label = $Root/Panel/Margin/VBox/Title
@onready var _body: RichTextLabel = $Root/Panel/Margin/VBox/Body
@onready var _close_button: Button = $Root/Panel/Margin/VBox/CloseButton
@onready var _panel: PanelContainer = $Root/Panel

var _options: VBoxContainer
var _interaction_id: String = ""
var _conversation: ConversationPlayer
var _document: DocumentViewer
## The text panel's authored anchors (left, top, right, bottom), restored
## when no document image is shown.
var _text_anchors: Array[float] = []

var is_open: bool = false
## When true the panel cannot be closed (fatal content errors).
var blocking: bool = false


func _ready() -> void:
	visible = false
	_options = VBoxContainer.new()
	_close_button.get_parent().add_child(_options)
	_close_button.get_parent().move_child(_options, _close_button.get_index())
	_close_button.pressed.connect(close)
	_conversation = ConversationPlayer.new()
	_conversation.name = "Conversation"
	# The panel already shows its text: unvoiced paragraphs need no extra subtitle.
	_conversation.subtitle_fallback = false
	add_child(_conversation)
	_text_anchors = [_panel.anchor_left, _panel.anchor_top, _panel.anchor_right, _panel.anchor_bottom]
	_document = DocumentViewer.new()
	_document.anchor_left = 0.04
	_document.anchor_top = 0.04
	_document.anchor_right = 0.52
	_document.anchor_bottom = 0.96
	_document.visible = false
	$Root.add_child(_document)


## The voiced segments of a panel's body, for its default speaker.
static func voice_segments(data: Dictionary) -> Array[Dictionary]:
	var speaker: String = str(data.get("voice_speaker", VoiceScript.NARRATOR))
	return VoiceScript.segments(str(data.get("body", "")), speaker)


func is_speaking() -> bool:
	return _conversation.is_playing


func skip_line() -> void:
	_conversation.skip_line()


func _unhandled_input(event: InputEvent) -> void:
	if is_open and _conversation.is_playing and event.is_action_pressed("ui_accept"):
		skip_line()
		get_viewport().set_input_as_handled()


func open(data: Dictionary) -> void:
	for child: Node in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	_interaction_id = str(data.get("interaction_id", ""))
	for option: Dictionary in data.get("options", []):
		var button: Button = Button.new()
		button.text = option["label"]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_select_option.bind(_interaction_id, str(option["id"])))
		_options.add_child(button)
	_title.text = str(data.get("title", ""))
	_body.text = str(data.get("body", ""))
	_body.scroll_to_line(0)
	_show_document(data)
	blocking = bool(data.get("blocking", false))
	_close_button.visible = not blocking
	visible = true
	is_open = true
	if not blocking:
		_close_button.grab_focus()
	var parts: Array[Dictionary] = voice_segments(data)
	if bool(data.get("voiced", true)) and VoiceScript.has_voice(parts):
		_conversation.play(parts)
	else:
		_conversation.cancel()


func close() -> void:
	if not is_open or blocking:
		return
	_conversation.cancel()
	_document.clear()
	_document.visible = false
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)


## The document viewer beside the text (tests read it).
func get_document_viewer() -> DocumentViewer:
	return _document


func is_showing_document() -> bool:
	return _document.visible and _document.has_image()


## Shows the clue's paper image beside the text when it has one.
func _show_document(data: Dictionary) -> void:
	var clue_id: String = str(data.get("clue_id", ""))
	var shown: bool = not DocumentViewer.image_path(clue_id).is_empty() \
			and _document.show_document(clue_id, str(data.get("title", "")), str(data.get("body", "")))
	if not shown:
		_document.clear()
	_document.visible = shown
	var anchors: Array[float] = _text_anchors
	if shown:
		anchors = [0.55, 0.1, 0.96, 0.9]
	_panel.anchor_left = anchors[0]
	_panel.anchor_top = anchors[1]
	_panel.anchor_right = anchors[2]
	_panel.anchor_bottom = anchors[3]


func _select_option(interaction_id: String, option_id: String) -> void:
	if not is_open or blocking or interaction_id != _interaction_id:
		return
	for button: Node in _options.get_children():
		(button as Button).disabled = true  # One selection per panel: flags advance once.
	EventBus.story_option_selected.emit(interaction_id, option_id)
	# The handler may have replaced this panel with its response or changed chapter.
	if is_open and _interaction_id == interaction_id:
		close()
