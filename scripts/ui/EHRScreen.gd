class_name EHRScreen
extends CanvasLayer
## EHRScreen: the electronic health record (GDD §9), opened from EHR
## workstations or with J.
##
## Top: a "Next step" bar derived from the chapter's current objective. When
## the objective is met in the chart (a note saved, an order placed) it names
## the tab, highlights that tab and offers a button to go there.
## Left: the census. Right: a chart header card (name, age, legal status,
## location, arrival, alerts from the patient data) and the chart in tabs:
##   Summary       demographics, presenting concerns, chart status (cards)
##   Observations  authored reports vs what the physician has witnessed,
##                 each with source, time and provenance (one card each)
##   Notes         append-only structured notes: cite recorded findings,
##                 mark differentials under consideration, write a plan
##   Orders        the order catalog (data/order_catalog.json): patient
##                 identification, witnessed findings, assessment status,
##                 one card per order with its status and a Place button;
##                 Details shows indication, prerequisites, time and history;
##                 placing asks for confirmation. Unavailable orders are
##                 listed apart with the reason. Outcomes come from ClinicalRules.
##   Audit         every chart event with time and rule ids
## The screen owns no state: it reads PatientManager/ContentRegistry (and the
## ChapterDirector's current objective) and calls their commands. The button
## handlers are public so tests drive the same paths a player does.

const PANEL_ID: String = "ehr"
const NOTE_MINUTES: int = 10
const TABS: Array[String] = ["Summary", "Observations", "Notes", "Orders", "Audit"]
## Story conditions met inside the chart, and the tab where the player meets them.
const OBJECTIVE_TABS: Dictionary = {"note_saved": "Notes", "action_committed": "Orders"}
## Type sizes, chosen for a 1440x900 laptop window (the 1920x1080 canvas is
## scaled to about 0.75 there).
const SIZE_TITLE: int = 32
const SIZE_HEADING: int = 25
const SIZE_BODY: int = 22
const SIZE_SMALL: int = 20

var is_open: bool = false
var patient_id: String = ""

var _title: Label
var _banner: Label
var _next_step: PanelContainer
var _next_step_text: Label
var _next_step_hint: Label
var _next_step_button: Button
var _next_tab: String = ""
var _census: ItemList
var _header: VBoxContainer
var _tabs: TabContainer
var _summary: VBoxContainer
var _observations: VBoxContainer
var _notes_list: RichTextLabel
var _finding_boxes: VBoxContainer
var _consideration_boxes: VBoxContainer
var _plan: TextEdit
var _note_status: Label
var _orders: VBoxContainer
var _order_result: RichTextLabel
## The order whose details are shown, and whether its confirmation is showing.
var _selected_order: String = ""
var _confirming: bool = false
var _audit: RichTextLabel
var _close_button: Button
var _tab_marker: Texture2D


func _ready() -> void:
	layer = 8
	_tab_marker = _dot_texture(UIStyle.WARNING)
	_build()
	visible = false
	# Signal name -> argument count, so one refresh handler fits them all.
	var sources: Dictionary = {"patient_state_changed": 3, "observation_recorded": 2, "patient_note_saved": 2,
			"clinical_action_committed": 3, "patient_record_opened": 2, "objective_changed": 2}
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
	_selected_order = ""
	_confirming = false
	_note_status.text = ""
	_plan.text = ""
	_refresh()


func show_tab(tab_name: String) -> void:
	var index: int = TABS.find(tab_name)
	if index >= 0:
		_tabs.current_tab = index


## Goes to the tab the Next step bar points at (its button calls this).
func go_to_next_step() -> void:
	if not _next_tab.is_empty():
		show_tab(_next_tab)


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


## Shows an order's details in the Orders tab.
func select_order(order_id: String) -> void:
	_selected_order = order_id
	_confirming = false
	_refresh()


