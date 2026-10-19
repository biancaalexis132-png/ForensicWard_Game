extends Node
## Fast smoke check using every shipped panel recording (no test substitute).
func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	Settings.set_value("recap_narration", true)
	Settings.set_value("subtitles", true)
	var checked: Dictionary = {}
	var failures: int = 0
	for variant: String in ["ch1", "ch2", "ch3", "ch4", "review", "restricted", "inquiry"]:
		var chapter: String = variant if variant.begins_with("ch") else "ch5"
		var context: Dictionary = {}
		if chapter == "ch5":
			context = {"chapters": {"ch5": {"flags": ["ch5_ending_" + variant, "ch5_epilogue_" + variant]}}}
		var director: CutsceneDirector = load("res://scenes/cutscene/CutsceneDirector.tscn").instantiate()
		add_child(director)
		director.open({"cutscene_id": "cs_ch0%s_static_gn" % chapter.substr(2), "story_context": context})
		director.set_process(false)
		while director.is_open:
			var track: Dictionary = director.get("_track")
			var id: String = str(track.get("id", ""))
			await get_tree().create_timer(0.06).timeout
			director.advance(0.06)
			var valid: bool = not id.is_empty() and bool(director.get("_voice_on")) and not AudioDirector.narration_finished()
			valid = valid and director.get_node("Root/Subtitle").text == str(track.get("text", ""))
			valid = valid and absf(AudioDirector.narration_length() - float(track.get("duration_seconds", 0.0))) < 0.1
			if not valid:
				failures += 1
				print("FAIL production panel ", id)
			checked[id] = true
			director.next_panel()
		director.free()
		await get_tree().process_frame
	if checked.size() != 38:
		failures += 1
	AudioDirector.stop_narration()
	AudioDirector.clear_music_contexts()
	await get_tree().create_timer(0.2).timeout
	print("PRODUCTION_VOICE_RESULT unique=%d failed=%d" % [checked.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
