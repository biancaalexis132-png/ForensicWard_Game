extends TestCase
## Verifies the cast animation standard on the real Naomi v05 GLB: clips import with
## keys, loop, split onto the body and gesture players, reach the acting adapter,
## and the face morphs blink and take expressions. Also checks that the runtime clip
## lists match tools/character_animation/clip_library.json.

const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")
const CLIP_LIBRARY: String = "res://tools/character_animation/clip_library.json"
const VERSION: String = "v05"
const GREETING_ID: String = "ch1_b2_bennett_001"

var _characters: Array[WardCharacter] = []


func after_each() -> void:
	AudioDirector.stop_dialogue()
	for character: WardCharacter in _characters:
		if is_instance_valid(character):
			character.queue_free()
	_characters.clear()
	CharacterVisualPreview.reset()
	super.after_each()


func test_runtime_clip_lists_match_the_clip_library() -> void:
	var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CLIP_LIBRARY))
	var loops: PackedStringArray = []
	var one_shots: PackedStringArray = []
	var gestures: PackedStringArray = []
	for clip: Dictionary in library["clips"]:
		if clip["player"] == "gesture":
			gestures.append(clip["name"])
		elif clip["loop"]:
			loops.append(clip["name"])
		else:
			one_shots.append(clip["name"])
	check_eq(loops, CharacterAnimationRig.BODY_LOOP_CLIPS, "looping body clips match the library")
	check_eq(one_shots, CharacterAnimationRig.BODY_ONE_SHOT_CLIPS, "one-shot body clips match")
	check_eq(gestures, CharacterAnimationRig.GESTURE_CLIPS, "gesture clips match the library")
	var cue_data: Dictionary = NaomiActingController.load_cue_data()
	for line_id: String in cue_data["cues"]:
		for stage: String in cue_data["cues"][line_id]:
			var cue: Dictionary = cue_data["cues"][line_id][stage]
			check(cue["body"] in loops or cue["body"] in one_shots, "cue body clip is in the standard: " + cue["body"])
			check(cue["gesture"] == "none" or cue["gesture"] in gestures,
					"cue gesture is in the standard: " + cue["gesture"])


func test_clips_import_with_keys_and_split_by_player() -> void:
	var bennett: WardCharacter = _spawn_preview_bennett()
	var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
	var body: AnimationPlayer = _player(model, false)
	var gesture: AnimationPlayer = _player(model, true)
	check(body != null, "imported AnimationPlayer found")
	check(gesture != null, "GestureAnimationPlayer created next to it")
	if body == null or gesture == null:
		return
	for clip: String in CharacterAnimationRig.BODY_LOOP_CLIPS + CharacterAnimationRig.BODY_ONE_SHOT_CLIPS:
		check(body.has_animation(clip), "body clip imported: " + clip)
		if body.has_animation(clip):
			var animation: Animation = body.get_animation(clip)
			check(animation.get_track_count() > 0 and animation.track_get_key_count(0) > 1,
					"body clip has keyed tracks: " + clip)
			var loops: bool = clip in CharacterAnimationRig.BODY_LOOP_CLIPS
			check_eq(animation.loop_mode == Animation.LOOP_LINEAR, loops, "loop mode is right: " + clip)
	for clip: String in CharacterAnimationRig.GESTURE_CLIPS:
		check(gesture.has_animation(clip) and not body.has_animation(clip), "gesture clip moved: " + clip)
		if gesture.has_animation(clip):
			for track: int in gesture.get_animation(clip).get_track_count():
				var path: String = str(gesture.get_animation(clip).track_get_path(track))
				check(path.contains("neck") or path.contains("arm") or path.contains("hand"),
						"gesture only animates neck or arms: " + path)
	check_eq(body.current_animation, &"idle_neutral", "idle plays as soon as the model attaches")


func test_idle_moves_the_skeleton() -> void:
	var bennett: WardCharacter = _spawn_preview_bennett()
	var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var body: AnimationPlayer = _player(model, false)
	var bone: int = skeleton.find_bone("spine_03")
	body.play(&"idle_breathing")
	body.seek(0.0, true)
	var exhale: Quaternion = skeleton.get_bone_pose_rotation(bone)
	body.seek(1.0, true)
	var inhale: Quaternion = skeleton.get_bone_pose_rotation(bone)
	var degrees: float = rad_to_deg(exhale.angle_to(inhale))
	check(degrees > 0.4 and degrees < 3.0, "breathing turns the chest subtly (%.2f degrees)" % degrees)
	# A gesture applied after the body clip must leave the breathing chest alone.
	var gesture: AnimationPlayer = _player(model, true)
	gesture.play(&"small_greeting_nod")
	gesture.seek(0.35, true)
	check(skeleton.get_bone_pose_rotation(bone).is_equal_approx(inhale), "a gesture does not freeze the breathing")


