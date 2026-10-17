extends Node
## ContentRegistry: loads and validates all authored data at boot (Autoload "ContentRegistry").
##
## Every global file in MANIFEST is parsed, then data/campaign.json names the
## rest: the dialogue files and, per chapter, a story and a world file. Each
## document is checked against its ContentSchemas contract, then
## cross-referenced (unknown ids, duplicates across all chapters, id
## prefixes, dangling dialogue states). Content is frozen read-only after
## loading: authored data is immutable, and run state lives in the managers.
##
## If validation fails, `is_valid` is false and `errors` lists actionable
## messages naming the file, the JSON path and the fix. Main shows them on
## screen instead of starting the game.

## Global files: key -> [file name under res://data, schema].
const MANIFEST: Dictionary = {
	"patients": ["patients.json", ContentSchemas.PATIENTS_FILE],
	"clinical_rules": ["clinical_rules.json", ContentSchemas.CLINICAL_RULES_FILE],
	"clues": ["clues.json", ContentSchemas.CLUES_FILE],
	"source_catalog": ["source_catalog.json", ContentSchemas.SOURCE_CATALOG_FILE],
	"staff": ["staff.json", ContentSchemas.STAFF_FILE],
	"intent_lexicon": ["intent_lexicon.json", ContentSchemas.INTENT_LEXICON_FILE],
	"campaign": ["campaign.json", ContentSchemas.CAMPAIGN_FILE],
	"zones": ["zones.json", ContentSchemas.ZONES_FILE],
}
## Document keys for files the campaign names: "dialogue:<file>",
## "story:<chapter id>", "world:<chapter id>".
const DIALOGUE_KEY: String = "dialogue:"
const STORY_KEY: String = "story:"
const WORLD_KEY: String = "world:"
const DATA_DIR: String = "res://data"

var is_valid: bool = false
## Tests that load deliberately broken content set this false to keep logs clean.
var log_problems: bool = true
var errors: Array[String] = []
var warnings: Array[String] = []

var _patients: Dictionary = {}       ## id -> patient
var _dialogues: Dictionary = {}      ## patient_id -> dialogue document
var _rules: Array = []
var _actions: Dictionary = {}        ## id -> clinical action
var _clues: Dictionary = {}          ## id -> clue
var _hypotheses: Dictionary = {}     ## id -> authored hypothesis
var _sources: Dictionary = {}        ## id -> catalog item
var _staff: Dictionary = {}          ## id -> staff member
var _lexicon: Dictionary = {}
var _campaign: Dictionary = {}
var _chapters: Dictionary = {}       ## chapter id -> campaign entry
var _worlds: Dictionary = {}         ## chapter id -> world wiring
var _stories: Dictionary = {}        ## chapter id -> story
var _zones: Dictionary = {}          ## zone id -> zone
var _connections: Dictionary = {}    ## connection id -> connection


func _ready() -> void:
	load_all(DATA_DIR)


## Loads every content file from `directory`. Returns true if valid.
func load_all(directory: String) -> bool:
	errors.clear()
	warnings.clear()
	var documents: Dictionary = collect_documents(directory, errors)

	if errors.is_empty():
		var report: Dictionary = ContentValidator.validate_documents(documents)
		errors.assign(report["errors"])
		warnings.assign(report["warnings"])

	is_valid = errors.is_empty()
	if is_valid:
		_build_indexes(documents)
	if log_problems:
		for message: String in errors:
			push_error("Content: " + message)
		for message: String in warnings:
			push_warning("Content: " + message)
	EventBus.content_loaded.emit({"errors": errors, "warnings": warnings, "files": documents.size()})
	return is_valid


## Parses the global files, then the files data/campaign.json names.
## Returns {key: {file, data, schema}}; parse problems go to `problems`.
## Tests use it to get mutable copies of the shipped content.
static func collect_documents(directory: String, problems: Array[String]) -> Dictionary:
	var documents: Dictionary = {}
	for key: String in MANIFEST:
		var file_name: String = MANIFEST[key][0]
		var parsed: Variant = _parse_file(directory, file_name, problems)
		if parsed != null:
			documents[key] = {"file": file_name, "data": parsed, "schema": MANIFEST[key][1]}
	if not documents.has("campaign") or not documents["campaign"]["data"] is Dictionary:
		return documents
	var campaign: Dictionary = documents["campaign"]["data"]
	var dialogue_files: Variant = campaign.get("dialogue_files", [])
	if dialogue_files is Array:
		for file_name: Variant in dialogue_files:
			_add_document(documents, DIALOGUE_KEY + str(file_name), directory, str(file_name),
					ContentSchemas.DIALOGUE_FILE, problems)
	var chapters: Variant = campaign.get("chapters", [])
	if chapters is Array:
		for chapter: Variant in chapters:
			if not chapter is Dictionary:
				continue
			var chapter_id: String = str(chapter.get("id", ""))
			if chapter.has("story"):
				_add_document(documents, STORY_KEY + chapter_id, directory, str(chapter["story"]),
						ContentSchemas.STORY_FILE, problems)
			if chapter.has("world"):
				_add_document(documents, WORLD_KEY + chapter_id, directory, str(chapter["world"]),
						ContentSchemas.WORLD_FILE, problems)
	return documents


# --- Queries (all returned data is read-only) -----------------------------------

func get_patient(patient_id: String) -> Dictionary:
	return _patients.get(patient_id, {})


func get_patient_ids() -> Array[String]:
	return _sorted(_patients)


func get_dialogue(patient_id: String) -> Dictionary:
	return _dialogues.get(patient_id, {})


func get_rules() -> Array:
	return _rules


