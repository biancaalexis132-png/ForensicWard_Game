class_name CutsceneDirector
extends CanvasLayer
## CutsceneDirector: plays a data-driven graphic-novel cutscene over the game
## and hands control back exactly as it found it.
##
## A cutscene (res://data/cutscenes/<id>.json, validated by CutsceneRegistry) is
## a list of painted panels. Each panel stacks up to three texture layers that
## drift by their own parallax factor while the panel slowly pushes or pans,
## then dissolves, cuts or fades through black into the next one. Campaign
## captions and optional recap narration come from validated authored registries.
## Narration uses AudioDirector without replaying gameplay dialogue or driving
## character lip-sync. Music runs as an AudioDirector music context
## and is handed back when the cutscene ends.
##
## Lifecycle: IDLE -> PRELOADING -> PLAYING -> RESTORING -> IDLE. Every exit
## (completed, skipped, invalid data, a loaded save, the node leaving the tree,
## the watchdog) goes through one idempotent _finish(), which stops the line,
## ends the music context, restores the mouse mode, frees the panels and
## emits ui_panel_closed so Main restores player input, HUD and the clock.
## Nothing here writes story, clinical, evidence or save state.
##
## Review-only gate: a cutscene with "approved": false plays only when
## review_mode is on, which only the --cutscene-preview=<id> argument, the
## review scene (scenes/cutscene/CutscenePreview.tscn) or tests turn on. The
## campaign triggers are chapter_start (title cards) and chapter_complete
## (approved illustrated recaps, after their gameplay events).
##
## Controls while playing: Esc skips, Enter / Space / E advances one panel,
## R replays; P pauses; V toggles narration. Reduce Motion holds each panel still.

signal finished(cutscene_id: String, reason: String)

enum State { IDLE, PRELOADING, PLAYING, RESTORING }

const PANEL_ID: String = "cutscene"
const ARG_PREFIX: String = "--cutscene-preview="
const MUSIC_CONTEXT_ID: String = "cutscene"
## Seconds past the authored length before the watchdog ends a stuck cutscene.
const WATCHDOG_MARGIN: float = 10.0
## The last panel dissolves into the game over this many seconds.
const EXIT_FADE_SECONDS: float = 0.9
## Inset frame margin as a fraction of the screen, and its border.
const INSET_MARGIN: float = 0.035
const PAGE_COLOR: Color = Color(0.055, 0.063, 0.082)
const BORDER_COLOR: Color = Color(0.93, 0.91, 0.85)
const CAPTION_BACKGROUND: Color = Color(0.93, 0.91, 0.85, 0.95)
const CAPTION_TEXT: Color = Color(0.09, 0.1, 0.13)
const PLACEHOLDER_COLOR: Color = Color(0.22, 0.25, 0.3)

## Lets unapproved cutscenes play. Set only by the preview argument, the review scene and tests.
var review_mode: bool = false
var is_open: bool = false
var state: State = State.IDLE
var cutscene_id: String = ""
var panel_index: int = -1
## Problems found while playing (missing textures fall back to a plain panel).
var runtime_errors: Array[String] = []

var _data: Dictionary = {}
var _last_data: Dictionary = {} ## For replay after the cutscene ended.
var _panel_time: float = 0.0
var _elapsed: float = 0.0
var _total: float = 0.0
var _saved_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _music_started: bool = false
var _line_id: String = ""
var _textures: Dictionary = {} ## path -> Texture2D, current and next panel only
var _requested: Dictionary = {} ## paths with a threaded load in flight
var _root: Control
var _page: ColorRect
var _current: Control
var _previous: Control
var _black: ColorRect
var _subtitle: Label
var _hint: Label
var _narration_data: Dictionary = {}
var _story_context: Dictionary = {}
var _track: Dictionary = {}
var _panel_duration: float = 0.0
var _voice_on: bool = false
var _voice_tail: float = -1.0
var narration_paused: bool = false
var _controls: HBoxContainer
var _pause_button: Button
var _voice_toggle: CheckBox


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	visible = false
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.subtitle_shown.connect(_on_subtitle_shown)
	EventBus.subtitle_cleared.connect(_on_subtitle_cleared)
	EventBus.settings_changed.connect(_on_narration_setting_changed)
	var preview_id: String = preview_request(OS.get_cmdline_user_args())
	if not preview_id.is_empty():
		review_mode = true
		# Through Main, so its input mode, HUD and clock follow the cutscene.
		EventBus.ui_panel_requested.emit.call_deferred(PANEL_ID, {"cutscene_id": preview_id})


