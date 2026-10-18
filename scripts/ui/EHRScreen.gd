class_name EHRScreen
extends CanvasLayer
## EHRScreen: the electronic health record (GDD §9), opened from EHR
## workstations or with J.
##
## Left: the census. Right: the selected patient's chart in tabs:
##   Summary       demographics, legal status, location, chart status
##   Observations  authored reports vs what the physician has witnessed,
##                 each with source, time and provenance
##   Notes         append-only structured notes: cite recorded findings,
##                 mark differentials under consideration, write a plan
##   Orders        authored clinical actions, evaluated by ClinicalRules
##   Audit         every chart event with time and rule ids
## The screen owns no state: it reads PatientManager/ContentRegistry and
## calls their commands. The button handlers are public so tests drive the
## same paths a player does.

const PANEL_ID: String = "ehr"
const NOTE_MINUTES: int = 10
const TABS: Array[String] = ["Summary", "Observations", "Notes", "Orders", "Audit"]

var is_open: bool = false
var patient_id: String = ""

var _title: Label
var _banner: Label
var _census: ItemList
var _header: RichTextLabel
var _tabs: TabContainer
var _summary: RichTextLabel
var _observations: RichTextLabel
var _notes_list: RichTextLabel
var _finding_boxes: VBoxContainer
var _consideration_boxes: VBoxContainer
var _plan: TextEdit
var _note_status: Label
var _orders: VBoxContainer
var _order_result: RichTextLabel
var _audit: RichTextLabel
var _close_button: Button


func _ready() -> void:
	layer = 8
	_build()
	visible = false
	# Signal name -> argument count, so one refresh handler fits them all.
	var sources: Dictionary = {"patient_state_changed": 3, "observation_recorded": 2, "patient_note_saved": 2,
			"clinical_action_committed": 3, "patient_record_opened": 2}
	for signal_name: String in sources:
		EventBus.connect(signal_name, _refresh.unbind(sources[signal_name]))


# --- Panel protocol (Main) ---------------------------------------------------------

## data: {"title": String (optional), "patient_id": String (optional)}
func open(data: Dictionary) -> void:
	_title.text = str(data.get("title", "Electronic Health Record"))
	visible = true
	is_open = true
	_census.clear()
	var ids: Array[String] = []
	ids.assign(ContentRegistry.get_patient_ids().filter(PatientManager.is_admitted))
	for id: String in ids:
		_census.add_item(ContentRegistry.get_patient(id).get("name", id))
		_census.set_item_metadata(_census.item_count - 1, id)
	var wanted: String = str(data.get("patient_id", ""))
	if wanted.is_empty() or not wanted in ids:
		wanted = ids[0] if not ids.is_empty() else ""
	select_patient(wanted)
	_close_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)


# --- Actions (buttons call these; so do tests) -----------------------------------

func select_patient(id: String) -> void:
	patient_id = id
	for i: int in _census.item_count:
		if _census.get_item_metadata(i) == id:
			_census.select(i)
	if not id.is_empty():
		PatientManager.open_record(id)  # Audited once per patient per day.
	_order_result.text = ""
	_note_status.text = ""
	_plan.text = ""
	_refresh()


func show_tab(tab_name: String) -> void:
	var index: int = TABS.find(tab_name)
	if index >= 0:
		_tabs.current_tab = index


## Ticks the given findings/considerations in the note composer and sets the plan.
func set_note_selection(findings: Array[String], considerations: Array[String], plan: String) -> void:
	for box: Node in _finding_boxes.get_children():
		if box is CheckBox:
			(box as CheckBox).button_pressed = box.get_meta("id") in findings
	for box: Node in _consideration_boxes.get_children():
		if box is CheckBox:
			(box as CheckBox).button_pressed = box.get_meta("id") in considerations
	_plan.text = plan


## Saves the composed note. Returns the note id, or "" if nothing valid was entered.
func submit_note() -> String:
	var findings: Array[String] = _checked(_finding_boxes)
	var considerations: Array[String] = _checked(_consideration_boxes)
	var note_id: String = PatientManager.save_note(patient_id, findings, considerations, _plan.text)
	if note_id.is_empty():
		_note_status.text = "Nothing to save: cite a recorded finding, a consideration, or write a plan."
		return ""
	TimeManager.advance(NOTE_MINUTES, "documentation")
	var none: Array[String] = []
	set_note_selection(none, none, "")
	_note_status.text = "Note saved to the chart (%s)." % note_id
	EventBus.notification_requested.emit("Note saved to %s's chart" % ContentRegistry.get_patient(patient_id).get("name", ""))
	_refresh()
	return note_id


