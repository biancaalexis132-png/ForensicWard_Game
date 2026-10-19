extends TestCase
## F2 zones: data/zones.json, ZoneDirector streaming and transitions, door
## state that survives unloading, saves and loads, and save version 3 with
## its migration from version 2. Runs against the real Main scene and the
## Blender-built environments.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const V2_SAVE: String = "res://scripts/tests/fixtures/saves/save_v2_ch1_doors_open.json"
const CLINICAL: String = "zone_clinical_wing"
const SECURITY: String = "zone_security_admin"
const RESEARCH: String = "zone_research_level"
const HISTORIC: String = "zone_historic_sublevel"
const LIFT: String = "conn_restricted_lift"
const HATCH: String = "conn_service_hatch"
## Static memory may grow this much between the first and the tenth lift
## round trip (allocator slack), but not by a level per trip. Measured
## growth headless was about 8 KB; one research level is tens of MB.
const MEMORY_TOLERANCE_BYTES: float = 1024.0 * 1024.0

var _main: Node3D = null
var _notifications: Array[String] = []
var _zone_changes: Array[String] = []


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	_zones().fade_seconds = 0.0
	_notifications.clear()
	_zone_changes.clear()
	EventBus.notification_requested.connect(_record_notification)
	EventBus.zone_changed.connect(_record_zone_change)


func after_each() -> void:
	EventBus.notification_requested.disconnect(_record_notification)
	EventBus.zone_changed.disconnect(_record_zone_change)
	if is_instance_valid(_main):
		_main.free()
	ContentRegistry.load_all(ContentRegistry.DATA_DIR)
	super.after_each()


# Authored-condition fixture only: no new campaign or clinical content.
class ZoneStoryDirector extends ChapterDirector:
	func _story() -> Dictionary:
		return {
			"objectives": [{"id": "fixture_arrive", "text": "Fixture arrival",
				"complete_when": {"zone": "zone_security_admin"}}],
			"beats": [{"id": "fixture_arrival", "when": {"zone": "zone_security_admin"},
				"actions": [{"flag": "fixture_arrived"}]}]
		}


func _install_zone_story() -> ChapterDirector:
	_main.get_node("ChapterDirector").free()
	var director: ChapterDirector = ZoneStoryDirector.new()
	director.name = "ChapterDirector"
	_main.add_child(director)
	return director


func test_zone_conditions_follow_real_walk_and_update_objective() -> void:
	var director: ChapterDirector = _install_zone_story()
	await runner.get_tree().process_frame
	check_eq(director.get_story_context().get("zone", ""), CLINICAL, "initial story location")
	check_eq(director.get_current_objective().get("id", ""), "fixture_arrive", "arrival objective active")
	await _walk_into_security()
	check(director.has_flag("fixture_arrived"), "arrival beat runs from zone event without manual evaluation")
	check(director.get_current_objective().is_empty(), "arrival completes objective")
	check_eq(_main.get_node("HUD").objective_text, "", "HUD clears completed objective")
	_player().place(Vector3(0.0, 0.05, -10.0), PI)
	_zones().update_now()
	check_eq(director.get_story_context().get("zone", ""), CLINICAL, "return updates story location")
	check_eq(director.to_save_data()["chapters"]["ch1"]["fired"].count("fixture_arrival"), 1, "arrival remains deduplicated")


func test_zone_story_context_survives_same_zone_load_and_new_game() -> void:
	var director: ChapterDirector = _install_zone_story()
	await _walk_into_security()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save away from start zone")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "reload without changing zone")
	check_eq(director.get_story_context().get("zone", ""), SECURITY, "same-zone reload restores location")
	check(director.has_flag("fixture_arrived"), "saved arrival retained")
	SaveManager.reset_all()
	await runner.get_tree().process_frame
	check_eq(director.get_story_context().get("zone", ""), CLINICAL, "new game uses start location")
	check(not director.has_flag("fixture_arrived"), "new game does not replay old arrival")


# --- Chapter 1 is unchanged --------------------------------------------------------------

