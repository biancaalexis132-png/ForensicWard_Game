extends TestCase
## Real campaign casting, rather than command-line model previews.
var _main: Node = null

func before_each() -> void:
	super.before_each()
	CharacterVisualPreview.set_requests({})

func after_each() -> void:
	AudioDirector.stop_dialogue()
	AudioDirector.stop_narration()
	if is_instance_valid(_main):
		_main.free()
	_main = null
	CharacterVisualPreview.reset()
	super.after_each()

func _boot() -> AuthoredWorld:
	_main = load("res://scenes/main/Main.tscn").instantiate()
	runner.add_child(_main)
	await runner.get_tree().process_frame
	return _main.get_node("World") as AuthoredWorld

func test_all_five_chapters_use_real_cast_without_preview_arguments() -> void:
	var data: Dictionary = CampaignCastVisuals.load_data()
	check_eq(CampaignCastVisuals.validate(data), [], "cosmetic catalogue validates")
	var world: AuthoredWorld = await _boot()
	var seen: Dictionary = {}
	for chapter: String in ContentRegistry.get_chapter_ids():
		world.configure_chapter(chapter)
		await runner.get_tree().process_frame
		for entry: Dictionary in ContentRegistry.get_world(chapter)["characters"]:
			var zone: String = str(entry.get("zone", world.start_zone_id))
			if not world.has_zone(zone):
				world.build_zone(zone, AuthoredWorld.load_zone_scenes(zone))
			var id: String = entry["character_id"]
			seen[id] = true
			var actor: WardCharacter = world.get_character(id)
			check(actor != null, "%s %s spawns" % [chapter, id])
			if actor == null:
				continue
			var visual: Node3D = actor.get_node("VisualRoot")
			check_eq(visual.get_child_count(), 1, "%s %s has one imported model" % [chapter, id])
			check(not (actor.get_node("Body/Mesh") as MeshInstance3D).visible, "capsule is fallback only")
			check_eq(actor.visual_scene.resource_path, data["characters"][id]["scene"], "correct cast asset")
			check_eq(str(actor.get_meta("visual_review_status")), "PENDING_OWNER_VISUAL_REVIEW", "integration never invents visual approval")
			if visual.get_child_count() != 1:
				continue
			var model: Node3D = visual.get_child(0)
			check(model.find_child("CharacterFaceRig", true, false) != null, "shared face rig attached")
			check(model.find_child("CharacterGazeRig", true, false) != null, "shared gaze rig attached")
			var body: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
			check(body != null and body.has_animation(&"idle_neutral"), "body animation available")
			var gestures: AnimationPlayer = model.find_child("GestureAnimationPlayer", true, false) as AnimationPlayer
			check(gestures != null and gestures.has_animation(&"small_greeting_nod"), "shared gestures remain available")
			var marker: Node3D = world.find_zone_node(zone, entry["marker"])
			check(model.global_basis.z.normalized().dot(-marker.global_basis.z.normalized()) > 0.99, "model faces authored marker direction")
			var interactable: Node3D = actor.get_node("Interactable")
			check_eq(interactable.global_position, actor.global_transform * Vector3(0.0, 0.9, 0.0), "visible actor and interaction move together")
		check_eq(world.unresolved, [] as Array[String], "chapter world has no missing bindings")
	check_eq(seen.size(), 7, "all seven authored cast members covered across the five chapters")
	# Return to idle before later suites register their input listeners.
	await runner.get_tree().create_timer(0.01).timeout

func test_model_choice_does_not_enter_saves_and_survives_zone_reload() -> void:
	var world: AuthoredWorld = await _boot()
	var before: Dictionary = SaveManager.capture_state()
	world.get_character("staff_voss").clear_visual_scene()
	check_eq(SaveManager.capture_state(), before, "cosmetic model removal changes no saved gameplay state")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "real save with campaign models")
	var saved: String = FileAccess.get_file_as_string(SaveManager.get_slot_path(TEST_SAVE_SLOT))
	check(not "v01_draft" in saved and not "Naomi_Bennett_v07" in saved, "model paths and approvals stay outside save schema")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "real save restores campaign")
	world.unload_zone(world.start_zone_id)
	await runner.get_tree().process_frame
	world.build_zone(world.start_zone_id, AuthoredWorld.load_zone_scenes(world.start_zone_id))
	for id: String in ["staff_bennett", "staff_voss", "pt_elias_ward"]:
		check_eq(world.get_character(id).get_node("VisualRoot").get_child_count(), 1, "streamed zone rebuild restores " + id)
	var bennett: WardCharacter = world.get_character("staff_bennett")
	var controller: NaomiActingController = bennett.get_node("NaomiActingController")
	check(controller.get_adapter().has_capability("body", "idle_neutral"), "Naomi controller discovers model before ready")
	check(controller.get_adapter().has_capability("gesture", "small_greeting_nod"), "Naomi gestures remain connected")

