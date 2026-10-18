extends TestCase
## Verifies Naomi's presentation layer stays additive and capability-driven.

const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")
const GREETING_ID: String = "ch1_b2_bennett_001"

var _characters: Array[WardCharacter] = []


func after_each() -> void:
	AudioDirector.stop_dialogue()
	for character: WardCharacter in _characters:
		if is_instance_valid(character):
			character.queue_free()
	_characters.clear()
	super.after_each()


func test_cue_lookup_is_deterministic_and_defensive() -> void:
	var cue_data: Dictionary = NaomiActingController.load_cue_data()
	var first: Dictionary = NaomiActingController.cue_for_line(cue_data, GREETING_ID)
	var second: Dictionary = NaomiActingController.cue_for_line(cue_data, GREETING_ID)
	check_eq(first, second, "same line ID resolves the same cue data")
	check_eq(first.get("during_speech", {}).get("face", ""), "warm_subtle", "existing greeting cue loads")
	first["during_speech"]["face"] = "changed_by_test"
	check_eq(NaomiActingController.cue_for_line(cue_data, GREETING_ID)
			.get("during_speech", {}).get("face", ""), "warm_subtle", "cue lookup returns a defensive copy")
	check(NaomiActingController.cue_for_line(cue_data, "not_a_dialogue_id").is_empty(),
			"unknown dialogue IDs have no acting cue")


func test_placeholder_safely_ignores_missing_rig_capabilities() -> void:
	var character: WardCharacter = _spawn_bennett()
	var controller: NaomiActingController = character.get_node("NaomiActingController") as NaomiActingController
	var adapter: CharacterActingAdapter = controller.get_adapter()
	check(adapter != null, "placeholder receives acting controller and adapter")
	check(not adapter.has_capability("body", "turn_from_workstation"), "capsule requires no animation clips")
	check(not adapter.has_capability("face", "attentive"), "capsule requires no facial blend shapes")
	controller.begin_conversation()
	_emit_line_started(GREETING_ID)
	check_eq(controller.get_active_line_id(), GREETING_ID, "dialogue still activates the cue without a rig")
	check(adapter.is_actor_speaking(), "speech state is synchronized to Bennett's subtitle start")
	EventBus.dialogue_line_finished.emit(GREETING_ID, false)
	check(not controller.is_conversation_active(), "interruption exits conversation safely")
	check_eq(adapter.get_last_stage(), "interrupted", "interruption returns to safe fallback")
	check_eq(adapter.get_last_cue().get("body", ""), "idle_neutral", "fallback pose remains neutral")


func test_completed_scene_transitions_to_work_state() -> void:
	var character: WardCharacter = _spawn_bennett()
	var controller: NaomiActingController = character.get_node("NaomiActingController") as NaomiActingController
	var ids: Array[String] = [
		"ch1_b2_bennett_001", "ch1_b2_player_001", "ch1_b2_bennett_002",
		"ch1_b2_player_002", "ch1_b2_bennett_003",
	]
	for line_id: String in ids:
		_emit_line_started(line_id)
		check_eq(controller.get_active_line_id(), line_id, "scene line starts: " + line_id)
		EventBus.dialogue_line_finished.emit(line_id, true)
	check(not controller.is_conversation_active(), "final line returns actor to working state")
	check_eq(controller.get_active_line_id(), "", "completed scene clears transient line state")
	check_eq(controller.get_adapter().get_last_cue().get("body", ""),
			"return_to_workstation", "final on_exit cue returns toward workstation")
	check(not controller.get_adapter().is_actor_speaking(), "speaker state clears when voice completes")


