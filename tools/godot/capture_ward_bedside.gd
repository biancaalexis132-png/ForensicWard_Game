extends Node
## Review captures of the ward-round patients waiting in the patient rooms
## (Chapter 1): each room from its doorway, each patient close up while they
## turn to the conversation, and Room 01 after the next patient arrives.
## Desktop review only; on Linux this is the Compatibility renderer on
## llvmpipe, not Mac/Metal evidence.
##
##   xvfb-run -s "-screen 0 1280x720x24" Godot --rendering-driver opengl3 --path . \
##       res://tools/godot/CaptureWardBedside.tscn -- --output-dir=/tmp/ward_bedside

const WardRoundTests = preload("res://scripts/tests/test_ward_rounds.gd")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var output: String = "user://ward_bedside_review"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output = argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	CharacterVisualPreview.set_requests({})
	WardRounds.reset_state()
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	var world: AuthoredWorld = main.get_node("World")
	await get_tree().process_frame
	var bedside: WardRoundBedside = world.find_child(WardRoundBedside.NODE_NAME, true, false)
	bedside.refresh()
	var camera: Camera3D = Camera3D.new()
	camera.fov = 60.0
	add_child(camera)
	camera.make_current()
	for slot_id: String in ["room_01", "room_02"]:
		var patient: WardCharacter = bedside.occupant(slot_id)
		# From just inside the doorway, at eye height.
		camera.global_position = Vector3(1.85, 1.6, patient.global_position.z + 1.6)
		camera.look_at(patient.global_position + Vector3.UP * 0.8)
		await _wait_seconds(1.0)
		_save(output, "%s_doorway.png" % slot_id)
		_frame(camera, patient, 1.3)
		patient.performer.begin_conversation()
		await _wait_seconds(1.2)
		_save(output, "%s_close.png" % slot_id)
	var ortiz: String = bedside.occupancy()["room_01"]
	var solved: Dictionary = WardRoundTests._solve(WardRounds.get_case(ortiz))
	for lab_id: String in solved["labs"]:
		WardRounds.order_lab(ortiz, lab_id)
	WardRounds.submit_plan(ortiz, solved["plan"])
	var next: WardCharacter = bedside.occupant("room_01")
	camera.global_position = Vector3(1.85, 1.6, next.global_position.z + 1.6)
	camera.look_at(next.global_position + Vector3.UP * 0.8)
	await _wait_seconds(1.0)
	_save(output, "room_01_next_patient.png")
	print("WARD_BEDSIDE_CAPTURE done next=", next.ward_round_case_id)
	get_tree().quit()


func _frame(camera: Camera3D, actor: WardCharacter, distance: float) -> void:
	var model: Node3D = actor.get_node("VisualRoot").get_child(0)
	var front: Vector3 = model.global_basis.z.normalized()
	var focus: Vector3 = actor.global_position + Vector3.UP * 1.05
	camera.global_position = focus + front.rotated(Vector3.UP, deg_to_rad(20.0)) * distance + Vector3.UP * 0.15
	camera.look_at(focus)
	camera.make_current()


func _save(output: String, file: String) -> void:
	get_viewport().get_texture().get_image().save_png(output.path_join(file))


func _wait_seconds(seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
