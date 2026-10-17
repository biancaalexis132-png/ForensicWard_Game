extends Node
## Audio pipeline checks: assets load, buses and volumes, location/day-night
## ambience, dialogue/subtitle sync, narrative events, accessibility,
## soundtrack contexts, repeats and ducking.
## Run: godot --headless --path . res://tests/audio/TestAudio.tscn
## Headless Godot uses the Dummy audio driver: playback state and timing are
## exercised, but nothing is audible. Listening tests remain manual.

const MANIFEST_PATH: String = "res://audio/manifest.json"

var passed := 0
var failed := 0
var subtitles: Array[Dictionary] = []

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		print("FAIL: " + label)

func _ready() -> void:
	AudioDirector.persist = false
	EventBus.subtitle_shown.connect(func(id: String, speaker: String, text: String, duration: float) -> void:
		subtitles.append({"event": "shown", "id": id, "speaker": speaker, "text": text, "duration": duration, "at": now()}))
	EventBus.subtitle_cleared.connect(func(id: String) -> void:
		subtitles.append({"event": "cleared", "id": id, "at": now()}))
	test_buses_and_volume()
	test_assets_and_manifest()
	await test_location_and_day_night()
	await test_events_and_positional_sfx()
	await test_startle_accessibility()
	await test_dialogue_subtitle_sync()
	await test_anomalies_need_explicit_events()
	await test_music_states_and_dialogue_ducking()
	await test_environment_set()
	await test_soundtrack()
	await test_pause_menu_audio_settings()
	# Release playbacks before quitting; the audio server frees them on its next mix.
	AudioDirector.stop_ambience(0.01)
	AudioDirector.stop_music(0.01)
	await wait(0.3)
	check(not AudioDirector.get_active_ambience().playing, "stop_ambience silences the bed")
	print("AUDIO_RESULT passed=%d failed=%d" % [passed, failed])
	get_tree().quit(1 if failed else 0)

func now() -> float:
	return Time.get_ticks_msec() / 1000.0

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func test_buses_and_volume() -> void:
	for bus: String in ["Master", "Music", "Ambient", "AmbienceBed", "SFX", "Voice"]:
		check(AudioServer.get_bus_index(bus) >= 0, "bus exists: " + bus)
	check(AudioServer.get_bus_send(AudioServer.get_bus_index("AmbienceBed")) == &"Ambient", "ambience bed feeds the Ambient slider bus")
	for key: String in ["volume_music", "volume_ambient", "volume_sfx", "volume_voice"]:
		var bus: int = AudioServer.get_bus_index(AudioDirector.VOLUME_BUSES[key])
		AudioDirector.set_setting(key, 0.5)
		check(absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.5)) < 0.01 and not AudioServer.is_bus_mute(bus), key + " 0.5 sets -6 dB")
		AudioDirector.set_setting(key, 0.0)
		check(AudioServer.is_bus_mute(bus), key + " 0 mutes bus")
		AudioDirector.set_setting(key, 1.0)
		check(is_zero_approx(AudioServer.get_bus_volume_db(bus)) and not AudioServer.is_bus_mute(bus), key + " restored")
	AudioDirector.set_setting("volume_voice", 7.0)
	check(AudioDirector.get_setting("volume_voice") == 1.0, "volume clamps to 1.0")

func test_assets_and_manifest() -> void:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	check(manifest is Dictionary and not manifest.get("assets", []).is_empty(), "manifest parses")
	if not manifest is Dictionary:
		return
	for asset: Dictionary in manifest["assets"]:
		var path: String = "res://" + asset["file"]
		var stream := load(path) as AudioStream
		check(stream != null and stream.get_length() > 0.05, "loads: " + asset["file"])
		if stream != null:
			check(absf(stream.get_length() - float(asset["duration_seconds"])) < 0.05, "manifest duration matches: " + asset["file"])
	var cues: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AudioDirector.CUES_PATH))
	for cue_id: String in cues["cues"]:
		var cue: Dictionary = cues["cues"][cue_id]
		for path: String in cue.get("streams", [cue.get("stream", "")]):
			check(ResourceLoader.exists(path), "cue stream exists: %s (%s)" % [cue_id, path.get_file()])
	for scene_id: String in ["ch1_b2_bennett_handover", "ch1_b6_after_hours_intercom"]:
		for line_id: String in AudioDirector.get_scene_lines(scene_id):
			check(AudioDirector.get_voice_stream(line_id) != null, "voice clip exists: " + line_id)

