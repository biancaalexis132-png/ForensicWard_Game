extends TestCase
## Real imported models, existing audio lifecycle, and synthetic timing fixtures.

const CHARACTER: PackedScene = preload("res://scenes/props/Character.tscn")
const FIRST: String = "ch1_b2_bennett_001"
const NEXT: String = "ch1_b2_bennett_003"
var _actors: Array[WardCharacter] = []
var _face: CharacterFaceRig
var _mesh: MeshInstance3D


func after_each() -> void:
	runner.get_tree().paused = false
	AudioDirector.stop_dialogue()
	for actor: WardCharacter in _actors:
		actor.free()
	_actors.clear()
	super.after_each()


func test_track_is_deterministic_bounded_and_quiet_for_invalid_input() -> void:
	var slots: Array[Dictionary] = DialogueVisemeTrack.build("Map, thin shoes.", 3.0)
	check_eq(slots, DialogueVisemeTrack.build("Map, thin shoes.", 3.0), "same text/duration gives the same track")
	check(is_equal_approx(float(slots.back()["end"]), 3.0), "track spans the supplied clip duration")
	check_eq(DialogueVisemeTrack.build("", 3.0).size(), 0, "empty text is quiet")
	check_eq(DialogueVisemeTrack.build("a", 0.0).size(), 0, "zero duration is quiet")
	check_eq(DialogueVisemeTrack.build("a", NAN).size(), 0, "invalid duration is quiet")
	for i: int in 150:
		var sample: Dictionary = DialogueVisemeTrack.sample(slots, float(i) / 50.0)
		check(float(sample["weight"]) >= 0.0 and float(sample["weight"]) <= 0.6,
				"approximation stays restrained")
	check_eq(DialogueVisemeTrack.sample(slots, 3.0)["shape"], DialogueVisemeTrack.SILENCE, "track ends quietly")


func test_actual_audio_event_drives_mpfb_and_skip_clears_every_mouth_shape() -> void:
	var actor: WardCharacter = _spawn("v06_mpfb")
	AudioDirector.play_line(FIRST, actor)
	check_eq(_face._line_id, FIRST, "existing audio event binds the real actor's line")
	var largest: float = 0.0
	for i: int in 30:
		_face._process(0.02)
		largest = maxf(largest, _max_viseme())
	check(largest > 0.05, "real dialogue animates exported MPFB shapes")
	AudioDirector.stop_dialogue()
	check_eq(_face._line_id, "", "skip releases the active line")
	check_eq(_max_viseme(), 0.0, "skip immediately clears all visemes")
	check_eq(_mesh.get_blend_shape_value(_mesh.find_blend_shape_by_name(&"mouth_open")), 0.0, "skip closes the fallback jaw")


func test_plain_v06_uses_jaw_fallback_and_completion_closes_it() -> void:
	_spawn("v06")
	_face._on_dialogue_started(FIRST, "Naomi", "a", 1.0)
	_face._process(0.5)
	check(_mesh.get_blend_shape_value(_mesh.find_blend_shape_by_name(&"mouth_open")) > 0.5, "model without visemes uses jaw fallback")
	EventBus.dialogue_line_finished.emit(FIRST, true)
	check_eq(_mesh.get_blend_shape_value(_mesh.find_blend_shape_by_name(&"mouth_open")), 0.0, "completion closes the jaw")


func test_different_text_shapes_do_not_double_the_jaw_or_touch_expressions_and_shadows() -> void:
	var actor: WardCharacter = _spawn("v06_mpfb")
	var expression: int = _mesh.find_blend_shape_by_name(&"warm_subtle")
	_mesh.set_blend_shape_value(expression, 0.25)
	_face._on_dialogue_started(FIRST, "Naomi", "a", 1.0)
	_face.blink()
	_face._process(0.5)
	check(_mesh.get_blend_shape_value(_mesh.find_blend_shape_by_name(&"viseme_aa_02")) > 0.5, "a selects the aa viseme")
	check_eq(_mesh.get_blend_shape_value(_mesh.find_blend_shape_by_name(&"mouth_open")), 0.0, "viseme does not stack with mouth_open")
	check_eq(_mesh.get_blend_shape_value(expression), 0.25, "expression remains independent")
	_face._on_dialogue_started(NEXT, "Naomi", "m", 1.0)
	_face._process(0.5)
	check(_mesh.get_blend_shape_value(_mesh.find_blend_shape_by_name(&"viseme_p_b_m_21")) > 0.5, "new text selects the closed-lip group")
	check_eq(_mesh.get_blend_shape_value(_mesh.find_blend_shape_by_name(&"viseme_aa_02")), 0.0, "replacement clears the old shape")
	for node: Node in actor.find_children("*", "MeshInstance3D", true, false):
		var proxy: MeshInstance3D = node as MeshInstance3D
		if proxy.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			for index: int in proxy.mesh.get_blend_shape_count():
				check_eq(proxy.get_blend_shape_value(index), 0.0, "static proxy remains untouched")


func test_stale_completion_does_not_cancel_replacement_and_load_resets_it() -> void:
	_spawn("v06_mpfb")
	_face._on_dialogue_started(FIRST, "Naomi", "a", 1.0)
	_face._on_dialogue_started(NEXT, "Naomi", "m", 1.0)
	EventBus.dialogue_line_finished.emit(FIRST, false)
	check_eq(_face._line_id, NEXT, "old completion cannot stop the replacement")
	_face._process(0.5)
	check(_max_viseme() > 0.5, "replacement keeps moving")
	EventBus.game_loaded.emit(TEST_SAVE_SLOT)
	check_eq(_face._line_id, "", "load resets presentation")
	check_eq(_max_viseme(), 0.0, "load clears all mouth shapes")


