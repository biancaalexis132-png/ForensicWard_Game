class_name CaseFileScreen
extends CanvasLayer
## CaseFileScreen: what you know, what is still open and where to go next,
## opened with Tab. Read-only: everything comes from CaseFile, which reads
## ChapterDirector, EvidenceManager and data/case_file.json.
##
## Left: the case notes, newest chapter first, with a filter (All, Still
## open, Established, Care). Right: Now (the current objective and where it
## happens) and Evidence (clues collected, hypotheses and the ordinary
## explanations still open), with buttons to the evidence board and the
## clinical case journal.

const PANEL_ID: String = "case_file"
const FILTERS: Array[String] = ["all", "open", "established", "care"]
const FILTER_LABELS: Dictionary = {"all": "All", "open": "Still open", "established": "Established", "care": "Care"}
const STATUS_COLORS: Dictionary = {"open": UIStyle.WARNING, "established": UIStyle.ACCENT, "care": UIStyle.GOOD}

var is_open: bool = false
var filter: String = "all"

var _notes: VBoxContainer
var _now: RichTextLabel
var _evidence: RichTextLabel
var _filter_buttons: Dictionary = {}
var _close_button: Button
var _title: Label


func _ready() -> void:
	layer = 9
	_build()
	visible = false


func open(_data: Dictionary = {}) -> void:
	visible = true
	is_open = true
	_refresh()
	_close_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)


func set_filter(value: String) -> void:
	if value in FILTERS:
		filter = value
		_refresh()


## Opens another screen in place of this one.
func open_other(panel_id: String) -> void:
	close()
	EventBus.ui_panel_requested.emit(panel_id, {})


# --- Read back (tests, screen readers) -----------------------------------------------

func get_now_text() -> String:
	return _now.get_parsed_text()


func get_evidence_text() -> String:
	return _evidence.get_parsed_text()


## The notes as shown under the current filter, one string per card.
func get_note_texts() -> Array[String]:
	var result: Array[String] = []
	for card: Node in _notes.get_children():
		if card.has_meta("note_text"):
			result.append(str(card.get_meta("note_text")))
	return result


# --- Content ---------------------------------------------------------------------

func _director() -> ChapterDirector:
	return get_tree().get_first_node_in_group(ChapterDirector.GROUP) as ChapterDirector if is_inside_tree() else null


func _refresh() -> void:
	var director: ChapterDirector = _director()
	var story: Dictionary = ContentRegistry.get_story(director.get_chapter_id()) if director != null else {}
	_title.text = "Case file — %s" % story.get("title", "") if not story.is_empty() else "Case file"
	for value: String in _filter_buttons:
		(_filter_buttons[value] as Button).button_pressed = value == filter
	_refresh_now(director)
	_refresh_evidence()
	_refresh_notes(director)


func _refresh_now(director: ChapterDirector) -> void:
	var lines: PackedStringArray = ["[b]Now[/b]"]
	var objective: Dictionary = director.get_current_objective() if director != null else {}
	if objective.is_empty():
		lines.append("[color=#%s]No objective right now.[/color]" % UIStyle.MUTED.to_html(false))
	else:
		lines.append(_escape(str(objective["text"])))
		var place: String = CaseFile.objective_place(director)
		if not place.is_empty():
			lines.append("[color=#%s]%s[/color]" % [UIStyle.ACCENT.to_html(false), _escape(place)])
	_now.text = "\n".join(lines)


func _refresh_evidence() -> void:
	var summary: Dictionary = CaseFile.evidence_summary()
	var lines: PackedStringArray = ["[b]Evidence[/b]",
			"Collected %d of %d, %d pinned on the board." % [summary["collected"], summary["total"], summary["pinned"]]]
	for hypothesis: Dictionary in summary["hypotheses"]:
		lines.append("")
		lines.append("%s [color=#%s](%s)[/color]" % [_escape(hypothesis["title"]), UIStyle.MUTED.to_html(false), hypothesis["status"]])
		if hypothesis["status"] != "refuted" and not hypothesis["alternates"].is_empty():
			lines.append("[color=#%s]Other explanations still open: %s.[/color]" % [
					UIStyle.MUTED.to_html(false), ", ".join(hypothesis["alternates"])])
	_evidence.text = "\n".join(lines)


