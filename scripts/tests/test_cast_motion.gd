extends TestCase
## The cast motion pass: walk cycle, arm swing and the new gestures on the six draft
## models (tools/character_animation/clip_library_motion.json, add_motion_clips.py),
## the shared CastPerformer acting, and CastRoute walking with its world data.

const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")
const MOTION_LIBRARY: String = "res://tools/character_animation/clip_library_motion.json"
const STANDING: PackedStringArray = ["staff_voss", "staff_hale", "staff_rahman", "staff_facilities_tech"]
const SEATED: PackedStringArray = ["pt_elias_ward", "pt_mara_ellis"]
const VOSS_LINE: String = "ch1_v_3556aa2f5b"

var _characters: Array[WardCharacter] = []
var _main: Node = null


func before_each() -> void:
	super.before_each()
	CharacterVisualPreview.set_requests({})


func after_each() -> void:
	AudioDirector.stop_dialogue()
	for character: WardCharacter in _characters:
		if is_instance_valid(character):
			character.free()
	_characters.clear()
	if is_instance_valid(_main):
		_main.free()
	_main = null
	CharacterVisualPreview.reset()
	super.after_each()


func test_draft_models_carry_the_motion_clips_on_the_right_players() -> void:
	var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MOTION_LIBRARY))
	for id: String in STANDING + SEATED:
		var character: WardCharacter = _spawn(id, id in SEATED)
		var model: Node3D = _model(character)
		if model == null:
			check(false, "%s attaches a model" % id)
			continue
		var body: AnimationPlayer = _body_player(model)
		var gestures: AnimationPlayer = model.find_child(CharacterActingAdapter.GESTURE_PLAYER_NAME, true, false) as AnimationPlayer
		for clip: Dictionary in library["clips"]:
			var name: String = clip["name"]
			var expected: bool = not (id in SEATED and clip.get("standing_only", false))
			var player: AnimationPlayer = gestures if clip["player"] == "gesture" else body
			check_eq(player.has_animation(name), expected, "%s %s %s" % [id, "has" if expected else "has no", name])
			if expected and player.has_animation(name):
				check_eq(player.get_animation(name).loop_mode == Animation.LOOP_LINEAR, bool(clip["loop"]),
						"%s %s loop mode" % [id, name])
		check(character.performer != null, "%s gets the shared CastPerformer" % id)
		check_eq(character.performer.can_walk(), id in STANDING, "%s can walk only when standing" % id)


func test_idle_characters_keep_the_facing_they_are_placed_with() -> void:
	# AuthoredWorld turns the actor to its marker after adding it to the tree.
	var voss: WardCharacter = _spawn("staff_voss", false)
	voss.rotation.y = deg_to_rad(150.0)
	for i: int in 30:
		voss.performer._process(0.05)
	check(absf(rad_to_deg(voss.rotation.y) - 150.0) < 0.01, "an idle character stays facing its marker")


func test_naomi_keeps_her_controller_and_turns_to_the_player() -> void:
	var naomi: WardCharacter = _spawn("staff_bennett", false)
	check(naomi.get_node_or_null("NaomiActingController") != null, "Naomi keeps her cue-driven controller")
	check(naomi.performer != null, "and gets the shared performer for turning and uncued talk")
	var camera: Camera3D = Camera3D.new()
	runner.add_child(camera)
	camera.make_current()
	naomi.rotation.y = 0.0
	# The player stands to her right (+X); she faces -Z.
	camera.global_position = naomi.global_position + Vector3(2.0, 1.6, 0.0)
	naomi.performer.begin_conversation()
	for i: int in 40:
		naomi.performer._process(0.05)
	check(rad_to_deg(naomi.rotation.y) < -30.0, "she turns toward the player when spoken to")
	camera.free()


