class_name SpatialMap
extends Control
## Draws a FloorPlan snapshot: rooms named beside the plan with leader lines
## (rooms west of the plan's middle on the left, the rest on the right), the
## room you are in highlighted, the current objective as a gold star, people as named dots, doors (green open to
## you, amber locked) and EHR workstations, with a drawn legend.

const ROOM: Color = Color("2b3f4a")
const ROOM_HERE: Color = Color("3f6b62")
const ROOM_EDGE: Color = Color("8ba2a8")
const LABEL: Color = Color("dfe9e6")
const LABEL_HERE: Color = Color("9ff0d2")
const DOOR_OPEN: Color = Color("82d1a5")
const DOOR_LOCKED: Color = Color("edb164")
const STATION: Color = Color("91d7ee")
const PERSON: Color = Color("f2c7e0")
const OBJECTIVE: Color = Color("ffd36b")
const LABEL_SIZE: int = 17
const LABEL_GAP: float = 30.0
const LEGEND_HEIGHT: float = 34.0
const SIDE_MARGIN: float = 210.0

var plan: Dictionary = {}
var _bounds: Rect2 = Rect2(Vector2(-7, -20), Vector2(14, 21))
var _scale: float = 1.0
var _offset: Vector2


func show_plan(data: Dictionary) -> void:
	plan = data
	var first: bool = true
	for floor: Dictionary in plan.get("floors", []):
		_bounds = floor["rect"] if first else _bounds.merge(floor["rect"])
		first = false
	if not first:
		_bounds = _bounds.grow(0.6)
	queue_redraw()


