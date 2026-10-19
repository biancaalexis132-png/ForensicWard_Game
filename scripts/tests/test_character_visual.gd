extends TestCase
## Verifies optional character visuals do not alter fallback, interaction,
## dialogue, save data, or zone-rebuild behavior.

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
	super.after_each()


func test_seated_fallback_preserves_existing_interaction_contract() -> void:
	var character: WardCharacter = _spawn_character("staff_bennett", true)
	var placeholder: MeshInstance3D = character.get_node("Body/Mesh")
	var collision: CollisionShape3D = character.get_node("Body/Collision")
	var interactable: Interactable = character.get_node("Interactable")
	check(placeholder.visible, "legacy capsule is visible by default")
	check_eq(placeholder.scale, Vector3(1.0, 0.65, 1.0), "only the placeholder receives seated scaling")
	check(collision.disabled, "seated body collider remains disabled")
	check_eq(interactable.interactable_id, "character:staff_bennett", "interaction ID is unchanged")
	check(character.get_node("VisualRoot") is Node3D, "optional visual slot exists")


func test_visual_scene_attaches_without_rig_scaling_and_dialogue_still_plays() -> void:
	var character: WardCharacter = _spawn_character("staff_bennett", true)
	var rig_root: Node3D = Node3D.new()
	rig_root.name = "TestRig"
	rig_root.position = Vector3(0.2, 0.4, -0.1)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	rig_root.add_child(mesh_instance)
	var expected_position: Vector3 = rig_root.position
	var packed_rig: PackedScene = _pack_scene(rig_root)
	check(character.set_visual_scene(packed_rig), "Node3D visual scene attaches")
	var visual: Node3D = character.get_node("VisualRoot/TestRig")
	check_eq(visual.position, expected_position, "source visual position is preserved")
	check_eq(visual.scale, Vector3.ONE, "seated placeholder scale is not applied to the rig")
	check(not (character.get_node("Body/Mesh") as MeshInstance3D).visible,
			"placeholder hides after a visual attaches")
	check((character.get_node("Body/Collision") as CollisionShape3D).disabled,
			"visual attachment does not change seated collision")

	AudioDirector.play_line(GREETING_ID, character)
	check(AudioDirector.is_dialogue_playing(), "Naomi dialogue starts with a visual that has no rig controls")
	var controller: NaomiActingController = character.get_node("NaomiActingController")
	check_eq(controller.get_active_line_id(), GREETING_ID, "existing Naomi cue follows dialogue playback")
	AudioDirector.stop_dialogue()
	await runner.get_tree().process_frame
	character.clear_visual_scene()
	check((character.get_node("Body/Mesh") as MeshInstance3D).visible,
			"clearing the visual restores the fallback")
	check(character.get_node_or_null("VisualRoot/TestRig") == null,
			"clearing the visual removes the imported scene")


func test_visual_scene_can_be_configured_before_tree_entry() -> void:
	var character: WardCharacter = CHARACTER_SCENE.instantiate() as WardCharacter
	character.kind = WardCharacter.Kind.STAFF
	character.character_id = "staff_voss"
	var rig: Node3D = Node3D.new()
	rig.name = "TestRig"
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	rig.add_child(mesh_instance)
	check(character.set_visual_scene(_pack_scene(rig)), "visual can be queued before the character enters the tree")
	runner.add_child(character)
	_roots.append(character)
	check(not (character.get_node("Body/Mesh") as MeshInstance3D).visible,
			"queued visual attaches during character readiness")
	check(character.get_node_or_null("VisualRoot/TestRig") != null, "queued visual is present")


func test_invalid_visual_keeps_fallback_visible() -> void:
	var character: WardCharacter = _spawn_character("staff_voss", false)
	var invalid_root: Node = Node.new()
	invalid_root.name = "InvalidVisualRoot"
	var invalid_scene: PackedScene = _pack_scene(invalid_root)
	check(not character.set_visual_scene(invalid_scene), "non-Node3D scene is rejected")
	check((character.get_node("Body/Mesh") as MeshInstance3D).visible,
			"rejected visual leaves the placeholder operational")
	check(character.get_node("VisualRoot").get_child_count() == 0,
			"rejected visual does not leave a partial child")

	var empty_root: Node3D = Node3D.new()
	empty_root.name = "EmptyVisualRoot"
	var empty_scene: PackedScene = _pack_scene(empty_root)
	check(not character.set_visual_scene(empty_scene), "empty 3D visual scene is rejected")
	check((character.get_node("Body/Mesh") as MeshInstance3D).visible,
			"empty scene leaves the placeholder visible")


func test_visual_is_not_saved_and_zone_rebuild_returns_to_campaign_visual() -> void:
	var main: Node3D = load(MAIN_SCENE).instantiate() as Node3D
	runner.add_child(main)
	_roots.append(main)
	await runner.get_tree().process_frame
	var world: AuthoredWorld = main.get_node("World")
	var character: WardCharacter = world.get_character("staff_bennett")
	check(character != null, "Chapter 1 Bennett is assembled from world data")
	var expected_state: Dictionary = SaveManager.capture_state()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save before visual attach")
	var rig: Node3D = Node3D.new()
	rig.name = "TestRig"
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	rig.add_child(mesh_instance)
	check(character.set_visual_scene(_pack_scene(rig)), "test visual attaches to Chapter 1 character")
	var save_data: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(SaveManager.get_slot_path(TEST_SAVE_SLOT)))
	check(not save_data.get("state", {}).has("character_visuals"),
			"visual configuration adds no save-provider state")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load while visual is attached")
	check_eq(SaveManager.capture_state(), expected_state, "saved gameplay state is unchanged")

	world.unload_zone(CLINICAL_ZONE)
	await runner.get_tree().process_frame
	check(world.get_character("staff_bennett") == null, "unloaded zone forgets the old character")
	world.build_zone(CLINICAL_ZONE, AuthoredWorld.load_zone_scenes(CLINICAL_ZONE))
	var rebuilt: WardCharacter = world.get_character("staff_bennett")
	check(rebuilt != null, "zone rebuild recreates Bennett")
	if rebuilt != null:
		check_eq((rebuilt.get_node("Interactable") as Interactable).interactable_id,
				"character:staff_bennett", "rebuilt character retains the existing interaction ID")
		check(not (rebuilt.get_node("Body/Mesh") as MeshInstance3D).visible,
				"rebuilt zone restores its authored campaign model")
		check_eq(rebuilt.visual_scene.resource_path,
				CampaignCastVisuals.load_data()["characters"]["staff_bennett"]["scene"],
				"temporary visual is replaced by the normal cast asset after streaming")


func _spawn_character(id: String, is_seated: bool) -> WardCharacter:
	var character: WardCharacter = CHARACTER_SCENE.instantiate() as WardCharacter
	character.kind = WardCharacter.Kind.STAFF
	character.character_id = id
	character.seated = is_seated
	runner.add_child(character)
	_roots.append(character)
	return character


func _pack_scene(root: Node) -> PackedScene:
	for node: Node in root.find_children("*", "Node", true, false):
		node.owner = root
	var scene: PackedScene = PackedScene.new()
	check_eq(scene.pack(root), OK, "synthetic test scene packs")
	root.free()
	return scene
