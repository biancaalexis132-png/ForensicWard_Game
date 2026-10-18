extends SceneTree
## Bounded diagnostic in the existing nursing station, using real authored audio.
## No preview registration dependency and no gameplay/save/clinical content writes.
## godot --path . -s res://tools/godot/review_dialogue_visemes.gd
## Optional engine --write-movie captures this eight-second diagnostic.

func _initialize() -> void:
	root.size = Vector2i(640, 480)
	root.content_scale_size = Vector2i(640, 480)
	CharacterVisualPreview.set_requests({})
	_run.call_deferred()


func _run() -> void:
	var world: Node3D = load("res://scenes/world/HospitalGreybox.tscn").instantiate() as Node3D
	root.add_child(world)
	for i: int in 5:
		await process_frame
	var actor: Node3D = world.find_child("NurseBennett", true, false) as Node3D
	if actor == null or not bool(actor.call("set_visual_scene", load("res://assets/exports/characters/Naomi_Bennett_v06_mpfb.glb") as PackedScene)):
		push_error("Viseme review could not attach the existing MPFB candidate")
		quit(1)
		return
	var model: Node3D = actor.get_node("VisualRoot").get_child(0)
	model.transform = CharacterVisualPreview.placement_for("staff_bennett") * model.transform
	var camera: Camera3D = Camera3D.new()
	world.add_child(camera)
	var head: Vector3 = model.global_position + Vector3(0.0, 1.52, 0.0)
	camera.global_position = head + model.global_basis.z.normalized() * 1.25 + model.global_basis.x.normalized() * 0.3
	camera.look_at(head - Vector3(0.0, 0.15, 0.0))
	camera.fov = 38.0
	camera.current = true
	var label: Label = Label.new()
	label.text = "DIAGNOSTIC: approximate text visemes / unapproved v06 MPFB candidate"
	label.position = Vector2(12.0, 12.0)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.add_child(label)
	root.add_child(layer)
	var audio: Node = root.get_node("AudioDirector")
	audio.call("play_line", "ch1_b2_bennett_001", actor)
	await create_timer(8.0, false).timeout
	# Match Main's audio teardown, including releasing the native OGG playback.
	for node: Node in actor.find_children("*", "AudioStreamPlayer3D", true, false):
		var voice: AudioStreamPlayer3D = node as AudioStreamPlayer3D
		voice.stop()
		voice.stream = null
	audio.call("stop_dialogue")
	# Let the existing awaitable line/duck-release callbacks settle before teardown.
	await create_timer(1.0, false).timeout
	world.queue_free()
	layer.queue_free()
	await process_frame
	await process_frame
	print("VISEME_REVIEW_DONE")
	quit(0)