func test_missing_voice_file_keeps_subtitle_and_interrupt_fallback() -> void:
	var character: WardCharacter = _spawn_bennett()
	var controller: NaomiActingController = character.get_node("NaomiActingController") as NaomiActingController
	var saved_line: Dictionary = AudioDirector._lines[GREETING_ID].duplicate(true)
	AudioDirector._lines[GREETING_ID]["chapter"] = "naomi_missing_voice_fixture"
	AudioDirector.play_line(GREETING_ID, character)
	check(AudioDirector.is_dialogue_playing(), "unvoiced line remains available as subtitle dialogue")
	check(character.get_node_or_null("Voice_" + GREETING_ID) == null, "missing voice file creates no voice player")
	check_eq(controller.get_active_line_id(), GREETING_ID, "acting still follows unvoiced subtitle start")
	AudioDirector.stop_dialogue()
	AudioDirector._lines[GREETING_ID] = saved_line
	await runner.get_tree().process_frame
	check(not controller.is_conversation_active(), "stopped unvoiced line returns to safe fallback")


func test_save_load_discards_transient_cues_without_schema_changes() -> void:
	var character: WardCharacter = _spawn_bennett()
	var controller: NaomiActingController = character.get_node("NaomiActingController") as NaomiActingController
	await runner.get_tree().process_frame
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save before acting")
	var saved_document: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(SaveManager.get_slot_path(TEST_SAVE_SLOT)))
	var expected_state: Dictionary = saved_document.get("state", {})
	check(not expected_state.has("naomi_acting"), "acting adds no save provider or schema field")
	AudioDirector.play_line(GREETING_ID, character)
	check_eq(controller.get_active_line_id(), GREETING_ID, "voice is active before load")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load existing save during dialogue")
	await runner.get_tree().process_frame
	check(not AudioDirector.is_dialogue_playing(), "load interrupts transient dialogue")
	check(not controller.is_conversation_active(), "load resets the actor to working state")
	var actual_state: Variant = JSON.parse_string(JSON.stringify(SaveManager.capture_state()))
	check_eq(actual_state, expected_state, "acting state is absent from loaded save data")


func test_adapter_uses_a_clip_only_when_present() -> void:
	var root: Node3D = Node3D.new()
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	root.add_child(animation_player)
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation("stand_conversational", Animation.new())
	animation_player.add_animation_library("", library)
	runner.add_child(root)
	var adapter: CharacterActingAdapter = CharacterActingAdapter.new()
	adapter.configure(root)
	root.add_child(adapter)
	check(adapter.has_capability("body", "stand_conversational"), "matching animation is discovered")
	adapter.apply_cue("during_speech", {"body": "stand_conversational"}, true)
	check_eq(animation_player.current_animation, &"stand_conversational", "available body clip plays")
	adapter.apply_cue("fallback", {"body": "missing_clip"}, false)
	check_eq(animation_player.current_animation, &"", "missing clip stops only the adapter-owned animation")
	root.queue_free()


func test_adapter_falls_back_to_idle_neutral_for_a_missing_clip() -> void:
	var root: Node3D = Node3D.new()
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	root.add_child(animation_player)
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation("idle_neutral", Animation.new())
	animation_player.add_animation_library("", library)
	runner.add_child(root)
	var adapter: CharacterActingAdapter = CharacterActingAdapter.new()
	adapter.configure(root)
	root.add_child(adapter)
	# Before the fix the adapter found the idle player but asked it to play the
	# missing clip, which errors and leaves the rig frozen.
	adapter.apply_cue("on_enter", {"body": "turn_from_workstation"}, false)
	check_eq(animation_player.current_animation, &"idle_neutral",
			"a rig without the requested clip plays idle_neutral instead")
	adapter.apply_cue("during_speech", {"body": "stand_conversational"}, true)
	check_eq(animation_player.current_animation, &"idle_neutral", "idle keeps playing across missing clips")
	adapter.apply_cue("fallback", {"body": "none"}, false)
	check_eq(animation_player.current_animation, &"", "body 'none' stops the fallback idle it started")
	root.queue_free()


func _spawn_bennett() -> WardCharacter:
	var character: WardCharacter = CHARACTER_SCENE.instantiate() as WardCharacter
	character.kind = WardCharacter.Kind.STAFF
	character.character_id = "staff_bennett"
	runner.add_child(character)
	_characters.append(character)
	return character


func _emit_line_started(line_id: String) -> void:
	var line: Dictionary = AudioDirector.get_line(line_id)
	EventBus.subtitle_shown.emit(line_id, line["speaker_name"], line["text"], 1.0)