func test_chapter1_loads_only_the_clinical_wing() -> void:
	check(ContentRegistry.is_valid, "zones.json validates: %s" % str(ContentRegistry.errors))
	check_eq(_zones().current_zone_id, CLINICAL, "starts in the clinical wing")
	check_eq(_zones().get_loaded_zone_ids(), [CLINICAL] as Array[String], "nothing else is loaded")
	check(_world().unresolved.is_empty(), "every configured node exists: %s" % str(_world().unresolved))
	_player().place(Vector3(0.0, 0.05, -18.5), 0.0)
	_zones().update_now()
	check(not _zones().is_streaming(SECURITY), "a locked ward entry does not stream the security wing")


func test_locked_connections_ignore_trust() -> void:
	for staff_id: String in ContentRegistry.get_staff_ids():
		for axis: String in ["respect", "trust"]:
			TrustManager.adjust(staff_id, axis, 100.0, "test")
	var entry: ImportedDoor = _world().get_door("door_ward_entry")
	_interact(entry.get_leaves()[0].get_node("Interactable"))
	check(not entry.is_open, "ward entry stays locked at full trust")
	check_contains(_notifications, "Ward entry: controlled access", "ward entry says why")
	await _walk_into_security()
	_notifications.clear()
	check(not _zones().use_connection(LIFT), "lift refused without access")
	check(not _zones().in_transition, "no transition started")
	check_eq(_zones().current_zone_id, SECURITY, "still in the security wing")
	check_contains(_notifications, "Restricted lift: the key switch will not turn", "lift says why")
	check_eq(_prompt_of(_world().find_zone_node(SECURITY, "LL_ElevatorDoors")),
			"Take the restricted lift down to the research unit (locked)", "lift prompt shows it is locked")


# --- Seamless door -----------------------------------------------------------------------

func test_ward_entry_is_walked_through_without_a_fade() -> void:
	var transitions: Array[int] = [0]
	_zones().transition_finished.connect(func() -> void: transitions[0] += 1)
	await _walk_into_security()
	check_eq(_zones().current_zone_id, SECURITY, "now in the security wing")
	check_eq(_zone_changes, ["%s<-%s" % [SECURITY, CLINICAL]], "one zone change")
	check_eq(transitions[0], 0, "no fade transition")
	check_eq(_zones().get_loaded_zone_ids(), [CLINICAL, SECURITY] as Array[String], "both ground-floor zones loaded")
	check(_world().get_door("door_conference") != null, "security doors are wired")
	_player().place(Vector3(0.0, 0.05, -10.0), PI)
	_zones().update_now()
	check_eq(_zones().current_zone_id, CLINICAL, "walking back returns to the clinical wing")
	var tracker: AudioZoneTracker = _main.get_node("AudioZoneTracker")
	check_eq(tracker.location_at(Vector3(-3.0, 0.0, -10.0)), "nursing_station", "clinical audio rooms still apply")
	check_eq(tracker.location_at(Vector3(0.0, 0.0, -30.0)), "corridor", "security wing has a location")


func test_security_wing_keeps_the_clinical_wing_that_holds_its_door() -> void:
	TrustManager.grant_access("access_ward_entry", "test")
	TrustManager.grant_access("access_restricted_lift", "test")
	await _walk_into_security()
	await _use(LIFT)
	await _use(LIFT)
	check_eq(_zones().current_zone_id, SECURITY, "back in the security wing")
	check_eq(_zones().get_loaded_zone_ids(), [CLINICAL, SECURITY] as Array[String],
			"the clinical wing is rebuilt with the ward entry doors")


# --- Fade transitions ------------------------------------------------------------------

