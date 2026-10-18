class_name CutsceneRegistry
extends RefCounted
## CutsceneRegistry: loads and validates the graphic-novel cutscenes in
## res://data/cutscenes/*.json (schema in docs/CUTSCENES.md).
##
## Validation cross-checks every reference against data that already exists:
## dialogue line ids in res://data/narrative, music cues in res://audio/cues.json,
## chapter ids and caption text in res://data/campaign.json, and panel textures
## on disk. A cutscene that fails validation never plays.
##
## Nothing here writes story, clinical or save state. Until the owner approves a
## cutscene and its placement, the only allowed mode is "review_only" and the only
## trigger is "manual_preview" (the --cutscene-preview command-line argument or
## the review scene), so no cutscene can start in the normal campaign.

const DIRECTORY: String = "res://data/cutscenes"
const CAMPAIGN_PATH: String = "res://data/campaign.json"
const CUES_PATH: String = "res://audio/cues.json"
const NARRATIVE_DIR: String = "res://data/narrative"

const SCHEMA_VERSION: int = 1
const MODES: Array[String] = ["review_only"]
const TRIGGER_KINDS: Array[String] = ["manual_preview"]
const TRANSITIONS: Array[String] = ["cut", "dissolve", "fade_black"]
const FRAMES: Array[String] = ["inset", "full_bleed"]
const AMBIENCE_MODES: Array[String] = ["keep", "duck", "stop"]
const MAX_LAYERS: int = 3
const MAX_PAN: float = 0.05
const MIN_ZOOM: float = 1.0
const MAX_ZOOM: float = 1.12
## Music that marks a story reveal, with the earliest chapter a cutscene may use it.
## "" = never from a cutscene (only its explicit narrative event may start it).
const RESTRICTED_CUES: Dictionary = {
	"mus_temporal_fracture": "",
	"mus_final_revelation": "ch5",
	"mus_ending_credits": "ch5",
}


## {cutscenes: {id: data}, errors: [String]}. Files are read in name order.
static func load_all() -> Dictionary:
	var cutscenes: Dictionary = {}
	var errors: Array[String] = []
	var context: Dictionary = reference_context()
	for file_name: String in _json_files():
		var path: String = "%s/%s" % [DIRECTORY, file_name]
		var data: Variant = _read_json(path)
		if not data is Dictionary:
			errors.append("%s: not a JSON object" % path)
			continue
		var problems: Array[String] = validate(data, context)
		var id: String = str((data as Dictionary).get("cutscene_id", ""))
		if cutscenes.has(id):
			problems.append("duplicate cutscene_id '%s'" % id)
		if file_name.get_basename() != id:
			problems.append("file name must be <cutscene_id>.json")
		for problem: String in problems:
			errors.append("%s: %s" % [path, problem])
		if problems.is_empty():
			cutscenes[id] = data
	return {"cutscenes": cutscenes, "errors": errors}


## The validated cutscene, or {} with `errors` filled in.
static func get_cutscene(cutscene_id: String, errors: Array[String] = []) -> Dictionary:
	var path: String = "%s/%s.json" % [DIRECTORY, cutscene_id]
	if not FileAccess.file_exists(path):
		errors.append("unknown cutscene '%s'" % cutscene_id)
		return {}
	var data: Variant = _read_json(path)
	if not data is Dictionary:
		errors.append("%s: not a JSON object" % path)
		return {}
	var problems: Array[String] = validate(data, reference_context())
	if str((data as Dictionary).get("cutscene_id", "")) != cutscene_id:
		problems.append("cutscene_id does not match the file name")
	errors.append_array(problems)
	return {} if not problems.is_empty() else data


