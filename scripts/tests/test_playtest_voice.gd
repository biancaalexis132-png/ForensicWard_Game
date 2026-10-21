extends TestCase
## Owner playtest fixes: the protagonist's female/male choice (saved with the
## profile, picks the psychiatrist's voice with a male fallback) and Naomi
## Bennett's Chapter 1 opening, which must not say the same thing twice.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const PLAYER_LINE: String = "ch1_b2_player_001"
const BENNETT_GREETING: String = "ch1_b2_bennett_001"
const HANDOVER_SCENE: String = "ch1_b2_bennett_handover"

var _main: Node3D = null
var _subtitles: Array[String] = []


func after_each() -> void:
	AudioDirector.stop_dialogue()
	if EventBus.subtitle_shown.is_connected(_on_subtitle):
		EventBus.subtitle_shown.disconnect(_on_subtitle)
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func _on_subtitle(line_id: String, _speaker: String, _text: String, _duration: float) -> void:
	_subtitles.append(line_id)


func _choose_gender(gender: String) -> bool:
	var draft: Dictionary = ProtagonistProfile.get_profile()
	draft["gender"] = gender
	return ProtagonistProfile.apply_draft(draft)


# --- Gender choice ------------------------------------------------------------------

func test_profile_gender_round_trips_save_and_load() -> void:
	check_eq(ProtagonistProfile.gender(), "male", "a new game keeps the existing default voice")
	check(_choose_gender("female"), "female is a valid choice")
	check_eq(ProtagonistProfile.get_profile()["pronouns"], "", "free-text pronouns stay a separate field")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check_eq(ProtagonistProfile.gender(), "male", "reset restores the default")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check_eq(ProtagonistProfile.gender(), "female", "the choice survives save and load")
	check(_choose_gender("male"), "male is a valid choice")
	check_eq(ProtagonistProfile.gender(), "male", "the choice can be changed back")
	check(not _choose_gender("robot"), "a value outside the catalog is rejected")
	check_eq(ProtagonistProfile.gender(), "male", "a rejected draft changes nothing")


func test_saves_from_before_the_choice_still_load() -> void:
	var legacy: Dictionary = ProtagonistProfile.default_data()
	legacy.erase("gender")
	legacy["name"] = "Dr Legacy"
	legacy["configured"] = true
	check(ProtagonistProfile.validate_save_data(legacy), "a profile without gender is still valid")
	ProtagonistProfile.load_save_data(legacy)
	check_eq(ProtagonistProfile.get_profile()["name"], "Dr Legacy", "the old profile loads")
	check_eq(ProtagonistProfile.gender(), "male", "an old profile keeps the original voice")
	var bad: Dictionary = ProtagonistProfile.default_data()
	bad["gender"] = 7
	check(not ProtagonistProfile.validate_save_data(bad), "a non-text gender is rejected")


func test_profile_screen_offers_the_choice() -> void:
	var panel: ProtagonistScreen = load("res://scenes/ui/ProtagonistScreen.tscn").instantiate()
	runner.add_child(panel)
	var select: OptionButton = panel._fields.get("gender") as OptionButton
	check(select != null, "the profile screen has a gender selector")
	if select != null:
		var ids: Array[String] = []
		for index: int in select.item_count:
			ids.append(str(select.get_item_metadata(index)))
		check_eq(ids, ["female", "male"] as Array[String], "female and male are offered")
	check(panel._fields.get("pronouns") is LineEdit, "pronouns stay free text")
	panel.free()


func test_female_choice_selects_female_clip_with_male_fallback() -> void:
	var male_path: String = "res://audio/voice/ch1/%s.ogg" % PLAYER_LINE
	var female_path: String = "res://audio/voice/ch1/female/%s.ogg" % PLAYER_LINE
	check_eq(AudioDirector.get_voice_path(PLAYER_LINE), male_path, "default profile plays the male clip")
	check(_choose_gender("female"), "choose female")
	check_eq(AudioDirector.get_voice_variant("player"), "female", "the profile change reaches AudioDirector")
	check_eq(AudioDirector.get_voice_path(PLAYER_LINE), female_path, "female profile plays the female clip")
	var stream: AudioStream = AudioDirector.get_voice_stream(PLAYER_LINE)
	check(stream != null and stream.resource_path == female_path, "the female clip loads")
	check_eq(AudioDirector.get_voice_path(BENNETT_GREETING), "res://audio/voice/ch1/%s.ogg" % BENNETT_GREETING,
			"other speakers keep their own voice")
	# A player line with no female clip yet (here: a Bennett line relabelled as
	# the player's) falls back to the male clip.
	var original_greeting: Dictionary = AudioDirector._lines[BENNETT_GREETING].duplicate(true)
	AudioDirector._lines[BENNETT_GREETING]["speaker"] = "player"
	check_eq(AudioDirector.get_voice_path(BENNETT_GREETING), "res://audio/voice/ch1/%s.ogg" % BENNETT_GREETING,
			"missing female clip falls back to the male clip")
	AudioDirector._lines[BENNETT_GREETING] = original_greeting
	check(_choose_gender("male"), "choose male")
	check_eq(AudioDirector.get_voice_path(PLAYER_LINE), male_path, "male profile plays the male clip again")
	check(_choose_gender("female"), "choose female again")
	SaveManager.reset_all()
	check_eq(AudioDirector.get_voice_variant("player"), "", "a new game returns to the default voice")


func test_every_player_line_has_a_female_clip() -> void:
	check(_choose_gender("female"), "choose female")
	var count: int = 0
	for line_id: String in AudioDirector._lines:
		if AudioDirector._lines[line_id]["speaker"] != "player":
			continue
		count += 1
		check("/female/" in AudioDirector.get_voice_path(line_id), "female clip exists: " + line_id)
	check(count > 0, "player lines found")


# --- Naomi's opening ----------------------------------------------------------------

## Word triples shared between two texts, ignoring case and punctuation.
static func _shared_phrases(a: String, b: String) -> Array[String]:
	var shared: Array[String] = []
	var theirs: Dictionary = {}
	for phrase: String in _phrases(b):
		theirs[phrase] = true
	for phrase: String in _phrases(a):
		if theirs.has(phrase) and not phrase in shared:
			shared.append(phrase)
	return shared


static func _phrases(text: String) -> Array[String]:
	var clean: String = ""
	for character: String in text.to_lower():
		clean += character if character.is_valid_identifier() or character == "'" or character.is_valid_int() else " "
	var words: PackedStringArray = clean.split(" ", false)
	var result: Array[String] = []
	for index: int in maxi(0, words.size() - 2):
		result.append("%s %s %s" % [words[index], words[index + 1], words[index + 2]])
	return result


func test_naomi_opening_does_not_repeat_itself() -> void:
	var intro: String = ContentRegistry.get_staff("staff_bennett")["intro_line"]
	for line_id: String in AudioDirector.get_scene_lines(HANDOVER_SCENE):
		var line: Dictionary = AudioDirector.get_line(line_id)
		check_eq(_shared_phrases(intro, line["text"]), [] as Array[String],
				"her first panel and the handover do not repeat each other: " + line_id)
	check(AudioDirector.get_voice_stream(BENNETT_GREETING) != null, "the handover greeting clip loads")
	var intro_id: String = AudioDirector.find_line("staff_bennett", intro)
	check(AudioDirector.get_voice_stream(intro_id) != null, "the shortened intro is voiced")


func test_talking_to_naomi_again_does_not_replay_her_line() -> void:
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	EventBus.subtitle_shown.connect(_on_subtitle)
	var bennett: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character("staff_bennett")
	var info: InfoPanel = _main.get_node("InfoPanel")
	var intro_id: String = AudioDirector.find_line("staff_bennett", ContentRegistry.get_staff("staff_bennett")["intro_line"])
	(bennett.get_node("Interactable") as Interactable).interact(_main.get_node("Player"))
	await _frames(3)
	check(info.is_open and info.is_speaking(), "first talk: she speaks")
	check(intro_id in _subtitles, "first talk: her intro line plays")
	info.close()
	AudioDirector.cancel_pending_events()
	await runner.get_tree().create_timer(0.2).timeout
	_subtitles.clear()
	(bennett.get_node("Interactable") as Interactable).interact(_main.get_node("Player"))
	await _frames(3)
	check(info.is_open, "second talk: her panel still opens")
	check(not info.is_speaking(), "second talk: the heard line is not replayed")
	check(not intro_id in _subtitles, "second talk: no repeated subtitle")
	check_eq(_subtitles.filter(func(id: String) -> bool: return id in AudioDirector.get_scene_lines(HANDOVER_SCENE)),
			[] as Array[String], "the handover scene plays only once")
	info.close()


func _frames(count: int) -> void:
	for _i: int in count:
		await runner.get_tree().process_frame
