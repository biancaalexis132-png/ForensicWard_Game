extends TestCase
## F3 anomaly model: data/anomalies.json, the AnomalyLedger, the evidence
## ladder and the rule that keeps clinical and supernatural events apart
## (F0 audit section 7). With the flag off, Chapter 1 plays exactly as before;
## with it on, the ledger records episodes and changes nothing else.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const FIXTURE_DATA_DIR: String = "user://test_anomaly"
const ELIAS: String = "pt_elias_ward"
const INTERCOM: String = "anom_ch1_after_hours_intercom"
const CREDENTIAL: String = "anom_ch1_inactive_credential"
const UNEASE: String = "anom_ch1_w0b_unease"
## Signals the ledger must never hear: clinical work, dialogue, staff
## relationships and the physician's strain (Psychosomatic Bleed).
const CLINICAL_SIGNALS: Array[String] = ["clinical_action_committed", "patient_record_opened", "patient_state_changed",
		"observation_recorded", "patient_note_saved", "patient_location_changed", "clinical_review_flagged",
		"patient_admitted", "medication_ordered", "medication_discontinued", "patient_state_updated",
		"clinical_alert_raised", "lab_results_ready", "dialogue_started", "dialogue_line_added", "dialogue_ended",
		"rapport_changed", "trust_changed", "access_granted", "objectivity_changed", "bleed_stage_changed"]

var _main: Node3D = null
var _observed: Array[String] = []
var _thresholds: Array[String] = []


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	_observed.clear()
	_thresholds.clear()
	EventBus.anomaly_episode_observed.connect(_record_episode)
	EventBus.anomaly_threshold_changed.connect(_record_threshold)


func after_each() -> void:
	EventBus.anomaly_episode_observed.disconnect(_record_episode)
	EventBus.anomaly_threshold_changed.disconnect(_record_threshold)
	if is_instance_valid(_main):
		_main.free()
	ContentRegistry.load_all(ContentRegistry.DATA_DIR)
	_remove_dir(FIXTURE_DATA_DIR)
	super.after_each()


# --- Shipped content and the flag ------------------------------------------------------

func test_shipped_episodes_are_valid_and_capped() -> void:
	check(ContentRegistry.is_valid, "anomalies.json validates: %s" % str(ContentRegistry.errors))
	var ids: Array[String] = []
	for episode: Dictionary in ContentRegistry.get_anomaly_episodes("ch1"):
		ids.append(episode["id"])
	ids.sort()
	check_eq(ids, [INTERCOM, CREDENTIAL, UNEASE] as Array[String], "three Chapter 1 episodes")
	check_eq(ContentRegistry.get_anomaly_cap("ch1"), "reported", "Chapter 1 is capped at reported")
	check_eq(ProjectSettings.get_setting(AnomalyLedger.ENABLED_SETTING, true), false, "the flag ships off")
	check(not _ledger().enabled, "the ledger is off")
	check_eq(ContentRegistry.known_exceptions.size(), 2, "two known exceptions reported")
	check_contains(ContentRegistry.known_exceptions, "[patients/PT-001.json] clue_gates", "PT-001 named")
	check_contains(ContentRegistry.known_exceptions, "[patients/PT-002.json] clue_gates", "PT-002 named")


func test_flag_off_records_nothing() -> void:
	_play_chapter1_night()
	check_eq(_ledger().to_save_data(), {"observed": {}}, "nothing observed")
	check_eq(_ledger().get_level(), "none", "level stays none")
	check(_observed.is_empty() and _thresholds.is_empty(), "no anomaly signals")


## The ledger, on or off, changes nothing but its own record: the same run
## with the ledger enabled, disabled and removed gives the same game state.
func test_ledger_changes_nothing_but_its_record() -> void:
	var runs: Array[String] = []
	for mode: String in ["enabled", "disabled", "removed"]:
		SaveManager.reset_all()
		if mode == "removed":
			_ledger().free()
		else:
			_ledger().enabled = mode == "enabled"
		_play_chapter1_night()
		var state: Dictionary = SaveManager.capture_state()
		check_eq(state.has("anomaly"), mode != "removed", "%s: anomaly section present" % mode)
		state.erase("anomaly")
		runs.append(JSON.stringify(state, "", true))
	check_eq(runs[0], runs[2], "enabled ledger leaves the game state unchanged")
	check_eq(runs[1], runs[2], "disabled ledger leaves the game state unchanged")
	check_eq(_observed.size(), 3, "only the enabled run observed episodes")


