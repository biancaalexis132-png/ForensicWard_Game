extends TestCase
## Real director + AudioDirector regressions, with a temporary audio fixture.
## The fixture reuses an existing short gameplay OGG only as a test stimulus;
## it is never assigned to a shipped recap track or distributed as narration.
const SCENE: PackedScene = preload("res://scenes/cutscene/CutsceneDirector.tscn")
const FIXTURE: String = "res://audio/narration/__qa_voice.ogg"
const SOURCE: String = "res://audio/voice/ch1/ch1_b2_player_001.ogg"
var _roots: Array[Node] = []

func before_each() -> void:
	super.before_each()
	Settings.set_value("recap_narration", true)
	Settings.set_value("subtitles", true)
	AudioDirector.clear_music_contexts()

func after_each() -> void:
	AudioDirector.stop_narration()
	AudioDirector.stop_dialogue()
	for node: Node in _roots:
		if is_instance_valid(node):
			node.queue_free()
	_roots.clear()
	DirAccess.remove_absolute(FIXTURE)
	Settings.set_value("recap_narration", true)
	Settings.set_value("subtitles", true)
	Settings.set_value("reduce_motion", false)
	AudioDirector.clear_music_contexts()
	super.after_each()

func _director() -> CutsceneDirector:
	var node: CutsceneDirector = SCENE.instantiate() as CutsceneDirector
	runner.add_child(node)
	_roots.append(node)
	node.set_process(false)
	return node

func _voiced() -> CutsceneDirector:
	check_eq(DirAccess.copy_absolute(SOURCE, FIXTURE), OK, "temporary real audio stimulus copied")
	var d: CutsceneDirector = _director()
	check(d.play("cs_ch01_static_gn"), "real recap starts")
	var data: Dictionary = d.get("_narration_data").duplicate(true)
	var track: Dictionary = data["tracks"]["nar_ch01_p01"]
	track["audio_path"] = FIXTURE
	var stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(FIXTURE)
	track["cues"] = [{"start": 0.0, "end": stream.get_length(), "text": track["text"]}]
	d.set("_narration_data", data)
	d.call("_show_panel", 0)
	return d

func test_every_panel_has_exact_binding_and_three_exclusive_endings() -> void:
	var data: Dictionary = NarrationRegistry.load_data()
	check_eq(NarrationRegistry.validate(data), [], "authored narration validates")
	check_eq(data["bindings"].size(), 36, "all 36 original panels have bindings")
	check_eq(data["tracks"].size(), 39, "36 defaults plus three ending alternatives")
	for chapter: int in [1, 2, 3, 4, 5]:
		var errors: Array[String] = []
		var scene: Dictionary = CutsceneRegistry.get_cutscene("cs_ch0%d_static_gn" % chapter, errors)
		check_eq(errors, [], "recap validates")
		for panel: Dictionary in scene["panels"]:
			check_eq(panel["narration_ref"], "ch%d:%s" % [chapter, panel["id"]], "panel/chapter binding stays exact")
	for ending: String in ["review", "restricted", "inquiry"]:
		var story: Dictionary = {"chapters": {"ch5": {"flags": ["ch5_ending_" + ending, "ch5_epilogue_" + ending]}}}
		var track: Dictionary = NarrationRegistry.resolve("ch5:p06", story, data)
		check(not str(track["audio_path"]).is_empty(), "exactly one ending is voiced")
		check(track["id"] != "nar_ch05_p06", "generic alternatives are not narrated as an outcome")
	var conflicting: Dictionary = {"chapters": {"ch5": {"flags": ["ch5_ending_review", "ch5_epilogue_review", "ch5_ending_restricted", "ch5_epilogue_restricted"]}}}
	check_eq(NarrationRegistry.resolve("ch5:p06", conflicting, data)["audio_path"], "", "conflicting flags recover without a made-up ending")
	check_eq(NarrationRegistry.resolve("ch5:p06", {}, data)["audio_path"], "", "legacy/missing flag fallback")