func test_walk_moves_the_legs_and_swings_the_arms() -> void:
	var hale: WardCharacter = _spawn("staff_hale", false)
	var model: Node3D = _model(hale)
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var body: AnimationPlayer = _body_player(model)
	var gestures: AnimationPlayer = model.find_child(CharacterActingAdapter.GESTURE_PLAYER_NAME, true, false) as AnimationPlayer
	hale.performer.set_walking(true)
	check_eq(body.current_animation, &"walk_neutral", "walking plays the walk cycle")
	check_eq(gestures.current_animation, &"walk_arm_swing", "and the arm swing on the gesture player")
	# Skip the cross-fade from the idle so the poses below are the walk's own.
	body.play(&"walk_neutral")
	var thigh: int = skeleton.find_bone("thigh_l")
	var arm: int = skeleton.find_bone("upperarm_r")
	body.seek(0.0, true)
	gestures.seek(0.0, true)
	var thigh_a: Quaternion = skeleton.get_bone_pose_rotation(thigh)
	var arm_a: Quaternion = skeleton.get_bone_pose_rotation(arm)
	body.seek(0.55, true)
	gestures.seek(0.55, true)
	var thigh_degrees: float = rad_to_deg(thigh_a.angle_to(skeleton.get_bone_pose_rotation(thigh)))
	var arm_degrees: float = rad_to_deg(arm_a.angle_to(skeleton.get_bone_pose_rotation(arm)))
	check(thigh_degrees > 25.0 and thigh_degrees < 50.0, "the thigh swings through a step (%.1f degrees)" % thigh_degrees)
	check(arm_degrees > 10.0 and arm_degrees < 30.0, "the opposite arm swings (%.1f degrees)" % arm_degrees)
	check(not hale.performer.play_gesture(&"explain_open_hand"), "no talking gestures while walking")
	hale.performer.set_walking(false)
	check_eq(body.current_animation, &"idle_neutral", "stopping the walk returns to the idle")


func test_performer_talks_listens_and_greets() -> void:
	check_eq(str(AudioDirector.get_line(VOSS_LINE).get("speaker", "")), "staff_voss", "fixture line is Voss's")
	var voss: WardCharacter = _spawn("staff_voss", false)
	var model: Node3D = _model(voss)
	var body: AnimationPlayer = _body_player(model)
	var gestures: AnimationPlayer = model.find_child(CharacterActingAdapter.GESTURE_PLAYER_NAME, true, false) as AnimationPlayer
	voss.performer.begin_conversation()
	check_eq(gestures.current_animation, &"small_greeting_nod", "the first conversation starts with a greeting nod")
	check_eq(body.current_animation, &"listen_neutral", "and the body listens")
	gestures.stop()
	voss.performer.begin_conversation()
	check_eq(gestures.current_animation, &"small_acknowledgement_nod", "later conversations get an acknowledgement")
	gestures.stop()
	EventBus.subtitle_shown.emit(VOSS_LINE, "Dr. Voss", "A test line long enough to gesture over.", 6.0)
	check(voss.performer.is_speaking(), "her own line makes her speak")
	check_eq(body.current_animation, &"stand_conversational", "speaking plays the conversational body clip")
	EventBus.dialogue_line_finished.emit(VOSS_LINE, true)
	check(not voss.performer.is_speaking(), "the line ending stops the speaking")
	check_eq(body.current_animation, &"listen_neutral", "and she listens again")


func test_talk_gestures_are_the_same_for_the_same_line() -> void:
	var first: Array = _planned_gestures()
	var second: Array = _planned_gestures()
	check(not first.is_empty(), "a six-second line plans at least one gesture")
	check_eq(first, second, "gesture choice is seeded by the line, not by chance")
	for gesture: String in first:
		check(gesture in CastPerformer.TALK_GESTURES, "talk gestures are neutral ones: " + gesture)


func test_route_walks_out_and_back_and_waits_for_the_player() -> void:
	var tech: WardCharacter = _spawn("staff_facilities_tech", false)
	var route: CastRoute = CastRoute.attach(tech, {"points": [[0.0, -2.0]], "pause_seconds": [0.5, 0.5]}, 0.7)
	check(route != null, "a valid route attaches")
	var start: Vector3 = tech.global_position
	var far: Vector3 = tech.global_transform * Vector3(0.0, 0.0, -2.0)
	var walked: bool = false
	var reached: bool = false
	for i: int in 400:
		route._physics_process(0.05)
		walked = walked or tech.performer.is_walking()
		if tech.global_position.distance_to(far) < 0.06:
			reached = true
			break
	check(walked, "the walk cycle plays while moving")
	check(reached, "the character reaches the end of the route")
	for i: int in 400:
		route._physics_process(0.05)
		if tech.global_position.distance_to(start) < 0.06 and not tech.performer.is_walking():
			break
	check(tech.global_position.distance_to(start) < 0.06, "and walks back to the marker")
	# Talking to them stops the walk where they are.
	route._physics_process(0.6)
	for i: int in 10:
		route._physics_process(0.05)
	tech.performer.begin_conversation()
	var held: Vector3 = tech.global_position
	for i: int in 20:
		route._physics_process(0.05)
	check(tech.global_position.is_equal_approx(held), "an engaged character does not walk away")
	check(not tech.performer.is_walking(), "and stands still")