# --- Flag on ---------------------------------------------------------------------------

func test_episodes_fire_once_and_chapter1_stays_reported() -> void:
	_ledger().enabled = true
	EvidenceManager.acquire_clue("clue_access", "test")
	check(_ledger().has_observed(CREDENTIAL) and _ledger().has_observed(UNEASE), "door log episodes observed")
	check_eq(_ledger().get_level(), "reported", "an access-log reading is capped at reported in Chapter 1")
	EvidenceManager.add_verification("clue_access", "test")
	TimeManager.jump_to_shift(1, "night")
	TimeManager.advance(15, "test")
	check(_ledger().has_observed(INTERCOM), "intercom episode observed after the beat")
	check_eq(_observed.size(), 3, "each episode fires once")
	check_eq(_thresholds, ["reported"] as Array[String], "one threshold change, to reported")
	_ledger().evaluate()
	TimeManager.advance(60, "test")
	check_eq(_observed.size(), 3, "re-evaluating fires nothing new")


func test_save_and_load_restore_without_refiring() -> void:
	_ledger().enabled = true
	_play_chapter1_night()
	check_eq(_ledger().get_observed_ids().size(), 3, "three observed before saving")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check(_ledger().get_observed_ids().is_empty(), "reset clears the record")
	check_eq(_ledger().get_level(), "none", "reset clears the level")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check_eq(_ledger().get_observed_ids(), [INTERCOM, CREDENTIAL, UNEASE] as Array[String], "record restored")
	check_eq(_ledger().get_level(), "reported", "level recomputed on load")
	check_eq(_observed.size(), 3, "loading fires no episode")
	_ledger().evaluate()
	check_eq(_observed.size(), 3, "evaluating after load fires no episode")
	SaveManager.delete_save(TEST_SAVE_SLOT)


# --- Separation ------------------------------------------------------------------------

func test_ledger_never_listens_to_clinical_signals() -> void:
	var ledger: AnomalyLedger = _ledger()
	for signal_name: String in CLINICAL_SIGNALS:
		check(EventBus.has_signal(signal_name), "EventBus has %s" % signal_name)
		for connection: Dictionary in EventBus.get_signal_connection_list(signal_name):
			check((connection["callable"] as Callable).get_object() != ledger, "ledger is not connected to %s" % signal_name)


func test_clinical_events_move_nothing() -> void:
	var ledger: AnomalyLedger = _ledger()
	ledger.enabled = true
	EventBus.clinical_action_committed.emit(ELIAS, "act_test", "evt_test")
	EventBus.patient_record_opened.emit(ELIAS, "evt_test")
	EventBus.observation_recorded.emit(ELIAS, "obs_mutism")
	EventBus.patient_note_saved.emit(ELIAS, "note_test")
	EventBus.patient_state_changed.emit(ELIAS, "symptoms.agitation", 9)
	EventBus.clinical_alert_raised.emit(ELIAS, "alert_test", "high")
	EventBus.dialogue_started.emit(ELIAS)
	EventBus.dialogue_line_added.emit(ELIAS, "patient", "It was in the wall.")
	EventBus.dialogue_ended.emit(ELIAS)
	EventBus.rapport_changed.emit(ELIAS, 90.0)
	EventBus.trust_changed.emit("staff_bennett", "trust", 100.0)
	EventBus.bleed_stage_changed.emit(3)
	check(ledger.get_observed_ids().is_empty(), "no episode from clinical, dialogue or trust events")
	check_eq(ledger.get_level(), "none", "level stays none")


## Psychosomatic Bleed is presentation only: the physician's strain never
## fires an episode or moves the ladder.
func test_objectivity_never_reveals_the_anomaly() -> void:
	var ledger: AnomalyLedger = _ledger()
	ledger.enabled = true
	for value: float in [100.0, 75.0, 50.0, 25.0, 10.0, 0.0]:
		GameState.set_objectivity(value)
	check_eq(GameState.objectivity, 0.0, "objectivity reached zero")
	check(ledger.get_observed_ids().is_empty(), "no episode from objectivity")
	check_eq(ledger.get_level(), "none", "level stays none")
	check(_observed.is_empty() and _thresholds.is_empty(), "no anomaly signals")


