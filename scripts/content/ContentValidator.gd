class_name ContentValidator
extends RefCounted
## Validates parsed JSON documents against ContentSchemas and checks
## cross-file references (unknown ids, duplicate ids, dangling dialogue
## states). Pure and static, so tests can feed it deliberately broken data.
##
## Every message names the file and the exact JSON path, so a content author
## can fix it without reading code, e.g.
##   [clues.json] hypotheses[0].required_clues[1]: unknown clue id 'clue_rostr'.

static var _id_regex: RegEx = null


## Validates `value` against `schema`. Appends to `errors` / `warnings`.
static func validate_value(value: Variant, schema: Dictionary, path: String,
		errors: Array[String], warnings: Array[String]) -> void:
	var type_name: String = schema.get("type", "any")
	match type_name:
		"any":
			pass
		"object":
			if not value is Dictionary:
				errors.append("%s: expected an object, got %s." % [path, _describe(value)])
				return
			var required: Dictionary = schema.get("required", {})
			var optional: Dictionary = schema.get("optional", {})
			for field: String in required:
				if not value.has(field):
					errors.append("%s: missing required field '%s'." % [path, field])
				else:
					validate_value(value[field], required[field], _join(path, field), errors, warnings)
			for field: String in optional:
				if value.has(field):
					validate_value(value[field], optional[field], _join(path, field), errors, warnings)
			for field: Variant in value:
				if not required.has(field) and not optional.has(field):
					warnings.append("%s: unknown field '%s' (ignored)." % [path, field])
		"map":
			if not value is Dictionary:
				errors.append("%s: expected an object, got %s." % [path, _describe(value)])
				return
			for key: Variant in value:
				validate_value(value[key], schema.get("values", {}), _join(path, str(key)), errors, warnings)
		"array":
			if not value is Array:
				errors.append("%s: expected an array, got %s." % [path, _describe(value)])
				return
			var min_items: int = schema.get("min_items", 0)
			if value.size() < min_items:
				errors.append("%s: needs at least %d item(s), has %d." % [path, min_items, value.size()])
			for i: int in value.size():
				validate_value(value[i], schema.get("items", {}), "%s[%d]" % [path, i], errors, warnings)
		"string":
			if not value is String:
				errors.append("%s: expected text, got %s." % [path, _describe(value)])
			elif (value as String).strip_edges().is_empty() and not schema.get("allow_empty", false):
				errors.append("%s: must not be empty." % path)
		"id":
			if not value is String:
				errors.append("%s: expected an id string, got %s." % [path, _describe(value)])
			elif not _is_valid_id(value):
				errors.append("%s: id '%s' must use lowercase letters, digits and underscores, starting with a letter." % [path, value])
		"int":
			if not (value is int or (value is float and is_equal_approx(value, roundf(value)))):
				errors.append("%s: expected a whole number, got %s." % [path, _describe(value)])
		"number":
			if not (value is int or value is float):
				errors.append("%s: expected a number, got %s." % [path, _describe(value)])
		"bool":
			if not value is bool:
				errors.append("%s: expected true or false, got %s." % [path, _describe(value)])
		"enum":
			var allowed: Array = schema.get("values", [])
			if not value is String or not value in allowed:
				errors.append("%s: '%s' is not allowed. Use one of: %s." % [path, str(value), ", ".join(allowed)])
		_:
			errors.append("%s: schema uses unknown type '%s' (code bug)." % [path, type_name])

	if schema.has("const") and errors.is_empty() and value != schema["const"]:
		errors.append("%s: must be %s." % [path, JSON.stringify(schema["const"])])


