class_name InfoPanel
extends CanvasLayer
## InfoPanel: a modal information panel with optional authored story choices (terminal screens, documents,
## conversations, content error reports). Main opens and closes it; Esc or
## the Close button closes it. Body text supports BBCode.

const PANEL_ID: String = "info"

@onready var _title: Label = $Root/Panel/Margin/VBox/Title
@onready var _body: RichTextLabel = $Root/Panel/Margin/VBox/Body
@onready var _close_button: Button = $Root/Panel/Margin/VBox/CloseButton

var _options: VBoxContainer
var _interaction_id: String = ""

var is_open: bool = false
## When true the panel cannot be closed (fatal content errors).
var blocking: bool = false


func _ready() -> void:
	visible = false
	_options = VBoxContainer.new()
	_close_button.get_parent().add_child(_options)
	_close_button.get_parent().move_child(_options, _close_button.get_index())
	_close_button.pressed.connect(close)


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
	blocking = bool(data.get("blocking", false))
	_close_button.visible = not blocking
	visible = true
	is_open = true
	if not blocking:
		_close_button.grab_focus()


func close() -> void:
	if not is_open or blocking:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)


func _select_option(interaction_id: String, option_id: String) -> void:
	if not is_open or blocking or interaction_id != _interaction_id:
		return
	EventBus.story_option_selected.emit(interaction_id, option_id)
	# The handler may have replaced this panel with its response or changed chapter.
	if is_open and _interaction_id == interaction_id:
		close()
