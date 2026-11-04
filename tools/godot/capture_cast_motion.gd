extends Node
## Review captures of the cast motion pass in the real campaign world: Hale walking
## his Chapter 4 route (a strip of frames), and Voss and Elias mid-gesture while
## their acting is driven the way dialogue drives it. Desktop review only; on
## Linux this is the Compatibility renderer on llvmpipe, not Mac/Metal evidence.
##
##   xvfb-run -s "-screen 0 1280x720x24" Godot --rendering-driver opengl3 --path . \
##       res://tools/godot/CaptureCastMotion.tscn -- --output-dir=/tmp/cast_motion

const HALE_CHAPTER: String = "ch4"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var output: String = "user://cast_motion_review"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output = argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	CharacterVisualPreview.set_requests({})
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	var world: AuthoredWorld = main.get_node("World")
	world.configure_chapter(HALE_CHAPTER)
	for light: Light3D in world.get_lights():
		light.shadow_enabled = false
	await get_tree().process_frame
	var camera: Camera3D = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	camera.make_current()

	# Hale walking: camera to the side of his route, frames while he walks out.
	var hale: WardCharacter = world.get_character("staff_hale")
	var route: CastRoute = hale.get_node("CastRoute")
	var a: Vector3 = route.points[0]
	var b: Vector3 = route.points[1]
	var mid: Vector3 = (a + b) * 0.5
	# The staff door corridor is narrow, so the camera follows from behind and above.
	var along: Vector3 = (b - a).normalized()
	camera.global_position = a - along * 0.4 + Vector3.UP * 1.9
	camera.look_at(b + Vector3.UP * 0.6)
	route.player_clearance_m = 0.0
	route._index = 1
	route._wait = 0.0
	var frames: Array[Image] = []
	var t: float = 0.0
	while t < 4.0 and frames.size() < 8:
		await get_tree().process_frame
		t += get_process_delta_time()
		camera.make_current()
		if hale.performer.is_walking() and fmod(t, 0.3) < get_process_delta_time():
			frames.append(get_viewport().get_texture().get_image())
	_save_strip(frames, output.path_join("hale_walk_strip.png"))
	print("CAST_MOTION_CAPTURE hale_walk frames=", frames.size())

	# Voss talking: drive her line the way dialogue does, capture at a gesture peak.
	var voss: WardCharacter = world.get_character("staff_voss")
	_frame(camera, voss, 1.9)
	voss.performer.begin_conversation()
	await _wait_seconds(1.5)
	voss.performer.play_gesture(&"explain_open_hand")
	await _wait_seconds(0.8)
	camera.make_current()
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(output.path_join("voss_explain.png"))
	voss.performer.play_gesture(&"thinking_pause")
	await _wait_seconds(1.0)
	get_viewport().get_texture().get_image().save_png(output.path_join("voss_thinking.png"))
	print("CAST_MOTION_CAPTURE voss")

	var elias: WardCharacter = world.get_character("pt_elias_ward")
	if elias != null and elias.is_present():
		_frame(camera, elias, 1.6)
		elias.performer.play_gesture(&"explain_both_hands")
		await _wait_seconds(0.9)
		get_viewport().get_texture().get_image().save_png(output.path_join("elias_explain.png"))
		print("CAST_MOTION_CAPTURE elias")
	get_tree().quit()


func _frame(camera: Camera3D, actor: WardCharacter, distance: float) -> void:
	# Imported models face +Z (see capture_campaign_cast.gd).
	var model: Node3D = actor.get_node("VisualRoot").get_child(0)
	var front: Vector3 = model.global_basis.z.normalized()
	var height: float = 0.85 if actor.seated else 1.15
	var focus: Vector3 = actor.global_position + Vector3.UP * height
	camera.global_position = focus + front.rotated(Vector3.UP, deg_to_rad(15.0)) * distance + Vector3.UP * 0.1
	camera.look_at(focus)
	camera.make_current()


func _wait_seconds(seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()


func _save_strip(frames: Array[Image], path: String) -> void:
	if frames.is_empty():
		return
	var w: int = frames[0].get_width() / 2
	var h: int = frames[0].get_height() / 2
	var strip: Image = Image.create(w * frames.size(), h, false, frames[0].get_format())
	for i: int in frames.size():
		var small: Image = frames[i].duplicate()
		small.resize(w, h)
		strip.blit_rect(small, Rect2i(0, 0, w, h), Vector2i(i * w, 0))
	strip.save_png(path)
