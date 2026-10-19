class_name CampaignCastVisuals
extends RefCounted
## Cosmetic campaign casting; never writes story, clinical or save state.
## Existing --character-preview overrides remain available for model review.
const DATA_PATH: String = "res://data/character_visuals.json"

static func load_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary or not validate(parsed).is_empty():
		push_warning("CampaignCastVisuals: invalid visual catalogue; using character fallbacks")
		return {}
	return parsed

static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if data.get("schema_version") != 1 or not data.get("characters") is Dictionary:
		errors.append("character visuals require schema_version 1 and characters object")
		return errors
	for id: String in data["characters"]:
		var entry: Variant = data["characters"][id]
		if not entry is Dictionary:
			errors.append("invalid character visual: " + id)
			continue
		var path: String = str(entry.get("scene", ""))
		if not path.begins_with("res://assets/exports/characters/") or not path.ends_with(".glb") or ".." in path:
			errors.append("invalid character model path: " + id)
		if not entry.get("model_yaw_degrees") is float or not is_finite(float(entry.get("model_yaw_degrees", NAN))):
			errors.append("invalid model yaw: " + id)
		if str(entry.get("review_status", "")).is_empty():
			errors.append("missing visual review status: " + id)
		if not _valid_offset(entry.get("marker_offset")):
			errors.append("invalid marker offset: " + id)
		var overrides: Variant = entry.get("marker_offsets", {})
		if not overrides is Dictionary:
			errors.append("marker_offsets must be object: " + id)
		else:
			for marker: String in overrides:
				if not _valid_offset(overrides[marker]):
					errors.append("invalid marker offset: " + id + "/" + marker)
	return errors

static func _valid_offset(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for component: Variant in value:
		if not (component is float or component is int) or not is_finite(float(component)) or absf(float(component)) > 2.0:
			return false
	return true

## Called before adding the actor to the tree, so its animation/acting setup
## sees the final model during _ready. Returns its local marker offset.
static func configure(character: WardCharacter, marker: String) -> Vector3:
	if not CharacterVisualPreview.requested_version(character.character_id).is_empty():
		return Vector3.ZERO
	var entry: Dictionary = load_data().get("characters", {}).get(character.character_id, {})
	if entry.is_empty():
		return Vector3.ZERO
	var path: String = str(entry["scene"])
	if not ResourceLoader.exists(path):
		push_warning("CampaignCastVisuals: missing model for %s; using placeholder" % character.character_id)
		return Vector3.ZERO
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		push_warning("CampaignCastVisuals: invalid scene for %s; using placeholder" % character.character_id)
		return Vector3.ZERO
	character.visual_scene = scene
	character.visual_placement = Transform3D(Basis(Vector3.UP, deg_to_rad(float(entry["model_yaw_degrees"]))), Vector3.ZERO)
	character.set_meta("visual_review_status", entry["review_status"])
	var offset: Array = entry.get("marker_offsets", {}).get(marker, entry["marker_offset"])
	return Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