func _exit_tree() -> void:
	_finish("interrupted")


## The cutscene id named by --cutscene-preview=<id>, or "".
static func preview_request(args: PackedStringArray) -> String:
	for arg: String in args:
		if arg.begins_with(ARG_PREFIX):
			return arg.trim_prefix(ARG_PREFIX).strip_edges()
	return ""


## Main's panel interface: data = {cutscene_id}.
func open(data: Dictionary) -> void:
	_story_context = (data.get("story_context", {}) as Dictionary).duplicate(true)
	play(str(data.get("cutscene_id", "")))


## The playing cutscene's trigger kind ("" when idle): Main's presentation state reads it.
func get_trigger_kind() -> String:
	return str((_data.get("trigger", {}) as Dictionary).get("kind", "")) if is_open else ""


## Main's panel interface: Esc on the top panel skips.
func close() -> void:
	skip()


## Starts a cutscene from res://data/cutscenes. Returns false (and reports why
## through `finished`) when it cannot play.
func play(id: String) -> bool:
	if not _can_start(id):
		return false
	var errors: Array[String] = []
	return _start(CutsceneRegistry.get_cutscene(id, errors), errors)


## Starts a cutscene from data that is not in res://data/cutscenes (review tools,
## tests). It is validated exactly like a file.
func play_data(data: Dictionary) -> bool:
	if not _can_start(str(data.get("cutscene_id", ""))):
		return false
	var errors: Array[String] = CutsceneRegistry.validate(data, CutsceneRegistry.reference_context())
	return _start(data if errors.is_empty() else {}, errors)


func _can_start(id: String) -> bool:
	if state != State.IDLE:
		push_warning("CutsceneDirector: '%s' is already playing; ignoring '%s'" % [cutscene_id, id])
		return false
	cutscene_id = id
	runtime_errors.clear()
	state = State.PRELOADING
	return true


func _start(data: Dictionary, errors: Array[String]) -> bool:
	if data.is_empty():
		for error: String in errors:
			push_warning("CutsceneDirector: %s: %s" % [cutscene_id, error])
		runtime_errors.append_array(errors)
		_finish("invalid")
		return false
	if not bool(data.get("approved", false)) and not review_mode:
		push_warning("CutsceneDirector: '%s' is not approved; it plays only in review mode" % cutscene_id)
		runtime_errors.append("not approved")
		_finish("not_approved")
		return false
	_data = data
	_last_data = data
	_narration_data = NarrationRegistry.load_data()
	if not NarrationRegistry.validate(_narration_data).is_empty():
		_narration_data = {}
	set_narration_paused(false)
	_saved_mouse_mode = Input.mouse_mode
	_total = _estimated_total(_data)
	_elapsed = 0.0
	is_open = true
	visible = true
	_hint.text = "Esc Skip · Enter Next · P Pause · R Replay · V Voice"
	_voice_toggle.set_pressed_no_signal(bool(Settings.get_value("recap_narration")))
	_start_music()
	state = State.PLAYING
	EventBus.cutscene_started.emit(cutscene_id)
	_show_panel(0)
	return true


## Ends the cutscene now. Nothing the cutscene would have shown is granted.
func skip() -> void:
	if state == State.PLAYING:
		_finish("skipped")


## Moves to the next panel, or ends the cutscene on the last one.
func next_panel() -> void:
	if state != State.PLAYING:
		return
	if panel_index + 1 >= _panels().size():
		_finish("completed")
	else:
		_elapsed = _panel_start_time(panel_index + 1)
		_show_panel(panel_index + 1)


## Plays the current (or last) cutscene again from its first panel.
func replay() -> void:
	if state == State.PLAYING:
		_stop_line()
		set_narration_paused(false)
		_elapsed = 0.0
		_show_panel(0)
	elif state == State.IDLE and not _last_data.is_empty():
		play_data(_last_data)


func get_total_seconds() -> float:
	return _total


