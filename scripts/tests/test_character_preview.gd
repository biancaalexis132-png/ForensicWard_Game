extends TestCase
## Verifies the review-only Naomi preview: off by default, attaches the real
## candidate GLB when requested, and leaves interaction, dialogue, acting cues,
## save data and zone rebuilds exactly as they are with the placeholder.

const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")
const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const GREETING_ID: String = "ch1_b2_bennett_001"
const CLINICAL_ZONE: String = "zone_clinical_wing"

var _roots: Array[Node] = []


func after_each() -> void:
	AudioDirector.stop_dialogue()
	for root: Node in _roots:
		if is_instance_valid(root):
			root.queue_free()
	_roots.clear()
	CharacterVisualPreview.reset()
	super.after_each()


func test_arguments_select_only_known_candidates() -> void:
	check_eq(CharacterVisualPreview.parse_args(PackedStringArray()), {}, "no arguments, no preview")
	check_eq(CharacterVisualPreview.parse_args(PackedStringArray(["--fullscreen"])), {},
			"unrelated arguments are ignored")
	check_eq(CharacterVisualPreview.parse_args(PackedStringArray(["--character-preview=staff_bennett"])),
			{"staff_bennett": "v05"}, "Bennett defaults to the newest candidate")
	check_eq(CharacterVisualPreview.parse_args(PackedStringArray(["--character-preview=staff_bennett:v01"])),
			{"staff_bennett": "v01"}, "an older candidate can be chosen")
	check_eq(CharacterVisualPreview.parse_args(PackedStringArray(["--character-preview=staff_voss,staff_bennett:v99"])),
			{}, "unknown characters and versions are refused")
	for version: String in ["v01", "v02", "v03", "v04", "v05"]:
		check(ResourceLoader.exists(CharacterVisualPreview.candidate_path("staff_bennett", version)),
				"Naomi %s GLB is imported" % version)


func test_placement_is_identity_without_an_entry() -> void:
	check_eq(CharacterVisualPreview.placement_for("staff_voss"), Transform3D.IDENTITY,
			"characters without a placement keep the model on their marker")


func test_preview_is_off_by_default() -> void:
	CharacterVisualPreview.set_requests({})
	var bennett: WardCharacter = _spawn_character("staff_bennett")
	check((bennett.get_node("Body/Mesh") as MeshInstance3D).visible, "placeholder stays visible")
	check_eq(bennett.get_node("VisualRoot").get_child_count(), 0, "no model is attached")


func test_requested_candidate_attaches_without_changing_interaction() -> void:
	CharacterVisualPreview.set_requests({"staff_bennett": "v05"})
	var bennett: WardCharacter = _spawn_character("staff_bennett")
	var voss: WardCharacter = _spawn_character("staff_voss")
	var visual_root: Node3D = bennett.get_node("VisualRoot")
	check_eq(visual_root.get_child_count(), 1, "Naomi candidate is attached")
	if visual_root.get_child_count() == 1:
		var model: Node = visual_root.get_child(0)
		check_eq(model.find_children("*", "Skeleton3D", true, false).size(), 1, "candidate keeps its rig")
		check_eq((model as Node3D).scale, Vector3.ONE, "candidate is not rescaled")
		check_eq((model as Node3D).transform, CharacterVisualPreview.placement_for("staff_bennett"),
				"only the review placement is applied to the model")
	check(not (bennett.get_node("Body/Mesh") as MeshInstance3D).visible, "placeholder hides behind the model")
	check(not (bennett.get_node("Body/Collision") as CollisionShape3D).disabled, "standing collision is unchanged")
	check_eq((bennett.get_node("Interactable") as Interactable).interactable_id,
			"character:staff_bennett", "interaction ID is unchanged")
	check((voss.get_node("Body/Mesh") as MeshInstance3D).visible, "other characters keep their placeholder")

	AudioDirector.play_line(GREETING_ID, bennett)
	check(AudioDirector.is_dialogue_playing(), "Naomi's greeting still plays with the model attached")
	var controller: NaomiActingController = bennett.get_node("NaomiActingController")
	check_eq(controller.get_active_line_id(), GREETING_ID, "acting cues still follow dialogue")


func test_preview_changes_no_saved_state_and_survives_zone_rebuild() -> void:
	CharacterVisualPreview.set_requests({})
	var plain_state: Dictionary = await _main_state()
	SaveManager.reset_all()

	CharacterVisualPreview.set_requests({"staff_bennett": "v05"})
	var main: Node3D = load(MAIN_SCENE).instantiate() as Node3D
	runner.add_child(main)
	_roots.append(main)
	await runner.get_tree().process_frame
	var world: AuthoredWorld = main.get_node("World")
	var bennett: WardCharacter = world.get_character("staff_bennett")
	check(bennett != null and bennett.get_node("VisualRoot").get_child_count() == 1,
			"nursing-station Bennett shows the candidate")
	if bennett != null and bennett.get_node("VisualRoot").get_child_count() == 1:
		var model: Node3D = bennett.get_node("VisualRoot").get_child(0)
		# glTF models face +Z; the corridor counter is on the +X side of the nursing station.
		check(model.global_basis.z.normalized().dot(Vector3.RIGHT) > 0.99, "previewed Naomi faces the counter")
		check(model.global_position.x < bennett.global_position.x - 0.4,
				"previewed Naomi stands on the office side of the desk, not inside it")
		check_eq((bennett.get_node("Interactable") as Node3D).global_position,
				bennett.global_transform * Vector3(0.0, 0.9, 0.0), "interaction box stays on the marker")
	check_eq(SaveManager.capture_state(), plain_state, "game state is identical with and without the preview")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save with the preview on")
	var save_data: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(SaveManager.get_slot_path(TEST_SAVE_SLOT)))
	check(not str(save_data).contains("Naomi_Bennett"), "no model path reaches the save file")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load with the preview on")

	world.unload_zone(CLINICAL_ZONE)
	await runner.get_tree().process_frame
	world.build_zone(CLINICAL_ZONE, AuthoredWorld.load_zone_scenes(CLINICAL_ZONE))
	var rebuilt: WardCharacter = world.get_character("staff_bennett")
	check(rebuilt != null and rebuilt.get_node("VisualRoot").get_child_count() == 1,
			"rebuilt zone keeps the requested preview")


func _main_state() -> Dictionary:
	var main: Node3D = load(MAIN_SCENE).instantiate() as Node3D
	runner.add_child(main)
	await runner.get_tree().process_frame
	var state: Dictionary = SaveManager.capture_state()
	runner.remove_child(main)
	main.free()
	return state


func _spawn_character(id: String) -> WardCharacter:
	var character: WardCharacter = CHARACTER_SCENE.instantiate() as WardCharacter
	character.kind = WardCharacter.Kind.STAFF
	character.character_id = id
	runner.add_child(character)
	_roots.append(character)
	return character
