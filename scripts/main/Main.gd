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
## ChapterDirector (story), AnomalyLedger (anomaly evidence, flag off by
## default), AudioZoneTracker (ambience per room) and ZoneDirector (which
## zones are loaded, transitions) are children of Main, so they exist exactly
## while the playable world does.
##
## Also registers the "world" save provider: the player transform. Door
## state is saved per zone by ZoneDirector ("zones").

const WORLD_PROVIDER_KEY: String = "world"
const TIME_PAUSE_REASON: String = "ui"

@onready var _world: Node3D = $World
@onready var _player: FirstPersonController = $Player
@onready var _hud: HUD = $HUD
@onready var _info_panel: InfoPanel = $InfoPanel
@onready var _ehr: EHRScreen = $EHRScreen
@onready var _interview: InterviewScreen = $InterviewScreen
@onready var _evidence: EvidenceBoard = $EvidenceBoard
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _zones: ZoneDirector = $ZoneDirector
## Topmost first: Esc closes the first open one.
@onready var _panels: Array[CanvasLayer] = [_info_panel, _interview, _ehr, _evidence]


func _ready() -> void:
	EventBus.ui_panel_requested.connect(_on_ui_panel_requested)
	EventBus.ui_panel_closed.connect(func(_panel_id: String) -> void: _update_input_mode())
	_pause_menu.closed.connect(_update_input_mode)
	SaveManager.register_provider(WORLD_PROVIDER_KEY, self)
	_place_at_spawn()
	_zones.setup(_world, _player)
	_zones.transition_finished.connect(_update_input_mode)
	($AudioZoneTracker as AudioZoneTracker).target = _player
	get_tree().auto_accept_quit = false  # Quit via _quit_gracefully (audio first).

	if not ContentRegistry.is_valid:
		_show_content_errors()
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
	return _top_panel() != null or _pause_menu.is_open


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
		InterviewScreen.PANEL_ID:
			var with_world: Dictionary = data.duplicate()
			with_world["world"] = _world
			_interview.open(with_world)
		_:
			push_warning("Main: unknown panel '%s'" % panel_id)
			return
	_update_input_mode()


func _update_input_mode() -> void:
	var ui_open: bool = _is_ui_open()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if ui_open else Input.MOUSE_MODE_CAPTURED
	_player.set_input_enabled(not ui_open and not _zones.in_transition)
	_hud.set_world_hud_visible(not ui_open)
	if ui_open:
		TimeManager.push_pause(TIME_PAUSE_REASON)
	else:
		TimeManager.pop_pause(TIME_PAUSE_REASON)


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
	var player: Dictionary = data.get("player", {})
	var position_values: Array = player.get("position", [])
	if position_values.size() == 3:
		_player.place(Vector3(position_values[0], position_values[1], position_values[2]),
				float(player.get("yaw", 0.0)), float(player.get("pitch", 0.0)))


func reset_state() -> void:
	_place_at_spawn()
