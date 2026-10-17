extends Node
## AudioDirector — adaptive audio engine (Autoload singleton, registered as "AudioDirector").
##
## Owns every long-lived audio player and the bus layout. Content lives in data:
##   res://audio/cues.json         cues (streams + bus + flags), locations, events
##   res://data/narrative/*.json   dialogue lines; clips at audio/voice/<chapter>/<line_id>.ogg
##   res://audio/music_ai/music_cues.json  optional: AI-generated score (cues + music
##                                 states), kept separate from procedural assets
##
## Features: location ambience with day/night variants and crossfades, room
## reverb per location, music states whose calm/intense variants crossfade with
## an intensity control, one-shot and 3D positional SFX, dialogue playback that
## drives subtitles and ducks music and ambience, per-bus volume settings and a
## "reduce startling audio" accessibility option.
##
## Listens to EventBus.shift_started (day/night) and EventBus.narrative_event_fired
## (authored audio events). It deliberately does NOT listen to objectivity or
## bleed-stage changes: anomaly audio is started only by explicit narrative events,
## so it never implies the player character is ill.
##
## Usage:
##     AudioDirector.set_location("corridor")
##     EventBus.narrative_event_fired.emit("ch1_pager_bennett", {})
##     await AudioDirector.play_scene("ch1_b2_bennett_handover")

const CUES_PATH: String = "res://audio/cues.json"
const AI_MUSIC_CUES_PATH: String = "res://audio/music_ai/music_cues.json"
const NARRATIVE_DIR: String = "res://data/narrative"
const VOICE_DIR: String = "res://audio/voice"
const SETTINGS_PATH: String = "user://audio_settings.cfg"
const SETTINGS_SECTION: String = "audio"

const SILENT_DB: float = -80.0
const LOWPASS_OPEN_HZ: float = 20000.0
## Music intensity 0..1 opens the Music bus low-pass from this cutoff to fully open.
const MUSIC_DARK_HZ: float = 900.0
## "Reduce startling audio": startle-flagged cues play this much quieter and fade in.
const STARTLE_REDUCTION_DB: float = -10.0
const STARTLE_FADE_IN: float = 0.6
const LINE_GAP_SECONDS: float = 0.35
## Ducking while anyone speaks, so music and ambience never mask dialogue.
const DIALOGUE_DUCK_MUSIC_DB: float = -9.0
const DIALOGUE_DUCK_AMBIENCE_DB: float = -4.0
const DIALOGUE_DUCK_ATTACK: float = 0.3
const DIALOGUE_DUCK_RELEASE: float = 1.2
## Crossfade time when intensity moves a music state to another variant.
const MUSIC_VARIANT_FADE: float = 4.0

## Player-facing settings. Volumes are linear 0..1.
const SETTING_DEFAULTS: Dictionary = {
	"volume_master": 1.0,
	"volume_music": 1.0,
	"volume_ambient": 1.0,
	"volume_sfx": 1.0,
	"volume_voice": 1.0,
	"reduce_startling_audio": false,
	"music_intensity_cap": 1.0,
}
const VOLUME_BUSES: Dictionary = {
	"volume_master": "Master", "volume_music": "Music", "volume_ambient": "Ambient",
	"volume_sfx": "SFX", "volume_voice": "Voice",
}

## Emitted internally when a dialogue line ends. `completed` is false if it was stopped.
signal _line_done(line_id: String, completed: bool)

## Tests set this to false so they never overwrite the player's settings file.
var persist: bool = true

var _settings: Dictionary = {}
var _cues: Dictionary = {}
var _locations: Dictionary = {}
var _events: Dictionary = {}
var _music_states: Dictionary = {} ## state_id -> [{cue, min_intensity}] sorted ascending
var _lines: Dictionary = {}  ## line_id -> {id, chapter, speaker, speaker_name, text}
var _scenes: Dictionary = {} ## scene_id -> Array of line ids

