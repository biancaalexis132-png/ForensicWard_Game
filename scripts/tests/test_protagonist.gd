extends TestCase
## P1: synthetic creation drafts only; no authored protagonist choices ship.

const FIXTURES: String = "res://scripts/tests/fixtures/protagonist/"


func test_empty_optional_selections_are_valid_with_no_available_options() -> void:
	var catalog: Dictionary = _catalog()
	for group: String in catalog["groups"]:
		catalog["groups"][group] = []
	check(ProtagonistValidator.validate_catalog(catalog)["errors"].is_empty(), "empty groups are supported")
	check(ProtagonistValidator.validate_profile(_profile(), catalog)["errors"].is_empty(), "unspecified identity and skipped backgrounds are valid")


func test_configured_unicode_identity_and_independent_appearance_selections() -> void:
	var profile: Dictionary = _profile()
	profile["creation_state"] = "configured"
	profile["identity"]["name"] = "Zoë 李 🩺"
	profile["identity"]["pronouns"] = {"preset_id": "popt_fixture_pronouns", "subject": "they", "object": "them", "possessive": "their"}
	for field: String in ProtagonistSchemas.APPEARANCE_GROUPS:
		profile["appearance"][field] = "popt_fixture_" + ProtagonistSchemas.APPEARANCE_GROUPS[field]
	profile["appearance"]["accessory_ids"] = ["popt_fixture_accessories"]
	# No background, relationships, trauma or personality selection is required.
	check(ProtagonistValidator.validate_profile(profile, _catalog())["errors"].is_empty(), "Unicode name, all appearance choices and skipped background coexist")


func test_optional_backgrounds_do_not_change_professional_role_or_require_personal_history() -> void:
	var profile: Dictionary = _profile()
	profile["creation_state"] = "configured"
	profile["identity"]["name"] = "Synthetic Doctor"
	profile["background"]["professional_interest_id"] = "popt_fixture_professional_interests"
	check(ProtagonistValidator.validate_profile(profile, _catalog())["errors"].is_empty(), "professional interest requires no personal history")
	for field: String in ProtagonistSchemas.BACKGROUND_GROUPS:
		var id: String = "popt_fixture_" + ProtagonistSchemas.BACKGROUND_GROUPS[field]
		if profile["background"][field] is Array:
			profile["background"][field] = [id]
		else:
			profile["background"][field] = id
	check(ProtagonistValidator.validate_profile(profile, _catalog())["errors"].is_empty(), "all optional categories may coexist")
	check_eq(profile["identity"]["professional_role"], "psychiatrist", "professional role stays fixed")


func test_custom_pronouns_and_literal_text_are_not_normalized() -> void:
	var profile: Dictionary = _profile()
	profile["identity"]["name"] = "[b]Literal[/b]"
	profile["identity"]["pronouns"] = {"preset_id": "", "subject": "iel", "object": "iel", "possessive": "ses"}
	var before: String = JSON.stringify(profile)
	check(ProtagonistValidator.validate_profile(profile, _catalog())["errors"].is_empty(), "custom complete forms accepted")
	check_eq(JSON.stringify(profile), before, "validation never renders or rewrites user text")


func test_invalid_roles_and_unknown_behavior_fields_are_rejected() -> void:
	for role: Variant in ["psychologist", "security_director", "", null, 1]:
		var profile: Dictionary = _profile()
		profile["identity"]["professional_role"] = role
		_profile_error(profile, "profile.identity.professional_role", "fixed psychiatrist role")
	for field: String in ["personality_class", "clinical_effects", "mandatory_evidence"]:
		var profile: Dictionary = _profile()
		profile[field] = {}
		_profile_error(profile, "unknown field '%s'" % field, "unsupported behavior must not be silently accepted")
	var catalog: Dictionary = _catalog()
	catalog["groups"]["professional_interests"][0]["grant_access"] = "access_records_archive"
	check_contains(ProtagonistValidator.validate_catalog(catalog)["errors"], "unknown field 'grant_access'", "option metadata cannot grant access")


func test_unknown_and_wrong_group_option_ids_are_rejected() -> void:
	var profile: Dictionary = _profile()
	profile["appearance"]["skin_tone_id"] = "popt_fixture_hair_textures"
	_profile_error(profile, "profile.appearance.skin_tone_id: unknown option", "category-specific lookup")
	profile = _profile()
	profile["background"]["professional_interest_id"] = "popt_missing"
	_profile_error(profile, "profile.background.professional_interest_id: unknown option", "unknown professional background")
	profile = _profile()
	profile["background"]["relationship_ids"] = ["popt_missing"]
	_profile_error(profile, "profile.background.relationship_ids[0]: unknown option", "array reference path")
	profile = _profile()
	profile["appearance"]["outfit_id"] = "res://arbitrary.tscn"
	_profile_error(profile, "profile.appearance.outfit_id: unknown option", "paths cannot substitute for catalog ids")


