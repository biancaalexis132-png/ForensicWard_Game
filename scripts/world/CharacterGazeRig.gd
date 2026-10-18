class_name CharacterGazeRig
extends Node
## Turns a character's eyes toward the target its acting cue names.
##
## Works on models built to the cast animation standard, which give each eye its
## own bone (eye_l, eye_r) under the head. Only the eye bones move: the head and
## body stay with their clips. Directives come from CharacterActingAdapter
## through the gaze adapter group:
##   player                   the active camera, when it is in front of her
##   workstation              the nearest EHR terminal, else down and to one side
##   workstation_then_player  the workstation briefly, then the player
## Anything else, or a target behind her, returns the eyes to rest. Small
## fixational movements keep a held gaze from looking frozen.

const EYE_BONES: Array[StringName] = [&"eye_l", &"eye_r"]
## Models follow the glTF convention: +Z is the character's front, +Y is up.
const MODEL_FORWARD: Vector3 = Vector3(0, 0, 1)
const MODEL_UP: Vector3 = Vector3(0, 1, 0)
const MAX_YAW_DEG: float = 26.0
const MAX_PITCH_DEG: float = 12.0
## Beyond this yaw the target is treated as behind her and the eyes rest.
const IGNORE_YAW_DEG: float = 60.0
const PLAYER_RANGE: float = 7.0
const WORKSTATION_RANGE: float = 4.0
const WORKSTATION_FIRST_SECONDS: float = 1.2
## Fallback when no terminal is near: down and toward her right.
const WORKSTATION_FALLBACK_DEG: Vector2 = Vector2(-18.0, -11.0)
## Saccades are fast; this is the exponential rate toward the target angle.
const EYE_RATE: float = 18.0
const MICRO_INTERVAL: Vector2 = Vector2(0.5, 1.8)
const MICRO_DEG: float = 0.7

var _skeleton: Skeleton3D = null
var _eyes: Array[Dictionary] = []
var _directive: StringName = &"player"
var _directive_time: float = 0.0
var _workstation: Node3D = null
var _workstation_searched: bool = false
var _angles: Vector2 = Vector2.ZERO  # x = yaw, y = pitch, degrees
var _micro: Vector2 = Vector2.ZERO
var _until_micro: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Finds the eye bones. Returns false if the model has none.
func configure(model: Node3D) -> bool:
	_eyes.clear()
	for node: Node in model.find_children("*", "Skeleton3D", true, false):
		var skeleton: Skeleton3D = node as Skeleton3D
		for bone_name: StringName in EYE_BONES:
			var bone: int = skeleton.find_bone(bone_name)
			if bone < 0:
				continue
			_skeleton = skeleton
			# The eye's rest frame in model space gives the forward and up axes in
			# bone space, so no bone-roll convention is assumed.
			var rest: Transform3D = skeleton.get_bone_global_rest(bone)
			var to_bone: Basis = rest.basis.orthonormalized().inverse()
			var forward: Vector3 = (to_bone * MODEL_FORWARD).normalized()
			var up: Vector3 = (to_bone * MODEL_UP).normalized()
			_eyes.append({
				"bone": bone,
				"rest_rotation": skeleton.get_bone_rest(bone).basis.get_rotation_quaternion(),
				"forward": forward,
				"up": up,
				"side": up.cross(forward).normalized(),
			})
	return has_eyes()


func has_eyes() -> bool:
	return not _eyes.is_empty()


func _ready() -> void:
	add_to_group(CharacterActingAdapter.GAZE_ADAPTER_GROUP)
	_rng.randomize()


func set_gaze_directive(directive: StringName) -> void:
	_directive = directive
	_directive_time = 0.0


func get_gaze_directive() -> StringName:
	return _directive


## Current eye angles in degrees (x = yaw toward her left, y = pitch up).
func get_eye_angles() -> Vector2:
	return _angles + _micro