## Clinical actions offered for a patient, in authored order.
func get_actions(patient_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action: Dictionary in _actions.values():
		if action["patient_id"] == patient_id:
			result.append(action)
	return result


func get_action(action_id: String) -> Dictionary:
	return _actions.get(action_id, {})


func get_clue(clue_id: String) -> Dictionary:
	return _clues.get(clue_id, {})


func get_clue_ids() -> Array[String]:
	return _sorted(_clues)


func get_hypothesis(hypothesis_id: String) -> Dictionary:
	return _hypotheses.get(hypothesis_id, {})


func get_hypothesis_ids() -> Array[String]:
	return _sorted(_hypotheses)


func get_source(source_id: String) -> Dictionary:
	return _sources.get(source_id, {})


func get_staff(staff_id: String) -> Dictionary:
	return _staff.get(staff_id, {})


func get_staff_ids() -> Array[String]:
	return _sorted(_staff)


func get_lexicon() -> Dictionary:
	return _lexicon


## The world wiring of a chapter (default: the start chapter). {} if it has none.
func get_world(chapter_id: String = "") -> Dictionary:
	return _worlds.get(_chapter_or_start(chapter_id), {})


## The story of a chapter (default: the start chapter). {} for planned chapters.
func get_story(chapter_id: String = "") -> Dictionary:
	return _stories.get(_chapter_or_start(chapter_id), {})


func get_zone(zone_id: String) -> Dictionary:
	return _zones.get(zone_id, {})


func get_zone_ids() -> Array[String]:
	return _sorted(_zones)


func get_connection(connection_id: String) -> Dictionary:
	return _connections.get(connection_id, {})


func get_connection_ids() -> Array[String]:
	return _sorted(_connections)


## Connections with an end in `zone_id`, sorted by id.
func get_connections_of(zone_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for connection_id: String in get_connection_ids():
		var connection: Dictionary = _connections[connection_id]
		for end: Dictionary in connection["ends"]:
			if end["zone"] == zone_id:
				result.append(connection)
				break
	return result


func get_campaign() -> Dictionary:
	return _campaign


func get_institution_name() -> String:
	return str(_campaign.get("institution", {}).get("name", ""))


func get_start_chapter_id() -> String:
	return str(_campaign.get("start_chapter", ""))


## Chapter ids in campaign order.
func get_chapter_ids() -> Array[String]:
	var ids: Array[String] = []
	for chapter: Dictionary in _campaign.get("chapters", []):
		ids.append(chapter["id"])
	return ids


func get_chapter(chapter_id: String) -> Dictionary:
	return _chapters.get(chapter_id, {})


func is_chapter_playable(chapter_id: String) -> bool:
	return _stories.has(chapter_id)


# --- Internals ------------------------------------------------------------------

static func _add_document(documents: Dictionary, key: String, directory: String, file_name: String,
		schema: Dictionary, problems: Array[String]) -> void:
	var parsed: Variant = _parse_file(directory, file_name, problems)
	if parsed != null:
		documents[key] = {"file": file_name, "data": parsed, "schema": schema}


static func _parse_file(directory: String, file_name: String, problems: Array[String]) -> Variant:
	if file_name.is_empty() or ".." in file_name or file_name.begins_with("/") or file_name.get_file().begins_with("._"):
		problems.append("[campaign.json] '%s' is not a file name inside the data folder." % file_name)
		return null
	var path: String = "%s/%s" % [directory, file_name]
	if not FileAccess.file_exists(path):
		problems.append("[%s] file is missing. Expected at %s." % [file_name, path])
		return null
	var json: JSON = JSON.new()
	var error: Error = json.parse(FileAccess.get_file_as_string(path))
	if error != OK:
		problems.append("[%s] line %d: invalid JSON: %s." % [file_name, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _build_indexes(documents: Dictionary) -> void:
	_patients = _index(documents["patients"]["data"]["patients"])
	_rules = _freeze(documents["clinical_rules"]["data"]["rules"])
	_actions = _index(documents["clinical_rules"]["data"].get("actions", []))
	_clues = _index(documents["clues"]["data"]["clues"])
	_hypotheses = _index(documents["clues"]["data"]["hypotheses"])
	_sources = _index(documents["source_catalog"]["data"]["items"])
	_staff = _index(documents["staff"]["data"]["staff"])
	_lexicon = _freeze(documents["intent_lexicon"]["data"])
	_campaign = _freeze(documents["campaign"]["data"])
	_chapters = _index(_campaign["chapters"])
	_zones = _index(documents["zones"]["data"]["zones"])
	_connections = _index(documents["zones"]["data"]["connections"])
	_dialogues = {}
	_stories = {}
	_worlds = {}
	for key: String in documents:
		var data: Variant = documents[key]["data"]
		if key.begins_with(DIALOGUE_KEY):
			_dialogues[data["patient_id"]] = _freeze(data)
		elif key.begins_with(STORY_KEY):
			_stories[key.trim_prefix(STORY_KEY)] = _freeze(data)
		elif key.begins_with(WORLD_KEY):
			_worlds[key.trim_prefix(WORLD_KEY)] = _freeze(data)


func _chapter_or_start(chapter_id: String) -> String:
	return chapter_id if not chapter_id.is_empty() else get_start_chapter_id()


func _index(items: Array) -> Dictionary:
	var result: Dictionary = {}
	for item: Dictionary in items:
		result[item["id"]] = _freeze(item)
	return result


## Recursively marks arrays and dictionaries read-only.
func _freeze(value: Variant) -> Variant:
	if value is Dictionary:
		for key: Variant in value:
			_freeze(value[key])
		(value as Dictionary).make_read_only()
	elif value is Array:
		for item: Variant in value:
			_freeze(item)
		(value as Array).make_read_only()
	return value


func _sorted(dictionary: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	keys.assign(dictionary.keys())
	keys.sort()
	return keys
