extends SceneTree
## Review-only: records Naomi's preview model performing a scripted beat at the
## nursing station, one PNG per frame, for owner visual review. Nothing here touches
## story, save or clinical state, and it is never run by the game or the QA suite.
##
## Usage (from the project root, after importing; needs a window, not --headless):
##   godot --path . -s res://tools/godot/capture_character_performance.gd \
##       --resolution 1280x720 --fixed-fps 30 -- --out=/tmp/naomi_take --version=v04
##   ffmpeg -framerate 30 -i /tmp/naomi_take/f%05d.png -c:v libx264 -pix_fmt yuv420p take.mp4
##
## Every frame is drawn with RenderingServer.force_draw before it is saved. Godot's
## --write-movie repeats frames when macOS throttles a window that is not on screen
## (for example over Remote Control), which made gestures look frozen.

const FPS: float = 30.0
const EXPRESSIONS: PackedStringArray = [
	"attentive", "warm_subtle", "concerned_restrained", "professionally_serious", "focused", "calm_professional",
]
## [seconds, cue]. Body clips loop; gestures play once on GestureAnimationPlayer.
const BEAT: Array = [
	[0.0, "idle"], [2.5, "blink"], [3.2, "greet"], [5.0, "speak_warm"], [8.5, "stop"],
	[9.0, "listen_concerned"], [12.0, "ack"], [13.5, "speak_serious"], [16.5, "chart"], [19.5, "end"],
]

var _out: String = ""
var _version: String = "v04"
var _world: Node
var _model: Node3D
var _face: Node
var _body: AnimationPlayer
var _gesture: AnimationPlayer
var _meshes: Array[MeshInstance3D] = []
var _time: float = 0.0
var _step: int = 0
var _frame: int = 0
var _ticks: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--version="):
			_version = arg.trim_prefix("--version=")
	if _out.is_empty():
		push_error("capture_character_performance: pass -- --out=DIR")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	CharacterVisualPreview.set_requests({"staff_bennett": _version})
	_world = (load("res://scenes/world/HospitalGreybox.tscn") as PackedScene).instantiate()
	get_root().add_child(_world)


func _process(delta: float) -> bool:
	_ticks += 1
	if _ticks < 3:
		return false
	if _model == null and not _find_model():
		push_error("capture_character_performance: %s has no animated preview model" % _version)
		quit(1)
		return true
	_time += delta
	while _step < BEAT.size() and _time >= float(BEAT[_step][0]):
		_cue(str(BEAT[_step][1]))
		_step += 1
	if _step >= BEAT.size():
		print("capture_character_performance: wrote %d frames to %s" % [_frame, _out])
		return true
	RenderingServer.force_draw(false, 1.0 / FPS)
	get_root().get_texture().get_image().save_png(_out.path_join("f%05d.png" % _frame))
	_frame += 1
	return false


func _find_model() -> bool:
	var root: Node3D = _world.find_child("NurseBennett", true, false).get_node("VisualRoot")
	if root.get_child_count() == 0:
		return false
	_model = root.get_child(root.get_child_count() - 1)
	_face = _model.find_child("CharacterFaceRig", true, false)
	for player: AnimationPlayer in _model.find_children("*", "AnimationPlayer", true, false):
		if player.name == "GestureAnimationPlayer":
			_gesture = player
		else:
			_body = player
	for node: Node in _model.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).find_blend_shape_by_name(EXPRESSIONS[0]) >= 0:
			_meshes.append(node)
	if _body == null or _face == null:
		return false
	# Head-and-shoulders framing from the counter side, slightly off axis.
	var head: Vector3 = _model.global_position + Vector3(0.0, 1.52, 0.0)
	var camera: Camera3D = Camera3D.new()
	_world.add_child(camera)
	camera.global_position = head + _model.global_basis.z.normalized() * 1.25 \
			+ _model.global_basis.x.normalized() * 0.3 + Vector3(0.0, -0.02, 0.0)
	camera.look_at(head - Vector3(0.0, 0.18, 0.0))
	camera.fov = 38.0
	camera.current = true
	return true


func _expression(name: String, weight: float) -> void:
	for mesh: MeshInstance3D in _meshes:
		for shape: String in EXPRESSIONS:
			var index: int = mesh.find_blend_shape_by_name(shape)
			if index >= 0:
				create_tween().tween_method(func(v: float) -> void: mesh.set_blend_shape_value(index, v),
						mesh.get_blend_shape_value(index), weight if shape == name else 0.0, 0.4)


func _play_gesture(clip: String) -> void:
	if _gesture != null and _gesture.has_animation(clip):
		_gesture.play(clip)


func _cue(cue: String) -> void:
	match cue:
		"idle":
			_body.play("idle_breathing")
			_expression("calm_professional", 0.6)
		"blink":
			_face.blink()
		"greet":
			_play_gesture("small_greeting_nod")
		"speak_warm":
			_body.play("stand_conversational")
			_expression("warm_subtle", 0.8)
			_face.set_speaking(true)
		"stop":
			_face.set_speaking(false)
		"listen_concerned":
			_body.play("listen_neutral")
			_expression("concerned_restrained", 0.8)
		"ack":
			_play_gesture("small_acknowledgement_nod")
		"speak_serious":
			_body.play("stand_conversational")
			_expression("professionally_serious", 0.8)
			_face.set_speaking(true)
		"chart":
			_face.set_speaking(false)
			_play_gesture("restrained_chart_indication")
