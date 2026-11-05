class_name CastPerformer
extends Node
## Everyday acting for the cast: they greet the player, turn toward them, talk with small hand gestures while
## their voiced lines play, listen while someone else speaks, vary their idle, and
## walk when a CastRoute asks them to.
##
## Purely cosmetic: reads EventBus signals and the camera, never writes story,
## clinical or save state. Choices are seeded from the character id and line id,
## so the same lines give the same gestures. Works on any model built to the cast
## animation standard; clips a model lacks are simply skipped.
##
## Naomi also has NaomiActingController, which acts her authored handover lines
## from cue data; while it is acting a line (`body_busy` returns true) this node
## leaves her body and gestures alone and only turns her toward the player.
##
## Clip names come from tools/character_animation/clip_library.json and
## clip_library_motion.json (see CHARACTER_ANIMATION_STANDARD.md).

const IDLE_CLIPS: PackedStringArray = ["idle_neutral", "idle_breathing"]
const LISTEN_CLIP: StringName = &"listen_neutral"
const TALK_CLIP: StringName = &"stand_conversational"
const WALK_CLIP: StringName = &"walk_neutral"
const ARM_SWING_CLIP: StringName = &"walk_arm_swing"
const GREETING_GESTURE: StringName = &"small_greeting_nod"
const ACK_GESTURE: StringName = &"small_acknowledgement_nod"
## Gestures that fit any line: none of them says yes, no or "I don't know".
## small_head_shake and small_shrug carry meaning, so they only play on request.
const TALK_GESTURES: PackedStringArray = [
	"explain_open_hand", "explain_both_hands", "small_acknowledgement_nod", "thinking_pause",
]
## Gestures a seated patient can make without leaving the chair.
const SEATED_TALK_GESTURES: PackedStringArray = [
	"small_acknowledgement_nod", "explain_open_hand", "thinking_pause",
]
const BODY_BLEND_SECONDS: float = 0.4
## The conversation is over once the player is this far away.
const ENGAGE_RANGE_M: float = 6.0
## Lines from others within this range of the character are listened to.
const LISTEN_RANGE_M: float = 5.0
## After the last line or the panel closing, they hold attention this long.
const ATTENTION_HOLD_SECONDS: float = 3.0
## Standing characters turn toward the player by at most this much from home.
const MAX_TURN_DEGREES: float = 80.0
const TURN_RATE_DEGREES: float = 150.0
const IDLE_SWAP_SECONDS: Vector2 = Vector2(9.0, 16.0)

var actor: WardCharacter
var body_player: AnimationPlayer
var gesture_player: AnimationPlayer
var seated: bool = false
## Face and eyes in conversation (null when the model has neither).
var conversation: ConversationPerformance = null
## Returns true while another controller is acting the body (Naomi's cue lines).
var body_busy: Callable = Callable()

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _speaking_line: String = ""
var _speaking_until: float = 0.0
var _engaged: bool = false
var _panel_open: bool = false
var _attention_until: float = 0.0
var _greeted: bool = false
var _walking: bool = false
var _arm_swing_stopping: bool = false
## Captured on the first frame: AuthoredWorld places the actor after _ready.
var _home_yaw: float = NAN
var _turn_target: float = NAN
var _until_idle_swap: float = 0.0
var _idle_index: int = 0
var _pending_gestures: Array[Dictionary] = []
var _clock: float = 0.0


## Returns null when the model has no standard clips to act with.
static func attach(character: WardCharacter, model: Node3D, player: AnimationPlayer) -> CastPerformer:
	if player == null or not player.has_animation(LISTEN_CLIP):
		return null
	var performer: CastPerformer = CastPerformer.new()
	performer.name = "CastPerformer"
	performer.actor = character
	performer.body_player = player
	performer.seated = character.seated
	performer.gesture_player = player.get_parent().get_node_or_null(
			NodePath(CharacterActingAdapter.GESTURE_PLAYER_NAME)) as AnimationPlayer
	model.add_child(performer)
	performer.conversation = ConversationPerformance.attach(performer, model)
	return performer


func _ready() -> void:
	_rng.seed = hash(actor.character_id if actor != null else name)
	_until_idle_swap = _rng.randf_range(IDLE_SWAP_SECONDS.x, IDLE_SWAP_SECONDS.y)
	EventBus.subtitle_shown.connect(_on_subtitle_shown)
	EventBus.dialogue_line_finished.connect(_on_line_finished)
	EventBus.ui_panel_closed.connect(_on_panel_closed)
	EventBus.game_loaded.connect(_on_game_loaded.unbind(1))


