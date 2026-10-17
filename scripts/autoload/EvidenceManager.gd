extends Node
## EvidenceManager: clues, provenance, manual links and hypotheses (Autoload "EvidenceManager").
##
## Clue definitions are authored content; this manager tracks what the
## player has done with them:
##   acquired:      clue_id -> {method, at_minutes}  (how and when it was obtained)
##   pinned:        clues on the evidence board
##   links:         undirected player-made connections ("a|b", sorted)
##   hypotheses:    authored + player-registered, each unresolved/supported/refuted
##   verifications: clue_id -> [{method, at_minutes}] independent corroboration
##
## Design rules (GDD §10): links are manual; a hypothesis may be wrong
## without breaking anything; a contradiction opens a question, not a verdict.

var _acquired: Dictionary = {}
var _pinned: Array[String] = []
var _links: Array[String] = []
var _hypotheses: Dictionary = {}
var _verifications: Dictionary = {}


func _ready() -> void:
	SaveManager.register_provider("evidence", self)
	reset_state()


# --- Clues -----------------------------------------------------------------------------

## Returns true if newly acquired. `method` records provenance, e.g. "terminal:office_ehr".
func acquire_clue(clue_id: String, method: String) -> bool:
	if ContentRegistry.get_clue(clue_id).is_empty():
		push_error("EvidenceManager: unknown clue '%s'" % clue_id)
		return false
	if _acquired.has(clue_id):
		return false
	_acquired[clue_id] = {"method": method, "at_minutes": TimeManager.total_minutes}
	EventBus.clue_acquired.emit(clue_id)
	return true


func has_clue(clue_id: String) -> bool:
	return _acquired.has(clue_id)


func get_acquired_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_acquired.keys())
	ids.sort()
	return ids


func get_acquisition(clue_id: String) -> Dictionary:
	return _acquired.get(clue_id, {}).duplicate()


func set_pinned(clue_id: String, pinned: bool) -> bool:
	if not has_clue(clue_id):
		return false
	if pinned and not clue_id in _pinned:
		_pinned.append(clue_id)
		_pinned.sort()
	elif not pinned and clue_id in _pinned:
		_pinned.erase(clue_id)
		# Unpinning removes the clue's board links.
		for key: String in _links.duplicate():
			if clue_id in key.split("|"):
				_remove_link(key)
	else:
		return false
	EventBus.clue_pinned.emit(clue_id, pinned)
	return true


func is_pinned(clue_id: String) -> bool:
	return clue_id in _pinned


# --- Links ------------------------------------------------------------------------------

## Links two pinned clues. Returns false if invalid or already linked.
func link_clues(clue_a: String, clue_b: String) -> bool:
	if clue_a == clue_b or not is_pinned(clue_a) or not is_pinned(clue_b):
		return false
	var key: String = _link_key(clue_a, clue_b)
	if key in _links:
		return false
	_links.append(key)
	_links.sort()
	EventBus.clues_linked.emit(clue_a, clue_b, true)
	return true


func unlink_clues(clue_a: String, clue_b: String) -> bool:
	var key: String = _link_key(clue_a, clue_b)
	if not key in _links:
		return false
	_remove_link(key)
	return true


func are_linked(clue_a: String, clue_b: String) -> bool:
	return _link_key(clue_a, clue_b) in _links


func get_links() -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	for key: String in _links:
		result.append(key.split("|"))
	return result


# --- Hypotheses ------------------------------------------------------------------------------

## Registers a player hypothesis. Any clue set is allowed, including a wrong
## one: a false hypothesis never invalidates the chart or blocks progress.
func register_hypothesis(hypothesis_id: String, title: String, clue_ids: Array[String]) -> bool:
	if _hypotheses.has(hypothesis_id) or hypothesis_id.is_empty():
		return false
	_hypotheses[hypothesis_id] = {"title": title, "clue_ids": clue_ids.duplicate(), "status": "unresolved", "origin": "player"}
	EventBus.hypothesis_updated.emit(hypothesis_id, "unresolved")
	return true


func set_hypothesis_status(hypothesis_id: String, status: String) -> bool:
	if not _hypotheses.has(hypothesis_id) or not status in ContentSchemas.HYPOTHESIS_STATUSES:
		return false
	_hypotheses[hypothesis_id]["status"] = status
	EventBus.hypothesis_updated.emit(hypothesis_id, status)
	return true


func get_hypothesis(hypothesis_id: String) -> Dictionary:
	return _hypotheses.get(hypothesis_id, {}).duplicate(true)


## True when every required clue is acquired and they are all linked into one
## connected group on the board. This says only that the hypothesis can be
## *argued*; it never confirms it.
func is_hypothesis_supported_by_board(hypothesis_id: String) -> bool:
	var required: Array = _hypotheses.get(hypothesis_id, {}).get("clue_ids", [])
	if required.is_empty():
		return false
	for clue_id: String in required:
		if not is_pinned(clue_id):
			return false
	var reached: Dictionary = {required[0]: true}
	var frontier: Array = [required[0]]
	while not frontier.is_empty():
		var current: String = frontier.pop_back()
		for pair: PackedStringArray in get_links():
			var other: String = pair[1] if pair[0] == current else (pair[0] if pair[1] == current else "")
			if not other.is_empty() and not reached.has(other):
				reached[other] = true
				frontier.append(other)
	for clue_id: String in required:
		if not reached.has(clue_id):
			return false
	return true


## Independent corroborations of a clue: [{method, at_minutes}].
func get_verifications(clue_id: String) -> Array:
	return _verifications.get(clue_id, []).duplicate(true)


## Records an independent corroboration once per method. Returns true if new.
func add_verification(clue_id: String, method: String) -> bool:
	if not has_clue(clue_id):
		return false
	if get_verifications(clue_id).any(func(v: Dictionary) -> bool: return v["method"] == method):
		return false
	if not _verifications.has(clue_id):
		_verifications[clue_id] = []
	_verifications[clue_id].append({"method": method, "at_minutes": TimeManager.total_minutes})
	return true


# --- Internals ------------------------------------------------------------------------------

func _link_key(clue_a: String, clue_b: String) -> String:
	return "%s|%s" % [clue_a, clue_b] if clue_a < clue_b else "%s|%s" % [clue_b, clue_a]


func _remove_link(key: String) -> void:
	_links.erase(key)
	var pair: PackedStringArray = key.split("|")
	EventBus.clues_linked.emit(pair[0], pair[1], false)


# --- Save provider ------------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {
		"acquired": _acquired.duplicate(true),
		"pinned": _pinned.duplicate(),
		"links": _links.duplicate(),
		"hypotheses": _hypotheses.duplicate(true),
		"verifications": _verifications.duplicate(true),
	}


func load_save_data(data: Dictionary) -> void:
	reset_state()
	for clue_id: String in data.get("acquired", {}):
		if not ContentRegistry.get_clue(clue_id).is_empty():
			_acquired[clue_id] = data["acquired"][clue_id]
	for clue_id: Variant in data.get("pinned", []):
		if _acquired.has(clue_id):
			_pinned.append(clue_id)
	for key: Variant in data.get("links", []):
		var pair: PackedStringArray = str(key).split("|")
		if pair.size() == 2 and pair[0] in _pinned and pair[1] in _pinned:
			_links.append(str(key))
	for hypothesis_id: String in data.get("hypotheses", {}):
		_hypotheses[hypothesis_id] = data["hypotheses"][hypothesis_id]
	_verifications = data.get("verifications", {}).duplicate(true)
	_pinned.sort()
	_links.sort()


func reset_state() -> void:
	_acquired.clear()
	_pinned.clear()
	_links.clear()
	_verifications.clear()
	_hypotheses.clear()
	if not ContentRegistry.is_valid:
		return
	for hypothesis_id: String in ContentRegistry.get_hypothesis_ids():
		var authored: Dictionary = ContentRegistry.get_hypothesis(hypothesis_id)
		_hypotheses[hypothesis_id] = {
			"title": authored["title"],
			"clue_ids": Array(authored["required_clues"]).duplicate(),
			"status": authored["status"],
			"origin": "authored",
		}
