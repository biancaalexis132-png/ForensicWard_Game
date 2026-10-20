class_name TitleScreen
extends CanvasLayer
## TitleScreen: the first thing a player sees. New Game starts Chapter 1 as
## Main already set it up, Continue loads the manual save (slot 1, the same one
## the pause menu uses) and Quit leaves through Main's graceful quit.
##
## It pauses the scene tree while open (process_mode ALWAYS, like PauseMenu)
## and writes no story, clinical or save state itself. Main opens it at boot
## only when it is the running scene in a window, so tests, headless QA and
## the --cutscene-preview / --character-preview review arguments skip it.

signal closed

const GAME_TITLE: String = "The Forensic Ward"
## Shown here and in the pause menu instead of on clinical screens.
const DISCLAIMER: String = "A work of fiction. All patients, staff, records and events are invented. This game is not clinical software and gives no medical advice."
const BACKGROUND: Color = Color(0.035, 0.04, 0.05)
const TEXT: Color = Color(0.93, 0.91, 0.85)
const MUTED: Color = Color(0.6, 0.62, 0.64)

var is_open: bool = false
## The pause menu's manual save slot. Tests point it at their own slot.
var save_slot: int = PauseMenu.SAVE_SLOT

var _continue_button: Button
var _new_button: Button
var _status: Label


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
	var has_save: bool = SaveManager.has_save(save_slot)
	_continue_button.disabled = not has_save
	_status.text = ""
	visible = true
	is_open = true
	get_tree().paused = true
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
	close()


func continue_game() -> void:
	var error: Error = SaveManager.load_game(save_slot)
	if error == OK:
		close()
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
	_continue_button = _button(column, "Continue", continue_game)
	_new_button = _button(column, "New Game", new_game)
	_button(column, "Quit", func() -> void:
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST))
	_status = _label("", 16, MUTED)
	column.add_child(_status)
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
