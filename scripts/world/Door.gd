class_name Door
extends Node3D
## Door: a hinged door that swings open and closed, optionally locked behind
## an access grant (TrustManager). Open/closed state is saved.
##
## Scene layout (scenes/props/Door.tscn):
##   Door (this) > Hinge > Panel (AnimatableBody3D) > Mesh, Collision, Interactable
## The panel has sync_to_physics = false: with it on, an AnimatableBody3D only
## follows its *own* transform and ignores the rotating Hinge parent.

@export var door_id: String = ""
@export var display_name: String = "Door"
## Access id required to open, e.g. "access_records_archive". Empty = unlocked.
@export var required_access: String = ""
@export var locked_message: String = "Locked."
@export var open_angle_degrees: float = 100.0
@export var swing_seconds: float = 0.6
@export var starts_open: bool = false

var is_open: bool = false

var _tween: Tween = null

@onready var _hinge: Node3D = $Hinge
@onready var _interactable: Interactable = $Hinge/Panel/Interactable


func _ready() -> void:
	add_to_group("persistent_world")
	_interactable.interactable_id = door_id
	_interactable.prompt_provider = _get_prompt
	_interactable.interacted.connect(_on_interacted)
	_set_open(starts_open, false)


func get_persist_id() -> String:
	return "door:" + door_id


func to_save_data() -> Dictionary:
	return {"open": is_open}


func load_save_data(data: Dictionary) -> void:
	_set_open(bool(data.get("open", starts_open)), false)


func is_locked() -> bool:
	return not TrustManager.has_access(required_access)


func _get_prompt() -> String:
	if is_locked():
		return "%s (locked)" % display_name
	return ("Close " if is_open else "Open ") + display_name.to_lower()


func _on_interacted(_interactor: Node) -> void:
	if is_locked():
		EventBus.notification_requested.emit(locked_message)
		return
	_set_open(not is_open, true)


func _set_open(open: bool, animate: bool) -> void:
	is_open = open
	var target: float = deg_to_rad(open_angle_degrees if open else 0.0)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# Respect "reduce motion": snap instead of swinging.
	if animate and not Settings.get_value("reduce_motion"):
		_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_hinge, "rotation:y", target, swing_seconds)
	else:
		_hinge.rotation.y = target
