class_name ConversationPerformance
extends Node
## Face and eyes for the shared cast in conversation, on top of CastPerformer's
## body and gestures. Each character's manner comes from data/cast_performance.json:
##
## - Expression: their speaking face while they talk, their listening face while
##   you or someone near them talks, neutral otherwise. Faces ease in and out.
## - Eyes: on you while they talk, with short looks away at their own rhythm; on
##   whoever is speaking while they listen; resting when nobody is talking to
##   them, with an occasional glance when you come close.
## - A beat: after you make a choice, staff look down and gather themselves for a
##   moment as their reply starts (a thinking gesture, eyes lowered).
##
## Purely cosmetic: reads EventBus and CastPerformer, never writes story, clinical
## or save state, and never changes what is said or when. Patients keep a neutral
## face while speaking and never avert their eyes or pause, so nothing they do can
## read as a symptom. Naomi is acted by NaomiActingController and gets none of this.

const DATA_PATH: String = "res://data/cast_performance.json"
const EXPRESSIONS: PackedStringArray = [
	"attentive", "warm_subtle", "concerned_restrained", "professionally_serious", "focused", "calm_professional",
]
const NEUTRAL: String = "neutral"
const SKIPPED_CHARACTERS: PackedStringArray = ["staff_bennett"]
## Exponential rate the expression weights move at (per second): about 0.35 s to settle.
const FACE_RATE: float = 8.0
const BEAT_GESTURE: StringName = &"thinking_pause"
## Looks away go down and to one side, alternating, like someone finding a word.
const AWAY_ANGLES: Vector2 = Vector2(13.0, -7.0)
const BEAT_ANGLES: Vector2 = Vector2(9.0, -10.0)
const GLANCE_RANGE_M: float = 3.5
const GLANCE_SECONDS: float = 1.2
const GLANCE_EVERY: Vector2 = Vector2(7.0, 14.0)
const LISTEN_RANGE_M: float = 5.0
const STANDING_HEAD_M: float = 1.62
const SEATED_HEAD_M: float = 1.18

static var _data: Dictionary = {}

var performer: CastPerformer
var gaze: CharacterGazeRig
var profile: Dictionary = {}

var _faces: Array[Dictionary] = []
var _weights: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _clock: float = 0.0
var _was_speaking: bool = false
var _beat_pending: bool = false
var _beat_until: float = -1.0
var _next_break: float = INF
var _away_until: float = -1.0
var _away_side: float = 1.0
var _next_glance: float = 0.0
var _glance_until: float = -1.0
var _other_speaker: WardCharacter = null
var _other_until: float = -1.0


## Adds the layer to a character the shared CastPerformer acts. Returns null when
## the character is skipped or the model has neither eyes nor expression morphs.
static func attach(cast_performer: CastPerformer, model: Node3D) -> ConversationPerformance:
	if cast_performer == null or cast_performer.actor == null \
			or cast_performer.actor.character_id in SKIPPED_CHARACTERS:
		return null
	var node: ConversationPerformance = ConversationPerformance.new()
	node.name = "ConversationPerformance"
	node.performer = cast_performer
	node.profile = profile_for(cast_performer.actor.character_id, cast_performer.actor.kind == WardCharacter.Kind.STAFF)
	for found: Node in model.find_children("*", "CharacterGazeRig", true, false):
		node.gaze = found as CharacterGazeRig
	node._find_faces(model)
	if node.gaze == null and node._faces.is_empty():
		node.free()
		return null
	model.add_child(node)
	return node


## The character's manner: their own entry over the staff or patient defaults.
static func profile_for(character_id: String, is_staff: bool) -> Dictionary:
	var data: Dictionary = load_data()
	var result: Dictionary = (data.get("defaults", {}).get("staff" if is_staff else "patient", {}) as Dictionary).duplicate(true)
	if is_staff:
		result.merge(data.get("characters", {}).get(character_id, {}), true)
	return result


static func load_data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data


