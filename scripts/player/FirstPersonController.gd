class_name FirstPersonController
extends CharacterBody3D
## FirstPersonController: WASD movement, mouse look, E to interact.
##
## Input actions (Project Settings > Input Map): move_forward, move_back,
## move_left, move_right, sprint, interact. Mouse look works only while the
## mouse is captured; Main owns capture and calls set_input_enabled() when
## UI opens or closes. Head bob respects Settings "reduce_motion".

@export_group("Movement")
@export var walk_speed: float = 2.8
@export var sprint_speed: float = 4.5
@export var acceleration: float = 12.0
@export var deceleration: float = 14.0

@export_group("Look")
@export var max_pitch_degrees: float = 85.0

@export_group("Head bob")
@export var bob_frequency: float = 1.8
@export var bob_amplitude: float = 0.035

var input_enabled: bool = true

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _bob_time: float = 0.0
var _focused: Interactable = null
var _head_base_y: float = 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _ray: RayCast3D = $Head/Camera3D/InteractionRay


func _ready() -> void:
	_head_base_y = _head.position.y
	_ray.add_exception(self)


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		_set_focus(null)


## Teleports the player (spawn points and save loading). `yaw` in radians.
func place(at: Vector3, yaw: float, pitch: float = 0.0) -> void:
	global_position = at
	rotation.y = yaw
	_head.rotation.x = pitch
	velocity = Vector3.ZERO


func get_look_pitch() -> float:
	return _head.rotation.x


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event
		var sensitivity: float = deg_to_rad(Settings.get_value("mouse_sensitivity"))
		var invert: float = -1.0 if Settings.get_value("invert_y") else 1.0
		rotate_y(-motion.relative.x * sensitivity)
		_head.rotation.x = clampf(_head.rotation.x - motion.relative.y * sensitivity * invert,
				-deg_to_rad(max_pitch_degrees), deg_to_rad(max_pitch_degrees))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _focused != null:
		_focused.interact(self)
		refresh_focus_prompt() # e.g. "Open door" becomes "Close door".
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input_vector: Vector2 = Vector2.ZERO
	if input_enabled:
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var speed: float = sprint_speed if input_enabled and Input.is_action_pressed("sprint") else walk_speed
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = acceleration if direction != Vector3.ZERO else deceleration
	horizontal = horizontal.move_toward(direction * speed, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

	_update_head_bob(delta, horizontal.length())
	_update_focus()


func _update_head_bob(delta: float, speed: float) -> void:
	if Settings.get_value("reduce_motion") or speed < 0.1 or not is_on_floor():
		_bob_time = 0.0
		_head.position.y = lerpf(_head.position.y, _head_base_y, minf(delta * 10.0, 1.0))
		return
	_bob_time += delta * bob_frequency * (speed / walk_speed) * TAU
	_head.position.y = _head_base_y + sin(_bob_time) * bob_amplitude


func _update_focus() -> void:
	var target: Interactable = null
	if input_enabled and _ray.is_colliding():
		var hit: Object = _ray.get_collider()
		if hit is Interactable and (hit as Interactable).enabled:
			target = hit
	_set_focus(target)


func _set_focus(target: Interactable) -> void:
	if target == _focused:
		return
	_focused = target
	EventBus.interaction_focus_changed.emit(target.get_prompt() if target != null else "")


## Re-announces the prompt (e.g. after a door opens and its prompt changes).
func refresh_focus_prompt() -> void:
	if _focused != null:
		EventBus.interaction_focus_changed.emit(_focused.get_prompt())
