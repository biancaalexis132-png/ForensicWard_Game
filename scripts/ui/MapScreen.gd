class_name MapScreen
extends CanvasLayer
## Simple in-game floor map/directory

const PANEL_ID: String = "map"

var is_open: bool = false
var _elapsed: float = 0.0

@onready var _close_button: Button = $Root/Panel/Margin/VBox/Close
@onready var _map: SpatialMap = $Root/Panel/Margin/VBox/Map
@onready var _text: RichTextLabel = $Root/Panel/Margin/VBox/Text

func _ready() -> void:
	layer = 9
	visible = false
	if has_node("Root/Panel/Margin/VBox/Close"):
		_close_button.pressed.connect(close)


func open(_data: Dictionary = {}) -> void:
	visible = true
	is_open = true
	_refresh_map()
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/floor_directory.json"))
	if document is Dictionary and document.get("body") is String:
		_text.text = "White: you / heading · Amber: locked door · Green: accessible door · E: EHR\nCurrent floor only. Closed outline: open door. North is up."
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


func _process(delta: float) -> void:
	_elapsed += delta
	if is_open and _elapsed >= 0.1:
		_elapsed = 0.0
		_refresh_map()


func _refresh_map() -> void:
	var main: Node = get_parent()
	if main == null or not main.has_node("ZoneDirector"):
		return
	var plan: Dictionary = FloorPlan.snapshot(main.get_node("World"), main.get_node("Player"), main.get_node("ZoneDirector"))
	_map.show_plan(plan)
	$Root/Panel/Margin/VBox/Title.text = "%s — %s" % [plan["title"], plan["level"]]