## Asks for confirmation before placing the selected order.
func request_place(order_id: String) -> void:
	var order: Dictionary = ContentRegistry.get_order(order_id)
	if order.is_empty() or not ClinicalOrders.status(patient_id, order)["can_place"]:
		return
	_selected_order = order_id
	_confirming = true
	_refresh()


## Places the order awaiting confirmation. Returns the ClinicalRules result,
## or {} when nothing was awaiting confirmation or it was already placed.
func confirm_order() -> Dictionary:
	var order: Dictionary = ContentRegistry.get_order(_selected_order)
	if not _confirming or order.is_empty():
		return {}
	_confirming = false
	var result: Dictionary = commit_action(order["action_id"])
	if not result.is_empty():
		var placed: String = str(order.get("placed_text", "%s placed." % ContentRegistry.get_action(order["action_id"])["label"]))
		EventBus.notification_requested.emit(placed if not result["rule_ids"].is_empty() else
				"Order logged; no rule applied yet")
	return result


func cancel_order() -> void:
	_confirming = false
	_refresh()


func get_tab_text(tab_name: String) -> String:
	match tab_name:
		"Summary": return _rich_text_of(_summary)
		"Observations": return _rich_text_of(_observations)
		"Notes": return _notes_list.get_parsed_text()
		"Orders": return _orders_text() + "\n" + _order_result.get_parsed_text()
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


## The Next step bar as shown: {"visible", "text", "hint", "tab"}.
func get_next_step() -> Dictionary:
	return {"visible": _next_step.visible, "text": _next_step_text.text, "hint": _next_step_hint.text, "tab": _next_tab}


## The tab marked as the next step, or "" when none is.
func get_highlighted_tab() -> String:
	for i: int in _tabs.get_tab_count():
		if _tabs.get_tab_icon(i) != null:
			return TABS[i]
	return ""


# --- Next step ---------------------------------------------------------------

## The ChapterDirector's current objective, or {} outside the playable world.
func _current_objective() -> Dictionary:
	var director: Node = get_tree().get_first_node_in_group(ChapterDirector.GROUP) if is_inside_tree() else null
	return (director as ChapterDirector).get_current_objective() if director != null else {}


## Which chart condition (note_saved / action_committed) the objective asks
## for, and for which patient: {"tab", "patient_id"} or {}.
static func objective_target(condition: Dictionary) -> Dictionary:
	for key: String in OBJECTIVE_TABS:
		if condition.has(key):
			return {"tab": OBJECTIVE_TABS[key], "patient_id": str(condition[key])}
	for nested_key: String in ["all", "any"]:
		for child: Variant in condition.get(nested_key, []):
			if child is Dictionary:
				var found: Dictionary = objective_target(child)
				if not found.is_empty():
					return found
	return {}


func _refresh_next_step() -> void:
	var objective: Dictionary = _current_objective()
	var target: Dictionary = objective_target(objective.get("complete_when", {})) if not objective.is_empty() else {}
	_next_tab = str(target.get("tab", ""))
	_next_step.visible = not objective.is_empty()
	_next_step_text.text = str(objective.get("text", ""))
	_next_step_hint.text = _next_step_hint_text(target)
	_next_step_hint.visible = not _next_step_hint.text.is_empty()
	_next_step_button.text = "Go to %s" % _next_tab
	_update_next_step_button()
	for i: int in _tabs.get_tab_count():
		var marked: bool = TABS[i] == _next_tab
		_tabs.set_tab_icon(i, _tab_marker if marked else null)
		_tabs.set_tab_title(i, TABS[i] + ("  (next step)" if marked else ""))


## The Go to button shows while the next-step tab is not the one open.
func _update_next_step_button() -> void:
	_next_step_button.visible = not _next_tab.is_empty() and TABS[_tabs.current_tab] != _next_tab


