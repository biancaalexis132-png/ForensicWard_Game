class_name TestCase
extends RefCounted
## Base class for automated tests. TestRunner finds res://scripts/tests/test_*.gd,
## and runs every method whose name starts with "test_", in alphabetical
## order. Before each test, all run state is reset to a fresh game.
## Test methods may `await` (e.g. for physics frames).

const TEST_SAVE_SLOT: int = 99

## The TestRunner node: use for add_child() and get_tree().
var runner: Node = null

var _failures: Array[String] = []


func before_each() -> void:
	Settings.persist = false
	ClinicalRules.build_mode = ClinicalRules.MODE_PROTOTYPE
	SaveManager.reset_all()


func after_each() -> void:
	SaveManager.delete_save(TEST_SAVE_SLOT)


func take_failures() -> Array[String]:
	var result: Array[String] = _failures.duplicate()
	_failures.clear()
	return result


func check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_failures.append("%s (expected %s, got %s)" % [message, var_to_str(expected), var_to_str(actual)])


func check_contains(haystack: Array, needle_fragment: String, message: String) -> void:
	for item: Variant in haystack:
		if needle_fragment in str(item):
			return
	_failures.append("%s: no entry contains \"%s\". Got: %s" % [message, needle_fragment, str(haystack)])


func wait_physics_frames(count: int) -> void:
	for _i: int in count:
		await runner.get_tree().physics_frame