## Advances playback; _process calls this, tests call it to step time exactly.
func advance(delta: float) -> void:
	if state != State.PLAYING or narration_paused or get_tree().paused:
		return
	_elapsed += delta
	_panel_time += delta
	if _elapsed > _total + _panels().size() * 5.0 + WATCHDOG_MARGIN:
		push_warning("CutsceneDirector: '%s' overran its length; restoring the game" % cutscene_id)
		_finish("timeout")
		return
	var panel: Dictionary = _panels()[panel_index]
	var duration: float = _panel_duration
	if _voice_on:
		if AudioDirector.narration_finished():
			if _voice_tail < 0.0:
				_voice_tail = _panel_time
			duration = maxf(float(panel["duration_seconds"]), _voice_tail + 0.5)
		elif _panel_time > minf(120.0, AudioDirector.narration_length() + 5.0):
			runtime_errors.append("narration timeout: " + str(_track.get("id", "")))
			AudioDirector.stop_narration()
			_voice_on = false
			duration = maxf(_panel_time + 0.5, _caption_duration(panel))
			_panel_duration = duration
		else:
			# The final image cannot fade out or advance before speech completes.
			duration = maxf(duration, _panel_time + EXIT_FADE_SECONDS)
	_update_narration_caption()
	if _panel_time >= duration:
		if panel_index + 1 >= _panels().size():
			_finish("completed")
		else:
			var overflow: float = _panel_time - duration
			_show_panel(panel_index + 1)
			if not _voice_on:
				_panel_time = overflow # Legacy visual timing; narration starts at audio zero.
		return
	_update_panel(panel, duration)


func _process(delta: float) -> void:
	if state == State.PLAYING and not get_tree().paused:
		advance(delta)


func _input(event: InputEvent) -> void:
	if not is_open or event is InputEventMouseButton or event is InputEventMouseMotion:
		return
	var key: InputEventKey = event as InputEventKey
	if event.is_pressed() and not event.is_echo():
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			skip()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			next_panel()
		elif key != null and key.physical_keycode == KEY_P:
			set_narration_paused(not narration_paused)
		elif key != null and key.physical_keycode == KEY_R:
			replay()
		elif key != null and key.physical_keycode == KEY_V:
			Settings.set_value("recap_narration", not bool(Settings.get_value("recap_narration")))
	get_viewport().set_input_as_handled()


# --- Panels ---------------------------------------------------------------------------

func _panels() -> Array:
	return _data.get("panels", [])


func _panel_start_time(index: int) -> float:
	var start: float = 0.0
	for i: int in index:
		start += _estimated_panel_duration(_panels()[i])
	return start


func _show_panel(index: int) -> void:
	_stop_line()
	if _previous != null:
		_previous.queue_free()
	_previous = _current
	panel_index = index
	_panel_time = 0.0
	var panel: Dictionary = _panels()[index]
	_current = _build_panel(panel)
	_root.add_child(_current)
	_root.move_child(_current, _black.get_index()) # Above the outgoing panel, under the overlays.
	_root.modulate.a = 1.0
	match str(panel.get("transition", "dissolve")):
		"cut":
			_drop_previous()
		"fade_black":
			_drop_previous()
	_release_textures_before(index)
	_request_textures(index + 1)
	_track = NarrationRegistry.resolve(str(panel.get("narration_ref", "")), _story_context, _narration_data)
	_panel_duration = _caption_duration(panel)
	_voice_tail = -1.0
	_voice_on = false
	if not _track.is_empty() and not (_track.get("cues", []) as Array).is_empty() and bool(Settings.get_value("recap_narration")):
		_voice_on = AudioDirector.play_narration(_track)
		if _voice_on:
			_panel_duration = maxf(float(panel["duration_seconds"]), AudioDirector.narration_length() + 0.5)
			AudioDirector.pause_narration(narration_paused)
	_update_narration_caption()
	_update_panel(panel, _panel_duration)
	var line_id: Variant = panel.get("line_id")
	if line_id != null:
		_line_id = str(line_id)
		AudioDirector.play_line(_line_id)


func _drop_previous() -> void:
	if _previous != null:
		_previous.queue_free()
		_previous = null


