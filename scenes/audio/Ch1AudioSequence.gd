extends Node3D
## Ch1AudioSequence — playable check of the first audio milestone.
##
## Runs the Chapter 1 audio beats in order through the real AudioDirector and
## narrative events: corridor ambience, secure door (3D, to the right of the
## camera), pager, Nurse Bennett handover with subtitles, night shift, the
## after-hours intercom, and the unease transition. Open this scene and press
## F6 (Mac: Cmd + R). Volume keys: 1-4 lower Music/Ambient/SFX/Voice, Shift+1-4
## raise them; S toggles "reduce startling audio".
## Headless QA passes `-- --exit-when-done` to quit after the last beat.

const DOOR_POSITION: Vector3 = Vector3(4.0, 1.2, -1.0)
const VOLUME_KEYS: Dictionary = {
	KEY_1: "volume_music", KEY_2: "volume_ambient", KEY_3: "volume_sfx", KEY_4: "volume_voice",
}

@onready var _subtitle: Label = $HUD/Subtitle
@onready var _log_label: Label = $HUD/Log

var _log: Array[String] = []


func _ready() -> void:
	EventBus.subtitle_shown.connect(_on_subtitle_shown)
	EventBus.subtitle_cleared.connect(_on_subtitle_cleared)
	_subtitle.text = ""
	await _run_sequence()
	_step("CH1_SEQUENCE_DONE")
	if "--exit-when-done" in OS.get_cmdline_user_args():
		AudioDirector.stop_ambience(0.01)
		AudioDirector.stop_music(0.01)
		await _wait(0.3)
		get_tree().quit()


func _run_sequence() -> void:
	GameState.start_shift(1, "day")
	AudioDirector.set_location("corridor", 2.0)
	_step("corridor ambience (day)")
	await _wait(2.5)
	_step("secure door opens (3D, right)")
	EventBus.narrative_event_fired.emit("ch1_secure_door_opened", {"position": DOOR_POSITION})
	await _wait(3.5)
	_step("pager")
	EventBus.narrative_event_fired.emit("ch1_pager_bennett", {})
	await _wait(2.0)
	AudioDirector.set_location("nursing_station", 2.0)
	_step("nursing station: Bennett handover")
	await AudioDirector.play_scene("ch1_b2_bennett_handover")
	await _wait(1.5)
	GameState.start_shift(1, "night")
	AudioDirector.set_location("corridor", 3.0)
	_step("night shift: corridor ambience (night)")
	await _wait(4.0)
	_step("after-hours intercom")
	EventBus.narrative_event_fired.emit("ch1_after_hours_intercom", {})
	await EventBus.subtitle_cleared
	await _wait(1.0)
	_step("unease transition")
	EventBus.narrative_event_fired.emit("ch1_w0b_unease", {})
	await _wait(10.5)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if VOLUME_KEYS.has(key.keycode):
		var setting: String = VOLUME_KEYS[key.keycode]
		var step: float = 0.25 if key.shift_pressed else -0.25
		AudioDirector.set_setting(setting, float(AudioDirector.get_setting(setting)) + step)
		_step("%s = %.2f" % [setting, AudioDirector.get_setting(setting)])
	elif key.keycode == KEY_S:
		AudioDirector.set_setting("reduce_startling_audio", not AudioDirector.get_setting("reduce_startling_audio"))
		_step("reduce_startling_audio = %s" % AudioDirector.get_setting("reduce_startling_audio"))


func _on_subtitle_shown(line_id: String, speaker_name: String, text: String, duration: float) -> void:
	_subtitle.text = "%s: %s" % [speaker_name, text]
	print("SUBTITLE %s %.2fs" % [line_id, duration])


func _on_subtitle_cleared(_line_id: String) -> void:
	_subtitle.text = ""


func _step(text: String) -> void:
	print("[Ch1 audio] %.1fs %s" % [Time.get_ticks_msec() / 1000.0, text])
	_log.append(text)
	if _log.size() > 10:
		_log.pop_front()
	_log_label.text = "CHAPTER 1 AUDIO SEQUENCE\n\n" + "\n".join(_log) + \
		"\n\n[1-4] lower music/ambient/sfx/voice  [Shift+1-4] raise  [S] reduce startling audio"


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