# --------------------------------------------------------------------------- public

## The player has just started talking to this character.
func begin_conversation() -> void:
	_engaged = true
	_panel_open = true
	_attention_until = _clock + ATTENTION_HOLD_SECONDS
	play_gesture(ACK_GESTURE if _greeted else GREETING_GESTURE)
	_greeted = true
	_update_body()


func is_engaged() -> bool:
	return _engaged


func is_speaking() -> bool:
	return not _speaking_line.is_empty()


func is_walking() -> bool:
	return _walking


## Plays one gesture over whatever the body is doing. Returns false if the model
## does not have it, or the character is walking (the arms are swinging).
func play_gesture(gesture: StringName) -> bool:
	if gesture_player == null or _walking or not gesture_player.has_animation(gesture):
		return false
	gesture_player.play(gesture)
	return true


## Starts or stops the walk cycle. CastRoute moves the character; this only animates.
func set_walking(walking: bool, speed_scale: float = 1.0) -> void:
	if walking == _walking:
		if walking:
			body_player.speed_scale = speed_scale
			if gesture_player != null:
				gesture_player.speed_scale = speed_scale
		return
	_walking = walking
	_pending_gestures.clear()
	if walking and body_player.has_animation(WALK_CLIP):
		body_player.speed_scale = speed_scale
		body_player.play(WALK_CLIP, 0.25)
		if gesture_player != null and gesture_player.has_animation(ARM_SWING_CLIP):
			_arm_swing_stopping = false
			gesture_player.speed_scale = speed_scale
			# The arm swing must stay in step with the legs.
			gesture_player.play(ARM_SWING_CLIP)
			gesture_player.seek(body_player.current_animation_position, true)
		return
	body_player.speed_scale = 1.0
	if gesture_player != null and gesture_player.current_animation == ARM_SWING_CLIP:
		_arm_swing_stopping = true
	_update_body()


## Where the character faces when nobody is talking to it (CastRoute sets this).
func set_home_yaw(yaw: float) -> void:
	_home_yaw = yaw


func can_walk() -> bool:
	return not seated and body_player.has_animation(WALK_CLIP)


# --------------------------------------------------------------------------- events

func _on_subtitle_shown(line_id: String, _speaker_name: String, _text: String, seconds: float) -> void:
	if actor == null or not actor.is_present():
		return
	var speaker: String = str(AudioDirector.get_line(line_id).get("speaker", ""))
	if speaker == actor.character_id:
		_speaking_line = line_id
		_speaking_until = _clock + maxf(seconds, 0.5)
		_engaged = true
		_attention_until = _speaking_until + ATTENTION_HOLD_SECONDS
		if not _body_busy():
			_plan_talk_gestures(line_id, seconds)
	elif _engaged or (_player_distance() <= LISTEN_RANGE_M and not speaker.is_empty()):
		# Someone else is talking near them: they listen.
		_engaged = true
		_attention_until = _clock + maxf(seconds, 0.5) + ATTENTION_HOLD_SECONDS
	_update_body()


func _on_line_finished(line_id: String, _completed: bool) -> void:
	if line_id != _speaking_line:
		return
	_speaking_line = ""
	_pending_gestures.clear()
	_attention_until = _clock + ATTENTION_HOLD_SECONDS
	_update_body()


func _on_panel_closed(_panel_id: String) -> void:
	if not _panel_open:
		return
	_panel_open = false
	_attention_until = _clock + ATTENTION_HOLD_SECONDS


func _on_game_loaded() -> void:
	_speaking_line = ""
	_engaged = false
	_panel_open = false
	_pending_gestures.clear()
	_turn_target = NAN
	_update_body()


# --------------------------------------------------------------------------- frame

func _process(delta: float) -> void:
	_clock += delta
	if not _speaking_line.is_empty() and _clock > _speaking_until + 1.0:
		# The line-finished signal never came (skipped, or the voice stopped).
		_on_line_finished(_speaking_line, false)
	if _engaged and not _panel_open and _speaking_line.is_empty() and _clock > _attention_until:
		_engaged = false
		_update_body()
	if _engaged and _player_distance() > ENGAGE_RANGE_M:
		_engaged = false
		_panel_open = false
		_update_body()
	_run_pending_gestures()
	_update_idle(delta)
	_update_arm_swing_stop()
	_update_turn(delta)


