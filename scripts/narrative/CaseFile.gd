class_name CaseFile
extends RefCounted
## CaseFile: the player's investigation at a glance, assembled read-only from
## state other systems already keep. It owns no state and saves nothing.
##
##   - Now: the current objective and where it happens (derived from the story
##     data: the interaction whose choice completes it, the staff member to
##     talk to, the zone, or the EHR / handover board).
##   - Noted: story choices the player has made that data/case_file.json lists,
##     each marked established, open (still uncertain) or care. Every note's
##     text is copied verbatim from the choice's approved response; validate()
##     enforces that, so the case file never says anything the story did not.
##   - Evidence: clues collected, and hypotheses with their status and the
##     ordinary explanations still open.
##
## Notes appear in authored story order, chapter by chapter. Order is
## deterministic and needs no save data: a note shows once its flag is set
## in its chapter (ChapterDirector.get_chapter_flags()).

const PATH: String = "res://data/case_file.json"
const STATUSES: Array[String] = ["established", "open", "care"]
const STATUS_LABELS: Dictionary = {"established": "Established", "open": "Still open", "care": "Care"}

static var _entries: Array = []
static var _loaded: bool = false


## Section D lines of the approved review sheet, shown under "Your record".
const RECORD_MORE_OPEN: String = "You left more questions open than you closed, and every one of them is written down. That's what lets someone else pick them up."
const RECORD_MORE_SETTLED: String = "Most of what you recorded will stand up to a second reader. The rest is marked for what it is."
const RECORD_EVERY_CARE_STEP: String = "No patient waited on this investigation. That was a choice, and you made it every time."
## D3: coverage confirmed in Chapters 3 and 5, and care escalated in Chapter 5.
const EVERY_CARE_STEP: Array = [["ch3", "ch3_coverage_confirmed"], ["ch5", "ch5_brief_coverage"], ["ch5", "ch5_care_escalated"]]


## The authored entries (data/case_file.json), loaded once.
static func entries() -> Array:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_entries = parsed.get("entries", []) if parsed is Dictionary else []
	return _entries


static func entry_for_flag(chapter_id: String, flag: String) -> Dictionary:
	for entry: Dictionary in entries():
		if entry["chapter"] == chapter_id and entry["flag"] == flag:
			return entry
	return {}


## Problems with data/case_file.json against the story files ([] when valid).
static func validate() -> Array[String]:
	var problems: Array[String] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary or not parsed.get("entries") is Array:
		problems.append("[case_file.json] needs an object with an entries array.")
		return problems
	var seen: Dictionary = {}
	for i: int in parsed["entries"].size():
		var entry: Variant = parsed["entries"][i]
		var where: String = "[case_file.json] entries[%d]" % i
		if not entry is Dictionary or not entry.get("chapter") is String or not entry.get("flag") is String \
				or not entry.get("text") is String or not entry.get("status") is String:
			problems.append(where + ": needs string chapter, flag, status and text.")
			continue
		if not entry["status"] in STATUSES:
			problems.append(where + ": status must be one of %s." % ", ".join(STATUSES))
		var key: String = entry["chapter"] + ":" + entry["flag"]
		if seen.has(key):
			problems.append(where + ": %s is listed twice." % key)
		seen[key] = true
		var option: Dictionary = _option_for_flag(entry["chapter"], entry["flag"])
		if option.is_empty():
			problems.append(where + ": no story choice in %s sets flag '%s'." % [entry["chapter"], entry["flag"]])
		elif str(entry["text"]).strip_edges().is_empty() or not str(option["option"]["response"]).contains(entry["text"]):
			problems.append(where + ": text must be copied verbatim from the response of the choice that sets '%s'." % entry["flag"])
	return problems


## Every note the player has earned so far, oldest chapter first:
## [{chapter, chapter_title, flag, status, text, source, choice}].
static func noted(director: ChapterDirector) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if director == null:
		return result
	for chapter_id: String in ContentRegistry.get_chapter_ids():
		var flags: Array = director.get_chapter_flags(chapter_id)
		if flags.is_empty():
			continue
		var story: Dictionary = ContentRegistry.get_story(chapter_id)
		for interaction: Dictionary in story.get("interactions", []):
			for option: Dictionary in interaction["options"]:
				var flag: String = str(option.get("flag", ""))
				if flag.is_empty() or not flag in flags:
					continue
				var entry: Dictionary = entry_for_flag(chapter_id, flag)
				if entry.is_empty() or result.any(func(n: Dictionary) -> bool: return n["chapter"] == chapter_id and n["flag"] == flag):
					continue
				result.append({"chapter": chapter_id, "chapter_title": str(story.get("title", chapter_id)),
						"flag": flag, "status": entry["status"], "text": entry["text"],
						"source": str(interaction["title"]), "choice": str(option["label"])})
	return result


## The closing paragraph of the end-of-campaign panel, built from the case file
## (approved by Bi 2026-11-05, review sheet section D). "" with nothing noted.
static func record_summary(director: ChapterDirector) -> String:
	var notes: Array[Dictionary] = noted(director)
	if notes.is_empty():
		return ""
	var counts: Dictionary = {"established": 0, "open": 0, "care": 0}
	for note: Dictionary in notes:
		counts[note["status"]] = int(counts.get(note["status"], 0)) + 1
	var lines: Array[String] = ["Your record: %s, %s, %s." % [
		_count(counts["established"], "finding preserved as found", "findings preserved as found"),
		_count(counts["open"], "question left honestly open", "questions left honestly open"),
		_count(counts["care"], "care decision that kept patients first", "care decisions that kept patients first")]]
	if counts["open"] > counts["established"]:
		lines.append(RECORD_MORE_OPEN)
	elif counts["established"] > counts["open"]:
		lines.append(RECORD_MORE_SETTLED)
	var all_care: bool = true
	for step: Array in EVERY_CARE_STEP:
		all_care = all_care and str(step[1]) in director.get_chapter_flags(str(step[0]))
	if all_care:
		lines.append(RECORD_EVERY_CARE_STEP)
	return "\n\n".join(lines)


static func _count(value: int, one: String, many: String) -> String:
	return "%d %s" % [value, one if value == 1 else many]


## Where the current objective happens ("With Naomi Bennett", "At Records
## worksheet"), or "" when the data does not say.
## Looks at the first condition of the objective that is not yet met.
static func objective_place(director: ChapterDirector) -> String:
	if director == null:
		return ""
	var objective: Dictionary = director.get_current_objective()
	if objective.is_empty():
		return ""
	return _place_for(objective["complete_when"], director)


## What the current objective points at, for the map: {"character": id},
## {"node": interactable node name}, {"type": interactable type} (the EHR,
## the sign-out board) or {"zone": id}; {} when the data does not say.
## Follows the same first-unmet-condition rule as objective_place().
static func objective_target(director: ChapterDirector) -> Dictionary:
	if director == null:
		return {}
	var objective: Dictionary = director.get_current_objective()
	if objective.is_empty():
		return {}
	return _target_for(objective["complete_when"], director)


static func _target_for(condition: Dictionary, director: ChapterDirector) -> Dictionary:
	var kind: String = condition.keys()[0]
	var value: Variant = condition[kind]
	match kind:
		"all":
			for part: Dictionary in value:
				if not StoryLogic.evaluate(part, director.get_story_context()):
					return _target_for(part, director)
		"any":
			for part: Dictionary in value:
				var target: Dictionary = _target_for(part, director)
				if not target.is_empty():
					return target
		"flag":
			var found: Dictionary = _option_for_flag(director.get_chapter_id(), str(value))
			if not found.is_empty():
				var interactable_id: String = found["interaction"]["interactable_id"]
				if interactable_id.begins_with("character:"):
					return {"character": interactable_id.trim_prefix("character:")}
				return {"node": interactable_id}
		"talked_to":
			return {"character": str(value)}
		"zone":
			return {"zone": str(value)}
		"observations_recorded":
			return {"character": str(value.get("patient_id", ""))}
		"note_saved", "action_committed":
			return {"type": "ehr_terminal"}
		"shift":
			return {"type": "shift_signout"}
	return {}


