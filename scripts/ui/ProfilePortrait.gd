class_name ProfilePortrait
extends Control
## Small procedural portrait: no extra 3D world, skinning, texture or camera allocation.
var draft: Dictionary = {}
func _draw() -> void:
	var catalog: Dictionary = ProtagonistProfile.options
	var skin: Color = Color(str(catalog.get("skin_tones", {}).get(draft.get("skin_tone"), "#bd8863")))
	var hair: Color = Color(str(catalog.get("hair_colors", {}).get(draft.get("hair_color"), "#60432e")))
	var outfit: Color = Color(str(catalog.get("outfits", {}).get(draft.get("outfit"), "#263d56")))
	var center: Vector2 = size / 2
	draw_circle(center + Vector2(0, 55), 65, outfit)
	if draft.get("hair_style") == "long":
		draw_rect(Rect2(center + Vector2(-46, -65), Vector2(92, 120)), hair)
	draw_circle(center + Vector2(0, -25), 40, skin)
	if draft.get("hair_style") != "none":
		draw_arc(center + Vector2(0, -27), 40, PI, TAU, 32, hair, 17)
	draw_circle(center + Vector2(-13, -25), 3, Color("34302d"))
	draw_circle(center + Vector2(13, -25), 3, Color("34302d"))
	draw_line(center + Vector2(-10, -7), center + Vector2(10, -7), skin.darkened(0.35), 2)