## A short how-to for the objective's tab, from the order catalog and chart.
func _next_step_hint_text(target: Dictionary) -> String:
	if target.is_empty():
		return ""
	var parts: PackedStringArray = []
	var wanted: String = str(target["patient_id"])
	if wanted != patient_id and not ContentRegistry.get_patient(wanted).is_empty():
		parts.append("Select %s in the census first." % ContentRegistry.get_patient(wanted)["name"])
	match target["tab"]:
		"Notes":
			parts.append("Open Notes, tick the findings you witnessed, add a plan and press Save note.")
		"Orders":
			parts.append("Open Orders and press Place on an order, then Confirm.")
			var ready: PackedStringArray = []
			var waiting: PackedStringArray = []
			for order: Dictionary in ContentRegistry.get_orders(wanted):
				var status: Dictionary = ClinicalOrders.status(wanted, order)
				var label: String = str(ContentRegistry.get_action(order["action_id"]).get("label", order["id"]))
				if status["state"] == ClinicalOrders.AVAILABLE:
					ready.append(label)
				elif status["state"] == ClinicalOrders.NEEDS_PREREQUISITES:
					waiting.append(label)
			if not ready.is_empty():
				parts.append("Ready now: %s." % ", ".join(ready))
			if not waiting.is_empty():
				parts.append("%s: findings needed first." % ", ".join(waiting))
	return " ".join(parts)


# --- Rendering ---------------------------------------------------------------

func _refresh() -> void:
	if not is_open or patient_id.is_empty():
		return
	var definition: Dictionary = ContentRegistry.get_patient(patient_id)
	var state: Dictionary = PatientManager.get_state(patient_id)
	_banner.text = _banner_text()
	_banner.visible = not _banner.text.is_empty()
	_rebuild_header(definition, state)
	_refresh_next_step()
	_rebuild_summary(definition, state)
	_rebuild_observations(definition, state)
	_notes_list.text = _notes_text(state)
	_rebuild_note_composer(definition, state)
	_rebuild_orders(state)
	_audit.text = _audit_text(state)


## Empty when everything shown for this patient is approved. Review provenance
## stays in the audit trail and the data, not in the normal chart.
func _banner_text() -> String:
	if not _has_unapproved_content():
		return ""
	if ClinicalRules.build_mode == ClinicalRules.MODE_VALIDATED:
		return "Some orders here await clinical review and are switched off in this build."
	return "Some clinical content here awaits clinical review and is shown for testing only."


func _has_unapproved_content() -> bool:
	if ContentRegistry.get_patient(patient_id).get("clinical_review_status", "") != "APPROVED":
		return true
	for action: Dictionary in ContentRegistry.get_actions(patient_id):
		if not ClinicalOrders.is_action_approved(action):
			return true
	return false


## Chart header: who this is, where, under what legal status, and any alert
## the patient data carries.
func _rebuild_header(definition: Dictionary, state: Dictionary) -> void:
	_clear(_header)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	var name_label: Label = UIStyle.label(str(definition["name"]), SIZE_TITLE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(name_label)
	var age: Label = UIStyle.label("Age %d" % int(definition["age"]), SIZE_BODY, UIStyle.MUTED)
	age.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	age.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(age)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var signed_in: Label = UIStyle.label("Signed in: " + ProtagonistProfile.display_name(), SIZE_SMALL, UIStyle.MUTED)
	signed_in.autowrap_mode = TextServer.AUTOWRAP_OFF
	signed_in.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(signed_in)
	_header.add_child(top)
	var chips: HFlowContainer = HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 6)
	chips.add_child(_chip("Legal status: " + UIStyle.humanize(definition["legal_status"]).capitalize(), UIStyle.ACCENT))
	chips.add_child(_chip("Location: " + UIStyle.humanize(state["location"]).capitalize(), UIStyle.MUTED))
	chips.add_child(_chip("Arrived: shift %d" % int(definition["arrival_shift"]), UIStyle.MUTED))
	var hold: String = str(definition.get("must_not_auto_transfer_if", ""))
	if not hold.is_empty():
		chips.add_child(_chip("Alert: no automatic transfer if %s" % UIStyle.humanize(hold), UIStyle.WARNING))
	_header.add_child(chips)


