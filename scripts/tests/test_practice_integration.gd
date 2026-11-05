extends TestCase
## Approval flags below are an isolated test fixture, never a content approval.
const CASE_ID: String = "cp_001"
const PATIENT: String = "pt_cp001_jordan_vale"
var _original: Dictionary
var _main: Main

func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	if not _original.is_empty():
		ContinuingPractice._definitions[CASE_ID] = _original
	ContinuingPractice.reset_state()
	ContentRegistry.load_all(ContentRegistry.DATA_DIR)
	PatientManager.reset_state()
	super.after_each()

func test_real_five_encounter_chart_loop_across_saved_endings_and_profiles() -> void:
	_original = ContinuingPractice.get_definition(CASE_ID)
	var fixture: Dictionary = _original.duplicate(true)
	fixture["clinical_review_status"] = "APPROVED"
	fixture["patient"]["clinical_review_status"] = "APPROVED"
	for encounter: Dictionary in fixture["encounters"]:
		encounter["clinical_review_status"] = "APPROVED"
		encounter["dialogue"]["clinical_review_status"] = "APPROVED"
	ContinuingPractice._definitions[CASE_ID] = fixture
	check(ContentRegistry.register_practice_patient(fixture), "test-only reviewed definition uses standard schema")
	var endings: Array[String] = ["ch5_ending_review", "ch5_ending_restricted", "ch5_ending_inquiry"]
	var interests: Array[String] = ["none", "community", "academic"]
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	var director: ChapterDirector = _main.get_node("ChapterDirector")
	for variant: int in 3:
		SaveManager.reset_all()
		check(not ContinuingPractice.accept_case(CASE_ID), "real provider blocks acceptance before campaign completion")
		var profile: Dictionary = ProtagonistProfile.get_profile()
		profile["professional_interest"] = interests[variant]
		profile["name"] = "Dr Test %d" % variant
		check(ProtagonistProfile.apply_draft(profile), "apply distinct optional background")
		director.load_save_data({"current": "ch5", "chapters": {"ch5": {"flags": [StoryLogic.CHAPTER_COMPLETE_FLAG, endings[variant]]}}})
		check(director.has_flag(endings[variant]), "real saved ending flag retained")
		check(ContinuingPractice.accept_case(CASE_ID), "all three completed endings admit the same optional case")
		check_eq(PatientManager.get_notes(PATIENT).size(), 0, "continuity does not invent a previous chart encounter")
		for encounter: int in range(1, 6):
			check(DialogueManager.start_dialogue(PATIENT), "real encounter dialogue opens")
			var choices: Array[Dictionary] = DialogueManager.get_choices()
			var steps: int = 0
			while not choices.is_empty() and steps < 10:
				DialogueManager.select_choice(choices[0]["id"])
				choices = DialogueManager.get_choices()
				steps += 1
			check(DialogueManager.is_interview_complete(PATIENT), "authored terminal state reached")
			DialogueManager.end_dialogue()
			var case: PracticeCase = ContinuingPractice.get_case(CASE_ID)
			check(not case.finish_encounter(), "real signed chart note still required")
			check(not ContinuingPractice.can_close_shift(), "unfinished assessment prevents sign-out")
			var note: String = PatientManager.save_note(PATIENT, [] as Array[String], [] as Array[String], "Test encounter %d" % encounter)
			check(not note.is_empty(), "real patient chart signed")
			check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save between each actual interview and completion")
			check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "restore all providers through JSON")
			case = ContinuingPractice.get_case(CASE_ID)
			check(case.finish_encounter(), "restored real transcript and note references complete encounter")
		check_eq(ContinuingPractice.get_case(CASE_ID).to_save_data()["status"], "followup_cycle_complete", "authored arc completes without discharging patient")
		check_eq(PatientManager.get_notes(PATIENT).size(), 5, "five chart-owned signed notes")
		check_eq(ProtagonistProfile.get_profile()["professional_interest"], interests[variant], "case progression preserves optional background")
