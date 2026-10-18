class_name CharacterVisualPreview
extends RefCounted
## Review-only character visuals, enabled from the command line and never by default.
##
## Unapproved character models can be viewed in the real Chapter 1 scene without
## being wired into it: run the game with `-- --character-preview=staff_bennett`
## (or `staff_bennett:v01` for an older candidate). Without the argument every
## WardCharacter keeps its placeholder. Nothing here touches story, dialogue,
## clinical or save state; WardCharacter.set_visual_scene still validates the model
## and falls back to the capsule if it is missing or invalid.

const ARG_PREFIX: String = "--character-preview="

## character id -> { version -> GLB path }. Candidates listed here are NOT approved;
## see tools/blender/characters/NAOMI_VISUAL_QA.md.
const CANDIDATES: Dictionary = {
	"staff_bennett": {
		"v01": "res://assets/exports/characters/Naomi_Bennett_Base_v01.glb",
		"v02": "res://assets/exports/characters/Naomi_Bennett_Base_v02.glb",
	},
}
const DEFAULT_VERSION: Dictionary = {
	"staff_bennett": "v02",
}

static var _requests: Dictionary = {}
static var _parsed: bool = false


## Character id -> requested version, parsed from arguments after `--`.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var requests: Dictionary = {}
	for arg: String in args:
		if not arg.begins_with(ARG_PREFIX):
			continue
		for item: String in arg.trim_prefix(ARG_PREFIX).split(",", false):
			var parts: PackedStringArray = item.strip_edges().split(":", false)
			if parts.is_empty():
				continue
			var id: String = parts[0]
			if not CANDIDATES.has(id):
				push_warning("CharacterVisualPreview: no review candidate for '%s'" % id)
				continue
			var version: String = parts[1] if parts.size() > 1 else str(DEFAULT_VERSION.get(id, ""))
			if not (CANDIDATES[id] as Dictionary).has(version):
				push_warning("CharacterVisualPreview: '%s' has no candidate '%s'" % [id, version])
				continue
			requests[id] = version
	return requests


## Overrides the command line; tests use this. Pass {} to turn previews off.
static func set_requests(requests: Dictionary) -> void:
	_requests = requests.duplicate()
	_parsed = true


static func reset() -> void:
	_requests = {}
	_parsed = false


static func requested_version(character_id: String) -> String:
	if not _parsed:
		set_requests(parse_args(OS.get_cmdline_user_args()))
	return str(_requests.get(character_id, ""))


static func candidate_path(character_id: String, version: String) -> String:
	return str((CANDIDATES.get(character_id, {}) as Dictionary).get(version, ""))


## The requested candidate scene, or null when no preview is requested or it cannot load.
static func scene_for(character_id: String) -> PackedScene:
	var version: String = requested_version(character_id)
	if version.is_empty():
		return null
	var path: String = candidate_path(character_id, version)
	if not ResourceLoader.exists(path):
		push_warning("CharacterVisualPreview: %s is not imported; keeping placeholder for %s" % [path, character_id])
		return null
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		push_warning("CharacterVisualPreview: %s is not a scene; keeping placeholder for %s" % [path, character_id])
		return null
	print("[The Forensic Ward] Review preview: %s uses unapproved candidate %s (%s)" % [character_id, version, path])
	return scene