func _rebuild_summary(definition: Dictionary, state: Dictionary) -> void:
	_clear(_summary)
	var demographics: PackedStringArray = []
	demographics.append("Name: %s    Age: %d" % [definition["name"], definition["age"]])
	demographics.append("Legal status: %s" % UIStyle.humanize(definition["legal_status"]))
	demographics.append("Arrived: shift %d    Current location: %s" % [definition["arrival_shift"], UIStyle.humanize(state["location"])])
	_summary.add_child(_card("Demographics", "\n".join(demographics)))
	var concerns: PackedStringArray = []
	for complaint: String in definition["presentation"]["complaints"]:
		concerns.append("•  " + UIStyle.humanize(complaint))
	_summary.add_child(_card("Presenting concerns (as referred)", "\n".join(concerns)))
	var status: PackedStringArray = []
	var assessment: Dictionary = state["assessment"]
	status.append("Structured assessment: %s" % ("started" if assessment.get("started", false) else "not started"))
	status.append("Medical review: %s" % ("requested" if assessment.get("medical_review_requested", false) else "not requested"))
	status.append("Findings you have recorded: %d of %d reported" % [state["observations"].size(),
			definition["presentation"]["observations"].size()])
	status.append("Notes: %d" % state["notes"].size())
	if definition["clinical_review_status"] != "APPROVED":
		status.append("[color=#%s]This record awaits clinical review.[/color]" % UIStyle.WARNING.to_html(false))
	_summary.add_child(_card("Chart status", "\n".join(status)))


func _rebuild_observations(definition: Dictionary, state: Dictionary) -> void:
	_clear(_observations)
	_observations.add_child(UIStyle.label("Reported observations and what you have witnessed", SIZE_HEADING, UIStyle.MUTED))
	for observation: Dictionary in definition["presentation"]["observations"]:
		var id: String = observation["id"]
		var lines: PackedStringArray = []
		lines.append("Report: %s" % observation["text"])
		lines.append("[color=#%s]Source: %s, %s[/color]" % [UIStyle.MUTED.to_html(false),
				UIStyle.humanize(observation["source"]), UIStyle.humanize(observation["timestamp"])])
		var accent: Color = UIStyle.MUTED
		if state["observations"].has(id):
			var recorded: Dictionary = state["observations"][id]
			accent = UIStyle.ACCENT
			lines.append("[color=#%s]Witnessed by you: %s, %s. %s[/color]" % [UIStyle.ACCENT.to_html(false),
					_describe_provenance(recorded["recorded_by"]), TimeManager.format_minutes(int(recorded["at_minutes"])),
					"Verified." if recorded.get("verified", false) else "Not independently verified."])
		else:
			lines.append("[color=#%s]Not yet witnessed by you.[/color]" % UIStyle.WARNING.to_html(false))
		_observations.add_child(_card(UIStyle.humanize(id.trim_prefix("obs_")).capitalize(), "\n".join(lines), accent))


func _notes_text(state: Dictionary) -> String:
	if state["notes"].is_empty():
		return "[color=#%s]No notes yet.[/color]" % UIStyle.MUTED.to_html(false)
	var lines: PackedStringArray = []
	for note: Dictionary in state["notes"]:
		lines.append("[b]%s[/b]  ·  %s shift  ·  %s" % [TimeManager.format_minutes(int(note["at_minutes"])),
				str(note["shift"]).capitalize(), note["id"]])
		lines.append("  Author: " + str(note.get("author_name", "Player psychiatrist")).replace("[", "[lb]"))
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
	_finding_boxes.add_child(UIStyle.label("Cite findings you have witnessed:", SIZE_SMALL, UIStyle.MUTED))
	var recorded: Array = state["observations"].keys()
	recorded.sort()
	if recorded.is_empty():
		_finding_boxes.add_child(UIStyle.label("  (none yet: interview or examine the patient first)", SIZE_SMALL, UIStyle.MUTED))
	for id: String in recorded:
		_finding_boxes.add_child(_check_box(id, UIStyle.humanize(id.trim_prefix("obs_")), id in keep_findings))
	_consideration_boxes.add_child(UIStyle.label("Keep under consideration (not a diagnosis):", SIZE_SMALL, UIStyle.MUTED))
	for tag: String in definition["differential_tags"]:
		_consideration_boxes.add_child(_check_box(tag, UIStyle.humanize(tag), tag in keep_considerations))


