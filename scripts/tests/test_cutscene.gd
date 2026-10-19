extends TestCase
## Graphic-novel cutscenes (CutsceneRegistry, CutsceneDirector): the review-only
## gate, schema and reference validation, playback, skip/replay, every restore
## path, and that a cutscene never writes story, clinical or save state.

const DIRECTOR_SCENE: PackedScene = preload("res://scenes/cutscene/CutsceneDirector.tscn")
const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const PILOT: String = "cs_ch01_first_shift_pilot"
const STEP: float = 0.1

var _roots: Array[Node] = []
var _finished: Array[String] = []


func before_each() -> void:
	super.before_each()
	_finished.clear()
	AudioDirector.clear_music_contexts()


func after_each() -> void:
	AudioDirector.stop_dialogue()
	for root: Node in _roots:
		if is_instance_valid(root):
			root.queue_free()
	_roots.clear()
	AudioDirector.clear_music_contexts()
	Settings.set_value("reduce_motion", false)
	super.after_each()


# --- Registry ---------------------------------------------------------------------------

func test_pilot_is_valid_and_review_only() -> void:
	var loaded: Dictionary = CutsceneRegistry.load_all()
	check_eq(loaded["errors"], [], "every cutscene file validates")
	var pilot: Dictionary = (loaded["cutscenes"] as Dictionary).get(PILOT, {})
	check(not pilot.is_empty(), "the Chapter 1 pilot is registered")
	check_eq(pilot.get("approved"), false, "the pilot is not approved")
	check_eq(pilot.get("mode"), "review_only", "the pilot is review-only")
	check_eq((pilot.get("trigger", {}) as Dictionary).get("kind"), "manual_preview", "only a manual preview starts it")
	check_eq(CutsceneRegistry.chapter_start_cutscene("ch1"), "", "nothing plays when Chapter 1 opens")
	check_eq((pilot.get("panels", []) as Array).size(), 7, "seven panels")
	check_eq(CutsceneRegistry.total_duration(pilot), 52.0, "about 52 seconds")


func test_chapter_title_cards_are_approved_and_play() -> void:
	var loaded: Dictionary = CutsceneRegistry.load_all()
	for chapter: int in [2, 3, 4, 5]:
		var id: String = "cs_ch0%d_title" % chapter
		var card: Dictionary = (loaded["cutscenes"] as Dictionary).get(id, {})
		check(not card.is_empty(), "registered: " + id)
		check_eq(card.get("approved"), true, id + " is approved by the owner")
		check_eq((card.get("trigger", {}) as Dictionary).get("kind"), "chapter_start", id + " opens its chapter")
		check_eq(CutsceneRegistry.chapter_start_cutscene("ch%d" % chapter), id, id + " is found for its chapter")
		check_eq(card.get("chapter_id"), "ch%d" % chapter, id + " belongs to its chapter")
		check_eq(card["panels"][0]["caption_ref"], "chapter.ch%d.title" % chapter, id + " opens on its chapter title")
		for panel: Dictionary in card["panels"]:
			check(panel["line_id"] == null, id + " has no dialogue")
		var director: CutsceneDirector = _director(false)
		check(director.play(id), id + " plays outside review mode")
		var elapsed: float = 0.0
		while director.is_open and elapsed < 30.0:
			director.advance(STEP)
			elapsed += STEP
		check(not director.is_open, id + " finishes")
		check_eq(director.runtime_errors, [], id + " textures load")
		check_eq(AudioDirector.get_music_context(), "", id + " restores the music")


