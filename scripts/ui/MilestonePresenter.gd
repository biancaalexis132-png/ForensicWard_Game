class_name MilestonePresenter
extends CanvasLayer
## MilestonePresenter: a short split-screen moment after a meaningful
## objective is done (data/milestones.json). Two existing plates side by side,
## each captioned with existing objective text, so it adds no new story text.
##
## It only presents. It never grants evidence, sets flags, plays dialogue or
## assumes an outcome: the milestone follows an objective the player already
## completed, and its only saved state is which milestones were shown, so a
## load never replays one. Only approved milestones play in the campaign;
## others play with `-- --milestone-preview=<id>` for review.
## Controls: Esc or Enter skips, P pauses, R replays. Main owns the panel
## protocol (open/close/is_open) and restores input when it closes.

signal finished(milestone_id: String, reason: String)

const PANEL_ID: String = "milestone"
const DATA_PATH: String = "res://data/milestones.json"
const PROVIDER_KEY: String = "milestones"
const ARG_PREFIX: String = "--milestone-preview="
const FADE_SECONDS: float = 0.6

var is_open: bool = false
var is_paused: bool = false
var milestone_id: String = ""
## Plays unapproved milestones too (review preview and tests).
var review_mode: bool = false

var _milestones: Array[Dictionary] = []
var _shown: Array[String] = []
var _pending: Array[String] = []
var _elapsed: float = 0.0
var _duration: float = 0.0
var _root: Control
var _sides: Array[TextureRect] = []
var _captions: Array[Label] = []
var _hint: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	visible = false
	_build()
	_milestones = load_milestones()
	SaveManager.register_provider(PROVIDER_KEY, self)
	EventBus.objective_changed.connect(func(_id: String, _text: String) -> void: check_milestones())
	for arg: String in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with(ARG_PREFIX):
			review_mode = true
			_preview.call_deferred(arg.trim_prefix(ARG_PREFIX))


func _exit_tree() -> void:
	SaveManager.unregister_provider(PROVIDER_KEY)


## The milestones in data/milestones.json that pass validate(); problems are warnings.
static func load_milestones() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
	if not data is Dictionary:
		return result
	for entry: Variant in (data as Dictionary).get("milestones", []):
		var problems: Array[String] = validate(entry)
		if problems.is_empty():
			result.append(entry)
		else:
			push_warning("MilestonePresenter: %s" % "; ".join(problems))
	return result


## Problems with one milestone entry; [] when it can play.
static func validate(entry: Variant) -> Array[String]:
	if not entry is Dictionary:
		return ["milestone must be an object"]
	var errors: Array[String] = []
	var id: String = str(entry.get("id", ""))
	if not id.begins_with("ms_"):
		errors.append("id must start with ms_: '%s'" % id)
	var story: Dictionary = ContentRegistry.get_story(str(entry.get("chapter_id", "")))
	var objectives: Array = story.get("objectives", []).map(func(o: Dictionary) -> String: return o["id"])
	if not str(entry.get("after_objective", "")) in objectives:
		errors.append("%s: after_objective must be an objective of its chapter" % id)
	if not entry.get("approved") is bool:
		errors.append("%s: approved must be true or false" % id)
	if float(entry.get("duration_seconds", 0.0)) <= 0.0:
		errors.append("%s: duration_seconds must be positive" % id)
	for side: String in ["left", "right"]:
		var panel: Variant = entry.get(side)
		if not panel is Dictionary:
			errors.append("%s: %s must be an object" % [id, side])
			continue
		if not ResourceLoader.exists(str(panel.get("texture", ""))):
			errors.append("%s: %s.texture is missing" % [id, side])
		if not str(panel.get("caption_objective", "")) in objectives:
			errors.append("%s: %s.caption_objective must be an objective of its chapter" % [id, side])
	return errors


func get_milestone(id: String) -> Dictionary:
	for entry: Dictionary in _milestones:
		if entry["id"] == id:
			return entry
	return {}


func get_captions() -> Array[String]:
	var texts: Array[String] = []
	for caption: Label in _captions:
		texts.append(caption.text)
	return texts


func has_shown(id: String) -> bool:
	return id in _shown


## Queues every playable milestone whose objective is now done. Main shows the
## queue when nothing else is on screen (flush_pending).
func check_milestones() -> void:
	var director: ChapterDirector = get_tree().get_first_node_in_group(ChapterDirector.GROUP) if is_inside_tree() else null
	if director == null:
		return
	var done: Array = director.get_objective_list().filter(func(o: Dictionary) -> bool: return o["status"] == "done") \
			.map(func(o: Dictionary) -> String: return o["id"])
	for entry: Dictionary in _milestones:
		var id: String = entry["id"]
		if entry["chapter_id"] != director.get_chapter_id() or id in _shown or id in _pending:
			continue
		if (entry["approved"] or review_mode) and entry["after_objective"] in done:
			_pending.append(id)
	if not _pending.is_empty():
		EventBus.ui_panel_requested.emit(PANEL_ID, {})