## Validates a whole content set. `documents` maps a manifest key to
## {"file": "clues.json", "data": parsed JSON, "schema": Dictionary}.
## Returns {"errors": Array[String], "warnings": Array[String]}.
static func validate_documents(documents: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	for key: String in documents:
		var document: Dictionary = documents[key]
		var file_errors: Array[String] = []
		var file_warnings: Array[String] = []
		validate_value(document["data"], document["schema"], "", file_errors, file_warnings)
		for message: String in file_errors:
			errors.append("[%s] %s" % [document["file"], _strip_root(message)])
		for message: String in file_warnings:
			warnings.append("[%s] %s" % [document["file"], _strip_root(message)])
	# Reference checks only make sense once every file is structurally sound.
	if errors.is_empty():
		errors.append_array(check_references(documents))
	return {"errors": errors, "warnings": warnings}


## Cross-file reference and uniqueness checks. Assumes structural validity.
static func check_references(documents: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var patients: Array = _data(documents, "patients").get("patients", [])
	var clue_doc: Dictionary = _data(documents, "clues")
	var clues: Array = clue_doc.get("clues", [])
	var hypotheses: Array = clue_doc.get("hypotheses", [])
	var sources: Array = _data(documents, "source_catalog").get("items", [])
	var staff: Array = _data(documents, "staff").get("staff", [])

	var patient_ids: Dictionary = _collect_ids(patients, _file(documents, "patients"), "patients", errors)
	var clue_ids: Dictionary = _collect_ids(clues, _file(documents, "clues"), "clues", errors)
	_collect_ids(hypotheses, _file(documents, "clues"), "hypotheses", errors)
	var source_ids: Dictionary = _collect_ids(sources, _file(documents, "source_catalog"), "items", errors)
	var staff_ids: Dictionary = _collect_ids(staff, _file(documents, "staff"), "staff", errors)
	var chapter_ids: Dictionary = _check_campaign(documents, errors)
	var zones_by_id: Dictionary = _check_zones(documents, errors)

	# Observation ids are unique per patient; rules reference them.
	var observations_by_patient: Dictionary = {}
	for i: int in patients.size():
		var patient: Dictionary = patients[i]
		observations_by_patient[patient["id"]] = _collect_ids(patient["presentation"]["observations"],
				_file(documents, "patients"), "patients[%d].presentation.observations" % i, errors)

	for i: int in hypotheses.size():
		var required_clues: Array = hypotheses[i]["required_clues"]
		for j: int in required_clues.size():
			_require_known(required_clues[j], clue_ids, "clue", _file(documents, "clues"),
					"hypotheses[%d].required_clues[%d]" % [i, j], errors)

	var dialogue_owner: Dictionary = {}  # patient id -> file
	for key: String in _keys(documents, ContentRegistry.DIALOGUE_KEY):
		var dialogue: Dictionary = _data(documents, key)
		var file: String = _file(documents, key)
		_require_known(dialogue["patient_id"], patient_ids, "patient", file, "patient_id", errors)
		if dialogue_owner.has(dialogue["patient_id"]):
			errors.append("[%s] patient_id: '%s' already has dialogue in %s; one dialogue file per patient." % [
					file, dialogue["patient_id"], dialogue_owner[dialogue["patient_id"]]])
		dialogue_owner[dialogue["patient_id"]] = file
		var state_ids: Dictionary = _collect_ids(dialogue["states"], file, "states", errors)
		for i: int in dialogue["states"].size():
			var choices: Array = dialogue["states"][i]["choices"]
			_collect_ids(choices, file, "states[%d].choices" % i, errors)
			for j: int in choices.size():
				_require_known(choices[j]["next"], state_ids, "dialogue state", file,
						"states[%d].choices[%d].next" % [i, j], errors)
				var recorded: Array = choices[j].get("records_observations", [])
				for k: int in recorded.size():
					_require_known(recorded[k], observations_by_patient.get(dialogue["patient_id"], {}),
							"observation of %s" % dialogue["patient_id"], file,
							"states[%d].choices[%d].records_observations[%d]" % [i, j, k], errors)

	if documents.has("clinical_rules"):
		var rules: Array = _data(documents, "clinical_rules")["rules"]
		var file: String = _file(documents, "clinical_rules")
		_collect_ids(rules, file, "rules", errors)
		var actions: Array = _data(documents, "clinical_rules").get("actions", [])
		var action_ids: Dictionary = _collect_ids(actions, file, "actions", errors)
		for i: int in actions.size():
			_require_known(actions[i]["patient_id"], patient_ids, "patient", file, "actions[%d].patient_id" % i, errors)
		for i: int in rules.size():
			var rule: Dictionary = rules[i]
			if not actions.is_empty():
				_require_known(rule["trigger_action"], action_ids, "clinical action", file,
						"rules[%d].trigger_action" % i, errors)
			_require_known(rule["patient_id"], patient_ids, "patient", file, "rules[%d].patient_id" % i, errors)
			var known_observations: Dictionary = observations_by_patient.get(rule["patient_id"], {})
			var present: Array = rule["condition"].get("observations_present", [])
			for j: int in present.size():
				_require_known(present[j], known_observations, "observation of %s" % rule["patient_id"], file,
						"rules[%d].condition.observations_present[%d]" % [i, j], errors)
			for j: int in rule["source_catalog_ids"].size():
				_require_known(rule["source_catalog_ids"][j], source_ids, "source catalog", file,
						"rules[%d].source_catalog_ids[%d]" % [i, j], errors)
	for key: String in _keys(documents, ContentRegistry.WORLD_KEY):
		var world: Dictionary = _data(documents, key)
		var file: String = _file(documents, key)
		_require_known(world["start_zone"], zones_by_id, "zone", file, "start_zone", errors)
		if zones_by_id.get(world["start_zone"], {}).get("status", "built") != "built":
			errors.append("[%s] start_zone: '%s' is a placeholder zone with no environments yet." % [file, world["start_zone"]])
		for door_id: String in world["doors"]:
			if world["doors"][door_id].has("zone"):
				_require_known(world["doors"][door_id]["zone"], zones_by_id, "zone", file, "doors.%s.zone" % door_id, errors)
		for list_name: String in ["interactables", "characters"]:
			for i: int in world[list_name].size():
				if world[list_name][i].has("zone"):
					_require_known(world[list_name][i]["zone"], zones_by_id, "zone", file,
							"%s[%d].zone" % [list_name, i], errors)
		for i: int in world["interactables"].size():
			var entry: Dictionary = world["interactables"][i]
			if entry["type"] in ["clue_terminal", "clue_pickup"]:
				if not entry.has("clue_id"):
					errors.append("[%s] interactables[%d]: type '%s' needs a clue_id." % [file, i, entry["type"]])
				else:
					_require_known(entry["clue_id"], clue_ids, "clue", file, "interactables[%d].clue_id" % i, errors)
		for i: int in world["characters"].size():
			var character: Dictionary = world["characters"][i]
			var known: Dictionary = staff_ids if character["kind"] == "staff" else patient_ids
			_require_known(character["character_id"], known, character["kind"], file,
					"characters[%d].character_id" % i, errors)
	var hypothesis_ids: Dictionary = {}
	for hypothesis: Dictionary in hypotheses:
		hypothesis_ids[hypothesis["id"]] = true
	var refs: Dictionary = {"patients": patient_ids, "clues": clue_ids, "hypotheses": hypothesis_ids,
			"staff": staff_ids, "chapters": chapter_ids}
	for key: String in _keys(documents, ContentRegistry.STORY_KEY):
		var story: Dictionary = _data(documents, key)
		var file: String = _file(documents, key)
		var chapter_id: String = key.trim_prefix(ContentRegistry.STORY_KEY)
		if story["chapter"] != chapter_id:
			errors.append("[%s] chapter: '%s' does not match the campaign chapter '%s' that loads this file." % [
					file, story["chapter"], chapter_id])
		_collect_ids(story["objectives"], file, "objectives", errors)
		_collect_ids(story["beats"], file, "beats", errors)
		for i: int in story["objectives"].size():
			StoryLogic.check_condition(story["objectives"][i]["complete_when"], "[%s] objectives[%d].complete_when" % [file, i], refs, errors)
			if story["objectives"][i].has("expires_when"):
				StoryLogic.check_condition(story["objectives"][i]["expires_when"], "[%s] objectives[%d].expires_when" % [file, i], refs, errors)
		for i: int in story["beats"].size():
			var beat: Dictionary = story["beats"][i]
			StoryLogic.check_condition(beat["when"], "[%s] beats[%d].when" % [file, i], refs, errors)
			for j: int in beat["actions"].size():
				StoryLogic.check_action(beat["actions"][j], "[%s] beats[%d].actions[%d]" % [file, i, j], refs, errors)
		for i: int in story["staff_lines"].size():
			var line: Dictionary = story["staff_lines"][i]
			_require_known(line["staff_id"], staff_ids, "staff", file, "staff_lines[%d].staff_id" % i, errors)
			StoryLogic.check_condition(line["when"], "[%s] staff_lines[%d].when" % [file, i], refs, errors)
			if line.has("verify_clue"):
				_require_known(line["verify_clue"], clue_ids, "clue", file, "staff_lines[%d].verify_clue" % i, errors)
		var sign_out: Dictionary = story["sign_out"]
		for j: int in sign_out["handover_patients"].size():
			_require_known(sign_out["handover_patients"][j], patient_ids, "patient", file, "sign_out.handover_patients[%d]" % j, errors)
		for list_name: String in ["documented_trust", "undocumented_trust"]:
			for j: int in sign_out[list_name].size():
				_require_known(sign_out[list_name][j]["staff_id"], staff_ids, "staff", file,
						"sign_out.%s[%d].staff_id" % [list_name, j], errors)
	errors.append_array(check_global_ids(documents))
	return errors


## Campaign rules: chapter ids look like ch1, ch2...; the start chapter is
## playable; a playable chapter has a story; a planned chapter ships no
## story yet. Returns the chapter ids.
static func _check_campaign(documents: Dictionary, errors: Array[String]) -> Dictionary:
	if not documents.has("campaign"):
		return {}
	var campaign: Dictionary = _data(documents, "campaign")
	var file: String = _file(documents, "campaign")
	var chapters: Array = campaign["chapters"]
	var chapter_ids: Dictionary = _collect_ids(chapters, file, "chapters", errors)
	var pattern: RegEx = RegEx.create_from_string(ContentSchemas.CHAPTER_ID_PATTERN)
	for i: int in chapters.size():
		var chapter: Dictionary = chapters[i]
		if pattern.search(chapter["id"]) == null:
			errors.append("[%s] chapters[%d].id: '%s' must look like ch1, ch2 ..." % [file, i, chapter["id"]])
		if chapter["status"] == "playable" and not chapter.has("story"):
			errors.append("[%s] chapters[%d]: a playable chapter needs a \"story\" file." % [file, i])
		if chapter["status"] == "planned" and (chapter.has("story") or chapter.has("world")):
			errors.append("[%s] chapters[%d]: a planned chapter ships no story or world yet; mark it playable once its content is approved." % [file, i])
	_require_known(campaign["start_chapter"], chapter_ids, "chapter", file, "start_chapter", errors)
	for chapter: Dictionary in chapters:
		if chapter["id"] == campaign["start_chapter"] and chapter["status"] != "playable":
			errors.append("[%s] start_chapter: '%s' is not playable." % [file, chapter["id"]])
	return chapter_ids


## Zone rules: a built zone has environments that exist and floor-plan
## bounds; zones on one level never overlap (the level decides what may be
## loaded together). A connection joins two different zones; a seamless one
## stays on one level and names its door, the zone whose geometry holds that
## door, and an anchor point; a fade one names, per end, the node the player
## uses and where they arrive. Returns zone id -> zone.
static func _check_zones(documents: Dictionary, errors: Array[String]) -> Dictionary:
	if not documents.has("zones"):
		return {}
	var data: Dictionary = _data(documents, "zones")
	var file: String = _file(documents, "zones")
	var zones: Array = data["zones"]
	var by_id: Dictionary = {}
	for i: int in _collect_ids(zones, file, "zones", errors).values():
		by_id[zones[i]["id"]] = zones[i]
	for i: int in zones.size():
		var zone: Dictionary = zones[i]
		var where: String = "[%s] zones[%d]" % [file, i]
		if zone["status"] == "built" and (zone["environments"].is_empty() or zone["bounds"].is_empty()):
			errors.append("%s: a built zone needs environments and bounds." % where)
		if zone["status"] == "placeholder" and not zone["environments"].is_empty():
			errors.append("%s: a placeholder zone lists no environments; mark it built once they exist." % where)
		for j: int in zone["environments"].size():
			var path: String = zone["environments"][j]
			if not path.begins_with("res://assets/") or not ResourceLoader.exists(path):
				errors.append("%s.environments[%d]: '%s' is not an imported scene under res://assets/." % [where, j, path])
		for j: int in zone["bounds"].size():
			if not _rect_is_valid(zone["bounds"][j]):
				errors.append("%s.bounds[%d]: min_xz must be below max_xz on both axes." % [where, j])
		for j: int in i:
			if zones[j]["level"] == zone["level"] and _bounds_overlap(zones[j]["bounds"], zone["bounds"]):
				errors.append("%s: bounds overlap %s on level '%s'; zones on one level must not overlap." % [
						where, zones[j]["id"], zone["level"]])
	var connections: Array = data["connections"]
	_collect_ids(connections, file, "connections", errors)
	for i: int in connections.size():
		var connection: Dictionary = connections[i]
		var where: String = "[%s] connections[%d]" % [file, i]
		var ends: Array = connection["ends"]
		if ends.size() != 2 or ends[0]["zone"] == ends[ends.size() - 1]["zone"]:
			errors.append("%s.ends: a connection joins exactly two different zones." % where)
			continue
		for j: int in 2:
			_require_known(ends[j]["zone"], by_id, "zone", file, "connections[%d].ends[%d].zone" % [i, j], errors)
		if not (by_id.has(ends[0]["zone"]) and by_id.has(ends[1]["zone"])):
			continue
		var same_level: bool = by_id[ends[0]["zone"]]["level"] == by_id[ends[1]["zone"]]["level"]
		if connection["transition"] == "seamless":
			if not same_level:
				errors.append("%s: a seamless connection stays on one level; use \"fade\" between levels." % where)
			for field: String in ["door_id", "door_zone", "anchor_xz"]:
				if not connection.has(field):
					errors.append("%s: a seamless connection needs \"%s\"." % [where, field])
			if connection.has("door_zone") and not connection["door_zone"] in [ends[0]["zone"], ends[1]["zone"]]:
				errors.append("%s.door_zone: '%s' is not one of the connection's zones." % [where, connection["door_zone"]])
		else:
			for j: int in 2:
				if not ends[j].has("node") or not ends[j].has("arrival"):
					errors.append("%s.ends[%d]: a fade connection needs \"node\" and \"arrival\" at each end." % [where, j])
	return by_id


static func _rect_is_valid(rect: Dictionary) -> bool:
	return rect["min_xz"][0] < rect["max_xz"][0] and rect["min_xz"][1] < rect["max_xz"][1]


## True when any rectangle of `a` shares area with any rectangle of `b`
## (touching edges is fine: neighbouring zones meet at a doorway).
static func _bounds_overlap(a: Array, b: Array) -> bool:
	for ra: Dictionary in a:
		for rb: Dictionary in b:
			if ra["min_xz"][0] < rb["max_xz"][0] and rb["min_xz"][0] < ra["max_xz"][0] \
					and ra["min_xz"][1] < rb["max_xz"][1] and rb["min_xz"][1] < ra["max_xz"][1]:
				return true
	return false


## Ids of patients, staff, clues, hypotheses, objectives, beats, zones and
## connections must carry their kind's prefix (ContentSchemas.ID_PREFIXES)
## and be unique across every file and chapter, so a later chapter can never
## shadow an earlier id.
static func check_global_ids(documents: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}  # id -> "file path"
	var groups: Array = [
		["patient", "patients", "patients", _data(documents, "patients").get("patients", [])],
		["staff", "staff", "staff", _data(documents, "staff").get("staff", [])],
		["clue", "clues", "clues", _data(documents, "clues").get("clues", [])],
		["hypothesis", "clues", "hypotheses", _data(documents, "clues").get("hypotheses", [])],
	]
	groups.append(["zone", "zones", "zones", _data(documents, "zones").get("zones", [])])
	groups.append(["connection", "zones", "connections", _data(documents, "zones").get("connections", [])])
	for key: String in _keys(documents, ContentRegistry.STORY_KEY):
		groups.append(["objective", key, "objectives", _data(documents, key).get("objectives", [])])
		groups.append(["beat", key, "beats", _data(documents, key).get("beats", [])])
	for group: Array in groups:
		var kind: String = group[0]
		var file: String = _file(documents, group[1])
		var prefix: String = ContentSchemas.ID_PREFIXES[kind]
		for i: int in group[3].size():
			var id: String = group[3][i]["id"]
			var where: String = "[%s] %s[%d].id" % [file, group[2], i]
			if not id.begins_with(prefix):
				errors.append("%s: %s id '%s' must start with '%s'." % [where, kind, id, prefix])
			if seen.has(id) and not seen[id].begins_with("[%s] %s[" % [file, group[2]]):
				errors.append("%s: id '%s' is already used at %s; ids are unique across all files and chapters." % [where, id, seen[id]])
			elif not seen.has(id):
				seen[id] = where
	return errors


static func _collect_ids(items: Array, file: String, path: String, errors: Array[String]) -> Dictionary:
	var ids: Dictionary = {}
	for i: int in items.size():
		var id: String = items[i]["id"]
		if ids.has(id):
			errors.append("[%s] %s[%d].id: duplicate id '%s' (first used at %s[%d])." % [file, path, i, id, path, ids[id]])
		else:
			ids[id] = i
	return ids


static func _require_known(id: String, known: Dictionary, kind: String, file: String, path: String,
		errors: Array[String]) -> void:
	if not known.has(id):
		var choices: Array = known.keys()
		choices.sort()
		errors.append("[%s] %s: unknown %s id '%s'. Known ids: %s." % [file, path, kind, id,
				", ".join(choices) if not choices.is_empty() else "(none)"])


## Document keys with a prefix such as ContentRegistry.STORY_KEY, sorted.
static func _keys(documents: Dictionary, prefix: String) -> Array[String]:
	var keys: Array[String] = []
	for key: String in documents:
		if key.begins_with(prefix):
			keys.append(key)
	keys.sort()
	return keys


static func _data(documents: Dictionary, key: String) -> Dictionary:
	return documents[key]["data"] if documents.has(key) else {}


static func _file(documents: Dictionary, key: String) -> String:
	return documents[key]["file"] if documents.has(key) else key + ".json"


static func _is_valid_id(value: String) -> bool:
	if _id_regex == null:
		_id_regex = RegEx.create_from_string(ContentSchemas.ID_PATTERN)
	return _id_regex.search(value) != null


static func _join(path: String, field: String) -> String:
	return field if path.is_empty() else "%s.%s" % [path, field]


static func _strip_root(message: String) -> String:
	return message.trim_prefix(": ").replace(" : ", " ")


static func _describe(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_STRING:
			return "text \"%s\"" % value
		TYPE_DICTIONARY:
			return "an object"
		TYPE_ARRAY:
			return "an array"
		_:
			return "%s (%s)" % [str(value), type_string(typeof(value))]
