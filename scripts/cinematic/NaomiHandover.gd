extends Node3D
## First cinematic blocking pass. Reuses the shipped actor, acting rig and voices.
## Review scene only: does not advance story, create a patient or write saves.
const SHOT_PATH: String = "res://data/cinematics/naomi_handover.json"
var _camera: Camera3D
var _caption: Label
var _actor: WardCharacter
var _motion: Tween
var _finished: bool = false
var _did_finish: bool = false
var _shots: Array = []
var _exit_when_done: bool = false

func _ready() -> void:
	_exit_when_done = "--exit-when-done" in OS.get_cmdline_user_args()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHOT_PATH))
	if not data is Dictionary or not data.get("shots") is Array:
		_fail("Invalid cinematic shot data")
		return
	_shots = data["shots"]
	for shot: Dictionary in _shots:
		if not AudioDirector.has_line(str(shot.get("line", ""))):
			_fail("Missing authored dialogue: " + str(shot.get("line")))
			return
	_build_stage()
	if not _actor.visual_error.is_empty():
		_fail(_actor.visual_error)
		return
	EventBus.subtitle_shown.connect(_on_subtitle)
	await get_tree().process_frame
	AudioDirector.begin_conversation()
	for shot: Dictionary in _shots:
		if _finished:
			break
		_frame_shot(shot)
		if not await AudioDirector.play_line(str(shot["line"])):
			break
	AudioDirector.end_conversation()
	_finish()

func _build_stage() -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.08, 0.11, 0.12)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.68, 0.76, 0.8)
	environment.environment.ambient_light_energy = 0.3
	add_child(environment)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.light_energy = 0.65
	add_child(light)
	var key: SpotLight3D = SpotLight3D.new()
	key.position = Vector3(1.4, 2.4, 1.8)
	key.light_color = Color(1.0, 0.92, 0.84)
	key.light_energy = 1.8
	key.spot_range = 6.0
	key.spot_angle = 48.0
	key.shadow_enabled = true
	add_child(key)
	key.look_at(Vector3(0.0, 1.35, 0.0))
	var fill: OmniLight3D = OmniLight3D.new()
	fill.position = Vector3(-1.0, 1.8, 1.2)
	fill.light_color = Color(0.75, 0.85, 1.0)
	fill.light_energy = 0.45
	fill.omni_range = 4.0
	add_child(fill)
	var station: PackedScene = load("res://assets/exports/clinical/env/ENV_NursingStation.glb") as PackedScene
	if station != null:
		var room: Node3D = station.instantiate() as Node3D
		room.transform = Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3.ZERO) * Transform3D(Basis.IDENTITY, Vector3(2.30, 0.0, 10.45))
		add_child(room)
	_actor = preload("res://scenes/props/Character.tscn").instantiate() as WardCharacter
	_actor.character_id = "staff_bennett"
	CampaignCastVisuals.configure(_actor, "")
	# Imported cast faces +Z; the standalone camera is on that side.
	_actor.visual_placement = Transform3D.IDENTITY
	add_child(_actor)
	(_actor.get_node("NameLabel") as Label3D).hide()
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.make_current()
	var ui_scale: float = maxf(get_viewport().get_visible_rect().size.y / 1080.0, 0.5)
	var subtitle_height: float = maxf(100.0 * ui_scale, 80.0)
	var overlay: CanvasLayer = CanvasLayer.new()
	add_child(overlay)
	for bottom: bool in [false, true]:
		var bar: ColorRect = ColorRect.new()
		bar.color = Color.BLACK
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
		bar.offset_top = -subtitle_height if bottom else 0
		bar.offset_bottom = 0 if bottom else 65.0 * ui_scale
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
	_caption = Label.new()
	_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_top = -subtitle_height + 6.0
	_caption.offset_bottom = -8
	_caption.offset_left = 60.0 * ui_scale
	_caption.offset_right = -60.0 * ui_scale
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", maxi(14, roundi(22.0 * ui_scale)))
	overlay.add_child(_caption)
	var hint: Label = Label.new()
	hint.text = "CINEMATIC BLOCKING PREVIEW     Esc: finish"
	hint.position = Vector2(24, 18) * ui_scale
	hint.add_theme_font_size_override("font_size", maxi(12, roundi(16.0 * ui_scale)))
	overlay.add_child(hint)

func _frame_shot(shot: Dictionary) -> void:
	if _motion != null:
		_motion.kill()
	print("CINEMATIC_SHOT " + str(shot["line"]))
	var point: Array = shot["camera"]
	var target: Array = shot["target"]
	_camera.position = Vector3(float(point[0]), float(point[1]), float(point[2]))
	_camera.look_at(Vector3(float(target[0]), float(target[1]), float(target[2])))
	_camera.fov = float(shot["fov"])
	_motion = create_tween()
	_motion.tween_property(_camera, "fov", _camera.fov - 2.0, 6.0).set_trans(Tween.TRANS_SINE)

func _on_subtitle(_id: String, speaker: String, text: String, _duration: float) -> void:
	_caption.text = speaker + "\n" + text

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_finished = true
		AudioDirector.stop_dialogue()
		_finish()

func _finish() -> void:
	if _did_finish:
		return
	_did_finish = true
	_finished = true
	if _motion != null:
		_motion.kill()
	_caption.text = "End of cinematic preview"
	print("CINEMATIC_PREVIEW_DONE")
	if _exit_when_done:
		get_tree().quit()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)

func _exit_tree() -> void:
	AudioDirector.stop_dialogue()
