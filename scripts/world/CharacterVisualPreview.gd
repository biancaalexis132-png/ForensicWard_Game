class_name CharacterVisualPreview
extends RefCounted
## Review-only character visuals, enabled from the command line and never by default.
##
## Unapproved character models can be viewed in the real Chapter 1 scene without
## being wired into it: run the game with `-- --character-preview=staff_bennett`
## (or `staff_bennett:v03`, `:v02`, `:v01` for an older candidate). Without the argument every
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
		"v03": "res://assets/exports/characters/Naomi_Bennett_v03.glb",
		"v04": "res://assets/exports/characters/Naomi_Bennett_v04.glb",
		# Mac pipeline validation build from PR #51 (three small clips, no face morphs).
		"v04_local": "res://assets/exports/characters/Naomi_Bennett_v04_local.glb",
		# Mac build: v04 with MPFB2 CC0 faceunit expressions and visemes (bake_mpfb_face_shapes.py).
		"v05_mpfb": "res://assets/exports/characters/Naomi_Bennett_v05_mpfb.glb",
	},
}
const DEFAULT_VERSION: Dictionary = {
	"staff_bennett": "v04",
}
## Where the previewed model stands, relative to the character's marker. Only the
## model moves; the interaction box, collision and name label stay on the marker.
## Bennett's marker sits inside the nursing-station desk facing into the office, so
## the model steps back to the office side and turns to face the corridor counter.
const PLACEMENT: Dictionary = {
	"staff_bennett": {"yaw_degrees": 180.0, "offset": Vector3(-0.05, 0.0, 0.55)},
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


## Transform to apply to a previewed model under WardCharacter/VisualRoot.
static func placement_for(character_id: String) -> Transform3D:
	var placement: Dictionary = PLACEMENT.get(character_id, {})
	var basis: Basis = Basis(Vector3.UP, deg_to_rad(float(placement.get("yaw_degrees", 0.0))))
	return Transform3D(basis, placement.get("offset", Vector3.ZERO))


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
