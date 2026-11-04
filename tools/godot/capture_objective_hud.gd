extends Node
## Review capture of the objective HUD: the player stands at conversation
## distance facing Bennett right after talking to her, so the "Objective
## complete" banner, the checklist, a toast and Bennett's name tag are on
## screen together. Windowed Compatibility-renderer capture; not Mac acceptance.
##
##   Godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
##       --resolution 1920x1080 res://tools/godot/CaptureObjectiveHUD.tscn -- \
##       --output-dir=/absolute/dir --label=1920x1080
## Writes <label>_objective_hud.png.


func _ready() -> void:
	var output_dir: String = "user://"
	var label: String = "capture"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
		elif argument.begins_with("--label="):
			label = argument.trim_prefix("--label=")
	Settings.persist = false
	SaveManager.reset_all()
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	for light: Light3D in main.get_node("World").get_lights():
		light.shadow_enabled = false
	await _frames(6)
	var bennett: WardCharacter = (main.get_node("World") as AuthoredWorld).get_character("staff_bennett")
	var player: Node3D = main.get_node("Player")
	(bennett.get_node("Interactable") as Interactable).interact(player)
	(main.get_node("InfoPanel") as InfoPanel).close()
	AudioDirector.cancel_pending_events()
	# Stand 1.4 m in front of her, eyes on her name tag's height.
	var target: Vector3 = bennett.global_position
	var forward: Vector3 = -bennett.global_basis.z
	var stand: Vector3 = target + Vector3(forward.x, 0.0, forward.z).normalized() * 1.4
	var to_her: Vector3 = target - stand
	player.call("place", Vector3(stand.x, player.global_position.y, stand.z), atan2(-to_her.x, -to_her.z), 0.12)
	EventBus.notification_requested.emit("Note saved to the chart.")
	await _frames(20)
	await _save(output_dir, "%s_objective_hud.png" % label)
	AudioDirector.stop_music(0.01)
	main.free()
	await _frames(4)
	print("OBJECTIVE_HUD_CAPTURE_DONE")
	get_tree().quit()


func _save(output_dir: String, file_name: String) -> void:
	await _frames(8)
	var path: String = output_dir.path_join(file_name)
	var result: Error = get_viewport().get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Capture failed: %s (%s)" % [path, error_string(result)])
	else:
		print("wrote ", path)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame
