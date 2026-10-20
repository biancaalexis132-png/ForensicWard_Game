extends TestCase

var _main_node: Node


func after_each() -> void:
	if is_instance_valid(_main_node):
		_main_node.free()
	_main_node = null
	runner.get_tree().paused = false
	super.after_each()


func test_journal_json_round_trip_and_old_save_default() -> void:
	var tags: Array = [{"source": "player"}]
	var id: String = CaseJournal.add_clinical_entry("pt_test", "note", "Test note", tags)
	tags[0]["source"] = "changed"
	check_eq(CaseJournal.get_all_entries()[0]["tags"][0]["source"], "player", "tags are owned by the journal")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save succeeds")
	CaseJournal.reset_state()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "JSON save loads into typed entry storage")
	check_eq(CaseJournal.get_entries_for_patient("pt_test")[0]["id"], id, "entry survives JSON round trip")
	var snapshot: Array[Dictionary] = CaseJournal.get_all_entries()
	snapshot[0]["content"] = "changed"
	check_eq(CaseJournal.get_all_entries()[0]["content"], "Test note", "queries cannot mutate stored notes")
	CaseJournal.load_save_data({})
	check(CaseJournal.get_all_entries().is_empty(), "missing journal state starts empty")


func test_optional_panels_pause_and_escape_and_reuse() -> void:
	_main_node = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main_node)
	await runner.get_tree().process_frame
	var player: FirstPersonController = _main_node.get_node("Player")
	var before: Dictionary = SaveManager.capture_state()
	for panel_id: String in ["case_journal", "map"]:
		var node_name: String = "CaseJournalScreen" if panel_id == "case_journal" else "MapScreen"
		var pause: PauseMenu = _main_node.get_node("PauseMenu")
		pause.open()
		var button_name: String = "CaseJournal" if panel_id == "case_journal" else "Directory"
		pause.get_node("Root/Panel/Margin/VBox/" + button_name).pressed.emit()
		var panel: CanvasLayer = _main_node.get_node(node_name)
		check(panel.get("is_open"), "menu opens " + panel_id)
		check(not runner.get_tree().paused, "menu releases scene pause")
		check(TimeManager.is_paused(), "panel pauses clock")
		check(not player.input_enabled, "panel prevents player movement")
		check_eq(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE, "panel releases mouse")
		var escape: InputEventAction = InputEventAction.new()
		escape.action = "pause"
		escape.pressed = true
		_main_node.call("_unhandled_input", escape)
		check(not panel.get("is_open"), "Escape closes " + panel_id)
		check(player.input_enabled, "closing restores movement")
		EventBus.ui_panel_requested.emit(panel_id, {})
		check_eq(_main_node.get_node(node_name), panel, "reopening reuses panel")
		panel.call("close")
	check_eq(SaveManager.capture_state(), before, "viewing panels writes no run state")


func test_journal_scene_lists_and_displays_entries() -> void:
	CaseJournal.add_clinical_entry("pt_test", "note", "Test content")
	var panel: CaseJournalScreen = load("res://scenes/ui/CaseJournalScreen.tscn").instantiate()
	runner.add_child(panel)
	panel.open()
	check_eq(panel._list.get_child_count(), 1, "scene paths resolve and list has entry")
	check("Test content" in panel._details.text, "selected entry content is visible")
	panel.close()
	panel.free()


func test_title_settings_hide_gameplay_panel_buttons() -> void:
	var pause: PauseMenu = load("res://scenes/ui/PauseMenu.tscn").instantiate()
	runner.add_child(pause)
	pause.open_settings_from_title()
	for button_name: String in ["CaseJournal", "Directory"]:
		check(not pause.get_node("Root/Panel/Margin/VBox/" + button_name).visible, "title settings hides " + button_name)
	pause.close()
	pause.open()
	for button_name: String in ["CaseJournal", "Directory"]:
		check(pause.get_node("Root/Panel/Margin/VBox/" + button_name).visible, "game menu shows " + button_name)
	pause.close()
	pause.free()
