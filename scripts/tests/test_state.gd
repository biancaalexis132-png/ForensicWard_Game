extends TestCase
## Manager state: event dedupe, rule governance, determinism, location
## guard, time, evidence, trust, settings and save integrity.

const PATIENT: String = "pt_elias_ward"
const CATATONIA_EVENT: Dictionary = {
	"event_id": "evt_day1_assess_catatonia", "type": "clinical_action", "patient_id": PATIENT,
	"action_id": "evaluate_catatonia", "at_minutes": 522,
	"payload": {"finding_ids": ["obs_mutism", "obs_posturing"]},
}


func test_opening_record_twice_does_not_duplicate() -> void:
	check(PatientManager.open_record(PATIENT), "first open logs an event")
	check(not PatientManager.open_record(PATIENT), "second open is deduped")
	check_eq(PatientManager.get_state(PATIENT)["audit"].size(), 1, "one audit entry")


func test_clinical_action_is_deduped() -> void:
	check(not PatientManager.commit_clinical_action(CATATONIA_EVENT).is_empty(), "first commit evaluates")
	check(PatientManager.commit_clinical_action(CATATONIA_EVENT).is_empty(), "replay is ignored")


func test_pending_rule_applies_only_non_medical_effects_in_prototype() -> void:
	var result: Dictionary = PatientManager.commit_clinical_action(CATATONIA_EVENT)
	check_eq(result["rule_ids"], ["clinical_rule_catatonia_escalation_v1"], "rule matched")
	check_eq(PatientManager.get_state(PATIENT)["assessment"].get("started"), true, "assessment marked started")
	check_contains(result["review_flags"], "Unreviewed rule applied in prototype mode", "flagged for review")


func test_pending_rule_blocked_in_validated_mode() -> void:
	ClinicalRules.build_mode = ClinicalRules.MODE_VALIDATED
	var result: Dictionary = PatientManager.commit_clinical_action(CATATONIA_EVENT)
	check(result["effects"].is_empty(), "no effects from a pending rule")
	check(not PatientManager.get_state(PATIENT)["assessment"].has("started"), "state untouched")
	check_contains(result["review_flags"], "not applied in validated build mode", "flag explains why")


func test_rule_needs_its_findings() -> void:
	var event: Dictionary = CATATONIA_EVENT.duplicate(true)
	event["payload"]["finding_ids"] = ["obs_mutism"]
	var result: Dictionary = PatientManager.commit_clinical_action(event)
	check(result["rule_ids"].is_empty(), "rule does not fire without posturing finding")


func test_same_inputs_give_identical_state() -> void:
	var first: String = _run_scripted_sequence()
	SaveManager.reset_all()
	var second: String = _run_scripted_sequence()
	check_eq(second, first, "replaying the same actions from a fresh run gives the same state")


func test_location_guard_blocks_unsafe_automatic_transfer() -> void:
	PatientManager.set_flag(PATIENT, "medically_unstable", true)
	check(not PatientManager.set_location(PATIENT, "ward_zero", "story_transfer", true), "auto transfer blocked")
	check_eq(PatientManager.get_location(PATIENT), "clinical_unit", "still on the clinical unit")
	check(PatientManager.set_location(PATIENT, "medical_unit", "escalation"), "clinician escalation allowed")
	check_eq(PatientManager.get_location(PATIENT), "medical_unit", "single location after escalation")


func test_scheduled_events_fire_in_order_and_shift_changes() -> void:
	var fired: Array[String] = []
	var on_fired: Callable = func(event_id: String, _payload: Dictionary) -> void: fired.append(event_id)
	var shifts: Array[String] = []
	var on_shift: Callable = func(_day: int, shift: String) -> void: shifts.append(shift)
	EventBus.scheduled_event_fired.connect(on_fired)
	EventBus.shift_changed.connect(on_shift)
	TimeManager.schedule(TimeManager.total_minutes + 30, "evt_b")
	TimeManager.schedule(TimeManager.total_minutes + 10, "evt_a")
	check(not TimeManager.schedule(TimeManager.total_minutes + 50, "evt_a"), "duplicate id rejected")
	TimeManager.advance(12 * 60, "test")
	EventBus.scheduled_event_fired.disconnect(on_fired)
	EventBus.shift_changed.disconnect(on_shift)
	check_eq(fired, ["evt_a", "evt_b"] as Array[String], "fired in time order")
	check_eq(shifts, ["night"] as Array[String], "08:00 + 12h crosses into the night shift")
	check_eq(TimeManager.get_clock_string(), "Day 1  20:00", "clock")


