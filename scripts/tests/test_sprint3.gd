extends TestCase
## Sprint 3: chapter objectives and beats (ChapterDirector), the evidence
## board, shift sign-out with handover trust, the after-hours W0-B beat,
## staff lines, HUD objective/subtitles and audio zones, all through the
## real Main scene.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const ELIAS: String = "pt_elias_ward"
const BENNETT: String = "staff_bennett"

var _main: Node3D = null


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	super.after_each()
	if is_instance_valid(_main):
		_main.free()


# --- Objectives and beats ---------------------------------------------------------

func test_first_objective_is_shown_on_the_hud() -> void:
	await runner.get_tree().process_frame  # The director announces its first objective deferred.
	check_eq(_director().get_current_objective().get("id", ""), "obj_meet_bennett", "starts with the charge nurse")
	check("charge nurse" in _hud().objective_text, "HUD shows the objective, got '%s'" % _hud().objective_text)


func test_talking_to_bennett_fires_handover_and_advances_objective() -> void:
	var beats: Array[String] = []
	var on_beat: Callable = func(id: String) -> void: beats.append(id)
	EventBus.story_beat_fired.connect(on_beat)
	_talk(BENNETT)
	EventBus.story_beat_fired.disconnect(on_beat)
	check_eq(beats, ["beat_b2_handover"] as Array[String], "handover beat fired once")
	check_eq(_director().get_current_objective()["id"], "obj_see_elias", "next: see Elias")
	_info().close()
	_talk(BENNETT)
	check_eq(beats.size(), 1, "talking again does not replay the beat")


func test_objectives_follow_the_clinical_loop() -> void:
	_talk(BENNETT)
	_info().close()
	_interview_elias(["ask_intake", "assess_motor"])
	check_eq(_director().get_current_objective()["id"], "obj_document", "after the interview: document")
	_save_note()
	check_eq(_director().get_current_objective()["id"], "obj_act", "after the note: act")
	PatientManager.perform_action(ELIAS, "evaluate_catatonia", ["obs_mutism", "obs_posturing"] as Array[String])
	check_eq(_director().get_current_objective()["id"], "obj_compare_records", "then compare records")


# --- Evidence board --------------------------------------------------------------------

func test_tab_opens_board_and_esc_closes_it() -> void:
	_press("journal")
	await runner.get_tree().process_frame
	check(_board().is_open, "Tab opens the evidence board")
	check(not _player().input_enabled, "player frozen")
	_press("pause")
	await runner.get_tree().process_frame
	check(not _board().is_open, "Esc closes it")
	check(not (_main.get_node("PauseMenu") as PauseMenu).is_open, "without opening the pause menu")


func test_board_links_clues_and_supports_hypothesis() -> void:
	EvidenceManager.acquire_clue("clue_transfer", "test")
	EvidenceManager.acquire_clue("clue_roster", "test")
	_board().open()
	check(not _board().argue("hyp_identity_reuse"), "cannot argue before pinning")
	check("not pinned" in _board().get_feedback(), "says what is missing: %s" % _board().get_feedback())
	_board().toggle_pin("clue_transfer")
	_board().toggle_pin("clue_roster")
	check_eq(_board().get_card_ids(), ["clue_roster", "clue_transfer"] as Array[String], "pinned cards on the board")
	check(not _board().argue("hyp_identity_reuse"), "pinned but unlinked is not enough")
	_board().select_card("clue_transfer")
	_board().select_card("clue_roster")
	check(_board().link_selected(), "linked")
	check(_board().argue("hyp_identity_reuse"), "supported once linked")
	check_eq(EvidenceManager.get_hypothesis("hyp_identity_reuse")["status"], "supported", "status recorded")
	check_eq(_director().get_current_objective().get("id", ""), "obj_meet_bennett",
			"earlier objectives still come first (no skipping the patient)")


func test_player_hypothesis_can_be_wrong_without_blocking() -> void:
	EvidenceManager.acquire_clue("clue_transfer", "test")
	_board().open()
	_board().toggle_pin("clue_transfer")
	_board().select_card("clue_transfer")
	var id: String = _board().propose_hypothesis("The transfer summary was simply misfiled")
	check_eq(id, "hyp_player_1", "player hypothesis registered")
	_board().set_aside(id)
	check_eq(EvidenceManager.get_hypothesis(id)["status"], "refuted", "set aside")
	check_eq(EvidenceManager.get_hypothesis("hyp_identity_reuse")["status"], "unresolved", "authored hypothesis untouched")


