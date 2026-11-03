class_name WardRoundScreen
extends CanvasLayer
## WardRoundScreen: the ward round in the EHR (opened from its Ward round
## button). Left: the patients admitted so far, with their status. Right, in
## tabs, for the selected patient:
##   Bedside how you open the conversation, then questions; answers fill the chart
##   Chart   presentation, then history, mental state and vitals once heard at
##           the bedside, current medications
##   Labs    the lab catalog by category; Order shows the result at once
##   Plan    an action for each current medication, medications to start and
##           interventions
##   Debrief the score once a plan is accepted (WardRoundScoring)
## Below the tabs, always in view: the attending's reply and Submit to attending.
## Once a plan is accepted the reply adds the debrief (WardRoundScoring), and
## Replay case starts the patient again for a better score.
## The screen owns only the unsent plan; everything else is in WardRounds.
## Button handlers are public so tests drive the same paths a player does.

const PANEL_ID: String = "ward_round"
const TABS: Array[String] = ["Bedside", "Chart", "Labs", "Plan", "Debrief"]
const SIZE_TITLE: int = 32
const SIZE_HEADING: int = 25
const SIZE_BODY: int = 22
const SIZE_SMALL: int = 20
const FLAG_COLORS: Dictionary = {"normal": UIStyle.GOOD, "abnormal": UIStyle.WARNING, "critical": Color(1.0, 0.45, 0.4)}

var is_open: bool = false
var case_id: String = ""

## Unsent plans: case id -> {"meds": {med_id: action}, "start": [ids], "int": [ids]}.
var _drafts: Dictionary = {}
var _census: ItemList
var _badge: Label
var _tabs: TabContainer
var _bedside: VBoxContainer
var _chart: VBoxContainer
## Bedside replies this visit, shown under the questions: case id -> [String].
var _transcript: Dictionary = {}
var _labs: VBoxContainer
var _plan: VBoxContainer
var _debrief: VBoxContainer
var _review: RichTextLabel
var _submit: Button
var _replay: Button
var _close_button: Button


func _ready() -> void:
	layer = 9
	_build()
	visible = false
	WardRounds.case_changed.connect(func(_id: String) -> void:
		if is_open:
			_refresh_census())


# --- Panel protocol (Main) ---------------------------------------------------------

## data: {"case_id": String (optional)}
func open(data: Dictionary = {}) -> void:
	visible = true
	is_open = true
	_refresh_census()
	var ids: Array[String] = WardRounds.admitted_case_ids()
	var wanted: String = str(data.get("case_id", ""))
	if not wanted in ids:
		wanted = _first_open(ids)
	select_case(wanted)
	_close_button.grab_focus()


func close() -> void:
	if not is_open:
		return
	visible = false
	is_open = false
	EventBus.ui_panel_closed.emit(PANEL_ID)


# --- Actions (buttons call these; so do tests) -----------------------------------

func select_case(id: String) -> void:
	case_id = id
	for i: int in _census.item_count:
		if _census.get_item_metadata(i) == id:
			_census.select(i)
	_badge.visible = WardRounds.is_draft(id)
	_build_bedside()
	_build_chart()
	_build_labs()
	_build_plan()
	_build_debrief()
	_show_review(WardRounds.last_review(id))
	# A patient not yet spoken to opens at the bedside; otherwise at the chart.
	var fresh: bool = not WardRounds.bedside().is_empty() and WardRounds.bedside_opening(id).is_empty() \
			and WardRounds.is_editable(id)
	show_tab("Bedside" if fresh else "Chart")


## Bedside actions (buttons call these; so do tests).
func open_bedside(opening_id: String) -> String:
	var text: String = WardRounds.open_bedside(case_id, opening_id)
	_after_bedside(text)
	return text


func ask(question_id: String) -> String:
	var text: String = WardRounds.ask_bedside(case_id, question_id)
	_after_bedside(text)
	return text


func repair() -> String:
	var text: String = WardRounds.repair_bedside(case_id)
	_after_bedside(text)
	return text


func _after_bedside(text: String) -> void:
	if text.is_empty():
		return
	if not _transcript.has(case_id):
		_transcript[case_id] = []
	_transcript[case_id].append(text)
	_build_bedside()
	_build_chart()