## Problems with data/cast_performance.json ([] when valid).
static func validate() -> Array[String]:
	var problems: Array[String] = []
	var data: Dictionary = load_data()
	var where: String = "[cast_performance.json]"
	if not data.get("defaults") is Dictionary or not data.get("characters") is Dictionary:
		return [where + " needs defaults and characters objects."]
	var entries: Dictionary = {"defaults.staff": data["defaults"].get("staff"), "defaults.patient": data["defaults"].get("patient")}
	for id: String in data["characters"]:
		entries["characters." + id] = data["characters"][id]
		if not id.begins_with("staff_") or ContentRegistry.get_staff(id).is_empty():
			problems.append("%s characters.%s: only known staff can have their own manner." % [where, id])
		if id in SKIPPED_CHARACTERS:
			problems.append("%s characters.%s: acted by her own controller, not this layer." % [where, id])
	for key: String in entries:
		var entry: Variant = entries[key]
		if not entry is Dictionary:
			problems.append("%s %s: missing." % [where, key])
			continue
		for face_key: String in ["speaking_face", "listening_face", "beat_face"]:
			if entry.has(face_key) and not (str(entry[face_key]) in EXPRESSIONS or str(entry[face_key]) == NEUTRAL):
				problems.append("%s %s.%s: unknown expression '%s'." % [where, key, face_key, entry[face_key]])
		var breaks: Variant = entry.get("gaze_breaks", [])
		if not breaks is Array or not (breaks.is_empty() or (breaks.size() == 2 and float(breaks[0]) >= 1.5 and float(breaks[1]) >= float(breaks[0]))):
			problems.append("%s %s.gaze_breaks: [] or [min, max] seconds, at least 1.5 s apart." % [where, key])
		if float(entry.get("break_seconds", 0.0)) > 1.2 or float(entry.get("beat_seconds", 0.0)) > 1.2:
			problems.append("%s %s: looks away and beats stay at 1.2 s or less." % [where, key])
	var patient: Dictionary = data["defaults"].get("patient", {}) if data["defaults"].get("patient") is Dictionary else {}
	if not (patient.get("gaze_breaks", []) as Array).is_empty() or float(patient.get("beat_seconds", 0.0)) > 0.0 \
			or str(patient.get("speaking_face", NEUTRAL)) != NEUTRAL:
		problems.append(where + " defaults.patient: patients keep a neutral speaking face, no looks away and no beat.")
	return problems


func _ready() -> void:
	_rng.seed = hash("performance:" + performer.actor.character_id)
	_next_glance = _rng.randf_range(GLANCE_EVERY.x * 0.3, GLANCE_EVERY.y * 0.5)
	EventBus.subtitle_shown.connect(_on_subtitle_shown)
	EventBus.story_option_selected.connect(_on_story_option_selected)
	EventBus.game_loaded.connect(_on_game_loaded.unbind(1))


# --------------------------------------------------------------------------- queries (tests)

## The expression it is easing toward ("neutral" for none).
func wanted_face() -> String:
	if performer.is_speaking():
		return str(profile.get("beat_face", NEUTRAL)) if _clock < _beat_until else str(profile.get("speaking_face", NEUTRAL))
	if performer.is_engaged():
		return str(profile.get("listening_face", NEUTRAL))
	return NEUTRAL


func face_weight(expression: String) -> float:
	return float(_weights.get(expression, 0.0))


func in_beat() -> bool:
	return _clock < _beat_until


# --------------------------------------------------------------------------- events

func _on_story_option_selected(_interaction_id: String, _option_id: String) -> void:
	# Their reply to the choice is the next line they speak.
	if performer.is_engaged() and float(profile.get("beat_seconds", 0.0)) > 0.0:
		_beat_pending = true


func _on_subtitle_shown(line_id: String, _speaker_name: String, _text: String, seconds: float) -> void:
	if not is_inside_tree() or not is_instance_valid(performer) or performer.actor == null:
		return  # An unloaded zone keeps its characters out of the tree.
	var speaker: String = str(AudioDirector.get_line(line_id).get("speaker", ""))
	if speaker.is_empty() or speaker == performer.actor.character_id:
		return
	_other_speaker = null
	for node: Node in get_tree().get_nodes_in_group(WardCharacter.GROUP):
		var other: WardCharacter = node as WardCharacter
		if other != null and other.character_id == speaker and other.is_present() \
				and other.global_position.distance_to(performer.actor.global_position) <= LISTEN_RANGE_M:
			_other_speaker = other
			_other_until = _clock + maxf(seconds, 0.5)
			return


