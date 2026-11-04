class_name ProtagonistScreen
extends CanvasLayer
const PANEL_ID: String = "protagonist"
var is_open: bool = false
var _draft: Dictionary = {}
var _fields: Dictionary = {}
var _status: Label
var _portrait: ProfilePortrait
var _name_field: LineEdit

func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var backdrop: Control = UIStyle.make_root(self, 0.72)
	var root: PanelContainer = PanelContainer.new()
	root.add_theme_stylebox_override("panel", UIStyle.panel_style())
	backdrop.add_child(root)
	root.anchor_left = 0.5
	root.anchor_right = 0.5
	root.anchor_top = 0.5
	root.anchor_bottom = 0.5
	root.offset_left = -580
	root.offset_right = 580
	root.offset_top = -340
	root.offset_bottom = 340
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	root.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	margin.add_child(box)
	var title: Label = Label.new()
	title.text = "Your psychiatrist"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var help: Label = Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "Background and personal history are optional. Every choice retains the same professional competence."
	box.add_child(help)
	var row: HBoxContainer = HBoxContainer.new()
	box.add_child(row)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grid)
	for field: String in ["name", "pronouns", "personal_history"]:
		var label: Label = Label.new()
		label.text = field.capitalize()
		grid.add_child(label)
		var edit: LineEdit = LineEdit.new()
		edit.max_length = 64 if field == "name" else (32 if field == "pronouns" else 512)
		edit.custom_minimum_size.x = 470
		grid.add_child(edit)
		_fields[field] = edit
		edit.text_changed.connect(func(value: String) -> void: _draft[field] = value)
	_name_field = _fields["name"]
	# Gender sets the psychiatrist's voice; free-text pronouns stay a separate field.
	var catalog_fields: Dictionary = {"gender": "genders", "professional_interest": "professional_interests", "acceptance_reason": "acceptance_reasons", "relationship": "relationships", "skin_tone": "skin_tones", "hair_color": "hair_colors", "hair_style": "hair_styles", "outfit": "outfits"}
	for field: String in catalog_fields:
		var label: Label = Label.new()
		label.text = field.capitalize()
		grid.add_child(label)
		var select: OptionButton = OptionButton.new()
		for id: String in ProtagonistProfile.options[catalog_fields[field]]:
			var value: String = str(ProtagonistProfile.options[catalog_fields[field]][id])
			select.add_item(id.capitalize() if value.begins_with("#") else value)
			select.set_item_metadata(select.item_count - 1, id)
		grid.add_child(select)
		_fields[field] = select
		select.item_selected.connect(func(index: int) -> void:
			_draft[field] = select.get_item_metadata(index)
			_refresh_portrait())
	_portrait = ProfilePortrait.new()
	_portrait.custom_minimum_size = Vector2(230, 260)
	row.add_child(_portrait)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	var buttons: HBoxContainer = HBoxContainer.new()
	box.add_child(buttons)
	for label: String in ["Confirm", "Cancel"]:
		var button: Button = Button.new()
		button.text = label
		buttons.add_child(button)
		button.pressed.connect(confirm if label == "Confirm" else close)

func open(_data: Dictionary = {}) -> void:
	_draft = ProtagonistProfile.get_profile()
	for field: String in _fields:
		if _fields[field] is LineEdit:
			_fields[field].text = str(_draft[field])
		else:
			var select: OptionButton = _fields[field]
			for index: int in select.item_count:
				if select.get_item_metadata(index) == _draft[field]:
					select.select(index)
	_status.text = "Optional: leave details blank or cancel. Your signed chart entries retain their original author identity.\nRecorded choices: %d. No permanent personality class is assigned." % _draft["choices"].size()
	_refresh_portrait()
	visible = true
	is_open = true
	_name_field.grab_focus()

func _refresh_portrait() -> void:
	_portrait.draft = _draft.duplicate(true)
	_portrait.queue_redraw()

func confirm() -> void:
	if ProtagonistProfile.apply_draft(_draft):
		close()
	else:
		_status.text = "Check the entered details before confirming."

func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