## Commits an authored clinical action citing every recorded finding.
func commit_action(action_id: String) -> Dictionary:
	var findings: Array[String] = []
	findings.assign(PatientManager.get_state(patient_id).get("observations", {}).keys())
	findings.sort()
	var result: Dictionary = PatientManager.perform_action(patient_id, action_id, findings)
	_order_result.text = _describe_result(action_id, result)
	_refresh()
	return result


func get_tab_text(tab_name: String) -> String:
	match tab_name:
		"Summary": return _summary.get_parsed_text()
		"Observations": return _observations.get_parsed_text()
		"Notes": return _notes_list.get_parsed_text()
		"Orders": return _order_result.get_parsed_text()
		"Audit": return _audit.get_parsed_text()
	return ""


func get_finding_choices() -> Array[String]:
	var ids: Array[String] = []
	for box: Node in _finding_boxes.get_children():
		if box is CheckBox:
			ids.append(box.get_meta("id"))
	return ids


func get_action_button(action_id: String) -> Button:
	return _orders.find_child("Action_" + action_id, true, false) as Button


# --- Rendering ---------------------------------------------------------------

func _refresh() -> void:
	if not is_open or patient_id.is_empty():
		return
	var definition: Dictionary = ContentRegistry.get_patient(patient_id)
	var state: Dictionary = PatientManager.get_state(patient_id)
	_banner.text = _banner_text()
	_header.text = "[b]%s[/b]   %d   ·   %s   ·   Location: %s" % [definition["name"], definition["age"],
			UIStyle.humanize(definition["legal_status"]), UIStyle.humanize(state["location"])]
	_summary.text = _summary_text(definition, state)
	_observations.text = _observations_text(definition, state)
	_notes_list.text = _notes_text(state)
	_rebuild_note_composer(definition, state)
	_rebuild_orders(state)
	_audit.text = _audit_text(state)


func _banner_text() -> String:
	if ClinicalRules.build_mode == ClinicalRules.MODE_VALIDATED:
		return "Validated build: clinical rules that are not approved are switched off."
	return "Prototype build: clinical content marked pending is shown for testing and is NOT clinically validated."


func _summary_text(definition: Dictionary, state: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]Demographics[/b]")
	lines.append("Name: %s    Age: %d    (fictional patient)" % [definition["name"], definition["age"]])
	lines.append("Legal status: %s" % UIStyle.humanize(definition["legal_status"]))
	lines.append("Arrived: shift %d    Current location: %s" % [definition["arrival_shift"], UIStyle.humanize(state["location"])])
	lines.append("")
	lines.append("[b]Presenting concerns (as referred)[/b]")
	for complaint: String in definition["presentation"]["complaints"]:
		lines.append("  • " + UIStyle.humanize(complaint))
	lines.append("")
	lines.append("[b]Chart status[/b]")
	var assessment: Dictionary = state["assessment"]
	lines.append("  Structured assessment: %s" % ("started" if assessment.get("started", false) else "not started"))
	lines.append("  Medical review: %s" % ("requested" if assessment.get("medical_review_requested", false) else "not requested"))
	lines.append("  Findings you have recorded: %d of %d reported" % [state["observations"].size(),
			definition["presentation"]["observations"].size()])
	lines.append("  Notes: %d" % state["notes"].size())
	lines.append("")
	lines.append("[color=#%s]Clinical content status: %s[/color]" % [UIStyle.MUTED.to_html(false),
			definition["clinical_review_status"]])
	return "\n".join(lines)


func _observations_text(definition: Dictionary, state: Dictionary) -> String:
	var lines: PackedStringArray = ["[b]Reported observations and what you have witnessed[/b]", ""]
	for observation: Dictionary in definition["presentation"]["observations"]:
		var id: String = observation["id"]
		lines.append("[b]%s[/b]" % UIStyle.humanize(id.trim_prefix("obs_")).capitalize())
		lines.append("  Report: %s" % observation["text"])
		lines.append("  Source: %s, %s" % [UIStyle.humanize(observation["source"]), UIStyle.humanize(observation["timestamp"])])
		if state["observations"].has(id):
			var recorded: Dictionary = state["observations"][id]
			lines.append("  [color=#%s]Witnessed by you: %s, %s. %s[/color]" % [UIStyle.BORDER.lightened(0.3).to_html(false),
					_describe_provenance(recorded["recorded_by"]), TimeManager.format_minutes(int(recorded["at_minutes"])),
					"Verified." if recorded.get("verified", false) else "Not independently verified."])
		else:
			lines.append("  [color=#%s]Not yet witnessed by you.[/color]" % UIStyle.MUTED.to_html(false))
		lines.append("")
	return "\n".join(lines)


