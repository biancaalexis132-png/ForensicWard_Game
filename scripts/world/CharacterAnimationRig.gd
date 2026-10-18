class_name CharacterAnimationRig
extends RefCounted
## Prepares an imported character model that follows the cast animation standard
## (tools/character_animation/clip_library.json and CHARACTER_ANIMATION_STANDARD.md).
##
## Imported glTF puts every clip on one AnimationPlayer. The acting adapter looks
## for gesture clips on a player named GestureAnimationPlayer, so gesture clips
## move there; body clips stay and loop. Gesture clips only animate the neck and
## arms and body clips never do, so both players run at once without fighting.
## Models without these clips or morph targets are left exactly as imported.

const BODY_LOOP_CLIPS: PackedStringArray = [
	"idle_neutral", "idle_breathing", "listen_neutral", "stand_conversational",
]
const BODY_ONE_SHOT_CLIPS: PackedStringArray = ["turn_from_workstation", "return_to_workstation"]
const GESTURE_CLIPS: PackedStringArray = [
	"small_greeting_nod", "small_acknowledgement_nod",
	"restrained_chart_indication", "subtle_workstation_indication",
]
const IDLE_CLIP: StringName = &"idle_neutral"
const BLINK_SHAPE: StringName = &"blink"


## Returns the body AnimationPlayer it prepared, or null if the model has no clips.
static func setup(model: Node3D) -> AnimationPlayer:
	var body_player: AnimationPlayer = _find_body_player(model)
	if body_player != null:
		_prepare_players(body_player)
	if _has_blend_shape(model, BLINK_SHAPE):
		var face: CharacterFaceRig = CharacterFaceRig.new()
		face.name = "CharacterFaceRig"
		face.configure(model)
		model.add_child(face)
	return body_player


static func _prepare_players(body_player: AnimationPlayer) -> void:
	var gesture_library: AnimationLibrary = AnimationLibrary.new()
	for library_name: StringName in body_player.get_animation_library_list():
		var library: AnimationLibrary = body_player.get_animation_library(library_name)
		for clip: StringName in library.get_animation_list():
			var animation: Animation = library.get_animation(clip)
			if String(clip) in BODY_LOOP_CLIPS:
				animation.loop_mode = Animation.LOOP_LINEAR
			elif String(clip) in GESTURE_CLIPS and library_name == &"":
				gesture_library.add_animation(clip, _without_held_tracks(animation))
	if not gesture_library.get_animation_list().is_empty():
		# The imported library is shared by every instance of the scene: edit a copy.
		var main_library: AnimationLibrary = body_player.get_animation_library(&"").duplicate()
		for clip: StringName in gesture_library.get_animation_list():
			main_library.remove_animation(clip)
		body_player.remove_animation_library(&"")
		body_player.add_animation_library(&"", main_library)
		var gesture_player: AnimationPlayer = AnimationPlayer.new()
		gesture_player.name = CharacterActingAdapter.GESTURE_PLAYER_NAME
		gesture_player.root_node = body_player.root_node
		gesture_player.add_animation_library(&"", gesture_library)
		# Added after the body player, so it processes later in the frame.
		body_player.get_parent().add_child(gesture_player)
	if body_player.has_animation(IDLE_CLIP) and body_player.current_animation.is_empty():
		body_player.play(IDLE_CLIP)


## The glTF importer gives every clip a one-key track holding the rest pose for each
## bone some other clip animates. On the gesture player those would freeze the body
## clip's spine and head while a gesture plays, so gesture clips keep only the bones
## they actually move.
static func _without_held_tracks(animation: Animation) -> Animation:
	var trimmed: Animation = animation.duplicate() as Animation
	for track: int in range(trimmed.get_track_count() - 1, -1, -1):
		if trimmed.track_get_key_count(track) <= 1:
			trimmed.remove_track(track)
	return trimmed


static func _find_body_player(model: Node3D) -> AnimationPlayer:
	for node: Node in model.find_children("*", "AnimationPlayer", true, false):
		var player: AnimationPlayer = node as AnimationPlayer
		if player.name != CharacterActingAdapter.GESTURE_PLAYER_NAME and player.has_animation(IDLE_CLIP):
			return player
	return null


static func _has_blend_shape(model: Node3D, shape: StringName) -> bool:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).find_blend_shape_by_name(shape) >= 0:
			return true
	return false