func test_episodes_never_change_clinical_state() -> void:
	var ledger: AnomalyLedger = _ledger()
	ledger.enabled = true
	var patients_before: String = JSON.stringify(PatientManager.to_save_data(), "", true)
	var objectivity_before: float = GameState.objectivity
	# The intercom episode is observed through the flag alone, so the story
	# beat's own chart entry does not run.
	_director().set_flag("intercom_heard")
	ledger.evaluate()
	check(ledger.has_observed(INTERCOM), "intercom episode observed")
	check_eq(JSON.stringify(PatientManager.to_save_data(), "", true), patients_before, "patients unchanged")
	check_eq(GameState.objectivity, objectivity_before, "objectivity unchanged")


func test_testimony_is_recorded_but_never_counts() -> void:
	var docs: Dictionary = _documents()
	var clue: Dictionary = docs["clues"]["data"]["clues"][0].duplicate(true)
	clue["id"] = "clue_test_patient_report"
	clue["source_class"] = "patient_report"
	docs["clues"]["data"]["clues"].append(clue)
	docs["anomalies"]["data"]["episodes"][0]["readings"] = ["clue_test_patient_report"]
	docs["anomalies"]["data"]["episodes"][0]["when"] = {"flag": "test_never_set"}
	_write_data_dir(docs)
	check(ContentRegistry.load_all(FIXTURE_DATA_DIR), "fixture data validates: %s" % str(ContentRegistry.errors))
	_ledger().enabled = true
	check(EvidenceManager.acquire_clue("clue_test_patient_report", "test"), "testimony clue recorded")
	EvidenceManager.add_verification("clue_test_patient_report", "test")
	check(EvidenceManager.has_clue("clue_test_patient_report"), "the clue is in the evidence board")
	check_eq(_ledger().get_level(), "none", "testimony does not move the ladder")


func test_ladder_steps() -> void:
	var doc: Dictionary = {"source_class": "document", "verified": false}
	var log_verified: Dictionary = {"source_class": "access_log", "verified": true}
	var instrument: Dictionary = {"source_class": "instrument", "verified": true}
	var testimony: Dictionary = {"source_class": "patient_report", "verified": true}
	var staff: Dictionary = {"source_class": "staff_testimony", "verified": true}
	check_eq(AnomalyLedger.compute_level(0, [], "accepted"), "none", "nothing gives none")
	check_eq(AnomalyLedger.compute_level(0, [testimony, staff], "accepted"), "none", "testimony alone gives none")
	check_eq(AnomalyLedger.compute_level(1, [], "accepted"), "reported", "an episode gives reported")
	check_eq(AnomalyLedger.compute_level(0, [doc], "accepted"), "inconsistent_records", "a document")
	check_eq(AnomalyLedger.compute_level(0, [instrument], "accepted"), "reported", "an instrument needs records first")
	check_eq(AnomalyLedger.compute_level(0, [doc, instrument], "accepted"), "instrumented", "records and an instrument")
	check_eq(AnomalyLedger.compute_level(0, [log_verified, instrument], "accepted"), "corroborated", "two verified classes")
	check_eq(AnomalyLedger.compute_level(0, [doc, instrument, testimony], "accepted"), "instrumented",
			"verified testimony is not a second class")
	check_eq(AnomalyLedger.compute_level(3, [log_verified, instrument], "reported"), "reported", "the cap holds")
	check_eq(AnomalyLedger.compute_level(3, [log_verified, instrument], "corroborated"), "corroborated", "never accepted from evidence")


# --- Validator -------------------------------------------------------------------------

func test_conditions_may_not_name_clinical_work() -> void:
	var docs: Dictionary = _documents()
	var episodes: Array = docs["anomalies"]["data"]["episodes"]
	episodes[0]["when"] = {"talked_to": "staff_bennett"}
	episodes[1]["when"] = {"any": [{"shift": "night"}, {"note_saved": ELIAS}]}
	episodes[2]["when"] = {"flag": "obs_mutism"}
	episodes[2]["manifestations"] = [{"device_log": ELIAS}]
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "episodes[0].when: an anomaly condition may not use 'talked_to'", "talked_to refused")
	check_contains(report["errors"], "episodes[1].when.any[1]: an anomaly condition may not use 'note_saved'", "nested note_saved refused")
	check_contains(report["errors"], "episodes[1]: names the clinical id 'pt_elias_ward'", "patient id in a condition")
	check_contains(report["errors"], "episodes[2]: names the clinical id 'obs_mutism'", "observation used as a flag")


