extends Node
## CutscenePreview: review scene for graphic-novel cutscenes, outside the campaign.
##
## Plays one cutscene (default: the Chapter 1 pilot) over a stand-in "game"
## backdrop, in review mode, so unapproved cutscenes can be watched without
## touching a save. Open scenes/cutscene/CutscenePreview.tscn and press F6
## (Mac: Cmd + R). Esc skips, Enter advances, R replays.
##
## Arguments after `--`:
##   --cutscene=<cutscene_id>   which cutscene to play
##   --exit-when-done           quit when it finishes (headless QA)
##   --capture-dir=<path>       save one PNG from the middle of every panel, stepping
##                              time exactly, then quit (needs a rendering display)

const DEFAULT_CUTSCENE: String = "cs_ch01_first_shift_pilot"
const CAPTURE_STEP: float = 1.0 / 30.0

@onready var _director: CutsceneDirector = $CutsceneDirector
@onready var _status: Label = $Backdrop/Status


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var cutscene_id: String = _arg(args, "--cutscene=", DEFAULT_CUTSCENE)
	var capture_dir: String = _arg(args, "--capture-dir=", "")
	_director.review_mode = true
	_director.finished.connect(_on_finished.bind("--exit-when-done" in args))
	EventBus.cutscene_started.connect(func(id: String) -> void:
		print("CUTSCENE_PREVIEW started %s (%.1fs)" % [id, _director.get_total_seconds()]))
	if not capture_dir.is_empty():
		await _capture(cutscene_id, capture_dir)
		_quit()
		return
	_director.play(cutscene_id)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode == KEY_R:
		_director.replay()


func _on_finished(cutscene_id: String, reason: String, exit_when_done: bool) -> void:
	_status.text = "Cutscene %s ended (%s). Game restored.\nR  Replay" % [cutscene_id, reason]
	print("CUTSCENE_PREVIEW finished %s reason=%s errors=%d" % [cutscene_id, reason, _director.runtime_errors.size()])
	for error: String in _director.runtime_errors:
		print("CUTSCENE_PREVIEW error: " + error)
	if exit_when_done:
		_quit()


## Lets the music fade finish before quitting, so no stream is playing at shutdown.
func _quit() -> void:
	AudioDirector.stop_music(0.01)
	AudioDirector.stop_ambience(0.01)
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


## Steps time by hand (no real-time playback) and saves the middle of every panel.
func _capture(cutscene_id: String, directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	_director.set_process(false)
	if not _director.play(cutscene_id):
		return
	var index: int = 0
	var panel_start: float = 0.0
	var elapsed: float = 0.0
	while _director.is_open:
		var panel: Dictionary = (CutsceneRegistry.get_cutscene(cutscene_id)["panels"] as Array)[index]
		var middle: float = panel_start + float(panel["duration_seconds"]) * 0.5
		while elapsed < middle:
			_director.advance(CAPTURE_STEP)
			elapsed += CAPTURE_STEP
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var path: String = "%s/%s_%02d_%s.png" % [directory, cutscene_id, index + 1, panel["id"]]
		get_viewport().get_texture().get_image().save_png(path)
		print("CUTSCENE_PREVIEW captured " + path)
		panel_start += float(panel["duration_seconds"])
		index += 1
		while _director.is_open and _director.panel_index < index:
			_director.advance(CAPTURE_STEP)
			elapsed += CAPTURE_STEP


func _arg(args: PackedStringArray, prefix: String, fallback: String) -> String:
	for arg: String in args:
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
