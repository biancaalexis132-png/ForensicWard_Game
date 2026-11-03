class_name CastRoute
extends Node
## Walks a standing cast member back and forth along a short authored route, so
## the ward has people moving in it. Points come from the character's `route` in
## data/world_chapter*.json, in the spawn marker's own frame (x right, z back,
## metres; forward is -z), and the route always starts and ends at the marker.
##
##   "route": {"points": [[0.0, -1.8]], "pause_seconds": [6.0, 11.0]}
##
## The character stops and stays where it is while the player talks to it or
## stands in its way, and starts again a little after. Cosmetic only: the walk is
## not saved, and a loaded game puts everyone back at their markers.

const TURN_RATE_DEGREES: float = 200.0
## Slows the leg cycle a little from its authored pace, for a calmer walk.
const ANIMATION_PACE: float = 0.9
## Seconds of one walk_neutral step (half of its 1.1 s cycle).
const STEP_SECONDS: float = 0.55
const DEFAULT_STEP_M: float = 0.65
const ARRIVE_M: float = 0.05
## The character waits while the player is closer than this to it.
const PLAYER_CLEARANCE_M: float = 1.8
const RESUME_DELAY_SECONDS: float = 2.5

var actor: WardCharacter
var performer: CastPerformer
var points: Array[Vector3] = []
var pause_seconds: Vector2 = Vector2(6.0, 11.0)
## Metres per step, from the motion build's report (data/character_visuals.json).
var step_m: float = DEFAULT_STEP_M
## Review captures set this to 0 to film from close by.
var player_clearance_m: float = PLAYER_CLEARANCE_M
## The marker's authored facing, restored whenever the character is back home.
var home_yaw: float = 0.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _index: int = 0
var _direction: int = 1
var _wait: float = 0.0
var _resume_at: float = 0.0
var _clock: float = 0.0


## Validates a route entry from world data. Returns the problems found.
static func validate(entry: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not entry is Dictionary:
		return ["route must be an object"]
	var raw: Variant = entry.get("points")
	if not raw is Array or (raw as Array).is_empty():
		errors.append("route needs at least one point")
	else:
		for point: Variant in raw:
			if not point is Array or point.size() != 2 or not (point[0] is float or point[0] is int) \
					or not (point[1] is float or point[1] is int) \
					or absf(float(point[0])) > 8.0 or absf(float(point[1])) > 8.0:
				errors.append("route point must be [x, z] within 8 m of the marker")
	var pause: Variant = entry.get("pause_seconds", [6.0, 11.0])
	if not pause is Array or pause.size() != 2 or float(pause[0]) < 0.5 or float(pause[1]) < float(pause[0]):
		errors.append("pause_seconds must be [min, max] with min >= 0.5")
	return errors


## Builds the route on a character just placed at its marker. Returns null when
## the entry is invalid or the character cannot walk (seated, or no walk clip).
static func attach(character: WardCharacter, entry: Dictionary, step_length_m: float) -> CastRoute:
	if not validate(entry).is_empty() or character.seated:
		return null
	var route: CastRoute = CastRoute.new()
	route.name = "CastRoute"
	route.actor = character
	route.step_m = step_length_m if step_length_m > 0.2 else DEFAULT_STEP_M
	var home: Transform3D = character.global_transform
	route.home_yaw = character.rotation.y
	route.points.append(home.origin)
	for p: Array in entry["points"]:
		var world: Vector3 = home * Vector3(float(p[0]), 0.0, float(p[1]))
		route.points.append(Vector3(world.x, home.origin.y, world.z))
	var pause: Array = entry.get("pause_seconds", [6.0, 11.0])
	route.pause_seconds = Vector2(float(pause[0]), float(pause[1]))
	character.add_child(route)
	return route


## Metres per second the feet are planted at, for this character's stride.
func walk_speed() -> float:
	return step_m / STEP_SECONDS * ANIMATION_PACE


func _ready() -> void:
	_rng.seed = hash(actor.character_id + ":route")
	_wait = _rng.randf_range(pause_seconds.x, pause_seconds.y)
	EventBus.game_loaded.connect(_on_game_loaded.unbind(1))


func _physics_process(delta: float) -> void:
	_clock += delta
	if performer == null:
		performer = actor.get_node_or_null("VisualRoot").find_child("CastPerformer", true, false) as CastPerformer \
				if actor.get_node_or_null("VisualRoot") != null else null
		if performer == null or not performer.can_walk():
			return
	if not actor.is_present() or points.size() < 2:
		return
	if _blocked():
		_resume_at = _clock + RESUME_DELAY_SECONDS
		_stop_walking()
		return
	if _clock < _resume_at:
		return
	if _wait > 0.0:
		_wait -= delta
		_stop_walking()
		return
	var target: Vector3 = points[_index]
	var to_target: Vector3 = target - actor.global_position
	to_target.y = 0.0
	if to_target.length() <= ARRIVE_M:
		actor.global_position = Vector3(target.x, actor.global_position.y, target.z)
		_arrive()
		return
	var facing: float = atan2(-to_target.x, -to_target.z)
	var diff: float = wrapf(facing - actor.rotation.y, -PI, PI)
	var turn_step: float = deg_to_rad(TURN_RATE_DEGREES) * delta
	actor.rotation.y += clampf(diff, -turn_step, turn_step)
	performer.set_home_yaw(actor.rotation.y)
	if absf(diff) > deg_to_rad(35.0):
		# Turn on the spot first; walking sideways would slide the feet.
		_stop_walking()
		return
	performer.set_walking(true, ANIMATION_PACE)
	var travel: float = minf(walk_speed() * delta, to_target.length())
	actor.global_position += to_target.normalized() * travel


func _arrive() -> void:
	_stop_walking()
	_wait = _rng.randf_range(pause_seconds.x, pause_seconds.y)
	if _index == points.size() - 1:
		_direction = -1
	elif _index == 0:
		_direction = 1
		# Back at the marker: face the way the scene was authored.
		performer.set_home_yaw(_marker_yaw())
	_index += _direction


func _marker_yaw() -> float:
	return home_yaw


func _stop_walking() -> void:
	if performer != null and performer.is_walking():
		performer.set_walking(false)


func _blocked() -> bool:
	if performer.is_engaged() or performer.is_speaking():
		return true
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return false
	var flat: Vector3 = camera.global_position - actor.global_position
	flat.y = 0.0
	return flat.length() < player_clearance_m


func _on_game_loaded() -> void:
	_stop_walking()
	actor.global_position = points[0]
	_index = 0
	_direction = 1
	_wait = _rng.randf_range(pause_seconds.x, pause_seconds.y)
	if performer != null:
		performer.set_home_yaw(_marker_yaw())
	actor.rotation.y = _marker_yaw()
