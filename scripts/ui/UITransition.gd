class_name UITransition
extends RefCounted
## UITransition: short fades so panels, menus and subtitles ease in instead of
## popping. Presentation only: visibility, focus and input change at once, as
## before, so nothing waits on a fade. With reduce_motion on, nothing fades.

const PANEL_SECONDS: float = 0.16
const TEXT_SECONDS: float = 0.12
const META_TWEEN: String = "ui_transition_tween"


## Fades `target` from transparent to opaque. Restarts cleanly if called again.
static func fade_in(target: CanvasItem, seconds: float = PANEL_SECONDS) -> void:
	if target == null or not target.is_inside_tree():
		return
	var previous: Variant = target.get_meta(META_TWEEN) if target.has_meta(META_TWEEN) else null
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	if Settings.get_value("reduce_motion"):
		target.modulate.a = 1.0
		return
	target.modulate.a = 0.0
	var tween: Tween = target.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target, "modulate:a", 1.0, seconds)
	target.set_meta(META_TWEEN, tween)


## Fades in a CanvasLayer screen's "Root" control (every panel has one).
static func fade_in_screen(layer: Node, seconds: float = PANEL_SECONDS) -> void:
	if layer == null:
		return
	fade_in(layer.get_node_or_null("Root") as CanvasItem, seconds)
