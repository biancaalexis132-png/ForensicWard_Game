class_name ProtagonistValidator
extends RefCounted
## Pure, strict validation of P1 catalogs and creation drafts. Inputs are never
## normalized or changed. Reports use {errors: Array[String], warnings: Array[String]}.
## No files, assets, autoload state, events, RNG or clinical systems are accessed.

static func validate_catalog(catalog: Variant) -> Dictionary:
	var errors: Array[String] = _shape_errors(catalog, ProtagonistSchemas.CATALOG, "catalog")
	if not errors.is_empty():
		return _report(errors)
	_check_version(catalog["catalog_version"], "catalog.catalog_version", errors)
	var seen: Dictionary = {}
	for group: String in ProtagonistSchemas.GROUPS["required"]:
		var options: Array = catalog["groups"][group]
		for i: int in options.size():
			var option: Dictionary = options[i]
			var path: String = "catalog.groups.%s[%d]" % [group, i]
			var id: String = option["id"]
			if not id.begins_with(ProtagonistSchemas.OPTION_PREFIX) or id.length() <= ProtagonistSchemas.OPTION_PREFIX.length():
				errors.append("%s.id: must start with '%s' and have a nonempty suffix." % [path, ProtagonistSchemas.OPTION_PREFIX])
			if seen.has(id):
				errors.append("%s.id: duplicate option id '%s' (first at %s)." % [path, id, seen[id]])
			else:
				seen[id] = path
			if group == "pronouns":
				_check_forms(option["forms"], path + ".forms", false, errors)
	return _report(errors)


static func validate_profile(profile: Variant, catalog: Variant) -> Dictionary:
	var errors: Array[String] = []
	errors.append_array(validate_catalog(catalog)["errors"])
	errors.append_array(_shape_errors(profile, ProtagonistSchemas.PROFILE, "profile"))
	# Reference checks only run on structurally valid inputs and a valid catalog.
	if not errors.is_empty():
		return _report(errors)
	_check_version(profile["profile_version"], "profile.profile_version", errors)
	_check_text(profile["identity"]["name"], "profile.identity.name", ProtagonistSchemas.NAME_MAX_CHARS, errors)
	if profile["creation_state"] == "configured" and profile["identity"]["name"].is_empty():
		errors.append("profile.identity.name: a configured draft needs a name.")
	var groups: Dictionary = catalog["groups"]
	_check_pronouns(profile["identity"]["pronouns"], groups["pronouns"], errors)
	for field: String in ProtagonistSchemas.APPEARANCE_GROUPS:
		_check_selection(profile["appearance"][field], groups[ProtagonistSchemas.APPEARANCE_GROUPS[field]],
				"profile.appearance." + field, errors)
	_check_selections(profile["appearance"]["accessory_ids"], groups["accessories"],
			"profile.appearance.accessory_ids", errors)
	for field: String in ProtagonistSchemas.BACKGROUND_GROUPS:
		var value: Variant = profile["background"][field]
		var options: Array = groups[ProtagonistSchemas.BACKGROUND_GROUPS[field]]
		var path: String = "profile.background." + field
		if value is Array:
			_check_selections(value, options, path, errors)
		else:
			_check_selection(value, options, path, errors)
	_check_limit(profile["background"]["formative_experience_ids"], ProtagonistSchemas.FORMATIVE_MAX_ITEMS,
			"profile.background.formative_experience_ids", errors)
	_check_limit(profile["background"]["relationship_ids"], ProtagonistSchemas.RELATIONSHIP_MAX_ITEMS,
			"profile.background.relationship_ids", errors)
	return _report(errors)


static func _shape_errors(value: Variant, schema: Dictionary, path: String) -> Array[String]:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	ContentValidator.validate_value(value, schema, path, errors, warnings)
	# P1 is a closed input contract: unknown behavior/canon fields must not be
	# silently accepted. This does not change the shared validator's policy.
	for warning: String in warnings:
		errors.append(warning.replace("(ignored)", "(not allowed in P1)"))
	return errors


static func _check_version(value: Variant, path: String, errors: Array[String]) -> void:
	# JSON numbers may be floats; exact comparison also rejects near-integers
	# that the general content schema's tolerant integer check could accept.
	if value != ProtagonistSchemas.VERSION:
		errors.append("%s: only version %d is supported." % [path, ProtagonistSchemas.VERSION])


static func _check_pronouns(pronouns: Dictionary, options: Array, errors: Array[String]) -> void:
	var path: String = "profile.identity.pronouns"
	_check_forms(pronouns, path, true, errors)
	var id: String = pronouns["preset_id"]
	_check_selection(id, options, path + ".preset_id", errors)
	if id.is_empty():
		return  # All-empty is unspecified; complete forms without an id are custom.
	for option: Dictionary in options:
		if option["id"] == id:
			for form: String in ProtagonistSchemas.PRONOUN_FORMS["required"]:
				if pronouns[form] != option["forms"][form]:
					errors.append("%s.%s: does not match preset '%s'." % [path, form, id])


static func _check_forms(forms: Dictionary, path: String, allow_unspecified: bool, errors: Array[String]) -> void:
	var filled: int = 0
	for form: String in ProtagonistSchemas.PRONOUN_FORMS["required"]:
		_check_text(forms[form], path + "." + form, ProtagonistSchemas.PRONOUN_MAX_CHARS, errors)
		if not forms[form].is_empty():
			filled += 1
	if filled != 3 and not (allow_unspecified and filled == 0):
		errors.append("%s: pronoun forms must be complete%s." % [path, " or all empty" if allow_unspecified else ""])


static func _check_text(value: String, path: String, max_chars: int, errors: Array[String]) -> void:
	if value.length() > max_chars:
		errors.append("%s: must be at most %d Unicode characters." % [path, max_chars])
	if value != value.strip_edges():
		errors.append("%s: must not have leading or trailing whitespace." % path)
	for i: int in value.length():
		var code: int = value.unicode_at(i)
		if code < 32 or (code >= 127 and code <= 159):
			errors.append("%s: control characters are not allowed." % path)
			break


static func _check_selection(id: String, options: Array, path: String, errors: Array[String]) -> void:
	if id.is_empty():
		return  # Optional omissions never require a background or appearance choice.
	for option: Dictionary in options:
		if option["id"] == id:
			return
	errors.append("%s: unknown option id '%s' for this group." % [path, id])


static func _check_selections(ids: Array, options: Array, path: String, errors: Array[String]) -> void:
	var seen: Dictionary = {}
	for i: int in ids.size():
		var id: String = ids[i]
		var at: String = "%s[%d]" % [path, i]
		_check_selection(id, options, at, errors)
		if seen.has(id):
			errors.append("%s: duplicate selected option '%s'." % [at, id])
		seen[id] = true


static func _check_limit(values: Array, limit: int, path: String, errors: Array[String]) -> void:
	if values.size() > limit:
		errors.append("%s: at most %d selections are supported." % [path, limit])


static func _report(errors: Array[String]) -> Dictionary:
	return {"errors": errors, "warnings": [] as Array[String]}
