extends Node
## TrustManager: staff relationship vectors and access grants (Autoload "TrustManager").
##
## Each staff member has three independent, bounded axes. There is no
## binary good/evil flag (GDD §5):
##   respect   (professional regard)       -100..100
##   trust     (willingness to share)      -100..100
##   suspicion (wariness of the player)    -100..100
## Access grants (badges, permissions) are recorded with who granted them.
## Trust may gate optional investigation routes, but never mandatory
## patient-care routes (GDD §10).

const AXES: Array[String] = ["respect", "trust", "suspicion"]
const MIN_VALUE: float = -100.0
const MAX_VALUE: float = 100.0

var _vectors: Dictionary = {} ## staff_id -> {respect, trust, suspicion}
var _access: Dictionary = {}  ## access_id -> {source_id, at_minutes}


func _ready() -> void:
	SaveManager.register_provider("trust", self)
	reset_state()


func get_value(staff_id: String, axis: String) -> float:
	return _vectors.get(staff_id, {}).get(axis, 0.0)


func get_vector(staff_id: String) -> Dictionary:
	return _vectors.get(staff_id, {}).duplicate()


## Adjusts one axis, clamped to bounds. `reason` is for logs/debugging.
func adjust(staff_id: String, axis: String, delta: float, reason: String) -> void:
	if not _vectors.has(staff_id) or not axis in AXES:
		push_error("TrustManager: invalid adjust %s.%s (%s)" % [staff_id, axis, reason])
		return
	var value: float = clampf(_vectors[staff_id][axis] + delta, MIN_VALUE, MAX_VALUE)
	if is_equal_approx(value, _vectors[staff_id][axis]):
		return
	_vectors[staff_id][axis] = value
	EventBus.trust_changed.emit(staff_id, axis, value)


func grant_access(access_id: String, source_id: String) -> bool:
	if _access.has(access_id):
		return false
	_access[access_id] = {"source_id": source_id, "at_minutes": TimeManager.total_minutes}
	EventBus.access_granted.emit(access_id, source_id)
	return true


func has_access(access_id: String) -> bool:
	return access_id.is_empty() or _access.has(access_id)


func to_save_data() -> Dictionary:
	return {"vectors": _vectors.duplicate(true), "access": _access.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	reset_state()
	var vectors: Dictionary = data.get("vectors", {})
	for staff_id: String in vectors:
		if _vectors.has(staff_id):
			for axis: String in AXES:
				_vectors[staff_id][axis] = clampf(float(vectors[staff_id].get(axis, 0.0)), MIN_VALUE, MAX_VALUE)
	_access = data.get("access", {}).duplicate(true)


func reset_state() -> void:
	_vectors.clear()
	_access.clear()
	if not ContentRegistry.is_valid:
		return
	for staff_id: String in ContentRegistry.get_staff_ids():
		var initial: Dictionary = ContentRegistry.get_staff(staff_id)["initial_trust"]
		_vectors[staff_id] = {}
		for axis: String in AXES:
			_vectors[staff_id][axis] = clampf(float(initial[axis]), MIN_VALUE, MAX_VALUE)
