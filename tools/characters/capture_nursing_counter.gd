extends Node
## Windowed Compatibility-renderer review capture; not Mac acceptance.
## Run with -- --output=/absolute/path.png (defaults to user://nursing_counter.png).
func _ready() -> void:
	var output: String = "user://nursing_counter.png"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	for light: Light3D in main.get_node("World").get_lights():
		light.shadow_enabled = false
	var player: FirstPersonController = main.get_node("Player")
	player.place(Vector3(-0.3, 0.05, -11.05), PI / 2.0, -0.07)
	for i: int in 12:
		await get_tree().process_frame
	var result: Error = get_viewport().get_texture().get_image().save_png(output)
	if result != OK:
		push_error("Counter screenshot failed: %s" % error_string(result))
		get_tree().quit(1)
		return
	main.free()
	main = null
	await get_tree().process_frame
	await get_tree().process_frame
	print("COUNTER_CAPTURE_DONE")
	get_tree().quit()