func test_static_graphic_novel_chapters_are_review_only_and_play() -> void:
	var loaded: Dictionary = CutsceneRegistry.load_all()
	for chapter: int in [1, 2, 3, 4, 5]:
		var id: String = "cs_ch0%d_static_gn" % chapter
		var cutscene: Dictionary = (loaded["cutscenes"] as Dictionary).get(id, {})
		if cutscene.is_empty() and not FileAccess.file_exists("res://data/cutscenes/%s.json" % id):
			continue
		check(not cutscene.is_empty(), "registered: " + id)
		check_eq(cutscene.get("approved"), false, id + " placement is not approved yet")
		check_eq((cutscene.get("trigger", {}) as Dictionary).get("kind"), "manual_preview", id + " only plays on request")
		check_eq(cutscene.get("chapter_id"), "ch%d" % chapter, id + " belongs to its chapter")
		check(not _director(false).play(id), id + " never plays outside review")
		var director: CutsceneDirector = _director(true)
		check(director.play(id), id + " plays in review mode")
		var visited: Array[int] = [director.panel_index]
		var elapsed: float = 0.0
		while director.is_open and elapsed < 90.0:
			director.advance(STEP)
			elapsed += STEP
			if director.is_open and director.panel_index != visited.back():
				visited.append(director.panel_index)
		check_eq(visited.size(), (cutscene["panels"] as Array).size(), id + " shows every panel once")
		check(absf(elapsed - CutsceneRegistry.total_duration(cutscene)) < 0.2, id + " runs its authored length")
		check(not director.is_open, id + " finishes")
		check_eq(director.runtime_errors, [], id + " textures load")
		check_eq(AudioDirector.get_music_context(), "", id + " restores the music")
	for chapter: int in [2, 3, 4, 5]:
		check_eq(CutsceneRegistry.chapter_start_cutscene("ch%d" % chapter), "cs_ch0%d_title" % chapter, "the title card still opens chapter %d" % chapter)


func test_captions_come_from_campaign_data() -> void:
	check_eq(CutsceneRegistry.resolve_caption("institution.name"), "Ashcroft State Forensic Hospital",
			"institution caption is the approved name")
	check_eq(CutsceneRegistry.resolve_caption("chapter.ch1.title"), "Chapter 1: The Admission",
			"chapter caption is campaign.json's title")
	check_eq(CutsceneRegistry.resolve_caption("chapter.ch9.title"), "", "unknown references resolve to nothing")


func test_validation_rejects_invented_or_unsafe_content() -> void:
	var context: Dictionary = CutsceneRegistry.reference_context()
	var cases: Dictionary = {
		"line_id 'ch1_invented_line' is not an existing dialogue line": func(d: Dictionary) -> void: d["panels"][0]["line_id"] = "ch1_invented_line",
		"music.cue 'mus_unknown' is not in audio/cues.json": func(d: Dictionary) -> void: d["music"]["cue"] = "mus_unknown",
		"music.cue 'mus_temporal_fracture' is reserved": func(d: Dictionary) -> void: d["music"]["cue"] = "mus_temporal_fracture",
		"music.cue 'mus_final_revelation' is reserved": func(d: Dictionary) -> void: d["music"]["cue"] = "mus_final_revelation",
		"panels carry no literal text": func(d: Dictionary) -> void: d["panels"][0]["caption"] = "Welcome to Ward Zero",
		"caption_ref 'ward_zero.name' does not name approved campaign text": func(d: Dictionary) -> void: d["panels"][0]["caption_ref"] = "ward_zero.name",
		"missing texture res://assets/cutscenes/ch01_pilot/nope.png": func(d: Dictionary) -> void: d["panels"][0]["layers"][0]["texture"] = "res://assets/cutscenes/ch01_pilot/nope.png",
		"trigger.kind must be one of": func(d: Dictionary) -> void: d["trigger"] = {"kind": "story_beat", "beat_id": "ch1_start"},
		"mode must be one of": func(d: Dictionary) -> void: d["mode"] = "cinematic",
		"mode campaign goes with trigger chapter_start": func(d: Dictionary) -> void: d["mode"] = "campaign",
		"a campaign cutscene must be approved by the owner": func(d: Dictionary) -> void:
			d["mode"] = "campaign"
			d["trigger"] = {"kind": "chapter_start"},
		"duration_seconds must be positive": func(d: Dictionary) -> void: d["panels"][1]["duration_seconds"] = 0,
		"motion.pan_to must stay within": func(d: Dictionary) -> void: d["panels"][2]["motion"]["pan_to"] = [0.3, 0.0],
		"layers must hold 1 to 3 entries": func(d: Dictionary) -> void: d["panels"][3]["layers"] = [],
		"unknown chapter_id": func(d: Dictionary) -> void: d["chapter_id"] = "ch9",
	}
	check_eq(CutsceneRegistry.validate(_pilot(), context), [], "the unmodified pilot is valid")
	for expected: String in cases:
		var data: Dictionary = _pilot()
		(cases[expected] as Callable).call(data)
		check_contains(CutsceneRegistry.validate(data, context), expected, "validation catches: " + expected)