func test_ten_lift_round_trips_free_each_level_and_keep_memory_flat() -> void:
	TrustManager.grant_access("access_ward_entry", "test")
	TrustManager.grant_access("access_restricted_lift", "test")
	await _walk_into_security()
	var first: Dictionary = {}
	for trip: int in 10:
		var ground_roots: Array[int] = _root_ids([CLINICAL, SECURITY])
		await _use(LIFT)
		check_eq(_zones().get_loaded_zone_ids(), [RESEARCH] as Array[String], "trip %d: only the research level" % trip)
		_check_arrival(LIFT, RESEARCH, trip)
		await runner.get_tree().process_frame
		check(ground_roots.all(func(id: int) -> bool: return not is_instance_id_valid(id)),
				"trip %d: ground floor freed" % trip)
		var research_root: int = _world().get_zone_root(RESEARCH).get_instance_id()
		await _use(LIFT)
		_check_arrival(LIFT, SECURITY, trip)
		await runner.get_tree().process_frame
		check(not is_instance_id_valid(research_root), "trip %d: research level freed" % trip)
		check(not TimeManager.is_paused(), "trip %d: clock runs again" % trip)
		if trip == 0:
			first = _zones().sample_performance()
	var last: Dictionary = _zones().sample_performance()
	var growth: float = last["static_memory_bytes"] - first["static_memory_bytes"]
	check(growth < MEMORY_TOLERANCE_BYTES, "static memory grew %.2f MB over nine round trips" % (growth / 1048576.0))
	check_eq(last["object_count"], first["object_count"], "no objects left behind by nine round trips")


func test_every_fade_arrival_stands_on_a_floor() -> void:
	TrustManager.grant_access("access_ward_entry", "test")
	TrustManager.grant_access("access_restricted_lift", "test")
	TrustManager.grant_access("access_maintenance", "test")
	await _walk_into_security()
	for step: Array in [[LIFT, RESEARCH], [LIFT, SECURITY], [HATCH, HISTORIC], [HATCH, SECURITY]]:
		await _use(step[0])
		await wait_physics_frames(30)
		var arrival: Array = _arrival_of(step[0], step[1])
		check_eq(_zones().current_zone_id, step[1], "%s arrives in %s" % step)
		check(absf(_player().global_position.y - float(arrival[1])) < 0.15,
				"%s into %s: stands on a floor, y=%.2f" % [step[0], step[1], _player().global_position.y])
		check_eq(_zones().zone_at(_player().global_position), step[1], "%s arrival is inside %s" % step)


func test_time_is_paused_during_a_fade_and_input_returns() -> void:
	TrustManager.grant_access("access_ward_entry", "test")
	TrustManager.grant_access("access_restricted_lift", "test")
	await _walk_into_security()
	_zones().fade_seconds = 0.05
	var minutes: int = TimeManager.total_minutes
	check(_zones().use_connection(LIFT), "lift used")
	check(_zones().in_transition, "transition running")
	check(not _player().input_enabled, "no control while fading")
	check(TimeManager.is_paused(), "clock paused while fading")
	while _zones().in_transition:
		await runner.get_tree().process_frame
	check_eq(TimeManager.total_minutes, minutes, "no game time passed during the transition")
	check(not TimeManager.is_paused(), "clock runs again")
	check(_player().input_enabled, "control returns")
	check(not _zones().use_connection("conn_ward_entry"), "seamless connections are walked, not used")


# --- Door state and saves -----------------------------------------------------------------

func test_door_opened_in_security_survives_unload_save_and_load() -> void:
	TrustManager.grant_access("access_ward_entry", "test")
	TrustManager.grant_access("access_restricted_lift", "test")
	await _walk_into_security()
	_world().get_door("door_conference").set_open(true, false)
	await _use(LIFT)
	check(_world().get_door("door_conference") == null, "security wing unloaded")
	check(_zones().get_zone_objects(SECURITY)["door:door_conference"]["open"], "state kept while unloaded")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save on the research level")
	SaveManager.reset_all()
	check_eq(_zones().get_loaded_zone_ids(), [CLINICAL] as Array[String], "reset returns to the clinical wing")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check_eq(_zones().current_zone_id, RESEARCH, "loaded on the research level")
	await _use(LIFT)
	check(_world().get_door("door_conference").is_open, "conference door still open after the round trip")
	check(_world().get_door("door_ward_entry").is_open, "ward entry still open")


