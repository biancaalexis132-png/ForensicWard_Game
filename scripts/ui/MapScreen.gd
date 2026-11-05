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
	var plan: Dictionary = FloorPlan.snapshot(main.get_node("World"), main.get_node("Player"), main.get_node("ZoneDirector"),
			get_tree().get_first_node_in_group(ChapterDirector.GROUP) as ChapterDirector)
	_map.show_plan(plan)
	$Root/Panel/Margin/VBox/Title.text = "%s — %s" % [plan["title"], plan["level"]]
	_text.text = describe(plan)


## The plan in words: where you are and who is on this floor (also read by tests).
static func describe(plan: Dictionary) -> String:
	var lines: PackedStringArray = []
	var here: String = str(plan.get("here", ""))
	lines.append("You are in: [b]%s[/b]" % (here if not here.is_empty() else plan.get("title", "")))
	var people: PackedStringArray = []
	for person: Dictionary in plan.get("people", []):
		people.append("%s (%s)" % [person["name"], person["room"]])
	if not people.is_empty():
		lines.append("On this floor: " + ", ".join(people))
	var objective: Dictionary = plan.get("objective", {})
	if objective.has("position"):
		var room: String = str(objective.get("room", ""))
		lines.append("[color=#ffd36b]★ Objective:[/color] %s%s" % [objective["label"], (" (%s)" % room) if not room.is_empty() else ""])
	elif objective.has("elsewhere"):
		lines.append("[color=#ffd36b]★ Objective:[/color] %s — not on this floor" % objective["label"])
	elif objective.has("here"):
		lines.append("[color=#ffd36b]★ Objective:[/color] %s — this floor" % objective["label"])
	lines.append("[color=#9aa8a6]Current floor only. North is up. M or Esc closes the map.[/color]")
	return "\n".join(lines)