func test_unpinning_removes_links_and_board_state_persists() -> void:
	for clue_id: String in ["clue_transfer", "clue_roster", "clue_access"]:
		EvidenceManager.acquire_clue(clue_id, "test")
		EvidenceManager.set_pinned(clue_id, true)
	EvidenceManager.link_clues("clue_transfer", "clue_roster")
	EvidenceManager.link_clues("clue_roster", "clue_access")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check(EvidenceManager.are_linked("clue_roster", "clue_transfer"), "link restored")
	_board().open()
	_board().toggle_pin("clue_access")
	check(not EvidenceManager.are_linked("clue_roster", "clue_access"), "unpinning removed its link")


# --- Shift sign-out, trust, after-hours beat -------------------------------------------------

func test_documented_handover_builds_bennett_trust_and_starts_night() -> void:
	_interview_elias(["ask_intake"])
	_save_note()
	var trust_before: float = TrustManager.get_value(BENNETT, "trust")
	_use_board()
	check_eq(TrustManager.get_value(BENNETT, "trust") - trust_before, 10.0, "documented handover: +10 trust")
	check_eq(TimeManager.get_shift(), "night", "night shift began")
	check("Handover documented" in _info().get_node("Root/Panel/Margin/VBox/Body").get_parsed_text(), "summary shown")


func test_undocumented_handover_costs_respect_but_never_blocks() -> void:
	var respect_before: float = TrustManager.get_value(BENNETT, "respect")
	_use_board()
	check_eq(TrustManager.get_value(BENNETT, "respect") - respect_before, -5.0, "respect lost")
	check_eq(TimeManager.get_shift(), "night", "night still begins: no soft lock")


func test_after_hours_intercom_logs_disputed_transfer() -> void:
	var lines: Array[String] = []
	var on_event: Callable = func(id: String, _p: Dictionary) -> void: lines.append(id)
	EventBus.narrative_event_fired.connect(on_event)
	_use_board()
	check(not _director().has_fired("beat_b6_intercom"), "intercom waits 15 minutes")
	TimeManager.advance(15, "test")
	EventBus.narrative_event_fired.disconnect(on_event)
	check(_director().has_fired("beat_b6_intercom"), "intercom fired")
	check_contains(lines, "ch1_after_hours_intercom", "audio event sent")
	var audit: Array = PatientManager.get_state(ELIAS)["audit"]
	var logged: Array = audit.filter(func(e: Dictionary) -> bool: return e["type"] == "transfer_request_logged")
	check_eq(logged.size(), 1, "disputed transfer logged on the chart")
	check_eq(logged[0]["by"], "credential:inactive", "under an inactive credential")
	check(PatientManager.get_state(ELIAS)["observations"].is_empty(), "narrative never adds clinical findings")
	check_eq(PatientManager.get_location(ELIAS), "clinical_unit", "and never moves the patient")


func test_trusted_bennett_corroborates_the_door_log() -> void:
	_interview_elias(["ask_intake"])
	_save_note()
	_use_board()  # +10 trust: 15.
	TimeManager.advance(15, "test")
	EvidenceManager.acquire_clue("clue_access", "terminal:W0B_AccessPanel")
	_talk(BENNETT)
	check("inactive for months" in _info_text(), "high-trust line")
	check_eq(EvidenceManager.get_verifications("clue_access").size(), 1, "testimony recorded as corroboration")
	_info().close()
	_talk(BENNETT)
	check_eq(EvidenceManager.get_verifications("clue_access").size(), 1, "not duplicated")


func test_low_trust_bennett_stays_guarded() -> void:
	_use_board()  # Undocumented: trust stays 5.
	TimeManager.advance(15, "test")
	EvidenceManager.acquire_clue("clue_access", "test")
	_talk(BENNETT)
	check("isn't on my board" in _info_text(), "guarded line")
	check(EvidenceManager.get_verifications("clue_access").is_empty(), "no corroboration")


func test_night_sign_out_completes_the_chapter() -> void:
	var completed: Array[String] = []
	var on_done: Callable = func(id: String) -> void: completed.append(id)
	EventBus.chapter_completed.connect(on_done)
	_use_board()
	_use_board()
	EventBus.chapter_completed.disconnect(on_done)
	check_eq(completed, ["ch1"] as Array[String], "chapter completed")
	check(_director().has_flag("chapter_complete"), "flag set")
	check("End of Chapter 1" in _info_text(), "end summary shown")
	check(_director().get_current_objective().is_empty(), "no objectives left")


