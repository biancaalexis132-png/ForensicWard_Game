extends TestCase
## Objective feedback: the checklist derives from ChapterDirector's saved
## story state, completing an objective shows one "Objective complete" banner
## then a "New objective" notice, upcoming objectives never show, and saving,
## loading or resetting never repeats a banner. Settings switch each part off.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"

var _main: Node3D = null


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	for key: String in ["objective_checklist", "objective_banners", "objective_sound", "reduce_motion"]:
		Settings.set_value(key, Settings.DEFAULTS[key])
	AudioDirector.cancel_pending_events()  # Talking to Bennett queues her authored scene.
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func test_first_objective_is_announced_once_and_checklist_hides_upcoming() -> void:
	await _settle()
	check_eq(_tracker().banner_log, ["New objective: Report to the charge nurse at the nursing station."] as Array[String],
			"the opening objective is announced once")
	var text: String = _tracker().get_checklist_text()
	check("Report to the charge nurse" in text, "current objective listed")
	check(not "Interview Room A" in text, "upcoming objectives are not shown")


func test_completing_an_objective_shows_complete_then_new() -> void:
	await _settle()
	await _talk_to_bennett()
	check_eq(_tracker().banner_log.slice(1), [
			"Objective complete: Report to the charge nurse at the nursing station.",
			"New objective: See Elias Ward in Interview Room A."] as Array[String], "complete, then the next objective")
	check(_tracker().is_banner_showing(), "banner on screen")
	var text: String = _tracker().get_checklist_text()
	check("Report to the charge nurse" in text and "See Elias Ward" in text, "done and current objectives listed")
	var director: ChapterDirector = _main.get_node("ChapterDirector")
	check_eq(director.get_objective_list()[0]["status"], "done", "status comes from the director")


func test_reevaluating_and_reloading_never_repeat_banners() -> void:
	await _settle()
	await _talk_to_bennett()
	var count: int = _tracker().banner_log.size()
	(_main.get_node("ChapterDirector") as ChapterDirector).evaluate()
	await _talk_to_bennett()
	check_eq(_tracker().banner_log.size(), count, "no repeat from re-evaluation or talking again")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	await runner.get_tree().process_frame
	check_eq(_tracker().banner_log.size(), count, "loading a save repeats nothing")
	check("See Elias Ward" in _tracker().get_checklist_text(), "checklist restored from the save")


func test_loading_an_earlier_save_does_not_announce_or_complete() -> void:
	await _settle()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save before talking to Bennett")
	await _talk_to_bennett()
	var count: int = _tracker().banner_log.size()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load the earlier save")
	await runner.get_tree().process_frame
	check_eq(_tracker().banner_log.size(), count, "going back is silent")
	await _talk_to_bennett()
	check_eq(_tracker().banner_log.size(), count + 2, "replaying from the earlier save shows its banners again, once")


func test_settings_turn_parts_off() -> void:
	await _settle()
	Settings.set_value("objective_checklist", false)
	check_eq(_tracker().get_checklist_text(), "", "checklist hidden")
	Settings.set_value("objective_banners", false)
	await _talk_to_bennett()
	check(not _tracker().is_banner_showing(), "no banner when banners are off")
	check_eq(_tracker().banner_log.size(), 3, "still recorded once, so turning banners on later repeats nothing")


## Lets the director announce the opening objective (TestRunner does not await before_each).
func _settle() -> void:
	await runner.get_tree().process_frame
	await runner.get_tree().process_frame


func _talk_to_bennett() -> void:
	var bennett: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character("staff_bennett")
	(bennett.get_node("Interactable") as Interactable).interact(_main.get_node("Player"))
	(_main.get_node("InfoPanel") as InfoPanel).close()
	AudioDirector.cancel_pending_events()
	# The audio server releases a stopped clip's playback on a later mix step.
	await runner.get_tree().create_timer(0.3).timeout


func _tracker() -> ObjectiveTracker:
	return _main.get_node("ObjectiveTracker")