func test_patient_presence_disables_hidden_rigs_and_keeps_interactions_exclusive() -> void:
	var world: AuthoredWorld = await _boot()
	var chapter: ChapterDirector = _main.get_node("ChapterDirector")
	chapter.start_chapter("ch2")
	await runner.get_tree().process_frame
	var elias: WardCharacter = world.get_character("pt_elias_ward")
	var mara: WardCharacter = world.get_character("pt_mara_ellis")
	check(elias.visible and not mara.visible, "original patient present before the approved Mara beat")
	check_eq(mara.process_mode, Node.PROCESS_MODE_DISABLED, "hidden patient skin/face/gaze processing stopped")
	chapter.set_flag("ch2_voss_followup_written_process")
	EventBus.objective_changed.emit("cast_test", "Refresh authored presence")
	check(mara.visible and not elias.visible, "existing story flag selects Mara")
	check_eq(elias.process_mode, Node.PROCESS_MODE_DISABLED, "replaced patient processing stopped")
	check_eq(mara.process_mode, Node.PROCESS_MODE_INHERIT, "visible patient's animation resumes")
	check((mara.get_node("Interactable") as Interactable).enabled, "Mara remains approachable")
	check(not (elias.get_node("Interactable") as Interactable).enabled, "hidden patient cannot be approached")

func test_preview_override_and_invalid_catalogue_recovery() -> void:
	var data: Dictionary = CampaignCastVisuals.load_data()
	data["characters"]["staff_voss"]["marker_offset"] = [0.0, "bad", 0.0]
	check_contains(CampaignCastVisuals.validate(data), "invalid marker offset", "invalid geometry offset rejected")
	data = CampaignCastVisuals.load_data()
	data["characters"]["staff_voss"]["scene"] = "res://assets/exports/characters/../bad.glb"
	check_contains(CampaignCastVisuals.validate(data), "invalid character model path", "path traversal rejected")
	CharacterVisualPreview.set_requests({"staff_bennett": "v06_mpfb"})
	var world: AuthoredWorld = await _boot()
	var bennett: WardCharacter = world.get_character("staff_bennett")
	check_eq(bennett.visual_scene.resource_path, CharacterVisualPreview.candidate_path("staff_bennett", "v06_mpfb"), "explicit preview wins over campaign default")
	check_eq(world.get_character("staff_voss").get_node("VisualRoot").get_child_count(), 1, "other cast keep campaign models")
	var unknown: WardCharacter = load("res://scenes/props/Character.tscn").instantiate()
	unknown.character_id = "unknown_cosmetic_actor"
	check_eq(CampaignCastVisuals.configure(unknown, "MARK_Missing"), Vector3.ZERO, "unknown cosmetics keep original marker")
	check(unknown.visual_scene == null, "unknown cosmetic entry retains existing capsule fallback")
	unknown.free()

func test_player_can_focus_and_talk_to_naomi_inside_the_station() -> void:
	var world: AuthoredWorld = await _boot()
	var nurse: WardCharacter = world.get_character("staff_bennett")
	var player: FirstPersonController = _main.get_node("Player")
	# The workspace approach stays usable alongside the public counter point.
	player.place(Vector3(-3.9, 0.05, nurse.global_position.z), -PI / 2.0, -0.07)
	await wait_physics_frames(5)
	var ray: RayCast3D = player.get_node("Head/Camera3D/InteractionRay")
	ray.force_raycast_update()
	if ray.get_collider() != nurse.get_node("Interactable"):
		print("CAST_RAY_BLOCKED ", (ray.get_collider() as Node).get_path() if ray.get_collider() is Node else "no hit", " at ", ray.get_collision_point(), " camera ", (player.get_node("Head/Camera3D") as Camera3D).global_position)
	check(ray.get_collider() == nurse.get_node("Interactable"), "real player ray reaches the relocated nurse from the station workspace")
	var event: InputEventAction = InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await runner.get_tree().process_frame
	check(TrustManager.has_access("access_records_archive"), "normal interaction still grants authored access and allows Chapter 1 progression")
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await runner.get_tree().create_timer(0.01).timeout