func test_existing_dialogue_line_is_accepted() -> void:
	var data: Dictionary = _pilot()
	data["panels"][4]["line_id"] = "ch1_b2_bennett_001"
	check_eq(CutsceneRegistry.validate(data, CutsceneRegistry.reference_context()), [],
			"a real Chapter 1 line id may be referenced")


func test_preview_argument() -> void:
	check_eq(CutsceneDirector.preview_request(PackedStringArray()), "", "no argument, no cutscene")
	check_eq(CutsceneDirector.preview_request(PackedStringArray(["--character-preview=staff_bennett"])), "",
			"other review arguments are ignored")
	check_eq(CutsceneDirector.preview_request(PackedStringArray(["--cutscene-preview=" + PILOT])), PILOT,
			"--cutscene-preview names the cutscene")


# --- Director ---------------------------------------------------------------------------

func test_unapproved_cutscene_never_plays_outside_review() -> void:
	var director: CutsceneDirector = _director(false)
	var context_before: String = AudioDirector.get_music_context()
	check(not director.play(PILOT), "play refuses an unapproved cutscene")
	check(not director.is_open, "nothing is shown")
	check_eq(_finished, ["%s:not_approved" % PILOT], "the refusal is reported")
	check_eq(AudioDirector.get_music_context(), context_before, "music is untouched")


func test_main_has_no_cutscene_without_the_preview_argument() -> void:
	var main: Node = await _main()
	var director: CutsceneDirector = main.get_node("CutsceneDirector")
	check(not director.review_mode, "review mode is off in a normal run")
	check(not director.is_open, "no cutscene starts with the campaign")
	EventBus.ui_panel_requested.emit(CutsceneDirector.PANEL_ID, {"cutscene_id": PILOT})
	check(not director.is_open, "a panel request cannot start the unapproved pilot")
	check(not TimeManager.is_paused(), "the clock keeps running")


func test_plays_every_panel_in_order_then_restores() -> void:
	var director: CutsceneDirector = _director(true)
	var started: Array[String] = []
	EventBus.cutscene_started.connect(func(id: String) -> void: started.append(id), CONNECT_ONE_SHOT)
	var mouse_before: Input.MouseMode = Input.mouse_mode
	check(director.play(PILOT), "the pilot plays in review mode")
	check_eq(started, [PILOT], "cutscene_started is emitted")
	check_eq(AudioDirector.get_music_context(), CutsceneDirector.MUSIC_CONTEXT_ID, "the cutscene's music context is active")
	var visited: Array[int] = [director.panel_index]
	var elapsed: float = 0.0
	while director.is_open and elapsed < 70.0:
		director.advance(STEP)
		elapsed += STEP
		if director.is_open and director.panel_index != visited.back():
			visited.append(director.panel_index)
	check_eq(visited, [0, 1, 2, 3, 4, 5, 6], "every panel shows once, in order")
	check(absf(elapsed - 52.0) < 0.2, "it runs for its authored length (%.1fs)" % elapsed)
	check_eq(_finished, ["%s:completed" % PILOT], "it finishes once, as completed")
	check_eq(AudioDirector.get_music_context(), "", "music returns to the location")
	check_eq(Input.mouse_mode, mouse_before, "the mouse mode is restored")
	check(not director.visible, "the overlay is hidden")
	check_eq(director.runtime_errors, [], "every panel texture loaded")


func test_skip_restores_once() -> void:
	var director: CutsceneDirector = _director(true)
	var closed: Array[String] = []
	var on_closed: Callable = func(panel_id: String) -> void: closed.append(panel_id)
	EventBus.ui_panel_closed.connect(on_closed)
	director.play(PILOT)
	director.advance(3.0)
	director.skip()
	director.skip()
	director.close()
	EventBus.ui_panel_closed.disconnect(on_closed)
	check_eq(_finished, ["%s:skipped" % PILOT], "skip finishes exactly once")
	check_eq(closed, [CutsceneDirector.PANEL_ID], "Main is told once to restore input")
	check_eq(AudioDirector.get_music_context(), "", "the music context ends on skip")
	check(not director.is_open and director.panel_index == -1, "the director is idle again")