var _location: String = ""
var _shift: String = "day"
var _music_intensity: float = 1.0
var _music_state: String = ""
var _ambience_players: Array[AudioStreamPlayer] = []
var _ambience_slot: int = 0
var _music_players: Array[AudioStreamPlayer] = []
var _music_slot: int = 0
var _tweens: Dictionary = {} ## Object -> Tween, so a new fade replaces the old one.
var _current_line_id: String = ""
var _current_voice: Node = null
## Bumped whenever dialogue is started or stopped, so a scene notices interruptions.
var _dialogue_token: int = 0

var _ambience_lowpass: AudioEffectLowPassFilter
var _music_lowpass: AudioEffectLowPassFilter
var _sfx_reverb: AudioEffectReverb
var _music_duck: AudioEffectAmplify
var _ambience_duck: AudioEffectAmplify
var _voice_reverb: AudioEffectReverb


func _ready() -> void:
	_setup_buses()
	_load_cues()
	_load_narrative()
	for slot: int in 2:
		_ambience_players.append(_new_player("AmbienceBed", "Ambience%d" % slot))
		_music_players.append(_new_player("Music", "Music%d" % slot))
	_load_settings()
	_shift = GameState.shift
	EventBus.shift_started.connect(_on_shift_started)
	EventBus.narrative_event_fired.connect(_on_narrative_event_fired)


# ===========================================================================
# Settings
# ===========================================================================

func get_setting(key: String) -> Variant:
	return _settings.get(key, SETTING_DEFAULTS.get(key))


func set_setting(key: String, value: Variant) -> void:
	if not SETTING_DEFAULTS.has(key):
		push_error("AudioDirector: unknown setting '%s'" % key)
		return
	if typeof(SETTING_DEFAULTS[key]) == TYPE_FLOAT and (value is int or value is float):
		value = clampf(float(value), 0.0, 1.0)
	elif typeof(value) != typeof(SETTING_DEFAULTS[key]):
		push_error("AudioDirector: '%s' expects %s" % [key, type_string(typeof(SETTING_DEFAULTS[key]))])
		return
	_settings[key] = value
	_apply_setting(key)
	if persist:
		_save_settings()


func _apply_setting(key: String) -> void:
	if VOLUME_BUSES.has(key):
		var bus: int = AudioServer.get_bus_index(VOLUME_BUSES[key])
		var volume: float = _settings[key]
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
		AudioServer.set_bus_mute(bus, volume <= 0.0)
	elif key == "music_intensity_cap":
		set_music_intensity(_music_intensity)


func _load_settings() -> void:
	_settings = SETTING_DEFAULTS.duplicate()
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		for key: String in SETTING_DEFAULTS:
			var stored: Variant = config.get_value(SETTINGS_SECTION, key, SETTING_DEFAULTS[key])
			if typeof(stored) == typeof(SETTING_DEFAULTS[key]):
				_settings[key] = stored
	for key: String in _settings:
		_apply_setting(key)


func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	for key: String in _settings:
		config.set_value(SETTINGS_SECTION, key, _settings[key])
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("AudioDirector: could not save %s (%s)" % [SETTINGS_PATH, error_string(error)])


# ===========================================================================
# Location ambience, day/night and room acoustics
# ===========================================================================

func get_location() -> String:
	return _location


## Switches to a location from audio/cues.json, crossfading its ambience bed.
func set_location(location_id: String, fade_seconds: float = 2.0) -> void:
	if not _locations.has(location_id):
		push_warning("AudioDirector: unknown location '%s'" % location_id)
		return
	_location = location_id
	_apply_location(fade_seconds)


## Fades out all ambience and forgets the location (e.g. menus, cutscenes in silence).
func stop_ambience(fade_seconds: float = 2.0) -> void:
	_location = ""
	_crossfade(_ambience_players, true, "", 0.0, fade_seconds)


## The ambience player currently fading in or playing (for tests and debugging).
func get_active_ambience() -> AudioStreamPlayer:
	return _ambience_players[_ambience_slot]