func _update_panel(panel: Dictionary, duration: float) -> void:
	var still: bool = bool(Settings.get_value("reduce_motion"))
	var progress: float = clampf(_panel_time / duration, 0.0, 1.0)
	var eased: float = progress * progress * (3.0 - 2.0 * progress)
	var motion: Dictionary = panel.get("motion", {})
	var zoom_from: float = float(motion.get("zoom_from", 1.0))
	var zoom_to: float = float(motion.get("zoom_to", 1.0))
	var pan_from: Array = motion.get("pan_from", [0.0, 0.0])
	var pan_to: Array = motion.get("pan_to", [0.0, 0.0])
	var zoom: float = zoom_to if still else lerpf(zoom_from, zoom_to, eased)
	var pan: Vector2 = Vector2(float(pan_to[0]), float(pan_to[1])) if still else Vector2(
			lerpf(float(pan_from[0]), float(pan_to[0]), eased), lerpf(float(pan_from[1]), float(pan_to[1]), eased))
	var reach: float = maxf(maxf(absf(float(pan_from[0])), absf(float(pan_from[1]))),
			maxf(absf(float(pan_to[0])), absf(float(pan_to[1]))))
	var art: Control = _current.get_node("Art")
	for layer_node: Node in art.get_children():
		var rect: Control = layer_node as Control
		var parallax: float = float(rect.get_meta("parallax", 1.0))
		# Oversize each layer by its widest pan, so panning never shows an edge;
		# layers with more parallax also zoom a little more, for depth.
		var cover: float = 1.0 + 2.0 * reach * parallax
		rect.pivot_offset = rect.size * 0.5
		rect.scale = Vector2.ONE * cover * (zoom + (parallax - 1.0) * (zoom - 1.0))
		rect.position = Vector2(pan.x * art.size.x, pan.y * art.size.y) * parallax
	var transition: String = str(panel.get("transition", "dissolve"))
	var transition_seconds: float = float(panel.get("transition_seconds", 0.0))
	var blend: float = 1.0 if transition == "cut" or transition_seconds <= 0.0 \
			else clampf(_panel_time / transition_seconds, 0.0, 1.0)
	if transition == "fade_black":
		_current.modulate.a = 1.0
		_black.color.a = 1.0 - blend
	else:
		_current.modulate.a = blend
		_black.color.a = 0.0
		if _previous != null and blend >= 1.0:
			_drop_previous()
	# The last panel dissolves into the game.
	if panel_index == _panels().size() - 1:
		_root.modulate.a = clampf((duration - _panel_time) / EXIT_FADE_SECONDS, 0.0, 1.0)


func _build_panel(panel: Dictionary) -> Control:
	var holder: Control = Control.new()
	holder.name = "Panel_%s" % panel.get("id", "")
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var full_bleed: bool = str(panel.get("frame", "inset")) == "full_bleed"
	var margin: float = 0.0 if full_bleed else INSET_MARGIN
	if not full_bleed:
		var border: ColorRect = ColorRect.new()
		border.color = BORDER_COLOR
		_set_inset(border, margin, 3.0)
		holder.add_child(border)
	var art: Control = Control.new()
	art.name = "Art"
	art.clip_contents = true
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_inset(art, margin, 0.0)
	holder.add_child(art)
	for layer: Dictionary in panel.get("layers", []):
		art.add_child(_build_layer(layer, panel))
	var caption_ref: Variant = panel.get("caption_ref")
	if caption_ref != null:
		var text: String = CutsceneRegistry.resolve_caption(str(caption_ref))
		if not text.is_empty():
			holder.add_child(_build_caption(text, margin))
	return holder


func _build_layer(layer: Dictionary, panel: Dictionary) -> Control:
	var path: String = str(layer.get("texture", ""))
	var texture: Texture2D = _texture(path)
	var rect: Control
	if texture != null:
		var image: TextureRect = TextureRect.new()
		image.texture = texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect = image
	else:
		runtime_errors.append("panel '%s': could not load %s" % [panel.get("id", ""), path])
		push_warning("CutsceneDirector: could not load %s; showing a plain panel" % path)
		var placeholder: ColorRect = ColorRect.new()
		# Only the base layer gets a fill, so a missing overlay stays invisible.
		placeholder.color = PLACEHOLDER_COLOR if float(layer.get("parallax", 1.0)) <= 1.0 else Color.TRANSPARENT
		rect = placeholder
	rect.name = "Layer"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.set_meta("parallax", float(layer.get("parallax", 1.0)))
	return rect


func _build_caption(text: String, margin: float) -> Control:
	var box: PanelContainer = PanelContainer.new()
	box.name = "Caption"
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = CAPTION_BACKGROUND
	style.border_color = CAPTION_TEXT
	style.set_border_width_all(2)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	box.add_theme_stylebox_override("panel", style)
	box.anchor_left = margin + 0.025
	box.anchor_top = margin + 0.04
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", int(26 * float(Settings.get_value("text_scale"))))
	label.add_theme_color_override("font_color", CAPTION_TEXT)
	box.add_child(label)
	return box