func test_location_and_day_night() -> void:
	GameState.start_shift(1, "day")
	AudioDirector.set_location("corridor", 0.2)
	var day_player: AudioStreamPlayer = AudioDirector.get_active_ambience()
	await wait(0.4)
	check(day_player.playing and day_player.stream.resource_path.ends_with("amb_corridor_day_loop.ogg"), "corridor day ambience plays")
	check(day_player.stream.get("loop") == true, "ambience stream loops")
	check(absf(day_player.volume_db) < 0.5, "day ambience faded in to 0 dB")
	var position_before: float = day_player.get_playback_position()
	await wait(0.3)
	check(day_player.get_playback_position() > position_before, "ambience playback advances")
	GameState.start_shift(1, "night")
	await wait(4.3)
	check(AudioDirector.get_active_ambience() == day_player and day_player.playing, "same bed continues across shift change (no restart)")
	check(absf(day_player.volume_db - -5.0) < 0.5, "night ambience is quieter")
	var lowpass := AudioServer.get_bus_effect(AudioServer.get_bus_index("AmbienceBed"), 0) as AudioEffectLowPassFilter
	check(lowpass != null and absf(lowpass.cutoff_hz - 2200.0) < 1.0, "night ambience is filtered")
	AudioDirector.set_location("nursing_station", 0.2)
	await wait(0.4)
	check(absf(day_player.volume_db - -10.0) < 0.5, "location change retargets ambience")
	var reverb := AudioServer.get_bus_effect(AudioServer.get_bus_index("SFX"), 0) as AudioEffectReverb
	check(reverb != null and is_equal_approx(reverb.room_size, 0.35), "location sets room reverb")
	GameState.start_shift(1, "day")
	AudioDirector.set_location("corridor", 0.2)
	await wait(0.4)

func test_events_and_positional_sfx() -> void:
	var before: int = AudioDirector.get_child_count()
	EventBus.narrative_event_fired.emit("ch1_pager_bennett", {})
	var pager := AudioDirector.get_node_or_null("SFX_sfx_pager_alert") as AudioStreamPlayer
	check(pager != null and pager.playing and pager.bus == &"SFX", "pager event plays on SFX bus")
	EventBus.narrative_event_fired.emit("ch1_secure_door_opened", {"position": Vector3(4, 1, -2)})
	var door := AudioDirector.get_node_or_null("SFX3D_sfx_door_secure_open") as AudioStreamPlayer3D
	check(door != null and door.playing and door.global_position.is_equal_approx(Vector3(4, 1, -2)), "door event with position plays in 3D")
	EventBus.narrative_event_fired.emit("unmapped_story_event", {})
	check(AudioDirector.get_child_count() == before + 2, "unmapped events play nothing")
	await wait(3.6)
	check(AudioDirector.get_child_count() == before, "one-shot players free themselves when finished")

func test_startle_accessibility() -> void:
	AudioDirector.set_setting("reduce_startling_audio", false)
	var normal: AudioStreamPlayer = AudioDirector.play_stinger("mus_transition_unease")
	check(normal != null and normal.playing and is_zero_approx(normal.volume_db), "stinger plays at full level by default")
	await wait(1.6)
	var bed_db: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("AmbienceBed"))
	check(bed_db < -8.0, "stinger ducks ambience for controlled silence")
	normal.stop()
	normal.queue_free()
	AudioDirector.set_setting("reduce_startling_audio", true)
	var reduced: AudioStreamPlayer = AudioDirector.play_stinger("mus_transition_unease")
	check(reduced.volume_db < -60.0, "reduced stinger starts silent (soft attack)")
	await wait(0.8)
	check(absf(reduced.volume_db - AudioDirector.STARTLE_REDUCTION_DB) < 0.5, "reduced stinger settles 10 dB lower")
	reduced.stop()
	reduced.queue_free()
	AudioDirector.set_setting("reduce_startling_audio", false)
	AudioDirector.set_setting("music_intensity_cap", 0.0)
	AudioDirector.set_music_intensity(1.0, 0.01)
	await wait(0.1)
	var music_lowpass := AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0) as AudioEffectLowPassFilter
	check(absf(music_lowpass.cutoff_hz - AudioDirector.MUSIC_DARK_HZ) < 1.0, "intensity cap limits music intensity")
	AudioDirector.set_setting("music_intensity_cap", 1.0)
	await wait(2.1)
	check(music_lowpass.cutoff_hz > 19000.0, "full intensity opens music filter")
	await wait(2.0) # Let the ducked ambience recover before dialogue tests.

func test_dialogue_subtitle_sync() -> void:
	subtitles.clear()
	var line_id: String = "ch1_b2_player_001"
	var clip_length: float = AudioDirector.get_voice_stream(line_id).get_length()
	var start: float = now()
	var completed: bool = await AudioDirector.play_line(line_id)
	var elapsed: float = now() - start
	check(completed, "line completes")
	check(subtitles.size() == 2 and subtitles[0]["event"] == "shown" and subtitles[1]["event"] == "cleared", "subtitle shown then cleared")
	if subtitles.size() == 2:
		check(subtitles[0]["text"] == AudioDirector.get_line(line_id)["text"] and subtitles[0]["speaker"] == "You", "subtitle text comes from narrative data")
		check(absf(subtitles[0]["duration"] - clip_length) < 0.01, "subtitle duration equals clip length")
		check(absf(subtitles[0]["at"] - start) < 0.05, "subtitle appears when voice starts")
	check(absf(elapsed - clip_length) < 0.35, "subtitle clears when voice ends (%.2f s vs %.2f s clip)" % [elapsed, clip_length])

	# Stopping mid-scene clears the subtitle and ends the scene without playing later lines.
	subtitles.clear()
	AudioDirector.play_scene("ch1_b2_bennett_handover")
	await wait(0.5)
	check(AudioDirector.is_dialogue_playing(), "scene starts dialogue")
	var voice := AudioDirector.get_node_or_null("Voice_ch1_b2_bennett_001") as AudioStreamPlayer
	check(voice != null and voice.playing and voice.bus == &"Voice", "scene voice plays on Voice bus")
	AudioDirector.stop_dialogue()
	await wait(1.0)
	var shown: Array = subtitles.filter(func(entry: Dictionary) -> bool: return entry["event"] == "shown")
	check(shown.size() == 1 and subtitles.back()["event"] == "cleared" and not AudioDirector.is_dialogue_playing(), "stopping dialogue clears subtitle and ends scene")

	# 3D emitter: the voice follows the speaking character.
	var bennett := Node3D.new()
	add_child(bennett)
	bennett.position = Vector3(2, 1.6, 0)
	AudioDirector.play_line("ch1_b2_bennett_001", bennett)
	await get_tree().process_frame
	var voice_3d := bennett.get_node_or_null("Voice_ch1_b2_bennett_001") as AudioStreamPlayer3D
	check(voice_3d != null and voice_3d.playing and voice_3d.global_position.is_equal_approx(Vector3(2, 1.6, 0)), "line with emitter plays positionally")
	AudioDirector.stop_dialogue()
	bennett.queue_free()

func test_anomalies_need_explicit_events() -> void:
	await get_tree().process_frame
	var before: int = AudioDirector.get_child_count()
	GameState.set_objectivity(10.0) # Severe bleed stage.
	await wait(0.2)
	check(AudioDirector.get_child_count() == before, "bleed stage alone triggers no anomaly audio")
	GameState.set_objectivity(100.0)