func test_clue_links_persist_through_save_and_load() -> void:
	for clue_id: String in ["clue_transfer", "clue_roster"]:
		EvidenceManager.acquire_clue(clue_id, "test")
		EvidenceManager.set_pinned(clue_id, true)
	check(EvidenceManager.link_clues("clue_transfer", "clue_roster"), "link")
	check(EvidenceManager.unlink_clues("clue_roster", "clue_transfer"), "unlink (order-independent)")
	check(EvidenceManager.link_clues("clue_roster", "clue_transfer"), "relink")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check(not EvidenceManager.are_linked("clue_transfer", "clue_roster"), "reset clears links")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check(EvidenceManager.are_linked("clue_transfer", "clue_roster"), "link restored")
	check(EvidenceManager.is_hypothesis_supported_by_board("hyp_identity_reuse"), "authored hypothesis now arguable")


func test_false_hypothesis_does_not_break_anything() -> void:
	EvidenceManager.acquire_clue("clue_access", "test")
	var clues: Array[String] = ["clue_access"]
	check(EvidenceManager.register_hypothesis("hyp_player_wrong", "The nurse forged the log", clues), "register")
	check(EvidenceManager.set_hypothesis_status("hyp_player_wrong", "refuted"), "refute")
	check_eq(EvidenceManager.get_hypothesis("hyp_identity_reuse")["status"], "unresolved", "authored hypothesis untouched")
	check_eq(PatientManager.get_location(PATIENT), "clinical_unit", "patient chart untouched")
	check(EvidenceManager.acquire_clue("clue_transfer", "test"), "investigation can continue")


func test_trust_is_bounded_and_multi_axis() -> void:
	TrustManager.adjust("staff_bennett", "trust", 500.0, "test")
	check_eq(TrustManager.get_value("staff_bennett", "trust"), 100.0, "clamped to 100")
	check_eq(TrustManager.get_value("staff_bennett", "suspicion"), 0.0, "other axes independent")
	check(not TrustManager.has_access("access_records_archive"), "no archive access yet")
	check(TrustManager.grant_access("access_records_archive", "staff_bennett"), "grant")
	check(TrustManager.has_access("access_records_archive"), "has access")


func test_accessibility_settings_are_independent() -> void:
	var before: Dictionary = {}
	for key: String in ["visual_effects", "subtitles", "chromatic_distortion"]:
		before[key] = Settings.get_value(key)
	Settings.set_value("flash_effects", false)
	for key: String in before:
		check_eq(Settings.get_value(key), before[key], "%s unaffected by flash toggle" % key)
	Settings.set_value("flash_effects", true)


func test_tampered_save_is_rejected() -> void:
	EvidenceManager.acquire_clue("clue_roster", "test")
	SaveManager.save_game(TEST_SAVE_SLOT)
	var path: String = SaveManager.get_slot_path(TEST_SAVE_SLOT)
	var text: String = FileAccess.get_file_as_string(path).replace("clue_roster", "clue_access")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	# Expected: SaveManager logs a "checksum mismatch" warning here.
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), ERR_FILE_CORRUPT, "checksum catches edits")


func _run_scripted_sequence() -> String:
	PatientManager.open_record(PATIENT)
	PatientManager.record_observation(PATIENT, "obs_mutism", "nurse_bennett")
	TimeManager.advance(42, "examination")
	PatientManager.commit_clinical_action(CATATONIA_EVENT)
	DialogueManager.start_dialogue(PATIENT)
	DialogueManager.submit_free_text("Is he eating?")
	DialogueManager.end_dialogue()
	EvidenceManager.acquire_clue("clue_transfer", "terminal:test")
	TrustManager.adjust("staff_bennett", "respect", 5.0, "test")
	var rng_value: int = SaveManager.make_rng("test_stream").randi()
	return JSON.stringify(SaveManager.capture_state(), "", true) + str(rng_value)