## Clue and hypothesis lines for the Evidence section.
static func evidence_summary() -> Dictionary:
	var hypotheses: Array[Dictionary] = []
	for hypothesis_id: String in ContentRegistry.get_hypothesis_ids():
		var state: Dictionary = EvidenceManager.get_hypothesis(hypothesis_id)
		var authored: Dictionary = ContentRegistry.get_hypothesis(hypothesis_id)
		var alternates: Array[String] = []
		for alternate: Variant in authored.get("alternate_explanations", []):
			alternates.append(str(alternate).replace("_", " "))
		hypotheses.append({"id": hypothesis_id, "title": state.get("title", ""), "status": state.get("status", ""),
				"alternates": alternates})
	return {"collected": EvidenceManager.get_acquired_ids().size(), "total": ContentRegistry.get_clue_ids().size(),
			"pinned": EvidenceManager.get_acquired_ids().filter(EvidenceManager.is_pinned).size(),
			"hypotheses": hypotheses}


## A short notice when a choice adds a note to the case file ("" when it adds none).
static func notice_for(chapter_id: String, option_flag: String) -> String:
	var entry: Dictionary = entry_for_flag(chapter_id, option_flag)
	if entry.is_empty():
		return ""
	return "Case file: noted as still open" if entry["status"] == "open" else "Case file updated"


## Connected in Main: announces a case-file note when a story choice adds one.
static func on_choice_committed(chapter_id: String, interaction_id: String, option_id: String) -> void:
	for interaction: Dictionary in ContentRegistry.get_story(chapter_id).get("interactions", []):
		if interaction["id"] != interaction_id:
			continue
		for option: Dictionary in interaction["options"]:
			if option["id"] == option_id:
				var notice: String = notice_for(chapter_id, str(option.get("flag", "")))
				if not notice.is_empty():
					EventBus.notification_requested.emit(notice)
				return


# --- Internals ---------------------------------------------------------------------

static func _option_for_flag(chapter_id: String, flag: String) -> Dictionary:
	for interaction: Dictionary in ContentRegistry.get_story(chapter_id).get("interactions", []):
		for option: Dictionary in interaction["options"]:
			if option.get("flag", "") == flag:
				return {"interaction": interaction, "option": option}
	return {}


static func _place_for(condition: Dictionary, director: ChapterDirector) -> String:
	var kind: String = condition.keys()[0]
	var value: Variant = condition[kind]
	match kind:
		"all":
			for part: Dictionary in value:
				if not StoryLogic.evaluate(part, director.get_story_context()):
					return _place_for(part, director)
			return ""
		"any":
			for part: Dictionary in value:
				var place: String = _place_for(part, director)
				if not place.is_empty():
					return place
			return ""
		"not":
			return ""
		"flag":
			return _place_for_flag(director.get_chapter_id(), str(value))
		"talked_to":
			return _with(str(ContentRegistry.get_staff(str(value)).get("name", "")))
		"zone":
			return _at(str(ContentRegistry.get_zone(str(value)).get("title", "")))
		"observations_recorded":
			return _with(str(ContentRegistry.get_patient(str(value.get("patient_id", ""))).get("name", "")))
		"note_saved", "action_committed":
			return _at("an EHR workstation")
		"hypothesis_supported":
			return _at("the evidence board")
		"shift":
			return _at(_world_title(director.get_chapter_id(), "shift_signout"))
	return ""


static func _place_for_flag(chapter_id: String, flag: String) -> String:
	var found: Dictionary = _option_for_flag(chapter_id, flag)
	if found.is_empty():
		return ""
	var interactable_id: String = found["interaction"]["interactable_id"]
	if interactable_id.begins_with("character:"):
		var name: String = str(ContentRegistry.get_staff(interactable_id.trim_prefix("character:")).get("name", ""))
		if not name.is_empty():
			return _with(name)
	for entry: Dictionary in ContentRegistry.get_world(chapter_id).get("interactables", []):
		if entry["node"] == interactable_id and entry.has("title"):
			return _at(str(entry["title"]))
	return _at(str(found["interaction"]["title"]))


static func _with(name: String) -> String:
	return "" if name.is_empty() else "With " + name


static func _at(place: String) -> String:
	return "" if place.is_empty() else "At " + place


static func _world_title(chapter_id: String, type: String) -> String:
	for entry: Dictionary in ContentRegistry.get_world(chapter_id).get("interactables", []):
		if entry["type"] == type and entry.has("title"):
			return str(entry["title"])
	return ""