func _on_shift_started(_day: int, shift: String) -> void:
	_shift = shift
	if not _location.is_empty():
		_apply_location(4.0)


func _apply_location(fade_seconds: float) -> void:
	var location: Dictionary = _locations[_location]
	var layer: Dictionary = location.get(_shift, location.get("day", {}))
	_crossfade(_ambience_players, true, str(layer.get("ambience", "")), float(layer.get("volume_db", 0.0)), fade_seconds)
	if layer.has("music_state"):
		set_music_state(str(layer["music_state"]), maxf(fade_seconds, 3.0))
	var cutoff: float = float(layer.get("lowpass_hz", LOWPASS_OPEN_HZ))
	_tween(_ambience_lowpass, "cutoff_hz", cutoff, fade_seconds)
	var reverb: Dictionary = location.get("reverb", {})
	for effect: AudioEffectReverb in [_sfx_reverb, _voice_reverb]:
		effect.room_size = float(reverb.get("room_size", 0.3))
		effect.damping = float(reverb.get("damping", 0.6))
	_sfx_reverb.wet = float(reverb.get("wet", 0.0))
	_voice_reverb.wet = float(reverb.get("wet", 0.0)) * 0.5 # Keep dialogue intelligible.


# ===========================================================================
# Music
# ===========================================================================

## Crossfades to a looping or long music cue. An empty cue fades music out.
## Playing a cue directly leaves any music state.
func play_music(cue_id: String, fade_seconds: float = 3.0) -> void:
	_music_state = ""
	_crossfade(_music_players, false, cue_id, 0.0, fade_seconds)


func stop_music(fade_seconds: float = 3.0) -> void:
	play_music("", fade_seconds)


## Enters a music state (e.g. "after_hours"): its variant for the current
## intensity crossfades in, and later intensity changes swap variants.
func set_music_state(state_id: String, fade_seconds: float = 4.0) -> void:
	if not _music_states.has(state_id):
		push_warning("AudioDirector: unknown music state '%s'" % state_id)
		return
	_music_state = state_id
	_crossfade(_music_players, false, _variant_for_intensity(), 0.0, fade_seconds)


func get_music_state() -> String:
	return _music_state


## Adds or replaces a music state. Variants: [{cue, min_intensity}].
func register_music_state(state_id: String, variants: Array) -> void:
	var sorted: Array = variants.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("min_intensity", 0.0)) < float(b.get("min_intensity", 0.0)))
	_music_states[state_id] = sorted


## Adds or replaces a cue (used by the AI music sheet and by tests).
func register_cue(cue_id: String, cue: Dictionary) -> void:
	_cues[cue_id] = cue


func _variant_for_intensity() -> String:
	var effective: float = minf(_music_intensity, float(get_setting("music_intensity_cap")))
	var chosen: String = ""
	for variant: Dictionary in _music_states.get(_music_state, []):
		if effective + 0.0001 >= float(variant.get("min_intensity", 0.0)):
			chosen = variant["cue"]
	return chosen


func get_active_music() -> AudioStreamPlayer:
	return _music_players[_music_slot]


## 0 = restrained (dark, filtered), 1 = full. Clamped by the music_intensity_cap setting.
func set_music_intensity(value: float, fade_seconds: float = 2.0) -> void:
	_music_intensity = clampf(value, 0.0, 1.0)
	var effective: float = minf(_music_intensity, float(get_setting("music_intensity_cap")))
	var cutoff: float = MUSIC_DARK_HZ * pow(LOWPASS_OPEN_HZ / MUSIC_DARK_HZ, effective)
	if _music_lowpass != null:
		_tween(_music_lowpass, "cutoff_hz", cutoff, fade_seconds)
	if not _music_state.is_empty():
		_crossfade(_music_players, false, _variant_for_intensity(), 0.0, MUSIC_VARIANT_FADE)