func test_acting_cues_drive_body_gesture_and_face() -> void:
	var bennett: WardCharacter = _spawn_preview_bennett()
	var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
	var controller: NaomiActingController = bennett.get_node("NaomiActingController")
	var adapter: CharacterActingAdapter = controller.get_adapter()
	for clip: String in ["idle_neutral", "listen_neutral", "stand_conversational", "turn_from_workstation"]:
		check(adapter.has_capability("body", clip), "adapter finds body clip " + clip)
	for clip: String in CharacterAnimationRig.GESTURE_CLIPS:
		check(adapter.has_capability("gesture", clip), "adapter finds gesture " + clip)
	check(adapter.has_capability("face", "warm_subtle"), "adapter finds the warm_subtle morph")
	var cue: Dictionary = NaomiActingController.cue_for_line(NaomiActingController.load_cue_data(), GREETING_ID)
	adapter.apply_cue("during_speech", cue["during_speech"], true)
	check_eq(_player(model, false).current_animation, &"stand_conversational", "speaking cue plays body clip")
	check_eq(_player(model, true).current_animation, &"small_greeting_nod", "speaking cue plays the nod")
	var face_mesh: MeshInstance3D = _face_mesh(model)
	var warm: int = face_mesh.find_blend_shape_by_name(&"warm_subtle")
	check_eq(face_mesh.get_blend_shape_value(warm), 1.0, "speaking cue sets the warm_subtle expression")
	adapter.reset_to_safe_idle(controller.load_cue_data()["fallback"], "test")
	check_eq(face_mesh.get_blend_shape_value(warm), 0.0, "fallback clears the expression")
	check_eq(_player(model, false).current_animation, &"idle_neutral", "fallback returns to idle")


func test_face_rig_blinks_and_moves_the_mouth_when_speaking() -> void:
	var bennett: WardCharacter = _spawn_preview_bennett()
	var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
	var face: CharacterFaceRig = model.get_node("CharacterFaceRig")
	check(face != null and face.has_blink(), "face rig attached to a model with a blink morph")
	if face == null:
		return
	var mesh: MeshInstance3D = _face_mesh(model)
	var blink: int = mesh.find_blend_shape_by_name(&"blink")
	var mouth: int = mesh.find_blend_shape_by_name(&"mouth_open")
	face.blink()
	face._process(CharacterFaceRig.BLINK_SECONDS * 0.5)
	check(mesh.get_blend_shape_value(blink) > 0.9, "mid-blink the eyes are closed")
	face._process(CharacterFaceRig.BLINK_SECONDS)
	check_eq(mesh.get_blend_shape_value(blink), 0.0, "the blink reopens")
	face.set_speaking(true)
	var peak: float = 0.0
	for i: int in 30:
		face._process(1.0 / 30.0)
		peak = maxf(peak, mesh.get_blend_shape_value(mouth))
	check(peak > 0.2, "the mouth moves while speaking")
	face.set_speaking(false)
	for i: int in 30:
		face._process(1.0 / 30.0)
	check_eq(mesh.get_blend_shape_value(mouth), 0.0, "the mouth closes after speech")


func test_gaze_turns_the_eyes_toward_the_player_within_limits() -> void:
	var bennett: WardCharacter = _spawn_preview_bennett()
	var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
	var gaze: CharacterGazeRig = model.get_node_or_null("CharacterGazeRig")
	check(gaze != null and gaze.has_eyes(), "gaze rig attached to a model with eye bones")
	if gaze == null:
		return
	var controller: NaomiActingController = bennett.get_node("NaomiActingController")
	check(controller.get_adapter().has_capability("gaze", "player"), "adapter finds the gaze rig")
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var eye: int = skeleton.find_bone("eye_l")
	var head: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("head"))).origin
	var front: Vector3 = model.global_basis.z.normalized()
	var her_left: Vector3 = model.global_basis.x.normalized()
	var camera: Camera3D = Camera3D.new()
	runner.add_child(camera)
	camera.current = true
	camera.global_position = head + front * 1.5 + her_left * 0.5
	gaze.set_gaze_directive(&"player")
	for i: int in 20:
		gaze._process(1.0 / 30.0)
	var angles: Vector2 = gaze.get_eye_angles()
	check(angles.x > 10.0 and angles.x <= CharacterGazeRig.MAX_YAW_DEG + 1.0,
			"eyes turn toward a player on her left (%.1f degrees)" % angles.x)
	var turned: Quaternion = skeleton.get_bone_pose_rotation(eye)
	check(not turned.is_equal_approx(skeleton.get_bone_rest(eye).basis.get_rotation_quaternion()), "the eye bone is posed")
	camera.global_position = head - front * 2.0
	for i: int in 30:
		gaze._process(1.0 / 30.0)
	check(gaze.get_eye_angles().length() < 2.0, "a player behind her leaves the eyes at rest")
	gaze.set_gaze_directive(&"workstation")
	for i: int in 30:
		gaze._process(1.0 / 30.0)
	check(gaze.get_eye_angles().y < -5.0, "workstation gaze looks down")
	camera.queue_free()


