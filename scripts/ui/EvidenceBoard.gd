class_name EvidenceBoard
extends CanvasLayer
## EvidenceBoard: the investigation board (GDD §10), opened with Tab.
##
## Left: every collected clue, with a pin toggle and a Read button that opens
## the document (its paper image when it has one) in the InfoPanel on top. Centre: pinned clues as
## cards; select two and Link (or Unlink) them, and the links are drawn as
## strings between cards. Right: the selected clue's provenance and
## corroborations, and the hypotheses. Arguing a hypothesis succeeds only
## when its clues are pinned and connected on the board, and even then it
## means "supported by the evidence you assembled", never "proven".
## A hypothesis can be set aside (refuted) or proposed by the player from
## selected cards; a wrong one never blocks progress.
## Owns no state: EvidenceManager holds pins, links and hypotheses.

const PANEL_ID: String = "evidence"
const CARD_SIZE: Vector2 = Vector2(230, 96)
const CARD_GAP: Vector2 = Vector2(70, 60)
const PAPER: Color = Color(0.9, 0.87, 0.78)
const STRING_RED: Color = Color(0.78, 0.18, 0.16)
const COLUMNS: int = 3

var is_open: bool = false
## Clue ids selected on the board (at most two).
var selected: Array[String] = []

var _clue_list: VBoxContainer
var _board: Control
var _details: RichTextLabel
var _hypotheses: VBoxContainer
var _feedback: Label
var _new_title: LineEdit
var _close_button: Button
var _view_selected: Button
var _card_positions: Dictionary = {}  ## clue_id -> card centre (board coords)


func _ready() -> void:
	layer = 8
	_build()
	visible = false
	var sources: Dictionary = {"clue_acquired": 1, "clue_pinned": 2, "clues_linked": 3, "hypothesis_updated": 2}
	for signal_name: String in sources:
		EventBus.connect(signal_name, _refresh.unbind(sources[signal_name]))


# --- Panel protocol (Main) ---------------------------------------------------------

func open(_data: Dictionary = {}) -> void:
	visible = true
	is_open = true
	selected.clear()
	_feedback.text = "Pin clues, select two cards and link them. Then argue a hypothesis."
	_refresh()
	_close_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)


# --- Actions (buttons call these; so do tests) -----------------------------------

func toggle_pin(clue_id: String) -> void:
	EvidenceManager.set_pinned(clue_id, not EvidenceManager.is_pinned(clue_id))
	selected.erase(clue_id)
	_refresh()


## Toggles a pinned card's selection; keeps at most the two latest.
func select_card(clue_id: String) -> void:
	if clue_id in selected:
		selected.erase(clue_id)
	else:
		selected.append(clue_id)
		while selected.size() > 2:
			selected.pop_front()
	_refresh()


func link_selected() -> bool:
	if selected.size() != 2:
		_feedback.text = "Select two pinned cards to link."
		return false
	var linked: bool = EvidenceManager.link_clues(selected[0], selected[1])
	_feedback.text = "Linked." if linked else "Those two are already linked."
	_refresh()
	return linked


func unlink_selected() -> bool:
	if selected.size() != 2:
		_feedback.text = "Select two linked cards to unlink."
		return false
	var unlinked: bool = EvidenceManager.unlink_clues(selected[0], selected[1])
	_feedback.text = "Link removed." if unlinked else "Those two are not linked."
	_refresh()
	return unlinked