func _on_game_loaded() -> void:
	_beat_pending = false
	_beat_until = -1.0
	_away_until = -1.0
	_other_speaker = null


# --------------------------------------------------------------------------- frame

func _process(delta: float) -> void:
	tick(delta)


## One frame of acting (public so tests can step it).
func tick(delta: float) -> void:
	_clock += delta
	var speaking: bool = performer.is_speaking()
	if speaking and not _was_speaking:
		_start_line()
	_was_speaking = speaking
	_update_gaze(speaking)
	_update_face(delta)


func _start_line() -> void:
	if _beat_pending:
		_beat_pending = false
		_beat_until = _clock + float(profile.get("beat_seconds", 0.0))
		performer.play_gesture(BEAT_GESTURE)
	var breaks: Array = profile.get("gaze_breaks", [])
	_next_break = (_clock + maxf(_beat_until - _clock, 0.0) + _rng.randf_range(float(breaks[0]), float(breaks[1]))) \
			if breaks.size() == 2 else INF


func _update_gaze(speaking: bool) -> void:
	if gaze == null:
		return
	if speaking:
		if _clock < _beat_until:
			gaze.look_away(Vector2(BEAT_ANGLES.x * _away_side, BEAT_ANGLES.y))
			return
		if _clock >= _next_break:
			var breaks: Array = profile.get("gaze_breaks", [])
			_away_side = -_away_side
			_away_until = _clock + float(profile.get("break_seconds", 0.0))
			_next_break = _away_until + _rng.randf_range(float(breaks[0]), float(breaks[1]))
		if _clock < _away_until:
			gaze.look_away(Vector2(AWAY_ANGLES.x * _away_side, AWAY_ANGLES.y))
		else:
			_set_directive(&"player")
		return
	if performer.is_engaged():
		if is_instance_valid(_other_speaker) and _clock < _other_until:
			var height: float = SEATED_HEAD_M if _other_speaker.seated else STANDING_HEAD_M
			gaze.look_at_point(_other_speaker.global_position + Vector3.UP * height)
		else:
			_set_directive(&"player")
		return
	# Nobody is talking to them: eyes rest, with a glance when you come close.
	if _clock >= _next_glance and _player_distance() <= GLANCE_RANGE_M:
		_glance_until = _clock + GLANCE_SECONDS
		_next_glance = _glance_until + _rng.randf_range(GLANCE_EVERY.x, GLANCE_EVERY.y)
	_set_directive(&"player" if _clock < _glance_until else &"rest")


func _set_directive(directive: StringName) -> void:
	if gaze.get_gaze_directive() != directive:
		gaze.set_gaze_directive(directive)


func _update_face(delta: float) -> void:
	if _faces.is_empty():
		return
	var wanted: String = wanted_face()
	var blend: float = 1.0 - exp(-FACE_RATE * delta)
	for expression: String in EXPRESSIONS:
		var current: float = float(_weights.get(expression, 0.0))
		var target: float = 1.0 if expression == wanted else 0.0
		if is_equal_approx(current, target):
			continue
		var next: float = lerpf(current, target, blend)
		if absf(next - target) < 0.005:
			next = target
		_weights[expression] = next
		for face: Dictionary in _faces:
			var index: int = int((face["shapes"] as Dictionary).get(expression, -1))
			if index >= 0 and is_instance_valid(face["mesh"]):
				(face["mesh"] as MeshInstance3D).set_blend_shape_value(index, next)


func _find_faces(model: Node3D) -> void:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null or mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		var shapes: Dictionary = {}
		for expression: String in EXPRESSIONS:
			var index: int = mesh.find_blend_shape_by_name(expression)
			if index >= 0:
				shapes[expression] = index
		if not shapes.is_empty():
			_faces.append({"mesh": mesh, "shapes": shapes})


func _player_distance() -> float:
	if not is_inside_tree():
		return INF
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return INF
	var flat: Vector3 = camera.global_position - performer.actor.global_position
	flat.y = 0.0
	return flat.length()