func test_saving_mid_zone_restores_zone_position_and_time_without_a_transition() -> void:
	TrustManager.grant_access("access_ward_entry", "test")
	await _walk_into_security()
	_player().place(Vector3(0.5, 0.05, -33.0), 0.4)
	TimeManager.advance(45, "test")
	var minutes: int = TimeManager.total_minutes
	var before: Dictionary = SaveManager.capture_state()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save in the security wing")
	SaveManager.reset_all()
	var transitions: Array[int] = [0]
	_zones().transition_finished.connect(func() -> void: transitions[0] += 1)
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check_eq(_zones().current_zone_id, SECURITY, "zone restored")
	check_eq(_zones().get_loaded_zone_ids(), [CLINICAL, SECURITY] as Array[String], "built directly")
	check(_player().global_position.distance_to(Vector3(0.5, 0.05, -33.0)) < 0.01, "position restored")
	check_eq(TimeManager.total_minutes, minutes, "time restored")
	check_eq(transitions[0], 0, "loading plays no transition")
	check(not _zones().in_transition, "not fading")
	var after: Dictionary = SaveManager.capture_state()
	for key: String in ["zones", "world", "time"]:
		check_eq(JSON.stringify(after[key], "", true), JSON.stringify(before[key], "", true), "%s state round-trips exactly" % key)


func test_version2_save_from_main_migrates_doors_into_zones() -> void:
	_install_save(FileAccess.get_file_as_string(V2_SAVE))
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "v2 save loads")
	check_eq(_zones().current_zone_id, CLINICAL, "migrated into the clinical wing")
	check(_world().get_door("door_office").is_open, "office door open, as saved")
	check(_world().get_door("door_interview").is_open, "interview door open, as saved")
	check(not _world().get_door("door_archive").is_open, "archive door closed, as saved")
	check(_player().global_position.distance_to(Vector3(-0.5, 0.0, -12.0)) < 0.01, "position kept")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "re-save")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.get_slot_path(TEST_SAVE_SLOT)))
	check_eq(int(saved["save_version"]), 3, "re-saved as version 3")
	check(not saved["state"]["world"].has("objects"), "doors no longer saved under world")
	check(saved["state"]["zones"]["objects"][CLINICAL]["door:door_office"]["open"], "doors saved per zone")


func test_tampered_version2_save_is_rejected_before_migration() -> void:
	_install_save(FileAccess.get_file_as_string(V2_SAVE).replace("\"open\": true", "\"open\": false"))
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), ERR_FILE_CORRUPT, "checksum checked on the file as written")


# --- Validation ----------------------------------------------------------------------------

func test_zone_rules_are_validated() -> void:
	var docs: Dictionary = _documents()
	var zones: Array = docs["zones"]["data"]["zones"]
	var connections: Array = docs["zones"]["data"]["connections"]
	zones[2]["level"] = "ground"  # Research floor plan on the ground floor.
	zones[3]["id"] = "historic_sublevel"
	zones[4]["status"] = "placeholder"  # A placeholder may not ship geometry.
	zones[3]["environments"].append("res://assets/exports/ward_zero/env/ENV_Missing.glb")
	connections[0]["ends"][1]["zone"] = RESEARCH
	connections[1]["ends"][0].erase("arrival")
	connections[2]["ends"][1]["zone"] = SECURITY
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "bounds overlap zone_security_admin on level 'ground'", "overlapping zones on one level")
	check_contains(report["errors"], "zone id 'historic_sublevel' must start with 'zone_'", "zone prefix")
	check_contains(report["errors"], "a placeholder zone lists no environments", "placeholder ships no geometry")
	check_contains(report["errors"], "is not an imported scene under res://assets/", "missing environment")
	check_contains(report["errors"], "connections[1].ends[0]: a fade connection needs \"node\" and \"arrival\"", "arrival required")
	check_contains(report["errors"], "connections[2].ends: a connection joins exactly two different zones", "two zones")


func test_seamless_connection_stays_on_one_level() -> void:
	var docs: Dictionary = _documents()
	var connection: Dictionary = docs["zones"]["data"]["connections"][0]
	connection["ends"][1]["zone"] = HISTORIC
	connection["door_zone"] = "zone_ward_zero"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "a seamless connection stays on one level", "level rule")
	check_contains(report["errors"], "door_zone: 'zone_ward_zero' is not one of the connection's zones", "door zone")


