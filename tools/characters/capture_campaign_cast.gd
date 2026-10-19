extends Node
## Capture actual integrated game models for desktop review, not Mac acceptance.
## Run in a window with -- --output-dir=/path; no character-preview argument.
func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var output: String = "user://campaign_cast_review"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output = argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	CharacterVisualPreview.set_requests({})
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	var world: AuthoredWorld = main.get_node("World")
	# Software-renderer review captures omit shadows to keep batch review
	# practical. Normal game lighting/shadow settings are never changed.
	for light: Light3D in world.get_lights():
		light.shadow_enabled = false
	await get_tree().process_frame
	var camera: Camera3D = Camera3D.new()
	camera.fov = 45.0
	add_child(camera)
	var captured: Dictionary = {}
	var report: Array[Dictionary] = []
	for chapter: String in ContentRegistry.get_chapter_ids():
		world.configure_chapter(chapter)
		for light: Light3D in world.get_lights():
			light.shadow_enabled = false
		await get_tree().process_frame
		for entry: Dictionary in ContentRegistry.get_world(chapter)["characters"]:
			var id: String = entry["character_id"]
			if captured.has(id):
				continue
			var zone: String = str(entry.get("zone", world.start_zone_id))
			if not world.has_zone(zone):
				world.build_zone(zone, AuthoredWorld.load_zone_scenes(zone))
			var actor: WardCharacter = world.get_character(id)
			# For review only, expose a story-gated actor without changing flags.
			var prior_visible: bool = actor.visible
			var prior_process: ProcessMode = actor.process_mode
			var neighbours: Array[Dictionary] = []
			for other: Node in world.find_children("Character_*", "", true, false):
				if other is WardCharacter and other != actor and (other as WardCharacter).global_position.distance_to(actor.global_position) < 0.1:
					neighbours.append({"node": other, "visible": other.visible, "process": other.process_mode})
					other.visible = false
					other.process_mode = Node.PROCESS_MODE_DISABLED
			actor.visible = true
			actor.process_mode = Node.PROCESS_MODE_INHERIT
			var model: Node3D = actor.get_node("VisualRoot").get_child(0)
			var front: Vector3 = model.global_basis.z.normalized()
			var focus: Vector3 = actor.global_position + Vector3.UP * (0.85 if actor.seated else 1.05)
			camera.global_position = focus + front * (1.5 if actor.seated else 2.8) + Vector3.UP * 0.15
			camera.look_at(focus)
			camera.make_current()
			for frame: int in 3:
				await get_tree().process_frame
			var result: Error = get_viewport().get_texture().get_image().save_png(output.path_join(id + ".png"))
			assert(result == OK)
			if actor.seated:
				# A side view exposes the chair/feet alignment hidden by the table.
				camera.global_position = actor.global_position + front * 1.2 + model.global_basis.x.normalized() * 1.3 + Vector3.UP * 0.9
				camera.look_at(actor.global_position + Vector3.UP * 0.65)
				for frame: int in 3:
					await get_tree().process_frame
				get_viewport().get_texture().get_image().save_png(output.path_join(id + "_side.png"))
			actor.visible = prior_visible
			actor.process_mode = prior_process
			for neighbour: Dictionary in neighbours:
				neighbour["node"].visible = neighbour["visible"]
				neighbour["node"].process_mode = neighbour["process"]
			captured[id] = true
			report.append({"id": id, "chapter": chapter, "model": actor.visual_scene.resource_path,
				"actor_position": var_to_str(actor.global_position), "model_front": var_to_str(front),
				"review_status": actor.get_meta("visual_review_status", ""), "seated": actor.seated})
			print("CAST_CAPTURE ", id)
	var file: FileAccess = FileAccess.open(output.path_join("capture_report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer": RenderingServer.get_video_adapter_name(),
		"note": "Actual campaign integration; hidden actors exposed only for review; shadows disabled for software batch captures. Not Mac/Metal appearance/performance evidence.", "cast": report}, "\t"))
	file.close()
	main.free()
	await get_tree().process_frame
	print("CAST_CAPTURE_DONE ", captured.size())
	get_tree().quit()
