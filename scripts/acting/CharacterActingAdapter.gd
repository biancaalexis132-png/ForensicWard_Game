class_name CharacterActingAdapter
extends Node
## Applies optional presentation capabilities without requiring a particular rig.

signal cue_applied(stage: String, cue: Dictionary, actor_speaking: bool)

const BODY_ADAPTER_GROUP: StringName = &"character_acting_adapter"
const FACE_ADAPTER_GROUP: StringName = &"character_face_adapter"
const GAZE_ADAPTER_GROUP: StringName = &"character_gaze_adapter"
const GESTURE_ADAPTER_GROUP: StringName = &"character_gesture_adapter"
const GESTURE_PLAYER_NAME: StringName = &"GestureAnimationPlayer"
const ANIMATION_BLEND_SECONDS: float = 0.3
const FALLBACK_BODY_CLIP: String = "idle_neutral"

var _actor_root: Node3D
var _active_face_shapes: Dictionary = {}
var _active_body_player: AnimationPlayer
var _active_body_animation: StringName = &""
var _active_gesture_player: AnimationPlayer
var _active_gesture_animation: StringName = &""
var _last_cue: Dictionary = {}
var _last_stage: String = ""
var _actor_speaking: bool = false


func configure(actor_root: Node3D) -> void:
	_actor_root = actor_root


func apply_cue(stage: String, cue: Dictionary, actor_speaking: bool) -> void:
	_last_cue = cue.duplicate(true)
	_last_stage = stage
	_actor_speaking = actor_speaking
	_apply_body(str(cue.get("body", "")))
	_apply_face(str(cue.get("face", "")))
	_apply_gaze(str(cue.get("gaze", "")))
	_apply_gesture(str(cue.get("gesture", "")))
	_dispatch_full_cue(stage, cue, actor_speaking)
	cue_applied.emit(stage, cue.duplicate(true), actor_speaking)


func reset_to_safe_idle(fallback: Dictionary, reason: String) -> void:
	_reset_face_shapes()
	apply_cue(reason, fallback, false)


func get_last_cue() -> Dictionary:
	return _last_cue.duplicate(true)


func get_last_stage() -> String:
	return _last_stage


func is_actor_speaking() -> bool:
	return _actor_speaking


func has_capability(capability: String, semantic_name: String) -> bool:
	if _actor_root == null:
		return false
	match capability:
		"body":
			return _find_animation_player(semantic_name, false) != null
		"gesture":
			return _find_animation_player(semantic_name, true) != null or \
					_has_group_method(GESTURE_ADAPTER_GROUP, "play_gesture")
		"face":
			return _find_blend_shape(semantic_name) != null or \
					_has_group_method(FACE_ADAPTER_GROUP, "set_expression")
		"gaze":
			return _has_group_method(GAZE_ADAPTER_GROUP, "set_gaze_directive")
		_:
			return false


func _apply_body(semantic_name: String) -> void:
	if semantic_name.is_empty():
		return
	var player: AnimationPlayer = null
	# The clip actually played: the requested one, or idle_neutral when the rig lacks it.
	var clip_name: String = semantic_name
	if semantic_name != "none":
		player = _find_animation_player(semantic_name, false)
		if player == null:
			clip_name = FALLBACK_BODY_CLIP
			player = _find_animation_player(clip_name, false)
	if player == null:
		_stop_body_animation()
	if semantic_name == "none" or player == null:
		return
	if player != _active_body_player:
		_stop_body_animation()
	if player.current_animation != clip_name:
		player.play(clip_name, ANIMATION_BLEND_SECONDS)
	_active_body_player = player
	_active_body_animation = StringName(clip_name)


func _apply_face(semantic_name: String) -> void:
	_reset_face_shapes()
	if semantic_name.is_empty() or semantic_name == "none":
		return
	for mesh: MeshInstance3D in _face_meshes():
		var shape_index: int = _blend_shape_index(mesh, semantic_name)
		if shape_index < 0:
			continue
		mesh.set_blend_shape_value(shape_index, 1.0)
		_active_face_shapes[mesh] = shape_index
	for node: Node in _adapter_nodes(FACE_ADAPTER_GROUP):
		if node.has_method("set_expression"):
			node.call("set_expression", StringName(semantic_name))
		if node.has_method("set_speaking"):
			node.call("set_speaking", _actor_speaking)


