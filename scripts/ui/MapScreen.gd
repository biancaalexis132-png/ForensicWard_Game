class_name MapScreen
extends CanvasLayer
## Simple in-game floor map/directory

const PANEL_ID: String = "map"

var is_open: bool = false

@onready var _close_button: Button = $Root/Panel/Margin/VBox/Close
@onready var _text: RichTextLabel = $Root/Panel/Margin/VBox/Text

func _ready() -> void:
	layer = 9
	visible = false
	if has_node("Root/Panel/Margin/VBox/Close"):
		_close_button.pressed.connect(close)


func open(_data: Dictionary = {}) -> void:
	visible = true
	is_open = true
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/floor_directory.json"))
	if document is Dictionary and document.get("body") is String:
		_text.text = document["body"]
	else:
		push_error("Floor directory requires a JSON object with a string body")
		_text.text = "Directory unavailable."
	if has_node("Root/Panel/Margin/VBox/Close"):
		_close_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)