func test_next_panel_and_replay() -> void:
	var director: CutsceneDirector = _director(true)
	director.play(PILOT)
	director.next_panel()
	director.next_panel()
	check_eq(director.panel_index, 2, "Enter moves one panel at a time")
	director.replay()
	check_eq(director.panel_index, 0, "replay returns to the first panel")
	for _i: int in 7:
		director.next_panel()
	check_eq(_finished, ["%s:completed" % PILOT], "advancing past the last panel completes it")
	director.replay()
	check(director.is_open and director.panel_index == 0, "replay after the end plays it again")


func test_invalid_or_unknown_cutscene_recovers() -> void:
	var director: CutsceneDirector = _director(true)
	check(not director.play("cs_does_not_exist"), "an unknown id does not play")
	check_contains(director.runtime_errors, "unknown cutscene", "the reason is recorded")
	var broken: Dictionary = _pilot()
	broken["panels"][0]["layers"][0]["texture"] = "res://assets/cutscenes/missing.png"
	check(not director.play_data(broken), "a cutscene with missing art does not play")
	check_eq(_finished, ["cs_does_not_exist:invalid", "%s:invalid" % PILOT], "both report invalid")
	check(not director.is_open, "nothing is left on screen")
	check(director.play(PILOT), "the director still works afterwards")


func test_runtime_texture_failure_falls_back_to_a_plain_panel() -> void:
	var director: CutsceneDirector = _director(true)
	var layer: Control = director._build_layer({"texture": "res://assets/cutscenes/missing.png", "parallax": 1.0},
			{"id": "p_missing"})
	check(layer is ColorRect, "a missing texture becomes a plain panel")
	check_contains(director.runtime_errors, "p_missing", "the failure is recorded")
	layer.free()


func test_interruptions_restore_the_game() -> void:
	var director: CutsceneDirector = _director(true)
	director.play(PILOT)
	EventBus.game_loaded.emit(1)
	check_eq(_finished, ["%s:interrupted" % PILOT], "loading a save ends the cutscene")
	director.play(PILOT)
	director.advance(200.0)
	check_eq(_finished.back(), "%s:timeout" % PILOT, "the watchdog ends a stuck cutscene")
	director.play(PILOT)
	runner.remove_child(director)
	check_eq(_finished.back(), "%s:interrupted" % PILOT, "leaving the tree ends it")
	check_eq(AudioDirector.get_music_context(), "", "music is handed back every time")
	runner.add_child(director)


func test_dialogue_line_plays_through_audio_director_and_stops_on_skip() -> void:
	var director: CutsceneDirector = _director(true)
	var shown: Array[String] = []
	var on_shown: Callable = func(line_id: String, _s: String, _t: String, _d: float) -> void: shown.append(line_id)
	EventBus.subtitle_shown.connect(on_shown)
	var data: Dictionary = _pilot()
	data["panels"][0]["line_id"] = "ch1_b2_bennett_001"
	director.play_data(data)
	EventBus.subtitle_shown.disconnect(on_shown)
	check_eq(shown, ["ch1_b2_bennett_001"], "the existing line's subtitle is shown")
	check((director.get_node("Root/Subtitle") as Label).text.contains("Naomi Bennett"),
			"the cutscene shows the subtitle above its panels")
	check(AudioDirector.is_dialogue_playing(), "the line is playing")
	director.skip()
	check(not AudioDirector.is_dialogue_playing(), "skip stops the line")


func test_reduce_motion_holds_panels_still() -> void:
	Settings.set_value("reduce_motion", true)
	var director: CutsceneDirector = _director(true)
	director.play(PILOT)
	director.advance(1.5)
	var layer: Control = director.get_node("Root/Panel_p01_staff_entry/Art").get_child(0)
	var first: Array = [layer.scale, layer.position]
	director.advance(5.0)
	check_eq([layer.scale, layer.position], first, "no push or pan with Reduce Motion")


