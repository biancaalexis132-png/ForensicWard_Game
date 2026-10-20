class_name Main
extends Node3D
## Main: composition root for the playable prototype.
##
## Owns the high-level input mode: when any panel or menu is open, the mouse
## is visible, the player can't move, the HUD crosshair hides and the clock
## pauses. When everything closes, mouse capture returns. Esc closes the
## top-most panel, or opens the pause menu if none is open.
##
## Panels opened through EventBus.ui_panel_requested(panel_id, data):
##   "info"       InfoPanel (documents, staff, notices; drawn on top)
##   "interview"  InterviewScreen (cinematic interview; gets the world's cameras)
##   "ehr"        EHRScreen (also opened with J)
##   "evidence"   EvidenceBoard (also opened with Tab)
##   "milestone"  MilestonePresenter (split-screen moment after an objective;
##                waits until nothing else is open)
##   "cutscene"   CutsceneDirector (graphic-novel cutscene: approved chapter title
##                cards play when a chapter opens, approved chapter recaps when
##                a chapter is completed (drawn over its end-of-chapter panel);
##                others only with `-- --cutscene-preview=<cutscene_id>`)
## ChapterDirector (story), AnomalyLedger (anomaly evidence, flag off by
## default), AudioZoneTracker (ambience per room) and ZoneDirector (which
## zones are loaded, transitions) are children of Main, so they exist exactly
## while the playable world does.
##
## Presentation state (get_presentation_state()): exactly one of TITLE,
## PROLOGUE (a new-game or chapter-opening cutscene), GAMEPLAY, MILESTONE,
## CHAPTER_RECAP (a chapter-complete recap) or CHAPTER_COMPLETE (the
## end-of-chapter panel). It is derived from what is open, so there is one
## owner of input at a time, and leaving any of them goes through
## _update_input_mode(), which restores mouse capture, player input, the HUD
## and the clock; cutscenes restore their own music. Changes are announced
## on EventBus.presentation_state_changed.
##
## Also registers the "world" save provider: the player transform. Door
## state is saved per zone by ZoneDirector ("zones").

const WORLD_PROVIDER_KEY: String = "world"
const TIME_PAUSE_REASON: String = "ui"
const TITLE: String = "TITLE"
const PROLOGUE: String = "PROLOGUE"
const GAMEPLAY: String = "GAMEPLAY"
const MILESTONE: String = "MILESTONE"
const CHAPTER_RECAP: String = "CHAPTER_RECAP"
const CHAPTER_COMPLETE: String = "CHAPTER_COMPLETE"

var _presentation_state: String = GAMEPLAY
## True from a chapter's completion until its end-of-chapter panel closes.
var _chapter_complete_showing: bool = false

@onready var _world: Node3D = $World
@onready var _player: FirstPersonController = $Player
@onready var _hud: HUD = $HUD
@onready var _info_panel: InfoPanel = $InfoPanel
@onready var _ehr: EHRScreen = $EHRScreen
@onready var _interview: InterviewScreen = $InterviewScreen
@onready var _evidence: EvidenceBoard = $EvidenceBoard
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _zones: ZoneDirector = $ZoneDirector
@onready var _cutscene: CutsceneDirector = $CutsceneDirector
@onready var _title: TitleScreen = $TitleScreen
@onready var _milestones: MilestonePresenter = $MilestonePresenter
## Topmost first: Esc closes the first open one.
@onready var _panels: Array[CanvasLayer] = [_cutscene, _milestones, _info_panel, _interview, _ehr, _evidence]


