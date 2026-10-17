class_name Main
extends Node3D
## Main: composition root for the playable prototype.
##
## Owns the high-level input mode: when any panel or menu is open, the mouse
## is visible, the player can't move, the HUD crosshair hides and the clock
## pauses. When everything closes, mouse capture returns. Esc closes the
## top-most panel, or opens the pause menu if none is open.
##
## Also registers the "world" save provider: player transform plus every
## node in the "persistent_world" group (doors).

const WORLD_PROVIDER_KEY: String = "world"
const TIME_PAUSE_REASON: String = "ui"

@onready var _world: Node3D = $HospitalGreybox
@onready var _player: FirstPersonController = $Player
@onready var _hud: HUD = $HUD
@onready var _info_panel: InfoPanel = $InfoPanel
@onready var _pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	EventBus.ui_panel_requested.connect(_on_ui_panel_requested)
	EventBus.ui_panel_closed.connect(func(_panel_id: String) -> void: _update_input_mode())
	_pause_menu.closed.connect(_update_input_mode)
	SaveManager.register_provider(WORLD_PROVIDER_KEY, self)
	_place_at_spawn()

	if not ContentRegistry.is_valid:
		_show_content_errors()
	_update_input_mode()
	# tests/qa/run.py looks for this line as boot evidence.
	print("[The Forensic Ward] Boot OK (content %s)" % ("valid" if ContentRegistry.is_valid else "INVALID"))


func _exit_tree() -> void:
	SaveManager.unregister_provider(WORLD_PROVIDER_KEY)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _info_panel.is_open:
			_info_panel.close()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("accessibility_menu") and not _info_panel.is_open:
		_open_pause_menu()
	elif event.is_action_pressed("ehr") and not _is_ui_open():
		EventBus.notification_requested.emit("Use an EHR workstation (full EHR screen arrives in Sprint 2).")
	elif event.is_action_pressed("journal") and not _is_ui_open():
		EventBus.notification_requested.emit("Evidence: %d item(s) collected (evidence board arrives in Sprint 3)." %
				EvidenceManager.get_acquired_ids().size())
	elif event is InputEventMouseButton and event.pressed and not _is_ui_open() \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# macOS releases capture when the window loses focus; click to recapture.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _is_ui_open() -> bool:
	return _info_panel.is_open or _pause_menu.is_open


func _open_pause_menu() -> void:
	if _pause_menu.is_open:
		return
	_pause_menu.open()
	_update_input_mode()


func _on_ui_panel_requested(panel_id: String, data: Dictionary) -> void:
	if panel_id != InfoPanel.PANEL_ID:
		push_warning("Main: unknown panel '%s'" % panel_id)
		return
	_info_panel.open(data)
	_update_input_mode()


func _update_input_mode() -> void:
	var ui_open: bool = _is_ui_open()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if ui_open else Input.MOUSE_MODE_CAPTURED
	_player.set_input_enabled(not ui_open)
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
	var objects: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("persistent_world"):
		objects[node.get_persist_id()] = node.to_save_data()
	var p: Vector3 = _player.global_position
	return {
		"player": {"position": [p.x, p.y, p.z], "yaw": _player.rotation.y, "pitch": _player.get_look_pitch()},
		"objects": objects,
	}


func load_save_data(data: Dictionary) -> void:
	var player: Dictionary = data.get("player", {})
	var position_values: Array = player.get("position", [])
	if position_values.size() == 3:
		_player.place(Vector3(position_values[0], position_values[1], position_values[2]),
				float(player.get("yaw", 0.0)), float(player.get("pitch", 0.0)))
	var objects: Dictionary = data.get("objects", {})
	for node: Node in get_tree().get_nodes_in_group("persistent_world"):
		node.load_save_data(objects.get(node.get_persist_id(), {}))


func reset_state() -> void:
	_place_at_spawn()
	for node: Node in get_tree().get_nodes_in_group("persistent_world"):
		node.load_save_data({})