func _process(delta: float) -> void:
	if not has_eyes() or not is_instance_valid(_skeleton):
		return
	_directive_time += delta
	var target: Vector2 = _target_angles()
	_angles = _angles.lerp(target, 1.0 - exp(-EYE_RATE * delta))
	_until_micro -= delta
	if _until_micro <= 0.0:
		_until_micro = _rng.randf_range(MICRO_INTERVAL.x, MICRO_INTERVAL.y)
		_micro = Vector2(_rng.randf_range(-MICRO_DEG, MICRO_DEG), _rng.randf_range(-MICRO_DEG, MICRO_DEG) * 0.6)
	_apply(_angles + _micro)


func _target_angles() -> Vector2:
	var directive: StringName = _directive
	if directive == &"workstation_then_player":
		directive = &"workstation" if _directive_time < WORKSTATION_FIRST_SECONDS else &"player"
	match directive:
		&"player":
			var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
			if camera != null:
				return _angles_to(camera.global_position, PLAYER_RANGE)
		&"workstation":
			var terminal: Node3D = _find_workstation()
			if terminal != null:
				return _angles_to(terminal.global_position, WORKSTATION_RANGE)
			return WORKSTATION_FALLBACK_DEG
	return Vector2.ZERO


## Yaw and pitch, in degrees, from the eyes' midpoint to a world point, clamped
## to what eyes alone can do. Out of range or behind her gives rest.
func _angles_to(point: Vector3, max_range: float) -> Vector2:
	var eye: Dictionary = _eyes[0]
	var frame: Transform3D = _eye_rest_frame(eye)
	var middle: Vector3 = frame.origin
	if _eyes.size() > 1:
		middle = (middle + _eye_rest_frame(_eyes[1]).origin) * 0.5
	var offset: Vector3 = point - middle
	if offset.length() > max_range or offset.length() < 0.05:
		return Vector2.ZERO
	var local: Vector3 = frame.basis.orthonormalized().inverse() * offset
	var forward: Vector3 = eye["forward"]
	var up: Vector3 = eye["up"]
	var side: Vector3 = eye["side"]
	var yaw: float = rad_to_deg(atan2(local.dot(side), local.dot(forward)))
	if absf(yaw) > IGNORE_YAW_DEG:
		return Vector2.ZERO
	var level: float = Vector2(local.dot(side), local.dot(forward)).length()
	var pitch: float = rad_to_deg(atan2(local.dot(up), level))
	return Vector2(clampf(yaw, -MAX_YAW_DEG, MAX_YAW_DEG), clampf(pitch, -MAX_PITCH_DEG, MAX_PITCH_DEG))


## The eye's rest frame carried by the animated head, in world space.
func _eye_rest_frame(eye: Dictionary) -> Transform3D:
	var bone: int = eye["bone"]
	var parent: int = _skeleton.get_bone_parent(bone)
	var parent_pose: Transform3D = _skeleton.get_bone_global_pose(parent) if parent >= 0 else Transform3D()
	return _skeleton.global_transform * parent_pose * _skeleton.get_bone_rest(bone)


func _apply(angles: Vector2) -> void:
	for eye: Dictionary in _eyes:
		var forward: Vector3 = eye["forward"]
		var up: Vector3 = eye["up"]
		# Rotating about up turns forward toward side (her left); rotating about
		# forward x up lifts forward toward up.
		var turn: Quaternion = Quaternion(up, deg_to_rad(angles.x)) * Quaternion(forward.cross(up).normalized(), deg_to_rad(angles.y))
		var rest_rotation: Quaternion = eye["rest_rotation"]
		_skeleton.set_bone_pose_rotation(eye["bone"], rest_rotation * turn)


func _find_workstation() -> Node3D:
	if _workstation_searched and (_workstation == null or is_instance_valid(_workstation)):
		return _workstation
	_workstation_searched = true
	_workstation = null
	if not is_inside_tree() or not has_eyes():
		return null
	var origin: Vector3 = _skeleton.global_position
	var best: float = WORKSTATION_RANGE
	for node: Node in get_tree().root.find_children("*", "Node", true, false):
		var interactable: ImportedInteractable = node as ImportedInteractable
		if interactable == null or interactable.kind != "ehr_terminal":
			continue
		var prop: Node3D = interactable.get_parent() as Node3D
		if prop != null and prop.global_position.distance_to(origin) < best:
			best = prop.global_position.distance_to(origin)
			_workstation = prop
	return _workstation
