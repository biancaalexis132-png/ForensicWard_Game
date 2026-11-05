class_name ProtagonistScreen
extends CanvasLayer
## "Choose your psychiatrist": the character creator. New Game opens it before the
## shift starts (mode "new_game"); it can also open on its own to edit the profile.
## Female or male picks the model and the psychiatrist's recorded voice; style
## choices dress the model in the live preview. Identity and presentation only:
## every choice keeps the same professional competence.

const PANEL_ID: String = "protagonist"
## Psychiatrist lines the "Hear voice" button plays, in turn.
const VOICE_SAMPLES: Array[String] = ["ch1_b2_player_001", "ch1_b2_player_002", "ch1_int_elias_ask_intake"]
## Appearance fields shown as rows of choices, with their catalogs and headings.
const STYLE_ROWS: Array = [
	["skin_tone", "skin_tones", "Skin tone"],
	["hair_style", "hair_styles", "Hairstyle"],
	["hair_color", "hair_colors", "Hair colour"],
	["glasses", "glasses", "Glasses"],
	["top", "tops", "Shirt"],
	["outfit", "outfits", "Trousers"],
]
const BACKGROUND_FIELDS: Dictionary = {"professional_interest": "professional_interests",
		"acceptance_reason": "acceptance_reasons", "relationship": "relationships"}
const FIELD_LABELS: Dictionary = {"name": "Name", "pronouns": "Pronouns", "personal_history": "Personal history",
		"professional_interest": "Professional interest", "acceptance_reason": "Why you took the post",
		"relationship": "Life outside work"}

var is_open: bool = false
## Text and drop-down fields by profile key (LineEdit or OptionButton).
var _fields: Dictionary = {}
## Choice rows by profile key: option id -> its toggle Button.
var _choices: Dictionary = {}
var _draft: Dictionary = {}
var _mode: String = ""
var _on_confirm: Callable = Callable()
var _status: Label
var _voice_note: Label
var _confirm_button: Button
var _cancel_button: Button
var _preview: ProtagonistPreview
var _name_field: LineEdit
var _voice_player: AudioStreamPlayer
var _sample_index: int = 0
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_random.randomize()
	var backdrop: Control = UIStyle.make_root(self, 0.82)
	var root: PanelContainer = PanelContainer.new()
	root.add_theme_stylebox_override("panel", UIStyle.panel_style())
	backdrop.add_child(root)
	root.anchor_left = 0.5
	root.anchor_right = 0.5
	root.anchor_top = 0.5
	root.anchor_bottom = 0.5
	root.offset_left = -700
	root.offset_right = 700
	root.offset_top = -420
	root.offset_bottom = 420
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	root.add_child(box)
	box.add_child(UIStyle.label("Choose your psychiatrist", 30))
	var help: Label = UIStyle.label("Pick who walks onto the ward, then dress them your way. Female or male sets the body and the voice you hear in conversations. Every choice keeps the same professional competence.", 17, UIStyle.MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(help)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	row.add_child(_build_preview_column())
	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	right.add_child(_build_body_choice())
	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(tabs)
	var style: Control = _build_style_tab()
	style.name = "Style"
	tabs.add_child(style)
	var identity: Control = _build_identity_tab()
	identity.name = "Name and background"
	tabs.add_child(identity)
	_status = UIStyle.label("", 16, UIStyle.MUTED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	_confirm_button = UIStyle.primary_button("Confirm")
	_confirm_button.pressed.connect(confirm)
	buttons.add_child(_confirm_button)
	_cancel_button = UIStyle.secondary_button("Cancel")
	_cancel_button.pressed.connect(close)
	buttons.add_child(_cancel_button)
	var surprise: Button = UIStyle.secondary_button("Surprise me")
	surprise.tooltip_text = "Random skin tone, hair, glasses and clothes. The body and voice stay as chosen."
	surprise.pressed.connect(randomize_style)
	buttons.add_child(surprise)
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Voice"
	add_child(_voice_player)


func _build_preview_column() -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_preview = ProtagonistPreview.new()
	_preview.custom_minimum_size = Vector2(440, 560)
	_preview.tooltip_text = "Drag to turn"
	column.add_child(_preview)
	var controls: HBoxContainer = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	column.add_child(controls)
	var left: Button = UIStyle.secondary_button("◀")
	left.tooltip_text = "Turn left"
	left.pressed.connect(func() -> void: _preview.turn(-PI / 6.0))
	controls.add_child(left)
	var right: Button = UIStyle.secondary_button("▶")
	right.tooltip_text = "Turn right"
	right.pressed.connect(func() -> void: _preview.turn(PI / 6.0))
	controls.add_child(right)
	var view: Button = UIStyle.secondary_button("Face")
	view.pressed.connect(func() -> void:
		_preview.framing = "face" if _preview.framing == "body" else "body"
		view.text = "Full body" if _preview.framing == "face" else "Face")
	controls.add_child(view)
	var hear: Button = UIStyle.secondary_button("Hear voice")
	hear.pressed.connect(play_voice_sample)
	controls.add_child(hear)
	return column


func _build_body_choice() -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.card_style(UIStyle.ACCENT))
	var box: VBoxContainer = VBoxContainer.new()
	card.add_child(box)
	box.add_child(UIStyle.label("Psychiatrist", 19, UIStyle.ACCENT))
	var cards: HBoxContainer = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	box.add_child(cards)
	var group: ButtonGroup = ButtonGroup.new()
	_choices["gender"] = {}
	for id: String in ProtagonistProfile.options.get("genders", {}):
		var name_text: String = str(ProtagonistProfile.options["genders"][id])
		var button: Button = _text_choice("%s psychiatrist\n%s voice" % [name_text, name_text.to_lower()], 18)
		button.button_group = group
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(choose.bind("gender", id))
		cards.add_child(button)
		_choices["gender"][id] = button
	_voice_note = UIStyle.label("", 15, UIStyle.MUTED)
	_voice_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_voice_note)
	return card


