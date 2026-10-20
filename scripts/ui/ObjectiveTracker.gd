class_name ObjectiveTracker
extends CanvasLayer
## ObjectiveTracker: objective feedback. A small checklist of the chapter's
## done and current objectives, an "Objective complete" banner with a quiet
## chime when the current one is finished, then a "New objective" notice.
##
## The objectives and their status come from ChapterDirector.get_objective_list()
## (saved story state); this node keeps no objective list of its own. It saves
## only which ids it has already announced, so loading a save, restarting a
## chapter or re-evaluating never repeats a banner. Upcoming objectives are
## never shown, so the checklist cannot spoil what comes next.
## Settings: objective_checklist, objective_banners, objective_sound; with
## reduce_motion the banner appears and leaves without fading.

const PROVIDER_KEY: String = "objective_feedback"
const BANNER_SECONDS: float = 3.2
const FADE_SECONDS: float = 0.35
const COMPLETE_CUE: String = "sfx_ui_terminal_open"

## Banner texts shown so far this session, oldest first (tests and QA read it).
var banner_log: Array[String] = []

var _announced: Array[String] = []
var _completed: Array[String] = []
var _current_id: String = ""
var _queue: Array[Dictionary] = []
var _showing: bool = false
var _checklist: RichTextLabel
var _banner: PanelContainer
var _banner_title: Label
var _banner_text: Label


func _ready() -> void:
	layer = 2
	_build()
	SaveManager.register_provider(PROVIDER_KEY, self)
	EventBus.objective_changed.connect(_on_objective_changed)
	EventBus.settings_changed.connect(func(key: String, value: Variant) -> void:
		if key == "objective_banners" and not value:
			_queue.clear()
			_showing = false
			_banner.visible = false
		if key.begins_with("objective"):
			refresh())
	refresh()


func _exit_tree() -> void:
	SaveManager.unregister_provider(PROVIDER_KEY)


## Checklist text as shown (BBCode stripped), for tests and screen readers.
func get_checklist_text() -> String:
	return _checklist.get_parsed_text() if _checklist.visible else ""


func is_banner_showing() -> bool:
	return _showing


func refresh() -> void:
	var lines: PackedStringArray = []
	for objective: Dictionary in _objectives():
		match objective["status"]:
			"done":
				lines.append("[color=#8fa39d][s]%s[/s][/color]" % _escape(objective["text"]))
			"current":
				lines.append("[b]• %s[/b]" % _escape(objective["text"]))
	_checklist.text = "\n".join(lines)
	_checklist.visible = Settings.get_value("objective_checklist") and not lines.is_empty()


# --- Feedback --------------------------------------------------------------------

func _on_objective_changed(objective_id: String, text: String) -> void:
	var previous: String = _current_id
	_current_id = objective_id
	if not previous.is_empty() and previous != objective_id and not previous in _completed:
		for objective: Dictionary in _objectives():
			if objective["id"] == previous and objective["status"] == "done":
				_completed.append(previous)
				_announce("Objective complete", objective["text"], true)
	if not objective_id.is_empty() and not objective_id in _announced:
		_announced.append(objective_id)
		_announce("New objective", text, false)
	refresh()


func _announce(title: String, text: String, chime: bool) -> void:
	banner_log.append("%s: %s" % [title, text])
	if not Settings.get_value("objective_banners"):
		return
	_queue.append({"title": title, "text": text, "chime": chime})
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		_banner.visible = false
		return
	_showing = true
	var next: Dictionary = _queue.pop_front()
	_banner_title.text = next["title"]
	_banner_text.text = next["text"]
	_banner.visible = true
	if next["chime"] and Settings.get_value("objective_sound"):
		AudioDirector.play_sfx(COMPLETE_CUE)
	var tween: Tween = create_tween()
	if Settings.get_value("reduce_motion"):
		_banner.modulate.a = 1.0
		tween.tween_interval(BANNER_SECONDS)
	else:
		_banner.modulate.a = 0.0
		tween.tween_property(_banner, "modulate:a", 1.0, FADE_SECONDS)
		tween.tween_interval(BANNER_SECONDS)
		tween.tween_property(_banner, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(_show_next)


func _objectives() -> Array[Dictionary]:
	var director: ChapterDirector = get_tree().get_first_node_in_group(ChapterDirector.GROUP) if is_inside_tree() else null
	if director == null:
		var none: Array[Dictionary] = []
		return none
	return director.get_objective_list()


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


# --- Save provider ----------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"announced": _announced.duplicate(), "completed": _completed.duplicate()}


func load_save_data(data: Dictionary) -> void:
	_clear_feedback()
	_announced.assign(data.get("announced", []))
	_completed.assign(data.get("completed", []))


func reset_state() -> void:
	_clear_feedback()
	_announced.clear()
	_completed.clear()


func _clear_feedback() -> void:
	_current_id = ""
	_queue.clear()
	_showing = false
	if _banner != null:
		_banner.visible = false


# --- Construction ----------------------------------------------------------------

func _build() -> void:
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_checklist = RichTextLabel.new()
	_checklist.name = "Checklist"
	_checklist.bbcode_enabled = true
	_checklist.fit_content = true
	_checklist.scroll_active = false
	_checklist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_checklist.position = Vector2(24, 64)
	_checklist.custom_minimum_size = Vector2(420, 0)
	_checklist.add_theme_font_size_override("normal_font_size", 17)
	_checklist.add_theme_font_size_override("bold_font_size", 17)
	_checklist.add_theme_color_override("default_color", Color(0.92, 0.96, 0.94))
	_checklist.add_theme_color_override("font_outline_color", Color.BLACK)
	_checklist.add_theme_constant_override("outline_size", 5)
	root.add_child(_checklist)

	_banner = PanelContainer.new()
	_banner.name = "Banner"
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.offset_left = -300
	_banner.offset_right = 300
	_banner.offset_top = 90
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.06, 0.82)
	style.border_color = Color(0.55, 0.7, 0.66, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(14)
	_banner.add_theme_stylebox_override("panel", style)
	var column: VBoxContainer = VBoxContainer.new()
	_banner.add_child(column)
	_banner_title = Label.new()
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.add_theme_font_size_override("font_size", 16)
	_banner_title.add_theme_color_override("font_color", Color(0.6, 0.78, 0.72))
	column.add_child(_banner_title)
	_banner_text = Label.new()
	_banner_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_text.add_theme_font_size_override("font_size", 21)
	column.add_child(_banner_text)
	_banner.visible = false
	root.add_child(_banner)