func show_tab(tab_name: String) -> void:
	_tabs.current_tab = TABS.find(tab_name)


func order_lab(lab_id: String) -> bool:
	if not WardRounds.order_lab(case_id, lab_id):
		return false
	_build_labs()
	return true


func set_med_action(med_id: String, action: String) -> void:
	_draft()["meds"][med_id] = action


func set_start(med_id: String, on: bool) -> void:
	_toggle(_draft()["start"], med_id, on)


func set_intervention(intervention_id: String, on: bool) -> void:
	_toggle(_draft()["int"], intervention_id, on)


## The unsent plan as WardRounds plan items.
func current_plan() -> Array:
	var draft: Dictionary = _draft()
	var plan: Array = []
	for med: Dictionary in WardRounds.get_case(case_id).get("presentation", {}).get("current_medications", []):
		plan.append("%s:%s" % [draft["meds"].get(med["id"], "continue"), med["id"]])
	for id: String in draft["start"]:
		plan.append("start:" + id)
	for id: String in draft["int"]:
		plan.append("int:" + id)
	return plan


## Starts an accepted case again for a better score (the chapter stays open).
func replay() -> bool:
	if not WardRounds.replay_case(case_id):
		return false
	_drafts.erase(case_id)
	_transcript.erase(case_id)
	select_case(case_id)
	return true


func submit() -> Dictionary:
	var review: Dictionary = WardRounds.submit_plan(case_id, current_plan())
	if not review.is_empty():
		_build_plan()
		_build_debrief()
		_show_review(review)
		if review["outcome"] == WardRoundCatalog.ACCEPTED:
			_refresh_census()
			show_tab("Debrief")
	return review


# --- Content -----------------------------------------------------------------------

func _refresh_census() -> void:
	_census.clear()
	for id: String in WardRounds.admitted_case_ids():
		var case: Dictionary = WardRounds.get_case(id)
		var done: bool = WardRounds.status(id) == WardRounds.STATUS_ACCEPTED and not WardRounds.is_replaying(id)
		var mark: String = "↻" if WardRounds.is_replaying(id) else ("✓" if done else "•")
		var best: int = WardRounds.best_score(id)
		var suffix: String = "  ·  %d" % best if best >= 0 else ""
		_census.add_item("%s %s%s" % [mark, case["patient"]["name"], suffix])
		_census.set_item_metadata(_census.item_count - 1, id)
		_census.set_item_custom_fg_color(_census.item_count - 1, UIStyle.GOOD if done else UIStyle.TEXT)
		if id == case_id:
			_census.select(_census.item_count - 1)


func _build_chart() -> void:
	_clear(_chart)
	var case: Dictionary = WardRounds.get_case(case_id)
	if case.is_empty():
		_chart.add_child(UIStyle.label("No ward-round patients yet. New patients are admitted as each chapter begins.", SIZE_BODY, UIStyle.MUTED))
		return
	var patient: Dictionary = case["patient"]
	var presentation: Dictionary = case["presentation"]
	var referral: String = ""
	if presentation.has("triage_label"):
		# The referral's working label; it can be incomplete or wrong.
		referral = "[b]Referred as[/b]  \"%s\"\n\n" % presentation["triage_label"]
	_chart.add_child(_card("%s, %d" % [patient["name"], int(patient["age"])],
			"%s[b]Reason for review[/b]\n%s" % [referral, presentation["reason"]], UIStyle.ACCENT))
	for row: Array in [["History", "history"], ["Mental state", "mental_status"], ["Vitals and examination", "vitals"]]:
		if WardRounds.is_revealed(case_id, row[1]):
			_chart.add_child(_card(row[0], presentation[row[1]]))
		else:
			_chart.add_child(_card(row[0], "[color=#%s]Not yet heard. Ask at the bedside (Bedside tab).[/color]" % UIStyle.MUTED.to_html(false)))
	var meds: Array[String] = []
	for med: Dictionary in presentation["current_medications"]:
		meds.append("• " + str(med["label"]))
	_chart.add_child(_card("Current medications", "\n".join(meds) if not meds.is_empty() else "None"))


