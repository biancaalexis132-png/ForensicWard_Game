class_name ConversationRange
extends Node
## ConversationRange: ends a spoken conversation when the player walks away
## from the character speaking it.
##
## Story scenes (a handover, a corridor exchange) play while the player can
## still move. The first line by a character standing in the world anchors
## the conversation to them; once the player is more than WALK_AWAY_METERS
## away, the current line and the rest of the scene stop, as they would in
## person. Narrator, intercom and the player's own lines never anchor. The
## anchor clears when the voice channel goes quiet. Nothing here writes story,
## clinical or save state: the scene's beat has already been applied.

## A conversational distance plus a few steps of slack.
const WALK_AWAY_METERS: float = 6.0
const GROUP: String = "conversation_range"

## The node whose distance counts (Main sets the player).
var target: Node3D
## The character the current conversation is anchored to, or null.
var anchor: WardCharacter


func _ready() -> void:
	add_to_group(GROUP)
	EventBus.subtitle_shown.connect(_on_subtitle_shown)


func _physics_process(_delta: float) -> void:
	if anchor == null:
		return
	if not is_instance_valid(anchor) or not AudioDirector.is_voice_busy():
		anchor = null
		return
	if is_instance_valid(target) and distance_to_anchor() > WALK_AWAY_METERS:
		walk_away()


## Horizontal distance from the player to the anchored speaker, so stairs
## and seated characters do not count as walking away.
func distance_to_anchor() -> float:
	if anchor == null or not is_instance_valid(target):
		return 0.0
	var offset: Vector3 = target.global_position - anchor.global_position
	offset.y = 0.0
	return offset.length()


## Stops the conversation the player has left.
func walk_away() -> void:
	anchor = null
	AudioDirector.stop_dialogue()


func _on_subtitle_shown(line_id: String, _speaker_name: String, _text: String, _duration: float) -> void:
	var speaker: String = str(AudioDirector.get_line(line_id).get("speaker", ""))
	if speaker.is_empty() or speaker == "player":
		return
	var character: WardCharacter = find_character(speaker)
	if character != null:
		anchor = character
	elif anchor != null and not _is_anchor_speaker(speaker):
		anchor = null # A narrator, intercom or off-screen voice took over.


func _is_anchor_speaker(speaker: String) -> bool:
	return anchor != null and is_instance_valid(anchor) and anchor.character_id == speaker


## The present, visible character with this id, or null.
func find_character(character_id: String) -> WardCharacter:
	for node: Node in get_tree().get_nodes_in_group(WardCharacter.GROUP):
		var character: WardCharacter = node as WardCharacter
		if character != null and character.character_id == character_id and character.is_present() \
				and character.is_visible_in_tree():
			return character
	return null