func test_wrong_root_and_nested_types_return_reports_without_crashing() -> void:
	for bad: Variant in [null, [], true, 7, "profile"]:
		check(not ProtagonistValidator.validate_profile(bad, _catalog())["errors"].is_empty(), "bad profile root rejected")
		check(not ProtagonistValidator.validate_catalog(bad)["errors"].is_empty(), "bad catalog root rejected")
	for field: String in ["identity", "appearance", "background"]:
		var profile: Dictionary = _profile()
		profile[field] = []
		_profile_error(profile, "profile." + field + ": expected an object", "nested container type")
	var profile: Dictionary = _profile()
	profile["identity"]["pronouns"] = null
	_profile_error(profile, "profile.identity.pronouns: expected an object", "pronoun object type")
	profile = _profile()
	profile["appearance"]["accessory_ids"] = [false]
	_profile_error(profile, "profile.appearance.accessory_ids[0]: expected an id", "selection element type")
	var catalog: Dictionary = _catalog()
	catalog["groups"]["pronouns"][0]["forms"] = []
	check_contains(ProtagonistValidator.validate_catalog(catalog)["errors"], ".forms: expected an object", "bad catalog forms prevent reference checks")


func test_missing_fields_name_the_exact_path() -> void:
	for field: String in _profile():
		var profile: Dictionary = _profile()
		profile.erase(field)
		_profile_error(profile, "profile: missing required field '%s'" % field, "missing root field")
	var profile: Dictionary = _profile()
	profile["background"].erase("professional_interest_id")
	_profile_error(profile, "profile.background: missing required field 'professional_interest_id'", "missing nested field")
	var catalog: Dictionary = _catalog()
	catalog["groups"].erase("voices")
	check_contains(ProtagonistValidator.validate_catalog(catalog)["errors"], "catalog.groups: missing required field 'voices'", "catalog group contract")


func test_versions_are_exact_and_json_round_trips_are_supported() -> void:
	var profile: Dictionary = JSON.parse_string(JSON.stringify(_profile()))
	var catalog: Dictionary = JSON.parse_string(JSON.stringify(_catalog()))
	check(ProtagonistValidator.validate_profile(profile, catalog)["errors"].is_empty(), "JSON float representation of whole versions supported")
	for bad: Variant in [true, "1", 0, 2, 1.000001, INF, NAN]:
		profile = _profile()
		profile["profile_version"] = bad
		_profile_error(profile, "profile.profile_version", "invalid profile version")
		catalog = _catalog()
		catalog["catalog_version"] = bad
		check_contains(ProtagonistValidator.validate_catalog(catalog)["errors"], "catalog.catalog_version", "invalid catalog version")


func test_catalog_option_ids_are_prefixed_unique_and_valid() -> void:
	var catalog: Dictionary = _catalog()
	catalog["groups"]["voices"].append(catalog["groups"]["voices"][0].duplicate(true))
	check_contains(ProtagonistValidator.validate_catalog(catalog)["errors"], "catalog.groups.voices[1].id: duplicate option", "duplicate in one group")
	catalog = _catalog()
	catalog["groups"]["voices"][0]["id"] = "popt_fixture_skin_tones"
	check_contains(ProtagonistValidator.validate_catalog(catalog)["errors"], "duplicate option id 'popt_fixture_skin_tones'", "duplicate across groups")
	for bad: String in ["other_option", "popt_", "popt_bad/path", "POPT_UPPER"]:
		catalog = _catalog()
		catalog["groups"]["voices"][0]["id"] = bad
		check_contains(ProtagonistValidator.validate_catalog(catalog)["errors"], "catalog.groups.voices[0].id", "invalid id names path")


func test_repeated_selections_and_personal_history_limits() -> void:
	var profile: Dictionary = _profile()
	profile["appearance"]["accessory_ids"] = ["popt_fixture_accessories", "popt_fixture_accessories"]
	_profile_error(profile, "profile.appearance.accessory_ids[1]: duplicate selected", "duplicate accessory")
	var catalog: Dictionary = _catalog()
	profile = _profile()
	for i: int in 4:
		var id: String = "popt_fixture_experience_%d" % i
		catalog["groups"]["formative_experiences"].append({"id": id, "label": "Synthetic experience"})
		profile["background"]["formative_experience_ids"].append(id)
	check_contains(ProtagonistValidator.validate_profile(profile, catalog)["errors"], "at most 3 selections", "bounded formative details")
	profile["background"]["formative_experience_ids"].pop_back()
	check(ProtagonistValidator.validate_profile(profile, catalog)["errors"].is_empty(), "boundary accepted")
	for i: int in 3:
		var id: String = "popt_fixture_relationship_%d" % i
		catalog["groups"]["relationships"].append({"id": id, "label": "Synthetic relationship"})
		profile["background"]["relationship_ids"].append(id)
	check_contains(ProtagonistValidator.validate_profile(profile, catalog)["errors"], "at most 2 selections", "bounded optional relationships")