func test_cutscene_writes_no_game_state() -> void:
	var main: Node = await _main()
	var before: Dictionary = SaveManager.capture_state()
	var director: CutsceneDirector = main.get_node("CutsceneDirector")
	director.review_mode = true
	EventBus.ui_panel_requested.emit(CutsceneDirector.PANEL_ID, {"cutscene_id": PILOT})
	var player: FirstPersonController = main.get_node("Player")
	check(director.is_open, "Main opens the cutscene as its top panel")
	check(not player.input_enabled, "the player cannot move during the cutscene")
	check(TimeManager.is_paused(), "the clock pauses during the cutscene")
	for _i: int in 600:
		director.advance(STEP)
	check(not director.is_open, "the cutscene ran to the end")
	check(player.input_enabled, "player input is restored")
	check(not TimeManager.is_paused(), "the clock runs again")
	check_eq(SaveManager.capture_state(), before, "story, clinical and save state are unchanged")


func test_title_card_plays_when_a_chapter_opens() -> void:
	var main: Node = await _main()
	var director: CutsceneDirector = main.get_node("CutsceneDirector")
	var chapter: ChapterDirector = main.get_node("ChapterDirector")
	check(not director.is_open, "no card while Chapter 1 runs")
	check(chapter.start_chapter("ch2"), "Chapter 2 starts")
	check(director.is_open, "the Chapter 2 title card opens")
	check_eq(director.cutscene_id, "cs_ch02_title", "it is Chapter 2's card")
	var player: FirstPersonController = main.get_node("Player")
	check(not player.input_enabled, "the player waits for the card")
	director.skip()
	check(not director.is_open, "skipping ends the card")
	check(player.input_enabled, "player input is restored after the card")


func test_chapter_recap_plays_over_the_end_of_chapter_panel() -> void:
	var main: Node = await _main()
	var director: CutsceneDirector = main.get_node("CutsceneDirector")
	var chapter: ChapterDirector = main.get_node("ChapterDirector")
	var info: InfoPanel = main.get_node("InfoPanel")
	var recap: String = CutsceneRegistry.chapter_complete_cutscene("ch1")
	chapter.set_flag(StoryLogic.CHAPTER_COMPLETE_FLAG)
	EventBus.ui_panel_requested.emit(InfoPanel.PANEL_ID, {"title": "End of chapter", "body": "Summary"})
	if recap.is_empty():
		check(not director.is_open, "no recap plays for Chapter 1 while none is approved")
		return
	check(director.is_open, "the Chapter 1 recap opens when the chapter is completed")
	check_eq(director.cutscene_id, recap, "it is Chapter 1's recap")
	check(info.is_open, "the end-of-chapter panel waits underneath")
	director.skip()
	check(not director.is_open, "skipping ends the recap")
	check(info.is_open, "the end-of-chapter panel is still there to continue from")


func test_chapter_complete_trigger_needs_owner_approval() -> void:
	var context: Dictionary = CutsceneRegistry.reference_context()
	var data: Dictionary = _pilot()
	data["mode"] = "campaign"
	data["trigger"] = {"kind": "chapter_complete"}
	check_contains(CutsceneRegistry.validate(data, context), "a campaign cutscene must be approved by the owner",
			"an unapproved recap is refused")
	data["approved"] = true
	check_eq(CutsceneRegistry.validate(data, context), [], "an approved recap validates")
	data["mode"] = "review_only"
	check_contains(CutsceneRegistry.validate(data, context), "mode campaign goes with trigger",
			"a review-only cutscene cannot use a campaign trigger")


# --- Helpers --------------------------------------------------------------------------------

func _director(review: bool) -> CutsceneDirector:
	var director: CutsceneDirector = DIRECTOR_SCENE.instantiate() as CutsceneDirector
	director.review_mode = review
	runner.add_child(director)
	director.set_process(false) # Tests step time with advance().
	director.finished.connect(func(id: String, reason: String) -> void: _finished.append("%s:%s" % [id, reason]))
	_roots.append(director)
	return director


func _main() -> Node:
	var main: Node = load(MAIN_SCENE).instantiate()
	runner.add_child(main)
	_roots.append(main)
	await runner.get_tree().process_frame
	(main.get_node("CutsceneDirector") as CutsceneDirector).set_process(false)
	return main


func _pilot() -> Dictionary:
	return (JSON.parse_string(FileAccess.get_file_as_string("res://data/cutscenes/%s.json" % PILOT)) as Dictionary)
