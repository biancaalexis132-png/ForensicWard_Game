extends TestCase
## Voiced dialogue: authored choices only, the psychiatrist's line then the
## response, narrator for a mute patient, skip and interruption, subtitle
## timing and fallbacks, story choices applied exactly once, and coverage of
## every authored passage by a recorded clip.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const ELIAS: String = "pt_elias_ward"
## Chapter 1's playable speakers with something to say.
const CHAPTER1_STAFF: Array[String] = ["staff_bennett", "staff_voss"]

var _main: Node3D = null
var _subtitles: Array[Dictionary] = []


func before_each() -> void:
	super.before_each()
	_subtitles.clear()
	EventBus.subtitle_shown.connect(_on_subtitle)
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	EventBus.subtitle_shown.disconnect(_on_subtitle)
	AudioDirector.stop_dialogue()
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func _on_subtitle(line_id: String, speaker: String, text: String, duration: float) -> void:
	_subtitles.append({"line_id": line_id, "speaker": speaker, "text": text, "duration": duration})


# --- Coverage -----------------------------------------------------------------------

func test_every_chapter1_speaker_has_recorded_lines() -> void:
	for staff_id: String in CHAPTER1_STAFF:
		var intro: String = ContentRegistry.get_staff(staff_id)["intro_line"]
		var line_id: String = AudioDirector.find_line(staff_id, intro)
		check(not line_id.is_empty(), staff_id + " intro line is recorded")
		check(AudioDirector.get_voice_stream(line_id) != null, staff_id + " intro clip loads")
	for line: Dictionary in ContentRegistry.get_story("ch1")["staff_lines"]:
		check(not AudioDirector.find_line(line["staff_id"], line["text"]).is_empty(), "staff line recorded: " + line["text"])
	for state: Dictionary in ContentRegistry.get_dialogue(ELIAS)["states"]:
		for choice: Dictionary in state["choices"]:
			var question: String = AudioDirector.find_choice_line(ELIAS, choice["id"])
			check(not question.is_empty() and AudioDirector.get_voice_stream(question) != null,
					"psychiatrist's question is voiced: " + choice["id"])
			var response: Array[Dictionary] = VoiceScript.segments(choice["response"], ELIAS)
			check(VoiceScript.has_voice(response), "response is narrated: " + choice["id"])
			for part: Dictionary in response:
				check_eq(part["speaker"], VoiceScript.NARRATOR, "a mute patient is never given words: " + choice["id"])


## Every authored passage a player can open is voiced (or narrated) line by line,
## with no blank text: the audit the owner asked for, as a regression test.
func test_every_authored_passage_has_a_clip() -> void:
	var missing: Array[String] = []
	for chapter_id: String in ContentRegistry.get_chapter_ids():
		var story: Dictionary = ContentRegistry.get_story(chapter_id)
		var passages: Array[String] = []
		for interaction: Dictionary in story.get("interactions", []):
			for key: String in ["body", "unavailable_body", "completed_body"]:
				if interaction.has(key):
					passages.append(interaction[key])
			for option: Dictionary in interaction["options"]:
				passages.append(option["response"])
		for passage: String in passages:
			for part: Dictionary in VoiceScript.segments(passage, VoiceScript.NARRATOR):
				check(not str(part["text"]).is_empty(), "no blank subtitle")
				if str(part["line_id"]).is_empty():
					missing.append("%s: %s" % [chapter_id, part["text"]])
	check_eq(missing, [] as Array[String], "every passage has a recorded clip (run tools/audio/extract_voice_lines.py)")
	for patient_id: String in ["pt_elias_ward", "pt_mara_ellis"]:
		for state: Dictionary in ContentRegistry.get_dialogue(patient_id)["states"]:
			for choice: Dictionary in state["choices"]:
				for part: Dictionary in VoiceScript.segments(choice["response"], patient_id):
					check(not str(part["line_id"]).is_empty(), "%s response voiced: %s" % [patient_id, part["text"]])


func test_voice_script_splits_speakers_and_stage_directions() -> void:
	var parts: Array[Dictionary] = VoiceScript.segments(
			"Voss: We start now.\n\n(She places two copies on the table.)\n\nThe door closes.\n\nHale counts the team in: four.",
			"pt_mara_ellis")
	check_eq(parts.size(), 4, "four paragraphs")
	check_eq([parts[0]["speaker"], parts[0]["text"]], ["staff_voss", "We start now."], "known prefix picks the voice")
	check_eq(parts[1]["speaker"], VoiceScript.NARRATOR, "stage direction is narrated")
	check_eq(parts[2]["speaker"], "pt_mara_ellis", "unprefixed text takes the default speaker")
	check_eq(parts[3]["speaker"], "pt_mara_ellis", "unknown prefixes are not treated as speakers")
	check_eq(VoiceScript.segments("[i]Charge Nurse[/i]", "staff_bennett")[0]["text"], "Charge Nurse", "BBCode stripped")


# --- Interview presentation -------------------------------------------------------

func test_free_text_field_is_hidden_in_normal_play() -> void:
	_approach_elias()
	check(not _interview()._ask_row.visible, "no typed-question field without --dev-free-text")
	check(not _interview().get_choice_labels().is_empty(), "authored choices offered")


