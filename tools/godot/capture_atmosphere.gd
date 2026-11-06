extends Node
## Review captures of an explicitly selected zone for the lighting and
## materials baseline: one eye-level view per room, HUD hidden. Windowed
## Compatibility-renderer capture; not Mac acceptance.
##
##   Godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
##       --resolution 1280x720 res://tools/godot/CaptureAtmosphere.tscn -- --output-dir=/absolute/dir [--tag=after] [--rooms=clinical_corridor,nursing_station]
## Writes atmosphere_<tag>_<room>.png.
## Optional --zone=zone_historic_sublevel selects a review floor without
## changing campaign access. --reverse captures the opposite end of each room.


func _ready() -> void:
	var output_dir: String = "user://"
	var tag: String = "now"
	var rooms: PackedStringArray = []
	var zone_id: String = "zone_clinical_wing"
	var reverse: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
		elif argument.begins_with("--tag="):
			tag = argument.trim_prefix("--tag=")
		elif argument.begins_with("--rooms="):
			rooms = argument.trim_prefix("--rooms=").split(",")
		elif argument.begins_with("--zone="):
			zone_id = argument.trim_prefix("--zone=")
		elif argument == "--reverse":
			reverse = true
	Settings.persist = false
	SaveManager.reset_all()
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	AudioDirector.cancel_pending_events()
	for layer: Node in main.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	var player: FirstPersonController = main.get_node("Player")
	player.set_input_enabled(false)
	var world: AuthoredWorld = main.get_node("World")
	var zones: ZoneDirector = main.get_node("ZoneDirector")
	if ContentRegistry.get_zone(zone_id).is_empty():
		push_error("Unknown review zone: " + zone_id)
		main.free()
		get_tree().quit(1)
		return
	# Review-only setup: never expose a second level beside the requested floor.
	zones.set_process(false)
	if zone_id != zones.current_zone_id:
		for loaded_zone: String in world.get_zone_ids():
			world.unload_zone(loaded_zone)
		world.build_zone(zone_id, AuthoredWorld.load_zone_scenes(zone_id))
		zones.current_zone_id = zone_id
	var plan: Dictionary = FloorPlan.snapshot(world, player, zones)
	for floor: Dictionary in plan["floors"]:
		if not rooms.is_empty() and not str(floor["label"]).to_snake_case() in rooms:
			continue
		var rect: Rect2 = floor["rect"]
		var long_x: bool = rect.size.x > rect.size.y
		# Stand near one end of the room and look along it.
		var at: Vector2 = rect.get_center() + (Vector2(-rect.size.x * 0.35, 0) if long_x else Vector2(0, rect.size.y * 0.35))
		var yaw: float = -PI / 2.0 if long_x else 0.0
		if reverse:
			at = rect.get_center() * 2.0 - at
			yaw += PI
		player.place(Vector3(at.x, player.global_position.y, at.y), yaw, -0.08)
		await _frames(6)
		await _save(output_dir, "atmosphere_%s_%s.png" % [tag, str(floor["label"]).to_snake_case()])
	AudioDirector.stop_music(0.01)
	main.free()
	await _frames(4)
	print("ATMOSPHERE_CAPTURE_DONE")
	get_tree().quit()


func _save(output_dir: String, file_name: String) -> void:
	await _frames(4)
	var path: String = output_dir.path_join(file_name)
	var result: Error = get_viewport().get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Capture failed: %s (%s)" % [path, error_string(result)])
	else:
		print("wrote ", path)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame
