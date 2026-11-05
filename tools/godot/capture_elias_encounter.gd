extends Node
## Review captures of the Elias encounter: the staged interview room, each
## examination step mid-motion (the psychiatrist's reach and Elias's arm),
## the orders tab, the lorazepam reassessment, and the busier ward corridor
## and nursing station with background staff.
## Desktop review only; on Linux this is the Compatibility renderer on
## llvmpipe, not Mac/Metal evidence.
##
##   xvfb-run -s "-screen 0 1600x900x24" Godot --rendering-driver opengl3 --path . \
##       res://tools/godot/CaptureEliasEncounter.tscn -- --output-dir=/tmp/elias --gender=female

const ELIAS: String = "pt_elias_ward"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var output: String = "user://elias_encounter_review"
	var gender: String = "female"
	var only: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output = argument.trim_prefix("--output-dir=")
		if argument.begins_with("--gender="):
			gender = argument.trim_prefix("--gender=")
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	DirAccess.make_dir_recursive_absolute(output)
	CharacterVisualPreview.set_requests({})
	var profile: Dictionary = ProtagonistProfile.get_profile()
	profile["gender"] = gender
	profile["configured"] = true
	ProtagonistProfile.load_save_data(profile)
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	await _wait_seconds(1.0)
	if only.is_empty() or only == "ward":
		await _ward(main, output)
	EventBus.ui_panel_requested.emit("interview", {"patient_id": ELIAS})
	await _wait_seconds(0.5)
	var screen: EncounterScreen = main.get_node("EncounterScreen")
	await _step(screen, "open_introduce", 3.5, output, "01_introduce")
	await _step(screen, "hx_onset", 4.5, output, "02_sitter_reads_packet")
	for step: String in ["ex_pulse", "ex_mouth", "ex_echopraxia", "ex_arm_raise", "ex_tone", "ex_clonus"]:
		await _step(screen, step, 3.8, output, "03_" + step)
	screen.skip_all()
	EncounterManager.perform_step(ELIAS, "hx_intake")
	screen.show_section("plan")
	await _wait_seconds(0.6)
	_save(output, "04_orders_tab.png")
	for id: String in ["eo_lorazepam_challenge", "eo_lab_ck", "eo_medical_review", "eo_fluid_chart"]:
		screen.toggle_order(id, true)
	screen.give_orders()
	await _wait_seconds(0.5)
	screen.skip_all()
	await _wait_seconds(0.4)
	_save(output, "05_orders_given.png")
	screen.close()
	TimeManager.advance(60, "capture")
	EventBus.ui_panel_requested.emit("interview", {"patient_id": ELIAS})
	await _wait_seconds(0.5)
	screen = main.get_node("EncounterScreen")
	await _step(screen, "re_observe", 2.5, output, "06_reassess_looks")
	await _step(screen, "re_drink", 4.0, output, "06_reassess_drinks")
	print("ELIAS_ENCOUNTER_CAPTURE done")
	get_tree().quit()


func _step(screen: EncounterScreen, step: String, seconds: float, output: String, file: String) -> void:
	screen.skip_all()
	if step.begins_with("ex_"):
		screen.show_section("exam")
	screen.do_step(step)
	await _wait_seconds(seconds)
	_save(output, file + ".png")


func _ward(main: Node, output: String) -> void:
	var camera: Camera3D = Camera3D.new()
	camera.fov = 62.0
	add_child(camera)
	camera.make_current()
	await _wait_seconds(6.0)
	camera.global_position = Vector3(0.2, 1.65, -1.2)
	camera.look_at(Vector3(-0.2, 1.2, -12.0))
	await _wait_seconds(0.4)
	_save(output, "00_corridor.png")
	camera.global_position = Vector3(0.6, 1.65, -10.0)
	camera.look_at(Vector3(-3.6, 1.0, -10.2))
	await _wait_seconds(0.4)
	_save(output, "00_nursing_station.png")
	camera.queue_free()


func _save(output: String, file: String) -> void:
	get_viewport().get_texture().get_image().save_png(output.path_join(file))


func _wait_seconds(seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
