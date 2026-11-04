extends Node
## WardRounds (autoload): the patients each chapter admits for the player to
## work up in the EHR (data/ward_rounds.json, rules in WardRoundCatalog).
##
## A case is on the ward once its chapter has started (it stays on after).
## The player orders labs (the result is shown at once) and submits a plan.
## The attending's reply is "accepted" or "revise" with a reason per item;
## a revised plan can be resubmitted as often as needed. A chapter cannot be
## closed (night sign-out, or a story choice that completes it) until every
## case it admitted has an accepted plan: ChapterDirector asks can_close_chapter().
##
## Clinical governance: the cases are draft teaching content. While a case is
## PENDING_PSYCHIATRIST_REVIEW it plays only in the prototype build, with a
## draft badge, and every submission raises clinical_review_flagged. In the
## validated build pending cases are hidden and never gate a chapter.
##
## Saved under "ward_rounds": {"cases": {id: {labs, plan, status, attempts}}}.

const DATA_PATH: String = "res://data/ward_rounds.json"
const PROVIDER_KEY: String = "ward_rounds"
const STATUS_OPEN: String = "open"
const STATUS_ACCEPTED: String = "accepted"
const APPROVED: String = "APPROVED"

signal case_changed(case_id: String)

## Tests that drive chapters without ward rounds switch the chapter gate off
## (TestCase.before_each does). The game never changes it.
var enforce_gate: bool = true

var _data: Dictionary = {}
var _cases: Dictionary = {}          ## id -> case definition, in file order
var _order: Array[String] = []
var _labels: Dictionary = {}         ## lab / medication / intervention id -> label
var _state: Dictionary = {}          ## id -> {labs, plan, status, attempts, history, replaying, best}


func _ready() -> void:
	load_catalog(DATA_PATH)
	SaveManager.register_provider(PROVIDER_KEY, self)


## Loads and checks a catalog; on any error no case plays. Returns the errors.
func load_catalog(path: String) -> Array[String]:
	_data = {}
	_cases.clear()
	_order.clear()
	_labels.clear()
	_state.clear()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var errors: Array[String] = WardRoundCatalog.validate(parsed, ContentRegistry.get_chapter_ids())
	if not errors.is_empty():
		for error: String in errors:
			push_error("WardRounds: " + error)
		return errors
	_data = parsed
	for field: String in ["lab_catalog", "medication_catalog", "intervention_catalog"]:
		for entry: Dictionary in _data[field]:
			_labels[entry["id"]] = entry["label"]
	for case: Dictionary in _data["cases"]:
		_cases[case["id"]] = WardRoundCatalog.with_defaults(case, _data["intervention_catalog"])
		_order.append(case["id"])
	return errors


# --- Queries --------------------------------------------------------------------

func labels() -> Dictionary:
	return _labels


func lab_catalog() -> Array:
	return _data.get("lab_catalog", [])


func medication_catalog() -> Array:
	return _data.get("medication_catalog", [])


func intervention_catalog() -> Array:
	return _data.get("intervention_catalog", [])


func get_case(case_id: String) -> Dictionary:
	return _cases.get(case_id, {})


## True when the case may play in this build (approved, or a prototype build).
func is_playable(case_id: String) -> bool:
	if not _cases.has(case_id):
		return false
	if _cases[case_id]["clinical_review_status"] == APPROVED:
		return true
	return _cases[case_id]["clinical_review_status"] != "REJECTED" \
			and ClinicalRules.build_mode == ClinicalRules.MODE_PROTOTYPE


func is_draft(case_id: String) -> bool:
	return _cases.has(case_id) and _cases[case_id]["clinical_review_status"] != APPROVED


## Playable cases whose chapter has started, in file order.
func admitted_case_ids() -> Array[String]:
	var started: Array[String] = _started_chapters()
	var result: Array[String] = []
	for id: String in _order:
		if is_playable(id) and _cases[id]["chapter"] in started:
			result.append(id)
	return result


## Playable cases admitted with this chapter that still lack an accepted plan.
func open_case_ids(chapter_id: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in _order:
		if _cases[id]["chapter"] == chapter_id and is_playable(id) and status(id) != STATUS_ACCEPTED:
			result.append(id)
	return result


func can_close_chapter(chapter_id: String) -> bool:
	return not enforce_gate or open_case_ids(chapter_id).is_empty()


## The notice shown when a chapter cannot close yet.
func blocked_message(chapter_id: String) -> String:
	var names: Array[String] = []
	for id: String in open_case_ids(chapter_id):
		names.append(_cases[id]["patient"]["name"])
	return "Ward round first: %s still need%s an accepted plan (EHR, Ward round)." % [
			" and ".join(names), "s" if names.size() == 1 else ""]


func status(case_id: String) -> String:
	return str(_state.get(case_id, {}).get("status", STATUS_OPEN))


func ordered_labs(case_id: String) -> Array:
	return _state.get(case_id, {}).get("labs", []).duplicate()


func submitted_plan(case_id: String) -> Array:
	return _state.get(case_id, {}).get("plan", []).duplicate()


# --- Bedside conversation (data/ward_rounds.json "bedside"; optional) -----------

## The bedside block, or {} when the catalog has none (then the chart shows everything).
func bedside() -> Dictionary:
	return _data.get("bedside", {})


func bedside_opening(case_id: String) -> String:
	return str(_state.get(case_id, {}).get("opening", ""))


func bedside_asked(case_id: String) -> Array:
	return _state.get(case_id, {}).get("asked", []).duplicate()


## 0 to 2: set by the opening, raised to 1 by repairing after a poor opening.
func bedside_trust(case_id: String) -> int:
	var opening: Dictionary = _bedside_entry("openings", bedside_opening(case_id))
	var trust: int = int(opening.get("trust", 0))
	if bool(_state.get(case_id, {}).get("repaired", false)):
		trust = maxi(trust, 1)
	return trust


func bedside_repaired(case_id: String) -> bool:
	return bool(_state.get(case_id, {}).get("repaired", false))


## True when a chart field is known: there is no bedside block, or the
## question that reveals it was asked with enough trust.
func is_revealed(case_id: String, field: String) -> bool:
	if bedside().is_empty():
		return true
	for question: Dictionary in bedside()["questions"]:
		if question["field"] == field and question["id"] in _state.get(case_id, {}).get("revealed", []):
			return true
	return false


## Chooses how to open the conversation (once per run).
func open_bedside(case_id: String, opening_id: String) -> String:
	if bedside().is_empty() or not case_id in admitted_case_ids() or not is_editable(case_id):
		return ""
	var opening: Dictionary = _bedside_entry("openings", opening_id)
	if opening.is_empty() or not bedside_opening(case_id).is_empty():
		return ""
	_entry(case_id)["opening"] = opening_id
	case_changed.emit(case_id)
	return _bedside_text(opening["response"], case_id)


## Asks a question. Returns the patient's spoken answer (bedside_line), or the
## chart text when the case has no line ("" if not allowed). With too
## little trust, a question that needs it gets a short reply and reveals nothing.
func ask_bedside(case_id: String, question_id: String) -> String:
	if bedside_opening(case_id).is_empty() or not is_editable(case_id):
		return ""
	var question: Dictionary = _bedside_entry("questions", question_id)
	if question.is_empty():
		return ""
	var entry: Dictionary = _entry(case_id)
	if not question_id in entry["asked"]:
		entry["asked"].append(question_id)
	var text: String
	if bool(question["needs_trust"]) and bedside_trust(case_id) < 1:
		text = _bedside_text(bedside()["low_trust_response"], case_id)
	else:
		if not question_id in entry["revealed"]:
			entry["revealed"].append(question_id)
		text = bedside_line(case_id, question_id)
		if text.is_empty():
			text = str(get_case(case_id)["presentation"][question["field"]])
	case_changed.emit(case_id)
	return text


## The patient's own spoken answer to a question, as "Name: “line”", or "" when
## the case has none (the answer is then the chart text). A line in brackets
## describes what you see instead, so it is shown without quotation marks.
func bedside_line(case_id: String, question_id: String) -> String:
	return _spoken(case_id, str(get_case(case_id).get("bedside_lines", {}).get(question_id, "")))


## What the patient says when the accepted plan included explaining it to them,
## formatted like bedside_line; "" otherwise or when the case has no line.
func plan_response(case_id: String) -> String:
	if status(case_id) != STATUS_ACCEPTED or not WardRoundScoring.EXPLAIN_ITEM in submitted_plan(case_id):
		return ""
	return _spoken(case_id, str(get_case(case_id).get("plan_response", {}).get("line", "")))


## Lines for the day shift handover: each of the chapter's ward-round patients
## with their plan status and best debrief, and any earlier patients checked in
## on. Empty when the chapter has none. Uses no clinical wording.
func handover_lines(chapter_id: String) -> PackedStringArray:
	var lines: PackedStringArray = []
	for id: String in admitted_case_ids():
		var name: String = str(_cases[id]["patient"]["name"])
		if _cases[id]["chapter"] == chapter_id:
			if status(id) == STATUS_ACCEPTED:
				var best: int = best_score(id)
				var graded: String = " (debrief %d, %s)" % [best, WardRoundScoring.grade_for(best)] if best >= 0 else ""
				lines.append("%s: plan accepted%s." % [name, graded])
			else:
				lines.append("%s: no accepted plan yet." % name)
		elif not followed_up_line(id).is_empty():
			lines.append("%s: you checked in on them." % name)
	if not lines.is_empty():
		lines.insert(0, "[b]Ward round[/b]")
	return lines


## True when the player can check in on a patient treated in an earlier
## chapter: their plan was accepted, a later chapter has begun, and the case has
## a follow-up line.
func can_follow_up(case_id: String) -> bool:
	if status(case_id) != STATUS_ACCEPTED or is_replaying(case_id):
		return false
	if str(get_case(case_id).get("follow_up", {}).get("line", "")).is_empty():
		return false
	var started: Array[String] = _started_chapters()
	return not started.is_empty() and started[started.size() - 1] != str(_cases[case_id]["chapter"])


## Checks in on an earlier patient. Returns what they say ("" if not allowed).
func follow_up(case_id: String) -> String:
	if not can_follow_up(case_id):
		return ""
	_entry(case_id)["followed_up"] = true
	case_changed.emit(case_id)
	return followed_up_line(case_id)


## The follow-up line once the player has checked in, else "".
func followed_up_line(case_id: String) -> String:
	if not bool(_state.get(case_id, {}).get("followed_up", false)):
		return ""
	return _spoken(case_id, str(get_case(case_id).get("follow_up", {}).get("line", "")))


func _spoken(case_id: String, line: String) -> String:
	if line.is_empty():
		return ""
	if line.begins_with("("):
		return line
	var name: String = str(get_case(case_id).get("patient", {}).get("name", "The patient"))
	return "%s: “%s”" % [name.get_slice(" ", 0), line]


## Slows down after a poor opening; trust rises to 1.
func repair_bedside(case_id: String) -> String:
	if bedside_opening(case_id).is_empty() or bedside_trust(case_id) >= 1 or not is_editable(case_id):
		return ""
	_entry(case_id)["repaired"] = true
	case_changed.emit(case_id)
	return _bedside_text(bedside()["repair"]["response"], case_id)


func _bedside_entry(field: String, id: String) -> Dictionary:
	for entry: Dictionary in bedside().get(field, []):
		if entry["id"] == id:
			return entry
	return {}


func _bedside_text(template: String, case_id: String) -> String:
	return template.replace("{name}", str(get_case(case_id).get("patient", {}).get("name", "The patient")))


## True while the player can still order tests and submit: an open case, or
## an accepted one being replayed.
func is_editable(case_id: String) -> bool:
	return status(case_id) != STATUS_ACCEPTED or bool(_state.get(case_id, {}).get("replaying", false))


func is_replaying(case_id: String) -> bool:
	return bool(_state.get(case_id, {}).get("replaying", false))


## The tests budget for this patient (WardRoundScoring; soft, never blocks).
func tests_budget(case_id: String) -> int:
	return WardRoundScoring.budget(_cases.get(case_id, {}))


## The debrief score for the accepted plan in this run ({} before acceptance,
## and while a replay is under way).
func score(case_id: String) -> Dictionary:
	if status(case_id) != STATUS_ACCEPTED or is_replaying(case_id):
		return {}
	return WardRoundScoring.score(_cases[case_id], _state[case_id].get("history", []),
			_data["intervention_catalog"], _labels, _bedside_record(case_id))


## What the debrief needs from the bedside conversation ({} without a bedside block).
func _bedside_record(case_id: String) -> Dictionary:
	if bedside().is_empty():
		return {}
	var entry: Dictionary = _state.get(case_id, {})
	return {"opening": _bedside_entry("openings", str(entry.get("opening", ""))),
			"repaired": bool(entry.get("repaired", false))}


## The best total across runs of an accepted case (-1 if none).
func best_score(case_id: String) -> int:
	return int(_state.get(case_id, {}).get("best", -1))


## Starts the case again for a better score. The chapter stays unlocked: the
## case keeps its accepted status, and the best total is kept.
func replay_case(case_id: String) -> bool:
	if status(case_id) != STATUS_ACCEPTED or is_replaying(case_id):
		return false
	var entry: Dictionary = _entry(case_id)
	entry["labs"] = []
	entry["plan"] = []
	entry["attempts"] = 0
	entry["history"] = []
	entry["opening"] = ""
	entry["asked"] = []
	entry["revealed"] = []
	entry["repaired"] = false
	entry["replaying"] = true
	case_changed.emit(case_id)
	return true


func attempts(case_id: String) -> int:
	return int(_state.get(case_id, {}).get("attempts", 0))


## The attending's view of the last submitted plan ({} before any submission).
func last_review(case_id: String) -> Dictionary:
	if attempts(case_id) == 0:
		return {}
	return WardRoundCatalog.evaluate(_cases[case_id], ordered_labs(case_id), submitted_plan(case_id), _labels)


func lab_result(case_id: String, lab_id: String) -> Dictionary:
	return WardRoundCatalog.lab_result(_cases.get(case_id, {}), lab_id)


# --- Commands -------------------------------------------------------------------

## Orders a lab; its result is available at once. False if not allowed.
func order_lab(case_id: String, lab_id: String) -> bool:
	if not case_id in admitted_case_ids() or not is_editable(case_id) or not _labels.has(lab_id):
		return false
	if not lab_id in lab_catalog().map(func(entry: Dictionary) -> String: return entry["id"]):
		return false
	var entry: Dictionary = _entry(case_id)
	if lab_id in entry["labs"]:
		return false
	entry["labs"].append(lab_id)
	case_changed.emit(case_id)
	return true


## Submits a plan and returns the attending's review ({} if not allowed).
func submit_plan(case_id: String, plan: Array) -> Dictionary:
	if not case_id in admitted_case_ids() or not is_editable(case_id):
		return {}
	var entry: Dictionary = _entry(case_id)
	var clean: Array = []
	for key: Variant in plan:
		if key is String and not key in clean:
			clean.append(key)
	entry["plan"] = clean
	entry["attempts"] = int(entry["attempts"]) + 1
	entry["history"].append({"labs": entry["labs"].duplicate(), "plan": clean.duplicate(),
			"revealed": entry["revealed"].duplicate()})
	var review: Dictionary = WardRoundCatalog.evaluate(_cases[case_id], entry["labs"], clean, _labels)
	if review["outcome"] == WardRoundCatalog.ACCEPTED:
		entry["status"] = STATUS_ACCEPTED
		entry["replaying"] = false
		var scored: Dictionary = WardRoundScoring.score(_cases[case_id], entry["history"], _data["intervention_catalog"],
				_labels, _bedside_record(case_id))
		entry["best"] = maxi(int(entry.get("best", -1)), int(scored.get("total", -1)))
	if is_draft(case_id):
		EventBus.clinical_review_flagged.emit("ward_round_draft",
				"Ward round case %s is draft teaching content pending psychiatrist review." % case_id)
	case_changed.emit(case_id)
	return review


# --- SaveManager provider -------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"cases": _state.duplicate(true)}


func validate_save_data(data: Variant) -> bool:
	if not data is Dictionary or not data.get("cases") is Dictionary:
		return false
	for id: Variant in data["cases"]:
		var entry: Variant = data["cases"][id]
		if not id is String or not entry is Dictionary:
			return false
		if not entry.get("labs") is Array or not entry.get("plan") is Array \
				or not entry.get("status") in [STATUS_OPEN, STATUS_ACCEPTED] \
				or not (entry.get("attempts") is int or entry.get("attempts") is float):
			return false
		# Saves from before scoring have no history; it defaults to empty.
		if entry.has("history") and not entry["history"] is Array:
			return false
		for submission: Variant in entry.get("history", []):
			if not submission is Dictionary or not submission.get("labs") is Array or not submission.get("plan") is Array:
				return false
		for field: String in ["asked", "revealed"]:
			if entry.has(field) and not entry[field] is Array:
				return false
		if entry.has("opening") and not entry["opening"] is String:
			return false
		if entry.has("followed_up") and not entry["followed_up"] is bool:
			return false
	return true


func load_save_data(data: Dictionary) -> void:
	_state.clear()
	if not validate_save_data(data):
		return
	for id: String in data["cases"]:
		if not _cases.has(id):
			continue  # A case removed from the catalog since the save.
		var entry: Dictionary = data["cases"][id]
		_state[id] = {"labs": entry["labs"].filter(func(lab: Variant) -> bool: return _labels.has(str(lab))),
				"plan": entry["plan"].duplicate(), "status": entry["status"], "attempts": int(entry["attempts"]),
				"history": entry.get("history", []).duplicate(true), "replaying": bool(entry.get("replaying", false)),
				"best": int(entry.get("best", -1)), "opening": str(entry.get("opening", "")),
				"asked": entry.get("asked", []).duplicate(), "revealed": entry.get("revealed", []).duplicate(),
				"repaired": bool(entry.get("repaired", false)),
				"followed_up": bool(entry.get("followed_up", false))}


func reset_state() -> void:
	_state.clear()


# --- Internal -------------------------------------------------------------------

func _entry(case_id: String) -> Dictionary:
	if not _state.has(case_id):
		_state[case_id] = {"labs": [], "plan": [], "status": STATUS_OPEN, "attempts": 0,
				"history": [], "replaying": false, "best": -1,
				"opening": "", "asked": [], "revealed": [], "repaired": false, "followed_up": false}
	return _state[case_id]


## The current chapter and every chapter before it in campaign order.
func _started_chapters() -> Array[String]:
	var result: Array[String] = []
	var director: ChapterDirector = get_tree().get_first_node_in_group(ChapterDirector.GROUP) as ChapterDirector
	if director == null:
		return result
	var current: String = director.get_chapter_id()
	for id: String in ContentRegistry.get_chapter_ids():
		result.append(id)
		if id == current:
			return result
	return [current] as Array[String]