func _rebuild_orders(state: Dictionary) -> void:
	_clear(_orders)
	var definition: Dictionary = ContentRegistry.get_patient(patient_id)
	var context: VBoxContainer = VBoxContainer.new()
	context.add_child(UIStyle.label("Patient: %s, %d  ·  %s  ·  %s" % [definition["name"], definition["age"],
			UIStyle.humanize(definition["legal_status"]), UIStyle.humanize(state["location"])], SIZE_BODY))
	context.add_child(UIStyle.label("Findings you have witnessed: %s" % _finding_list(state["observations"].keys()), SIZE_SMALL, UIStyle.MUTED))
	var assessment: Dictionary = state["assessment"]
	context.add_child(UIStyle.label("Structured assessment: %s    Medical review: %s" % [
			"started" if assessment.get("started", false) else "not started",
			"requested" if assessment.get("medical_review_requested", false) else "not requested"], SIZE_SMALL, UIStyle.MUTED))
	_orders.add_child(_card_container(context, UIStyle.BORDER))
	_orders.add_child(UIStyle.label("Available orders", SIZE_HEADING))
	var orders: Array[Dictionary] = ContentRegistry.get_orders(patient_id)
	if orders.is_empty():
		_orders.add_child(UIStyle.label("No orders are available for this patient yet.", SIZE_BODY, UIStyle.MUTED))
	for order: Dictionary in orders:
		_orders.add_child(_order_card(order))
	var unavailable: Array[Dictionary] = ContentRegistry.get_unavailable_orders()
	if not unavailable.is_empty():
		_orders.add_child(UIStyle.label("Not available in this build", SIZE_HEADING, UIStyle.MUTED))
		for entry: Dictionary in unavailable:
			var box: VBoxContainer = VBoxContainer.new()
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var title: Label = UIStyle.label("%s  ·  %s" % [entry["label"], entry["category"]], SIZE_BODY, UIStyle.MUTED)
			title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(title)
			row.add_child(_chip("Not available", UIStyle.MUTED))
			box.add_child(row)
			box.add_child(_wrapped(str(entry["reason"]), SIZE_SMALL, UIStyle.MUTED))
			_orders.add_child(_card_container(box, UIStyle.MUTED, Color(UIStyle.CARD, 0.6)))


## One order: title, category and status, Details and Place on one row; the
## indication under it; details and confirmation when selected.
func _order_card(order: Dictionary) -> PanelContainer:
	var action: Dictionary = ContentRegistry.get_action(order["action_id"])
	var status: Dictionary = ClinicalOrders.status(patient_id, order)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var title: Label = UIStyle.label(str(action["label"]), SIZE_HEADING)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(_chip(str(order["category"]), UIStyle.MUTED))
	row.add_child(_chip(status["label"], _status_color(status["state"])))
	var open: bool = order["id"] == _selected_order
	var button: Button = UIStyle.secondary_button("Hide details" if open else "Details", SIZE_SMALL)
	# Named after the action so earlier tests and tools find the same control.
	button.name = "Action_" + str(order["action_id"])
	button.disabled = not status["can_place"] and not open and status["state"] != ClinicalOrders.REVIEW_BLOCKED
	var order_id: String = order["id"]
	button.pressed.connect(func() -> void: select_order("" if _selected_order == order_id else order_id))
	row.add_child(button)
	if status["can_place"] and not (open and _confirming):
		var place: Button = UIStyle.primary_button("Place  (%d min)" % int(action["time_minutes"]), SIZE_SMALL)
		place.name = "Place_" + order_id
		place.pressed.connect(func() -> void: request_place(order_id))
		row.add_child(place)
	box.add_child(row)
	box.add_child(_wrapped(str(order["indication"]), SIZE_SMALL, UIStyle.MUTED))
	if open:
		box.add_child(_order_details(order, action, status))
	return _card_container(box, _status_color(status["state"]))


func _chip(text: String, color: Color) -> PanelContainer:
	return UIStyle.chip(text, color, SIZE_SMALL - 1)


func _status_color(state: String) -> Color:
	match state:
		ClinicalOrders.AVAILABLE: return UIStyle.GOOD
		ClinicalOrders.NEEDS_PREREQUISITES, ClinicalOrders.REVIEW_BLOCKED: return UIStyle.WARNING
		ClinicalOrders.AWAITING_RESPONSE: return UIStyle.ACCENT
	return UIStyle.MUTED


func _order_details(order: Dictionary, action: Dictionary, status: Dictionary) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.name = "OrderDetails"
	box.add_child(HSeparator.new())
	box.add_child(_wrapped("Indication: " + str(order["indication"]), SIZE_BODY))
	box.add_child(_wrapped(str(order["details"]), SIZE_SMALL, UIStyle.MUTED))
	var needed: Array = order.get("prerequisites", {}).get("observations", [])
	if not needed.is_empty():
		var parts: PackedStringArray = []
		for observation_id: String in needed:
			parts.append("%s (%s)" % [_finding_list([observation_id]), "not yet recorded" if observation_id in status["missing"] else "recorded"])
		box.add_child(_wrapped("Needs: " + ", ".join(parts), SIZE_SMALL, UIStyle.WARNING if not status["missing"].is_empty() else UIStyle.MUTED))
	box.add_child(UIStyle.label("Time: %d min    Review: %s" % [int(action["time_minutes"]),
			"clinically approved" if ClinicalOrders.is_action_approved(action) else "awaiting clinical review"], SIZE_SMALL, UIStyle.MUTED))
	if not str(status["reason"]).is_empty():
		box.add_child(_wrapped(status["reason"], SIZE_SMALL, UIStyle.WARNING))
	for entry: Dictionary in ClinicalOrders.history(patient_id, order):
		box.add_child(UIStyle.label("  Placed %s%s" % [TimeManager.format_minutes(int(entry["at_minutes"])),
				"" if entry["rule_ids"].is_empty() else "  ·  rule applied"], SIZE_SMALL, UIStyle.MUTED))
	var order_id: String = order["id"]
	if _confirming:
		var prompt: String = "Place %s for %s? It takes %d minutes." % [action["label"],
				ContentRegistry.get_patient(patient_id)["name"], int(action["time_minutes"])]
		if not status["missing"].is_empty():
			prompt += " The findings it needs are not recorded, so the request will be logged without effect."
		box.add_child(_wrapped(prompt, SIZE_BODY))
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var confirm: Button = UIStyle.primary_button("Confirm order", SIZE_BODY)
		confirm.name = "Confirm_" + order_id
		confirm.pressed.connect(func() -> void: confirm_order())
		row.add_child(confirm)
		var cancel: Button = UIStyle.secondary_button("Cancel", SIZE_BODY)
		cancel.name = "Cancel_" + order_id
		cancel.pressed.connect(cancel_order)
		row.add_child(cancel)
		box.add_child(row)
	return box


## Plain text of the Orders tab, for tests and screen readers.
func _orders_text() -> String:
	var lines: PackedStringArray = []
	for node: Node in _orders.find_children("*", "Label", true, false):
		lines.append((node as Label).text)
	return "\n".join(lines)


