class_name InfoPanel
extends CanvasLayer
## InfoPanel: a modal read-only panel (terminal screens, documents,
## conversations, content error reports). Main opens and closes it; Esc or
## the Close button closes it. Body text supports BBCode.

const PANEL_ID: String = "info"

@onready var _title: Label = $Root/Panel/Margin/VBox/Title
@onready var _body: RichTextLabel = $Root/Panel/Margin/VBox/Body
@onready var _close_button: Button = $Root/Panel/Margin/VBox/CloseButton

var is_open: bool = false
## When true the panel cannot be closed (fatal content errors).
var blocking: bool = false


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)


func open(data: Dictionary) -> void:
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
