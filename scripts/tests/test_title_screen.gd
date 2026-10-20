extends TestCase
## Title screen: hidden in tests and headless runs, New Game and Continue hand
## control to the game, and opening it writes no game state. Settings, the
## preload and the prologue are covered in test_presentation.gd.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"

var _roots: Array[Node] = []


func after_each() -> void:
	for root: Node in _roots:
		if is_instance_valid(root):
			root.queue_free()
	_roots.clear()
	runner.get_tree().paused = false
	super.after_each()


func test_not_shown_in_tests_or_headless() -> void:
	var main: Node = await _main()
	var title: TitleScreen = main.get_node("TitleScreen")
	check(not TitleScreen.wanted(main), "a Main that is not the running scene skips the title")
	check(not title.is_open, "the title is not open")


func test_new_game_starts_play() -> void:
	var main: Node = await _main()
	var title: TitleScreen = main.get_node("TitleScreen")
	var before: Dictionary = SaveManager.capture_state()
	title.open()
	main.call("_update_input_mode")
	var player: FirstPersonController = main.get_node("Player")
	check(runner.get_tree().paused, "the title pauses the game")
	check(not player.input_enabled, "the player waits behind the title")
	check_eq(SaveManager.capture_state(), before, "opening the title writes no state")
	title.new_game()
	check(not title.is_open, "New Game closes the title")
	check(not runner.get_tree().paused, "the game runs again")
	check(player.input_enabled, "the player can move")


func test_continue_needs_a_save_and_loads_it() -> void:
	var main: Node = await _main()
	var title: TitleScreen = main.get_node("TitleScreen")
	title.save_slot = TEST_SAVE_SLOT
	title.open()
	check(title._continue_button.disabled, "Continue is off with no save")
	title.close()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "a save is written")
	title.open()
	while title.is_loading():  # The buttons wait for the short, bounded preload.
		await runner.get_tree().process_frame
	check(not title._continue_button.disabled, "Continue is on with a save")
	title.continue_game()
	check(not title.is_open, "Continue loads the save and closes the title")


func _main() -> Node:
	var main: Node = load(MAIN_SCENE).instantiate()
	runner.add_child(main)
	_roots.append(main)
	await runner.get_tree().process_frame
	return main
