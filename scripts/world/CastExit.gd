class_name CastExit
extends Node
## Walks a standing cast member out of the room once the player has finished
## talking to them, so a conversation ends the way it would on a real ward
## instead of with the character frozen in place. Points come from the
## character's `exit_after_talk` in data/world_chapter*.json, in the spawn
## marker's own frame (x right, z back, metres), the same as CastRoute:
##
##   "exit_after_talk": {"points": [[-0.7, 0.2], [-2.1, 1.0], [-1.3, 2.4]], "door": "door_office"}
##
## The character leaves only when the chapter has nothing more for them right
## now (no situational line and no open story scene). At the last point they
## step out of the scene. They come back to their marker as soon as the story
## has something for them again, and on every load. An optional door is opened
## on the way out and closed again behind them if it was closed. Cosmetic only:
## nothing here is saved.

enum State { HOME, WAITING, LEAVING, AWAY }

## Seconds after the conversation ends before the character sets off.
const DEPART_DELAY_SECONDS: float = 1.2
## The character pauses while the player is this close, rather than walk through them.
const PLAYER_CLEARANCE_M: float = 1.0
## How often an absent character checks whether the story needs them back.
const RECHECK_SECONDS: float = 1.0
## Points before this index are inside the room; the door opens on reaching it.
const DOOR_POINT_INDEX: int = 0
const DOOR_OPEN_PAUSE_SECONDS: float = 0.7

var actor: WardCharacter
var performer: CastPerformer
## World positions: the marker first, then each exit point.
var points: Array[Vector3] = []
var door_id: String = ""
var step_m: float = CastRoute.DEFAULT_STEP_M
var home_yaw: float = 0.0
var state: State = State.HOME

var _talked: bool = false
var _timer: float = 0.0
var _index: int = 1
var _door_opened_by_us: bool = false
var _door_pause: float = 0.0


## Validates an exit entry from world data. Returns the problems found.
static func validate(entry: Variant) -> Array[String]:
	if not entry is Dictionary:
		return ["exit_after_talk must be an object"]
	var errors: Array[String] = []
	var raw: Variant = entry.get("points")
	if not raw is Array or (raw as Array).is_empty():
		errors.append("exit_after_talk needs at least one point")
	else:
		for point: Variant in raw:
			if not point is Array or point.size() != 2 or not (point[0] is float or point[0] is int) \
					or not (point[1] is float or point[1] is int) \
					or absf(float(point[0])) > 8.0 or absf(float(point[1])) > 8.0:
				errors.append("exit point must be [x, z] within 8 m of the marker")
	if entry.has("door") and not entry["door"] is String:
		errors.append("door must be a door id")
	return errors


## Builds the exit on a character just placed at its marker. Returns null when
## the entry is invalid or the character is seated.
static func attach(character: WardCharacter, entry: Dictionary, step_length_m: float) -> CastExit:
	if not validate(entry).is_empty() or character.seated:
		return null
	var exit: CastExit = CastExit.new()
	exit.name = "CastExit"
	exit.actor = character
	exit.step_m = step_length_m if step_length_m > 0.2 else CastRoute.DEFAULT_STEP_M
	exit.door_id = str(entry.get("door", ""))
	var home: Transform3D = character.global_transform
	exit.home_yaw = character.rotation.y
	exit.points.append(home.origin)
	for p: Array in entry["points"]:
		var world: Vector3 = home * Vector3(float(p[0]), 0.0, float(p[1]))
		exit.points.append(Vector3(world.x, home.origin.y, world.z))
	character.add_child(exit)
	return exit


func _ready() -> void:
	(actor.get_node("Interactable") as Interactable).interacted.connect(_on_interacted.unbind(1))
	EventBus.game_loaded.connect(_on_game_loaded.unbind(1))


func walk_speed() -> float:
	return step_m / CastRoute.STEP_SECONDS * CastRoute.ANIMATION_PACE


func _on_interacted() -> void:
	if state == State.HOME:
		_talked = true


func _physics_process(delta: float) -> void:
	if performer == null:
		performer = _find_performer()
		if performer == null or not performer.can_walk():
			performer = null
			return
	match state:
		State.HOME:
			if _talked and _conversation_over():
				_talked = false
				if not _story_needs_actor():
					state = State.WAITING
					_timer = DEPART_DELAY_SECONDS
		State.WAITING:
			if performer.is_engaged() or performer.is_speaking():
				state = State.HOME  # The player started talking again.
				return
			_timer -= delta
			if _timer <= 0.0:
				_index = 1
				state = State.LEAVING
		State.LEAVING:
			if performer.is_engaged() or performer.is_speaking() or _story_needs_actor():
				# Called back mid-walk: turn round and stay in the scene.
				return_home()
				return
			_walk(delta)
		State.AWAY:
			_timer -= delta
			if _timer <= 0.0:
				_timer = RECHECK_SECONDS
				if _story_needs_actor():
					return_home()


