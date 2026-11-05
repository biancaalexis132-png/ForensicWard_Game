extends TestCase
## Staff remember earlier choices: an approved line opens the staff member's
## first reply in its chapter when the earlier choice was made, once, and is
## saved; unapproved lines never play.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const LINE: Dictionary = {"id": "ack_test_lobby", "chapter": "ch3", "staff_id": "staff_bennett",
		"when": {"chapter_flag": {"chapter": "ch2", "flag": "ch2_lobby_state_documented"}},
		"text": "Test acknowledgement line.", "approved": true}

var _main: Main


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	Acknowledgements.reload()
	AudioDirector.stop_dialogue()
	AudioDirector.cancel_pending_events()
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func _director() -> ChapterDirector:
	return _main.get_node("ChapterDirector")


func _talk_bennett() -> String:
	var actor: WardCharacter = (_main.get_node("World") as AuthoredWorld).get_character("staff_bennett")
	actor.get_node("Interactable").interact(_main.get_node("Player"))
	var body: String = (_main.get_node("InfoPanel/Root/Panel/Margin/VBox/Body") as RichTextLabel).get_parsed_text()
	(_main.get_node("InfoPanel") as InfoPanel).close()
	return body


func _to_chapter3(with_choice: bool) -> void:
	check(_director().start_chapter("ch2"), "chapter 2")
	if with_choice:
		_director().set_flag("ch2_lobby_state_documented")
	check(_director().start_chapter("ch3"), "chapter 3")


func test_data_is_valid() -> void:
	check_eq(Acknowledgements.validate(), [] as Array[String], "every line names real staff, chapters and choices")


func test_unapproved_lines_never_play() -> void:
	var pending: Array = Acknowledgements.lines().duplicate(true)
	for line: Dictionary in pending:
		line["approved"] = false
	Acknowledgements.override(pending)
	await runner.get_tree().process_frame
	_director().start_chapter("ch2")
	_director().set_flag("ch2_lobby_state_documented")
	_director().start_chapter("ch3")
	check(Acknowledgements.pending(_director(), "staff_bennett").is_empty(), "nothing plays until approved")


func test_approved_line_opens_the_first_reply_once() -> void:
	Acknowledgements.override([LINE])
	await runner.get_tree().process_frame
	_to_chapter3(true)
	var first: String = _talk_bennett()
	check(first.contains("Test acknowledgement line."), "remembered choice opens the reply: " + first)
	check(Acknowledgements.has_played("ack_test_lobby"), "recorded as played")
	check(not _director().has_flag("ack_test_lobby"), "story flags untouched")
	check(not _talk_bennett().contains("Test acknowledgement line."), "not repeated")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check(not _talk_bennett().contains("Test acknowledgement line."), "not repeated after loading")


func test_no_line_without_the_earlier_choice() -> void:
	Acknowledgements.override([LINE])
	await runner.get_tree().process_frame
	_to_chapter3(false)
	check(not _talk_bennett().contains("Test acknowledgement line."), "a choice not made is not remembered")
