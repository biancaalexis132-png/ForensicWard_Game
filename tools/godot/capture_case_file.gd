extends Node
## Review capture of the case file (Tab) partway through Chapter 3, with
## Chapter 2 notes behind it, plus the HUD objective line with its place.
## Windowed Compatibility-renderer capture; not Mac acceptance.
##
##   Godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
##       --resolution 1920x1080 res://tools/godot/CaptureCaseFile.tscn -- \
##       --output-dir=/absolute/dir
## Writes case_file_all.png, case_file_open.png and case_file_hud.png.

const CH2_FLAGS: Array[String] = ["ch2_clinical_work_owned", "ch2_discrepancy_recorded", "ch2_sources_requested",
		"ch2_witness_account_recorded", "ch2_witness_work_orders", "ch2_lobby_state_documented"]
const CH3_FLAGS: Array[String] = ["ch3_coverage_confirmed", "ch3_audit_summary_read", "ch3_scope_clarified",
		"ch3_question_confirmed", "ch3_briefing_complete", "ch3_levels_noted"]


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
	await _frames(6)
	var director: ChapterDirector = main.get_node("ChapterDirector")
	director.start_chapter("ch2")
	for flag: String in CH2_FLAGS:
		director.set_flag(flag)
	director.start_chapter("ch3")
	for flag: String in CH3_FLAGS:
		director.set_flag(flag)
	EvidenceManager.acquire_clue("clue_transfer", "capture")
	AudioDirector.cancel_pending_events()
	await _frames(10)
	var cutscene: CanvasLayer = main.get_node("CutsceneDirector")
	if cutscene.is_open:
		cutscene.call("close")
	await _frames(30)
	await _save(output_dir, "case_file_hud.png")
	EventBus.ui_panel_requested.emit(CaseFileScreen.PANEL_ID, {})
	await _frames(10)
	await _save(output_dir, "case_file_all.png")
	(main.get_node("CaseFileScreen") as CaseFileScreen).set_filter("open")
	await _frames(10)
	await _save(output_dir, "case_file_open.png")
	AudioDirector.stop_music(0.01)
	main.free()
	await _frames(4)
	print("CASE_FILE_CAPTURE_DONE")
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
