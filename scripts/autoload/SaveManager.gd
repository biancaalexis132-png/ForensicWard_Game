extends Node
## SaveManager: versioned save/load of all mutable state (Autoload "SaveManager").
##
## Managers register as *providers* that implement:
##     to_save_data() -> Dictionary   # canonical mutable state only
##     load_save_data(data: Dictionary) -> void
##     reset_state() -> void          # back to a fresh run
## Authored content (res://data) is never saved; only run state is.
##
## Save file layout (user://saves/slot_<n>.json):
##     {save_version, game_version, saved_at_unix, seed, checksum, state: {provider: {...}}}
## The checksum is SHA-256 of the canonical state JSON (sorted keys). It
## detects corruption; it is not anti-cheat.

## Version history:
##   1  Sprints 1-3: one chapter; the "chapter" provider is flat.
##   2  F1 campaign: the "chapter" provider keeps state per chapter id.
##   3  F2 zones: door state moves from "world" to "zones", per zone id.
##   4  Protagonist profile and Continuing Practice; legacy campaign state unchanged.
const SAVE_VERSION: int = 4
const SAVE_DIR: String = "user://saves"
## Older save versions migrate forward one step at a time:
## version N -> _migrate_from_N(data) -> data at version N + 1.
## The checksum is verified on the file as written, before any migration.
const MIGRATIONS: Dictionary = {1: "_migrate_from_1", 2: "_migrate_from_2", 3: "_migrate_from_3"}
## Every version 1 save was made in Chapter 1.
const V1_CHAPTER_ID: String = "ch1"
## Every version 1 and 2 save was made in the clinical wing, the only zone then.
const V2_ZONE_ID: String = "zone_clinical_wing"

## Master seed for all deterministic randomness in a run.
var run_seed: int = 1968

var _providers: Dictionary[String, Object] = {}


func register_provider(key: String, provider: Object) -> void:
	for method: String in ["to_save_data", "load_save_data", "reset_state"]:
		assert(provider.has_method(method), "Save provider '%s' lacks %s()" % [key, method])
	_providers[key] = provider


func unregister_provider(key: String) -> void:
	_providers.erase(key)


## A seeded RNG for one named random stream. The same seed and stream id
## always give the same sequence, so outcomes are reproducible.
func make_rng(stream_id: String) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%d:%s" % [run_seed, stream_id])
	return rng


## Starts a fresh run: every provider resets to authored initial state.
func reset_all(new_seed: int = 1968) -> void:
	run_seed = new_seed
	for key: String in _sorted_keys():
		_providers[key].reset_state()


## Canonical snapshot of all run state. Used for saves and determinism tests.
func capture_state() -> Dictionary:
	var state: Dictionary = {}
	for key: String in _sorted_keys():
		state[key] = _providers[key].to_save_data()
	return state


func get_slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot))


func save_game(slot: int = 1) -> Error:
	# Round-trip through JSON first so the checksum is computed on exactly
	# what load_game() will see (JSON turns ints into floats, etc.).
	var state: Dictionary = JSON.parse_string(JSON.stringify(capture_state()))
	var document: Dictionary = {
		"save_version": SAVE_VERSION,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "0.1.0")),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"seed": run_seed,
		"checksum": _checksum(state),
		"state": state,
	}
	var error: Error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if error != OK and error != ERR_ALREADY_EXISTS:
		return _fail(slot, "cannot create save folder (%s)" % error_string(error))

	# Write to a temp file, then rename, so a crash never leaves half a save.
	var final_path: String = get_slot_path(slot)
	var temp_path: String = final_path + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return _fail(slot, "cannot write %s (%s)" % [temp_path, error_string(FileAccess.get_open_error())])
	file.store_string(JSON.stringify(document, "\t", true))
	file.close()
	if FileAccess.file_exists(final_path):
		DirAccess.remove_absolute(final_path)
	error = DirAccess.rename_absolute(temp_path, final_path)
	if error != OK:
		return _fail(slot, "cannot finalize save (%s)" % error_string(error))
	EventBus.game_saved.emit(slot)
	return OK


func load_game(slot: int = 1) -> Error:
	var path: String = get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return _fail(slot, "no save in slot %d" % slot, ERR_FILE_NOT_FOUND)
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return _fail(slot, "save file is not valid JSON (line %d: %s)" % [json.get_error_line(), json.get_error_message()], ERR_PARSE_ERROR)

	var document: Dictionary = json.data
	var version: int = int(document.get("save_version", 0))
	if version > SAVE_VERSION:
		return _fail(slot, "save is from a newer build (v%d > v%d)" % [version, SAVE_VERSION], ERR_INVALID_DATA)
	# Verify what was written, before migrations change the state.
	if not document.get("state") is Dictionary or _checksum(document["state"]) != document.get("checksum", ""):
		return _fail(slot, "checksum mismatch: the save file was modified or corrupted", ERR_FILE_CORRUPT)
	while version < SAVE_VERSION:
		if not MIGRATIONS.has(version):
			return _fail(slot, "no migration from save v%d" % version, ERR_INVALID_DATA)
		document = call(MIGRATIONS[version], document)
		version += 1

	var state: Dictionary = document["state"]
	# Preflight optional provider contracts before changing any live state or seed.
	for key: String in _sorted_keys():
		if state.has(key) and _providers[key].has_method("validate_save_data"):
			if not _providers[key].call("validate_save_data", state[key]):
				return _fail(slot, "invalid saved %s data" % key, ERR_INVALID_DATA)

	run_seed = int(document.get("seed", run_seed))
	for key: String in _sorted_keys():
		if state.has(key):
			_providers[key].load_save_data(state[key])
		else:
			_providers[key].reset_state()
	EventBus.game_loaded.emit(slot)
	return OK


func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(get_slot_path(slot))


## v1 -> v2: the flat Chapter 1 story state moves under "ch1".
func _migrate_from_1(document: Dictionary) -> Dictionary:
	var migrated: Dictionary = document.duplicate(true)
	var state: Dictionary = migrated["state"]
	if state.has("chapter"):
		state["chapter"] = {"current": V1_CHAPTER_ID, "chapters": {V1_CHAPTER_ID: state["chapter"]}}
	migrated["save_version"] = 2
	return migrated


## v2 -> v3: door states move from "world" to "zones", under the clinical wing.
func _migrate_from_2(document: Dictionary) -> Dictionary:
	var migrated: Dictionary = document.duplicate(true)
	var state: Dictionary = migrated["state"]
	if state.get("world") is Dictionary:
		var objects: Variant = state["world"].get("objects", {})
		state["world"].erase("objects")
		state["zones"] = {"current": V2_ZONE_ID, "objects": {V2_ZONE_ID: objects}}
	migrated["save_version"] = 3
	return migrated


func _checksum(state: Dictionary) -> String:
	return JSON.stringify(state, "", true).sha256_text()


func _sorted_keys() -> Array[String]:
	var keys: Array[String] = []
	keys.assign(_providers.keys())
	keys.sort()
	return keys


func _fail(slot: int, reason: String, error: Error = FAILED) -> Error:
	push_warning("SaveManager: slot %d: %s" % [slot, reason])
	EventBus.save_failed.emit(slot, reason)
	return error


func _migrate_from_3(document: Dictionary) -> Dictionary:
	var migrated: Dictionary = document.duplicate(true)
	var state: Dictionary = migrated["state"]
	if not state.has("protagonist"):
		state["protagonist"] = ProtagonistProfile.default_data()
	if not state.has("continuing_practice"):
		state["continuing_practice"] = ContinuingPractice.default_data()
	migrated["save_version"] = 4
	return migrated
