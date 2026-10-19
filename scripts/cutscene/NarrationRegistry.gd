class_name NarrationRegistry
extends RefCounted
## Authored recap text is separate from gameplay dialogue and approved art.
## Missing audio is recoverable; invalid text/cue data is rejected.
const PATH: String = "res://data/narration/recaps.json"

static func load_data() -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return value if value is Dictionary else {}

static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if data.get("schema_version") != 1:
		errors.append("narration schema_version must be 1")
	var tracks: Variant = data.get("tracks")
	var bindings: Variant = data.get("bindings")
	if not tracks is Dictionary or not bindings is Dictionary:
		return ["narration tracks and bindings must be objects"]
	for id: String in tracks:
		var track: Variant = tracks[id]
		if not track is Dictionary:
			errors.append("narration track must be an object: " + id)
			continue
		if track.get("id") != id or str(track.get("text", "")).strip_edges().is_empty():
			errors.append("narration track needs matching id and text: " + id)
		if not str(track.get("audio_path", "")).begins_with("res://audio/narration/"):
			errors.append("narration audio must stay in audio/narration: " + id)
		var duration: Variant = track.get("estimated_seconds", 0)
		if not (duration is int or duration is float) or not is_finite(float(duration)) or float(duration) <= 0.0 or float(duration) > 120.0:
			errors.append("narration duration outside 0..120: " + id)
		var cues: Variant = track.get("cues", [])
		if not cues is Array:
			errors.append("narration cues must be an array: " + id)
			continue
		var previous_end: float = 0.0
		for cue: Variant in cues:
			if not cue is Dictionary or not cue.get("start") is float or not cue.get("end") is float:
				errors.append("narration cue needs numeric start/end: " + id)
				continue
			var start: float = float(cue["start"])
			var end: float = float(cue["end"])
			if not is_finite(start) or not is_finite(end) or start < previous_end or end <= start or end > 120.0 or str(cue.get("text", "")).is_empty():
				errors.append("narration cue timing/text invalid: " + id)
			previous_end = end
	for ref: String in bindings:
		var binding: Variant = bindings[ref]
		if not binding is Dictionary:
			errors.append("narration binding must be object: " + ref)
			continue
		for id: String in [str(binding.get("default", ""))]:
			if not tracks.has(id):
				errors.append("unknown narration track: " + id)
			elif ref != str(tracks[id].get("chapter_id")) + ":" + str(tracks[id].get("panel_id")):
				errors.append("narration panel/chapter mismatch: " + ref)
		var variants: Variant = binding.get("variants", [])
		if not variants is Array:
			errors.append("narration variants must be array: " + ref)
			continue
		for variant: Variant in variants:
			if not variant is Dictionary or not variant.get("flags") is Array or (variant.get("flags") as Array).is_empty() or not tracks.has(str(variant.get("track", ""))):
				errors.append("invalid narration variant: " + ref)
	return errors

## Only exactly one supported ending may play; ambiguous/legacy saves use a
## neutral caption-only fallback, never a randomly chosen outcome.
static func resolve(ref: String, story: Dictionary, data: Dictionary) -> Dictionary:
	var binding: Dictionary = data.get("bindings", {}).get(ref, {})
	if binding.is_empty():
		return {}
	var id: String = str(binding.get("default", ""))
	var variants: Array = binding.get("variants", [])
	var matches: Array[String] = []
	var choices: int = 0
	var flags: Array = story.get("chapters", {}).get(ref.get_slice(":", 0), {}).get("flags", [])
	for variant: Dictionary in variants:
		if variant["flags"][0] in flags:
			choices += 1
		var supported: bool = true
		for flag: String in variant["flags"]:
			if not flag in flags:
				supported = false
		if supported:
			matches.append(str(variant["track"]))
	if matches.size() == 1 and choices == 1:
		id = matches[0]
	var result: Dictionary = data.get("tracks", {}).get(id, {}).duplicate(true)
	if not variants.is_empty() and (matches.size() != 1 or choices != 1):
		result["audio_path"] = "" # Caption-only recovery; no invented ending.
	return result