## One-shot musical transition on the Music bus, layered over any music bed.
func play_stinger(cue_id: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = _play_cue_2d(cue_id)
	if player != null:
		var duck_db: float = float(_cues[cue_id].get("duck_ambience_db", 0.0))
		if duck_db < 0.0:
			_duck_ambience(duck_db, player.stream.get_length())
	return player


func _duck_ambience(duck_db: float, hold_seconds: float) -> void:
	var bus: int = AudioServer.get_bus_index("AmbienceBed")
	var tween: Tween = _new_tween(AudioServer)
	var set_db := func(db: float) -> void: AudioServer.set_bus_volume_db(bus, db)
	tween.tween_method(set_db, AudioServer.get_bus_volume_db(bus), duck_db, 1.5)
	tween.tween_interval(maxf(hold_seconds - 3.0, 0.0))
	tween.tween_method(set_db, duck_db, 0.0, 3.0)


# ===========================================================================
# Sound effects
# ===========================================================================

## Plays a non-positional one-shot. Returns the player (freed when finished).
func play_sfx(cue_id: String) -> AudioStreamPlayer:
	return _play_cue_2d(cue_id)


## Plays a one-shot at a world position with distance attenuation.
func play_sfx_3d(cue_id: String, world_position: Vector3) -> AudioStreamPlayer3D:
	var cue: Dictionary = _get_cue(cue_id)
	if cue.is_empty():
		return null
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.name = "SFX3D_" + cue_id
	player.stream = load(cue["stream"])
	player.bus = cue.get("bus", "SFX")
	player.max_distance = float(cue.get("max_distance", 25.0))
	player.unit_size = float(cue.get("unit_size", 3.0))
	player.attenuation_filter_cutoff_hz = 6000.0 # Distant sources sound duller.
	add_child(player)
	player.global_position = world_position
	_start_one_shot(player, cue)
	return player


func _play_cue_2d(cue_id: String) -> AudioStreamPlayer:
	var cue: Dictionary = _get_cue(cue_id)
	if cue.is_empty():
		return null
	var player: AudioStreamPlayer = _new_player(cue.get("bus", "SFX"), "SFX_" + cue_id)
	player.stream = load(cue["stream"])
	_start_one_shot(player, cue)
	return player


## Applies cue volume and the startle accessibility option, plays, and frees on finish.
func _start_one_shot(player: Node, cue: Dictionary) -> void:
	var target_db: float = float(cue.get("volume_db", 0.0))
	var softened: bool = cue.get("startle", false) and get_setting("reduce_startling_audio")
	if softened:
		target_db += STARTLE_REDUCTION_DB
		player.set("volume_db", SILENT_DB)
	else:
		player.set("volume_db", target_db)
	player.connect("finished", player.queue_free)
	player.call("play")
	if softened:
		_fade(player, target_db, STARTLE_FADE_IN)


# ===========================================================================
# Dialogue and subtitles
# ===========================================================================

func has_line(line_id: String) -> bool:
	return _lines.has(line_id)


func get_line(line_id: String) -> Dictionary:
	return _lines.get(line_id, {}).duplicate()


func get_scene_lines(scene_id: String) -> Array:
	return _scenes.get(scene_id, []).duplicate()


## Voice clip for a line, or null if it has not been generated yet.
func get_voice_stream(line_id: String) -> AudioStream:
	var line: Dictionary = _lines.get(line_id, {})
	if line.is_empty():
		return null
	var path: String = "%s/%s/%s.ogg" % [VOICE_DIR, line["chapter"], line_id]
	return load(path) if ResourceLoader.exists(path) else null


## Plays one line and shows its subtitle for exactly as long as the clip plays.
## Unvoiced lines still show their subtitle, for an estimated reading time.
## Awaitable; returns false if the line was stopped or replaced before it ended.
## Pass `emitter` to voice the line from a character in the world.
func play_line(line_id: String, emitter: Node3D = null) -> bool:
	var line: Dictionary = _lines.get(line_id, {})
	if line.is_empty():
		push_warning("AudioDirector: unknown dialogue line '%s'" % line_id)
		return false
	stop_dialogue()
	_current_line_id = line_id
	_set_dialogue_duck(true)
	var stream: AudioStream = get_voice_stream(line_id)
	var duration: float
	if stream != null:
		var player: Node = AudioStreamPlayer3D.new() if emitter != null else AudioStreamPlayer.new()
		player.name = "Voice_" + line_id
		player.set("stream", stream)
		player.set("bus", "Voice")
		(emitter if emitter != null else self).add_child(player)
		player.connect("finished", _on_voice_finished.bind(player, line_id))
		player.call("play")
		_current_voice = player
		duration = stream.get_length()
	else:
		push_warning("AudioDirector: no voice clip for '%s'; showing subtitle only" % line_id)
		duration = clampf(line["text"].split(" ").size() * 0.4, 2.0, 12.0)
		get_tree().create_timer(duration).timeout.connect(_on_unvoiced_timeout.bind(line_id))
	EventBus.subtitle_shown.emit(line_id, line["speaker_name"], line["text"], duration)
	var completed: bool = false
	while true:
		var result: Array = await _line_done
		if result[0] == line_id:
			completed = result[1]
			break
	EventBus.subtitle_cleared.emit(line_id)
	_release_duck_if_quiet()
	return completed


## Plays every line of a narrative scene in order. Awaitable.
func play_scene(scene_id: String, emitters: Dictionary = {}) -> void:
	var line_ids: Array = _scenes.get(scene_id, [])
	if line_ids.is_empty():
		push_warning("AudioDirector: unknown or empty narrative scene '%s'" % scene_id)
		return
	for index: int in line_ids.size():
		var line_id: String = line_ids[index]
		if not await play_line(line_id, emitters.get(_lines[line_id]["speaker"])):
			return # Stopped or replaced by another line.
		if index < line_ids.size() - 1:
			var token: int = _dialogue_token
			await get_tree().create_timer(LINE_GAP_SECONDS).timeout
			if token != _dialogue_token:
				return # Dialogue was stopped or restarted during the pause.


## Ducks (true) or restores (false) music and ambience around speech.
func _set_dialogue_duck(active: bool) -> void:
	var seconds: float = DIALOGUE_DUCK_ATTACK if active else DIALOGUE_DUCK_RELEASE
	_tween(_music_duck, "volume_db", DIALOGUE_DUCK_MUSIC_DB if active else 0.0, seconds)
	_tween(_ambience_duck, "volume_db", DIALOGUE_DUCK_AMBIENCE_DB if active else 0.0, seconds)


## Restores the mix shortly after speech ends, unless another line starts
## (the pause between lines in a scene must not pump the music).
func _release_duck_if_quiet() -> void:
	var token: int = _dialogue_token
	await get_tree().create_timer(LINE_GAP_SECONDS + 0.25).timeout
	if token == _dialogue_token and _current_line_id.is_empty():
		_set_dialogue_duck(false)


func is_dialogue_playing() -> bool:
	return not _current_line_id.is_empty()


## Stops the current line (e.g. the player skipped it). Its subtitle clears.
func stop_dialogue() -> void:
	_dialogue_token += 1
	if _current_line_id.is_empty():
		return
	var line_id: String = _current_line_id
	_current_line_id = ""
	if is_instance_valid(_current_voice):
		_current_voice.queue_free()
	_current_voice = null
	_line_done.emit(line_id, false)


func _on_voice_finished(player: Node, line_id: String) -> void:
	player.queue_free()
	_finish_line(line_id)


func _on_unvoiced_timeout(line_id: String) -> void:
	_finish_line(line_id)


func _finish_line(line_id: String) -> void:
	if _current_line_id != line_id:
		return # Already stopped or replaced.
	_current_line_id = ""
	_current_voice = null
	_line_done.emit(line_id, true)


# ===========================================================================
# Narrative events
# ===========================================================================

func has_event(event_id: String) -> bool:
	return _events.has(event_id)


func _on_narrative_event_fired(event_id: String, payload: Dictionary) -> void:
	trigger_event(event_id, payload)


## Runs the audio actions mapped to an explicit narrative event. Events without
## audio are ignored. payload.position (Vector3) makes SFX positional.
func trigger_event(event_id: String, payload: Dictionary = {}) -> void:
	var elapsed: float = 0.0
	for action: Dictionary in _events.get(event_id, []):
		var at: float = float(action.get("at", 0.0))
		if at > elapsed:
			await get_tree().create_timer(at - elapsed).timeout
			elapsed = at
		if action.has("sfx"):
			if payload.get("position") is Vector3:
				play_sfx_3d(action["sfx"], payload["position"])
			else:
				play_sfx(action["sfx"])
		elif action.has("stinger"):
			play_stinger(action["stinger"])
		elif action.has("music"):
			play_music(action["music"])
		elif action.has("music_state"):
			set_music_state(action["music_state"])
		elif action.has("stop_music"):
			stop_music(float(action["stop_music"]))
		elif action.has("intensity"):
			set_music_intensity(float(action["intensity"]))
		elif action.has("line"):
			play_line(action["line"])
		elif action.has("scene"):
			play_scene(action["scene"])


# ===========================================================================
# Internals
# ===========================================================================

func _setup_buses() -> void:
	_ensure_bus("Music", "Master")
	_ensure_bus("Ambient", "Master")
	_ensure_bus("AmbienceBed", "Ambient") # Internal: ducking and night filtering, no slider.
	_ensure_bus("SFX", "Master")
	_ensure_bus("Voice", "Master")
	_ambience_lowpass = _bus_effect("AmbienceBed", AudioEffectLowPassFilter.new()) as AudioEffectLowPassFilter
	_ambience_lowpass.cutoff_hz = LOWPASS_OPEN_HZ
	_music_lowpass = _bus_effect("Music", AudioEffectLowPassFilter.new()) as AudioEffectLowPassFilter
	_music_lowpass.cutoff_hz = LOWPASS_OPEN_HZ
	_ambience_duck = _bus_effect("AmbienceBed", AudioEffectAmplify.new()) as AudioEffectAmplify
	_music_duck = _bus_effect("Music", AudioEffectAmplify.new()) as AudioEffectAmplify
	_sfx_reverb = _bus_effect("SFX", AudioEffectReverb.new()) as AudioEffectReverb
	_voice_reverb = _bus_effect("Voice", AudioEffectReverb.new()) as AudioEffectReverb
	for effect: AudioEffectReverb in [_sfx_reverb, _voice_reverb]:
		effect.dry = 1.0
		effect.wet = 0.0


## Creates the bus if a bus layout did not already define it. Sends must point
## to an earlier bus, so callers create parents first.
func _ensure_bus(bus_name: String, send: String) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, send)