func _set_inset(control: Control, margin: float, grow_pixels: float) -> void:
	control.anchor_left = margin
	control.anchor_top = margin
	control.anchor_right = 1.0 - margin
	control.anchor_bottom = 1.0 - margin
	control.offset_left = -grow_pixels
	control.offset_top = -grow_pixels
	control.offset_right = grow_pixels
	control.offset_bottom = grow_pixels


# --- Textures: only the current and the next panel are held -------------------------------

func _texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D
	if _requested.has(path):
		_requested.erase(path)
		texture = ResourceLoader.load_threaded_get(path) as Texture2D
	else:
		texture = load(path) as Texture2D
	if texture != null:
		_textures[path] = texture
	return texture


func _request_textures(index: int) -> void:
	if index >= _panels().size():
		return
	for layer: Dictionary in _panels()[index].get("layers", []):
		var path: String = str(layer.get("texture", ""))
		if not _textures.has(path) and not _requested.has(path) and ResourceLoader.exists(path):
			if ResourceLoader.load_threaded_request(path) == OK:
				_requested[path] = true


func _release_textures_before(index: int) -> void:
	var keep: Dictionary = {}
	for i: int in range(maxi(index - 1, 0), mini(index + 2, _panels().size())):
		for layer: Dictionary in _panels()[i].get("layers", []):
			keep[str(layer.get("texture", ""))] = true
	for path: String in _textures.keys():
		if not keep.has(path):
			_textures.erase(path)


# --- Audio ---------------------------------------------------------------------------------

func _start_music() -> void:
	var music: Dictionary = _data.get("music", {})
	if music.is_empty():
		return
	AudioDirector.register_music_context(MUSIC_CONTEXT_ID, {
		"cue": str(music["cue"]),
		"ambience": str(music.get("ambience", "duck")),
		"ambience_db": float(music.get("ambience_db", -6.0)),
		"fade": float(music.get("fade", 2.0)),
	})
	AudioDirector.start_music_context(MUSIC_CONTEXT_ID)
	_music_started = true


func _stop_line() -> void:
	AudioDirector.stop_narration()
	_voice_on = false
	if not _line_id.is_empty() and AudioDirector.is_dialogue_playing():
		AudioDirector.stop_dialogue()
	_line_id = ""
	_subtitle.text = ""


func _on_subtitle_shown(line_id: String, speaker: String, text: String, _duration: float) -> void:
	if is_open and line_id == _line_id and Settings.get_value("subtitles"):
		_subtitle.text = "%s: %s" % [speaker, text] if not speaker.is_empty() else text


func _on_subtitle_cleared(line_id: String) -> void:
	if line_id == _line_id:
		_subtitle.text = ""


# --- Restore -------------------------------------------------------------------------------

func _on_game_loaded(_slot: int) -> void:
	_finish("interrupted")
	_last_data = {}
	_story_context = {}


## The single exit path. Safe to call any number of times.
func _finish(reason: String) -> void:
	if state == State.IDLE or state == State.RESTORING:
		return
	var was_open: bool = is_open
	state = State.RESTORING
	_stop_line()
	if _music_started:
		AudioDirector.end_music_context(MUSIC_CONTEXT_ID)
		_music_started = false
	if was_open:
		Input.mouse_mode = _saved_mouse_mode
	for child: Node in [_current, _previous]:
		if child != null:
			child.queue_free()
	_current = null
	_previous = null
	_textures.clear()
	# Collect loads still in flight, so no loader thread outlives the cutscene.
	for path: String in _requested.keys():
		ResourceLoader.load_threaded_get(path)
	_requested.clear()
	_black.color.a = 0.0
	narration_paused = false
	_track = {}
	visible = false
	is_open = false
	panel_index = -1
	_data = {}
	state = State.IDLE
	finished.emit(cutscene_id, reason)
	EventBus.cutscene_finished.emit(cutscene_id, reason)
	if was_open:
		EventBus.ui_panel_closed.emit(PANEL_ID)


# --- Overlay -------------------------------------------------------------------------------

