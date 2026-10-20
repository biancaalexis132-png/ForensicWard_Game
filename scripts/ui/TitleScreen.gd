class_name TitleScreen
extends CanvasLayer
## TitleScreen: the first thing a player sees. New Game starts Chapter 1 as
## Main already set it up (Main then plays the approved prologue, if any),
## Continue loads the manual save (slot 1, the same one the pause menu uses),
## Settings opens the pause menu's settings over the title, and Quit leaves
## through Main's graceful quit.
##
## While open it shows approved Chapter 1 art and preloads a short, bounded
## list of what the first minutes need (threaded, never more than
## MAX_PRELOAD items, so an 8 GB Mac is not asked to hold more), with a
## visible status line. The buttons wait for it, up to PRELOAD_TIMEOUT.
##
## It pauses the scene tree while open (process_mode ALWAYS, like PauseMenu)
## and writes no story, clinical or save state itself. Main opens it at boot
## only when it is the running scene in a window, so tests, headless QA and
## the --cutscene-preview / --character-preview review arguments skip it.

signal closed
signal new_game_started
signal settings_requested

const GAME_TITLE: String = "The Forensic Ward"
## Shown here and in the pause menu instead of on clinical screens.
const DISCLAIMER: String = "A work of fiction. All patients, staff, records and events are invented. This game is not clinical software and gives no medical advice."
const BACKGROUND: Color = Color(0.035, 0.04, 0.05)
const TEXT: Color = Color(0.93, 0.91, 0.85)
const MUTED: Color = Color(0.6, 0.62, 0.64)
## Owner-approved Chapter 1 art (static graphic novel v1), shown unchanged and dimmed.
const BACKGROUND_ART: String = "res://assets/cutscenes/static_gn_v1/ch01/chapter_01_panel_01.png"
const MAX_PRELOAD: int = 6
const PRELOAD_TIMEOUT: float = 10.0

var is_open: bool = false
## The pause menu's manual save slot. Tests point it at their own slot.
var save_slot: int = PauseMenu.SAVE_SLOT

var _continue_button: Button
var _new_button: Button
var _settings_button: Button
var _status: Label
var _loading: Label
## Paths still loading in the background, and how many the preload started with.
var _preloading: Array[String] = []
var _preload_total: int = 0
var _preload_time: float = 0.0
## Kept so the loaded resources stay cached until the game starts.
var _preloaded: Array[Resource] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	visible = false
	_build()


## Whether Main should show the title at boot.
static func wanted(main: Node) -> bool:
	if DisplayServer.get_name() == "headless" or main != main.get_tree().current_scene:
		return false
	for arg: String in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--") and "-preview" in arg:
			return false
	return true


func open() -> void:
	_status.text = ""
	visible = true
	is_open = true
	get_tree().paused = true
	start_preload(preload_paths())
	_update_buttons()


## What the first minutes of a new game need, at most MAX_PRELOAD paths:
## the prologue's first panels if the owner approved one, then the charge
## nurse's first line.
static func preload_paths() -> Array[String]:
	var paths: Array[String] = []
	var prologue: String = CutsceneRegistry.new_game_cutscene(ContentRegistry.get_start_chapter_id())
	if not prologue.is_empty():
		for panel: Dictionary in CutsceneRegistry.get_cutscene(prologue).get("panels", []).slice(0, 2):
			for layer: Dictionary in panel["layers"]:
				if not str(layer["texture"]) in paths:
					paths.append(str(layer["texture"]))
	var bennett: Dictionary = ContentRegistry.get_staff("staff_bennett")
	var line_id: String = AudioDirector.find_line("staff_bennett", str(bennett.get("intro_line", "")))
	var clip: String = "res://audio/voice/ch1/%s.ogg" % line_id
	if not line_id.is_empty() and ResourceLoader.exists(clip):
		paths.append(clip)
	return paths.slice(0, MAX_PRELOAD)


func start_preload(paths: Array[String]) -> void:
	_preloading.clear()
	_preload_time = 0.0
	for path: String in paths.slice(0, MAX_PRELOAD):
		if ResourceLoader.load_threaded_request(path) == OK:
			_preloading.append(path)
	_preload_total = _preloading.size()
	_update_loading()


func is_loading() -> bool:
	return not _preloading.is_empty()


func get_loading_text() -> String:
	return _loading.text


func _process(delta: float) -> void:
	if not is_open or _preloading.is_empty():
		return
	_preload_time += delta
	for path: String in _preloading.duplicate():
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_preloaded.append(ResourceLoader.load_threaded_get(path))
			_preloading.erase(path)
		elif status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			push_warning("TitleScreen: could not preload %s" % path)
			_preloading.erase(path)
	if _preload_time > PRELOAD_TIMEOUT:
		_preloading.clear()  # Never hold the player at the title; the rest loads on demand.
	_update_loading()
	_update_buttons()


func _update_loading() -> void:
	if _preloading.is_empty():
		_loading.text = "Ready."
	else:
		_loading.text = "Preparing the ward… %d of %d" % [_preload_total - _preloading.size(), _preload_total]


func _update_buttons() -> void:
	var waiting: bool = is_loading()
	var has_save: bool = SaveManager.has_save(save_slot)
	_new_button.disabled = waiting
	_continue_button.disabled = waiting or not has_save
	if not waiting and not _continue_button.has_focus() and not _new_button.has_focus() and not _settings_button.has_focus():
		(_continue_button if has_save else _new_button).grab_focus()


## Freed while open (scene change, quit to a new Main, tests): leave the tree running.
func _exit_tree() -> void:
	if is_open:
		get_tree().paused = false


func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	get_tree().paused = false
	closed.emit()


func new_game() -> void:
	if not is_open:
		return
	close()
	_preloaded.clear()
	new_game_started.emit()


func continue_game() -> void:
	var error: Error = SaveManager.load_game(save_slot)
	if error == OK:
		close()
		_preloaded.clear()
	else:
		_status.text = "The saved game could not be loaded (%s)." % error_string(error)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	if ResourceLoader.exists(BACKGROUND_ART):
		var art := TextureRect.new()
		art.name = "BackgroundArt"
		art.texture = load(BACKGROUND_ART)
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.modulate = Color(0.32, 0.32, 0.34)  # Dimmed so the menu stays readable.
		root.add_child(art)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.custom_minimum_size = Vector2(420, 0)
	center.add_child(column)
	column.add_child(_label(GAME_TITLE, 52, TEXT))
	var campaign: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
	var institution: String = ""
	if campaign is Dictionary:
		institution = str(((campaign as Dictionary).get("institution", {}) as Dictionary).get("name", ""))
	column.add_child(_label(institution, 20, MUTED))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 36)
	column.add_child(gap)
	_new_button = _button(column, "New Game", new_game)
	_continue_button = _button(column, "Continue", continue_game)
	_settings_button = _button(column, "Settings", func() -> void: settings_requested.emit())
	_button(column, "Quit", func() -> void:
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST))
	_status = _label("", 16, MUTED)
	column.add_child(_status)
	_loading = _label("", 15, MUTED)
	_loading.name = "Loading"
	column.add_child(_loading)
	var disclaimer: Label = _label(DISCLAIMER, 13, MUTED)
	disclaimer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(disclaimer)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