func _rich_text_of(container: Node) -> String:
	var parts: PackedStringArray = []
	for node: Node in container.find_children("*", "", true, false):
		if node is RichTextLabel:
			parts.append((node as RichTextLabel).get_parsed_text())
		elif node is Label:
			parts.append((node as Label).text)
	return "\n".join(parts)


func _finding_list(ids: Array) -> String:
	if ids.is_empty():
		return "none yet"
	var names: Array = ids.duplicate()
	names.sort()
	return ", ".join(names.map(func(id: String) -> String: return UIStyle.humanize(id.trim_prefix("obs_"))))


func _wrapped(text: String, size: int, color: Color = UIStyle.TEXT) -> Label:
	var label: Label = UIStyle.label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


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
	var root: Control = UIStyle.make_root(self, 0.6)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	panel.anchor_left = 0.03
	panel.anchor_top = 0.04
	panel.anchor_right = 0.97
	panel.anchor_bottom = 0.96
	root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var top: HBoxContainer = HBoxContainer.new()
	_title = UIStyle.label("Electronic Health Record", SIZE_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	_close_button = UIStyle.secondary_button("Close  (Esc)", SIZE_BODY)
	_close_button.pressed.connect(close)
	top.add_child(_close_button)
	column.add_child(top)
	_banner = UIStyle.label("", SIZE_SMALL, UIStyle.WARNING)
	_banner.visible = false
	column.add_child(_banner)
	column.add_child(_build_next_step())

	var split: HSplitContainer = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(split)
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size.x = 230
	left.add_child(UIStyle.label("Census", SIZE_HEADING, UIStyle.MUTED))
	_census = ItemList.new()
	_census.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_census.add_theme_font_size_override("font_size", SIZE_BODY)
	_census.add_theme_constant_override("v_separation", 10)
	_census.add_theme_color_override("font_color", UIStyle.TEXT)
	_census.item_selected.connect(func(index: int) -> void: select_patient(_census.get_item_metadata(index)))
	left.add_child(_census)
	split.add_child(left)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	_header = VBoxContainer.new()
	_header.name = "ChartHeader"
	_header.add_theme_constant_override("separation", 8)
	right.add_child(_card_container(_header, UIStyle.ACCENT))
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", SIZE_BODY)
	_tabs.add_theme_color_override("font_selected_color", Color.WHITE)
	_tabs.add_theme_color_override("font_unselected_color", UIStyle.MUTED.lightened(0.15))
	_tabs.tab_changed.connect(func(_index: int) -> void: _update_next_step_button())
	right.add_child(_tabs)
	split.add_child(right)

	_summary = _add_card_tab("Summary")
	_observations = _add_card_tab("Observations")
	_build_notes_tab()
	_build_orders_tab()
	_audit = _add_text_tab("Audit")


func _build_next_step() -> PanelContainer:
	_next_step = PanelContainer.new()
	_next_step.name = "NextStep"
	_next_step.visible = false
	var style: StyleBoxFlat = UIStyle.card_style(UIStyle.WARNING, Color(0.2, 0.17, 0.09, 1.0))
	_next_step.add_theme_stylebox_override("panel", style)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var text: VBoxContainer = VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 2)
	text.add_child(UIStyle.label("NEXT STEP", SIZE_SMALL - 2, UIStyle.WARNING))
	_next_step_text = UIStyle.label("", SIZE_HEADING, UIStyle.TEXT)
	text.add_child(_next_step_text)
	_next_step_hint = UIStyle.label("", SIZE_SMALL, UIStyle.WARNING.lightened(0.35))
	text.add_child(_next_step_hint)
	row.add_child(text)
	_next_step_button = UIStyle.primary_button("Go to", SIZE_BODY)
	_next_step_button.name = "GoToNextStep"
	_next_step_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_next_step_button.pressed.connect(go_to_next_step)
	row.add_child(_next_step_button)
	_next_step.add_child(row)
	return _next_step