func _build_style_tab() -> Control:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	for spec: Array in STYLE_ROWS:
		var field: String = spec[0]
		box.add_child(UIStyle.label(spec[2], 17, UIStyle.TEXT))
		var flow: HFlowContainer = HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 6)
		box.add_child(flow)
		var group: ButtonGroup = ButtonGroup.new()
		_choices[field] = {}
		var catalog: Dictionary = ProtagonistProfile.options.get(spec[1], {})
		for id: String in catalog:
			var value: String = str(catalog[id])
			var button: Button = _swatch(Color(value), UIStyle.humanize(id)) if value.begins_with("#") else _text_choice(value)
			button.button_group = group
			button.pressed.connect(choose.bind(field, id))
			flow.add_child(button)
			_choices[field][id] = button
	return scroll


func _build_identity_tab() -> Control:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for field: String in ["name", "pronouns", "personal_history"]:
		grid.add_child(UIStyle.label(FIELD_LABELS[field], 17))
		var edit: LineEdit = LineEdit.new()
		edit.max_length = 64 if field == "name" else (32 if field == "pronouns" else 512)
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.placeholder_text = {"name": "Dr …", "pronouns": "for example she/her, he/him, they/them", "personal_history": "Optional"}[field]
		grid.add_child(edit)
		_fields[field] = edit
		edit.text_changed.connect(func(value: String) -> void:
			_draft[field] = value
			if field == "pronouns":
				_follow_pronouns(value))
	_name_field = _fields["name"]
	for field: String in BACKGROUND_FIELDS:
		grid.add_child(UIStyle.label(FIELD_LABELS[field], 17))
		var select: OptionButton = OptionButton.new()
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for id: String in ProtagonistProfile.options[BACKGROUND_FIELDS[field]]:
			select.add_item(str(ProtagonistProfile.options[BACKGROUND_FIELDS[field]][id]))
			select.set_item_metadata(select.item_count - 1, id)
		grid.add_child(select)
		_fields[field] = select
		select.item_selected.connect(func(index: int) -> void: _draft[field] = select.get_item_metadata(index))
	return scroll


func _swatch(colour: Color, tip: String) -> Button:
	var button: Button = Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(46, 46)
	button.tooltip_text = tip
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = colour
		style.set_corner_radius_all(23)
		var selected: bool = state.contains("pressed")
		style.border_color = UIStyle.ACCENT if selected else (Color(1, 1, 1, 0.55) if state == "hover" else Color(0, 0, 0, 0.4))
		style.set_border_width_all(4 if selected else 2)
		if state == "focus":
			style.bg_color = Color(0, 0, 0, 0)
			style.border_color = Color(1, 1, 1, 0.7)
		button.add_theme_stylebox_override(state, style)
	return button


func _text_choice(text: String, font_size: int = 16) -> Button:
	var button: Button = Button.new()
	button.toggle_mode = true
	button.text = text
	button.custom_minimum_size = Vector2(0, 40)
	button.add_theme_font_size_override("font_size", font_size)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		var selected: bool = state.contains("pressed")
		style.bg_color = Color(UIStyle.ACCENT, 0.22) if selected else (Color(1, 1, 1, 0.08) if state == "hover" else UIStyle.CARD)
		style.border_color = UIStyle.ACCENT if selected else Color(1, 1, 1, 0.16)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_pressed_color", UIStyle.TEXT)
	button.add_theme_color_override("font_hover_pressed_color", UIStyle.TEXT)
	return button