func test_route_speed_matches_the_stride() -> void:
	var route: CastRoute = CastRoute.new()
	route.step_m = 0.75
	check(absf(route.walk_speed() - 0.75 / 0.55 * 0.9) < 0.001, "speed follows step length and pace")
	route.free()


func test_route_validation() -> void:
	check_eq(CastRoute.validate({"points": [[0.0, -1.5]], "pause_seconds": [6.0, 10.0]}), [] as Array[String], "valid route")
	check(not CastRoute.validate({"points": []}).is_empty(), "a route needs points")
	check(not CastRoute.validate({"points": [[0.0, -20.0]]}).is_empty(), "a route stays near its marker")
	check(not CastRoute.validate({"points": [[0.0, -1.0]], "pause_seconds": [0.0, 1.0]}).is_empty(), "pauses are real pauses")
	var seated: WardCharacter = _spawn("pt_elias_ward", true)
	check(CastRoute.attach(seated, {"points": [[0.0, -1.0]]}, 0.7) == null, "seated characters never walk")


func test_authored_routes_are_clear_of_walls_and_props() -> void:
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	await runner.get_tree().process_frame
	var world: AuthoredWorld = _main.get_node("World")
	var routes: int = 0
	for chapter: String in ContentRegistry.get_chapter_ids():
		world.configure_chapter(chapter)
		await runner.get_tree().physics_frame
		await runner.get_tree().physics_frame
		for entry: Dictionary in ContentRegistry.get_world(chapter)["characters"]:
			if not entry.has("route"):
				continue
			routes += 1
			var actor: WardCharacter = world.get_character(entry["character_id"])
			var route: CastRoute = actor.get_node_or_null("CastRoute") as CastRoute
			check(route != null, "%s %s has its route" % [chapter, entry["character_id"]])
			if route == null:
				continue
			var space: PhysicsDirectSpaceState3D = actor.get_world_3d().direct_space_state
			var exclude: Array[RID] = [(actor.get_node("Body") as CollisionObject3D).get_rid()]
			for leg: int in route.points.size() - 1:
				for height: float in [0.3, 1.0, 1.6]:
					for side: float in [-0.3, 0.0, 0.3]:
						var a: Vector3 = route.points[leg]
						var b: Vector3 = route.points[leg + 1]
						var across: Vector3 = (b - a).normalized().cross(Vector3.UP) * side
						var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
								a + across + Vector3.UP * height, b + across + Vector3.UP * height + (b - a).normalized() * 0.3)
						query.exclude = exclude
						var hit: Dictionary = space.intersect_ray(query)
						check(hit.is_empty(), "%s %s route leg %d is clear at %.1f m height, %.1f m aside (hit %s)" % [
								chapter, entry["character_id"], leg, height, side,
								str(hit.get("collider", "")) if not hit.is_empty() else ""])
	check(routes >= 3, "the chapters author routes (%d)" % routes)


func test_exit_validation() -> void:
	check_eq(CastExit.validate({"points": [[0.0, 1.0]], "door": "door_office"}), [] as Array[String], "valid exit")
	check(not CastExit.validate({"points": []}).is_empty(), "an exit needs points")
	check(not CastExit.validate({"points": [[0.0, 12.0]]}).is_empty(), "an exit stays near its marker")
	check(not CastExit.validate({"points": [[0.0, 1.0]], "door": 3}).is_empty(), "a door is named by id")


