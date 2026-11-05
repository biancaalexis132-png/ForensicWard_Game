class_name Acknowledgements
extends RefCounted
## Acknowledgements: staff remember the player's earlier choices.
##
## data/acknowledgements.json lists lines, each for one staff member in one
## chapter, with a StoryLogic condition (usually a chapter_flag from an earlier
## chapter). The first time the player talks to that staff member in that
## chapter while the condition holds, the line opens their reply, once. Played
## line ids are saved by their own provider ("acknowledgements"), kept apart
## from story flags so the story's own record is unchanged. Lines play only once approved is true (new
## dialogue needs the owner's approval; see the review sheet in the notes).

const PATH: String = "res://data/acknowledgements.json"
const PROVIDER_KEY: String = "acknowledgements"


## Save provider: which acknowledgement lines have played.
class Log extends RefCounted:
	var played: Array[String] = []

	func to_save_data() -> Dictionary:
		return {"played": played.duplicate()}

	func load_save_data(data: Dictionary) -> void:
		played.assign(data.get("played", []))

	func reset_state() -> void:
		played.clear()


static var _log: Log = null

static var _lines: Array = []
static var _loaded: bool = false


## Registers the played-lines record with SaveManager (Main calls this).
static func register() -> void:
	if _log == null:
		_log = Log.new()
	SaveManager.register_provider(PROVIDER_KEY, _log)


static func has_played(line_id: String) -> bool:
	return _log != null and line_id in _log.played


static func lines() -> Array:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_lines = parsed.get("acknowledgements", []) if parsed is Dictionary else []
	return _lines


## Test hook: replace the loaded lines (pass [] then reload() to restore).
static func override(entries: Array) -> void:
	_lines = entries
	_loaded = true


static func reload() -> void:
	_loaded = false


## The line to open this staff member's reply with right now, or {} when none.
## Only approved, unplayed lines of the current chapter whose condition holds.
static func pending(director: ChapterDirector, staff_id: String) -> Dictionary:
	if director == null:
		return {}
	var state: Dictionary = director.get_story_context()
	for line: Dictionary in lines():
		if not bool(line.get("approved", false)) or line["staff_id"] != staff_id \
				or line["chapter"] != director.get_chapter_id() or has_played(line["id"]):
			continue
		if StoryLogic.evaluate(line["when"], state):
			return line
	return {}


## Returns the line's text and records it as played ("" when none is due).
static func take(director: ChapterDirector, staff_id: String) -> String:
	var line: Dictionary = pending(director, staff_id)
	if line.is_empty():
		return ""
	if _log == null:
		register()
	_log.played.append(str(line["id"]))
	return str(line["text"])


## Problems with data/acknowledgements.json ([] when valid).
static func validate() -> Array[String]:
	var problems: Array[String] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary or not parsed.get("acknowledgements") is Array:
		problems.append("[acknowledgements.json] needs an object with an acknowledgements array.")
		return problems
	var refs: Dictionary = {"staff": _id_set(ContentRegistry.get_staff_ids()), "patients": _id_set(ContentRegistry.get_patient_ids()),
			"clues": _id_set(ContentRegistry.get_clue_ids()), "hypotheses": _id_set(ContentRegistry.get_hypothesis_ids()),
			"chapters": _id_set(ContentRegistry.get_chapter_ids()), "zones": _id_set(ContentRegistry.get_zone_ids())}
	var seen: Dictionary = {}
	for i: int in parsed["acknowledgements"].size():
		var line: Variant = parsed["acknowledgements"][i]
		var where: String = "[acknowledgements.json] acknowledgements[%d]" % i
		if not line is Dictionary or not line.get("id") is String or not line.get("chapter") is String \
				or not line.get("staff_id") is String or not line.get("text") is String \
				or not line.get("when") is Dictionary or not line.get("approved") is bool:
			problems.append(where + ": needs string id, chapter, staff_id and text, a when condition and approved true/false.")
			continue
		if not str(line["id"]).begins_with("ack_"):
			problems.append(where + ": id must start with ack_.")
		if seen.has(line["id"]):
			problems.append(where + ": id '%s' is used twice." % line["id"])
		seen[line["id"]] = true
		if not line["chapter"] in ContentRegistry.get_chapter_ids():
			problems.append(where + ": unknown chapter '%s'." % line["chapter"])
		if ContentRegistry.get_staff(line["staff_id"]).is_empty():
			problems.append(where + ": unknown staff '%s'." % line["staff_id"])
		var errors: Array[String] = []
		StoryLogic.check_condition(line["when"], where + ".when", refs, errors)
		problems.append_array(errors)
		_check_flags_exist(line["when"], where, problems)
	return problems


## A chapter_flag condition must name a flag some story choice or beat sets.
static func _check_flags_exist(condition: Dictionary, where: String, problems: Array[String]) -> void:
	var kind: String = condition.keys()[0]
	match kind:
		"all", "any":
			for part: Dictionary in condition[kind]:
				_check_flags_exist(part, where, problems)
		"not":
			_check_flags_exist(condition["not"], where, problems)
		"chapter_flag":
			var chapter_id: String = condition[kind]["chapter"]
			var flag: String = condition[kind]["flag"]
			if not flag in _flags_set_in(chapter_id):
				problems.append(where + ": no choice or beat in %s sets '%s'." % [chapter_id, flag])


static func _flags_set_in(chapter_id: String) -> Array[String]:
	var flags: Array[String] = []
	var story: Dictionary = ContentRegistry.get_story(chapter_id)
	for interaction: Dictionary in story.get("interactions", []):
		for option: Dictionary in interaction["options"]:
			if option.has("flag"):
				flags.append(str(option["flag"]))
	for beat: Dictionary in story.get("beats", []):
		for action: Dictionary in beat["actions"]:
			if action.has("flag"):
				flags.append(str(action["flag"]))
	return flags


static func _id_set(ids: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for id: String in ids:
		result[id] = true
	return result