func _plan_talk_gestures(line_id: String, seconds: float) -> void:
	_pending_gestures.clear()
	var pool: PackedStringArray = SEATED_TALK_GESTURES if seated else TALK_GESTURES
	var available: Array[String] = []
	for gesture: String in pool:
		if gesture_player != null and gesture_player.has_animation(gesture):
			available.append(gesture)
	if available.is_empty() or seconds < 1.5:
		return
	# Seeded by the line, so a replayed line gestures the same way.
	var line_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	line_rng.seed = hash(actor.character_id + ":" + line_id)
	var at: float = line_rng.randf_range(0.3, 0.9)
	while at < seconds - 1.0:
		_pending_gestures.append({"at": _clock + at,
				"gesture": available[line_rng.randi_range(0, available.size() - 1)]})
		at += line_rng.randf_range(3.5, 6.0)


func _run_pending_gestures() -> void:
	if _pending_gestures.is_empty() or _clock < float(_pending_gestures[0]["at"]):
		return
	var next: Dictionary = _pending_gestures.pop_front()
	if _body_busy() or (gesture_player != null and gesture_player.is_playing()):
		return  # Never cut a gesture short.
	play_gesture(StringName(next["gesture"]))


func _update_body() -> void:
	if _walking or body_player == null or _body_busy():
		return
	var clip: StringName
	if not _speaking_line.is_empty() and body_player.has_animation(TALK_CLIP):
		clip = TALK_CLIP
	elif _engaged:
		clip = LISTEN_CLIP
	else:
		clip = StringName(IDLE_CLIPS[_idle_index])
	if body_player.current_animation != clip and body_player.has_animation(clip):
		body_player.play(clip, BODY_BLEND_SECONDS)


func _update_idle(delta: float) -> void:
	if _walking or _engaged or _body_busy():
		return
	_until_idle_swap -= delta
	if _until_idle_swap > 0.0:
		return
	_until_idle_swap = _rng.randf_range(IDLE_SWAP_SECONDS.x, IDLE_SWAP_SECONDS.y)
	_idle_index = (_idle_index + 1) % IDLE_CLIPS.size()
	_update_body()


## The swing is stopped when both arms pass the bottom of the swing, so they do
## not snap back to the sides.
func _update_arm_swing_stop() -> void:
	if not _arm_swing_stopping or gesture_player == null:
		return
	if gesture_player.current_animation != ARM_SWING_CLIP:
		_arm_swing_stopping = false
		return
	var length: float = gesture_player.current_animation_length
	var phase: float = fmod(gesture_player.current_animation_position, length) / length
	if absf(phase - 0.25) < 0.04 or absf(phase - 0.75) < 0.04:
		gesture_player.stop()
		gesture_player.speed_scale = 1.0
		_arm_swing_stopping = false


func _update_turn(delta: float) -> void:
	if actor == null or seated or _walking:
		return
	if is_nan(_home_yaw):
		_home_yaw = actor.rotation.y
	var target: float = _home_yaw
	if _engaged:
		var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
		if camera != null:
			var to_player: Vector3 = camera.global_position - actor.global_position
			to_player.y = 0.0
			if to_player.length() > 0.2:
				# Godot's forward is -Z: the yaw that points -Z at the player.
				var facing: float = atan2(-to_player.x, -to_player.z)
				var offset: float = clampf(wrapf(facing - _home_yaw, -PI, PI),
						-deg_to_rad(MAX_TURN_DEGREES), deg_to_rad(MAX_TURN_DEGREES))
				target = _home_yaw + offset
	var current: float = actor.rotation.y
	var diff: float = wrapf(target - current, -PI, PI)
	if absf(diff) < 0.002:
		return
	var step: float = deg_to_rad(TURN_RATE_DEGREES) * delta
	# Eases in over the last 20 degrees so the turn settles instead of stopping dead.
	actor.rotation.y = current + clampf(diff, -step, step) * maxf(smoothstep(0.0, 0.35, absf(diff)), 0.15)


func _body_busy() -> bool:
	return body_busy.is_valid() and bool(body_busy.call())


func _player_distance() -> float:
	if actor == null or not is_inside_tree():
		return INF
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return INF
	var flat: Vector3 = camera.global_position - actor.global_position
	flat.y = 0.0
	return flat.length()