func test_voss_walks_out_of_the_office_after_the_talk_and_is_back_on_load() -> void:
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	await runner.get_tree().process_frame
	var world: AuthoredWorld = _main.get_node("World")
	world.configure_chapter("ch1")
	await runner.get_tree().physics_frame
	await runner.get_tree().physics_frame
	var voss: WardCharacter = world.get_character("staff_voss")
	var exit: CastExit = voss.get_node_or_null("CastExit") as CastExit
	check(exit != null, "Voss has her exit in Chapter 1")
	if exit == null:
		return
	# The authored points: inside the office by its door, through it, then up the corridor
	# (the office door is at x -1.5, z -5.0; the corridor is x -1.5 to 1.5).
	var door_point: Vector3 = exit.points[1]
	var corridor_point: Vector3 = exit.points[2]
	var last: Vector3 = exit.points[exit.points.size() - 1]
	check(door_point.x < -2.3 and absf(door_point.z + 5.0) < 0.2, "she stops inside the door first (%s)" % door_point)
	check(corridor_point.x > -1.3 and corridor_point.x < 1.3 and absf(corridor_point.z + 5.0) < 0.2,
			"then steps into the corridor (%s)" % corridor_point)
	check(last.x > -1.3 and last.z < -6.0, "and walks off up the corridor (%s)" % last)
	var door: ImportedDoor = world.get_door("door_office")
	check(door != null, "the office door exists")
	if door == null:
		return
	var was_open: bool = door.is_open
	door.set_open(true, false)
	await runner.get_tree().physics_frame
	await runner.get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = voss.get_world_3d().direct_space_state
	var exclude: Array[RID] = [(voss.get_node("Body") as CollisionObject3D).get_rid()]
	for leg: int in exit.points.size() - 1:
		for height: float in [0.3, 1.0, 1.6]:
			for side: float in [-0.25, 0.0, 0.25]:
				var a: Vector3 = exit.points[leg]
				var b: Vector3 = exit.points[leg + 1]
				var across: Vector3 = (b - a).normalized().cross(Vector3.UP) * side
				var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
						a + across + Vector3.UP * height, b + across + Vector3.UP * height)
				query.exclude = exclude
				var hit: Dictionary = space.intersect_ray(query)
				check(hit.is_empty(), "exit leg %d is clear at %.1f m, %.2f m aside (hit %s)" % [
						leg, height, side, str(hit.get("collider", "")) if not hit.is_empty() else ""])
	door.set_open(was_open, false)
	# A camera far off, so the player is never in her way.
	var camera: Camera3D = Camera3D.new()
	runner.add_child(camera)
	camera.global_position = Vector3(30.0, 1.6, 30.0)
	camera.make_current()
	var home: Vector3 = voss.global_position
	exit._on_interacted()
	var saw_walking: bool = false
	for i: int in 400:
		exit._physics_process(0.05)
		saw_walking = saw_walking or (exit.performer != null and exit.performer.is_walking())
		if exit.state == CastExit.State.AWAY:
			break
	check(saw_walking, "she walks, with the walk cycle")
	check_eq(exit.state, CastExit.State.AWAY, "she reaches the corridor and steps out")
	check(voss.is_away() and not voss.visible, "and is out of the scene")
	check_eq(door.is_open, was_open, "the door is left as she found it")
	EventBus.game_loaded.emit(0)
	check_eq(exit.state, CastExit.State.HOME, "a load brings her back")
	check(voss.visible and voss.global_position.distance_to(home) < 0.01, "at her marker")
	camera.free()


# --------------------------------------------------------------------------- helpers

func _planned_gestures() -> Array:
	var voss: WardCharacter = _spawn("staff_voss", false)
	EventBus.subtitle_shown.emit(VOSS_LINE, "Dr. Voss", "Line.", 9.0)
	var planned: Array = voss.performer._pending_gestures.map(func(g: Dictionary) -> String: return g["gesture"])
	EventBus.dialogue_line_finished.emit(VOSS_LINE, true)
	_characters.erase(voss)
	voss.free()
	return planned


func _spawn(id: String, seated: bool) -> WardCharacter:
	var character: WardCharacter = CHARACTER_SCENE.instantiate() as WardCharacter
	character.kind = WardCharacter.Kind.PATIENT if id.begins_with("pt_") else WardCharacter.Kind.STAFF
	character.character_id = id
	character.seated = seated
	var path: String = CampaignCastVisuals.load_data()["characters"][id]["scene"]
	character.visual_scene = load(path) as PackedScene
	runner.add_child(character)
	_characters.append(character)
	return character


func _model(character: WardCharacter) -> Node3D:
	var root: Node3D = character.get_node("VisualRoot")
	return root.get_child(0) as Node3D if root.get_child_count() > 0 else null


func _body_player(model: Node3D) -> AnimationPlayer:
	for node: Node in model.find_children("*", "AnimationPlayer", true, false):
		if node.name != CharacterActingAdapter.GESTURE_PLAYER_NAME:
			return node as AnimationPlayer
	return null