func test_music_states_and_dialogue_ducking() -> void:
	# Stand-in streams: the AI score is generated on the Mac (tools/music_ai).
	AudioDirector.register_cue("qa_calm", {"stream": "res://audio/music/mus_transition_unease_01.ogg", "bus": "Music"})
	AudioDirector.register_cue("qa_tense", {"stream": "res://audio/ambience/amb_corridor_day_loop.ogg", "bus": "Music", "volume_db": -3.0})
	AudioDirector.register_music_state("qa_state", [{"cue": "qa_tense", "min_intensity": 0.6}, {"cue": "qa_calm", "min_intensity": 0.0}])
	AudioDirector.set_music_intensity(0.2, 0.01)
	AudioDirector.set_music_state("qa_state", 0.2)
	await wait(0.4)
	var calm: AudioStreamPlayer = AudioDirector.get_active_music()
	check(AudioDirector.get_music_state() == "qa_state" and calm.playing and calm.stream.resource_path.ends_with("mus_transition_unease_01.ogg"), "music state starts calm variant at low intensity")
	check(calm.bus == &"Music", "music plays on Music bus")
	AudioDirector.set_music_intensity(0.8, 0.01)
	await wait(AudioDirector.MUSIC_VARIANT_FADE + 0.3)
	var tense: AudioStreamPlayer = AudioDirector.get_active_music()
	check(tense != calm and tense.playing and tense.stream.resource_path.ends_with("amb_corridor_day_loop.ogg"), "higher intensity crossfades to tense variant")
	check(not calm.playing and absf(tense.volume_db - -3.0) < 0.5, "old variant faded out, new variant at cue level")
	AudioDirector.set_setting("music_intensity_cap", 0.3)
	await wait(AudioDirector.MUSIC_VARIANT_FADE + 0.3)
	check(AudioDirector.get_active_music().stream.resource_path.ends_with("mus_transition_unease_01.ogg"), "intensity cap returns music to calm variant")
	AudioDirector.set_setting("music_intensity_cap", 1.0)

	var music_duck := AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 1) as AudioEffectAmplify
	var bed_duck := AudioServer.get_bus_effect(AudioServer.get_bus_index("AmbienceBed"), 1) as AudioEffectAmplify
	check(music_duck != null and bed_duck != null, "duck effects exist on Music and AmbienceBed")
	var playing_music: AudioStreamPlayer = AudioDirector.get_active_music()
	AudioDirector.play_scene("ch1_b2_bennett_handover")
	await wait(0.6)
	check(absf(music_duck.volume_db - AudioDirector.DIALOGUE_DUCK_MUSIC_DB) < 0.2, "music ducks during dialogue")
	check(absf(bed_duck.volume_db - AudioDirector.DIALOGUE_DUCK_AMBIENCE_DB) < 0.2, "ambience ducks during dialogue")
	check(playing_music.playing, "dialogue does not stop the music")
	AudioDirector.stop_dialogue()
	await wait(0.6 + AudioDirector.DIALOGUE_DUCK_RELEASE + 0.2)
	check(absf(music_duck.volume_db) < 0.2 and absf(bed_duck.volume_db) < 0.2, "mix restores after dialogue")