func _ready() -> void:
	EventBus.ui_panel_requested.connect(_on_ui_panel_requested)
	EventBus.chapter_started.connect(_on_chapter_started)
	EventBus.chapter_completed.connect(_on_chapter_completed)
	EventBus.ui_panel_closed.connect(func(_panel_id: String) -> void: _update_input_mode())
	_pause_menu.closed.connect(_update_input_mode)
	_title.closed.connect(_update_input_mode)
	_title.new_game_started.connect(_on_new_game_started)
	_title.settings_requested.connect(func() -> void: _pause_menu.open_settings_from_title())
	EventBus.ui_panel_closed.connect(func(panel_id: String) -> void:
		if panel_id == InfoPanel.PANEL_ID and not _cutscene.is_open:
			_chapter_complete_showing = false
			_update_input_mode())
	EventBus.game_loaded.connect(func(_slot: int) -> void:
		_chapter_complete_showing = false
		_update_input_mode())
	SaveManager.register_provider(WORLD_PROVIDER_KEY, self)
	_place_at_spawn()
	_zones.setup(_world, _player)
	_zones.transition_finished.connect(_update_input_mode)
	($AudioZoneTracker as AudioZoneTracker).target = _player
	get_tree().auto_accept_quit = false  # Quit via _quit_gracefully (audio first).

	if not ContentRegistry.is_valid:
		_show_content_errors()
	elif TitleScreen.wanted(self):
		_title.open()
	_update_input_mode()
	# tests/qa/run.py looks for this line as boot evidence.
	print("[The Forensic Ward] Boot OK (content %s)" % ("valid" if ContentRegistry.is_valid else "INVALID"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_gracefully()


## Stops audio and lets the audio thread finish before quitting, so no
## stream is still playing at shutdown.
func _quit_gracefully() -> void:
	_silence_audio()
	await get_tree().create_timer(0.25, true).timeout
	get_tree().quit()


func _exit_tree() -> void:
	SaveManager.unregister_provider(WORLD_PROVIDER_KEY)
	get_tree().auto_accept_quit = true
	_silence_audio()


## World audio belongs to the world: stop it when Main leaves (quit, tests),
## so no stream is still playing when the engine shuts down.
func _silence_audio() -> void:
	AudioDirector.stop_narration()
	AudioDirector.stop_dialogue()
	AudioDirector.stop_ambience(0.01)
	AudioDirector.stop_music(0.01)
	for player: Node in AudioDirector.find_children("*", "", true, false):
		if player is AudioStreamPlayer or player is AudioStreamPlayer3D:
			player.call("stop")
			player.set("stream", null)


func _unhandled_input(event: InputEvent) -> void:
	if _zones.in_transition:
		return
	if event.is_action_pressed("pause"):
		var top: CanvasLayer = _top_panel()
		if top != null:
			top.call("close")
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("accessibility_menu") and _top_panel() == null:
		_open_pause_menu()
	elif event.is_action_pressed("ehr") and _ehr.is_open and _top_panel() == _ehr:
		_ehr.close()
	elif event.is_action_pressed("ehr") and not _is_ui_open():
		_on_ui_panel_requested(EHRScreen.PANEL_ID, {})
	elif event.is_action_pressed("journal") and _top_panel() == _evidence:
		_evidence.close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal") and not _is_ui_open():
		_on_ui_panel_requested(EvidenceBoard.PANEL_ID, {})
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and not _is_ui_open() \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# macOS releases capture when the window loses focus; click to recapture.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _is_ui_open() -> bool:
	return _top_panel() != null or _pause_menu.is_open or _title.is_open


func _top_panel() -> CanvasLayer:
	for panel: CanvasLayer in _panels:
		if panel.get("is_open"):
			return panel
	return null


func _open_pause_menu() -> void:
	if _pause_menu.is_open:
		return
	_pause_menu.open()
	_update_input_mode()


func _on_ui_panel_requested(panel_id: String, data: Dictionary) -> void:
	match panel_id:
		InfoPanel.PANEL_ID:
			_info_panel.open(data)
		EHRScreen.PANEL_ID:
			_ehr.open(data)
		EvidenceBoard.PANEL_ID:
			_evidence.open(data)
		ProtagonistScreen.PANEL_ID:
			_open_optional_panel("ProtagonistScreen", "res://scenes/ui/ProtagonistScreen.tscn", data)
		PracticeScreen.PANEL_ID:
			_open_optional_panel("PracticeScreen", "res://scenes/ui/PracticeScreen.tscn", data)
		CaseJournalScreen.PANEL_ID:
			_open_optional_panel("CaseJournalScreen", "res://scenes/ui/CaseJournalScreen.tscn", data)
		MapScreen.PANEL_ID:
			_open_optional_panel("MapScreen", "res://scenes/ui/MapScreen.tscn", data)
		CutsceneDirector.PANEL_ID:
			var recap_data: Dictionary = data.duplicate()
			var chapter: ChapterDirector = $ChapterDirector
			if bool(data.get("replay_completed", false)):
				var latest: String = ""
				for id: String in ContentRegistry.get_chapter_ids():
					if chapter.has_completed(id):
						latest = id
				if latest.is_empty():
					return
				recap_data["cutscene_id"] = CutsceneRegistry.chapter_complete_cutscene(latest)
			recap_data["story_context"] = chapter.get_story_context()
			_cutscene.open(recap_data)
		MilestonePresenter.PANEL_ID:
			if _is_ui_open() or _zones.in_transition:
				return  # Stays queued; _update_input_mode() shows it once the screen is clear.
			if not _milestones.open(data):
				return
		InterviewScreen.PANEL_ID:
			var with_world: Dictionary = data.duplicate()
			with_world["world"] = null if bool(data.get("text_only", false)) else _world
			_interview.open(with_world)
		_:
			push_warning("Main: unknown panel '%s'" % panel_id)
			return
	_update_input_mode()


func _open_optional_panel(node_name: String, scene_path: String, data: Dictionary) -> void:
	var panel: CanvasLayer = get_node_or_null(NodePath(node_name)) as CanvasLayer
	if panel == null:
		var scene: PackedScene = load(scene_path) as PackedScene
		panel = scene.instantiate() as CanvasLayer
		add_child(panel)
		_panels.push_front(panel)
	panel.call("open", data)


func get_presentation_state() -> String:
	return _presentation_state


func _derive_presentation_state() -> String:
	if _title.is_open:
		return TITLE
	if _cutscene.is_open:
		return CHAPTER_RECAP if _cutscene.get_trigger_kind() == "chapter_complete" else PROLOGUE
	if _milestones.is_open:
		return MILESTONE
	if _chapter_complete_showing and _info_panel.is_open:
		return CHAPTER_COMPLETE
	return GAMEPLAY


func _update_input_mode() -> void:
	var state: String = _derive_presentation_state()
	if state != _presentation_state:
		_presentation_state = state
		EventBus.presentation_state_changed.emit(state)
	var ui_open: bool = _is_ui_open()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if ui_open else Input.MOUSE_MODE_CAPTURED
	_player.set_input_enabled(not ui_open and not _zones.in_transition)
	_hud.set_world_hud_visible(not ui_open)
	if ui_open:
		TimeManager.push_pause(TIME_PAUSE_REASON)
	else:
		TimeManager.pop_pause(TIME_PAUSE_REASON)
		# A milestone that came due while something else was open plays now.
		if _milestones.flush_pending():
			_update_input_mode()


func _show_content_errors() -> void:
	var body: String = "[b]The game data in res://data failed validation.[/b] Fix these and restart:\n\n"
	for message: String in ContentRegistry.errors:
		body += "• %s\n" % message
	_info_panel.open({"title": "Content validation failed", "body": body, "blocking": true})
	_player.set_input_enabled(false)


func _place_at_spawn() -> void:
	var spawn: Marker3D = _world.get_node("PlayerSpawn")
	_player.place(spawn.global_position, spawn.global_rotation.y)


# --- Save provider ("world") ------------------------------------------------------

func to_save_data() -> Dictionary:
	var p: Vector3 = _player.global_position
	return {"player": {"position": [p.x, p.y, p.z], "yaw": _player.rotation.y, "pitch": _player.get_look_pitch()}}


func load_save_data(data: Dictionary) -> void:
	_sync_chapter_world()
	var player: Dictionary = data.get("player", {})
	var position_values: Array = player.get("position", [])
	if position_values.size() == 3:
		_player.place(Vector3(position_values[0], position_values[1], position_values[2]),
				float(player.get("yaw", 0.0)), float(player.get("pitch", 0.0)))


func reset_state() -> void:
	_sync_chapter_world()
	_place_at_spawn()


func _sync_chapter_world() -> bool:
	var chapter: ChapterDirector = $ChapterDirector
	if not _world is AuthoredWorld or not _world.configure_chapter(chapter.get_chapter_id()):
		return false
	for panel: CanvasLayer in _panels:
		if panel.get("is_open"):
			panel.call("close")
	return true


func _on_chapter_started(chapter_id: String) -> void:
	if not _sync_chapter_world():
		return
	_silence_audio()
	_zones.reset_state()
	_place_at_spawn()
	_update_input_mode()
	var opening: String = CutsceneRegistry.chapter_start_cutscene(chapter_id)
	if not opening.is_empty():
		EventBus.ui_panel_requested.emit(CutsceneDirector.PANEL_ID, {"cutscene_id": opening})


## New Game from the title: the approved prologue for the start chapter, if
## the owner approved one. It writes no state; skipping it changes nothing.
func _on_new_game_started() -> void:
	var prologue: String = CutsceneRegistry.new_game_cutscene(ContentRegistry.get_start_chapter_id())
	if not prologue.is_empty():
		EventBus.ui_panel_requested.emit(CutsceneDirector.PANEL_ID, {"cutscene_id": prologue})
	_update_input_mode()


## An approved recap opens over the end-of-chapter panel, which is still there when it ends.
func _on_chapter_completed(chapter_id: String) -> void:
	_chapter_complete_showing = true
	_update_input_mode.call_deferred()
	var recap: String = CutsceneRegistry.chapter_complete_cutscene(chapter_id)
	if not recap.is_empty():
		EventBus.ui_panel_requested.emit(CutsceneDirector.PANEL_ID, {"cutscene_id": recap})
