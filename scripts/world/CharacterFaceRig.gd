class_name CharacterFaceRig
extends Node
## Blinking and speech mouth movement for models with the cast face morph targets.
##
## Expressions are set by CharacterActingAdapter directly by blend-shape name;
## Adds blinks, text-based approximate dialogue visemes, and a jaw fallback.
## Existing audio events own line completion; acting cues can still gate speech.

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
var _character_id: String = ""
var _line_id: String = ""
var _line_seconds: float = 0.0
var _line_duration: float = 0.0
var _viseme_track: Array[Dictionary] = []


func configure(model: Node3D) -> void:
	_targets.clear()
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		if mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue  # A still shadow proxy: blinking it would redraw shadow maps.
		var blink: int = mesh.find_blend_shape_by_name(BLINK_SHAPE)
		var mouth: int = mesh.find_blend_shape_by_name(MOUTH_SHAPE)
		var visemes: Dictionary = {}
		for index: int in mesh.mesh.get_blend_shape_count():
			var shape: StringName = mesh.mesh.get_blend_shape_name(index)
			if String(shape).begins_with(DialogueVisemeTrack.PREFIX):
				visemes[shape] = index
		if blink >= 0 or mouth >= 0 or not visemes.is_empty():
			_targets.append({"mesh": mesh, "blink": blink, "mouth": mouth, "visemes": visemes})


func _ready() -> void:
	add_to_group(CharacterActingAdapter.FACE_ADAPTER_GROUP)
	_rng.randomize()
	_until_blink = _rng.randf_range(0.5, BLINK_INTERVAL_MAX)
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor is WardCharacter:
			_character_id = (ancestor as WardCharacter).character_id
			break
		ancestor = ancestor.get_parent()
	EventBus.subtitle_shown.connect(_on_dialogue_started)
	EventBus.dialogue_line_finished.connect(_on_dialogue_finished)
	EventBus.game_loaded.connect(_on_game_loaded)


func has_blink() -> bool:
	return _targets.any(func(t: Dictionary) -> bool: return int(t["blink"]) >= 0)


func set_speaking(speaking: bool) -> void:
	_speaking = speaking
	if not speaking:
		_clear_mouth()


## Existing audio events supply authored text and actual clip/reading duration.
## This remains a restrained approximation until real phoneme timing exists.
func _on_dialogue_started(line_id: String, _speaker: String, text: String, seconds: float) -> void:
	var line: Dictionary = AudioDirector.get_line(line_id)
	if _character_id.is_empty() or str(line.get("speaker", "")) != _character_id:
		return
	_clear_mouth()
	_line_id = line_id
	_line_seconds = 0.0
	_line_duration = seconds
	_mouth_phase = 0.0
	_viseme_track = DialogueVisemeTrack.build(text, seconds)
	_speaking = not _viseme_track.is_empty()


func _on_dialogue_finished(line_id: String, _completed: bool) -> void:
	if line_id == _line_id:
		_stop_dialogue()


func _on_game_loaded(_slot: int) -> void:
	_stop_dialogue()


func _stop_dialogue() -> void:
	_line_id = ""
	_line_seconds = 0.0
	_line_duration = 0.0
	_viseme_track.clear()
	_speaking = false
	_clear_mouth()


func _clear_mouth() -> void:
	_mouth = 0.0
	_set_shape("mouth", 0.0)
	for target: Dictionary in _targets:
		var mesh: MeshInstance3D = target["mesh"]
		if not is_instance_valid(mesh):
			continue
		for index: int in (target["visemes"] as Dictionary).values():
			mesh.set_blend_shape_value(index, 0.0)


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
	if not _line_id.is_empty():
		if _speaking:
			_line_seconds += delta
			if _line_seconds >= _line_duration:
				_stop_dialogue()
				return
			_apply_viseme(DialogueVisemeTrack.sample(_viseme_track, _line_seconds), delta)
		return
	var target: float = 0.0
	if _speaking:
		_mouth_phase += delta
		# Syllable-rate movement without lip sync data: two mixed rhythms.
		var syllables: float = 0.5 + 0.5 * sin(_mouth_phase * 13.0) * sin(_mouth_phase * 3.1 + 0.7)
		target = MOUTH_MAX * clampf(syllables, 0.0, 1.0)
	_mouth = move_toward(_mouth, target, delta * 6.0)
	_set_shape("mouth", _mouth)


func _apply_viseme(sample: Dictionary, delta: float) -> void:
	var shape: StringName = sample["shape"]
	var weight: float = float(sample["weight"]) if shape != DialogueVisemeTrack.SILENCE else 0.0
	for target: Dictionary in _targets:
		var mesh: MeshInstance3D = target["mesh"]
		if not is_instance_valid(mesh):
			continue
		var visemes: Dictionary = target["visemes"]
		for name: StringName in visemes:
			var index: int = int(visemes[name])
			var current: float = mesh.get_blend_shape_value(index)
			var next: float = move_toward(current, weight if name == shape else 0.0, delta * 12.0)
			if not is_equal_approx(current, next):
				mesh.set_blend_shape_value(index, next)
		var mouth: int = int(target["mouth"])
		if mouth >= 0:
			# No double jaw movement; missing visemes fall back per mesh.
			mesh.set_blend_shape_value(mouth, weight if not visemes.has(shape) else 0.0)


func _set_shape(key: String, value: float) -> void:
	for target: Dictionary in _targets:
		var index: int = int(target[key])
		var mesh: MeshInstance3D = target["mesh"]
		if index >= 0 and is_instance_valid(mesh):
			mesh.set_blend_shape_value(index, value)
