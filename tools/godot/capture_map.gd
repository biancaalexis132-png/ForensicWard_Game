extends Node
## Review capture of the spatial map (pause menu > Spatial Map) in the
## clinical wing at the start of Chapter 1. Windowed Compatibility-renderer
## capture; not Mac acceptance.
##
##   Godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
##       --resolution 1920x1080 res://tools/godot/CaptureMap.tscn -- --output-dir=/absolute/dir
## Writes map_clinical_wing.png.


func _ready() -> void:
	var output_dir: String = "user://"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	Settings.persist = false
	SaveManager.reset_all()
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	for light: Light3D in main.get_node("World").get_lights():
		light.shadow_enabled = false
	await _frames(10)
	AudioDirector.cancel_pending_events()
	EventBus.ui_panel_requested.emit(MapScreen.PANEL_ID, {})
	await _frames(20)
	await _save(output_dir, "map_clinical_wing.png")
	AudioDirector.stop_music(0.01)
	main.free()
	await _frames(4)
	print("MAP_CAPTURE_DONE")
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
