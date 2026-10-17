extends TestCase
## Dialogue state machine and bounded free-text intent matching
## (MVP acceptance test 3).

const PATIENT: String = "pt_elias_ward"


func test_is_he_eating_maps_to_nutrition_topic() -> void:
	var result: Dictionary = DialogueManager.classify(PATIENT, "Is he eating?")
	check_eq(result["status"], "matched", "status")
	check_eq(result["choice_id"], "ask_intake", "choice")


func test_paraphrases_match() -> void:
	check_eq(DialogueManager.classify(PATIENT, "Has he had anything to drink today?")["choice_id"], "ask_intake", "fluids")
	check_eq(DialogueManager.classify(PATIENT, "What about his appetite")["choice_id"], "ask_intake", "appetite")
	check_eq(DialogueManager.classify(PATIENT, "Tell me about Ward Zero")["choice_id"], "ask_ward_zero", "ward zero")
	check_eq(DialogueManager.classify(PATIENT, "Examine his posturing")["choice_id"], "assess_motor", "motor exam")


func test_unsupported_input_falls_back_politely() -> void:
	DialogueManager.start_dialogue(PATIENT)
	var result: Dictionary = DialogueManager.submit_free_text("What's your favourite colour?")
	check_eq(result["status"], "fallback", "status")
	check_eq(result["response"], ContentRegistry.get_dialogue(PATIENT)["fallback_response"], "authored fallback text")
	check_eq(DialogueManager.get_choices().size(), 3, "state unchanged after fallback")


func test_empty_and_stopword_input_falls_back() -> void:
	check_eq(DialogueManager.classify(PATIENT, "")["status"], "fallback", "empty")
	check_eq(DialogueManager.classify(PATIENT, "is he?")["status"], "fallback", "stopwords only")


func test_choice_moves_state_and_records_transcript() -> void:
	DialogueManager.start_dialogue(PATIENT)
	var response: String = DialogueManager.select_choice("assess_motor")
	check(not response.is_empty(), "authored response returned")
	var choice_ids: Array = DialogueManager.get_choices().map(func(c: Dictionary) -> String: return c["id"])
	check_eq(choice_ids, ["return_to_general"], "now in assessment state")
	var transcript: Array = DialogueManager.get_transcript(PATIENT)
	check_eq(transcript.size(), 2, "physician line + response")
	check_eq(transcript[0]["speaker"], "physician", "first speaker")


func test_matching_is_deterministic() -> void:
	var first: Dictionary = DialogueManager.classify(PATIENT, "is he eating and drinking")
	for _i: int in 5:
		check_eq(DialogueManager.classify(PATIENT, "is he eating and drinking"), first, "same input, same result")


func test_transcript_survives_save_and_load() -> void:
	DialogueManager.start_dialogue(PATIENT)
	DialogueManager.submit_free_text("Is he eating?")
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check_eq(DialogueManager.get_transcript(PATIENT).size(), 0, "reset clears transcript")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	check_eq(DialogueManager.get_transcript(PATIENT).size(), 2, "transcript restored")
