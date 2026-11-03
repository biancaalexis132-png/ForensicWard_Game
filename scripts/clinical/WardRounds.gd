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
var _state: Dictionary = {}          ## id -> {labs, plan, status, attempts}


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
		_cases[case["id"]] = case
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
	if not case_id in admitted_case_ids() or status(case_id) == STATUS_ACCEPTED or not _labels.has(lab_id):
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
	if not case_id in admitted_case_ids() or status(case_id) == STATUS_ACCEPTED:
		return {}
	var entry: Dictionary = _entry(case_id)
	var clean: Array = []
	for key: Variant in plan:
		if key is String and not key in clean:
			clean.append(key)
	entry["plan"] = clean
	entry["attempts"] = int(entry["attempts"]) + 1
	var review: Dictionary = WardRoundCatalog.evaluate(_cases[case_id], entry["labs"], clean, _labels)
	if review["outcome"] == WardRoundCatalog.ACCEPTED:
		entry["status"] = STATUS_ACCEPTED
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
				"plan": entry["plan"].duplicate(), "status": entry["status"], "attempts": int(entry["attempts"])}


func reset_state() -> void:
	_state.clear()


# --- Internal -------------------------------------------------------------------

func _entry(case_id: String) -> Dictionary:
	if not _state.has(case_id):
		_state[case_id] = {"labs": [], "plan": [], "status": STATUS_OPEN, "attempts": 0}
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