func _point(position: Vector2) -> Vector2:
	return _offset + (position - _bounds.position) * _scale


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("142029"))
	if plan.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	var area: Rect2 = Rect2(Vector2(SIDE_MARGIN, 16), Vector2(size.x - SIDE_MARGIN * 2.0, size.y - 32 - LEGEND_HEIGHT))
	_scale = minf(area.size.x / maxf(_bounds.size.x, 1), area.size.y / maxf(_bounds.size.y, 1))
	_offset = area.position + (area.size - _bounds.size * _scale) / 2.0
	draw_string(font, Vector2(14, 28), "N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, LABEL)
	var here: String = str(plan.get("here", ""))
	var floors: Array = plan.get("floors", []).duplicate()
	# Largest first, so rooms that sit inside a corridor's bounds draw on top.
	floors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["rect"].get_area() > b["rect"].get_area())
	for floor: Dictionary in floors:
		var screen: Rect2 = Rect2(_point(floor["rect"].position), floor["rect"].size * _scale)
		draw_rect(screen, ROOM_HERE if floor["label"] == here else ROOM)
		draw_rect(screen, ROOM_EDGE, false, 1.0)
	_draw_labels(font, floors, here)
	for door: Dictionary in plan.get("doors", []):
		var p: Vector2 = _point(door["position"])
		var color: Color = DOOR_LOCKED if door["locked"] else DOOR_OPEN
		draw_circle(p, 5, color, not bool(door["open"]), 1.5 if door["open"] else -1.0)
		if door["locked"]:
			draw_line(p + Vector2(-5, -5), p + Vector2(5, 5), color, 2.0)
			draw_line(p + Vector2(-5, 5), p + Vector2(5, -5), color, 2.0)
	for station: Vector2 in plan.get("stations", []):
		var s: Vector2 = _point(station)
		draw_rect(Rect2(s - Vector2(6, 5), Vector2(12, 10)), STATION, false, 1.5)
		draw_string(font, s + Vector2(-4, 4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, STATION)
	for person: Dictionary in plan.get("people", []):
		var p: Vector2 = _point(person["position"])
		draw_circle(p, 5, PERSON)
		draw_string_outline(font, p + Vector2(8, 5), _short_name(person["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
		draw_string(font, p + Vector2(8, 5), _short_name(person["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PERSON)
	var objective: Dictionary = plan.get("objective", {})
	if objective.has("position"):
		_draw_star(_point(objective["position"]), 13.0, OBJECTIVE)
	var me: Vector2 = _point(plan["player"])
	var heading: Vector2 = Vector2(-sin(float(plan["yaw"])), -cos(float(plan["yaw"])))
	var side: Vector2 = Vector2(-heading.y, heading.x)
	draw_colored_polygon(PackedVector2Array([me + heading * 14, me - heading * 7 + side * 8, me - heading * 3, me - heading * 7 - side * 8]), Color.WHITE)
	_draw_legend(font)


## Room names beside the plan, kept at least LABEL_GAP apart, with a line to the room.
func _draw_labels(font: Font, floors: Array, here: String) -> void:
	var middle: float = _point(_bounds.get_center()).x
	for left: bool in [true, false]:
		var column: Array = []
		for floor: Dictionary in floors:
			var screen: Rect2 = Rect2(_point(floor["rect"].position), floor["rect"].size * _scale)
			if _is_corridor(screen):
				continue
			if (screen.get_center().x < middle - 1.0) == left:
				column.append({"label": floor["label"], "screen": screen})
		column.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["screen"].get_center().y < b["screen"].get_center().y)
		var next_y: float = 24.0
		for entry: Dictionary in column:
			var screen: Rect2 = entry["screen"]
			var y: float = maxf(screen.get_center().y, next_y)
			next_y = y + LABEL_GAP
			var is_here: bool = entry["label"] == here
			var color: Color = LABEL_HERE if is_here else LABEL
			var text: String = ("▶ " if is_here else "") + str(entry["label"])
			var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
			var anchor: Vector2 = Vector2(screen.position.x if left else screen.end.x, screen.get_center().y)
			var text_x: float = (SIDE_MARGIN - 16 - width) if left else (size.x - SIDE_MARGIN + 16)
			var line_end: Vector2 = Vector2((SIDE_MARGIN - 8) if left else (size.x - SIDE_MARGIN + 8), y - 5)
			draw_line(anchor, line_end, Color(color, 0.45), 1.0)
			draw_string(font, Vector2(maxf(text_x, 4.0), y), text, HORIZONTAL_ALIGNMENT_LEFT, SIDE_MARGIN - 20, LABEL_SIZE, color)


	# Long, thin rooms (corridors) are named inside, along their length.
	for floor: Dictionary in floors:
		var screen: Rect2 = Rect2(_point(floor["rect"].position), floor["rect"].size * _scale)
		if not _is_corridor(screen):
			continue
		var is_here: bool = floor["label"] == here
		var text: String = str(floor["label"])
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
		var color: Color = LABEL_HERE if is_here else LABEL
		if screen.size.y > screen.size.x:
			draw_set_transform(screen.get_center() + Vector2(6, width / 2.0), -PI / 2.0)
		else:
			draw_set_transform(screen.get_center() + Vector2(-width / 2.0, 6), 0.0)
		draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, Color(color, 0.85))
		draw_set_transform(Vector2.ZERO, 0.0)


static func _is_corridor(screen: Rect2) -> bool:
	return maxf(screen.size.x, screen.size.y) >= 2.5 * minf(screen.size.x, screen.size.y)


func _draw_legend(font: Font) -> void:
	var y: float = size.y - LEGEND_HEIGHT / 2.0
	var x: float = 16.0
	var items: Array = [["you", Color.WHITE], ["objective", OBJECTIVE], ["person", PERSON], ["open to you", DOOR_OPEN], ["locked", DOOR_LOCKED], ["EHR", STATION]]
	for item: Array in items:
		var color: Color = item[1]
		match item[0]:
			"you":
				draw_colored_polygon(PackedVector2Array([Vector2(x, y - 7), Vector2(x + 6, y + 6), Vector2(x, y + 3), Vector2(x - 6, y + 6)]), color)
			"locked":
				draw_circle(Vector2(x, y), 5, color)
				draw_line(Vector2(x - 5, y - 5), Vector2(x + 5, y + 5), color, 2.0)
				draw_line(Vector2(x - 5, y + 5), Vector2(x + 5, y - 5), color, 2.0)
			"objective":
				_draw_star(Vector2(x, y), 8.0, color)
			"EHR":
				draw_rect(Rect2(Vector2(x - 6, y - 5), Vector2(12, 10)), color, false, 1.5)
			_:
				draw_circle(Vector2(x, y), 5, color)
		draw_string(font, Vector2(x + 12, y + 5), item[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, LABEL)
		x += 26 + font.get_string_size(item[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 22


## A five-pointed star with a dark outline, so it reads over rooms and dots.
func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = []
	for i: int in 10:
		var r: float = radius if i % 2 == 0 else radius * 0.45
		var angle: float = -PI / 2.0 + i * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, Color.BLACK, 1.5)


## "Nurse Naomi Bennett" → "Naomi Bennett"; the dot label only needs the name.
static func _short_name(name: String) -> String:
	for title: String in ["Nurse ", "Dr ", "Dr. "]:
		if name.begins_with(title):
			return name.trim_prefix(title)
	return name