## Tries to support a hypothesis with the board as it stands.
func argue(hypothesis_id: String) -> bool:
	var hypothesis: Dictionary = EvidenceManager.get_hypothesis(hypothesis_id)
	if EvidenceManager.is_hypothesis_supported_by_board(hypothesis_id):
		EvidenceManager.set_hypothesis_status(hypothesis_id, "supported")
		_feedback.text = "Supported by the evidence you assembled. Still open to other explanations."
		EventBus.notification_requested.emit("Hypothesis supported: " + str(hypothesis["title"]))
		return true
	var missing: Array[String] = []
	for clue_id: String in hypothesis.get("clue_ids", []):
		if not EvidenceManager.has_clue(clue_id):
			missing.append("a clue you have not found yet")
		elif not EvidenceManager.is_pinned(clue_id):
			missing.append("\"%s\" is not pinned" % ContentRegistry.get_clue(clue_id)["title"])
	_feedback.text = ("Not yet: " + "; ".join(missing) + ".") if not missing.is_empty() \
			else "Not yet: the clues it rests on are not all connected on the board."
	return false


func set_aside(hypothesis_id: String) -> void:
	EvidenceManager.set_hypothesis_status(hypothesis_id, "refuted")
	_feedback.text = "Set aside. You can reopen it later."


func reopen(hypothesis_id: String) -> void:
	EvidenceManager.set_hypothesis_status(hypothesis_id, "unresolved")


## Registers a player hypothesis resting on the selected cards. Returns its id or "".
func propose_hypothesis(title: String) -> String:
	if title.strip_edges().is_empty() or selected.is_empty():
		_feedback.text = "Select the cards it rests on and give it a title."
		return ""
	var index: int = 1
	while not EvidenceManager.get_hypothesis("hyp_player_%d" % index).is_empty():
		index += 1
	var hypothesis_id: String = "hyp_player_%d" % index
	EvidenceManager.register_hypothesis(hypothesis_id, title.strip_edges().left(120), selected.duplicate())
	_new_title.text = ""
	_feedback.text = "Hypothesis recorded. Argue it once its clues are connected."
	_refresh()
	return hypothesis_id


## Opens a collected clue's document over the board (InfoPanel draws above it
## and Esc closes it first).
func view_document(clue_id: String) -> void:
	if EvidenceManager.has_clue(clue_id):
		EventBus.ui_panel_requested.emit("info", ClueText.panel_data(clue_id))


func get_feedback() -> String:
	return _feedback.text


func get_card_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_card_positions.keys())
	ids.sort()
	return ids


# --- Rendering ------------------------------------------------------------------

func _refresh() -> void:
	if not is_open:
		return
	selected.assign(selected.filter(func(id: String) -> bool: return EvidenceManager.is_pinned(id)))
	_rebuild_clue_list()
	_rebuild_board()
	_rebuild_hypotheses()
	_details.text = _details_text(selected[-1] if not selected.is_empty() else "")
	_view_selected.visible = not selected.is_empty()


func _rebuild_clue_list() -> void:
	_clear(_clue_list)
	var acquired: Array[String] = EvidenceManager.get_acquired_ids()
	if acquired.is_empty():
		_clue_list.add_child(UIStyle.label("Nothing collected yet. Documents, records and logs you find appear here.", 16, UIStyle.MUTED))
	for clue_id: String in acquired:
		var pin: CheckBox = CheckBox.new()
		pin.name = "Pin_" + clue_id
		pin.text = ContentRegistry.get_clue(clue_id)["title"]
		pin.button_pressed = EvidenceManager.is_pinned(clue_id)
		pin.add_theme_font_size_override("font_size", 16)
		pin.toggled.connect(func(_on: bool) -> void: toggle_pin(clue_id))
		pin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row: HBoxContainer = HBoxContainer.new()
		row.add_child(pin)
		var read: Button = UIStyle.secondary_button("Read", 16)
		read.name = "View_" + clue_id
		read.tooltip_text = "Show the document"
		read.pressed.connect(func() -> void: view_document(clue_id))
		row.add_child(read)
		_clue_list.add_child(row)