func _notes_text(state: Dictionary) -> String:
	if state["notes"].is_empty():
		return "[color=#%s]No notes yet.[/color]" % UIStyle.MUTED.to_html(false)
	var lines: PackedStringArray = []
	for note: Dictionary in state["notes"]:
		lines.append("[b]%s[/b]  ·  %s shift  ·  %s" % [TimeManager.format_minutes(int(note["at_minutes"])),
				str(note["shift"]).capitalize(), note["id"]])
		if not note["findings"].is_empty():
			lines.append("  Findings: " + ", ".join(Array(note["findings"]).map(
					func(f: String) -> String: return UIStyle.humanize(f.trim_prefix("obs_")))))
		if not note["considerations"].is_empty():
			lines.append("  Under consideration: " + ", ".join(Array(note["considerations"]).map(UIStyle.humanize)))
		if not str(note["plan"]).is_empty():
			lines.append("  Plan: " + str(note["plan"]).replace("[", "[lb]"))
		lines.append("")
	return "\n".join(lines)


func _audit_text(state: Dictionary) -> String:
	var lines: PackedStringArray = ["[b]Chart audit trail[/b] (newest first)", ""]
	var entries: Array = state["audit"].duplicate()
	entries.reverse()
	for entry: Dictionary in entries:
		var line: String = "%s   %s   %s" % [TimeManager.format_minutes(int(entry["at_minutes"])),
				UIStyle.humanize(entry["type"]), entry["event_id"]]
		if entry.has("rule_ids") and not entry["rule_ids"].is_empty():
			line += "   rules: " + ", ".join(entry["rule_ids"])
		lines.append(line)
		if entry.has("text"):
			lines.append("      [color=#%s]%s (by %s)[/color]" % [UIStyle.WARNING.to_html(false),
					str(entry["text"]).replace("[", "[lb]"), UIStyle.humanize(str(entry["by"]))])
		for reason: String in entry.get("review_flags", []):
			lines.append("      [color=#%s]review: %s[/color]" % [UIStyle.WARNING.to_html(false), reason])
	return "\n".join(lines)


func _rebuild_note_composer(definition: Dictionary, state: Dictionary) -> void:
	var keep_findings: Array[String] = _checked(_finding_boxes)
	var keep_considerations: Array[String] = _checked(_consideration_boxes)
	_clear(_finding_boxes)
	_clear(_consideration_boxes)
	_finding_boxes.add_child(UIStyle.label("Cite findings you have witnessed:", 16, UIStyle.MUTED))
	var recorded: Array = state["observations"].keys()
	recorded.sort()
	if recorded.is_empty():
		_finding_boxes.add_child(UIStyle.label("  (none yet: interview or examine the patient first)", 16, UIStyle.MUTED))
	for id: String in recorded:
		_finding_boxes.add_child(_check_box(id, UIStyle.humanize(id.trim_prefix("obs_")), id in keep_findings))
	_consideration_boxes.add_child(UIStyle.label("Keep under consideration (not a diagnosis):", 16, UIStyle.MUTED))
	for tag: String in definition["differential_tags"]:
		_consideration_boxes.add_child(_check_box(tag, UIStyle.humanize(tag), tag in keep_considerations))


func _rebuild_orders(state: Dictionary) -> void:
	_clear(_orders)
	var actions: Array[Dictionary] = ContentRegistry.get_actions(patient_id)
	if actions.is_empty():
		_orders.add_child(UIStyle.label("No clinical actions are authored for this patient yet.", 17, UIStyle.MUTED))
	for action: Dictionary in actions:
		var row: VBoxContainer = VBoxContainer.new()
		row.add_child(UIStyle.label("%s   [%s]" % [action["label"], action["clinical_review_status"]], 18))
		row.add_child(UIStyle.label(action["description"], 16, UIStyle.MUTED))
		var done: bool = PatientManager.has_processed(patient_id, PatientManager.action_event_id(patient_id, action["id"]))
		var button: Button = UIStyle.button("Committed this shift day" if done else "Commit  (%d min)" % int(action["time_minutes"]))
		button.name = "Action_" + str(action["id"])
		button.disabled = done
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var action_id: String = action["id"]
		button.pressed.connect(func() -> void: commit_action(action_id))
		row.add_child(button)
		_orders.add_child(row)
		_orders.add_child(HSeparator.new())
	var recorded: int = state["observations"].size()
	_orders.add_child(UIStyle.label("Actions cite the %d finding(s) you have witnessed." % recorded, 16, UIStyle.MUTED))