func test_environment_set() -> void:
	# Multi-take cues play through a randomizer with pitch variation.
	var step: AudioStreamPlayer3D = AudioDirector.play_sfx_3d("sfx_footstep_concrete", Vector3(0, 0, -3))
	check(step != null and step.playing and step.stream is AudioStreamRandomizer, "footstep cue uses a stream randomizer")
	if step != null and step.stream is AudioStreamRandomizer:
		var randomizer := step.stream as AudioStreamRandomizer
		check(randomizer.streams_count == 4 and randomizer.random_pitch > 1.0, "randomizer has 4 takes and pitch variation")
	check(AudioDirector.play_sfx("sfx_ui_keypress").stream == AudioDirector.play_sfx("sfx_ui_keypress").stream, "randomizer is cached per cue")

	# Base bed plus detail layer per location.
	GameState.start_shift(1, "day")
	AudioDirector.set_location("nursing_station", 0.2)
	await wait(0.4)
	var bed: AudioStreamPlayer = AudioDirector.get_active_ambience()
	var detail: AudioStreamPlayer = AudioDirector.get_active_ambience_detail()
	check(bed.playing and bed.stream.resource_path.ends_with("amb_corridor_day_loop.ogg"), "nursing station keeps the corridor bed")
	check(detail.playing and detail.stream.resource_path.ends_with("amb_nursing_station_loop.ogg") and detail.bus == &"AmbienceBed", "nursing station adds its detail layer")
	AudioDirector.set_location("ward_zero", 0.2)
	await wait(0.4)
	check(AudioDirector.get_active_ambience().stream.resource_path.ends_with("amb_ward_zero_loop.ogg"), "Ward Zero bed plays")
	check(AudioDirector.get_active_ambience_detail().stream.resource_path.ends_with("amb_historic_intercom_static_loop.ogg"), "Ward Zero static detail plays")
	check(not detail.playing or detail == AudioDirector.get_active_ambience_detail(), "previous detail layer fades out")
	var reverb := AudioServer.get_bus_effect(AudioServer.get_bus_index("SFX"), 0) as AudioEffectReverb
	check(is_equal_approx(reverb.room_size, 0.85), "Ward Zero uses a large room reverb")

	# Anomalies: event-only, startle-flagged, softened by the accessibility option.
	var before: int = AudioDirector.get_child_count()
	GameState.set_objectivity(5.0)
	await wait(0.2)
	check(AudioDirector.get_child_count() == before, "severe bleed stage in Ward Zero still starts no anomaly")
	GameState.set_objectivity(100.0)
	AudioDirector.set_setting("reduce_startling_audio", true)
	EventBus.narrative_event_fired.emit("w0_knocking_heard", {"position": Vector3(0, 1, -20)})
	var knocks := AudioDirector.get_node_or_null("SFX3D_sfx_w0_distant_knocks") as AudioStreamPlayer3D
	check(knocks != null and knocks.playing and knocks.volume_db < -60.0, "knocks play on explicit event, softened when requested")
	AudioDirector.set_setting("reduce_startling_audio", false)
	for event_id: String in ["ch1_badge_denied", "ch1_elevator_arrived", "ch1_ehr_alert_raised", "ch1_lights_flicker", "w0_power_surge"]:
		check(AudioDirector.has_event(event_id), "event mapped: " + event_id)
	await wait(5.8)
	GameState.start_shift(1, "day")
	AudioDirector.set_location("corridor", 0.2)
	await wait(0.4)

