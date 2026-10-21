extends Node
## Windowed Compatibility-renderer review capture of the ward door signs; not
## Mac acceptance. Run with -- --output-dir=/absolute/dir (defaults to user://).
## Writes door_signs_<door_id>.png, viewed from the side of the "Sign" plaque.

const DOORS: Array[String] = ["door_archive", "door_office", "door_interview", "door_nurse_station"]
const VIEW_DISTANCE: float = 1.6


func _ready() -> void:
	var output_dir: String = "user://"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	var world: AuthoredWorld = main.get_node("World")
	var player: FirstPersonController = main.get_node("Player")
	for door_id: String in DOORS:
		var door: ImportedDoor = world.get_door(door_id)
		var sign: Node3D = door.get_parent().get_node_or_null("Sign") if door != null else null
		if sign == null:
			push_error("No sign on %s" % door_id)
			continue
		for side: String in ["Sign", "SignBack"]:
			var plaque: Node3D = door.get_parent().get_node(side)
			# Label3D reads along its +Z: stand in front of it, eye level, looking back.
			var facing: Vector3 = plaque.global_basis.z.normalized()
			facing.y = 0.0
			var stand: Vector3 = plaque.global_position + facing.normalized() * VIEW_DISTANCE
			stand.y = door.get_parent().global_position.y + 0.05
			var to_sign: Vector3 = plaque.global_position - stand
			var yaw: float = atan2(-to_sign.x, -to_sign.z)
			player.place(stand, yaw, 0.12)
			for i: int in 10:
				await get_tree().process_frame
			var path: String = output_dir.path_join("door_signs_%s_%s.png" % [door_id, side.to_lower()])
			if get_viewport().get_texture().get_image().save_png(path) != OK:
				push_error("Door sign screenshot failed: " + path)
	main.free()
	await get_tree().process_frame
	print("DOOR_SIGN_CAPTURE_DONE")
	get_tree().quit()
