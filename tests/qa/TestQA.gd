extends Node

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		print("FAIL: " + label)

func _ready() -> void:
	GameState.reset()
	var item_events: Array[String] = []
	var on_item := func(id: String) -> void: item_events.append(id)
	EventBus.item_collected.connect(on_item)
	GameState.collect_item("qa_key")
	GameState.collect_item("qa_key")
	check(GameState.has_item("qa_key") and GameState.collected_items.size() == 1, "pickup state is idempotent")
	check(item_events == ["qa_key"], "duplicate pickup emits only one event")
	EventBus.item_collected.disconnect(on_item)
	check(not GameState.pin_clue("qa_clue"), "locked clues cannot be pinned")
	GameState.unlock_clue("qa_clue")
	check(GameState.pin_clue("qa_clue"), "unlocked clue can be pinned")
	check(not GameState.pin_clue("qa_clue"), "clue cannot be pinned twice")
	GameState.set_objectivity(-10.0)
	check(GameState.objectivity == 0.0 and GameState.bleed_stage == 3, "objectivity lower clamp and bleed")
	GameState.set_objectivity(150.0)
	check(GameState.objectivity == 100.0 and GameState.bleed_stage == 0, "objectivity upper clamp and recovery")
	var snapshot := GameState.to_dict().duplicate(true)
	GameState.reset()
	GameState.from_dict(snapshot)
	check(GameState.has_item("qa_key") and GameState.pinned_clues == ["qa_clue"], "progress survives serialization round trip")
	GameState.reset()
	check(GameState.day == 1 and GameState.shift == "day", "reset starts day 1, day shift")
	GameState.advance_shift()
	check(GameState.day == 1 and GameState.shift == "night", "end shift advances day to night")
	check(TimeManager.get_shift() == "night", "GameState clock is TimeManager's clock")
	GameState.advance_shift()
	check(GameState.day == 2 and GameState.shift == "day", "end shift advances night to next day")
	GameState.reset()
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	var packed := load(main_path) as PackedScene
	check(packed != null, "configured main scene loads")
	if packed != null:
		var main := packed.instantiate()
		add_child(main)
		for i in 3:
			await get_tree().physics_frame
		check(ContentRegistry.is_valid, "game content validates at boot")
		var player := main.get_node_or_null("Player") as FirstPersonController
		check(player != null and player.input_enabled, "player controller spawned with control")
		if player != null:
			var start := player.global_position
			Input.action_press("move_forward")
			for i in 45:
				await get_tree().physics_frame
			Input.action_release("move_forward")
			check(player.global_position.distance_to(start) > 0.5, "player movement: walks forward")
		var interactables := main.find_children("*", "Interactable", true, false)
		check(interactables.size() >= 5, "world contains interactables (%d)" % interactables.size())
		var door: Interactable = null
		for node in interactables:
			if (node as Interactable).interactable_id.begins_with("door_"):
				door = node
				break
		check(door != null, "world contains an interactable door")
		if door != null and player != null:
			var heard: Array[String] = []
			var on_interacted := func(id: String) -> void: heard.append(id)
			EventBus.interacted.connect(on_interacted)
			door.interact(player)
			EventBus.interacted.disconnect(on_interacted)
			check(heard == [door.interactable_id], "world object interaction reaches EventBus")
		main.queue_free()
		await get_tree().process_frame
	GameState.reset()
	SaveManager.reset_all()
	print("QA_RESULT passed=%d failed=%d skipped=0" % [passed, failed])
	get_tree().quit(1 if failed else 0)