func test_soundtrack() -> void:
	var tracks: Dictionary = {
		"mus_main_theme": "music_main_theme.ogg", "mus_main_theme_alt": "music_main_theme_alt.ogg",
		"mus_emotional": "music_emotional.ogg", "mus_narrative": "music_narrative.ogg",
		"mus_ending_credits": "music_ending_credits.ogg",
	}
	var cues: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AudioDirector.CUES_PATH))
	for cue_id: String in tracks:
		var cue: Dictionary = cues["cues"].get(cue_id, {})
		check(cue.get("stream", "") == "res://assets/audio/music/" + tracks[cue_id] and cue.get("bus") == "Music", "soundtrack cue on Music bus: " + cue_id)
		var stream := load(cue.get("stream", "")) as AudioStreamOggVorbis
		check(stream != null and stream.get_length() > 150.0 and not stream.loop, "soundtrack stream loads unmodified (no import loop): " + cue_id)
	var bed_duck := AudioServer.get_bus_effect(AudioServer.get_bus_index("AmbienceBed"), 1) as AudioEffectAmplify
	var music_duck := AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 1) as AudioEffectAmplify

	# Narrative exploration: day corridor and nursing station only; Ward Zero and night stay without score.
	AudioDirector.stop_music(0.01)
	GameState.start_shift(1, "day")
	AudioDirector.set_location("ward_zero", 0.2)
	await wait(0.3)
	AudioDirector.set_location("corridor", 0.2)
	check(AudioDirector.get_music_state() == "exploration" and AudioDirector.get_music_cue() == "mus_narrative", "corridor by day plays the narrative theme")
	var narrative: AudioStreamPlayer = AudioDirector.get_active_music()
	await wait(3.3)
	check(narrative.playing and absf(narrative.volume_db - -8.1) < 0.5, "narrative theme sits under the ambience at its cue level")
	check(AudioDirector.get_active_ambience().playing, "ambience keeps playing under exploration music")
	AudioDirector.set_location("nursing_station", 0.2)
	await wait(0.2)
	check(AudioDirector.get_active_music() == narrative and narrative.playing, "moving between exploration rooms does not restart the theme")
	AudioDirector.set_location("ward_zero", 0.2)
	await wait(3.3)
	check(not narrative.playing and AudioDirector.get_music_cue() == "", "Ward Zero fades exploration music out")
	GameState.start_shift(1, "night")
	AudioDirector.set_location("corridor", 0.2)
	await wait(0.2)
	check(AudioDirector.get_music_cue() == "", "night corridor keeps controlled silence")
	GameState.start_shift(1, "day")
	await wait(4.3)
	check(AudioDirector.get_music_cue() == "mus_narrative" and AudioDirector.get_active_music().playing, "day shift brings the narrative theme back")

	# Emotional scene: takes over the music, ducks ambience, survives room changes, hands back.
	EventBus.narrative_event_fired.emit("music_emotional_begin", {})
	await get_tree().process_frame
	check(AudioDirector.get_music_context() == "emotional" and AudioDirector.get_music_cue() == "mus_emotional", "emotional event starts the emotional theme")
	var emotional: AudioStreamPlayer = AudioDirector.get_active_music()
	await wait(4.3)
	check(emotional.playing and absf(emotional.volume_db - -5.0) < 0.5, "emotional theme fades in to its cue level")
	check(absf(bed_duck.volume_db - -6.0) < 0.2 and AudioDirector.get_active_ambience().playing, "emotional scene ducks ambience without stopping it")
	AudioDirector.set_location("nursing_station", 0.2)
	await wait(0.3)
	check(AudioDirector.get_music_cue() == "mus_emotional", "room change keeps the context's music")
	AudioDirector.play_line("ch1_b2_bennett_001")
	await wait(0.5)
	check(absf(music_duck.volume_db - AudioDirector.DIALOGUE_DUCK_MUSIC_DB) < 0.2, "emotional theme ducks under dialogue")
	check(absf(bed_duck.volume_db - (-6.0 + AudioDirector.DIALOGUE_DUCK_AMBIENCE_DB)) < 0.2, "dialogue duck adds to the context duck")
	AudioDirector.stop_dialogue()
	await wait(0.6 + AudioDirector.DIALOGUE_DUCK_RELEASE + 0.2)
	check(absf(music_duck.volume_db) < 0.2 and absf(bed_duck.volume_db - -6.0) < 0.2, "after dialogue the context duck remains")

	# Contexts stack: a cinematic over the emotional scene returns to it.
	EventBus.narrative_event_fired.emit("music_cinematic", {})
	await get_tree().process_frame
	check(AudioDirector.get_music_cue() == "mus_main_theme_alt", "cinematic event plays the alternate main theme")
	await wait(3.3)
	check(not emotional.playing and absf(bed_duck.volume_db - -12.0) < 0.2, "cinematic crossfades out the emotional theme and ducks ambience further")
	var cinematic: AudioStreamPlayer = AudioDirector.get_active_music()
	cinematic.seek(cinematic.stream.get_length() - 1.0)
	await wait(1.6)
	check(AudioDirector.get_music_context() == "emotional" and AudioDirector.get_music_cue() == "mus_emotional", "cinematic plays once, then the emotional scene resumes")
	EventBus.narrative_event_fired.emit("music_emotional_end", {})
	await get_tree().process_frame
	check(AudioDirector.get_music_context() == "" and AudioDirector.get_music_cue() == "mus_narrative", "ending the scene hands music back to the location")
	await wait(4.3)
	check(absf(bed_duck.volume_db) < 0.2, "ambience duck released")

	# Main menu: ambience stops, theme loops by crossfading its tail into its head.
	AudioDirector.start_music_context("main_menu")
	await wait(2.8)
	var menu: AudioStreamPlayer = AudioDirector.get_active_music()
	check(menu.playing and AudioDirector.get_music_cue() == "mus_main_theme", "main menu plays the main theme")
	check(not AudioDirector.get_active_ambience().playing and not AudioDirector.get_active_ambience_detail().playing, "main menu stops world ambience")
	AudioDirector.set_location("corridor", 0.2)
	await wait(0.3)
	check(not AudioDirector.get_active_ambience().playing, "location changes behind the menu stay silent")
	menu.seek(menu.stream.get_length() - 5.0)
	await wait(1.5)
	var menu_again: AudioStreamPlayer = AudioDirector.get_active_music()
	check(menu_again != menu and menu_again.playing and menu_again.get_playback_position() < 2.0 and menu.playing, "main theme crossfades its tail into a fresh start")
	await wait(4.0)
	check(not menu.playing and menu_again.playing, "old pass fades out after the loop crossfade")
	AudioDirector.end_music_context("main_menu")
	await wait(3.0)
	check(AudioDirector.get_active_ambience().playing and AudioDirector.get_music_cue() == "mus_narrative", "leaving the menu restores ambience and exploration music")

	# Repeat with a rest: tail fades out, silence, then the cue starts again.
	AudioDirector.register_cue("qa_rest", {"stream": "res://audio/music/mus_transition_unease_01.ogg", "bus": "Music", "tail_fade": 1.0, "repeat_after": 1.5})
	AudioDirector.play_music("qa_rest", 0.01)
	await get_tree().process_frame
	var rest: AudioStreamPlayer = AudioDirector.get_active_music()
	rest.seek(rest.stream.get_length() - 1.5)
	await wait(1.9)
	check(not rest.playing, "tail fade ends the pass")
	await wait(0.4)
	check(not AudioDirector.get_active_music().playing, "music rests in silence before repeating")
	await wait(1.2)
	check(AudioDirector.get_active_music().playing and AudioDirector.get_active_music().get_playback_position() < 1.0, "cue starts again after its rest")
	AudioDirector.stop_music(0.01)
	await wait(1.0)
	check(not AudioDirector.get_active_music().playing, "stopping music cancels a pending repeat")

	# Credits play once over silence, then end.
	AudioDirector.start_music_context("ending_credits")
	await wait(3.3)
	var credits: AudioStreamPlayer = AudioDirector.get_active_music()
	check(credits.playing and AudioDirector.get_music_cue() == "mus_ending_credits" and not AudioDirector.get_active_ambience().playing, "credits play over silence")
	AudioDirector.set_setting("volume_music", 0.25)
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.25)) < 0.01, "music volume setting scales the soundtrack bus")
	AudioDirector.set_setting("volume_music", 1.0)
	AudioDirector.clear_music_contexts()
	AudioDirector.stop_music(0.01)

