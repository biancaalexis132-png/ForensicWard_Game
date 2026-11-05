extends TestCase
## Smooth transitions: a newly opened panel or the pause menu eases in, a panel
## already open only fades its new text, subtitles ease in from empty, and
## reduce_motion turns every fade off. Input and visibility never wait.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"

var _main: Main


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	Settings.set_value("reduce_motion", Settings.DEFAULTS["reduce_motion"])
	AudioDirector.cancel_pending_events()
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func _info() -> InfoPanel:
	return _main.get_node("InfoPanel")


func _root(layer: Node) -> Control:
	return layer.get_node("Root")


func _wait(seconds: float) -> void:
	await runner.get_tree().create_timer(seconds, true).timeout


func test_new_panel_fades_in_but_is_usable_at_once() -> void:
	await runner.get_tree().process_frame
	EventBus.ui_panel_requested.emit("info", {"title": "T", "body": "B"})
	check(_info().is_open and _info().visible, "open and visible immediately")
	check(_root(_info()).modulate.a < 0.5, "starts transparent: %s" % _root(_info()).modulate.a)
	check(not (_main.get_node("Player") as FirstPersonController).input_enabled, "player frozen at once")
	await _wait(0.4)
	check_eq(_root(_info()).modulate.a, 1.0, "fully shown after the fade")


func test_open_panel_only_fades_its_new_text() -> void:
	await runner.get_tree().process_frame
	EventBus.ui_panel_requested.emit("info", {"title": "T", "body": "First"})
	await _wait(0.4)
	EventBus.ui_panel_requested.emit("info", {"title": "T", "body": "Second"})
	check_eq(_root(_info()).modulate.a, 1.0, "the panel itself does not flash")
	var body: RichTextLabel = _info().get_node("Root/Panel/Margin/VBox/Body")
	check(body.modulate.a < 0.5, "the new text eases in")
	await _wait(0.4)
	check_eq(body.modulate.a, 1.0, "text fully shown")


func test_pause_menu_fades_in_while_paused() -> void:
	await runner.get_tree().process_frame
	var pause: PauseMenu = _main.get_node("PauseMenu")
	_main.call("_open_pause_menu")
	check(pause.is_open, "open")
	check(_root(pause).modulate.a < 0.5, "starts transparent")
	await _wait(0.4)
	check_eq(_root(pause).modulate.a, 1.0, "fade runs while the tree is paused")
	pause.close()


func test_reduce_motion_turns_fades_off() -> void:
	await runner.get_tree().process_frame
	Settings.set_value("reduce_motion", true)
	EventBus.ui_panel_requested.emit("info", {"title": "T", "body": "B"})
	check_eq(_root(_info()).modulate.a, 1.0, "no fade with reduce motion")
	var hud: Node = _main.get_node("HUD")
	EventBus.subtitle_shown.emit("x", "Hale", "Line.", 1.0)
	check_eq((hud.get("_subtitle") as Label).modulate.a, 1.0, "subtitle shown at once")


func test_subtitle_eases_in_from_empty() -> void:
	await runner.get_tree().process_frame
	var subtitle: Label = _main.get_node("HUD").get("_subtitle")
	EventBus.subtitle_shown.emit("x", "Hale", "Line.", 1.0)
	check(subtitle.text != "", "text set at once")
	check(subtitle.modulate.a < 0.5, "eases in")
	await _wait(0.3)
	check_eq(subtitle.modulate.a, 1.0, "fully shown")
