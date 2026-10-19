class_name CharacterShadowSelector
extends Node
## Gives an animated character a moving shadow from the one shadowed light nearest
## to her, and the cheap static rest-pose shadow (CharacterAnimationRig's proxies)
## from every other light.
##
## A light redraws its shadow map whenever a caster inside it moves, so letting
## every light see the skinned meshes costs a redraw of each light's whole shadow
## every frame. One light is enough for gestures to cast a shadow that moves with
## the arms. Skinned meshes sit on LIVE_LAYER and proxies on PROXY_LAYER; each
## shadowed light leaves one of the two out of its shadow_caster_mask. A light
## any character has chosen stays live, so two characters never get both shadows.

const LIVE_LAYER: int = 1 << 18
const PROXY_LAYER: int = 1 << 19
const LIVE_META: StringName = &"character_live_shadow"
const REFRESH_SECONDS: float = 1.0

var _model: Node3D
var _elapsed: float = REFRESH_SECONDS


func configure(model: Node3D) -> void:
	_model = model


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < REFRESH_SECONDS or _model == null or not _model.is_inside_tree():
		return
	_elapsed = 0.0
	refresh()


## Chooses the nearest shadowed light that reaches the model and sets every
## shadowed light's caster mask. Zones load and unload lights, so this repeats.
func refresh() -> Light3D:
	var lights: Array[Light3D] = []
	for node: Node in get_tree().root.find_children("*", "Light3D", true, false):
		var light: Light3D = node as Light3D
		if light.shadow_enabled and light.is_visible_in_tree():
			lights.append(light)
	var nearest: Light3D = null
	var best: float = INF
	var origin: Vector3 = _model.global_position + Vector3(0.0, 1.0, 0.0)
	for light: Light3D in lights:
		if light is DirectionalLight3D:
			continue
		var reach: float = _range(light)
		var distance: float = light.global_position.distance_to(origin)
		if distance < reach and distance < best:
			best = distance
			nearest = light
	if nearest != null:
		nearest.set_meta(LIVE_META, true)
	for light: Light3D in lights:
		if light.get_meta(LIVE_META, false):
			light.shadow_caster_mask = light.shadow_caster_mask & ~PROXY_LAYER | LIVE_LAYER
		else:
			light.shadow_caster_mask = light.shadow_caster_mask & ~LIVE_LAYER | PROXY_LAYER
	return nearest


static func _range(light: Light3D) -> float:
	if light is OmniLight3D:
		return (light as OmniLight3D).omni_range
	if light is SpotLight3D:
		return (light as SpotLight3D).spot_range
	return INF