func test_pause_menu_audio_settings() -> void:
	var menu: PauseMenu = (load("res://scenes/ui/PauseMenu.tscn") as PackedScene).instantiate()
	add_child(menu)
	AudioDirector.set_setting("volume_music", 0.6)
	menu.open()
	var music_slider := menu.get_node("Root/Panel/Margin/VBox/Audio/Music") as HSlider
	check(is_equal_approx(music_slider.value, 0.6), "pause menu shows the current music volume")
	music_slider.value = 0.3
	check(is_equal_approx(AudioDirector.get_setting("volume_music"), 0.3), "music slider changes the music volume setting")
	(menu.get_node("Root/Panel/Margin/VBox/Audio/Voice") as HSlider).value = 0.8
	check(is_equal_approx(AudioDirector.get_setting("volume_voice"), 0.8), "dialogue slider changes the voice volume setting")
	(menu.get_node("Root/Panel/Margin/VBox/Accessibility/ReduceStartlingAudio") as CheckBox).button_pressed = true
	check(AudioDirector.get_setting("reduce_startling_audio") == true, "pause menu toggles reduce startling audio")
	menu.close()
	menu.queue_free()
	for key: String in ["volume_music", "volume_voice"]:
		AudioDirector.set_setting(key, 1.0)
	AudioDirector.set_setting("reduce_startling_audio", false)
	await get_tree().process_frame