## A tab of section cards in a scroll box; returns the card column.
func _add_card_tab(tab_name: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	_tabs.add_child(scroll)
	return box


func _add_text_tab(tab_name: String) -> RichTextLabel:
	var text: RichTextLabel = _rich(false)
	text.name = tab_name
	_tabs.add_child(text)
	return text


## A section card: heading and BBCode body.
func _card(heading: String, body: String, accent: Color = UIStyle.BORDER) -> PanelContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(UIStyle.label(heading, SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
	var text: RichTextLabel = _rich(true)
	text.text = body
	box.add_child(text)
	return _card_container(box, accent)


func _card_container(content: Control, accent: Color, background: Color = UIStyle.CARD) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.card_style(accent, background))
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(content)
	return card


func _rich(fit: bool) -> RichTextLabel:
	var text: RichTextLabel = UIStyle.rich_text(fit)
	for font: String in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		text.add_theme_font_size_override(font, SIZE_BODY)
	text.add_theme_constant_override("line_separation", 4)
	return text


func _build_notes_tab() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Notes"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	var saved: VBoxContainer = VBoxContainer.new()
	saved.add_child(UIStyle.label("Saved notes", SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
	_notes_list = _rich(true)
	saved.add_child(_notes_list)
	box.add_child(_card_container(saved, UIStyle.BORDER))
	var composer: VBoxContainer = VBoxContainer.new()
	composer.add_theme_constant_override("separation", 8)
	composer.add_child(UIStyle.label("New structured note", SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
	var lists: HBoxContainer = HBoxContainer.new()
	lists.add_theme_constant_override("separation", 24)
	_finding_boxes = VBoxContainer.new()
	_finding_boxes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_consideration_boxes = VBoxContainer.new()
	_consideration_boxes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.add_child(_finding_boxes)
	lists.add_child(_consideration_boxes)
	composer.add_child(lists)
	composer.add_child(UIStyle.label("Plan / free text (your own words):", SIZE_SMALL, UIStyle.MUTED))
	_plan = TextEdit.new()
	_plan.custom_minimum_size.y = 110
	_plan.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_plan.add_theme_font_size_override("font_size", SIZE_BODY)
	_plan.placeholder_text = "e.g. Review intake chart with nursing; repeat bedside examination next shift."
	composer.add_child(_plan)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var save: Button = UIStyle.primary_button("Save note  (%d min)" % NOTE_MINUTES, SIZE_BODY)
	save.name = "SaveNote"
	save.pressed.connect(func() -> void: submit_note())
	row.add_child(save)
	_note_status = UIStyle.label("", SIZE_SMALL, UIStyle.MUTED)
	_note_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_note_status)
	composer.add_child(row)
	box.add_child(_card_container(composer, UIStyle.ACCENT))
	_tabs.add_child(scroll)


func _build_orders_tab() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Orders"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	_orders = VBoxContainer.new()
	_orders.add_theme_constant_override("separation", 10)
	box.add_child(_orders)
	_order_result = _rich(true)
	box.add_child(_order_result)
	_tabs.add_child(scroll)


func _check_box(id: String, text: String, pressed: bool) -> CheckBox:
	var box: CheckBox = CheckBox.new()
	box.text = text
	box.set_meta("id", id)
	box.button_pressed = pressed
	box.add_theme_font_size_override("font_size", SIZE_BODY)
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


## A small filled circle for the "next step" tab marker.
static func _dot_texture(color: Color) -> Texture2D:
	var size: int = 14
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var centre: Vector2 = Vector2(size - 1, size - 1) / 2.0
	for y: int in size:
		for x: int in size:
			var d: float = Vector2(x, y).distance_to(centre)
			image.set_pixel(x, y, Color(color, clampf(size / 2.0 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)
