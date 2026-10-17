class_name HUD
extends CanvasLayer
## HUD: crosshair, interaction prompt, clock and toast notifications.
## Reads only EventBus signals and TimeManager; owns no game state.

const TOAST_SECONDS: float = 3.5
const MAX_TOASTS: int = 4

@onready var _crosshair: Control = $Root/Crosshair
@onready var _prompt: Label = $Root/Prompt
@onready var _clock: Label = $Root/Clock
@onready var _toasts: VBoxContainer = $Root/Toasts


func _ready() -> void:
	EventBus.interaction_focus_changed.connect(_on_focus_changed)
	EventBus.notification_requested.connect(show_toast)
	EventBus.time_advanced.connect(func(_t: int, _d: int, _r: String) -> void: _update_clock())
	EventBus.game_loaded.connect(func(_slot: int) -> void: _update_clock())
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


func _on_focus_changed(prompt: String) -> void:
	_prompt.text = "" if prompt.is_empty() else "[E]  " + prompt


func _update_clock() -> void:
	_clock.text = "%s  ·  %s shift" % [TimeManager.get_clock_string(), TimeManager.get_shift().capitalize()]