func test_invalid_cues_and_duplicate_gameplay_speech_are_rejected() -> void:
	var data: Dictionary = NarrationRegistry.load_data()
	data["tracks"]["nar_ch01_p01"]["cues"] = [{"start": 2.0, "end": 1.0, "text": "bad"}]
	check_contains(NarrationRegistry.validate(data), "timing/text invalid", "backwards cues fail")
	var errors: Array[String] = []
	var scene: Dictionary = CutsceneRegistry.get_cutscene("cs_ch01_static_gn", errors)
	scene["panels"][0]["line_id"] = "ch1_b2_bennett_001"
	check_contains(CutsceneRegistry.validate(scene, CutsceneRegistry.reference_context()), "cannot duplicate", "gameplay dialogue never added beneath narration")

func test_disabled_voice_keeps_readable_captions_even_with_subtitles_off() -> void:
	Settings.set_value("recap_narration", false)
	Settings.set_value("subtitles", false)
	var d: CutsceneDirector = _director()
	d.play("cs_ch01_static_gn")
	check(not d.get_node("Root/Subtitle").text.is_empty(), "captions remain usable without speech")
	check(AudioDirector.narration_finished(), "no voice started")
	check(not bool(AudioDirector.get("_dialogue_ducked")), "no voice duck held")
	check(d.get("_panel_duration") > 6.5, "reading time extends the original short silent hold")
	d.skip()

func test_pause_freezes_audio_captions_and_watchdog_and_restores_duck() -> void:
	var d: CutsceneDirector = _voiced()
	check(not AudioDirector.narration_finished(), "real audio playing")
	d.set_narration_paused(true)
	var elapsed: float = d.get("_panel_time")
	var position: float = AudioDirector.narration_position()
	d.advance(10000.0)
	await runner.get_tree().create_timer(0.1).timeout
	check_eq(d.get("_panel_time"), elapsed, "paused watchdog does not consume active time")
	check(absf(AudioDirector.narration_position() - position) < 0.1, "audio clock held")
	check(not bool(AudioDirector.get("_dialogue_ducked")), "paused voice releases speech duck")
	d.set_narration_paused(false)
	check(bool(AudioDirector.get("_dialogue_ducked")), "resume ducks again")
	d.skip()
	check(AudioDirector.narration_finished(), "skip stops paused/resumed voice")
	check(not bool(AudioDirector.get("_dialogue_ducked")), "skip restores speech mix")

func test_panel_waits_for_real_audio_and_subtitle_clears_on_finish() -> void:
	var d: CutsceneDirector = _voiced()
	# Deliberately extend the fixture stream beyond the visual clock, then
	# step visual time without advancing the sound device.
	d.advance(6.6)
	check_eq(d.panel_index, 0, "short authored panel cannot crop still-playing audio")
	check(not d.get_node("Root/Subtitle").text.is_empty(), "caption follows actual audio position")
	await runner.get_tree().create_timer(2.5).timeout
	d.advance(0.01)
	check_eq(d.get_node("Root/Subtitle").text, "", "subtitle ends with the clip")
	d.advance(0.6)
	check_eq(d.panel_index, 1, "voice completion plus tail advances")
	d.skip()

func test_stalled_audio_recovers_and_does_not_soft_lock() -> void:
	var d: CutsceneDirector = _voiced()
	d.advance(8.0)
	check_contains(d.runtime_errors, "narration timeout", "stalled voice has bounded active-time recovery")
	check(AudioDirector.narration_finished(), "stalled audio stopped")
	for _i: int in 1000:
		if not d.is_open:
			break
		d.advance(0.2)
	check(not d.is_open, "caption fallback finishes the chapter recap")

