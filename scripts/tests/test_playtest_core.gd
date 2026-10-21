extends TestCase
## Owner playtest fixes (2026-10-21): a conversation stops when the player
## walks away from the speaker, configured doors carry room signs, and a quiet
## music underscore plays under the ward ambience with its own volume setting.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"

var _roots: Array[Node] = []
var _saved_play_music: float = 0.6


var _saved_persist: bool = true


func before_each() -> void:
	super.before_each()
	_saved_persist = AudioDirector.persist
	AudioDirector.persist = false
	_saved_play_music = float(AudioDirector.get_setting("volume_play_music"))


func after_each() -> void:
	AudioDirector.stop_dialogue()
	AudioDirector.set_setting("volume_play_music", _saved_play_music)
	AudioDirector.stop_music(0.01)
	AudioDirector.persist = _saved_persist
	for root: Node in _roots:
		if is_instance_valid(root):
			root.queue_free()
	_roots.clear()
	super.after_each()


## Stops this test's audio and lets the voices and music release.
func _release_audio() -> void:
	AudioDirector.stop_dialogue()
	AudioDirector.stop_music(0.01)
	await runner.get_tree().create_timer(0.3).timeout


func test_walking_away_stops_the_conversation() -> void:
	var main: Node = await _main()
	var range_node: ConversationRange = main.get_node("ConversationRange")
	var bennett: WardCharacter = range_node.find_character("staff_bennett")
	check(bennett != null, "Naomi Bennett is in the ward")
	if bennett == null:
		return
	var player: FirstPersonController = main.get_node("Player")
	player.global_position = bennett.global_position + Vector3(1.5, 0.0, 0.0)
	var line_id: String = _bennett_line()
	check(not line_id.is_empty(), "a recorded Bennett line exists")
	AudioDirector.play_line(line_id)
	await _physics_frames(3)
	check(range_node.anchor == bennett, "her line anchors the conversation to her")
	check(AudioDirector.is_dialogue_playing(), "nearby, the line keeps playing")
	player.global_position = bennett.global_position + Vector3(ConversationRange.WALK_AWAY_METERS + 2.0, 0.0, 0.0)
	await _physics_frames(3)
	check(not AudioDirector.is_dialogue_playing(), "walking away stops the line")
	check(range_node.anchor == null, "the anchor clears")
	await _release_audio()


func test_narrator_lines_do_not_anchor() -> void:
	var main: Node = await _main()
	var range_node: ConversationRange = main.get_node("ConversationRange")
	AudioDirector.play_text("", "A narrated line with no speaker in the world.")
	await _physics_frames(2)
	check(range_node.anchor == null, "an unvoiced narrator line has no anchor")
	await _release_audio()


func test_configured_doors_have_room_signs() -> void:
	check_eq(ImportedDoor.default_sign("Records archive door"), "Records Archive", "door is dropped, words titled")
	check_eq(ImportedDoor.default_sign("Ward entry doors"), "Ward Entry", "plural doors is dropped")
	check_eq(ImportedDoor.default_sign("W0-B door"), "W0-B", "codes keep their capitals")
	var main: Node = await _main()
	var world: AuthoredWorld = main.get_node("World")
	var expected: Dictionary = {"door_archive": "Records Archive", "door_office": "Office",
			"door_interview": "Interview Room A"}
	for door_id: String in expected:
		var door: ImportedDoor = world.get_door(door_id)
		check(door != null, "%s is built" % door_id)
		if door == null:
			continue
		check_eq(door.sign_text, expected[door_id], "%s sign text" % door_id)
		var root: Node = door.get_parent()
		var front: Node3D = root.get_node_or_null("Sign")
		var back: Node3D = root.get_node_or_null("SignBack")
		check(front != null and back != null, "%s has a plaque on each face" % door_id)
		if front != null:
			check_eq((front.get_node("Label") as Label3D).text, expected[door_id], "%s plaque reads its name" % door_id)
			check(front.position.y > 1.8, "%s plaque sits above head height" % door_id)


func test_ward_plays_quiet_underscore_with_its_own_volume() -> void:
	AudioDirector.set_setting("volume_play_music", 0.6)
	AudioDirector.set_music_state("ward_underscore", 0.01)
	check(AudioDirector.is_underscore_playing(), "the ward underscore plays")
	check_eq(AudioDirector.get_music_cue(), "mus_waiting_room", "with one of the approved songs")
	var quiet_db: float = AudioDirector._variant_db()
	check(quiet_db < -6.0, "it sits well below its normal level (%.1f dB)" % quiet_db)
	AudioDirector.set_setting("volume_play_music", 1.0)
	check(AudioDirector._variant_db() > quiet_db, "the setting raises it")
	AudioDirector.set_setting("volume_play_music", 0.0)
	check_eq(AudioDirector.get_music_cue(), "", "zero turns music during play off")
	AudioDirector.set_music_state("hospital_ordinary", 0.01)
	check_eq(AudioDirector._variant_db(), 0.0, "other music states are unaffected")
	await _release_audio()


func test_pause_menu_has_music_during_play_slider() -> void:
	var main: Node = await _main()
	var slider: HSlider = main.get_node("PauseMenu").find_child("PlayMusic", true, false) as HSlider
	check(slider != null, "the pause menu has a Music during play slider")
	if slider != null:
		slider.value = 0.25
		check(is_equal_approx(float(AudioDirector.get_setting("volume_play_music")), 0.25), "the slider sets it")


func _bennett_line() -> String:
	for line_id: String in AudioDirector.get_scene_lines("ch1_b2_bennett_handover"):
		if AudioDirector.get_line(line_id).get("speaker", "") == "staff_bennett":
			return line_id
	return AudioDirector.find_line("staff_bennett", "I saw your note on Elias. Thank you. The night team will need it.")


func _physics_frames(count: int) -> void:
	for _i: int in count:
		await runner.get_tree().physics_frame


func _main() -> Node:
	var main: Node = load(MAIN_SCENE).instantiate()
	runner.add_child(main)
	_roots.append(main)
	await runner.get_tree().process_frame
	return main