func _refresh_notes(director: ChapterDirector) -> void:
	for child: Node in _notes.get_children():
		_notes.remove_child(child)
		child.queue_free()
	var notes: Array[Dictionary] = CaseFile.noted(director)
	notes.reverse()  # Newest chapter first; within a chapter, latest story step first.
	var chapter: String = ""
	var shown: int = 0
	for note: Dictionary in notes:
		if filter != "all" and note["status"] != filter:
			continue
		if note["chapter"] != chapter:
			chapter = note["chapter"]
			var heading: Label = UIStyle.label(note["chapter_title"], 19, UIStyle.MUTED)
			_notes.add_child(heading)
		_notes.add_child(_note_card(note))
		shown += 1
	if shown == 0:
		var empty: String = "Nothing in the case file yet. Choices you record in conversations and documents appear here." \
				if filter == "all" else "Nothing marked %s yet." % FILTER_LABELS[filter].to_lower()
		_notes.add_child(UIStyle.label(empty, 17, UIStyle.MUTED))


func _note_card(note: Dictionary) -> PanelContainer:
	var color: Color = STATUS_COLORS[note["status"]]
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.card_style(color))
	card.set_meta("note_text", note["text"])
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_child(UIStyle.chip(CaseFile.STATUS_LABELS[note["status"]], color, 14))
	var source: Label = UIStyle.label(note["source"], 15, UIStyle.MUTED)
	source.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(source)
	column.add_child(header)
	column.add_child(UIStyle.label(note["text"], 17))
	column.add_child(UIStyle.label("Your choice: " + note["choice"], 14, UIStyle.MUTED))
	return card


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


# --- Construction ------------------------------------------------------------------

func _build() -> void:
	var root: Control = UIStyle.make_root(self, 0.6)
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 60
	panel.offset_right = -60
	panel.offset_top = 40
	panel.offset_bottom = -40
	root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var top: HBoxContainer = HBoxContainer.new()
	_title = UIStyle.label("Case file", 26)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	var board: Button = UIStyle.secondary_button("Evidence board")
	board.name = "EvidenceBoardButton"
	board.pressed.connect(open_other.bind(EvidenceBoard.PANEL_ID))
	top.add_child(board)
	var journal: Button = UIStyle.secondary_button("Clinical journal")
	journal.name = "JournalButton"
	journal.pressed.connect(open_other.bind(CaseJournalScreen.PANEL_ID))
	top.add_child(journal)
	_close_button = UIStyle.secondary_button("Close")
	_close_button.name = "Close"
	_close_button.pressed.connect(close)
	top.add_child(_close_button)
	column.add_child(top)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	column.add_child(body)

	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	body.add_child(left)
	var filters: HBoxContainer = HBoxContainer.new()
	var group: ButtonGroup = ButtonGroup.new()
	for value: String in FILTERS:
		var button: Button = UIStyle.secondary_button(FILTER_LABELS[value], 16)
		button.name = "Filter_" + value
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(set_filter.bind(value))
		filters.add_child(button)
		_filter_buttons[value] = button
	left.add_child(filters)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_notes = VBoxContainer.new()
	_notes.name = "Notes"
	_notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notes.add_theme_constant_override("separation", 8)
	scroll.add_child(_notes)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	body.add_child(right)
	for node_name: String in ["Now", "Evidence"]:
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", UIStyle.card_style(UIStyle.ACCENT if node_name == "Now" else UIStyle.BORDER))
		var text: RichTextLabel = UIStyle.rich_text(true)
		text.name = node_name
		card.add_child(text)
		right.add_child(card)
		if node_name == "Now":
			_now = text
		else:
			_evidence = text
