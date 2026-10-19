extends Node
## Focused narration suite; full TestRunner still discovers the same tests.
func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await get_tree().process_frame
	var host: Node = Node.new()
	add_child(host)
	var test: TestCase = load("res://scripts/tests/test_narration.gd").new()
	test.runner = host
	var passed: int = 0
	var failed: int = 0
	for method: Dictionary in test.get_script().get_script_method_list():
		var name: String = str(method["name"])
		if not name.begins_with("test_"):
			continue
		test.before_each()
		await test.call(name)
		test.after_each()
		await get_tree().process_frame
		var failures: Array[String] = test.take_failures()
		if failures.is_empty():
			passed += 1
			print("PASS ", name)
		else:
			failed += 1
			print("FAIL ", name, " ", failures)
	AudioDirector.stop_narration()
	AudioDirector.stop_dialogue()
	AudioDirector.clear_music_contexts()
	for player: Node in AudioDirector.find_children("*", "", true, false):
		if player is AudioStreamPlayer or player is AudioStreamPlayer3D:
			player.call("stop")
			player.set("stream", null)
	test = null
	host.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	print("NARRATION_RESULT passed=%d failed=%d" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)