## Ids, cues and captions that cutscenes may reference.
static func reference_context() -> Dictionary:
	var campaign: Variant = _read_json(CAMPAIGN_PATH)
	var cues: Variant = _read_json(CUES_PATH)
	var chapters: Dictionary = {}
	var captions: Dictionary = {}
	if campaign is Dictionary:
		var institution: Dictionary = campaign.get("institution", {})
		if institution.has("name"):
			captions["institution.name"] = str(institution["name"])
		var order: int = 0
		for chapter: Dictionary in campaign.get("chapters", []):
			chapters[str(chapter.get("id", ""))] = order
			captions["chapter.%s.title" % chapter.get("id", "")] = str(chapter.get("title", ""))
			order += 1
	var lines: Dictionary = {}
	for file_name: String in DirAccess.get_files_at(NARRATIVE_DIR):
		if file_name.begins_with("._") or not file_name.ends_with(".json"):
			continue
		var narrative: Variant = _read_json("%s/%s" % [NARRATIVE_DIR, file_name])
		if not narrative is Dictionary:
			continue
		for scene: Dictionary in narrative.get("scenes", []):
			for line: Dictionary in scene.get("lines", []):
				lines[str(line.get("id", ""))] = str(narrative.get("chapter", ""))
	return {
		"chapters": chapters,
		"captions": captions,
		"lines": lines,
		"cues": (cues.get("cues", {}) as Dictionary).keys() if cues is Dictionary else [],
	}


