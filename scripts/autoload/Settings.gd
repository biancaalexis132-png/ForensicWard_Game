extends Node
## Settings: player preferences and accessibility options (Autoload "Settings").
##
## Stored in user://settings.cfg, separate from save games, so accessibility
## choices apply to every save. GDD §11: each effect category can be
## disabled independently, and no required information depends on audio or
## visual effects alone.

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "settings"

const DEFAULTS: Dictionary = {
	"mouse_sensitivity": 0.12, ## Degrees per mouse pixel.
	"invert_y": false,
	"reduce_motion": false,    ## Disables head bob and camera sway.
	"visual_effects": true,    ## Psychosomatic Bleed distortion (later sprints).
	"chromatic_distortion": true,
	"flash_effects": true,     ## Flickering lights and flashes.
	"subtitles": true,
	"subtitle_speaker_names": true, ## Prefix subtitles with who is speaking.
	"subtitle_background": true,    ## Dark box behind subtitles for contrast.
	"subtitle_scale": 1.0,          ## Subtitle text size multiplier (0.8 to 1.6).
	"recap_narration": true,    ## Voice-over is optional; recap captions remain.
	"text_scale": 1.0,
	"perf_log": false,         ## Debug: ZoneDirector writes user://perf_log.csv around zone transitions.
}
## Audio volumes and audio accessibility (reduce startling audio, music
## intensity) are owned by AudioDirector (systems/audio), not here.

## Tests set this to false so they never overwrite the player's settings file.
var persist: bool = true

var _values: Dictionary = {}


func _ready() -> void:
	_values = DEFAULTS.duplicate()
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		for key: String in DEFAULTS:
			var stored: Variant = config.get_value(SECTION, key, DEFAULTS[key])
			if typeof(stored) == typeof(DEFAULTS[key]):
				_values[key] = stored
	_apply_all()


func get_value(key: String) -> Variant:
	assert(DEFAULTS.has(key), "Unknown setting '%s'" % key)
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_error("Settings: unknown setting '%s'" % key)
		return
	if typeof(value) != typeof(DEFAULTS[key]):
		# Sliders give floats for int-like values and vice versa; coerce numbers.
		if typeof(DEFAULTS[key]) == TYPE_FLOAT and (value is int or value is float):
			value = float(value)
		else:
			push_error("Settings: '%s' expects %s" % [key, type_string(typeof(DEFAULTS[key]))])
			return
	if _values.get(key) == value:
		return
	_values[key] = value
	_apply(key)
	if persist:
		_save()
	EventBus.settings_changed.emit(key, value)


func reset_to_defaults() -> void:
	for key: String in DEFAULTS:
		set_value(key, DEFAULTS[key])


func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	for key: String in _values:
		config.set_value(SECTION, key, _values[key])
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("Settings: could not save %s (%s)" % [SETTINGS_PATH, error_string(error)])


func _apply_all() -> void:
	for key: String in _values:
		_apply(key)


## Hook for settings that change engine state when applied. None do yet:
## visual/flash toggles are read by the systems that use them.
func _apply(_key: String) -> void:
	pass