func test_skip_each_panel_replay_and_toggle_do_not_change_saved_game() -> void:
	for target: int in 7:
		var before: Dictionary = SaveManager.capture_state()
		var d: CutsceneDirector = _director()
		d.play("cs_ch01_static_gn")
		for _i: int in target:
			d.next_panel()
		d.skip()
		d.skip()
		check_eq(AudioDirector.get_music_context(), "", "skip restores music at every panel")
		check_eq(SaveManager.capture_state(), before, "recaps never grant story/clinical/evidence state")
		d.replay()
		check_eq(d.panel_index, 0, "campaign replay returns to first panel")
		d.skip()
	var voiced: CutsceneDirector = _voiced()
	Settings.set_value("recap_narration", false)
	check(AudioDirector.narration_finished(), "disabling mid-clip stops voice")
	check(not voiced.get_node("Root/Subtitle").text.is_empty(), "caption fallback immediate")
	Settings.set_value("recap_narration", true)
	check_eq(voiced.get("_panel_time"), 0.0, "enabling voice restarts the current panel from zero")
	voiced.skip()

func test_load_interrupts_and_reduced_motion_keeps_panels_still() -> void:
	Settings.set_value("reduce_motion", true)
	var d: CutsceneDirector = _voiced()
	d.advance(0.1)
	var layer: Control = d.get_node("Root/Panel_p01/Art/Layer")
	var position: Vector2 = layer.position
	var scale: Vector2 = layer.scale
	d.advance(0.2)
	check_eq(layer.position, position, "reduced-motion pan stays fixed")
	check_eq(layer.scale, scale, "reduced-motion zoom stays fixed")
	EventBus.game_loaded.emit(TEST_SAVE_SLOT)
	check(not d.is_open, "loading closes transient recap")
	check(AudioDirector.narration_finished(), "loading stops owned voice")
	check_eq(AudioDirector.get_music_context(), "", "loading restores soundtrack context")
	d.replay()
	check(not d.is_open, "load cannot replay stale prior-timeline recap")

func test_real_save_load_preserves_completion_and_replay_uses_saved_flags() -> void:
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(main)
	_roots.append(main)
	await wait_physics_frames(5)
	var chapter: ChapterDirector = main.get_node("ChapterDirector")
	chapter.set_flag("chapter_complete")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "completed campaign checkpoint saved")
	EventBus.ui_panel_requested.emit("cutscene", {"cutscene_id": "cs_ch01_static_gn"})
	var d: CutsceneDirector = main.get_node("CutsceneDirector")
	check(d.is_open, "recap overlays gameplay")
	check_eq(main.call("_top_panel"), d, "recap owns chapter-completion input")
	check(TimeManager.is_paused(), "world clock stays paused underneath recap")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load interrupts the transient overlay")
	check(not d.is_open, "loaded save cannot leave voice or overlay stuck")
	check(chapter.has_completed("ch1"), "chapter progress survives load")
	EventBus.ui_panel_requested.emit("cutscene", {"replay_completed": true})
	check(d.is_open, "completed recap remains replayable after loading")
	check_eq(d.cutscene_id, "cs_ch01_static_gn", "replay uses saved chapter progression")
	d.skip()

func test_branch_replay_snapshots_context_and_never_changes_story() -> void:
	var data: Dictionary = NarrationRegistry.load_data()
	var expected: Dictionary = {"review": "a", "restricted": "b", "inquiry": "c"}
	for ending: String in expected:
		var story: Dictionary = {"chapters": {"ch5": {"flags": ["ch5_ending_" + ending, "ch5_epilogue_" + ending]}}}
		var d: CutsceneDirector = _director()
		d.open({"cutscene_id": "cs_ch05_static_gn", "story_context": story})
		story["chapters"]["ch5"]["flags"].clear()
		for _i: int in 5:
			d.next_panel()
		check_eq(d.get("_track")["id"], "nar_ch05_p06_" + str(expected[ending]), "shared panel gets exactly its saved ending")
		d.replay()
		for _i: int in 5:
			d.next_panel()
		check_eq(d.get("_track")["id"], "nar_ch05_p06_" + str(expected[ending]), "replay holds immutable ending snapshot")
		d.skip()
