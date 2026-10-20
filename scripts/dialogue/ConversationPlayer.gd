class_name ConversationPlayer
extends Node
## ConversationPlayer: speaks a list of VoiceScript segments one after another
## through AudioDirector, so a panel or interview never talks over itself or
## over a narrative scene.
##
## Each segment plays its clip (subtitle timed to the clip) or, without one,
## a subtitle-only fallback for its reading time when `subtitle_fallback` is
## on. skip_line() ends the current line and moves on; cancel() stops the
## whole conversation. Nothing here writes story, clinical or save state: the
## caller applies a choice once, before or after presentation, never per line.

signal line_started(index: int, segment: Dictionary)
signal finished(completed: bool)

## Gap between lines, as AudioDirector.play_scene uses.
const LINE_GAP_SECONDS: float = 0.3
## How long to wait for another voice (an intercom, a scene) to finish first.
const WAIT_FOR_IDLE_SECONDS: float = 30.0

var is_playing: bool = false
## Show unvoiced segments as timed subtitles. Panels that already show the text leave it off.
var subtitle_fallback: bool = true
var current_index: int = -1

var _token: int = 0


## Plays the segments in order. Awaitable: true when every line ran to the
## end or was skipped line by line; false when cancelled or replaced.
func play(segments: Array[Dictionary]) -> bool:
	cancel()
	_token += 1
	var token: int = _token
	is_playing = true
	current_index = -1
	AudioDirector.begin_conversation()
	# A scene or intercom that started first finishes rather than being cut off.
	var waited: float = 0.0
	while AudioDirector.is_dialogue_playing() and token == _token and waited < WAIT_FOR_IDLE_SECONDS:
		await get_tree().create_timer(0.1, false).timeout
		waited += 0.1
	var completed: bool = token == _token
	for index: int in segments.size():
		if token != _token:
			completed = false
			break
		var segment: Dictionary = segments[index]
		var line_id: String = str(segment.get("line_id", ""))
		if line_id.is_empty() and not subtitle_fallback:
			continue
		current_index = index
		line_started.emit(index, segment)
		if not line_id.is_empty():
			await AudioDirector.play_line(line_id)
		else:
			await AudioDirector.play_text(_speaker_name(str(segment.get("speaker", ""))), str(segment.get("text", "")))
		if token != _token:
			completed = false
			break
		if index < segments.size() - 1:
			await get_tree().create_timer(LINE_GAP_SECONDS, false).timeout
	if token == _token:
		_end(completed)
	return completed


## Ends the current line now; the next one follows.
func skip_line() -> void:
	if is_playing:
		AudioDirector.stop_dialogue()


## Stops the conversation and its current line.
func cancel() -> void:
	if not is_playing:
		return
	_token += 1
	AudioDirector.stop_dialogue()
	_end(false)


func _end(completed: bool) -> void:
	is_playing = false
	current_index = -1
	AudioDirector.end_conversation()
	finished.emit(completed)


func _exit_tree() -> void:
	cancel()


static func _speaker_name(speaker: String) -> String:
	if speaker == VoiceScript.NARRATOR or speaker.is_empty():
		return ""
	if speaker == "player":
		return "You"
	var staff: Dictionary = ContentRegistry.get_staff(speaker)
	if not staff.is_empty():
		return str(staff.get("name", speaker))
	return str(ContentRegistry.get_patient(speaker).get("name", speaker.capitalize()))
