class_name SpatialMap
extends Control

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
		_bounds = _bounds.grow(1.0)
	queue_redraw()

func _point(position: Vector2) -> Vector2:
	return _offset + (position - _bounds.position) * _scale

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("142029"))
	if plan.is_empty():
		return
	_scale = minf((size.x - 32) / maxf(_bounds.size.x, 1), (size.y - 32) / maxf(_bounds.size.y, 1))
	_offset = (size - _bounds.size * _scale) / 2
	var font: Font = ThemeDB.fallback_font
	for floor: Dictionary in plan.get("floors", []):
		var rect: Rect2 = floor["rect"]
		var screen: Rect2 = Rect2(_point(rect.position), rect.size * _scale)
		draw_rect(screen, Color("304652"))
		draw_rect(screen, Color("8ba2a8"), false, 1.0)
		draw_string(font, screen.position + Vector2(3, 14), str(floor["label"]), HORIZONTAL_ALIGNMENT_LEFT, screen.size.x - 6, 11)
	for door: Dictionary in plan.get("doors", []):
		var p: Vector2 = _point(door["position"])
		var color: Color = Color("edb164") if door["locked"] else Color("82d1a5")
		draw_circle(p, 4, color, not bool(door["open"]), 1.5)
	for station: Vector2 in plan.get("stations", []):
		draw_string(font, _point(station) + Vector2(-4, 4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("91d7ee"))
	var here: Vector2 = _point(plan["player"])
	var heading: Vector2 = Vector2(-sin(float(plan["yaw"])), -cos(float(plan["yaw"])))
	draw_circle(here, 5, Color.WHITE)
	draw_line(here, here + heading * 18, Color.WHITE, 3.0)
	draw_string(font, Vector2(12, 18), "N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
