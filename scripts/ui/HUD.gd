class_name HUD
extends CanvasLayer
## HUD: crosshair, interaction prompt, clock, toast notifications, the
## current chapter objective and dialogue subtitles (when enabled in
## Settings). Reads only EventBus signals and TimeManager; owns no game state.

const TOAST_SECONDS: float = 3.5
const MAX_TOASTS: int = 4

@onready var _crosshair: Control = $Root/Crosshair
@onready var _prompt: Label = $Root/Prompt
@onready var _clock: Label = $Root/Clock
@onready var _toasts: VBoxContainer = $Root/Toasts

var objective_text: String = ""
var subtitle_text: String = ""

var _objective: Label
var _subtitle: Label
var _subtitle_box: StyleBoxFlat
var _subtitle_speaker: String = ""
var _subtitle_line: String = ""

const SUBTITLE_FONT_SIZE: int = 24


func _ready() -> void:
	EventBus.interaction_focus_changed.connect(_on_focus_changed)
	EventBus.notification_requested.connect(show_toast)
	EventBus.time_advanced.connect(func(_t: int, _d: int, _r: String) -> void: _update_clock())
	EventBus.game_loaded.connect(func(_slot: int) -> void: _update_clock())
	EventBus.objective_changed.connect(_on_objective_changed)
	EventBus.subtitle_shown.connect(_on_subtitle_shown)
	EventBus.subtitle_cleared.connect(func(_line_id: String) -> void: _set_subtitle("", ""))
	_objective = _overlay_label(20, HORIZONTAL_ALIGNMENT_LEFT)
	_objective.anchor_top = 1.0
	_objective.anchor_bottom = 1.0
	_objective.offset_left = 24.0
	_objective.offset_right = 760.0
	_objective.offset_top = -64.0
	_objective.offset_bottom = -24.0
	_subtitle = _overlay_label(24, HORIZONTAL_ALIGNMENT_CENTER)
	_subtitle.anchor_left = 0.15
	_subtitle.anchor_right = 0.85
	_subtitle.anchor_top = 1.0
	_subtitle.anchor_bottom = 1.0
	_subtitle.offset_top = -170.0
	_subtitle.offset_bottom = -90.0
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_subtitle.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_subtitle_box = StyleBoxFlat.new()
	_subtitle_box.bg_color = Color(0.0, 0.0, 0.0, 0.62)
	_subtitle_box.set_content_margin_all(10.0)
	_subtitle_box.set_corner_radius_all(4)
	EventBus.settings_changed.connect(func(key: String, _value: Variant) -> void:
		if key.begins_with("subtitle"):
			_set_subtitle(_subtitle_speaker, _subtitle_line))
	_prompt.text = ""
	_update_clock()


## Hides the crosshair and prompt while a panel or menu is open.
func set_world_hud_visible(shown: bool) -> void:
	_crosshair.visible = shown
	_prompt.visible = shown


func show_toast(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.9))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	_toasts.add_child(label)
	while _toasts.get_child_count() > MAX_TOASTS:
		_toasts.get_child(0).free()
	var tween: Tween = label.create_tween()
	tween.tween_interval(TOAST_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)


func _overlay_label(size: int, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.94))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(label)
	return label


func _on_objective_changed(_objective_id: String, text: String) -> void:
	objective_text = text
	_objective.text = "" if text.is_empty() else "Objective: " + text
	if not text.is_empty():
		show_toast("New objective: " + text)


func _on_subtitle_shown(_line_id: String, speaker: String, text: String, _duration: float) -> void:
	_set_subtitle(speaker, text)


## Applies the subtitle settings: on/off, speaker names, background and size.
func _set_subtitle(speaker: String, text: String) -> void:
	_subtitle_speaker = speaker
	_subtitle_line = text
	var named: bool = not speaker.is_empty() and Settings.get_value("subtitle_speaker_names")
	subtitle_text = "%s: %s" % [speaker, text] if named else text
	var shown: bool = Settings.get_value("subtitles") and not text.is_empty()
	_subtitle.text = subtitle_text if shown else ""
	_subtitle.add_theme_font_size_override("font_size", roundi(SUBTITLE_FONT_SIZE * float(Settings.get_value("subtitle_scale"))))
	if shown and Settings.get_value("subtitle_background"):
		_subtitle.add_theme_stylebox_override("normal", _subtitle_box)
	else:
		_subtitle.remove_theme_stylebox_override("normal")


func _on_focus_changed(prompt: String) -> void:
	_prompt.text = "" if prompt.is_empty() else "[E]  " + prompt


func _update_clock() -> void:
	_clock.text = "%s  ·  %s shift" % [TimeManager.get_clock_string(), TimeManager.get_shift().capitalize()]