func test_public_counter_talk_point_preserves_wall_and_chapter_bindings() -> void:
	var world: AuthoredWorld = await _boot()
	var player: FirstPersonController = _main.get_node("Player")
	var ray: RayCast3D = player.get_node("Head/Camera3D/InteractionRay")
	for chapter: String in ContentRegistry.get_chapter_ids():
		world.configure_chapter(chapter)
		var nurse: WardCharacter = world.get_character("staff_bennett")
		player.place(Vector3(-0.9, 0.05, -11.05), PI / 2.0, -0.07)
		await wait_physics_frames(5)
		ray.force_raycast_update()
		check(ray.get_collider() == nurse.get_node("Interactable"), chapter + ": corridor player can focus Naomi at the designated counter")
		check_eq((ray.get_collider() as Interactable).interactable_id, "character:staff_bennett", "same authored event id, not a new story trigger")
		var original_mask: int = ray.collision_mask
		ray.collision_mask = 1
		ray.force_raycast_update()
		check(ray.get_collider() is StaticBody3D, "physical counter barrier remains")
		check(str((ray.get_collider() as Node).name).begins_with("ENV_ClinicalCorridor_20m_COL_West"), "original wall collider is intact")
		ray.collision_mask = original_mask
		player.place(Vector3(-0.9, 0.05, -12.1), PI / 2.0, -0.07)
		await wait_physics_frames(3)
		ray.force_raycast_update()
		check(ray.get_collider() != nurse.get_node("Interactable"), "adjacent opaque wall does not offer counter speech")
		# The extra shape shares the actor's presence-controlled Area3D.
		nurse.present_when = {"flag": "counter_presence_probe"}
		nurse._update_presence()
		check_eq((nurse.get_node("Interactable") as Interactable).collision_layer, 0, "absent actor also disables the public talk point")
		nurse.present_when = {}
		nurse._update_presence()
	# A loaded/rebuilt zone recreates the one extra shape without saved state.
	world.configure_chapter("ch1")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "counter setup can be saved")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "counter setup can be loaded")
	world.unload_zone(world.start_zone_id)
	await runner.get_tree().process_frame
	world.build_zone(world.start_zone_id, AuthoredWorld.load_zone_scenes(world.start_zone_id))
	var interaction: Interactable = world.get_character("staff_bennett").get_node("Interactable")
	check_eq(interaction.get_child_count(), 2, "zone rebuild creates original shape plus one public talk point")
	player.place(Vector3(-0.9, 0.05, -11.05), PI / 2.0, -0.07)
	await wait_physics_frames(5)
	ray.force_raycast_update()
	check(ray.get_collider() == interaction, "public counter is still usable after load and zone rebuild")
	var event: InputEventAction = InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await runner.get_tree().process_frame
	check(TrustManager.has_access("access_records_archive"), "counter speech grants only the existing authored access")
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await runner.get_tree().create_timer(0.01).timeout

func test_invalid_public_talk_box_is_rejected_by_content_validation() -> void:
	var problems: Array[String] = []
	var docs: Dictionary = ContentRegistry.collect_documents("res://data", problems)
	var entry: Dictionary = docs[ContentRegistry.WORLD_KEY + "ch1"]["data"]["characters"][1]
	for size: Array in [[0.2, 0.6], [0.2, 0.6, 1.4, 1.0], [-0.2, 0.6, 1.4], [3.0, 0.6, 1.4]]:
		entry["interaction_box"]["size"] = size
		var report: Dictionary = ContentValidator.validate_documents(docs)
		check_contains(report["errors"], "interaction_box.size", "invalid shape dimensions are rejected")