## mode "new_game": the button reads "Begin the shift" and `on_confirm` runs after
## the profile is saved. Any other call edits the profile and returns.
func open(data: Dictionary = {}) -> void:
	_mode = str(data.get("mode", ""))
	_on_confirm = data.get("on_confirm", Callable()) if data.get("on_confirm") is Callable else Callable()
	_confirm_button.text = "Begin the shift" if _mode == "new_game" else "Confirm"
	_cancel_button.text = "Back" if _mode == "new_game" else "Cancel"
	_draft = ProtagonistProfile.get_profile()
	for field: String in _fields:
		if _fields[field] is LineEdit:
			_fields[field].text = str(_draft[field])
		else:
			var select: OptionButton = _fields[field]
			for index: int in select.item_count:
				if select.get_item_metadata(index) == _draft[field]:
					select.select(index)
	_sync_choices()
	_status.text = "Optional: leave the name and background blank if you like. Signed chart entries keep their original author.\nRecorded choices: %d. No permanent personality class is assigned." % _draft["choices"].size()
	_refresh_preview()
	visible = true
	is_open = true
	_name_field.grab_focus()


## Selects option `id` for a choice row (body/voice or a style row).
func choose(field: String, id: String) -> void:
	if not _choices.has(field) or not _choices[field].has(id):
		return
	_draft[field] = id
	_mark(field, id)
	if field == "gender":
		_voice_player.stop()
		_update_voice_note()
	_refresh_preview()


## The option ids a choice row offers, in order.
func option_ids(field: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in _choices.get(field, {}):
		ids.append(id)
	return ids


func selected(field: String) -> String:
	return str(_draft.get(field, ""))


## Random style, keeping the chosen body, voice and identity.
func randomize_style() -> void:
	for spec: Array in STYLE_ROWS:
		var ids: Array[String] = option_ids(spec[0])
		if not ids.is_empty():
			choose(spec[0], ids[_random.randi_range(0, ids.size() - 1)])


## Plays a short psychiatrist line in the voice the draft would use.
func play_voice_sample() -> void:
	var line_id: String = VOICE_SAMPLES[_sample_index % VOICE_SAMPLES.size()]
	_sample_index += 1
	var variant: String = "female" if selected("gender") == "female" else ""
	var path: String = AudioDirector.get_voice_path_for_variant(line_id, variant)
	var text: String = str(AudioDirector.get_line(line_id).get("text", ""))
	if path.is_empty():
		_voice_note.text = "No recording for that line yet."
		return
	_voice_player.stream = load(path)
	_voice_player.play()
	_voice_note.text = "“%s”  (%s voice)" % [text, "female" if variant == "female" else "male"]


func _sync_choices() -> void:
	for field: String in _choices:
		_mark(field, str(_draft.get(field, "")))
	_update_voice_note()


## Shows `id` as the one selected option in its row.
func _mark(field: String, id: String) -> void:
	for option: String in _choices.get(field, {}):
		(_choices[field][option] as Button).set_pressed_no_signal(option == id)


func _update_voice_note() -> void:
	var female: bool = selected("gender") == "female"
	_voice_note.text = "Your psychiatrist speaks with the %s voice in every conversation. Press Hear voice to listen." % ("female" if female else "male")


func _refresh_preview() -> void:
	_preview.show_profile(_draft, ProtagonistProfile.options)


## Typing she/her or he/him picks the matching body and voice, so they follow the
## character without a second step. The choice can still be changed after.
func _follow_pronouns(pronouns: String) -> void:
	var first: String = pronouns.strip_edges().to_lower().get_slice("/", 0).strip_edges()
	var gender: String = {"she": "female", "her": "female", "he": "male", "him": "male"}.get(first, "")
	if gender.is_empty() or _draft.get("gender") == gender:
		return
	choose("gender", gender)


func confirm() -> void:
	if ProtagonistProfile.apply_draft(_draft):
		var then: Callable = _on_confirm
		close()
		if then.is_valid():
			then.call()
	else:
		_status.text = "Check the entered details before confirming."


func close() -> void:
	if not is_open:
		return
	_voice_player.stop()
	visible = false
	is_open = false
	_on_confirm = Callable()
	EventBus.ui_panel_closed.emit(PANEL_ID)


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
