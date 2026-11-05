extends TestCase
## Presentation: the title screen's Settings, bounded preload and loading
## status; the review-only prologue and the new_game trigger; and Main's
## presentation states, each restoring input, mouse, clock and HUD on exit.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const PROLOGUE: String = "cs_ch01_prologue"

var _main: Node3D = null
var _states: Array[String] = []


func before_each() -> void:
	super.before_each()
	_states.clear()
	EventBus.presentation_state_changed.connect(_on_state)
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	EventBus.presentation_state_changed.disconnect(_on_state)
	runner.get_tree().paused = false
	AudioDirector.cancel_pending_events()
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func _on_state(state: String) -> void:
	_states.append(state)


# --- Title screen ---------------------------------------------------------------

func test_title_buttons_order_and_background_art() -> void:
	var title: TitleScreen = _main.get_node("TitleScreen")
	var labels: Array = title.find_children("*", "Button", true, false).map(func(b: Button) -> String: return b.text)
	check_eq(labels, ["New Game", "Customize new psychiatrist", "Continue", "Settings", "Quit"], "menu order including optional new-game customization")
	var art: TextureRect = title.find_child("BackgroundArt", true, false)
	check(art != null and art.texture != null, "approved Chapter 1 art behind the menu")


func test_title_preload_is_bounded_and_reports_status() -> void:
	var title: TitleScreen = _main.get_node("TitleScreen")
	var paths: Array[String] = TitleScreen.preload_paths()
	check(paths.size() <= TitleScreen.MAX_PRELOAD, "at most MAX_PRELOAD paths")
	check(not paths.is_empty(), "something to preload")
	title.open()
	check("Preparing the ward" in title.get_loading_text() or title.get_loading_text() == "Ready.", "status shown")
	await _wait_until(func() -> bool: return not title.is_loading())
	check_eq(title.get_loading_text(), "Ready.", "ready once loaded")
	check(not title._new_button.disabled, "New Game enabled once loaded")
	var too_many: Array[String] = []
	for i: int in 20:
		too_many.append(paths[0])
	title.start_preload(too_many)
	check(title._preload_total <= TitleScreen.MAX_PRELOAD, "never more than MAX_PRELOAD in flight")
	await _wait_until(func() -> bool: return not title.is_loading())
	title.close()


func test_settings_from_title_stays_paused_and_hides_in_game_rows() -> void:
	var title: TitleScreen = _main.get_node("TitleScreen")
	var pause: PauseMenu = _main.get_node("PauseMenu")
	title.open()
	title.settings_requested.emit()
	check(pause.is_open and pause.from_title, "settings open over the title")
	check(pause.layer > title.layer, "drawn above the title")
	check(not pause.get_node("Root/Panel/Scroll/Margin/VBox/Save").visible, "no Save from the title")
	pause.close()
	check(runner.get_tree().paused, "back at the title, the game stays paused")
	check(title.is_open, "title still open")
	pause.open()
	check(pause.get_node("Root/Panel/Scroll/Margin/VBox/Save").visible, "in-game pause menu shows Save again")
	pause.close()
	title.close()


# --- Prologue -------------------------------------------------------------------

func test_prologue_is_valid_approved_and_safe() -> void:
	var errors: Array[String] = []
	var data: Dictionary = CutsceneRegistry.get_cutscene(PROLOGUE, errors)
	check_eq(errors, [] as Array[String], "prologue validates")
	check_eq(data["panels"].size(), 5, "five panels")
	check(data["approved"] and data["mode"] == "campaign", "owner approved 2026-10-21")
	check_eq(data["trigger"], {"kind": "new_game"}, "plays on New Game")
	check_eq(CutsceneRegistry.new_game_cutscene("ch1"), PROLOGUE, "New Game finds the prologue")
	for panel: Dictionary in data["panels"]:
		check_eq(float(panel["transition_seconds"]), 1.5, "1.5 s transitions")
		check(AudioDirector.get_voice_stream(str(panel["line_id"])) != null, "narrated: " + panel["id"])
		var text: String = AudioDirector.get_line(str(panel["line_id"]))["text"]
		check(not "Ward Zero" in text and not "Elias" in text, "no early reveal or recap: " + panel["id"])
		for layer: Dictionary in panel["layers"]:
			check(not "static_gn_v1" in str(layer["texture"]), "does not reuse the Chapter 1 recap pages")
			check(not "naomi" in str(layer["texture"]), "leaves out the unapproved likeness")


