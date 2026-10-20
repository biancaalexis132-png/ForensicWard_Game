class_name PracticeScreen
extends CanvasLayer
const PANEL_ID: String = "continuing_practice"
var is_open: bool = false
var _body: RichTextLabel
var _status: Label
var _accept: Button
var _case_id: String = "cp_001"
var _task_description: LineEdit
var _task_owner: LineEdit
var _review_point: LineEdit
var _tasks: VBoxContainer

func _ready() -> void:
	layer = 12
	visible = false
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(210, 65)
	panel.custom_minimum_size = Vector2(1300, 850)
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	panel.add_child(box)
	_status = Label.new()
	box.add_child(_status)
	var tabs: HBoxContainer = HBoxContainer.new()
	box.add_child(tabs)
	for i: int in 5:
		var button: Button = Button.new()
		button.text = "Encounter %d" % (i + 1)
		tabs.add_child(button)
		button.pressed.connect(_show_encounter.bind(i))
	_body = RichTextLabel.new()
	_body.custom_minimum_size = Vector2(1220, 370)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_body)
	_tasks = VBoxContainer.new()
	box.add_child(_tasks)
	var task_fields: HBoxContainer = HBoxContainer.new()
	box.add_child(task_fields)
	_task_description = _edit(task_fields, "Follow-up task")
	_task_owner = _edit(task_fields, "Responsible role")
	_review_point = _edit(task_fields, "Next review point")
	var add: Button = Button.new()
	add.text = "Add follow-up"
	task_fields.add_child(add)
	add.pressed.connect(_add_task)
	var row: HBoxContainer = HBoxContainer.new()
	box.add_child(row)
	_accept = _button(row, "Accept case", _accept_case)
	_button(row, "Begin / resume interview", _begin_interview)
	_button(row, "Open patient chart", _open_chart)
	_button(row, "Complete encounter", _finish_encounter)
	_button(row, "Hold / resume", _toggle_hold)
	_button(row, "Next shift", _next_shift)
	_button(row, "Close", close)

func _edit(parent: Node, placeholder: String) -> LineEdit:
	var edit: LineEdit = LineEdit.new()
	edit.placeholder_text = placeholder
	edit.max_length = 512
	edit.custom_minimum_size.x = 260
	parent.add_child(edit)
	return edit

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func open(_data: Dictionary = {}) -> void:
	visible = true
	is_open = true
	_refresh()
	_show_encounter(0)

func _refresh() -> void:
	var case: PracticeCase = ContinuingPractice.get_case(_case_id)
	if case == null:
		_status.text = "No follow-up case available."
		_accept.disabled = true
		return
	var state: Dictionary = case.to_save_data()
	var pending: bool = not case.ready_for_play()
	_accept.disabled = pending or state["status"] != "available"
	_status.text = "%s · %s\n%s" % [case.definition["title"], state["status"].capitalize(),
			"Awaiting clinical review. Encounter drafts are available for review; clinical play is disabled." if pending else "Signed notes and completed interviews are required. Handoff acknowledgment does not resolve a clinical concern."]
	for node: Node in _tasks.get_children():
		_tasks.remove_child(node)
		node.queue_free()
	for task: Dictionary in state["tasks"]:
		var row: HBoxContainer = HBoxContainer.new()
		_tasks.add_child(row)
		var label: Label = Label.new()
		label.text = "%s · %s · %s · %s" % [task["description"], task["owner"], task["review_point"], task["status"]]
		row.add_child(label)
		for status: String in ["handoff_pending", "handoff_acknowledged", "completed"]:
			_button(row, status.capitalize(), func() -> void:
				case.update_task(task["id"], status)
				_refresh())

func _show_encounter(index: int) -> void:
	var definition: Dictionary = ContinuingPractice.get_definition(_case_id)
	_body.clear()
	if definition.is_empty():
		return
	var encounter: Dictionary = definition["encounters"][index]
	_body.add_text("%s\nClinical review: %s\n\n%s" % [encounter["title"], encounter["clinical_review_status"], encounter["review_text"]])

func _accept_case() -> void:
	if not ContinuingPractice.accept_case(_case_id):
		_status.text = "This optional case requires campaign completion and reviewed clinical content."
	else:
		_refresh()

func _finish_encounter() -> void:
	var case: PracticeCase = ContinuingPractice.get_case(_case_id)
	if case != null and case.finish_encounter():
		_refresh()
	else:
		_status.text = "Complete the interview and signed note, and account for every follow-up task first."

func _add_task() -> void:
	var case: PracticeCase = ContinuingPractice.get_case(_case_id)
	if case != null:
		var id: String = "task_%d" % (case.to_save_data()["tasks"].size() + 1)
		if case.add_task(id, _task_description.text, _task_owner.text, _review_point.text):
			_task_description.clear()
			_refresh()

func _toggle_hold() -> void:
	var case: PracticeCase = ContinuingPractice.get_case(_case_id)
	if case != null:
		case.set_hold(case.to_save_data()["status"] != "on_hold")
		_refresh()

func _next_shift() -> void:
	var case: PracticeCase = ContinuingPractice.get_case(_case_id)
	if case == null or not case.ready_for_play() or case.to_save_data()["status"] == "available":
		return
	if ContinuingPractice.can_close_shift():
		TimeManager.advance_to_next_shift()
		_refresh()
	else:
		_status.text = "The shift cannot close with unaccounted follow-up or an unfinished assessment."

func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)


func _begin_interview() -> void:
	var case: PracticeCase = ContinuingPractice.get_case(_case_id)
	if case == null or not case.ready_for_play() or case.to_save_data()["status"] not in ["accepted", "active"]:
		return
	var patient_id: String = case.definition["patient"]["id"]
	close()
	EventBus.ui_panel_requested.emit("interview", {"patient_id": patient_id, "text_only": true})

func _open_chart() -> void:
	var case: PracticeCase = ContinuingPractice.get_case(_case_id)
	if case == null or not case.ready_for_play() or case.to_save_data()["status"] == "available":
		return
	close()
	EventBus.ui_panel_requested.emit("ehr", {"patient_id": case.definition["patient"]["id"]})
