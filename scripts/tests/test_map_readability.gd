extends TestCase
## Map readability: M opens and closes the map; the plan says which room you
## are in and who is on this floor, and changes no game state.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"

var _main: Main


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	AudioDirector.cancel_pending_events()
	if is_instance_valid(_main):
		_main.free()
	super.after_each()


func _press(action: String) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


func _plan() -> Dictionary:
	return FloorPlan.snapshot(_main.get_node("World"), _main.get_node("Player"), _main.get_node("ZoneDirector"))


func test_m_opens_and_closes_the_map() -> void:
	await runner.get_tree().process_frame
	_press("map")
	await runner.get_tree().process_frame
	var map: MapScreen = _main.get_node_or_null("MapScreen")
	check(map != null and map.is_open, "M opens the map")
	check(not (_main.get_node("Player") as FirstPersonController).input_enabled, "player frozen")
	_press("map")
	await runner.get_tree().process_frame
	check(not map.is_open, "M closes it")
	check((_main.get_node("Player") as FirstPersonController).input_enabled, "player moves again")


func test_plan_names_your_room_and_the_people_here() -> void:
	await runner.get_tree().process_frame
	var before: Dictionary = SaveManager.capture_state()
	var plan: Dictionary = _plan()
	check_eq(plan["here"], "Clinical Corridor", "you start in the corridor")
	var names: Array = plan["people"].map(func(p: Dictionary) -> String: return p["name"])
	check(names.any(func(n: String) -> bool: return "Naomi Bennett" in n), "Naomi is on the plan: %s" % [names])
	for person: Dictionary in plan["people"]:
		if "Naomi Bennett" in person["name"]:
			check_eq(person["room"], "Nursing Station", "Naomi is at the nursing station")
	var text: String = MapScreen.describe(plan)
	check("You are in: [b]Clinical Corridor[/b]" in text, "says where you are")
	check("Naomi Bennett (Nursing Station)" in text, "says who is where")
	check_eq(SaveManager.capture_state(), before, "reading the plan changes nothing")


func test_room_at_prefers_the_smaller_room() -> void:
	var floors: Array = [{"rect": Rect2(-2, -20, 4, 20), "label": "Corridor"}, {"rect": Rect2(1, -10, 4, 4), "label": "Office"}]
	check_eq(FloorPlan.room_at(floors, Vector2(1.5, -8)), "Office", "the room, not the corridor around it")
	check_eq(FloorPlan.room_at(floors, Vector2(0, -15)), "Corridor", "corridor elsewhere")
	check_eq(FloorPlan.room_at(floors, Vector2(30, 0)), "", "outside every room")


func test_the_map_marks_the_current_objective() -> void:
	await runner.get_tree().process_frame
	var director: ChapterDirector = runner.get_tree().get_first_node_in_group(ChapterDirector.GROUP) as ChapterDirector
	check(director != null, "a chapter is running")
	var before: Dictionary = SaveManager.capture_state()
	var plan: Dictionary = FloorPlan.snapshot(_main.get_node("World"), _main.get_node("Player"), _main.get_node("ZoneDirector"), director)
	var objective: Dictionary = plan["objective"]
	check_eq(str(objective.get("label", "")), CaseFile.objective_place(director), "the star is labelled like the tracker")
	check(objective.has("position") or objective.has("elsewhere") or objective.has("here"), "and says where it is: %s" % [objective])
	var target: Dictionary = CaseFile.objective_target(director)
	if target.has("character") and objective.has("position"):
		for person: Dictionary in plan["people"]:
			if person["id"] == target["character"]:
				check_eq(objective["position"], person["position"], "the star sits on " + person["name"])
	check_eq(SaveManager.capture_state(), before, "marking the objective changes nothing")
	check(_plan()["objective"].is_empty(), "without a director the plan has no objective")


func test_describe_names_the_objective() -> void:
	var plan: Dictionary = {"here": "Clinical Corridor", "people": [],
			"objective": {"label": "With Nurse Naomi Bennett", "position": Vector2.ZERO, "room": "Nursing Station"}}
	check("Objective:[/color] With Nurse Naomi Bennett (Nursing Station)" in MapScreen.describe(plan), "on this floor")
	plan["objective"] = {"label": "At the evidence board", "elsewhere": true}
	check("At the evidence board — not on this floor" in MapScreen.describe(plan), "on another floor")
