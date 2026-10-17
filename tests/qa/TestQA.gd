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
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	var packed := load(main_path) as PackedScene
	check(packed != null, "configured main scene loads")
	if packed != null:
		var main := packed.instantiate()
		add_child(main)
		await get_tree().process_frame
		check(not PharmacologyEngine.get_state("PT-001").is_empty(), "boot admits sample patient")
		var label := main.get_node_or_null("HUD/StatusLabel") as Label
		check(label != null and "PT-001" in label.text, "demo HUD displays admitted patient")
		press(main, KEY_N)
		check(GameState.day == 1 and GameState.shift == "night", "end shift advances day to night")
		press(main, KEY_N)
		check(GameState.day == 2 and GameState.shift == "day", "end shift advances night to next day")
		press(main, KEY_R)
		check(PharmacologyEngine.get_patient("PT-001").doses.get("clozapine") == 300.0, "demo order updates dose")
		press(main, KEY_O)
		check(GameState.objectivity == 90.0, "demo drains objectivity")
		press(main, KEY_P)
		check(GameState.objectivity == 100.0, "demo restores objectivity")
		main.queue_free()
		await get_tree().process_frame
	print("SKIP: player movement — no player controller or scene in this revision")
	print("SKIP: world object interaction — no interactable implementation in this revision")
	print("QA_RESULT passed=%d failed=%d skipped=2" % [passed, failed])
	get_tree().quit(1 if failed else 0)

func press(target: Node, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	target.call("_unhandled_input", event)