## Shows the next queued milestone. Returns false when there is none.
func flush_pending() -> bool:
	if is_open or _pending.is_empty():
		return false
	return open({"milestone_id": _pending.pop_front()})


## Panel protocol. data: {"milestone_id": id} or {} for the next queued one.
func open(data: Dictionary) -> bool:
	var id: String = str(data.get("milestone_id", ""))
	if id.is_empty():
		return flush_pending()
	var entry: Dictionary = get_milestone(id)
	if entry.is_empty() or is_open or not (entry["approved"] or review_mode):
		return false
	milestone_id = id
	if not id in _shown:
		_shown.append(id)
	_present(entry)
	return true


## Skips to the end. Same as close(); safe to call any number of times.
func skip() -> void:
	close()


func close() -> void:
	if not is_open:
		return
	_finish("skipped" if _elapsed < _duration else "completed")


func toggle_pause() -> void:
	if is_open:
		is_paused = not is_paused
		_hint.text = _hint_text()


func replay() -> void:
	var entry: Dictionary = get_milestone(milestone_id)
	if entry.is_empty():
		return
	if is_open:
		_present(entry)
	else:
		open({"milestone_id": milestone_id})


func advance(delta: float) -> void:
	if not is_open or is_paused:
		return
	_elapsed += delta
	var fade: float = 1.0
	if not Settings.get_value("reduce_motion"):
		fade = clampf(minf(_elapsed, _duration - _elapsed) / FADE_SECONDS, 0.0, 1.0)
	_root.modulate.a = fade
	if _elapsed >= _duration:
		_finish("completed")


func _process(delta: float) -> void:
	advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_accept"):
		skip()
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_P: toggle_pause()
			KEY_R: replay()
			_: return
	else:
		return
	get_viewport().set_input_as_handled()


func _present(entry: Dictionary) -> void:
	var story: Dictionary = ContentRegistry.get_story(entry["chapter_id"])
	for index: int in 2:
		var panel: Dictionary = entry["left" if index == 0 else "right"]
		_sides[index].texture = load(panel["texture"])
		for objective: Dictionary in story.get("objectives", []):
			if objective["id"] == panel["caption_objective"]:
				_captions[index].text = objective["text"]
	_elapsed = 0.0
	_duration = float(entry["duration_seconds"])
	is_paused = false
	_root.modulate.a = 1.0 if Settings.get_value("reduce_motion") else 0.0
	_hint.text = _hint_text()
	visible = true
	is_open = true


func _finish(reason: String) -> void:
	visible = false
	is_open = false
	is_paused = false
	for side: TextureRect in _sides:
		side.texture = null  # Release the plates; nothing stays resident.
	finished.emit(milestone_id, reason)
	EventBus.ui_panel_closed.emit(PANEL_ID)


func _hint_text() -> String:
	return "Esc Skip · P %s · R Replay" % ("Resume" if is_paused else "Pause")


func _preview(id: String) -> void:
	if not open({"milestone_id": id}):
		push_warning("MilestonePresenter: cannot preview '%s'" % id)


# --- Save provider: only which milestones were shown ------------------------------

func to_save_data() -> Dictionary:
	return {"shown": _shown.duplicate()}


func load_save_data(data: Dictionary) -> void:
	reset_state()
	_shown.assign(data.get("shown", []))


func reset_state() -> void:
	if is_open:
		_finish("restored")
	_shown.clear()
	_pending.clear()
	milestone_id = ""


# --- Construction --------------------------------------------------------------

func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.02, 0.025, 0.03, 0.92)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_root = HBoxContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_theme_constant_override("separation", 12)
	add_child(_root)
	for index: int in 2:
		var column: VBoxContainer = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var art: TextureRect = TextureRect.new()
		art.name = "Left" if index == 0 else "Right"
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(art)
		var caption: Label = Label.new()
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.add_theme_font_size_override("font_size", 20)
		caption.custom_minimum_size.y = 70
		column.add_child(caption)
		_root.add_child(column)
		_sides.append(art)
		_captions.append(caption)
	_hint = Label.new()
	_hint.anchor_left = 1.0
	_hint.anchor_right = 1.0
	_hint.offset_left = -340
	_hint.offset_top = 12
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.modulate = Color(0.75, 0.77, 0.8)
	add_child(_hint)
