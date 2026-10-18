extends TestCase
## F1 campaign contract: data/campaign.json, ids that stay unique and
## prefixed across chapters, chapter-scoped story state, and save version 2
## with its migration from version 1 saves.
##
## Chapters 2-5 exist only as test fixtures (scripts/tests/fixtures/campaign),
## so no later-chapter text ships in res://data before it is approved.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const FIXTURE_DIR: String = "res://scripts/tests/fixtures/campaign"
const FIXTURE_DATA_DIR: String = "user://test_campaign"
const V1_SAVE: String = "res://scripts/tests/fixtures/saves/save_v1_ch1_night_pending.json"
const ELIAS: String = "pt_elias_ward"
const FIXTURE_CHAPTERS: Array[String] = ["ch2", "ch3", "ch4", "ch5"]

var _main: Node3D = null
var _director: ChapterDirector = null
var _beats: Array[String] = []


func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	if is_instance_valid(_director):
		_director.free()
	if EventBus.story_beat_fired.is_connected(_record_beat):
		EventBus.story_beat_fired.disconnect(_record_beat)
	ContentRegistry.load_all(ContentRegistry.DATA_DIR)
	_remove_dir(FIXTURE_DATA_DIR)
	super.after_each()


# --- Shipped campaign ------------------------------------------------------------------

func test_campaign_names_ashcroft_and_five_chapters() -> void:
	check(ContentRegistry.is_valid, "shipped content validates: %s" % str(ContentRegistry.errors))
	check_eq(ContentRegistry.get_institution_name(), "Ashcroft State Forensic Hospital", "approved name")
	check_eq(ContentRegistry.get_chapter_ids(), ["ch1", "ch2", "ch3", "ch4", "ch5"] as Array[String], "chapters")
	check_eq(ContentRegistry.get_start_chapter_id(), "ch1", "starts in chapter 1")
	check(ContentRegistry.is_chapter_playable("ch1"), "chapter 1 playable")
	check(ContentRegistry.is_chapter_playable("ch2"), "chapter 2 opening is playable")
	for chapter_id: String in ["ch3", "ch4", "ch5"]:
		check(not ContentRegistry.is_chapter_playable(chapter_id), "%s ships no story yet" % chapter_id)
		check(ContentRegistry.get_story(chapter_id).is_empty(), "%s has no story text in res://data" % chapter_id)
	check_eq(ContentRegistry.get_story(), ContentRegistry.get_story("ch1"), "default story is the start chapter")
	check_eq(ContentRegistry.get_world(), ContentRegistry.get_world("ch1"), "default world is the start chapter")


func test_existing_chapter1_ids_still_resolve() -> void:
	var story: Dictionary = ContentRegistry.get_story("ch1")
	var objective_ids: Array = story["objectives"].map(func(o: Dictionary) -> String: return o["id"])
	check_eq(objective_ids, ["obj_meet_bennett", "obj_see_elias", "obj_document", "obj_act", "obj_compare_records",
			"obj_sign_out", "obj_w0b", "obj_end"], "objective ids unchanged")
	var beat_ids: Array = story["beats"].map(func(b: Dictionary) -> String: return b["id"])
	check_eq(beat_ids, ["beat_b2_handover", "beat_b6_intercom", "beat_b6_unease"], "beat ids unchanged")
	check(not ContentRegistry.get_dialogue(ELIAS).is_empty(), "Elias dialogue loads through the campaign")


# --- Validation ----------------------------------------------------------------------------

func test_fixture_chapters_validate() -> void:
	var report: Dictionary = ContentValidator.validate_documents(_fixture_campaign_documents())
	check(report["errors"].is_empty(), "five-chapter fixture validates: %s" % str(report["errors"]))


func test_duplicate_id_across_chapters_names_both_files() -> void:
	var docs: Dictionary = _fixture_campaign_documents()
	docs[ContentRegistry.STORY_KEY + "ch3"]["data"]["objectives"][0]["id"] = "obj_meet_bennett"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "[story_ch3_fixture.json] objectives[0].id: id 'obj_meet_bennett' is already used at [story_chapter1.json] objectives[0].id",
			"cross-chapter duplicate")


func test_id_without_its_prefix_fails() -> void:
	var docs: Dictionary = _fixture_campaign_documents()
	docs[ContentRegistry.STORY_KEY + "ch2"]["data"]["beats"][0]["id"] = "ch2_opening"
	docs["clues"]["data"]["hypotheses"][0]["id"] = "identity_reuse"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "beat id 'ch2_opening' must start with 'beat_'", "beat prefix")
	check_contains(report["errors"], "hypothesis id 'identity_reuse' must start with 'hyp_'", "hypothesis prefix")


func test_planned_chapter_cannot_ship_a_story() -> void:
	var problems: Array[String] = []
	var docs: Dictionary = ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)
	var chapter: Dictionary = docs["campaign"]["data"]["chapters"][2]
	chapter["story"] = "story_ch3_fixture.json"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "a planned chapter ships no story or world yet", "planned stays empty")


func test_story_must_match_its_chapter() -> void:
	var docs: Dictionary = _fixture_campaign_documents()
	docs[ContentRegistry.STORY_KEY + "ch4"]["data"]["chapter"] = "ch3"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "'ch3' does not match the campaign chapter 'ch4'", "story/chapter mismatch")


func test_chapter_references_are_checked() -> void:
	var docs: Dictionary = _fixture_campaign_documents()
	docs[ContentRegistry.STORY_KEY + "ch2"]["data"]["beats"][1]["actions"][0] = {"start_chapter": "ch9"}
	docs[ContentRegistry.STORY_KEY + "ch5"]["data"]["beats"][0]["when"] = {"chapter_completed": "chapter_one"}
	docs["campaign"]["data"]["start_chapter"] = "ch3"
	docs["campaign"]["data"]["chapters"][2]["status"] = "planned"
	docs["campaign"]["data"]["chapters"][2].erase("story")
	docs.erase(ContentRegistry.STORY_KEY + "ch3")
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "start_chapter: unknown chapter id 'ch9'", "unknown chapter in an action")
	check_contains(report["errors"], "chapter_completed: unknown chapter id 'chapter_one'", "unknown chapter in a condition")
	check_contains(report["errors"], "start_chapter: 'ch3' is not playable", "start chapter must be playable")


func test_one_dialogue_file_per_patient() -> void:
	var docs: Dictionary = _fixture_campaign_documents()
	var key: String = ContentRegistry.DIALOGUE_KEY + "dialogue.json"
	docs[ContentRegistry.DIALOGUE_KEY + "dialogue_copy.json"] = {"file": "dialogue_copy.json",
			"data": docs[key]["data"].duplicate(true), "schema": docs[key]["schema"]}
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "already has dialogue in dialogue.json", "duplicate dialogue owner")


func test_campaign_file_names_stay_in_the_data_folder() -> void:
	_write_fixture_data_dir({"story_override": "../story_chapter1.json"})
	var registry: Node = load("res://scripts/autoload/ContentRegistry.gd").new()
	registry.log_problems = false
	check(not registry.load_all(FIXTURE_DATA_DIR), "path outside the data folder is refused")
	check_contains(registry.errors, "is not a file name inside the data folder", "says why")
	registry.free()


func test_macos_metadata_in_data_folder_is_ignored() -> void:
	_write_fixture_data_dir({})
	var junk: FileAccess = FileAccess.open(FIXTURE_DATA_DIR + "/._campaign.json", FileAccess.WRITE)
	junk.store_buffer(PackedByteArray([0, 5, 22, 7, 0, 2, 0, 0, 0xff, 0xfe]))
	junk.close()
	check(ContentRegistry.load_all(FIXTURE_DATA_DIR), "AppleDouble companion does not break loading: %s" % str(ContentRegistry.errors))


# --- Chapter-scoped story state ----------------------------------------------------------------

func test_chapters_keep_their_own_state_and_never_refire() -> void:
	_load_fixture_campaign()
	_start_director()
	_talk("staff_bennett")
	check(_director.has_fired("beat_b2_handover"), "chapter 1 handover fired")
	_director.set_flag(StoryLogic.CHAPTER_COMPLETE_FLAG)
	check(_director.start_chapter("ch2"), "moves to chapter 2")
	check_eq(_director.get_chapter_id(), "ch2", "current chapter")
	check(_director.has_completed("ch1"), "chapter 1 recorded as complete")
	check(_director.has_fired("beat_ch2_fixture_open"), "chapter 2 beat reads chapter 1's state")
	check_eq(_director.get_current_objective().get("id", ""), "obj_ch2_fixture", "chapter 2 objective")
	_talk("staff_bennett")
	check_eq(_beats.count("beat_b2_handover"), 1, "chapter 1 beat does not fire again in chapter 2")
	check(not _director.start_chapter("ch2"), "starting the running chapter is a no-op")
	check(not _director.start_chapter("ch9"), "unknown chapter refused")


func test_story_actions_walk_all_five_chapters() -> void:
	_load_fixture_campaign()
	_start_director()
	var started: Array[String] = []
	var on_start: Callable = func(id: String) -> void: started.append(id)
	EventBus.chapter_started.connect(on_start)
	_director.set_flag(StoryLogic.CHAPTER_COMPLETE_FLAG)
	_director.start_chapter("ch2")
	for chapter: String in ["ch2", "ch3", "ch4"]:
		_director.set_flag(chapter + "_done")
		await runner.get_tree().process_frame  # start_chapter actions are deferred.
	EventBus.chapter_started.disconnect(on_start)
	check_eq(started, ["ch2", "ch3", "ch4", "ch5"] as Array[String], "start_chapter actions advance in order")
	check(_director.has_flag("ch5_saw_ch2"), "chapter 5 recovery route reads a chapter 2 flag")
	check_eq(_director.get_chapter_flags("ch2"), ["ch2_done", "ch2_opened"], "chapter 2 flags kept")


func test_save_and_load_between_chapters() -> void:
	_load_fixture_campaign()
	_start_director()
	_talk("staff_bennett")
	_director.set_flag(StoryLogic.CHAPTER_COMPLETE_FLAG)
	_director.start_chapter("ch2")
	var before: Dictionary = SaveManager.capture_state()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save in chapter 2")
	SaveManager.reset_all()
	check_eq(_director.get_chapter_id(), "ch1", "reset returns to the start chapter")
	_beats.clear()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	await runner.get_tree().process_frame
	check_eq(_director.get_chapter_id(), "ch2", "back in chapter 2")
	check(_director.has_completed("ch1"), "chapter 1 still complete")
	check(_beats.is_empty(), "loading fires no beats, got %s" % str(_beats))
	check_eq(JSON.stringify(SaveManager.capture_state(), "", true), JSON.stringify(before, "", true),
			"state round-trips exactly")


func test_same_inputs_give_the_same_state_across_chapters() -> void:
	_load_fixture_campaign()
	_start_director()
	var runs: Array[String] = []
	for _run: int in 2:
		SaveManager.reset_all(1968)
		_talk("staff_bennett")
		TimeManager.advance(30, "test")
		_director.set_flag(StoryLogic.CHAPTER_COMPLETE_FLAG)
		_director.start_chapter("ch2")
		_director.set_flag("ch2_done")
		await runner.get_tree().process_frame
		runs.append(JSON.stringify(SaveManager.capture_state(), "", true))
	check_eq(runs[0], runs[1], "deterministic across a chapter transition")


# --- Save version 2 ---------------------------------------------------------------------------

func test_version1_save_from_main_migrates() -> void:
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	_install_save(FileAccess.get_file_as_string(V1_SAVE))
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "v1 save loads")
	var director: ChapterDirector = _main.get_node("ChapterDirector")
	check_eq(director.get_chapter_id(), "ch1", "migrated into chapter 1")
	check(director.has_fired("beat_b2_handover"), "fired beats kept")
	check(not director.has_fired("beat_b6_intercom"), "pending beat still pending")
	check_eq(TimeManager.get_shift(), "night", "night shift kept")
	TimeManager.advance(15, "test")
	check(director.has_fired("beat_b6_intercom"), "pending intercom fires after migration")
	var logged: Array = PatientManager.get_state(ELIAS)["audit"].filter(
			func(e: Dictionary) -> bool: return e["type"] == "transfer_request_logged")
	check_eq(logged.size(), 1, "exactly once")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "re-save")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.get_slot_path(TEST_SAVE_SLOT)))
	check_eq(int(saved["save_version"]), SaveManager.SAVE_VERSION, "re-saved as the current version")


func test_tampered_version1_save_is_rejected_before_migration() -> void:
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	_install_save(FileAccess.get_file_as_string(V1_SAVE).replace("\"staff_bennett\"", "\"staff_hale\""))
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), ERR_FILE_CORRUPT, "checksum checked on the file as written")


# --- Helpers ----------------------------------------------------------------------------------

func _record_beat(beat_id: String) -> void:
	_beats.append(beat_id)


func _talk(staff_id: String) -> void:
	EventBus.interacted.emit("character:" + staff_id)


func _start_director() -> void:
	_director = ChapterDirector.new()
	runner.add_child(_director)
	SaveManager.reset_all()
	EventBus.story_beat_fired.connect(_record_beat)


func _install_save(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveManager.get_slot_path(TEST_SAVE_SLOT), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _load_fixture_campaign() -> void:
	_write_fixture_data_dir({})
	check(ContentRegistry.load_all(FIXTURE_DATA_DIR), "fixture campaign loads: %s" % str(ContentRegistry.errors))


## Shipped documents plus the chapter 2-5 fixtures, marked playable.
func _fixture_campaign_documents() -> Dictionary:
	var problems: Array[String] = []
	var docs: Dictionary = ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)
	check(problems.is_empty(), "shipped files parse: %s" % str(problems))
	_make_fixture_chapters_playable(docs["campaign"]["data"])
	for chapter_id: String in FIXTURE_CHAPTERS:
		var file_name: String = "story_%s_fixture.json" % chapter_id
		docs[ContentRegistry.STORY_KEY + chapter_id] = {"file": file_name, "schema": ContentSchemas.STORY_FILE,
				"data": JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [FIXTURE_DIR, file_name]))}
	return docs


func _make_fixture_chapters_playable(campaign: Dictionary) -> void:
	for chapter: Dictionary in campaign["chapters"]:
		if chapter["id"] in FIXTURE_CHAPTERS:
			chapter["status"] = "playable"
			chapter["story"] = "story_%s_fixture.json" % chapter["id"]


## Writes the shipped data plus the fixture chapters into FIXTURE_DATA_DIR.
## options.story_override replaces chapter 1's story file name.
func _write_fixture_data_dir(options: Dictionary) -> void:
	_remove_dir(FIXTURE_DATA_DIR)
	DirAccess.make_dir_recursive_absolute(FIXTURE_DATA_DIR)
	var docs: Dictionary = _fixture_campaign_documents()
	var campaign: Dictionary = docs["campaign"]["data"]
	if options.has("story_override"):
		campaign["chapters"][0]["story"] = options["story_override"]
	for key: String in docs:
		var file: FileAccess = FileAccess.open("%s/%s" % [FIXTURE_DATA_DIR, docs[key]["file"]], FileAccess.WRITE)
		file.store_string(JSON.stringify(docs[key]["data"], "\t"))
		file.close()


func _remove_dir(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file_name: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute("%s/%s" % [directory, file_name])
	DirAccess.remove_absolute(directory)
