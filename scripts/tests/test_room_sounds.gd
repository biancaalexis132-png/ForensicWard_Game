extends TestCase
## Positional room sound (RoomSounds): which fixtures and workstations play near you.

var _main: Node = null


func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	_main = null
	super.after_each()


func test_data_is_valid() -> void:
	check_eq(RoomSounds.validate(), [] as Array[String], "room_sounds.json is valid")


func test_nearest_sources_play_and_silent_places_stay_silent() -> void:
	var sounds: RoomSounds = _boot()
	check(not sounds.drive_audio, "headless runs choose sources but play nothing")
	var terminal: Node3D = _first_terminal(sounds.world)
	check(terminal != null, "the start zone has an EHR workstation")
	if terminal == null:
		return
	var probe: Node3D = Node3D.new()
	sounds.world.add_child(probe)
	probe.global_position = terminal.global_position + Vector3(0.6, 0.0, 0.6)
	sounds.target = probe
	sounds.location_override = "corridor"
	sounds.update_now()
	var keys: Array = sounds.get_active_keys()
	check(keys.any(func(k: String) -> bool: return k.begins_with("workstation:")), "the workstation beside you whirs")
	check(keys.any(func(k: String) -> bool: return k.begins_with("ceiling_light:")), "a fixture overhead hums")
	check(keys.size() <= int(RoomSounds.load_settings()["max_active"]), "never more than max_active sources")
	var wanted: Array[Dictionary] = sounds.wanted_sources()
	for i: int in range(1, wanted.size()):
		check(wanted[i - 1]["distance"] <= wanted[i]["distance"], "nearest first")
	probe.global_position += Vector3(500.0, 0.0, 500.0)
	sounds.update_now()
	check(sounds.get_active_keys().is_empty(), "far from everything, nothing plays")
	probe.global_position = terminal.global_position + Vector3(0.6, 0.0, 0.6)
	sounds.location_override = "ward_zero"
	sounds.update_now()
	check(sounds.get_active_keys().is_empty(), "in Ward Zero the fixtures fall silent")


func test_a_source_is_a_quiet_looping_positional_player() -> void:
	var sounds: RoomSounds = _boot()
	sounds.drive_audio = true
	var at: Vector3 = Vector3(1.0, 2.6, -3.0)
	var player: AudioStreamPlayer3D = sounds._start({"key": "ceiling_light:test", "kind": "ceiling_light", "position": at})
	check(player != null, "a player is made for the source")
	if player == null:
		return
	check_eq(player.bus, &"SFX", "on the effects bus, with the room's reverb")
	check(player.global_position.is_equal_approx(at), "placed at the source")
	check((player.stream as AudioStreamOggVorbis).loop, "the loop repeats")
	check(absf(player.pitch_scale - 1.0) <= 0.02, "each fixture is detuned only slightly")
	player.stop()
	player.free()


# --------------------------------------------------------------------------- helpers

func _boot() -> RoomSounds:
	CharacterVisualPreview.set_requests({})
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	var sounds: RoomSounds = _main.get_node("RoomSounds") as RoomSounds
	check(sounds != null and sounds.world != null, "Main adds RoomSounds with the world")
	return sounds


func _first_terminal(world: AuthoredWorld) -> Node3D:
	for node: Node in world.find_children("*", "ImportedInteractable", true, false):
		var interactable: ImportedInteractable = node as ImportedInteractable
		if interactable.kind == "ehr_terminal" and interactable.is_inside_tree():
			return interactable.get_parent() as Node3D
	return null
