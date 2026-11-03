extends Node
## Review captures of the ward round screen: Lebel's chart, her labs after
## ordering, a plan the attending sends back, then the accepted plan.
## Desktop review only (Compatibility renderer on Linux, not Mac evidence).
##
##   xvfb-run -s "-screen 0 1920x1080x24" Godot --rendering-driver opengl3 --path . \
##       res://tools/godot/CaptureWardRound.tscn -- --output-dir=/tmp/ward_round

const CASE_ID: String = "wr_ch2_lebel"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var output: String = "user://ward_round_review"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output = argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	var director: ChapterDirector = main.get_node("ChapterDirector")
	director.load_save_data({"current": "ch2", "chapters": {}})
	await _frames(5)
	EventBus.ui_panel_requested.emit("ehr", {})
	await _frames(5)
	_save(output, "ehr_button.png")
	main.get_node("EHRScreen").open_ward_round()
	var screen: WardRoundScreen = main.get_node("WardRoundScreen")
	screen.select_case(CASE_ID)
	screen.show_tab("Chart")
	await _frames(5)
	_save(output, "chart.png")
	for lab_id: String in ["lithium_level", "bmp", "ecg"]:
		screen.order_lab(lab_id)
	screen.show_tab("Labs")
	await _frames(5)
	_save(output, "labs.png")
	screen.set_med_action("lithium", "reduce")
	screen.submit()
	screen.show_tab("Plan")
	await _frames(5)
	_save(output, "plan_revise.png")
	screen.set_med_action("lithium", "hold")
	screen.set_med_action("ibuprofen", "stop")
	screen.set_intervention("medical_transfer", true)
	screen.submit()
	screen.select_case(CASE_ID)
	screen.show_tab("Plan")
	await _frames(5)
	_save(output, "plan_accepted.png")
	screen.show_tab("Debrief")
	await _frames(5)
	_save(output, "debrief.png")
	# Replay with every useful test and an explanation for a better score.
	screen.replay()
	var case: Dictionary = WardRounds.get_case(CASE_ID)
	for lab_id: String in case["labs"]:
		if case["labs"][lab_id]["verdict"] in ["required", "helpful"]:
			screen.order_lab(lab_id)
	screen.set_med_action("lithium", "hold")
	screen.set_med_action("ibuprofen", "stop")
	screen.set_intervention("medical_transfer", true)
	screen.set_intervention("explain_plan", true)
	screen.submit()
	await _frames(5)
	_save(output, "debrief_replay.png")
	print("WARD_ROUND_CAPTURE done")
	get_tree().quit()


func _save(output: String, file: String) -> void:
	get_viewport().get_texture().get_image().save_png(output.path_join(file))


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame
