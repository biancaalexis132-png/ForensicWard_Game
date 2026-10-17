extends TestCase
## Existing save contracts needed before any optional provider is added.
## Exercises the public on-disk load path; no protagonist behavior is implemented.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const PROVIDER_KEY: String = "test_optional_provider"
const FIXTURES: Array[String] = [
	"res://scripts/tests/fixtures/saves/save_v1_ch1_night_pending.json",
	"res://scripts/tests/fixtures/saves/save_v2_ch1_doors_open.json",
]

class OptionalProvider extends RefCounted:
	var value: String = "default"
	var resets: int = 0

	func to_save_data() -> Dictionary:
		return {"value": value}

	func load_save_data(data: Dictionary) -> void:
		value = data["value"]

	func reset_state() -> void:
		value = "default"
		resets += 1

var _main: Node3D = null
var _loaded_slots: Array[int] = []


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	_loaded_slots.clear()
	EventBus.game_loaded.connect(_record_loaded)


func after_each() -> void:
	EventBus.game_loaded.disconnect(_record_loaded)
	SaveManager.unregister_provider(PROVIDER_KEY)
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func test_rejected_loads_preserve_live_state_seed_and_events() -> void:
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "create a valid source save")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.get_slot_path(TEST_SAVE_SLOT)))
	var future: Dictionary = saved.duplicate(true)
	future["save_version"] = SaveManager.SAVE_VERSION + 1
	var unsupported: Dictionary = saved.duplicate(true)
	unsupported["save_version"] = 0
	var tampered: Dictionary = saved.duplicate(true)
	tampered["state"]["patients"] = {}
	var wrong_state: Dictionary = saved.duplicate(true)
	wrong_state["state"] = []
	var cases: Array[Dictionary] = [
		{"name": "future version", "text": JSON.stringify(future), "error": ERR_INVALID_DATA},
		{"name": "missing migration", "text": JSON.stringify(unsupported), "error": ERR_INVALID_DATA},
		{"name": "checksum mismatch", "text": JSON.stringify(tampered), "error": ERR_FILE_CORRUPT},
		{"name": "wrong state type", "text": JSON.stringify(wrong_state), "error": ERR_FILE_CORRUPT},
		{"name": "invalid JSON", "text": "{broken", "error": ERR_PARSE_ERROR},
	]
	# Make live state distinguishable from both a fresh run and the source save.
	PatientManager.open_record("pt_elias_ward")
	EvidenceManager.acquire_clue("clue_roster", "test:compatibility")
	TrustManager.adjust("staff_bennett", "respect", 5.0, "test:compatibility")
	SaveManager.run_seed = 7142
	var before: String = _snapshot()
	for item: Dictionary in cases:
		_write_save(item["text"])
		check_eq(SaveManager.load_game(TEST_SAVE_SLOT), item["error"], item["name"] + " rejected")
		check_eq(_snapshot(), before, item["name"] + " leaves all providers unchanged")
		check_eq(SaveManager.run_seed, 7142, item["name"] + " leaves seed unchanged")
		check(_loaded_slots.is_empty(), item["name"] + " emits no successful load")


func test_provider_added_after_save_resets_instead_of_retaining_previous_run() -> void:
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save without optional provider")
	var optional: OptionalProvider = OptionalProvider.new()
	SaveManager.register_provider(PROVIDER_KEY, optional)
	optional.value = "previous run"
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "older provider set loads")
	check_eq(optional.value, "default", "missing provider resets to neutral default")
	check_eq(optional.resets, 1, "reset exactly once")
	check_eq(_loaded_slots, [TEST_SAVE_SLOT] as Array[int], "one successful load event")


func test_real_v1_and_v2_saves_reset_new_provider_after_migration() -> void:
	var optional: OptionalProvider = OptionalProvider.new()
	SaveManager.register_provider(PROVIDER_KEY, optional)
	for fixture: String in FIXTURES:
		optional.value = "must not leak"
		var before_resets: int = optional.resets
		_write_save(FileAccess.get_file_as_string(fixture))
		check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, fixture + " migrates")
		check_eq(optional.value, "default", "legacy save defaults the added provider")
		check_eq(optional.resets, before_resets + 1, "one reset per load")
		var state: Dictionary = SaveManager.capture_state()
		check_eq(state["chapter"]["current"], "ch1", "chapter migration retained")
		check_eq(state["zones"]["current"], "zone_clinical_wing", "zone migration retained")
		check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "migrated save can be written")
		optional.value = "changed after saving"
		check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "migrated save reloads")
		check_eq(optional.value, "default", "new provider default survives re-save")


func test_added_provider_round_trips_and_reset_all_clears_it() -> void:
	var optional: OptionalProvider = OptionalProvider.new()
	SaveManager.register_provider(PROVIDER_KEY, optional)
	optional.value = "saved choice"
	SaveManager.run_seed = 31415
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save with added provider")
	var before: String = _snapshot()
	SaveManager.reset_all(2718)
	check_eq(optional.value, "default", "new run clears added provider")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load with added provider")
	check_eq(optional.value, "saved choice", "provider payload restored")
	check_eq(SaveManager.run_seed, 31415, "saved seed restored")
	check_eq(_snapshot(), before, "all state round trips with added provider")


func _record_loaded(slot: int) -> void:
	_loaded_slots.append(slot)


func _snapshot() -> String:
	return JSON.stringify(SaveManager.capture_state(), "", true)


func _write_save(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveManager.get_slot_path(TEST_SAVE_SLOT), FileAccess.WRITE)
	file.store_string(text)
	file.close()