func test_duration_and_silent_text_finish_quietly() -> void:
	_spawn("v06_mpfb")
	_face._on_dialogue_started(FIRST, "Naomi", "a", 1.0)
	_face._process(0.5)
	check(_max_viseme() > 0.5, "shape moves before its duration")
	_face._process(0.6)
	check_eq(_max_viseme(), 0.0, "duration exhaustion clears the mouth")
	_face._on_dialogue_started(NEXT, "Naomi", "...", 1.0)
	_face._process(0.5)
	check_eq(_max_viseme(), 0.0, "punctuation makes no mouth opening")


func test_other_speakers_do_not_animate_this_actor() -> void:
	var actor: WardCharacter = _spawn("v06_mpfb", "staff_voss")
	AudioDirector.play_line(FIRST, actor)
	_face._process(0.3)
	check_eq(_face._line_id, "", "Naomi audio does not select Voss's face")
	check_eq(_max_viseme(), 0.0, "wrong actor remains quiet")


func test_scene_pause_freezes_viseme_time_and_resumes() -> void:
	# Flush actors queued for deletion by earlier scene/zone tests before audio starts.
	# Their existing exit hook stops their old dialogue when the queue is drained.
	await runner.get_tree().process_frame
	var actor: WardCharacter = _spawn("v06_mpfb")
	AudioDirector.play_line(FIRST, actor)
	_face.set_process(true)
	await runner.get_tree().create_timer(0.08).timeout
	var before: float = _face._line_seconds
	runner.get_tree().paused = true
	await runner.get_tree().create_timer(0.06, true).timeout
	check_eq(_face._line_seconds, before, "paused scene freezes the mouth clock")
	runner.get_tree().paused = false
	await runner.get_tree().create_timer(0.06).timeout
	check(_face._line_seconds > before, "resume continues from the paused position")


func test_unvoiced_reading_timeout_does_not_finish_during_pause() -> void:
	await runner.get_tree().process_frame
	var actor: WardCharacter = _spawn("v06_mpfb")
	var original: Dictionary = AudioDirector._lines[FIRST].duplicate(true)
	# Synthetic two-second, subtitle-only fixture; no authored file is changed.
	AudioDirector._lines[FIRST]["chapter"] = "viseme_missing_voice_fixture"
	AudioDirector._lines[FIRST]["text"] = "a"
	AudioDirector.play_line(FIRST, actor)
	_face.set_process(true)
	await runner.get_tree().create_timer(0.05).timeout
	var before: float = _face._line_seconds
	runner.get_tree().paused = true
	await runner.get_tree().create_timer(2.1, true).timeout
	check_eq(_face._line_id, FIRST, "unvoiced dialogue stays active past its reading duration while paused")
	check_eq(_face._line_seconds, before, "unvoiced mouth clock remains frozen")
	runner.get_tree().paused = false
	AudioDirector.stop_dialogue()
	AudioDirector._lines[FIRST] = original


func test_pause_between_scene_lines_delays_the_next_line() -> void:
	await runner.get_tree().process_frame
	var actor: WardCharacter = _spawn("v06_mpfb")
	var originals: Dictionary = {}
	for id: String in [FIRST, NEXT]:
		originals[id] = AudioDirector._lines[id].duplicate(true)
		AudioDirector._lines[id]["chapter"] = "viseme_missing_voice_fixture"
		AudioDirector._lines[id]["text"] = "a"
	var scene_id: String = "viseme_pause_test_scene"
	AudioDirector._scenes[scene_id] = [FIRST, NEXT]
	AudioDirector.play_scene(scene_id, {"staff_bennett": actor})
	var completed: Array = await EventBus.dialogue_line_finished
	check_eq(str(completed[0]), FIRST, "fixture first line completed")
	runner.get_tree().paused = true
	await runner.get_tree().create_timer(0.45, true).timeout
	check(not AudioDirector.is_dialogue_playing(), "paused between-line gap does not start the next line")
	check_eq(_face._line_id, "", "face stays quiet in the paused gap")
	runner.get_tree().paused = false
	await runner.get_tree().create_timer(0.45).timeout
	check_eq(_face._line_id, NEXT, "next line begins after the gap resumes")
	AudioDirector.stop_dialogue()
	for id: String in originals:
		AudioDirector._lines[id] = originals[id]
	AudioDirector._scenes.erase(scene_id)


func _spawn(version: String, character_id: String = "staff_bennett") -> WardCharacter:
	var actor: WardCharacter = CHARACTER.instantiate() as WardCharacter
	actor.character_id = character_id
	actor.visual_scene = load("res://assets/exports/characters/Naomi_Bennett_%s.glb" % version) as PackedScene
	runner.add_child(actor)
	_actors.append(actor)
	var model: Node3D = actor.get_node("VisualRoot").get_child(0)
	_face = model.get_node("CharacterFaceRig") as CharacterFaceRig
	_face.set_process(false)
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and mesh.find_blend_shape_by_name(&"mouth_open") >= 0:
			_mesh = mesh
	return actor


func _max_viseme() -> float:
	var maximum: float = 0.0
	for index: int in _mesh.mesh.get_blend_shape_count():
		if String(_mesh.mesh.get_blend_shape_name(index)).begins_with("viseme_"):
			maximum = maxf(maximum, _mesh.get_blend_shape_value(index))
	return maximum