func _walk(delta: float) -> void:
	if _door_pause > 0.0:
		_door_pause -= delta
		_stop_walking()
		return
	if _player_too_close():
		_stop_walking()
		return
	var target: Vector3 = points[_index]
	var to_target: Vector3 = target - actor.global_position
	to_target.y = 0.0
	if to_target.length() <= CastRoute.ARRIVE_M:
		actor.global_position = Vector3(target.x, actor.global_position.y, target.z)
		_arrive()
		return
	var facing: float = atan2(-to_target.x, -to_target.z)
	var diff: float = wrapf(facing - actor.rotation.y, -PI, PI)
	var turn_step: float = deg_to_rad(CastRoute.TURN_RATE_DEGREES) * delta
	actor.rotation.y += clampf(diff, -turn_step, turn_step)
	performer.set_home_yaw(actor.rotation.y)
	if absf(diff) > deg_to_rad(35.0):
		_stop_walking()
		return
	performer.set_walking(true, CastRoute.ANIMATION_PACE)
	actor.global_position += to_target.normalized() * minf(walk_speed() * delta, to_target.length())


func _arrive() -> void:
	if _index - 1 == DOOR_POINT_INDEX:
		var door: ImportedDoor = _door()
		if door != null and not door.is_open:
			door.set_open(true, true)
			_door_opened_by_us = true
			_door_pause = DOOR_OPEN_PAUSE_SECONDS
	if _index < points.size() - 1:
		_index += 1
		return
	_stop_walking()
	_close_door_behind()
	state = State.AWAY
	_timer = RECHECK_SECONDS
	actor.set_away(true)


## Puts the character back at the marker, in the scene, facing the authored way.
func return_home() -> void:
	_stop_walking()
	_close_door_behind()
	_talked = false
	_door_pause = 0.0
	state = State.HOME
	actor.global_position = points[0]
	actor.rotation.y = home_yaw
	if performer != null:
		performer.set_home_yaw(home_yaw)
	actor.set_away(false)


func _close_door_behind() -> void:
	if _door_opened_by_us:
		_door_opened_by_us = false
		var door: ImportedDoor = _door()
		if door != null and door.is_open:
			door.set_open(false, true)


func _door() -> ImportedDoor:
	if door_id.is_empty():
		return null
	for node: Node in get_tree().get_nodes_in_group("persistent_world"):
		if node is ImportedDoor and (node as ImportedDoor).door_id == door_id:
			return node as ImportedDoor
	return null


func _conversation_over() -> bool:
	return not performer.is_engaged() and not performer.is_speaking()


## True while the chapter has a line or an open story scene for this character.
func _story_needs_actor() -> bool:
	var director: Node = get_tree().get_first_node_in_group(ChapterDirector.GROUP) if is_inside_tree() else null
	if director == null:
		return false
	return not director.get_staff_line(actor.character_id).is_empty() \
			or director.has_open_interaction("character:" + actor.character_id)


## The player is close and in the way: ahead of the character on its way out.
## Someone standing beside or behind them does not hold them up (a small office
## otherwise kept Voss waiting; Mac playtest 2026-11-05).
func _player_too_close() -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return false
	var flat: Vector3 = camera.global_position - actor.global_position
	flat.y = 0.0
	if flat.length() >= PLAYER_CLEARANCE_M:
		return false
	var ahead: Vector3 = points[_index] - actor.global_position
	ahead.y = 0.0
	return ahead.length() < 0.01 or flat.normalized().dot(ahead.normalized()) > 0.3


func _stop_walking() -> void:
	if performer != null and performer.is_walking():
		performer.set_walking(false)


func _find_performer() -> CastPerformer:
	var root: Node = actor.get_node_or_null("VisualRoot")
	return root.find_child("CastPerformer", true, false) as CastPerformer if root != null else null


func _on_game_loaded() -> void:
	if state != State.HOME or _talked:
		_door_opened_by_us = false  # The load put the doors back as saved.
		if actor.is_inside_tree():
			return_home()
		else:
			state = State.HOME
			_talked = false
			actor.set_away(false)