func _bus_effect(bus_name: String, effect: AudioEffect) -> AudioEffect:
	var bus: int = AudioServer.get_bus_index(bus_name)
	for index: int in AudioServer.get_bus_effect_count(bus):
		var existing: AudioEffect = AudioServer.get_bus_effect(bus, index)
		if existing.get_class() == effect.get_class():
			return existing
	AudioServer.add_bus_effect(bus, effect)
	return effect


func _load_cues() -> void:
	var data: Dictionary = _read_json(CUES_PATH)
	_cues = data.get("cues", {})
	_locations = data.get("locations", {})
	_events = data.get("events", {})
	_load_cue_sheet_music(data)
	# The AI-generated score lives in its own sheet so it can be regenerated
	# and approved independently of the procedural effects.
	if FileAccess.file_exists(AI_MUSIC_CUES_PATH):
		var ai: Dictionary = _read_json(AI_MUSIC_CUES_PATH)
		_cues.merge(ai.get("cues", {}), true)
		_events.merge(ai.get("events", {}), true)
		_load_cue_sheet_music(ai)
		for location_id: String in ai.get("location_music", {}):
			if _locations.has(location_id):
				for shift: String in ai["location_music"][location_id]:
					_locations[location_id].get(shift, {})["music_state"] = ai["location_music"][location_id][shift]
	for cue_id: String in _cues:
		var path: String = _cues[cue_id].get("stream", "")
		if not ResourceLoader.exists(path):
			push_error("AudioDirector: cue '%s' stream not found: %s" % [cue_id, path])