func test_new_game_trigger_plays_an_approved_prologue_once() -> void:
	var data: Dictionary = CutsceneRegistry.get_cutscene(PROLOGUE).duplicate(true)
	data["mode"] = "campaign"
	data["approved"] = true
	data["trigger"] = {"kind": "new_game"}
	check_eq(CutsceneRegistry.validate(data, CutsceneRegistry.reference_context()), [] as Array[String],
			"new_game is a valid campaign trigger")
	await runner.get_tree().process_frame  # The opening objective is announced first.
	await runner.get_tree().process_frame
	var before: Dictionary = SaveManager.capture_state()
	var cutscene: CutsceneDirector = _main.get_node("CutsceneDirector")
	check(cutscene.play_data(data), "approved prologue plays")
	_main.call("_update_input_mode")
	check_eq((_main as Main).get_presentation_state(), Main.PROLOGUE, "prologue state")
	check(not (_main.get_node("Player") as FirstPersonController).input_enabled, "the prologue owns input")
	cutscene.skip()
	check_eq((_main as Main).get_presentation_state(), Main.GAMEPLAY, "back to gameplay")
	check((_main.get_node("Player") as FirstPersonController).input_enabled, "player input restored")
	check(not TimeManager.is_paused(), "clock running again")
	var after: Dictionary = SaveManager.capture_state()
	check_eq(after, before, "the prologue writes no game state")
	await _release_prologue_audio()


# --- Presentation states -------------------------------------------------------------

func test_title_then_gameplay_states() -> void:
	var title: TitleScreen = _main.get_node("TitleScreen")
	title.open()
	_main.call("_update_input_mode")
	check_eq((_main as Main).get_presentation_state(), Main.TITLE, "title state")
	await _wait_until(func() -> bool: return not title.is_loading())
	title.new_game()
	check_eq((_main as Main).get_presentation_state(), Main.PROLOGUE, "the approved prologue follows New Game")
	check(not (_main.get_node("Player") as FirstPersonController).input_enabled, "the prologue owns input")
	(_main.get_node("CutsceneDirector") as CutsceneDirector).skip()
	check_eq((_main as Main).get_presentation_state(), Main.GAMEPLAY, "gameplay after the prologue")
	check_eq(_states, [Main.TITLE, Main.PROLOGUE, Main.GAMEPLAY] as Array[String], "each change announced once")
	check((_main.get_node("Player") as FirstPersonController).input_enabled, "player input restored")
	check(not TimeManager.is_paused(), "clock running again")
	check((_main.get_node("HUD") as HUD).get_node("Root/Crosshair").visible, "HUD back")
	await _release_prologue_audio()


func test_chapter_complete_then_recap_then_gameplay() -> void:
	var director: ChapterDirector = _main.get_node("ChapterDirector")
	director.set_flag(StoryLogic.CHAPTER_COMPLETE_FLAG)
	await runner.get_tree().process_frame
	(_main.get_node("CutsceneDirector") as CutsceneDirector).skip()  # The approved Chapter 1 recap.
	EventBus.ui_panel_requested.emit("info", {"title": "End of chapter", "body": "Test."})
	check_eq((_main as Main).get_presentation_state(), Main.CHAPTER_COMPLETE, "end-of-chapter panel")
	(_main.get_node("InfoPanel") as InfoPanel).close()
	check_eq((_main as Main).get_presentation_state(), Main.GAMEPLAY, "gameplay once it closes")
	check(_states.has(Main.CHAPTER_RECAP), "the recap played as its own state")
	check(not TimeManager.is_paused(), "clock restored")


## The skipped prologue's voice and music fade out; let them finish before teardown.
func _release_prologue_audio() -> void:
	AudioDirector.stop_music(0.01)
	await runner.get_tree().create_timer(0.3).timeout


func _wait_until(condition: Callable, max_seconds: float = 10.0) -> void:
	var waited: float = 0.0
	while waited < max_seconds:
		if condition.call():
			return
		await runner.get_tree().create_timer(0.05, true, false, true).timeout
		waited += 0.05
	check(false, "timed out waiting")