func _describe_result(action_id: String, result: Dictionary) -> String:
	var label: String = ContentRegistry.get_action(action_id).get("label", action_id)
	if result.is_empty():
		return "[b]%s[/b]: already committed this shift day; nothing changed." % label
	var lines: PackedStringArray = ["[b]%s[/b] committed." % label]
	if result["rule_ids"].is_empty():
		lines.append("No rule applied: the findings this action needs are not documented yet. The request is logged in the audit trail.")
	for effect: Dictionary in result["effects"]:
		# "patients.<id>.assessment.started" -> "assessment: started"
		var field: PackedStringArray = str(effect["path"]).split(".").slice(2)
		lines.append("Chart updated: %s." % UIStyle.humanize(": ".join(field)))
	for flag: Dictionary in result["review_flags"]:
		lines.append("[color=#%s]Review flag (%s): %s[/color]" % [UIStyle.WARNING.to_html(false), flag["rule_id"], flag["reason"]])
	return "\n".join(lines)


func _describe_provenance(recorded_by: String) -> String:
	if recorded_by.begins_with("interview:"):
		return "during interview (%s)" % UIStyle.humanize(recorded_by.trim_prefix("interview:"))
	return UIStyle.humanize(recorded_by)


# --- Construction -------------------------------------------------------------

func _build() -> void:
	var root: Control = UIStyle.make_root(self, 0.55)
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	panel.anchor_left = 0.04
	panel.anchor_top = 0.05
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.95
	root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var top: HBoxContainer = HBoxContainer.new()
	_title = UIStyle.label("Electronic Health Record", 26)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	_close_button = UIStyle.button("Close  (Esc)")
	_close_button.pressed.connect(close)
	top.add_child(_close_button)
	column.add_child(top)
	_banner = UIStyle.label("", 15, UIStyle.WARNING)
	column.add_child(_banner)

	var split: HSplitContainer = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(split)
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size.x = 220
	left.add_child(UIStyle.label("Census", 18, UIStyle.MUTED))
	_census = ItemList.new()
	_census.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_census.add_theme_font_size_override("font_size", 17)
	_census.item_selected.connect(func(index: int) -> void: select_patient(_census.get_item_metadata(index)))
	left.add_child(_census)
	split.add_child(left)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header = UIStyle.rich_text(true)
	right.add_child(_header)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_tabs)
	split.add_child(right)

	_summary = _add_text_tab("Summary")
	_observations = _add_text_tab("Observations")
	_build_notes_tab()
	_build_orders_tab()
	_audit = _add_text_tab("Audit")


func _add_text_tab(tab_name: String) -> RichTextLabel:
	var text: RichTextLabel = UIStyle.rich_text()
	text.name = tab_name
	_tabs.add_child(text)
	return text


func _build_notes_tab() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Notes"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	_notes_list = UIStyle.rich_text(true)
	box.add_child(_notes_list)
	box.add_child(HSeparator.new())
	box.add_child(UIStyle.label("New structured note", 19))
	var lists: HBoxContainer = HBoxContainer.new()
	_finding_boxes = VBoxContainer.new()
	_finding_boxes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_consideration_boxes = VBoxContainer.new()
	_consideration_boxes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.add_child(_finding_boxes)
	lists.add_child(_consideration_boxes)
	box.add_child(lists)
	box.add_child(UIStyle.label("Plan / free text (your own words):", 16, UIStyle.MUTED))
	_plan = TextEdit.new()
	_plan.custom_minimum_size.y = 90
	_plan.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_plan.placeholder_text = "e.g. Review intake chart with nursing; repeat bedside examination next shift."
	box.add_child(_plan)
	var row: HBoxContainer = HBoxContainer.new()
	var save: Button = UIStyle.button("Save note  (%d min)" % NOTE_MINUTES)
	save.pressed.connect(func() -> void: submit_note())
	row.add_child(save)
	_note_status = UIStyle.label("", 16, UIStyle.MUTED)
	_note_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_note_status)
	box.add_child(row)
	_tabs.add_child(scroll)


func _build_orders_tab() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Orders"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	_orders = VBoxContainer.new()
	_orders.add_theme_constant_override("separation", 6)
	box.add_child(_orders)
	_order_result = UIStyle.rich_text(true)
	box.add_child(_order_result)
	_tabs.add_child(scroll)


func _check_box(id: String, text: String, pressed: bool) -> CheckBox:
	var box: CheckBox = CheckBox.new()
	box.text = text
	box.set_meta("id", id)
	box.button_pressed = pressed
	box.add_theme_font_size_override("font_size", 16)
	return box


func _checked(container: Container) -> Array[String]:
	var ids: Array[String] = []
	for box: Node in container.get_children():
		if box is CheckBox and (box as CheckBox).button_pressed:
			ids.append(box.get_meta("id"))
	return ids


func _clear(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
