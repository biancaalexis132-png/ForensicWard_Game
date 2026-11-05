extends TestCase
## EHR order catalog: data-driven orders with patient identification,
## indication, prerequisites, confirmation, status, feedback and audit
## history; unavailable orders listed apart with their reason; placing is
## idempotent across save and load; nothing simulates a result.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const ELIAS: String = "pt_elias_ward"
const ASSESSMENT: String = "ord_catatonia_assessment"
const REVIEW: String = "ord_medical_team_review"

var _main: Node3D = null


func before_each() -> void:
	super.before_each()
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)


func after_each() -> void:
	super.after_each()
	if is_instance_valid(_main):
		_main.free()


func test_catalog_loads_and_wraps_existing_actions() -> void:
	var orders: Array[Dictionary] = ContentRegistry.get_orders(ELIAS)
	check_eq(orders.map(func(o: Dictionary) -> String: return o["id"]), [ASSESSMENT, REVIEW], "Elias's orders in authored order")
	for order: Dictionary in orders:
		check(not ContentRegistry.get_action(order["action_id"]).is_empty(), "order wraps a real action: " + order["id"])
	check(ContentRegistry.get_orders("pt_mara_ellis").is_empty(), "orders apply only to their action's patient")
	check_eq(ContentRegistry.get_unavailable_orders().size(), 2, "medication and laboratory listed as unavailable")


func test_catalog_validation_rejects_bad_references() -> void:
	var problems: Array[String] = []
	var docs: Dictionary = ContentRegistry.collect_documents(ContentRegistry.DATA_DIR, problems)
	var orders: Array = docs["order_catalog"]["data"]["orders"]
	orders[0]["action_id"] = "prescribe_something"
	orders[1]["prerequisites"] = {"observations": ["obs_not_real"], "explanation": "x"}
	orders.append(orders[1].duplicate(true))
	docs["order_catalog"]["data"]["unavailable"][0]["id"] = "medication"
	var errors: Array = ContentValidator.validate_documents(docs)["errors"]
	check_contains(errors, "unknown clinical action id 'prescribe_something'", "unknown action")
	check_contains(errors, "unknown observation of pt_elias_ward id 'obs_not_real'", "unknown prerequisite finding")
	check_contains(errors, "one order per action", "an action is ordered once")
	check_contains(errors, "must start with 'ord_'", "order id prefix")


func test_orders_tab_shows_patient_findings_and_unavailable_reasons() -> void:
	_open_orders()
	var text: String = _ehr().get_tab_text("Orders")
	check("Patient: Elias Ward" in text, "patient identification")
	check("Findings you have witnessed: none yet" in text, "witnessed findings")
	check("Structured assessment: not started" in text, "assessment status")
	check("Findings needed" in text, "assessment shows its missing findings")
	check("Not available in this build" in text, "unavailable section")
	check("No medication logic has clinical approval" in text, "medication reason shown")
	check(not "awaiting clinical review" in text, "no review labels for approved orders")


func test_place_requires_confirmation_and_cancel_changes_nothing() -> void:
	_open_orders()
	var minutes: int = TimeManager.total_minutes
	_ehr().select_order(REVIEW)
	check(_find("Place_" + REVIEW) != null, "details offer Place")
	_ehr().request_place(REVIEW)
	check(_find("Confirm_" + REVIEW) != null, "confirmation shown")
	check(PatientManager.get_state(ELIAS)["audit"].filter(_is_action).is_empty(), "nothing placed before confirming")
	_ehr().cancel_order()
	check(_find("Confirm_" + REVIEW) == null, "cancel hides the confirmation")
	check_eq(TimeManager.total_minutes, minutes, "cancel costs no time")
	check(_ehr().confirm_order().is_empty(), "confirm without a pending request does nothing")