func _load_cue_sheet_music(data: Dictionary) -> void:
	var states: Dictionary = data.get("music_states", {})
	for state_id: String in states:
		register_music_state(state_id, states[state_id])


func _load_narrative() -> void:
	for file_name: String in DirAccess.get_files_at(NARRATIVE_DIR):
		if not file_name.ends_with(".json"):
			continue
		var data: Dictionary = _read_json(NARRATIVE_DIR.path_join(file_name))
		var speakers: Dictionary = data.get("speakers", {})
		for scene: Dictionary in data.get("scenes", []):
			var ids: Array = []
			for line: Dictionary in scene.get("lines", []):
				_lines[line["id"]] = {
					"id": line["id"], "chapter": data.get("chapter", ""), "speaker": line["speaker"],
					"speaker_name": speakers.get(line["speaker"], line["speaker"]), "text": line["text"],
				}
				ids.append(line["id"])
			_scenes[scene["id"]] = ids


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("AudioDirector: cannot parse %s" % path)
		return {}
	return parsed


func _get_cue(cue_id: String) -> Dictionary:
	if not _cues.has(cue_id):
		push_warning("AudioDirector: unknown cue '%s'" % cue_id)
		return {}
	return _cues[cue_id]


func _new_player(bus_name: String, player_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	add_child(player)
	return player


## Two-slot crossfade used by ambience and music. Same cue: only retargets volume.
func _crossfade(players: Array[AudioStreamPlayer], is_ambience: bool, cue_id: String, target_db: float, fade_seconds: float) -> void:
	var slot: int = _ambience_slot if is_ambience else _music_slot
	var current: AudioStreamPlayer = players[slot]
	var cue: Dictionary = _cues.get(cue_id, {})
	var stream_path: String = cue.get("stream", "")
	target_db += float(cue.get("volume_db", 0.0))
	if current.playing and current.stream != null and current.stream.resource_path == stream_path:
		_fade(current, target_db, fade_seconds)
		return
	for player: AudioStreamPlayer in players: # Includes a slot still fading out.
		if player.playing:
			_fade(player, SILENT_DB, fade_seconds, true)
	if cue.is_empty():
		return
	slot = 1 - slot
	var incoming: AudioStreamPlayer = players[slot]
	var stream: AudioStream = load(stream_path)
	if cue.get("loop", false) and "loop" in stream:
		stream.set("loop", true)
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	incoming.play()
	_fade(incoming, target_db, fade_seconds)
	if is_ambience:
		_ambience_slot = slot
	else:
		_music_slot = slot


## Fades in perceptual (linear gain) space so fade-ins don't jump at the end.
func _fade(player: Node, to_db: float, seconds: float, stop_after: bool = false) -> void:
	var tween: Tween = _new_tween(player)
	var set_db := func(gain: float) -> void: player.set("volume_db", linear_to_db(maxf(gain, 0.0001)))
	tween.tween_method(set_db, db_to_linear(player.get("volume_db")), db_to_linear(to_db), maxf(seconds, 0.01))
	if stop_after:
		tween.tween_callback(player.call.bind("stop"))


func _tween(target: Object, property: String, value: float, seconds: float) -> void:
	var tween: Tween = _new_tween(target)
	tween.tween_property(target, property, value, maxf(seconds, 0.01)).set_trans(Tween.TRANS_SINE)


func _new_tween(target: Object) -> Tween:
	var previous: Tween = _tweens.get(target)
	if previous != null and previous.is_valid():
		previous.kill()
	var tween: Tween = create_tween()
	_tweens[target] = tween
	return tween