func test_animated_model_casts_live_and_static_shadows_on_separate_layers() -> void:
	var bennett: WardCharacter = _spawn_preview_bennett()
	var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
	var skinned: int = 0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.skin == null:
			continue
		skinned += 1
		check(mesh.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "animated mesh can cast a live shadow: " + mesh.name)
		check_eq(mesh.layers, CharacterShadowSelector.LIVE_LAYER, "animated mesh is on the live-shadow layer: " + mesh.name)
		var proxy: MeshInstance3D = mesh.get_parent().get_node_or_null(String(mesh.name) + CharacterAnimationRig.SHADOW_PROXY_SUFFIX)
		check(proxy != null and proxy.mesh == mesh.mesh and proxy.skin == null, "static shadow copy exists: " + mesh.name)
		if proxy != null:
			check_eq(proxy.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "proxy only casts shadow")
			check_eq(proxy.layers, CharacterShadowSelector.PROXY_LAYER, "proxy is on the static-shadow layer")
	check(skinned >= 5, "the model's skinned meshes were found (%d)" % skinned)
	var face: CharacterFaceRig = model.get_node("CharacterFaceRig")
	face.blink()
	face._process(CharacterFaceRig.BLINK_SECONDS * 0.5)
	for node: Node in model.find_children("*" + CharacterAnimationRig.SHADOW_PROXY_SUFFIX, "MeshInstance3D", true, false):
		var proxy: MeshInstance3D = node as MeshInstance3D
		var index: int = proxy.find_blend_shape_by_name(&"blink")
		if index >= 0:
			check_eq(proxy.get_blend_shape_value(index), 0.0, "the shadow copy does not blink")


func test_only_the_nearest_light_sees_the_moving_meshes() -> void:
	var bennett: WardCharacter = _spawn_preview_bennett()
	var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
	var selector: CharacterShadowSelector = model.get_node("CharacterShadowSelector")
	var near: OmniLight3D = OmniLight3D.new()
	var far: OmniLight3D = OmniLight3D.new()
	for light: OmniLight3D in [near, far]:
		light.shadow_enabled = true
		light.omni_range = 10.0
		runner.add_child(light)
	near.global_position = model.global_position + Vector3(0.0, 2.5, 0.0)
	far.global_position = model.global_position + Vector3(6.0, 2.5, 0.0)
	check_eq(selector.refresh(), near, "the nearest shadowed light is chosen")
	check(near.shadow_caster_mask & CharacterShadowSelector.LIVE_LAYER != 0, "nearest light sees the moving meshes")
	check_eq(near.shadow_caster_mask & CharacterShadowSelector.PROXY_LAYER, 0, "nearest light ignores the static copies")
	check_eq(far.shadow_caster_mask & CharacterShadowSelector.LIVE_LAYER, 0, "other lights ignore the moving meshes")
	check(far.shadow_caster_mask & CharacterShadowSelector.PROXY_LAYER != 0, "other lights see the static copies")
	near.queue_free()
	far.queue_free()


func test_second_instance_gets_its_own_players() -> void:
	var first: WardCharacter = _spawn_preview_bennett()
	var second: WardCharacter = _spawn_preview_bennett()
	for bennett: WardCharacter in [first, second]:
		var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
		check(_player(model, true) != null and _player(model, true).has_animation(&"small_greeting_nod"),
				"every instance keeps its gesture clips (the imported library is not mutated)")


func test_models_without_clips_are_left_alone() -> void:
	var root: Node3D = Node3D.new()
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	root.add_child(mesh)
	runner.add_child(root)
	check(CharacterAnimationRig.setup(root) == null, "no AnimationPlayer, nothing prepared")
	check_eq(root.get_child_count(), 1, "no gesture player or face rig added")
	root.queue_free()


func _spawn_preview_bennett() -> WardCharacter:
	CharacterVisualPreview.set_requests({"staff_bennett": VERSION})
	var character: WardCharacter = CHARACTER_SCENE.instantiate() as WardCharacter
	character.kind = WardCharacter.Kind.STAFF
	character.character_id = "staff_bennett"
	runner.add_child(character)
	_characters.append(character)
	return character


func _player(model: Node, gesture: bool) -> AnimationPlayer:
	for node: Node in model.find_children("*", "AnimationPlayer", true, false):
		if (node.name == CharacterActingAdapter.GESTURE_PLAYER_NAME) == gesture:
			return node as AnimationPlayer
	return null


func _face_mesh(model: Node) -> MeshInstance3D:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.find_blend_shape_by_name(&"blink") >= 0 and mesh.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			return mesh
	return null