func test_episode_rules_are_validated() -> void:
	var docs: Dictionary = _documents()
	var data: Dictionary = docs["anomalies"]["data"]
	var clue: Dictionary = docs["clues"]["data"]["clues"][0].duplicate(true)
	clue["id"] = "clue_test_staff_story"
	clue["source_class"] = "staff_testimony"
	docs["clues"]["data"]["clues"].append(clue)
	for item: Dictionary in docs["clues"]["data"]["clues"]:
		if item["id"] == "clue_access":
			item.erase("source_class")
	data["chapter_caps"]["ch1"] = "instrumented"
	data["episodes"][0]["when"] = {"clue_acquired": "clue_test_staff_story"}
	data["episodes"][0]["manifestations"] = [{"spawn_apparition": "corridor"}]
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "chapter_caps.ch1: 'instrumented' is too high", "Chapter 1 cap")
	check_contains(report["errors"], "'clue_test_staff_story' is testimony (staff_testimony)", "testimony cannot cause an episode")
	check_contains(report["errors"], "episodes[0].manifestations[0]: a manifestation is an object with one key", "closed manifestations")
	check_contains(report["errors"], "clue 'clue_access' needs a source_class", "readings need a source class")


func test_clinical_files_never_name_the_anomaly() -> void:
	var docs: Dictionary = _documents()
	var patient: Dictionary = docs["patients"]["data"]["patients"][0]
	patient["record_discrepancies"] = [INTERCOM, "clue_access"]
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "names the anomaly id or reading '%s'" % INTERCOM, "episode id in a patient file")
	check_contains(report["errors"], "names the anomaly id or reading 'clue_access'", "reading in a patient file")


func test_symptom_gates_never_unlock_readings() -> void:
	var report: Dictionary = ContentValidator.separation_exceptions(ContentRegistry.DATA_DIR, [])
	check_eq(report["errors"].size(), 0, "no errors with no readings")
	check_eq(report["notices"].size(), 2, "one notice per pharmacology gate")
	var gated: String = _first_gated_clue()
	check(not gated.is_empty(), "a pharmacology gate exists")
	report = ContentValidator.separation_exceptions(ContentRegistry.DATA_DIR, [gated])
	check_contains(report["errors"], "'%s' is an anomaly reading; a symptom level can never unlock anomaly evidence" % gated,
			"a gated clue may not be a reading")


# --- Helpers ---------------------------------------------------------------------------

## Chapter 1 to the night intercom: read the W0-B door log on the day shift,
## then sign in for the night and wait for the after-hours call.
func _play_chapter1_night() -> void:
	EvidenceManager.acquire_clue("clue_access", "terminal")
	TimeManager.jump_to_shift(1, "night")
	TimeManager.advance(15, "test")


func _ledger() -> AnomalyLedger:
	return runner.get_tree().get_first_node_in_group(AnomalyLedger.GROUP) as AnomalyLedger


func _director() -> Node:
	return runner.get_tree().get_first_node_in_group(ChapterDirector.GROUP)


func _record_episode(episode_id: String) -> void:
	_observed.append(episode_id)


func _record_threshold(level: String, _previous: String) -> void:
	_thresholds.append(level)


func _documents() -> Dictionary:
	var problems: Array[String] = []
	return ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)


func _first_gated_clue() -> String:
	for file_name: String in DirAccess.get_files_at("res://data/patients"):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/patients".path_join(file_name)))
		if data is Dictionary and not data.get("clue_gates", []).is_empty():
			return str(data["clue_gates"][0].get("clue_id", ""))
	return ""


func _write_data_dir(docs: Dictionary) -> void:
	_remove_dir(FIXTURE_DATA_DIR)
	DirAccess.make_dir_recursive_absolute(FIXTURE_DATA_DIR)
	for key: String in docs:
		var file: FileAccess = FileAccess.open(FIXTURE_DATA_DIR.path_join(docs[key]["file"]), FileAccess.WRITE)
		file.store_string(JSON.stringify(docs[key]["data"], "\t"))
		file.close()


func _remove_dir(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file_name: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	DirAccess.remove_absolute(directory)