func _rebuild_board() -> void:
	_clear(_board)
	_card_positions.clear()
	var pinned: Array[String] = EvidenceManager.get_acquired_ids().filter(
			func(id: String) -> bool: return EvidenceManager.is_pinned(id))
	for i: int in pinned.size():
		var clue_id: String = pinned[i]
		var clue: Dictionary = ContentRegistry.get_clue(clue_id)
		var card: Button = Button.new()
		card.name = "Card_" + clue_id
		card.toggle_mode = true
		card.button_pressed = clue_id in selected
		card.text = "%s\n%s" % [clue["title"], UIStyle.humanize(clue["provenance"])]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_font_size_override("font_size", 16)
		for state: String in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
			card.add_theme_color_override(state, Color(0.12, 0.1, 0.08))
		card.add_theme_stylebox_override("normal", _card_style(false))
		card.add_theme_stylebox_override("hover", _card_style(false))
		card.add_theme_stylebox_override("pressed", _card_style(true))
		card.add_theme_stylebox_override("hover_pressed", _card_style(true))
		card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		card.size = CARD_SIZE
		card.position = Vector2(i % COLUMNS, i / COLUMNS) * (CARD_SIZE + CARD_GAP) + Vector2(20, 20)
		card.pressed.connect(func() -> void: select_card(clue_id))
		_board.add_child(card)
		_card_positions[clue_id] = card.position + CARD_SIZE / 2.0
	_board.queue_redraw()