func test_world_file_names_a_built_start_zone() -> void:
	var docs: Dictionary = _documents()
	var world: Dictionary = docs[ContentRegistry.WORLD_KEY + "ch1"]["data"]
	world["start_zone"] = "zone_ward_zero"
	world["characters"][0]["zone"] = "zone_atrium"
	docs["zones"]["data"]["zones"][4]["status"] = "placeholder"
	docs["zones"]["data"]["zones"][4]["environments"] = []
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "start_zone: 'zone_ward_zero' is a placeholder zone", "start zone built")
	check_contains(report["errors"], "characters[0].zone: unknown zone id 'zone_atrium'", "entry zone known")


func test_every_zone_audio_location_exists() -> void:
	var defined: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://audio/cues.json"))["locations"]
	for zone_id: String in ContentRegistry.get_zone_ids():
		var zone: Dictionary = ContentRegistry.get_zone(zone_id)
		var locations: Array = [zone.get("default_audio_location", "")]
		for rect: Dictionary in zone.get("audio_zones", []):
			locations.append(rect["location"])
		for location: String in locations:
			check(defined.has(location), "%s: audio location '%s' is defined in audio/cues.json" % [zone_id, location])


# --- Helpers ----------------------------------------------------------------------------------

## Grants ward entry access, streams the security wing, opens the doors and
## steps through them.
func _walk_into_security() -> void:
	TrustManager.grant_access("access_ward_entry", "test")
	_player().place(Vector3(0.0, 0.05, -18.5), 0.0)
	_zones().update_now()
	check(_zones().is_streaming(SECURITY) or _world().has_zone(SECURITY), "near the open-able door, the security wing streams")
	var entry: ImportedDoor = _world().get_door("door_ward_entry")
	_interact(entry.get_leaves()[0].get_node("Interactable"))
	check(entry.is_open, "ward entry opens with access")
	check(_world().has_zone(SECURITY), "the security wing is loaded before the doors open")
	_player().place(Vector3(0.0, 0.05, -23.0), 0.0)
	await wait_physics_frames(2)
	_zones().update_now()


func _use(connection_id: String) -> void:
	check(_zones().use_connection(connection_id), "%s used" % connection_id)
	while _zones().in_transition:
		await runner.get_tree().process_frame


func _arrival_of(connection_id: String, zone_id: String) -> Array:
	for end: Dictionary in ContentRegistry.get_connection(connection_id)["ends"]:
		if end["zone"] == zone_id:
			return end["arrival"]["position"]
	return []


func _check_arrival(connection_id: String, zone_id: String, trip: int) -> void:
	var arrival: Array = _arrival_of(connection_id, zone_id)
	var at: Vector3 = Vector3(arrival[0], arrival[1], arrival[2])
	check_eq(_zones().current_zone_id, zone_id, "trip %d: in %s" % [trip, zone_id])
	check(_player().global_position.distance_to(at) < 0.01, "trip %d: on the %s arrival" % [trip, zone_id])


func _root_ids(zone_ids: Array[String]) -> Array[int]:
	var ids: Array[int] = []
	for zone_id: String in zone_ids:
		if _world().has_zone(zone_id):
			ids.append(_world().get_zone_root(zone_id).get_instance_id())
	return ids


func _prompt_of(node: Node3D) -> String:
	var point: Interactable = node.get_node_or_null("ConnectionPoint")
	return point.get_prompt() if point != null else ""


func _documents() -> Dictionary:
	var problems: Array[String] = []
	return ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)


func _install_save(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveManager.get_slot_path(TEST_SAVE_SLOT), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _interact(interactable: Interactable) -> void:
	interactable.interact(_player())


func _record_notification(text: String) -> void:
	_notifications.append(text)


func _record_zone_change(zone_id: String, previous_zone_id: String) -> void:
	_zone_changes.append("%s<-%s" % [zone_id, previous_zone_id])


func _zones() -> ZoneDirector:
	return _main.get_node("ZoneDirector")


func _world() -> AuthoredWorld:
	return _main.get_node("World")


func _player() -> FirstPersonController:
	return _main.get_node("Player")
