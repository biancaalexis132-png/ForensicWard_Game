class_name CharacterFaceRig
extends Node
## Blinking and speech mouth movement for models with the cast face morph targets.
##
## Expressions are set by CharacterActingAdapter directly by blend-shape name;
## this node only adds what a cue cannot: natural, irregular blinks and a light
## jaw movement while the character speaks. It joins the face adapter group so
## the acting adapter tells it when speech starts and stops.

const BLINK_SHAPE: StringName = &"blink"
const MOUTH_SHAPE: StringName = &"mouth_open"
const BLINK_SECONDS: float = 0.16
const BLINK_INTERVAL_MIN: float = 2.2
const BLINK_INTERVAL_MAX: float = 5.5
const DOUBLE_BLINK_CHANCE: float = 0.15
const MOUTH_MAX: float = 0.85

var _targets: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _until_blink: float = 0.0
var _blink_time: float = -1.0
var _speaking: bool = false
var _mouth: float = 0.0
var _mouth_phase: float = 0.0


func configure(model: Node3D) -> void:
	_targets.clear()
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue  # A still shadow proxy: blinking it would redraw shadow maps.
		var blink: int = mesh.find_blend_shape_by_name(BLINK_SHAPE)
		var mouth: int = mesh.find_blend_shape_by_name(MOUTH_SHAPE)
		if blink >= 0 or mouth >= 0:
			_targets.append({"mesh": mesh, "blink": blink, "mouth": mouth})


func _ready() -> void:
	add_to_group(CharacterActingAdapter.FACE_ADAPTER_GROUP)
	_rng.randomize()
	_until_blink = _rng.randf_range(0.5, BLINK_INTERVAL_MAX)


func has_blink() -> bool:
	return _targets.any(func(t: Dictionary) -> bool: return int(t["blink"]) >= 0)


func set_speaking(speaking: bool) -> void:
	_speaking = speaking


func set_expression(_expression: StringName) -> void:
	pass  # The acting adapter drives expression blend shapes itself.


## Starts a blink now (also used by tests and review captures).
func blink() -> void:
	_blink_time = 0.0


func _process(delta: float) -> void:
	_update_blink(delta)
	_update_mouth(delta)


func _update_blink(delta: float) -> void:
	var value: float = 0.0
	if _blink_time >= 0.0:
		_blink_time += delta
		var t: float = _blink_time / BLINK_SECONDS
		# Fast close, slightly slower open.
		value = sin(clampf(t, 0.0, 1.0) * PI) if t < 0.5 else 1.0 - smoothstep(0.5, 1.0, t)
		if t >= 1.0:
			_blink_time = -1.0
			value = 0.0
	else:
		_until_blink -= delta
		if _until_blink <= 0.0:
			blink()
			var interval: float = _rng.randf_range(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)
			_until_blink = 0.25 if _rng.randf() < DOUBLE_BLINK_CHANCE else interval
	_set_shape("blink", value)


func _update_mouth(delta: float) -> void:
	var target: float = 0.0
	if _speaking:
		_mouth_phase += delta
		# Syllable-rate movement without lip sync data: two mixed rhythms.
		var syllables: float = 0.5 + 0.5 * sin(_mouth_phase * 13.0) * sin(_mouth_phase * 3.1 + 0.7)
		target = MOUTH_MAX * clampf(syllables, 0.0, 1.0)
	_mouth = move_toward(_mouth, target, delta * 6.0)
	_set_shape("mouth", _mouth)


func _set_shape(key: String, value: float) -> void:
	for target: Dictionary in _targets:
		var index: int = int(target[key])
		var mesh: MeshInstance3D = target["mesh"]
		if index >= 0 and is_instance_valid(mesh):
			mesh.set_blend_shape_value(index, value)
