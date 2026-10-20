class_name VoiceScript
extends RefCounted
## VoiceScript: splits authored text into voiced segments and finds each
## segment's clip, so panels and interviews can speak what they show.
##
## Splitting mirrors tools/audio/extract_voice_lines.py exactly (which writes
## data/narrative/voice_<chapter>.json from the same text): paragraphs are
## separated by a blank line; "(...)" paragraphs are narrated stage directions;
## a known "Speaker: words" prefix picks that speaker's voice; anything else
## takes the passage's default speaker. A mute patient's passages are always
## the narrator describing what is observed, never invented speech.

const NARRATOR: String = "narrator"
## Keep in step with SPEAKER_PREFIXES in tools/audio/extract_voice_lines.py.
const SPEAKER_PREFIXES: Dictionary = {
	"You": "player", "Player": "player",
	"Voss": "staff_voss", "Dr Voss": "staff_voss",
	"Hale": "staff_hale", "Hale (radio)": "staff_hale",
	"Bennett": "staff_bennett", "Nurse Bennett": "staff_bennett", "Naomi": "staff_bennett",
	"Rahman": "staff_rahman", "Dr Rahman": "staff_rahman",
	"Mara": "pt_mara_ellis",
	"Technician": "staff_facilities_tech", "Facilities": "staff_facilities_tech",
	"Engineer": "engineer", "Analyst": "analyst",
}
## Patients who do not speak: their responses are narrated observations.
const MUTE_SPEAKERS: Array[String] = ["pt_elias_ward"]

static var _bbcode: RegEx
static var _prefix: RegEx


## [{speaker, text, line_id}] for one authored passage. line_id is "" when no
## clip exists; callers then rely on the visible text (or a subtitle fallback).
static func segments(text: String, default_speaker: String) -> Array[Dictionary]:
	_compile()
	var result: Array[Dictionary] = []
	for raw: String in _bbcode.sub(text, "", true).split("\n\n"):
		var paragraph: String = raw.strip_edges()
		if paragraph.is_empty():
			continue
		var speaker: String = default_speaker
		var spoken: String = paragraph
		if paragraph.begins_with("(") and paragraph.ends_with(")"):
			speaker = NARRATOR
		else:
			var found: RegExMatch = _prefix.search(paragraph)
			if found != null and SPEAKER_PREFIXES.has(found.get_string(1)):
				speaker = SPEAKER_PREFIXES[found.get_string(1)]
				spoken = found.get_string(2).strip_edges()
				if spoken.length() > 1 and spoken.begins_with("\"") and spoken.ends_with("\""):
					spoken = spoken.substr(1, spoken.length() - 2).strip_edges()
		if speaker in MUTE_SPEAKERS:
			speaker = NARRATOR
		result.append({"speaker": speaker, "text": spoken, "line_id": AudioDirector.find_line(speaker, spoken)})
	return result


## True when at least one segment has a clip to play.
static func has_voice(parts: Array[Dictionary]) -> bool:
	return parts.any(func(part: Dictionary) -> bool: return not str(part["line_id"]).is_empty())


static func _compile() -> void:
	if _bbcode != null:
		return
	_bbcode = RegEx.create_from_string("\\[/?[a-z_]+(=[^\\]]*)?\\]")
	# (?s): the words after the prefix may span lines.
	_prefix = RegEx.create_from_string("(?s)^([A-Za-z][A-Za-z .'()-]{0,30}):\\s+(.+)$")
