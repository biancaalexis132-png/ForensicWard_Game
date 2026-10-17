extends Node
## ContentRegistry: loads and validates all authored data at boot (Autoload "ContentRegistry").
##
## Every file in MANIFEST is parsed, checked against its ContentSchemas
## contract, then cross-referenced (unknown ids, duplicates, dangling
## dialogue states). Content is frozen read-only after loading: authored
## data is immutable, and run state lives in the managers.
##
## If validation fails, `is_valid` is false and `errors` lists actionable
## messages naming the file, the JSON path and the fix. Main shows them on
## screen instead of starting the game.

## key -> [file name under res://data, schema]
const MANIFEST: Dictionary = {
	"patients": ["patients.json", ContentSchemas.PATIENTS_FILE],
	"dialogue": ["dialogue.json", ContentSchemas.DIALOGUE_FILE],
	"clinical_rules": ["clinical_rules.json", ContentSchemas.CLINICAL_RULES_FILE],
	"clues": ["clues.json", ContentSchemas.CLUES_FILE],
	"source_catalog": ["source_catalog.json", ContentSchemas.SOURCE_CATALOG_FILE],
	"staff": ["staff.json", ContentSchemas.STAFF_FILE],
	"intent_lexicon": ["intent_lexicon.json", ContentSchemas.INTENT_LEXICON_FILE],
}
const DATA_DIR: String = "res://data"

var is_valid: bool = false
## Tests that load deliberately broken content set this false to keep logs clean.
var log_problems: bool = true
var errors: Array[String] = []
var warnings: Array[String] = []

var _patients: Dictionary = {}       ## id -> patient
var _dialogues: Dictionary = {}      ## patient_id -> dialogue document
var _rules: Array = []
var _clues: Dictionary = {}          ## id -> clue
var _hypotheses: Dictionary = {}     ## id -> authored hypothesis
var _sources: Dictionary = {}        ## id -> catalog item
var _staff: Dictionary = {}          ## id -> staff member
var _lexicon: Dictionary = {}


func _ready() -> void:
	load_all(DATA_DIR)


## Loads every manifest file from `directory`. Returns true if valid.
func load_all(directory: String) -> bool:
	errors.clear()
	warnings.clear()
	var documents: Dictionary = {}
	for key: String in MANIFEST:
		var file_name: String = MANIFEST[key][0]
		var parsed: Variant = _parse_file("%s/%s" % [directory, file_name])
		if parsed != null:
			documents[key] = {"file": file_name, "data": parsed, "schema": MANIFEST[key][1]}

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


# --- Queries (all returned data is read-only) -----------------------------------

func get_patient(patient_id: String) -> Dictionary:
	return _patients.get(patient_id, {})


func get_patient_ids() -> Array[String]:
	return _sorted(_patients)


func get_dialogue(patient_id: String) -> Dictionary:
	return _dialogues.get(patient_id, {})


func get_rules() -> Array:
	return _rules


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


# --- Internals ------------------------------------------------------------------

func _parse_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		errors.append("[%s] file is missing. Expected at %s." % [path.get_file(), path])
		return null
	var json: JSON = JSON.new()
	var error: Error = json.parse(FileAccess.get_file_as_string(path))
	if error != OK:
		errors.append("[%s] line %d: invalid JSON: %s." % [path.get_file(), json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _build_indexes(documents: Dictionary) -> void:
	_patients = _index(documents["patients"]["data"]["patients"])
	var dialogue: Dictionary = documents["dialogue"]["data"]
	_dialogues = {dialogue["patient_id"]: _freeze(dialogue)}
	_rules = _freeze(documents["clinical_rules"]["data"]["rules"])
	_clues = _index(documents["clues"]["data"]["clues"])
	_hypotheses = _index(documents["clues"]["data"]["hypotheses"])
	_sources = _index(documents["source_catalog"]["data"]["items"])
	_staff = _index(documents["staff"]["data"]["staff"])
	_lexicon = _freeze(documents["intent_lexicon"]["data"])


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