## Opaque paper cards; selected ones get a red border.
func _card_style(selected_card: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(2)
	style.set_content_margin_all(8)
	style.set_border_width_all(4 if selected_card else 1)
	style.border_color = STRING_RED if selected_card else Color(0.5, 0.46, 0.38)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 4
	return style


## Strings run between card centres; the opaque cards hide the ends.
func _draw_links() -> void:
	for pair: PackedStringArray in EvidenceManager.get_links():
		if _card_positions.has(pair[0]) and _card_positions.has(pair[1]):
			_board.draw_line(_card_positions[pair[0]], _card_positions[pair[1]], STRING_RED, 3.0, true)


func _rebuild_hypotheses() -> void:
	_clear(_hypotheses)
	var ids: Array[String] = ContentRegistry.get_hypothesis_ids()
	var index: int = 1
	while not EvidenceManager.get_hypothesis("hyp_player_%d" % index).is_empty():
		ids.append("hyp_player_%d" % index)
		index += 1
	for hypothesis_id: String in ids:
		var hypothesis: Dictionary = EvidenceManager.get_hypothesis(hypothesis_id)
		var box: VBoxContainer = VBoxContainer.new()
		box.add_child(UIStyle.label("%s  [%s]" % [hypothesis["title"], hypothesis["status"]], 17))
		var rests_on: Array = Array(hypothesis["clue_ids"]).map(func(id: String) -> String:
			return ContentRegistry.get_clue(id)["title"] if EvidenceManager.has_clue(id) else "(not yet found)")
		box.add_child(UIStyle.label("Rests on: " + ", ".join(rests_on), 15, UIStyle.MUTED))
		var authored: Dictionary = ContentRegistry.get_hypothesis(hypothesis_id)
		if authored.has("alternate_explanations"):
			box.add_child(UIStyle.label("Other explanations to rule out: " + ", ".join(
					Array(authored["alternate_explanations"]).map(UIStyle.humanize)), 15, UIStyle.MUTED))
		var row: HBoxContainer = HBoxContainer.new()
		var argue_button: Button = UIStyle.button("Argue from the board")
		argue_button.name = "Argue_" + hypothesis_id
		argue_button.pressed.connect(func() -> void: argue(hypothesis_id))
		row.add_child(argue_button)
		var status_button: Button = UIStyle.button("Reopen" if hypothesis["status"] != "unresolved" else "Set aside")
		status_button.pressed.connect(func() -> void:
			if hypothesis["status"] == "unresolved":
				set_aside(hypothesis_id)
			else:
				reopen(hypothesis_id))
		row.add_child(status_button)
		box.add_child(row)
		_hypotheses.add_child(box)
		_hypotheses.add_child(HSeparator.new())


func _details_text(clue_id: String) -> String:
	if clue_id.is_empty():
		return "[color=#%s]Select a card to see where it came from.[/color]" % UIStyle.MUTED.to_html(false)
	var clue: Dictionary = ContentRegistry.get_clue(clue_id)
	var acquisition: Dictionary = EvidenceManager.get_acquisition(clue_id)
	var lines: PackedStringArray = ["[b]%s[/b]" % clue["title"], ClueText.describe(clue), ""]
	lines.append("Obtained: %s, %s" % [UIStyle.humanize(str(acquisition.get("method", "")).replace(":", ": ")),
			TimeManager.format_minutes(int(acquisition.get("at_minutes", 0)))])
	var verifications: Array = EvidenceManager.get_verifications(clue_id)
	if verifications.is_empty():
		lines.append("Corroboration: none yet.")
	for verification: Dictionary in verifications:
		lines.append("Corroborated by %s, %s" % [UIStyle.humanize(str(verification["method"]).replace(":", ": ")),
				TimeManager.format_minutes(int(verification["at_minutes"]))])
	return "\n".join(lines)


# --- Construction ------------------------------------------------------------------

func _build() -> void:
	var root: Control = UIStyle.make_root(self, 0.6)
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	panel.anchor_left = 0.03
	panel.anchor_top = 0.05
	panel.anchor_right = 0.97
	panel.anchor_bottom = 0.95
	root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var top: HBoxContainer = HBoxContainer.new()
	var title: Label = UIStyle.label("Evidence Board", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_close_button = UIStyle.button("Close  (Tab / Esc)")
	_close_button.pressed.connect(close)
	top.add_child(_close_button)
	column.add_child(top)
	_feedback = UIStyle.label("", 16, UIStyle.WARNING)
	column.add_child(_feedback)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)

	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size.x = 250
	left.add_child(UIStyle.label("Collected (tick to pin)", 17, UIStyle.MUTED))
	_clue_list = VBoxContainer.new()
	left.add_child(_clue_list)
	row.add_child(left)

	var centre: VBoxContainer = VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_stretch_ratio = 1.6
	var board_frame: PanelContainer = PanelContainer.new()
	var cork: StyleBoxFlat = UIStyle.panel_style(1.0)
	cork.bg_color = Color(0.17, 0.15, 0.12)
	board_frame.add_theme_stylebox_override("panel", cork)
	board_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board = Control.new()
	_board.clip_contents = true
	_board.draw.connect(_draw_links)
	board_frame.add_child(_board)
	centre.add_child(board_frame)
	var actions: HBoxContainer = HBoxContainer.new()
	var link: Button = UIStyle.button("Link selected")
	link.pressed.connect(func() -> void: link_selected())
	actions.add_child(link)
	var unlink: Button = UIStyle.button("Unlink selected")
	unlink.pressed.connect(func() -> void: unlink_selected())
	actions.add_child(unlink)
	_new_title = LineEdit.new()
	_new_title.placeholder_text = "New hypothesis from selected cards…"
	_new_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_title.text_submitted.connect(func(text: String) -> void: propose_hypothesis(text))
	actions.add_child(_new_title)
	var propose: Button = UIStyle.button("Propose")
	propose.pressed.connect(func() -> void: propose_hypothesis(_new_title.text))
	actions.add_child(propose)
	centre.add_child(actions)
	row.add_child(centre)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details = UIStyle.rich_text()
	_details.custom_minimum_size.y = 200
	right.add_child(_details)
	_view_selected = UIStyle.secondary_button("Read this document", 17)
	_view_selected.name = "ViewSelected"
	_view_selected.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_view_selected.visible = false
	_view_selected.pressed.connect(func() -> void:
		if not selected.is_empty():
			view_document(selected[-1]))
	right.add_child(_view_selected)
	right.add_child(UIStyle.label("Hypotheses", 18, UIStyle.MUTED))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_hypotheses = VBoxContainer.new()
	_hypotheses.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_hypotheses)
	right.add_child(scroll)
	row.add_child(right)


func _clear(container: Control) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
