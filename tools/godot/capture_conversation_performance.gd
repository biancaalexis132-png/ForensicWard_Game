extends Node
## Review close-ups of ConversationPerformance in the campaign world: Voss and Hale
## at rest, listening, in the beat before a reply, speaking, and glancing aside.
## Desktop review only; on Linux this is the Compatibility renderer on llvmpipe.
##
##   xvfb-run -s "-screen 0 1280x720x24" Godot --rendering-driver opengl3 --path . \
##       res://tools/godot/CaptureConversationPerformance.tscn -- --output-dir=/tmp/perf

const CHAPTER: String = "ch4"
const STATES: PackedStringArray = ["rest", "listening", "beat", "speaking", "aside"]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var output: String = "user://conversation_performance_review"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output = argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	CharacterVisualPreview.set_requests({})
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	var world: AuthoredWorld = main.get_node("World")
	world.configure_chapter(CHAPTER)
	await get_tree().process_frame
	var cutscenes: Node = main.find_child("CutsceneDirector", true, false)
	if cutscenes != null and cutscenes.has_method("close"):
		cutscenes.call("close")
	var camera: Camera3D = Camera3D.new()
	camera.fov = 30.0
	add_child(camera)
	for id: String in ["staff_voss", "staff_hale"]:
		var actor: WardCharacter = world.get_character(id)
		if actor == null or actor.performer == null or actor.performer.conversation == null:
			print("CONVERSATION_CAPTURE skipped ", id)
			continue
		var acting: ConversationPerformance = actor.performer.conversation
		acting.set_process(false)  # Stepped by hand below, so each state is exact.
		var line: String = _line_for(id)
		var frames: Array[Image] = []
		for state: String in STATES:
			_frame(camera, actor)
			match state:
				"rest":
					acting._next_glance = INF
					await _step(acting, 1.0)
				"listening":
					actor.performer.begin_conversation()
					await _step(acting, 1.2)
				"beat":
					EventBus.story_option_selected.emit("capture", "capture")
					EventBus.subtitle_shown.emit(line, actor.name, "", 8.0)
					await _step(acting, 0.3)
				"speaking":
					await _step(acting, 1.2)
					acting._next_break = INF
					acting._away_until = -1.0
					await _step(acting, 0.4)
				"aside":
					acting._next_break = 0.0
					await _step(acting, 0.3)
			camera.make_current()
			await get_tree().process_frame
			frames.append(get_viewport().get_texture().get_image())
		EventBus.dialogue_line_finished.emit(line, true)
		AudioDirector.stop_dialogue()
		_save_strip(frames, output.path_join(id + "_conversation.png"))
		print("CONVERSATION_CAPTURE ", id, " frames=", frames.size())
	get_tree().quit()


func _line_for(id: String) -> String:
	var lines: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://audio/voice/voice_lines.json"))
	for key: String in lines:
		if str(lines[key].get("speaker", "")) == id:
			return key
	return ""


func _frame(camera: Camera3D, actor: WardCharacter) -> void:
	var model: Node3D = actor.get_node("VisualRoot").get_child(0)
	var front: Vector3 = model.global_basis.z.normalized()
	var focus: Vector3 = actor.global_position + Vector3.UP * (_eye_height(model) - 0.04)
	camera.global_position = focus + front.rotated(Vector3.UP, deg_to_rad(8.0)) * 0.95
	camera.look_at(focus)
	camera.make_current()


func _eye_height(model: Node3D) -> float:
	for node: Node in model.find_children("*", "Skeleton3D", true, false):
		var skeleton: Skeleton3D = node as Skeleton3D
		var eye: int = skeleton.find_bone("eye_l")
		if eye >= 0:
			return (skeleton.global_transform * skeleton.get_bone_global_pose(eye)).origin.y - model.global_position.y
	return 1.58


func _step(acting: ConversationPerformance, seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		var delta: float = maxf(get_process_delta_time(), 1.0 / 60.0)
		acting.tick(delta)
		t += delta


func _save_strip(frames: Array[Image], path: String) -> void:
	if frames.is_empty():
		return
	# The middle of each frame: the face, not the room or the HUD.
	var w: int = frames[0].get_width() * 3 / 10
	var h: int = frames[0].get_height() * 6 / 10
	var crop: Rect2i = Rect2i((frames[0].get_width() - w) / 2, frames[0].get_height() * 15 / 100, w, h)
	var strip: Image = Image.create(w * frames.size(), h, false, frames[0].get_format())
	for i: int in frames.size():
		strip.blit_rect(frames[i], crop, Vector2i(i * w, 0))
	strip.save_png(path)