func _apply_gaze(semantic_name: String) -> void:
	if semantic_name.is_empty() or semantic_name == "none":
		return
	for node: Node in _adapter_nodes(GAZE_ADAPTER_GROUP):
		if node.has_method("set_gaze_directive"):
			node.call("set_gaze_directive", StringName(semantic_name))


func _apply_gesture(semantic_name: String) -> void:
	_stop_gesture()
	if semantic_name.is_empty():
		return
	for node: Node in _adapter_nodes(GESTURE_ADAPTER_GROUP):
		if node.has_method("stop_gesture"):
			node.call("stop_gesture")
	if semantic_name == "none":
		return
	var player: AnimationPlayer = _find_animation_player(semantic_name, true)
	if player != null:
		player.play(semantic_name, ANIMATION_BLEND_SECONDS)
		_active_gesture_player = player
		_active_gesture_animation = StringName(semantic_name)
	for node: Node in _adapter_nodes(GESTURE_ADAPTER_GROUP):
		if node.has_method("play_gesture"):
			node.call("play_gesture", StringName(semantic_name))


func _dispatch_full_cue(stage: String, cue: Dictionary, actor_speaking: bool) -> void:
	for node: Node in _adapter_nodes(BODY_ADAPTER_GROUP):
		if node.has_method("apply_acting_cue"):
			node.call("apply_acting_cue", stage, cue.duplicate(true), actor_speaking)
		if node.has_method("set_speaking"):
			node.call("set_speaking", actor_speaking)


func _reset_face_shapes() -> void:
	for mesh_value: Variant in _active_face_shapes:
		var mesh: MeshInstance3D = mesh_value as MeshInstance3D
		if is_instance_valid(mesh):
			mesh.set_blend_shape_value(int(_active_face_shapes[mesh_value]), 0.0)
	_active_face_shapes.clear()


func _stop_body_animation() -> void:
	if is_instance_valid(_active_body_player) and \
			_active_body_player.current_animation == _active_body_animation:
		_active_body_player.stop()
	_active_body_player = null
	_active_body_animation = &""


func _stop_gesture() -> void:
	if is_instance_valid(_active_gesture_player) and \
			_active_gesture_player.current_animation == _active_gesture_animation:
		_active_gesture_player.stop()
	_active_gesture_player = null
	_active_gesture_animation = &""


func _has_group_method(group_name: StringName, method_name: String) -> bool:
	for node: Node in _adapter_nodes(group_name):
		if node.has_method(method_name):
			return true
	return false


func _adapter_nodes(group_name: StringName) -> Array[Node]:
	var nodes: Array[Node] = []
	if _actor_root == null:
		return nodes
	for node: Node in _actor_root.find_children("*", "Node", true, false):
		if node.is_in_group(group_name):
			nodes.append(node)
	return nodes


func _find_animation_player(semantic_name: String, gesture: bool) -> AnimationPlayer:
	if _actor_root == null:
		return null
	for node: Node in _actor_root.find_children("*", "AnimationPlayer", true, false):
		var player: AnimationPlayer = node as AnimationPlayer
		if gesture and player.name != GESTURE_PLAYER_NAME:
			continue
		if player.has_animation(semantic_name):
			return player
	return null


func _face_meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if _actor_root == null:
		return meshes
	for node: Node in _actor_root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.get_blend_shape_count() > 0:
			meshes.append(mesh)
	return meshes


func _find_blend_shape(semantic_name: String) -> MeshInstance3D:
	for mesh: MeshInstance3D in _face_meshes():
		if _blend_shape_index(mesh, semantic_name) >= 0:
			return mesh
	return null


func _blend_shape_index(mesh: MeshInstance3D, semantic_name: String) -> int:
	return mesh.find_blend_shape_by_name(StringName(semantic_name))
