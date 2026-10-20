extends TestCase
## Split-screen milestones: valid data, review-only until approved, shown
## once after their objective and only when nothing else is open, skip,
## pause and replay, no story or evidence state written, and saves that
## remember a milestone was shown without replaying it.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const MILESTONE: String = "ms_ch1_first_assessment"
const ELIAS: String = "pt_elias_ward"

var _main: Node3D = null


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	AudioDirector.cancel_pending_events()
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func test_shipped_milestones_are_valid_and_review_only() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MilestonePresenter.DATA_PATH))
	for entry: Dictionary in data["milestones"]:
		check_eq(MilestonePresenter.validate(entry), [] as Array[String], "valid: " + entry["id"])
		check(not entry["approved"], "review-only until the owner approves: " + entry["id"])
	check_contains(MilestonePresenter.validate({"id": "x", "after_objective": "obj_nope"}), "must start with ms_", "id prefix")


func test_unapproved_milestone_never_plays_in_the_campaign() -> void:
	await _complete_obj_act()
	check(not _presenter().is_open, "not shown")
	check(not _presenter().has_shown(MILESTONE), "not recorded")


func test_approved_milestone_waits_for_a_clear_screen_then_plays_once() -> void:
	_presenter().review_mode = true  # Stands in for owner approval.
	var before_flags: Array = (_main.get_node("ChapterDirector") as ChapterDirector).get_chapter_flags("ch1")
	var clues: Variant = SaveManager.capture_state().get("evidence")
	await _complete_obj_act()
	check(not _presenter().is_open, "waits while the EHR is open")
	(_main.get_node("EHRScreen") as EHRScreen).close()
	check(_presenter().is_open, "plays once the screen is clear")
	check_eq((_main as Main).get_presentation_state(), Main.MILESTONE, "milestone state")
	check(not (_main.get_node("Player") as FirstPersonController).input_enabled, "milestone owns input")
	check_eq(_presenter().get_captions(), [_objective_text("obj_document"), _objective_text("obj_act")] as Array[String],
			"captions are existing objective text")
	_presenter().toggle_pause()
	_presenter().advance(100.0)
	check(_presenter().is_open, "paused milestones do not advance")
	_presenter().toggle_pause()
	_presenter().replay()
	check(_presenter().is_open, "replay restarts it")
	_presenter().skip()
	check_eq((_main as Main).get_presentation_state(), Main.GAMEPLAY, "gameplay restored")
	check((_main.get_node("Player") as FirstPersonController).input_enabled, "player input restored")
	check(not TimeManager.is_paused(), "clock restored")
	check_eq((_main.get_node("ChapterDirector") as ChapterDirector).get_chapter_flags("ch1"), before_flags, "no story flag")
	check_eq(SaveManager.capture_state().get("evidence"), clues, "no evidence granted")
	_presenter().check_milestones()
	check(not _presenter().is_open, "never shown twice")


func test_save_remembers_shown_and_load_does_not_replay() -> void:
	_presenter().review_mode = true
	await _complete_obj_act()
	(_main.get_node("EHRScreen") as EHRScreen).close()
	_presenter().skip()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	await runner.get_tree().process_frame
	check(_presenter().has_shown(MILESTONE), "shown state restored")
	check(not _presenter().is_open, "loading does not replay it")
	SaveManager.reset_all()
	check(not _presenter().has_shown(MILESTONE), "a new game forgets it")


## Plays Chapter 1 up to the clinical action, so the current objective moves on.
func _complete_obj_act() -> void:
	await runner.get_tree().process_frame
	var bennett: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character("staff_bennett")
	(bennett.get_node("Interactable") as Interactable).interact(_main.get_node("Player"))
	(_main.get_node("InfoPanel") as InfoPanel).close()
	AudioDirector.cancel_pending_events()
	await runner.get_tree().create_timer(0.3).timeout  # Lets the stopped clip release.
	PatientManager.record_observation(ELIAS, "obs_mutism", "test")
	EventBus.ui_panel_requested.emit("ehr", {"patient_id": ELIAS})
	var ehr: EHRScreen = _main.get_node("EHRScreen")
	ehr.set_note_selection(["obs_mutism"], [], "Plan.")
	ehr.submit_note()
	ehr.commit_action("request_medical_review")


func _objective_text(objective_id: String) -> String:
	for objective: Dictionary in ContentRegistry.get_story("ch1")["objectives"]:
		if objective["id"] == objective_id:
			return objective["text"]
	return ""


func _presenter() -> MilestonePresenter:
	return _main.get_node("MilestonePresenter")
