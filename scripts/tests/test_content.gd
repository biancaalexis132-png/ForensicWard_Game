extends TestCase
## JSON loading and validation: shipped fixtures pass, and broken content
## produces actionable errors naming the file and JSON path.


func test_shipped_content_is_valid() -> void:
	check(ContentRegistry.is_valid, "res://data should validate. Errors: %s" % str(ContentRegistry.errors))
	check_eq(ContentRegistry.get_patient_ids(), ["pt_elias_ward"] as Array[String], "patient ids")
	check_eq(ContentRegistry.get_clue_ids().size(), 3, "clue count")
	check(not ContentRegistry.get_dialogue("pt_elias_ward").is_empty(), "Elias has dialogue")


func test_content_is_read_only() -> void:
	check(ContentRegistry.get_patient("pt_elias_ward").is_read_only(), "patient definitions are frozen")
	check(ContentRegistry.get_clue("clue_roster").is_read_only(), "clue definitions are frozen")


func test_missing_required_field() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["patients"]["data"]["patients"][0].erase("name")
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "[patients.json] patients[0]: missing required field 'name'", "missing field")


func test_wrong_type_is_reported() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["patients"]["data"]["patients"][0]["age"] = "twenty-nine"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "patients[0].age: expected a whole number", "type error")


func test_patients_must_be_fictional() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["patients"]["data"]["patients"][0]["fictional"] = false
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "patients[0].fictional: must be true", "fictional guard")


func test_unknown_clue_reference() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["clues"]["data"]["hypotheses"][0]["required_clues"][1] = "clue_rostr"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "hypotheses[0].required_clues[1]: unknown clue id 'clue_rostr'", "dangling clue")


func test_duplicate_ids() -> void:
	var docs: Dictionary = _fixture_documents()
	var clues: Array = docs["clues"]["data"]["clues"]
	clues.append(clues[0].duplicate(true))
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "duplicate id 'clue_transfer'", "duplicate id")


func test_dangling_dialogue_state() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["dialogue"]["data"]["states"][0]["choices"][0]["next"] = "nowhere"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "next: unknown dialogue state id 'nowhere'", "dangling state")


func test_rule_references_unknown_observation() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["clinical_rules"]["data"]["rules"][0]["condition"]["observations_present"][0] = "obs_unknown"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "unknown observation of pt_elias_ward id 'obs_unknown'", "rule observation")


func test_dialogue_records_unknown_observation() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["dialogue"]["data"]["states"][0]["choices"][0]["records_observations"] = ["obs_mutsm"]
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "records_observations[0]: unknown observation of pt_elias_ward id 'obs_mutsm'",
			"dangling interview observation")


func test_rule_trigger_must_be_an_authored_action() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["clinical_rules"]["data"]["rules"][0]["trigger_action"] = "evaluate_catatona"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "rules[0].trigger_action: unknown clinical action id 'evaluate_catatona'",
			"rule without an action")


func test_actions_are_listed_per_patient() -> void:
	var labels: Array = ContentRegistry.get_actions("pt_elias_ward").map(func(a: Dictionary) -> String: return a["id"])
	check_eq(labels, ["evaluate_catatonia", "request_medical_review"], "authored order")


func test_bad_id_format() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["clues"]["data"]["clues"][0]["id"] = "Clue Transfer"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check_contains(report["errors"], "id 'Clue Transfer' must use lowercase", "id format")


func test_invalid_json_reports_file_and_line() -> void:
	var directory: String = "user://test_content"
	DirAccess.make_dir_recursive_absolute(directory)
	for key: String in ContentRegistry.MANIFEST:
		var file_name: String = ContentRegistry.MANIFEST[key][0]
		var text: String = FileAccess.get_file_as_string("res://data/" + file_name)
		if file_name == "clues.json":
			text = text.replace("\"clues\": [", "\"clues\": [,") # Syntax error.
		var file: FileAccess = FileAccess.open("%s/%s" % [directory, file_name], FileAccess.WRITE)
		file.store_string(text)
		file.close()
	var registry: Node = load("res://scripts/autoload/ContentRegistry.gd").new()
	registry.log_problems = false
	var ok: bool = registry.load_all(directory)
	check(not ok, "broken JSON fails validation")
	check_contains(registry.errors, "[clues.json] line", "parse error names file and line")
	registry.free()
	for file_name: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute("%s/%s" % [directory, file_name])


func test_unknown_field_is_warning_not_error() -> void:
	var docs: Dictionary = _fixture_documents()
	docs["clues"]["data"]["clues"][0]["colour"] = "red"
	var report: Dictionary = ContentValidator.validate_documents(docs)
	check(report["errors"].is_empty(), "unknown field should not be an error: %s" % str(report["errors"]))
	check_contains(report["warnings"], "unknown field 'colour'", "unknown field warning")


## Fresh, mutable copies of every shipped data file.
func _fixture_documents() -> Dictionary:
	var docs: Dictionary = {}
	for key: String in ContentRegistry.MANIFEST:
		var file_name: String = ContentRegistry.MANIFEST[key][0]
		docs[key] = {
			"file": file_name,
			"data": JSON.parse_string(FileAccess.get_file_as_string("res://data/" + file_name)),
			"schema": ContentRegistry.MANIFEST[key][1],
		}
	return docs