## Every schema and reference problem in one cutscene; [] when it is valid.
static func validate(data: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if data.get("schema_version") != float(SCHEMA_VERSION) and data.get("schema_version") != SCHEMA_VERSION:
		errors.append("schema_version must be %d" % SCHEMA_VERSION)
	var id: String = str(data.get("cutscene_id", ""))
	if not id.begins_with("cs_") or id != id.to_lower() or " " in id:
		errors.append("cutscene_id must be lower_snake_case starting with cs_")
	var chapter_id: String = str(data.get("chapter_id", ""))
	var chapters: Dictionary = context.get("chapters", {})
	if not chapters.has(chapter_id):
		errors.append("unknown chapter_id '%s'" % chapter_id)
	if str(data.get("source_scene_id", "")).is_empty():
		errors.append("source_scene_id is required (the screenplay scene this cutscene covers)")
	if not str(data.get("mode", "")) in MODES:
		errors.append("mode must be one of %s" % str(MODES))
	if not data.get("approved") is bool:
		errors.append("approved must be true or false")
	var trigger: Variant = data.get("trigger")
	if not trigger is Dictionary or not str(trigger.get("kind", "")) in TRIGGER_KINDS:
		errors.append("trigger.kind must be one of %s" % str(TRIGGER_KINDS))
	if data.get("fallback_action") != "restore_world":
		errors.append("fallback_action must be restore_world")
	if data.has("music"):
		errors.append_array(_validate_music(data["music"], chapter_id, context))
	var panels: Variant = data.get("panels")
	if not panels is Array or (panels as Array).is_empty():
		errors.append("panels must be a non-empty array")
		return errors
	var panel_ids: Dictionary = {}
	for index: int in (panels as Array).size():
		var panel: Variant = panels[index]
		if not panel is Dictionary:
			errors.append("panel %d must be an object" % index)
			continue
		var panel_id: String = str(panel.get("id", ""))
		if panel_id.is_empty() or panel_ids.has(panel_id):
			errors.append("panel %d needs a unique id" % index)
		panel_ids[panel_id] = true
		for problem: String in _validate_panel(panel, chapter_id, context):
			errors.append("panel '%s': %s" % [panel_id, problem])
	return errors


static func _validate_music(music: Variant, chapter_id: String, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not music is Dictionary:
		return ["music must be an object"]
	var cue: String = str(music.get("cue", ""))
	if not cue in context.get("cues", []):
		errors.append("music.cue '%s' is not in audio/cues.json" % cue)
	elif RESTRICTED_CUES.has(cue):
		var earliest: String = RESTRICTED_CUES[cue]
		var chapters: Dictionary = context.get("chapters", {})
		if earliest.is_empty() or int(chapters.get(chapter_id, -1)) < int(chapters.get(earliest, 99)):
			errors.append("music.cue '%s' is reserved for its story moment and may not be used here" % cue)
	if not str(music.get("ambience", "duck")) in AMBIENCE_MODES:
		errors.append("music.ambience must be one of %s" % str(AMBIENCE_MODES))
	for key: String in ["ambience_db", "fade"]:
		if music.has(key) and not (music[key] is float or music[key] is int):
			errors.append("music.%s must be a number" % key)
	return errors


static func _validate_panel(panel: Dictionary, chapter_id: String, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var duration: Variant = panel.get("duration_seconds")
	if not (duration is float or duration is int) or float(duration) <= 0.0:
		errors.append("duration_seconds must be positive")
	if not str(panel.get("transition", "dissolve")) in TRANSITIONS:
		errors.append("transition must be one of %s" % str(TRANSITIONS))
	var transition_seconds: float = float(panel.get("transition_seconds", 0.0))
	if transition_seconds < 0.0 or (duration is float and transition_seconds > float(duration) * 0.5):
		errors.append("transition_seconds must be between 0 and half the panel")
	if not str(panel.get("frame", "inset")) in FRAMES:
		errors.append("frame must be one of %s" % str(FRAMES))
	var layers: Variant = panel.get("layers")
	if not layers is Array or (layers as Array).is_empty() or (layers as Array).size() > MAX_LAYERS:
		errors.append("layers must hold 1 to %d entries" % MAX_LAYERS)
	else:
		for layer: Variant in layers:
			if not layer is Dictionary:
				errors.append("layer must be an object")
				continue
			var texture: String = str(layer.get("texture", ""))
			if not texture.begins_with("res://") or texture.ends_with(".import"):
				errors.append("layer texture must be a res:// image path")
			elif not ResourceLoader.exists(texture):
				errors.append("missing texture %s" % texture)
			var parallax: Variant = layer.get("parallax", 1.0)
			if not (parallax is float or parallax is int) or float(parallax) < 0.0 or float(parallax) > 3.0:
				errors.append("layer parallax must be between 0 and 3")
	var motion: Variant = panel.get("motion", {})
	if not motion is Dictionary:
		errors.append("motion must be an object")
	else:
		for key: String in ["zoom_from", "zoom_to"]:
			var zoom: float = float(motion.get(key, 1.0))
			if zoom < MIN_ZOOM or zoom > MAX_ZOOM:
				errors.append("motion.%s must be between %.2f and %.2f" % [key, MIN_ZOOM, MAX_ZOOM])
		for key: String in ["pan_from", "pan_to"]:
			var pan: Variant = motion.get(key, [0.0, 0.0])
			if not pan is Array or (pan as Array).size() != 2:
				errors.append("motion.%s must be [x, y]" % key)
			elif absf(float(pan[0])) > MAX_PAN or absf(float(pan[1])) > MAX_PAN:
				errors.append("motion.%s must stay within %.2f of centre" % [key, MAX_PAN])
	var caption_ref: Variant = panel.get("caption_ref")
	if caption_ref != null and not (context.get("captions", {}) as Dictionary).has(str(caption_ref)):
		errors.append("caption_ref '%s' does not name approved campaign text" % str(caption_ref))
	var line_id: Variant = panel.get("line_id")
	if line_id != null:
		var lines: Dictionary = context.get("lines", {})
		if not lines.has(str(line_id)):
			errors.append("line_id '%s' is not an existing dialogue line" % str(line_id))
		else:
			var chapters: Dictionary = context.get("chapters", {})
			if int(chapters.get(lines[str(line_id)], 99)) > int(chapters.get(chapter_id, -1)):
				errors.append("line_id '%s' belongs to a later chapter" % str(line_id))
	if panel.has("text") or panel.has("caption") or panel.has("subtitle"):
		errors.append("panels carry no literal text; use caption_ref or line_id")
	return errors


## The approved text a caption reference names, or "" if it names none.
static func resolve_caption(caption_ref: String) -> String:
	return str((reference_context().get("captions", {}) as Dictionary).get(caption_ref, ""))


static func total_duration(data: Dictionary) -> float:
	var total: float = 0.0
	for panel: Dictionary in data.get("panels", []):
		total += float(panel.get("duration_seconds", 0.0))
	return total


static func _json_files() -> Array[String]:
	var files: Array[String] = []
	if not DirAccess.dir_exists_absolute(DIRECTORY):
		return files
	for file_name: String in DirAccess.get_files_at(DIRECTORY):
		if file_name.ends_with(".json") and not file_name.begins_with("._"):
			files.append(file_name)
	files.sort()
	return files


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))
