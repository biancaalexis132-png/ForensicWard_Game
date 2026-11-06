class_name ProtagonistPreview
extends SubViewportContainer
## Live 3D preview for the character creator: the real psychiatrist model, dressed
## by ProtagonistAppearance, in its own small world with a neutral studio light.
## Drag to turn the character; `framing` switches between full body and face.

const IDLE_ANIMATION: StringName = &"idle_breathing"
const TURN_PER_PIXEL: float = 0.012
## Camera height and distance in metres, as a share of the model's eye height.
const FRAMINGS: Dictionary = {
	"body": [0.54, 3.35, 0.0],
	"face": [0.985, 0.62, 0.0],
}

var framing: String = "body":
	set(value):
		framing = value if FRAMINGS.has(value) else "body"
		_place_camera()

var _viewport: SubViewport
var _camera: Camera3D
var _turntable: Node3D
var _model: Node3D
var _model_gender: String = ""
var _eye_height: float = 1.6
var _dragging: bool = false


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	var environment: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.11, 0.13, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.66)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	_viewport.add_child(environment)
	var key: DirectionalLight3D = DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-28.0), deg_to_rad(28.0), 0.0)
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.96, 0.9)
	_viewport.add_child(key)
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-12.0), deg_to_rad(-140.0), 0.0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.8, 0.88, 1.0)
	_viewport.add_child(fill)
	var floor_disc: MeshInstance3D = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 0.55
	disc.bottom_radius = 0.55
	disc.height = 0.02
	floor_disc.mesh = disc
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.2, 0.23, 0.24)
	floor_disc.material_override = floor_material
	floor_disc.position.y = -0.01
	_viewport.add_child(floor_disc)
	_turntable = Node3D.new()
	_turntable.name = "Turntable"
	_viewport.add_child(_turntable)
	_camera = Camera3D.new()
	_camera.fov = 32.0
	_viewport.add_child(_camera)
	_camera.current = true
	_place_camera()


## Shows `profile`; swaps the model only when the female/male choice changed.
func show_profile(profile: Dictionary, options: Dictionary) -> void:
	var gender: String = str(profile.get("gender", ProtagonistProfile.DEFAULT_GENDER))
	if _model == null or gender != _model_gender:
		_load_model(gender)
	if _model != null:
		ProtagonistAppearance.apply(_model, profile, options)


func get_model() -> Node3D:
	return _model


func turn(radians: float) -> void:
	_turntable.rotation.y = wrapf(_turntable.rotation.y + radians, -PI, PI)


func _load_model(gender: String) -> void:
	if _model != null:
		# Queued while still a child, so it never outlives this viewport's world.
		_model.visible = false
		_model.name = "Discarded"
		_model.queue_free()
		_model = null
	var path: String = str(ProtagonistAppearance.MODEL_SCENES.get(gender, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	_model = (load(path) as PackedScene).instantiate() as Node3D
	_model_gender = gender
	# The models face +Z as built, toward this camera (the game yaws them to Godot's -Z).
	_turntable.add_child(_model)
	var skeleton: Skeleton3D = ProtagonistAppearance._skeleton(_model)
	if skeleton != null:
		_eye_height = maxf(ProtagonistAppearance._eye_centre(skeleton).y, 1.0)
	for node: Node in _model.find_children("*", "AnimationPlayer", true, false):
		var player: AnimationPlayer = node as AnimationPlayer
		if player.has_animation(IDLE_ANIMATION):
			player.get_animation(IDLE_ANIMATION).loop_mode = Animation.LOOP_LINEAR
			player.play(IDLE_ANIMATION)
		break
	_place_camera()


func _place_camera() -> void:
	if _camera == null:
		return
	var shot: Array = FRAMINGS[framing]
	var target: Vector3 = Vector3(0.0, _eye_height * float(shot[0]), 0.0)
	var eye: Vector3 = target + Vector3(0.0, 0.03 if framing == "face" else 0.12, float(shot[1]))
	_camera.transform = Transform3D(Basis.looking_at(target - eye, Vector3.UP), eye)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		turn(event.relative.x * TURN_PER_PIXEL)
		accept_event()