func _build_bedside() -> void:
	_clear(_bedside)
	var case: Dictionary = WardRounds.get_case(case_id)
	var block: Dictionary = WardRounds.bedside()
	if case.is_empty() or block.is_empty():
		_bedside.add_child(UIStyle.label("No bedside conversation for this patient.", SIZE_BODY, UIStyle.MUTED))
		return
	var editable: bool = WardRounds.is_editable(case_id)
	var opening: String = WardRounds.bedside_opening(case_id)
	_bedside.add_child(UIStyle.label("At the bedside with %s" % case["patient"]["name"], SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
	if opening.is_empty():
		_bedside.add_child(UIStyle.label("How do you open the conversation? It sets how much they are willing to tell you, and the debrief counts it.", SIZE_SMALL, UIStyle.MUTED))
		for entry: Dictionary in block["openings"]:
			var button: Button = _choice_button(entry["label"], "Open_" + str(entry["id"]))
			button.disabled = not editable
			button.pressed.connect(func() -> void: open_bedside(entry["id"]))
			_bedside.add_child(button)
	else:
		var asked: Array = WardRounds.bedside_asked(case_id)
		for entry: Dictionary in block["questions"]:
			var revealed: bool = WardRounds.is_revealed(case_id, entry["field"])
			var button: Button = _choice_button(("✓ " if revealed else "") + str(entry["label"]), "Ask_" + str(entry["id"]))
			button.disabled = not editable or revealed
			button.pressed.connect(func() -> void: ask(entry["id"]))
			_bedside.add_child(button)
		if WardRounds.bedside_trust(case_id) < 1 and not asked.is_empty():
			var mend: Button = _choice_button(block["repair"]["label"], "Repair")
			mend.disabled = not editable
			mend.pressed.connect(repair)
			_bedside.add_child(mend)
	var lines: Array = _transcript.get(case_id, [])
	if not lines.is_empty():
		var card: PanelContainer = _card("What you learn", "\n\n".join(lines.map(func(line: String) -> String: return "• " + line)))
		card.find_children("*", "RichTextLabel", true, false)[0].name = "BedsideReplies"
		_bedside.add_child(card)
	if not opening.is_empty() and editable:
		_bedside.add_child(UIStyle.label("Answers are added to the Chart tab.", SIZE_SMALL, UIStyle.MUTED))


func _choice_button(text: String, node_name: String) -> Button:
	var button: Button = UIStyle.secondary_button(text, SIZE_BODY)
	button.name = node_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _build_labs() -> void:
	_clear(_labs)
	if case_id.is_empty():
		return
	var ordered: Array = WardRounds.ordered_labs(case_id)
	var locked: bool = not WardRounds.is_editable(case_id)
	_labs.add_child(UIStyle.label("Order what this presentation needs. Results come back straight away.", SIZE_SMALL, UIStyle.MUTED))
	var budget: int = WardRounds.tests_budget(case_id)
	var over: bool = ordered.size() > budget
	var meter: Label = UIStyle.label("Tests ordered: %d of a budget of %d%s" % [ordered.size(), budget,
			"  ·  over budget: each extra test costs resource points" if over else "  ·  going over costs resource points but never stops an order"],
			SIZE_BODY, UIStyle.WARNING if over else UIStyle.TEXT)
	meter.name = "Budget"
	_labs.add_child(meter)
	var category: String = ""
	for lab: Dictionary in WardRounds.lab_catalog():
		if lab.get("category", "") != category:
			category = str(lab.get("category", ""))
			_labs.add_child(UIStyle.label(category, SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var name_label: Label = UIStyle.label(lab["label"], SIZE_BODY)
		name_label.custom_minimum_size.x = 520
		row.add_child(name_label)
		if lab["id"] in ordered:
			var result: Dictionary = WardRounds.lab_result(case_id, lab["id"])
			var text: Label = UIStyle.label(result["result"], SIZE_BODY, FLAG_COLORS.get(result["flag"], UIStyle.TEXT))
			text.name = "Result_" + str(lab["id"])
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(text)
		else:
			var order: Button = UIStyle.secondary_button("Order", SIZE_SMALL)
			order.name = "Order_" + str(lab["id"])
			order.disabled = locked
			order.pressed.connect(order_lab.bind(lab["id"]))
			row.add_child(order)
		_labs.add_child(row)


func _build_plan() -> void:
	_clear(_plan)
	var case: Dictionary = WardRounds.get_case(case_id)
	if case.is_empty():
		_submit.disabled = true
		_replay.visible = false
		return
	var locked: bool = not WardRounds.is_editable(case_id)
	_submit.disabled = locked
	_submit.text = "Plan accepted" if locked else "Submit to attending"
	_replay.visible = locked
	var draft: Dictionary = _draft()
	var current: Array = case["presentation"]["current_medications"]
	var current_ids: Array = current.map(func(med: Dictionary) -> String: return med["id"])
	_plan.add_child(UIStyle.label("Current medications", SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
	if current.is_empty():
		_plan.add_child(UIStyle.label("None", SIZE_BODY, UIStyle.MUTED))
	for med: Dictionary in current:
		var row: HBoxContainer = HBoxContainer.new()
		var name_label: Label = UIStyle.label(med["label"], SIZE_BODY)
		name_label.custom_minimum_size.x = 420
		row.add_child(name_label)
		var choice: OptionButton = OptionButton.new()
		choice.name = "Action_" + str(med["id"])
		choice.add_theme_font_size_override("font_size", SIZE_BODY)
		for action: String in WardRoundCatalog.MED_ACTIONS:
			choice.add_item(action.capitalize())
		choice.select(WardRoundCatalog.MED_ACTIONS.find(draft["meds"].get(med["id"], "continue")))
		choice.disabled = locked
		choice.item_selected.connect(func(index: int) -> void: set_med_action(med["id"], WardRoundCatalog.MED_ACTIONS[index]))
		row.add_child(choice)
		_plan.add_child(row)
	_plan.add_child(UIStyle.label("Start", SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
	var starts: Array = WardRounds.medication_catalog().filter(func(med: Dictionary) -> bool: return not med["id"] in current_ids)
	_plan.add_child(_check_grid(starts, draft["start"], "Start_", locked, set_start))
	_plan.add_child(UIStyle.label("Interventions", SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
	_plan.add_child(_check_grid(WardRounds.intervention_catalog(), draft["int"], "Int_", locked, set_intervention))


func _check_grid(entries: Array, chosen: Array, prefix: String, locked: bool, setter: Callable) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	for entry: Dictionary in entries:
		var toggle: Button = _toggle_button(entry["label"])
		toggle.name = prefix + str(entry["id"])
		toggle.tooltip_text = str(entry.get("class", ""))
		toggle.button_pressed = entry["id"] in chosen
		toggle.disabled = locked
		if locked and toggle.button_pressed:
			# An accepted plan keeps showing what was chosen.
			toggle.add_theme_stylebox_override("disabled", toggle.get_theme_stylebox("pressed"))
			toggle.add_theme_color_override("font_disabled_color", Color.WHITE)
		toggle.toggled.connect(func(on: bool) -> void: setter.call(entry["id"], on))
		grid.add_child(toggle)
	return grid


## A chip-like toggle: outlined when off, filled teal when chosen.
func _toggle_button(text: String) -> Button:
	var toggle: Button = UIStyle.secondary_button(text, SIZE_SMALL)
	toggle.toggle_mode = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Long labels wrap inside the chip instead of widening the whole screen.
	toggle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toggle.custom_minimum_size.x = 220
	var on: StyleBoxFlat = (toggle.get_theme_stylebox("normal") as StyleBoxFlat).duplicate()
	on.bg_color = Color(0.16, 0.42, 0.36)
	on.border_color = UIStyle.ACCENT
	toggle.add_theme_stylebox_override("pressed", on)
	toggle.add_theme_stylebox_override("hover_pressed", on)
	toggle.add_theme_color_override("font_pressed_color", Color.WHITE)
	toggle.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	return toggle


func _show_review(review: Dictionary) -> void:
	# Only assign text: clear() followed by the same text again leaves it blank.
	if review.is_empty():
		var replaying: String = "Replay: the chapter stays open and your best score is kept. " if WardRounds.is_replaying(case_id) else ""
		_review.text = "[color=#%s]%sSubmit the plan when you are ready. The attending replies straight away; you can revise and resubmit, but the debrief counts every attempt.[/color]" % [UIStyle.MUTED.to_html(false), replaying]
		return
	var labels: Dictionary = WardRounds.labels()
	var lines: Array[String] = []
	if review["outcome"] == WardRoundCatalog.ACCEPTED:
		lines.append("[color=#%s][b]Attending: plan accepted.[/b][/color]" % UIStyle.GOOD.to_html(false))
	else:
		lines.append("[color=#%s][b]Attending: revise the plan.[/b][/color]" % UIStyle.WARNING.to_html(false))
		for problem: Dictionary in review["problems"]:
			lines.append("• [b]%s[/b]: %s" % [WardRoundCatalog.describe_item(problem["item"], labels), problem["reason"]])
	for item: Dictionary in review["good"]:
		lines.append("[color=#%s]✓ %s: %s[/color]" % [UIStyle.GOOD.to_html(false),
				WardRoundCatalog.describe_item(item["item"], labels), item["reason"]])
	for note: Dictionary in review["notes"]:
		lines.append("[color=#%s]Note, %s: %s[/color]" % [UIStyle.MUTED.to_html(false),
				WardRoundCatalog.describe_item(note["item"], labels), note["reason"]])
	if review["outcome"] == WardRoundCatalog.ACCEPTED:
		lines.append("\n[b]Teaching point[/b]\n" + str(review["teaching"]))
		var scored: Dictionary = WardRounds.score(case_id)
		if not scored.is_empty():
			lines.append("\n[b]Debrief: %d / 100 · %s[/b] (Debrief tab)" % [scored["total"], scored["grade"]])
	_review.text = "\n".join(lines)


func _build_debrief() -> void:
	_clear(_debrief)
	var scored: Dictionary = WardRounds.score(case_id) if not case_id.is_empty() else {}
	if scored.is_empty():
		_debrief.add_child(UIStyle.label("The debrief appears here once the attending accepts a plan. It scores patient safety (40%), diagnostic reasoning (25%), rapport and communication (20%) and resource use (15%), counting every attempt.", SIZE_BODY, UIStyle.MUTED))
		return
	var text: RichTextLabel = _rich(true)
	text.name = "DebriefText"
	text.text = "\n".join(_debrief_lines(scored)).strip_edges()
	_debrief.add_child(text)
	_debrief.add_child(UIStyle.label("Replay case starts this patient again for a better score. The chapter stays open and your best score is kept.", SIZE_SMALL, UIStyle.MUTED))


## The debrief: total and grade, then each area with what went well or not.
func _debrief_lines(scored: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if scored.is_empty():
		return lines
	var colour: Color = UIStyle.WARNING if scored["capped"] else UIStyle.GOOD
	lines.append("\n[color=#%s][b]Debrief: %d / 100 · %s[/b][/color]" % [colour.to_html(false), scored["total"], scored["grade"]])
	if scored["capped"]:
		lines.append("[color=#%s]An unsafe or dismissive choice caps the grade, however good the rest of the plan.[/color]" % UIStyle.WARNING.to_html(false))
	var best: int = WardRounds.best_score(case_id)
	if best > int(scored["total"]):
		lines.append("[color=#%s]Your best on this patient: %d.[/color]" % [UIStyle.MUTED.to_html(false), best])
	for area: String in WardRoundScoring.AREAS:
		lines.append("[b]%s[/b] (%d%%): %d" % [WardRoundScoring.LABELS[area], roundi(WardRoundScoring.WEIGHTS[area] * 100), scored["areas"][area]])
		for finding: Dictionary in scored["findings"]:
			if finding["area"] == area:
				lines.append("[color=#%s]  %s %s[/color]" % [(UIStyle.GOOD if finding["good"] else UIStyle.WARNING).to_html(false),
						"✓" if finding["good"] else "•", finding["text"]])
	return lines


# --- Helpers -------------------------------------------------------------------------

func _draft() -> Dictionary:
	if not _drafts.has(case_id):
		var draft: Dictionary = {"meds": {}, "start": [], "int": []}
		for key: String in WardRounds.submitted_plan(case_id):
			var parts: PackedStringArray = key.split(":", true, 1)
			if parts[0] in WardRoundCatalog.MED_ACTIONS:
				draft["meds"][parts[1]] = parts[0]
			elif parts[0] in ["start", "int"]:
				draft[parts[0]].append(parts[1])
		_drafts[case_id] = draft
	return _drafts[case_id]


func _toggle(list: Array, id: String, on: bool) -> void:
	if on and not id in list:
		list.append(id)
	elif not on:
		list.erase(id)


func _first_open(ids: Array[String]) -> String:
	for id: String in ids:
		if WardRounds.status(id) != WardRounds.STATUS_ACCEPTED:
			return id
	return ids[0] if not ids.is_empty() else ""


func _clear(box: Node) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _card(heading: String, body: String, accent: Color = UIStyle.BORDER) -> PanelContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(UIStyle.label(heading, SIZE_HEADING, UIStyle.ACCENT.lightened(0.2)))
	var text: RichTextLabel = _rich(true)
	text.text = body
	box.add_child(text)
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.card_style(accent))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(box)
	return card


func _rich(fit: bool) -> RichTextLabel:
	var text: RichTextLabel = UIStyle.rich_text(fit)
	for font: String in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		text.add_theme_font_size_override(font, SIZE_BODY)
	text.add_theme_constant_override("line_separation", 4)
	return text


func _scroll_tab(tab_name: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	_tabs.add_child(scroll)
	return box


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
	top.add_theme_constant_override("separation", 16)
	var title: Label = UIStyle.label("Ward round", SIZE_TITLE)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(title)
	_badge = UIStyle.label("DRAFT TEACHING CASE · pending psychiatrist review", SIZE_SMALL, UIStyle.WARNING)
	_badge.name = "DraftBadge"
	_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_badge)
	_close_button = UIStyle.secondary_button("Close  (Esc)", SIZE_BODY)
	_close_button.pressed.connect(close)
	top.add_child(_close_button)
	column.add_child(top)
	column.add_child(UIStyle.label("Each chapter admits new patients. Talk with them at the bedside, read the chart, order the tests the presentation needs, then submit a medication plan. The chapter cannot close until each of its patients has an accepted plan.", SIZE_SMALL, UIStyle.MUTED))

	var split: HSplitContainer = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(split)
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size.x = 300
	left.add_child(UIStyle.label("Patients", SIZE_HEADING, UIStyle.MUTED))
	_census = ItemList.new()
	_census.name = "Census"
	_census.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_census.add_theme_font_size_override("font_size", SIZE_BODY)
	_census.add_theme_constant_override("v_separation", 10)
	_census.item_selected.connect(func(index: int) -> void: select_case(_census.get_item_metadata(index)))
	left.add_child(_census)
	split.add_child(left)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	split.add_child(right)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_size_override("font_size", SIZE_BODY)
	right.add_child(_tabs)
	_bedside = _scroll_tab("Bedside")
	_chart = _scroll_tab("Chart")
	_labs = _scroll_tab("Labs")
	_plan = _scroll_tab("Plan")
	_debrief = _scroll_tab("Debrief")
	# The attending's reply and the submit button stay in view on every tab.
	var reply: HBoxContainer = HBoxContainer.new()
	reply.add_theme_constant_override("separation", 16)
	_review = _rich(false)
	_review.name = "Review"
	_review.custom_minimum_size.y = 230
	_review.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.card_style(UIStyle.ACCENT))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(_review)
	reply.add_child(card)
	_submit = UIStyle.primary_button("Submit to attending", SIZE_BODY)
	_submit.name = "Submit"
	_submit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_submit.pressed.connect(submit)
	var buttons: VBoxContainer = VBoxContainer.new()
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons.add_theme_constant_override("separation", 10)
	buttons.add_child(_submit)
	_replay = UIStyle.secondary_button("Replay case", SIZE_BODY)
	_replay.name = "Replay"
	_replay.tooltip_text = "Start this patient again for a better score. The chapter stays open."
	_replay.visible = false
	_replay.pressed.connect(replay)
	buttons.add_child(_replay)
	reply.add_child(buttons)
	right.add_child(reply)
