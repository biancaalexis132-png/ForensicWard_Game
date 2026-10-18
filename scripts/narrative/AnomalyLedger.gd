class_name AnomalyLedger
extends Node
## AnomalyLedger: records which anomaly episodes (data/anomalies.json) have
## been observed and computes the evidence ladder from what was found.
##
## The separation rule (F0 audit section 7): the anomaly is a property of
## places, instruments and time. The ledger only listens to story, evidence,
## time, zone and world-state events; it never subscribes to clinical,
## dialogue, trust or objectivity signals, never reads patient state or the
## physician's strain (Psychosomatic Bleed is presentation only), and never
## writes anything but its own record. Episodes do not perform anything: the
## story beats they mirror already do.
##
## Ladder (ContentSchemas.ANOMALY_LEVELS), each step needing the one before:
##   reported              an episode was observed or a counting reading found
##   inconsistent_records  a counting document or access-log reading
##   instrumented          a counting instrument reading
##   corroborated          verified readings from two independent source classes
##   accepted              not reachable from evidence alone yet
## Testimony (patient_report, staff_testimony) never counts. The level is
## capped by the current chapter (anomalies.json chapter_caps).
##
## Off unless Project Settings forensic_ward/narrative/anomaly_enabled is true:
## while off, nothing is observed and the level stays "none".
## Saved as the "anomaly" provider: {"observed": {episode_id: {chapter, at_minutes}}}.
## Lives in Main (group "anomaly_ledger"), beside ChapterDirector.

const PROVIDER_KEY: String = "anomaly"
const GROUP: String = "anomaly_ledger"
const ENABLED_SETTING: String = "forensic_ward/narrative/anomaly_enabled"
## The only events that can move the ledger.
const LISTENED_SIGNALS: Array[String] = ["story_beat_fired", "clue_acquired", "hypothesis_updated", "shift_started",
		"environment_state_changed", "chapter_started"]

var enabled: bool = false

var _observed: Dictionary = {}  ## episode id -> {chapter, at_minutes}
var _level: String = "none"
var _zone_id: String = ""
var _evaluating: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	enabled = bool(ProjectSettings.get_setting(ENABLED_SETTING, false))
	_zone_id = str(ContentRegistry.get_world().get("start_zone", "")) if ContentRegistry.is_valid else ""
	SaveManager.register_provider(PROVIDER_KEY, self)
	for signal_name: String in LISTENED_SIGNALS:
		var argc: int = 0
		for info: Dictionary in EventBus.get_signal_list():
			if info["name"] == signal_name:
				argc = info["args"].size()
		EventBus.connect(signal_name, evaluate.unbind(argc))
	EventBus.zone_changed.connect(_on_zone_changed)
	# Evidence and chapter state load after this provider; recompute quietly once all are in.
	EventBus.game_loaded.connect(func(_slot: int) -> void: _update_level(false))


func _exit_tree() -> void:
	SaveManager.unregister_provider(PROVIDER_KEY)


# --- Queries --------------------------------------------------------------------

func get_level() -> String:
	return _level


func has_observed(episode_id: String) -> bool:
	return _observed.has(episode_id)


func get_observed_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_observed.keys())
	ids.sort()
	return ids


## The ladder level for `observed_count` episodes and the acquired readings
## ([{source_class, verified}]), capped at `cap`. Pure, for tests and tools.
static func compute_level(observed_count: int, readings: Array[Dictionary], cap: String) -> String:
	var levels: Array[String] = ContentSchemas.ANOMALY_LEVELS
	var classes: Dictionary = {}
	var verified_classes: Dictionary = {}
	for reading: Dictionary in readings:
		var source_class: String = reading["source_class"]
		if source_class in ContentSchemas.TESTIMONY_SOURCE_CLASSES:
			continue
		classes[source_class] = true
		if reading.get("verified", false):
			verified_classes[source_class] = true
	var index: int = 0
	if observed_count > 0 or not classes.is_empty():
		index = 1
	if index == 1 and (classes.has("document") or classes.has("access_log")):
		index = 2
	if index == 2 and classes.has("instrument"):
		index = 3
	if index == 3 and verified_classes.size() >= 2:
		index = 4
	return levels[mini(index, maxi(levels.find(cap), 0))]


# --- Evaluation -----------------------------------------------------------------

## Records episodes of the current chapter whose condition now holds, then
## recomputes the ladder. Does nothing while the flag is off.
func evaluate() -> void:
	if not enabled or _evaluating or not ContentRegistry.is_valid:
		return
	_evaluating = true
	var context: Dictionary = _context()
	var chapter_id: String = _chapter_id()
	for episode: Dictionary in ContentRegistry.get_anomaly_episodes(chapter_id):
		if _observed.has(episode["id"]) or not StoryLogic.evaluate(episode["when"], context):
			continue
		_observed[episode["id"]] = {"chapter": chapter_id, "at_minutes": TimeManager.total_minutes}
		EventBus.anomaly_episode_observed.emit(episode["id"])
	_evaluating = false
	_update_level(true)


func _update_level(announce: bool) -> void:
	var level: String = "none"
	if enabled:
		level = compute_level(_observed.size(), _acquired_readings(), ContentRegistry.get_anomaly_cap(_chapter_id()))
	if level == _level:
		return
	var previous: String = _level
	_level = level
	if announce:
		EventBus.anomaly_threshold_changed.emit(level, previous)


func _acquired_readings() -> Array[Dictionary]:
	var readings: Array[Dictionary] = []
	var seen: Dictionary = {}
	for episode: Dictionary in ContentRegistry.get_anomaly_episodes():
		for clue_id: String in episode["readings"]:
			if seen.has(clue_id) or not EvidenceManager.has_clue(clue_id):
				continue
			seen[clue_id] = true
			readings.append({"source_class": str(ContentRegistry.get_clue(clue_id).get("source_class", "")),
					"verified": not EvidenceManager.get_verifications(clue_id).is_empty()})
	return readings


func _context() -> Dictionary:
	var director: Node = get_tree().get_first_node_in_group(ChapterDirector.GROUP) if is_inside_tree() else null
	var context: Dictionary = director.get_story_context() if director != null else {"flags": [], "chapters": {}}
	context["zone"] = _zone_id
	return context


func _chapter_id() -> String:
	var director: Node = get_tree().get_first_node_in_group(ChapterDirector.GROUP) if is_inside_tree() else null
	return director.get_chapter_id() if director != null else ContentRegistry.get_start_chapter_id()


func _on_zone_changed(zone_id: String, _previous_zone_id: String) -> void:
	_zone_id = zone_id
	evaluate()


# --- Save provider ("anomaly") ------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"observed": _observed.duplicate(true)}


## Restores the record without announcing anything: loading never fires an
## episode. The level is recomputed on game_loaded, once evidence is restored.
func load_save_data(data: Dictionary) -> void:
	_observed = data.get("observed", {}).duplicate(true)


func reset_state() -> void:
	_observed.clear()
	_level = "none"