func test_placing_review_logs_once_and_shows_awaiting() -> void:
	_open_orders()
	var toasts: Array[String] = []
	var listener: Callable = func(text: String) -> void: toasts.append(text)
	EventBus.notification_requested.connect(listener)
	var minutes: int = TimeManager.total_minutes
	_ehr().select_order(REVIEW)
	_ehr().request_place(REVIEW)
	var result: Dictionary = _ehr().confirm_order()
	EventBus.notification_requested.disconnect(listener)
	check_eq(result["rule_ids"], ["clinical_rule_medical_review_request_v1"], "approved rule applied")
	check_eq(TimeManager.total_minutes - minutes, 5, "the order's time passed once")
	check(toasts.any(func(t: String) -> bool: return "Awaiting the medical team" in t), "feedback toast")
	var status: Dictionary = ClinicalOrders.status(ELIAS, ContentRegistry.get_order(REVIEW))
	check_eq(status["state"], ClinicalOrders.AWAITING_RESPONSE, "shown as awaiting a response")
	check(not status["can_place"], "cannot be placed twice the same day")
	_ehr().request_place(REVIEW)
	check(_ehr().confirm_order().is_empty(), "a second confirm does nothing")
	check_eq(ClinicalOrders.history(ELIAS, ContentRegistry.get_order(REVIEW)).size(), 1, "one audit record")
	check_eq(PatientManager.get_state(ELIAS)["assessment"].keys(), ["medical_review_requested"], "no simulated result")


func test_assessment_status_follows_recorded_findings() -> void:
	var order: Dictionary = ContentRegistry.get_order(ASSESSMENT)
	check_eq(ClinicalOrders.status(ELIAS, order)["state"], ClinicalOrders.NEEDS_PREREQUISITES, "needs findings")
	check(ClinicalOrders.status(ELIAS, order)["can_place"], "still placeable; the request is logged without effect")
	PatientManager.record_observation(ELIAS, "obs_mutism", "test")
	PatientManager.record_observation(ELIAS, "obs_posturing", "test")
	check_eq(ClinicalOrders.status(ELIAS, order)["state"], ClinicalOrders.AVAILABLE, "available once both are recorded")
	_open_orders()
	_ehr().request_place(ASSESSMENT)
	check(not "will be logged without effect" in _ehr().get_tab_text("Orders"), "no missing-findings warning")
	_ehr().confirm_order()
	check(PatientManager.get_state(ELIAS)["assessment"].get("started", false), "assessment started")
	check_eq(ClinicalOrders.status(ELIAS, order)["state"], ClinicalOrders.COMPLETED, "completed today")
	check(_find("Place_" + ASSESSMENT) == null, "no Place button once completed")
	_ehr().select_order("")
	check(_ehr().get_action_button("evaluate_catatonia").disabled, "row button locked once completed")


func test_status_survives_save_and_load_without_replaying() -> void:
	_open_orders()
	_ehr().request_place(REVIEW)
	_ehr().confirm_order()
	check_eq(SaveManager.save_game(TEST_SAVE_SLOT), OK, "save")
	SaveManager.reset_all()
	check_eq(ClinicalOrders.status(ELIAS, ContentRegistry.get_order(REVIEW))["state"], ClinicalOrders.AVAILABLE, "reset clears it")
	check_eq(SaveManager.load_game(TEST_SAVE_SLOT), OK, "load")
	var status: Dictionary = ClinicalOrders.status(ELIAS, ContentRegistry.get_order(REVIEW))
	check_eq(status["state"], ClinicalOrders.AWAITING_RESPONSE, "status restored")
	check(not status["can_place"], "still cannot be placed again the same day")
	check_eq(ClinicalOrders.history(ELIAS, ContentRegistry.get_order(REVIEW)).size(), 1, "no duplicate audit after load")


# --- Helpers ------------------------------------------------------------------------

func _open_orders() -> void:
	EventBus.ui_panel_requested.emit("ehr", {"patient_id": ELIAS})
	_ehr().show_tab("Orders")


func _find(node_name: String) -> Node:
	return _ehr().find_child(node_name, true, false)


static func _is_action(entry: Dictionary) -> bool:
	return entry["type"] == "clinical_action"


func _ehr() -> EHRScreen:
	return _main.get_node("EHRScreen")