func test_day_objectives_expire_at_night() -> void:
	_use_board()
	check_eq(_director().get_current_objective()["id"], "obj_w0b", "night objective replaces unfinished day tasks")


func test_pending_beat_survives_save_and_load() -> void:
	_use_board()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save while the intercom is pending")
	SaveManager.reset_all()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	TimeManager.advance(15, "test")
	check(_director().has_fired("beat_b6_intercom"), "pending beat fires after loading")
	var logged: Array = PatientManager.get_state(ELIAS)["audit"].filter(
			func(e: Dictionary) -> bool: return e["type"] == "transfer_request_logged")
	check_eq(logged.size(), 1, "exactly once")


# --- HUD and audio zones ---------------------------------------------------------------------

func test_subtitles_follow_settings() -> void:
	EventBus.subtitle_shown.emit("line", "Intercom", "Transfer team to W-Zero-B.", 2.0)
	check_eq(_hud().subtitle_text, "Intercom: Transfer team to W-Zero-B.", "subtitle text")
	check(_hud()._subtitle.text != "", "shown")
	Settings.set_value("subtitles", false)
	EventBus.subtitle_shown.emit("line", "Intercom", "Again.", 2.0)
	check_eq(_hud()._subtitle.text, "", "hidden when subtitles are off")
	Settings.set_value("subtitles", true)
	EventBus.subtitle_cleared.emit("line")
	check_eq(_hud()._subtitle.text, "", "cleared")


func test_audio_zones_follow_the_floor_plan() -> void:
	var tracker: AudioZoneTracker = _main.get_node("AudioZoneTracker")
	check_eq(tracker.location_at(Vector3(-3.0, 0.0, -10.0)), "nursing_station", "inside the nursing station")
	check_eq(tracker.location_at(Vector3(0.0, 0.0, -5.0)), "corridor", "corridor elsewhere")
	_player().place(Vector3(-3.0, 0.05, -10.0), 0.0)
	tracker.update_now()
	check_eq(tracker.current_location, "nursing_station", "tracks the player")


# --- Content validation -----------------------------------------------------------------------

func test_story_conditions_are_validated() -> void:
	var errors: Array[String] = []
	var refs: Dictionary = {"patients": {ELIAS: 0}, "clues": {"clue_access": 0}, "hypotheses": {}, "staff": {BENNETT: 0}}
	StoryLogic.check_condition({"clue_acquired": "clue_acess"}, "c", refs, errors)
	StoryLogic.check_condition({"talked_too": BENNETT}, "c", refs, errors)
	StoryLogic.check_condition({"all": [{"shift": "evening"}]}, "c", refs, errors)
	StoryLogic.check_action({"teleport": "ward_zero"}, "a", refs, errors)
	check_contains(errors, "unknown clue id 'clue_acess'", "bad reference")
	check_contains(errors, "unknown condition 'talked_too'", "bad condition kind")
	check_contains(errors, "must be \"day\" or \"night\"", "nested condition checked")
	check_contains(errors, "unknown action 'teleport'", "bad action kind")


# --- Helpers ----------------------------------------------------------------------------------

func _talk(staff_id: String) -> void:
	var character: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character(staff_id)
	(character.get_node("Interactable") as Interactable).interact(_player())


func _interview_elias(choices: Array) -> void:
	var elias: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character(ELIAS)
	(elias.get_node("Interactable") as Interactable).interact(_player())
	var interview: InterviewScreen = _main.get_node("InterviewScreen")
	for choice_id: String in choices:
		interview.ask_choice(choice_id)
	interview.close()


func _save_note() -> void:
	var findings: Array[String] = []
	findings.assign(PatientManager.get_state(ELIAS)["observations"].keys())
	var none: Array[String] = []
	PatientManager.save_note(ELIAS, findings, none, "Handover: reduced intake; reassess next shift.")


func _use_board() -> void:
	var board: ImportedInteractable = (_main.get_node("World") as AuthoredWorld).get_interactable("NS_NoticeBoard")
	board.interactable.interact(_player())


func _info_text() -> String:
	return (_info().get_node("Root/Panel/Margin/VBox/Body") as RichTextLabel).get_parsed_text()


func _press(action: String) -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)


func _director() -> ChapterDirector:
	return _main.get_node("ChapterDirector")


func _board() -> EvidenceBoard:
	return _main.get_node("EvidenceBoard")


func _hud() -> HUD:
	return _main.get_node("HUD")


func _info() -> InfoPanel:
	return _main.get_node("InfoPanel")


func _player() -> FirstPersonController:
	return _main.get_node("Player")
