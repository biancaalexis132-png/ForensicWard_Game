class_name PauseMenu
extends CanvasLayer
## PauseMenu: pauses the scene tree; offers resume, manual save/load,
## accessibility toggles, audio volumes and quit. process_mode is ALWAYS so it works while
## the tree is paused. Main decides when to open it (Esc with no panel open).

signal closed

const SAVE_SLOT: int = 1

## CheckBox node name -> Settings key.
const TOGGLES: Dictionary = {
	"ReduceMotion": "reduce_motion",
	"VisualEffects": "visual_effects",
	"FlashEffects": "flash_effects",
	"Subtitles": "subtitles",
	"RecapNarration": "recap_narration",
	"InvertY": "invert_y",
}

## Toggles added in code (CheckBox name -> Settings key), listed after the scene's own.
const EXTRA_TOGGLES: Dictionary = {
	"SubtitleSpeakerNames": ["subtitle_speaker_names", "Subtitles: show speaker names"],
	"SubtitleBackground": ["subtitle_background", "Subtitles: background box"],
	"ObjectiveChecklist": ["objective_checklist", "Objectives: show checklist"],
	"ObjectiveBanners": ["objective_banners", "Objectives: show banners"],
	"ObjectiveSound": ["objective_sound", "Objectives: completion chime"],
}

## HSlider node name (under Audio) -> AudioDirector volume setting (linear 0..1).
const VOLUMES: Dictionary = {
	"Master": "volume_master",
	"Music": "volume_music",
	"Voice": "volume_voice",
	"Effects": "volume_sfx",
	"Ambience": "volume_ambient",
}

@onready var _status: Label = $Root/Panel/Margin/VBox/Status
@onready var _toggles: VBoxContainer = $Root/Panel/Margin/VBox/Accessibility
@onready var _sensitivity: HSlider = $Root/Panel/Margin/VBox/Sensitivity/Slider
@onready var _resume_button: Button = $Root/Panel/Margin/VBox/Resume
@onready var _volumes: GridContainer = $Root/Panel/Margin/VBox/Audio
@onready var _reduce_startle: CheckBox = $Root/Panel/Margin/VBox/Accessibility/ReduceStartlingAudio

var is_open: bool = false
var _subtitle_size: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(close)
	var replay_button: Button = Button.new()
	replay_button.name = "ReplayRecap"
	replay_button.text = "Replay latest completed chapter recap"
	_resume_button.get_parent().add_child(replay_button)
	_resume_button.get_parent().move_child(replay_button, _resume_button.get_index() + 1)
	replay_button.pressed.connect(func() -> void:
		close()
		EventBus.ui_panel_requested.emit("cutscene", {"replay_completed": true}))
	# The fiction disclaimer lives here and on the title screen, not inside the EHR.
	var disclaimer: Label = Label.new()
	disclaimer.name = "Disclaimer"
	disclaimer.text = TitleScreen.DISCLAIMER
	disclaimer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disclaimer.add_theme_font_size_override("font_size", 13)
	disclaimer.modulate = Color(0.75, 0.77, 0.8)
	$Root/Panel/Margin/VBox.add_child(disclaimer)
	$Root/Panel/Margin/VBox/Save.pressed.connect(_on_save)
	$Root/Panel/Margin/VBox/Load.pressed.connect(_on_load)
	# Same path as closing the window: Main stops audio first, then quits.
	$Root/Panel/Margin/VBox/Quit.pressed.connect(func() -> void:
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST))
	for node_name: String in TOGGLES:
		var box: CheckBox = _toggles.get_node(node_name)
		var key: String = TOGGLES[node_name]
		box.toggled.connect(func(pressed: bool) -> void: Settings.set_value(key, pressed))
	for node_name: String in EXTRA_TOGGLES:
		var extra: CheckBox = CheckBox.new()
		extra.name = node_name
		extra.text = EXTRA_TOGGLES[node_name][1]
		_toggles.add_child(extra)
		var extra_key: String = EXTRA_TOGGLES[node_name][0]
		extra.toggled.connect(func(pressed: bool) -> void: Settings.set_value(extra_key, pressed))
	var size_row: HBoxContainer = HBoxContainer.new()
	size_row.name = "SubtitleSize"
	var size_label: Label = Label.new()
	size_label.text = "Subtitle size"
	size_label.custom_minimum_size.x = 160
	size_row.add_child(size_label)
	_subtitle_size = HSlider.new()
	_subtitle_size.name = "Slider"
	_subtitle_size.min_value = 0.8
	_subtitle_size.max_value = 1.6
	_subtitle_size.step = 0.1
	_subtitle_size.custom_minimum_size.x = 220
	_subtitle_size.value_changed.connect(func(value: float) -> void: Settings.set_value("subtitle_scale", value))
	size_row.add_child(_subtitle_size)
	_toggles.add_child(size_row)
	_sensitivity.value_changed.connect(func(value: float) -> void: Settings.set_value("mouse_sensitivity", value))
	# Audio settings belong to AudioDirector, which applies and saves them.
	for node_name: String in VOLUMES:
		var key: String = VOLUMES[node_name]
		(_volumes.get_node(node_name) as HSlider).value_changed.connect(
				func(value: float) -> void: AudioDirector.set_setting(key, value))
	_reduce_startle.toggled.connect(func(pressed: bool) -> void:
		AudioDirector.set_setting("reduce_startling_audio", pressed))


func open() -> void:
	for node_name: String in TOGGLES:
		(_toggles.get_node(node_name) as CheckBox).set_pressed_no_signal(Settings.get_value(TOGGLES[node_name]))
	for node_name: String in EXTRA_TOGGLES:
		(_toggles.get_node(node_name) as CheckBox).set_pressed_no_signal(Settings.get_value(EXTRA_TOGGLES[node_name][0]))
	_subtitle_size.set_value_no_signal(Settings.get_value("subtitle_scale"))
	_sensitivity.set_value_no_signal(Settings.get_value("mouse_sensitivity"))
	for node_name: String in VOLUMES:
		(_volumes.get_node(node_name) as HSlider).set_value_no_signal(AudioDirector.get_setting(VOLUMES[node_name]))
	_reduce_startle.set_pressed_no_signal(AudioDirector.get_setting("reduce_startling_audio"))
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
