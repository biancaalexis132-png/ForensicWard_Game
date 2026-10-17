class_name PauseMenu
extends CanvasLayer
## PauseMenu: pauses the scene tree; offers resume, manual save/load,
## accessibility toggles and quit. process_mode is ALWAYS so it works while
## the tree is paused. Main decides when to open it (Esc with no panel open).

signal closed

const SAVE_SLOT: int = 1

## CheckBox node name -> Settings key.
const TOGGLES: Dictionary = {
	"ReduceMotion": "reduce_motion",
	"VisualEffects": "visual_effects",
	"FlashEffects": "flash_effects",
	"Subtitles": "subtitles",
	"InvertY": "invert_y",
}

@onready var _status: Label = $Root/Panel/Margin/VBox/Status
@onready var _toggles: VBoxContainer = $Root/Panel/Margin/VBox/Accessibility
@onready var _sensitivity: HSlider = $Root/Panel/Margin/VBox/Sensitivity/Slider
@onready var _resume_button: Button = $Root/Panel/Margin/VBox/Resume

var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(close)
	$Root/Panel/Margin/VBox/Save.pressed.connect(_on_save)
	$Root/Panel/Margin/VBox/Load.pressed.connect(_on_load)
	$Root/Panel/Margin/VBox/Quit.pressed.connect(func() -> void: get_tree().quit())
	for node_name: String in TOGGLES:
		var box: CheckBox = _toggles.get_node(node_name)
		var key: String = TOGGLES[node_name]
		box.toggled.connect(func(pressed: bool) -> void: Settings.set_value(key, pressed))
	_sensitivity.value_changed.connect(func(value: float) -> void: Settings.set_value("mouse_sensitivity", value))


func open() -> void:
	for node_name: String in TOGGLES:
		(_toggles.get_node(node_name) as CheckBox).set_pressed_no_signal(Settings.get_value(TOGGLES[node_name]))
	_sensitivity.set_value_no_signal(Settings.get_value("mouse_sensitivity"))
	_status.text = "Saved game available." if SaveManager.has_save(SAVE_SLOT) else "No saved game yet."
	visible = true
	is_open = true
	get_tree().paused = true
	_resume_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _on_save() -> void:
	var error: Error = SaveManager.save_game(SAVE_SLOT)
	_status.text = "Game saved." if error == OK else "Save failed: %s" % error_string(error)


func _on_load() -> void:
	var error: Error = SaveManager.load_game(SAVE_SLOT)
	if error == OK:
		_status.text = "Game loaded."
		close()
	else:
		_status.text = "Load failed: %s" % error_string(error)
