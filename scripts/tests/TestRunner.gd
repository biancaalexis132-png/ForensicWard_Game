extends Node
## TestRunner: discovers and runs all test_*.gd files in this folder.
##
## Editor: open scripts/tests/TestRunner.tscn and press F6 (macOS: Cmd + R).
##         Results appear in the Output panel and on screen.
## Terminal (macOS):
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://scripts/tests/TestRunner.tscn
##   Exit code 0 = all passed, 1 = failures.

const TEST_DIR: String = "res://scripts/tests"

var _passed: int = 0
var _failed: int = 0
var _lines: PackedStringArray = []


func _ready() -> void:
	# Wait one frame so autoloads and the tree are fully settled.
	await get_tree().process_frame
	for file_name: String in _test_files():
		await _run_file(file_name)
	var summary: String = "%s: %d passed, %d failed" % ["PASSED" if _failed == 0 else "FAILED", _passed, _failed]
	_log("\n" + summary)
	SaveManager.reset_all()
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0 if _failed == 0 else 1)
	else:
		_show_on_screen(summary)


func _test_files() -> Array[String]:
	var files: Array[String] = []
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		# Exported/imported projects may list .gd.remap; only plain scripts here.
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			files.append(file_name)
	files.sort()
	return files


func _run_file(file_name: String) -> void:
	var script: GDScript = load("%s/%s" % [TEST_DIR, file_name])
	# A test file that fails to parse must fail the run, not be skipped.
	if script == null or not script.can_instantiate():
		_failed += 1
		_log("\n[%s]\n  FAIL (script did not load)" % file_name)
		return
	var test: TestCase = script.new()
	test.runner = self
	_log("\n[%s]" % file_name)
	var methods: Array[String] = []
	for method: Dictionary in script.get_script_method_list():
		if str(method["name"]).begins_with("test_"):
			methods.append(method["name"])
	methods.sort()
	for method: String in methods:
		test.before_each()
		await test.call(method)
		test.after_each()
		var failures: Array[String] = test.take_failures()
		if failures.is_empty():
			_passed += 1
			_log("  PASS %s" % method)
		else:
			_failed += 1
			_log("  FAIL %s" % method)
			for failure: String in failures:
				_log("       - " + failure)


func _log(line: String) -> void:
	print(line)
	_lines.append(line)


func _show_on_screen(summary: String) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	var label: RichTextLabel = RichTextLabel.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 24
	label.offset_top = 24
	label.add_theme_font_size_override("normal_font_size", 18)
	label.text = summary + "\n" + "\n".join(_lines)
	label.add_theme_color_override("default_color", Color.LIME_GREEN if _failed == 0 else Color.ORANGE_RED)
	layer.add_child(label)
	add_child(layer)