func _build_overlay() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_page = ColorRect.new()
	_page.name = "Page"
	_page.color = PAGE_COLOR
	_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_page)
	_black = ColorRect.new()
	_black.name = "Black"
	_black.color = Color(0, 0, 0, 0)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_black)
	_subtitle = Label.new()
	_subtitle.name = "Subtitle"
	_subtitle.add_theme_font_size_override("font_size", 26)
	_subtitle.add_theme_color_override("font_color", Color(0.95, 0.94, 0.9))
	_subtitle.add_theme_color_override("font_outline_color", Color.BLACK)
	_subtitle.add_theme_constant_override("outline_size", 8)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.anchor_left = 0.15
	_subtitle.anchor_right = 0.85
	_subtitle.anchor_top = 1.0
	_subtitle.anchor_bottom = 1.0
	_subtitle.offset_top = -220.0
	_subtitle.offset_bottom = -100.0
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_subtitle)
	_hint = Label.new()
	_hint.name = "Hint"
	_hint.text = "Esc  Skip     Enter  Next"
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.76, 0.74, 0.8))
	_hint.anchor_left = 0.1
	_hint.anchor_right = 0.9
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = 0.0
	_hint.offset_right = 0.0
	_hint.offset_top = -82.0
	_hint.offset_bottom = -60.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint)
	_controls = HBoxContainer.new()
	_controls.name = "PlaybackControls"
	_controls.anchor_top = 1.0
	_controls.anchor_bottom = 1.0
	_controls.offset_left = 24.0
	_controls.offset_top = -52.0
	_controls.offset_bottom = -12.0
	_root.add_child(_controls)
	_pause_button = _add_control("Pause (P)", func() -> void: set_narration_paused(not narration_paused))
	_add_control("Replay (R)", replay)
	_add_control("Next", next_panel)
	_add_control("Skip", skip)
	_voice_toggle = CheckBox.new()
	_voice_toggle.text = "Narration"
	_voice_toggle.toggled.connect(func(enabled: bool) -> void: Settings.set_value("recap_narration", enabled))
	_controls.add_child(_voice_toggle)


func _add_control(text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	# Keyboard shortcuts stay available; buttons work by click without Enter
	# simultaneously activating the focused button and advancing a panel.
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_controls.add_child(button)
	return button

func set_narration_paused(paused: bool) -> void:
	narration_paused = paused
	AudioDirector.pause_narration(paused)
	_pause_button.text = "Resume (P)" if paused else "Pause (P)"

func _on_narration_setting_changed(key: String, value: Variant) -> void:
	if key != "recap_narration":
		return
	_voice_toggle.set_pressed_no_signal(bool(value))
	if state != State.PLAYING or _track.is_empty():
		return
	if not bool(value):
		AudioDirector.stop_narration()
		_voice_on = false
		_panel_duration = _panel_time + _caption_duration(_panels()[panel_index])
		_total += _caption_duration(_panels()[panel_index])
	else:
		# Enabling voice restarts this panel so audio and captions share zero.
		_elapsed = _panel_start_time(panel_index)
		_show_panel(panel_index)

func _caption_duration(panel: Dictionary) -> float:
	if _track.is_empty():
		return float(panel["duration_seconds"])
	return maxf(float(panel["duration_seconds"]), minf(120.0,
			str(_track.get("text", "")).split(" ").size() * 60.0 / 130.0 + 0.5))

func _estimated_panel_duration(panel: Dictionary) -> float:
	var track: Dictionary = NarrationRegistry.resolve(str(panel.get("narration_ref", "")), _story_context, _narration_data)
	if track.is_empty():
		return float(panel["duration_seconds"])
	var reading: float = str(track.get("text", "")).split(" ").size() * 60.0 / 130.0
	var duration: float = float(track.get("duration_seconds", reading))
	var path: String = str(track.get("audio_path", ""))
	if not bool(Settings.get_value("recap_narration")) or path.is_empty() or (not ResourceLoader.exists(path) and not FileAccess.file_exists(path)):
		duration = reading
	return maxf(float(panel["duration_seconds"]), minf(120.0, duration + 0.5))

func _estimated_total(data: Dictionary) -> float:
	var total: float = 0.0
	for panel: Dictionary in data.get("panels", []):
		total += _estimated_panel_duration(panel)
	return total

func _update_narration_caption() -> void:
	if _track.is_empty():
		return
	# Disabled/missing voice always leaves readable captions, regardless of
	# the preference for subtitles under spoken audio.
	if not _voice_on:
		_subtitle.text = str(_track.get("text", ""))
		return
	_subtitle.text = ""
	if not bool(Settings.get_value("subtitles")):
		return
	var position: float = AudioDirector.narration_position()
	for cue: Dictionary in _track.get("cues", []):
		if position >= float(cue["start"]) and position < float(cue["end"]):
			_subtitle.text = str(cue["text"])
			return
