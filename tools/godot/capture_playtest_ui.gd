extends Node
## Review capture of the playtest UI pass: the EHR (Next step bar, Orders tab,
## Summary cards) and the document viewer for the Chapter 1 transfer summary.
## Windowed Compatibility-renderer review capture; not Mac acceptance.
##
## Run in a window at the size to check, for example:
##   Godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
##       --resolution 1440x900 res://tools/godot/CapturePlaytestUI.tscn -- \
##       --output-dir=/absolute/dir --label=1440x900
## Writes <label>_ehr_summary.png, <label>_ehr_orders.png,
## <label>_ehr_order_confirm.png and <label>_document_transfer.png.

const ELIAS: String = "pt_elias_ward"


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
	# Chapter 1 up to obj_act: Bennett met, one finding witnessed, note saved.
	var bennett: WardCharacter = (main.get_node("World") as AuthoredWorld).get_character("staff_bennett")
	(bennett.get_node("Interactable") as Interactable).interact(main.get_node("Player"))
	(main.get_node("InfoPanel") as InfoPanel).close()
	PatientManager.record_observation(ELIAS, "obs_mutism", "interview:capture")
	var none: Array[String] = []
	PatientManager.save_note(ELIAS, ["obs_mutism"] as Array[String], none, "Reduced intake; reassess next shift.")
	EventBus.ui_panel_requested.emit("ehr", {"patient_id": ELIAS, "title": "EHR Workstation (Office)"})
	var ehr: EHRScreen = main.get_node("EHRScreen")
	ehr.show_tab("Summary")
	await _save(output_dir, label + "_ehr_summary.png")
	ehr.go_to_next_step()
	await _save(output_dir, label + "_ehr_orders.png")
	ehr.request_place("ord_medical_team_review")
	await _save(output_dir, label + "_ehr_order_confirm.png")
	ehr.cancel_order()
	ehr.close()
	WorldActions.reveal_clue("clue_transfer", "pickup:capture")
	await _save(output_dir, label + "_document_transfer.png")
	(main.get_node("InfoPanel") as InfoPanel).close()
	AudioDirector.stop_music(0.01)
	main.free()
	await _frames(4)
	print("PLAYTEST_UI_CAPTURE_DONE")
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
