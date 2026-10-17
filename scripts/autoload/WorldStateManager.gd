extends Node
## WorldStateManager: named environment states (Autoload "WorldStateManager").
##
## Environment assets ship every variant of a toggleable element as sibling
## nodes tagged with glTF extras {state_group, state, default_visible}: an
## observation shutter (open/closed), the W0-B seal (sealed), and later the
## Ward Zero anomaly variants. This manager stores only the *chosen* state per
## group; scenes show the matching nodes and hide the rest. Nothing is ever
## deleted or modified, so every change is reversible and saved/loaded with
## the run (GDD §11, handoff "Ward Zero" requirements).

## A group with no explicit state uses each node's authored default_visible.
const DEFAULT: String = ""

var _states: Dictionary[String, String] = {}


func _ready() -> void:
	SaveManager.register_provider("world_states", self)


func set_state(group: String, state: String) -> void:
	if _states.get(group, DEFAULT) == state:
		return
	_states[group] = state
	EventBus.environment_state_changed.emit(group, state)


## Clears an explicit choice so authored defaults apply again.
func reset_group(group: String) -> void:
	if _states.erase(group):
		EventBus.environment_state_changed.emit(group, DEFAULT)


func get_state(group: String) -> String:
	return _states.get(group, DEFAULT)


## Whether a node tagged (group, state, default_visible) should be shown.
## If the chosen state has no node of its own (e.g. "removed" for the W0-B
## seal), every node in the group is hidden.
func is_node_visible(group: String, state: String, default_visible: bool) -> bool:
	var chosen: String = get_state(group)
	if chosen == DEFAULT:
		return default_visible
	return chosen == state


func to_save_data() -> Dictionary:
	return {"states": _states.duplicate()}


func load_save_data(data: Dictionary) -> void:
	var previous: Dictionary = _states.duplicate()
	_states.clear()
	var saved: Dictionary = data.get("states", {})
	for group: String in saved:
		_states[group] = str(saved[group])
	for group: String in _union_keys(previous, _states):
		EventBus.environment_state_changed.emit(group, get_state(group))


func reset_state() -> void:
	var previous: Array = _states.keys()
	_states.clear()
	for group: String in previous:
		EventBus.environment_state_changed.emit(group, DEFAULT)


func _union_keys(a: Dictionary, b: Dictionary) -> Array:
	var keys: Array = a.keys()
	for key: Variant in b:
		if not key in keys:
			keys.append(key)
	return keys
