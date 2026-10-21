extends TestCase

func test_all_standalone_review_views_build_without_campaign_state() -> void:
	var patients: Dictionary = PatientManager.to_save_data()
	var review: Node3D = load("res://scenes/review/EnvironmentReview.tscn").instantiate()
	runner.add_child(review)
	for index: int in [1, 2, 3]:
		review._show(index)
		check(not review._models.find_children("*", "MeshInstance3D", true, false).is_empty(), "review view has actual exported geometry")
		check(not review._models.find_children("CAM_*", "Camera3D", true, false).is_empty(), "exported framing camera available")
	check_eq(PatientManager.to_save_data(), patients, "standalone art review changes no patient state")
	review.free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func test_repeated_zone_finishes_share_materials_and_preserve_textured_signs() -> void:
	var scene: PackedScene = load("res://assets/exports/clinical/env/ENV_ClinicalCorridor_20m.glb")
	var root: Node3D = scene.instantiate()
	var textured: Array[Material] = []
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		for surface: int in node.mesh.get_surface_count():
			var material: StandardMaterial3D = node.get_active_material(surface) as StandardMaterial3D
			if material != null and material.albedo_texture != null:
				textured.append(material)
	EnvironmentFinish.apply(root)
	var count: int = EnvironmentFinish.material_count()
	check(count > 0, "flat architectural surfaces receive a finish")
	root.free()
	for visit: int in 3:
		root = scene.instantiate()
		EnvironmentFinish.apply(root)
		check_eq(EnvironmentFinish.material_count(), count, "zone visits do not grow the material cache")
		for node: Node in root.find_children("*", "MeshInstance3D", true, false):
			for surface: int in node.mesh.get_surface_count():
				var source: Material = node.mesh.surface_get_material(surface)
				if source in textured:
					check_eq(node.get_active_material(surface), source, "existing textured material is preserved")
		root.free()

func test_exterior_visibility_and_collision_follow_real_saved_level() -> void:
	var main: Main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(main)
	var zones: ZoneDirector = main.get_node("ZoneDirector")
	var campus: CampusBackdrop = main.get_node("CampusBackdrop")
	await wait_physics_frames(2)
	check(campus.visible, "campus starts on ground level")
	check(not campus.find_children("*", "CollisionShape3D", true, false).is_empty(), "campus has real collision")
	zones.load_save_data({"current": "zone_research_level", "objects": {}})
	await wait_physics_frames(2)
	check(not campus.visible, "outdoor mesh does not leak into overlapping research level")
	for shape: Node in campus.find_children("*", "CollisionShape3D", true, false):
		check(shape.disabled, "outdoor physics is disabled on other levels")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save on research level")
	zones.reset_state()
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "restore research level")
	await wait_physics_frames(2)
	check(not campus.visible, "loaded research save keeps campus hidden")
	zones.reset_state()
	await wait_physics_frames(2)
	check(campus.visible, "new game restores ground exterior")
	main.free()
