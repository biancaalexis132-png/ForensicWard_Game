class_name NaomiActingController
extends Node
## Drives Naomi's presentation from stable dialogue IDs and existing audio events.

const CUE_DATA_PATH: String = "res://docs/design/characters/Naomi_Acting_Cues_v1/naomi_acting_cues.json"
const NO_AUDIO_GRACE_SECONDS: float = 0.75

var actor_root: Node3D
var _cue_data: Dictionary = {}
var _adapter: CharacterActingAdapter
var _last_scene_line_id: String = ""
var _active_line_id: String = ""
var _conversation_token: int = 0
var _conversation_active: bool = false


func _ready() -> void:
	if actor_root == null:
		push_error("NaomiActingController requires an actor root")
		return
	_cue_data = load_cue_data()
	if _cue_data.is_empty():
		push_warning("NaomiActingController: cue data unavailable; presentation remains neutral")
		return
	_adapter = CharacterActingAdapter.new()
	_adapter.name = "CharacterActingAdapter"
	_adapter.configure(actor_root)
	add_child(_adapter)
	var scene_lines: Array = AudioDirector.get_scene_lines(str(_cue_data.get("scene_id", "")))
	if not scene_lines.is_empty():
		_last_scene_line_id = str(scene_lines.back())
	EventBus.subtitle_shown.connect(_on_subtitle_shown)
	EventBus.dialogue_line_finished.connect(_on_dialogue_line_finished)
	EventBus.game_loaded.connect(_on_game_loaded)
	_apply_fallback("working")


func _exit_tree() -> void:
	if not _active_line_id.is_empty():
		AudioDirector.stop_dialogue()
	if _adapter != null and is_instance_valid(_adapter):
		_adapter.reset_to_safe_idle(_fallback(), "tree_exit")


static func load_cue_data(path: String = CUE_DATA_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("NaomiActingController: cue file not found: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not parsed.get("cues", {}) is Dictionary:
		push_warning("NaomiActingController: invalid cue data in %s" % path)
		return {}
	return parsed


static func cue_for_line(cue_data: Dictionary, line_id: String) -> Dictionary:
	var cues: Variant = cue_data.get("cues", {})
	if not cues is Dictionary:
		return {}
	var cue: Variant = cues.get(line_id, {})
	return cue.duplicate(true) if cue is Dictionary else {}


func get_active_line_id() -> String:
	return _active_line_id


func is_conversation_active() -> bool:
	return _conversation_active


func get_adapter() -> CharacterActingAdapter:
	return _adapter


func begin_conversation() -> void:
	if _cue_data.is_empty() or _adapter == null:
		return
	_conversation_active = true
	_active_line_id = ""
	_conversation_token += 1
	_apply_fallback("conversation_enter")
	_end_if_no_dialogue(_conversation_token)


func _end_if_no_dialogue(token: int) -> void:
	await get_tree().create_timer(NO_AUDIO_GRACE_SECONDS).timeout
	if token == _conversation_token and _conversation_active and _active_line_id.is_empty():
		_end_conversation_with_fallback("no_dialogue")


func _on_subtitle_shown(line_id: String, _speaker_name: String, _text: String, _duration: float) -> void:
	var cue: Dictionary = cue_for_line(_cue_data, line_id)
	if cue.is_empty():
		return
	var line: Dictionary = AudioDirector.get_line(line_id)
	var speaker: String = str(line.get("speaker", ""))
	if speaker != str(_cue_data.get("character_id", "")) and speaker != "player":
		return
	_conversation_token += 1
	_conversation_active = true
	_active_line_id = line_id
	var actor_speaking: bool = speaker == str(_cue_data.get("character_id", ""))
	if cue.has("on_enter"):
		_adapter.apply_cue("on_enter", cue["on_enter"], false)
	if cue.has("during_speech"):
		_adapter.apply_cue("during_speech", cue["during_speech"], actor_speaking)


func _on_dialogue_line_finished(line_id: String, completed: bool) -> void:
	if line_id != _active_line_id:
		return
	var cue: Dictionary = cue_for_line(_cue_data, line_id)
	_active_line_id = ""
	if not completed:
		_end_conversation_with_fallback("interrupted")
		return
	if cue.has("on_exit"):
		_adapter.apply_cue("on_exit", cue["on_exit"], false)
	elif cue.has("during_speech"):
		_adapter.apply_cue("during_speech", cue["during_speech"], false)
	if line_id == _last_scene_line_id:
		_conversation_active = false
		_conversation_token += 1


func _on_game_loaded(_slot: int) -> void:
	if not _active_line_id.is_empty():
		AudioDirector.stop_dialogue()
	_end_conversation_with_fallback("game_loaded")


func _end_conversation_with_fallback(stage: String) -> void:
	_conversation_token += 1
	_conversation_active = false
	_active_line_id = ""
	_apply_fallback(stage)


func _apply_fallback(stage: String) -> void:
	if _adapter != null:
		_adapter.reset_to_safe_idle(_fallback(), stage)


func _fallback() -> Dictionary:
	var fallback: Variant = _cue_data.get("fallback", {})
	return fallback.duplicate(true) if fallback is Dictionary else {}
