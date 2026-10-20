extends Node
## Identity and presentation only. No clinical, access, anomaly or competence modifiers.

var _profile: Dictionary = default_data()
var options: Dictionary = {}

static func default_data() -> Dictionary:
	return {"profile_version": 1, "configured": false, "professional_role": "psychiatrist", "name": "",
		"pronouns": "", "professional_interest": "none", "acceptance_reason": "none", "relationship": "none",
		"personal_history": "", "skin_tone": "medium", "hair_color": "brown", "hair_style": "short", "outfit": "navy", "choices": []}

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/protagonist_options.json"))
	if parsed is Dictionary and parsed.get("schema_version") == 1:
		options = parsed
	else:
		push_error("Invalid protagonist catalog")
	SaveManager.register_provider("protagonist", self)
	EventBus.story_choice_committed.connect(_record_choice)

func get_profile() -> Dictionary:
	return _profile.duplicate(true)

func display_name() -> String:
	return "Psychiatrist" if str(_profile["name"]).is_empty() else str(_profile["name"])

func validate_save_data(data: Variant) -> bool:
	if not data is Dictionary or data.get("profile_version") != 1 or data.get("professional_role") != "psychiatrist":
		return false
	if not data.get("configured") is bool or not data.get("choices") is Array:
		return false
	for key: String in ["name", "pronouns", "personal_history", "professional_interest", "acceptance_reason", "relationship", "skin_tone", "hair_color", "hair_style", "outfit"]:
		if not data.get(key) is String:
			return false
	if data["name"].length() > 64 or data["pronouns"].length() > 32 or data["personal_history"].length() > 512:
		return false
	var seen: Dictionary = {}
	for choice: Variant in data["choices"]:
		if not choice is Dictionary:
			return false
		for key: String in ["event_id", "chapter_id", "interaction_id", "option_id"]:
			if not choice.get(key) is String or choice[key].is_empty():
				return false
		if seen.has(choice["event_id"]) or not (choice.get("at_minutes") is int or choice.get("at_minutes") is float):
			return false
		seen[choice["event_id"]] = true
	return true

func apply_draft(draft: Dictionary) -> bool:
	var candidate: Dictionary = draft.duplicate(true)
	candidate["name"] = str(candidate.get("name", "")).strip_edges()
	candidate["pronouns"] = str(candidate.get("pronouns", "")).strip_edges()
	candidate["personal_history"] = str(candidate.get("personal_history", "")).strip_edges()
	candidate["configured"] = true
	candidate["choices"] = _profile["choices"].duplicate(true)
	if not validate_save_data(candidate):
		return false
	for key: String in {"professional_interest": "professional_interests", "acceptance_reason": "acceptance_reasons", "relationship": "relationships", "skin_tone": "skin_tones", "hair_color": "hair_colors", "hair_style": "hair_styles", "outfit": "outfits"}:
		var catalog_key: String = {"professional_interest": "professional_interests", "acceptance_reason": "acceptance_reasons", "relationship": "relationships", "skin_tone": "skin_tones", "hair_color": "hair_colors", "hair_style": "hair_styles", "outfit": "outfits"}[key]
		if not options.get(catalog_key, {}).has(candidate[key]):
			return false
	_profile = candidate
	EventBus.protagonist_profile_changed.emit()
	return true

func appearance_color(field: String, catalog: String, fallback: String) -> Color:
	return Color(str(options.get(catalog, {}).get(_profile.get(field), fallback)))

func _record_choice(chapter_id: String, interaction_id: String, option_id: String) -> void:
	var event_id: String = "%s:%s:%s" % [chapter_id, interaction_id, option_id]
	for choice: Dictionary in _profile["choices"]:
		if choice["event_id"] == event_id:
			return
	_profile["choices"].append({"event_id": event_id, "chapter_id": chapter_id, "interaction_id": interaction_id,
			"option_id": option_id, "at_minutes": TimeManager.total_minutes})

func to_save_data() -> Dictionary:
	return get_profile()

func load_save_data(data: Dictionary) -> void:
	if validate_save_data(data):
		_profile = data.duplicate(true)
		_profile["profile_version"] = int(_profile["profile_version"])
		for choice: Dictionary in _profile["choices"]:
			choice["at_minutes"] = int(choice["at_minutes"])
		EventBus.protagonist_profile_changed.emit()

func reset_state() -> void:
	_profile = default_data()
	EventBus.protagonist_profile_changed.emit()