func test_choice_plays_question_then_narrated_response_and_applies_once() -> void:
	_approach_elias()
	var minutes: int = TimeManager.total_minutes
	_interview().ask_choice("ask_intake")
	check(_interview().is_presenting(), "presentation running")
	check(_choice_button("ask_intake").disabled, "choices locked while lines play")
	check(PatientManager.get_state(ELIAS)["observations"].has("obs_mutism"), "choice applied immediately")
	await _frames(2)
	check_eq(_subtitles.size(), 1, "one line at a time")
	check_eq(_subtitles[0]["line_id"], AudioDirector.find_choice_line(ELIAS, "ask_intake"), "the psychiatrist speaks first")
	check_eq(_subtitles[0]["speaker"], "You", "subtitle names the speaker")
	var stream: AudioStream = AudioDirector.get_voice_stream(_subtitles[0]["line_id"])
	check(absf(float(_subtitles[0]["duration"]) - stream.get_length()) < 0.01, "subtitle lasts exactly as long as the clip")
	_interview().skip_line()
	await _wait_for_subtitles(2)
	check_eq(_subtitles[1]["speaker"], "", "the narrator describes the silent response")
	check_eq(_subtitles[1]["text"], DialogueManager.get_transcript(ELIAS)[1]["text"], "narration matches the approved response")
	_interview().skip_line()
	await _wait_until(func() -> bool: return not _interview().is_presenting())
	check(not _choice_button("ask_intake").disabled, "choices return after the response")
	check_eq(TimeManager.total_minutes - minutes, DialogueManager.QUESTION_MINUTES, "time advanced once")
	check_eq(DialogueManager.get_transcript(ELIAS).size(), 2, "one question and one response in the transcript")


func test_new_choice_or_close_interrupts_without_duplicates() -> void:
	_approach_elias()
	_interview().ask_choice("assess_motor")
	_interview().ask_choice("return_to_general")  # Replaces the running presentation.
	check_eq(PatientManager.get_state(ELIAS)["observations"].size(), 1, "the first choice recorded its finding once")
	await _frames(2)
	check_eq(_subtitles.back()["line_id"], AudioDirector.find_choice_line(ELIAS, "return_to_general"),
			"the new question plays; the old one stopped")
	_interview().close()
	var count: int = _subtitles.size()
	await _frames(10)
	check_eq(_subtitles.size(), count, "closing stops the voice")
	check(not AudioDirector.is_dialogue_playing() and not AudioDirector.is_voice_busy(), "voice channel released")


func test_missing_clip_falls_back_to_a_timed_subtitle() -> void:
	var player: ConversationPlayer = ConversationPlayer.new()
	_main.add_child(player)
	var done: Array[bool] = []
	player.finished.connect(func(completed: bool) -> void: done.append(completed))
	var unrecorded: Array[Dictionary] = [{"speaker": "staff_voss", "text": "A line with no recording at all.", "line_id": ""}]
	player.play(unrecorded)
	await _frames(2)
	check_eq(_subtitles.size(), 1, "the line is still shown")
	check_eq(_subtitles[0]["speaker"], "Dr Evelyn Voss", "speaker named from staff data")
	check_eq(float(_subtitles[0]["duration"]), AudioDirector.reading_seconds("A line with no recording at all."), "reading-time subtitle")
	player.skip_line()
	await _wait_until(func() -> bool: return not done.is_empty())
	check_eq(done, [true], "skipping the last line completes the conversation")
	player.free()


# --- Staff and story panels ---------------------------------------------------------

func test_talking_to_staff_plays_their_own_voice() -> void:
	var bennett: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character("staff_bennett")
	(bennett.get_node("Interactable") as Interactable).interact(_player())
	await _frames(3)
	var info: InfoPanel = _main.get_node("InfoPanel")
	check(info.is_open, "panel open")
	var expected: String = AudioDirector.find_line("staff_bennett", ContentRegistry.get_staff("staff_bennett")["intro_line"])
	check(_subtitles.any(func(s: Dictionary) -> bool: return s["line_id"] == expected), "Bennett speaks her line")
	info.skip_line()
	await _frames(3)
	info.close()
	check(not info.is_speaking(), "closing the panel stops its voice")


func test_story_option_buttons_lock_after_one_choice() -> void:
	var info: InfoPanel = _main.get_node("InfoPanel")
	var picks: Array[String] = []
	var listener: Callable = func(_interaction: String, option: String) -> void: picks.append(option)
	EventBus.story_option_selected.connect(listener)
	info.open({"title": "Test", "body": "Choose.", "interaction_id": "test_once",
			"options": [{"id": "a", "label": "A"}, {"id": "b", "label": "B"}]})
	info._select_option("test_once", "a")
	info._select_option("test_once", "b")
	EventBus.story_option_selected.disconnect(listener)
	check_eq(picks, ["a"] as Array[String], "a second click cannot advance the story twice")


# --- Helpers ------------------------------------------------------------------------

func _approach_elias() -> void:
	var elias: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character(ELIAS)
	(elias.get_node("Interactable") as Interactable).interact(_player())


func _choice_button(choice_id: String) -> Button:
	return _interview().find_child("Choice_" + choice_id, true, false) as Button


func _frames(count: int) -> void:
	for _i: int in count:
		await runner.get_tree().process_frame


func _wait_for_subtitles(count: int) -> void:
	await _wait_until(func() -> bool: return _subtitles.size() >= count)


func _wait_until(condition: Callable, max_seconds: float = 15.0) -> void:
	var waited: float = 0.0
	while waited < max_seconds:
		if condition.call():
			return
		await runner.get_tree().create_timer(0.05).timeout
		waited += 0.05
	check(false, "timed out waiting")


func _player() -> FirstPersonController:
	return _main.get_node("Player")


func _interview() -> InterviewScreen:
	return _main.get_node("InterviewScreen")
