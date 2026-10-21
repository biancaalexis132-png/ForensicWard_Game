extends Node3D
## Standalone asset review scene; does not instantiate Main or save a campaign.
var _models: Node3D
var _player: FirstPersonController

func _ready() -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	environment.environment.sky = sky
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.environment.ambient_light_energy = 0.6
	add_child(environment)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	_player = load("res://scenes/player/FirstPersonController.tscn").instantiate()
	add_child(_player)
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var label: Label = Label.new()
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.text = "Environment visual review · 1 Campus · 2 Apartment · 3 Hospital exterior\nWASD / mouse · Esc exit · No campaign state is saved"
	layer.add_child(label)
	_show(1)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _show(index: int) -> void:
	if is_instance_valid(_models):
		_models.free()
	_models = Node3D.new()
	add_child(_models)
	var assets: Array[String] = []
	assets.assign(["CampusGrounds", "HospitalExterior"] if index == 1 else (["Apartment"] if index == 2 else ["HospitalExterior"]))
	for asset: String in assets:
		var model: Node3D = load("res://assets/exports/exterior/ENV_%s.glb" % asset).instantiate()
		_models.add_child(model)
	EnvironmentFinish.apply(_models)
	if index == 2:
		var lamp: OmniLight3D = OmniLight3D.new()
		lamp.position = Vector3(0, 2.8, 0)
		lamp.omni_range = 8.0
		lamp.light_energy = 1.2
		lamp.light_color = Color("fff2de")
		lamp.shadow_enabled = true
		_models.add_child(lamp)
	_player.place(Vector3(0, 0.1, 26) if index != 2 else Vector3(0, 0.1, 2), 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().quit()
	elif event is InputEventKey and event.pressed:
		if event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
			_show(event.physical_keycode - KEY_1 + 1)