func test_pronoun_forms_are_complete_and_match_the_selected_preset() -> void:
	var profile: Dictionary = _profile()
	profile["identity"]["pronouns"]["subject"] = "they"
	_profile_error(profile, "pronoun forms must be complete or all empty", "partial custom forms rejected")
	profile["identity"]["pronouns"] = {"preset_id": "popt_fixture_pronouns", "subject": "she", "object": "her", "possessive": "her"}
	_profile_error(profile, "does not match preset", "preset cannot contradict its forms")
	var catalog: Dictionary = _catalog()
	catalog["groups"]["pronouns"][0]["forms"]["subject"] = ""
	check_contains(ProtagonistValidator.validate_catalog(catalog)["errors"], "catalog.groups.pronouns[0].forms: pronoun forms must be complete", "catalog presets need all forms")


func test_unicode_text_boundaries_and_single_line_contract() -> void:
	var profile: Dictionary = _profile()
	profile["creation_state"] = "configured"
	profile["identity"]["name"] = "李".repeat(64)
	check(ProtagonistValidator.validate_profile(profile, _catalog())["errors"].is_empty(), "limit uses Unicode characters, not bytes")
	profile["identity"]["name"] += "李"
	_profile_error(profile, "at most 64 Unicode characters", "name limit")
	for bad: String in [" Alice", "Alice ", "Alice\nSmith", "Alice\tSmith"]:
		profile["identity"]["name"] = bad
		_profile_error(profile, "profile.identity.name", "single-line trimmed input")
	profile["identity"]["name"] = ""
	_profile_error(profile, "a configured draft needs a name", "configured identity needs a name")
	profile = _profile()
	profile["identity"]["pronouns"] = {"preset_id": "", "subject": "a".repeat(32), "object": "b", "possessive": "c"}
	check(ProtagonistValidator.validate_profile(profile, _catalog())["errors"].is_empty(), "pronoun boundary accepted")
	profile["identity"]["pronouns"]["subject"] += "a"
	_profile_error(profile, "at most 32 Unicode characters", "pronoun limit")


func test_validation_is_repeatable_and_leaves_inputs_and_run_state_unchanged() -> void:
	var catalog: Dictionary = _catalog()
	var profile: Dictionary = _profile()
	var catalog_before: String = JSON.stringify(catalog)
	var profile_before: String = JSON.stringify(profile)
	var state_before: String = JSON.stringify(SaveManager.capture_state(), "", true)
	var seed_before: int = SaveManager.run_seed
	var first: Dictionary = ProtagonistValidator.validate_profile(profile, catalog)
	check_eq(ProtagonistValidator.validate_profile(profile, catalog), first, "repeatable report")
	profile["identity"]["professional_role"] = "invalid"
	var invalid_before: String = JSON.stringify(profile)
	ProtagonistValidator.validate_profile(profile, catalog)
	check_eq(JSON.stringify(profile), invalid_before, "invalid inputs not repaired")
	profile["identity"]["professional_role"] = "psychiatrist"
	check_eq(JSON.stringify(profile), profile_before, "valid input unchanged")
	check_eq(JSON.stringify(catalog), catalog_before, "catalog unchanged")
	check_eq(JSON.stringify(SaveManager.capture_state(), "", true), state_before, "no patient, clinical, evidence or other provider changes")
	check_eq(SaveManager.run_seed, seed_before, "seed unchanged")


func test_read_only_catalogs_and_profiles_are_supported() -> void:
	var catalog: Dictionary = _catalog()
	var profile: Dictionary = _profile()
	_freeze(catalog)
	_freeze(profile)
	check(ProtagonistValidator.validate_profile(profile, catalog)["errors"].is_empty(), "frozen inputs validate without writes")


func _catalog() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURES + "catalog_fixture.json"))


func _profile() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURES + "unconfigured_fixture.json"))


func _profile_error(profile: Variant, fragment: String, message: String) -> void:
	check_contains(ProtagonistValidator.validate_profile(profile, _catalog())["errors"], fragment, message)


func _freeze(value: Variant) -> void:
	if value is Dictionary:
		for child: Variant in value.values():
			_freeze(child)
		value.make_read_only()
	elif value is Array:
		for child: Variant in value:
			_freeze(child)
		value.make_read_only()
