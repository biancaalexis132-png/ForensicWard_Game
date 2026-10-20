class_name CaseJournalScreen
extends CanvasLayer
## Case journal UI - separate from evidence board.

const PANEL_ID: String = "case_journal"

var is_open: bool = false

@onready var _list: VBoxContainer = $Root/Panel/Margin/VBox/HBox/Scroll/Entries
@onready var _details: RichTextLabel = $Root/Panel/Margin/VBox/HBox/Details
@onready var _close_button: Button = $Root/Panel/Margin/VBox/Close

func _ready() -> void:
	layer = 9
	visible = false
	_close_button.pressed.connect(close)


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


func _refresh() -> void:
	for c: Node in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var entries: Array[Dictionary] = CaseJournal.get_all_entries()
	if entries.is_empty():
		_details.text = "[b]Clinical Case Journal[/b]\n\nNo entries yet. Clinical documentation is kept separately from evidence and hypotheses."
		return
	for entry: Dictionary in entries:
		var btn: Button = Button.new()
		btn.text = "%s - %s [%s]" % [entry.get("patient_id",""), entry.get("type","note"), entry.get("shift","")]
		btn.pressed.connect(_show_entry.bind(entry))
		_list.add_child(btn)
	if entries.size() > 0:
		_show_entry(entries[entries.size()-1])


func _show_entry(entry: Dictionary) -> void:
	_details.text = "[b]%s - %s[/b]\nDay %s, %s (min %s)\n\n%s" % [
		entry.get("patient_id",""),
		entry.get("type",""),
		entry.get("day",""),
		entry.get("shift",""),
		entry.get("at_minutes",""),
		entry.get("content","")
	]
