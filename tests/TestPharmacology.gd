extends Node
## Scenario tests for PharmacologyEngine, built from the Day 6 lecture cases.
##
## Run in the editor: open tests/TestPharmacology.tscn and press F6 (Mac: Cmd + R).
## Run headless:      godot --headless --path . res://tests/TestPharmacology.tscn
## Results print to the Output panel. Headless runs exit with code 1 on failure;
## editor runs keep the window open with a PASSED / FAILED banner.

var _failures: int = 0


func _ready() -> void:
	_test_clozapine_smoking_cessation()
	_test_aripiprazole_fluoxetine()
	_test_lithium_nsaid_renal()
	_test_carbamazepine_autoinduction_and_quetiapine()
	_test_qtc_stacking()
	_test_serotonin_toxicity()
	_test_washout_after_stop()
	_test_preview_order_text()
	var summary: String = "%s: %d failure(s)" % ["PASSED" if _failures == 0 else "FAILED", _failures]
	print("\n" + summary)
	if DisplayServer.get_name() == "headless":
		get_tree().quit(1 if _failures > 0 else 0)
	else:
		# In the editor, quitting immediately cuts off the last Output lines,
		# so keep the window open and show the result instead.
		_show_summary(summary)


func _show_summary(summary: String) -> void:
	var label: Label = Label.new()
	label.text = summary + "\nSee the Output panel for details. Close this window to finish."
	label.position = Vector2(24.0, 24.0)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.LIME_GREEN if _failures == 0 else Color.RED)
	add_child(label)


func _test_clozapine_smoking_cessation() -> void:
	print("\n[Case] Clozapine + smoke-free admission (CYP1A2 de-induction)")
	var pid: String = _admit("res://data/patients/PT-001.json")
	var day0: float = PharmacologyEngine.get_state(pid)["levels"]["clozapine"]
	_advance_days(7.0)
	var state: Dictionary = PharmacologyEngine.get_state(pid)
	var day7: float = state["levels"]["clozapine"]
	print("  clozapine level day 0 = %.0f ng/mL, day 7 = %.0f ng/mL (+%d%%), sedation %.2f"
			% [day0, day7, roundi((day7 / day0 - 1.0) * 100.0), state["sedation"]])
	_check(day0 >= 300.0 and day0 <= 450.0, "smoker on 400 mg starts near the therapeutic range")
	_check(day7 / day0 > 1.4, "level rises > 40% after smoking stops")
	_check(_has_alert(state, "SEDATION"), "sedation alert raised")
	_check(not GameState.is_clue_unlocked("pt001_trial_memory"), "clue stays locked while over-sedated")

	PharmacologyEngine.order_medication(pid, "clozapine", 300.0)
	_advance_days(4.0)
	state = PharmacologyEngine.get_state(pid)
	print("  after dose cut to 300 mg: level %.0f ng/mL, sedation %.2f, psychosis %.2f"
			% [state["levels"]["clozapine"], state["sedation"], state["symptoms"]["psychosis"]])
	_check(GameState.is_clue_unlocked("pt001_trial_memory"), "correct dose adjustment unlocks the clue")


func _test_aripiprazole_fluoxetine() -> void:
	print("\n[Case] Aripiprazole + fluoxetine (CYP2D6 phenoconversion)")
	var pid: String = _admit("res://data/patients/PT-002.json", "PT-002-A")
	var before: float = PharmacologyEngine.get_state(pid)["exposures"]["aripiprazole"]
	var report: Dictionary = PharmacologyEngine.order_medication(pid, "fluoxetine", 20.0)
	for interaction: Dictionary in report["interactions"]:
		print("  EHR: " + interaction["text"])
	_advance_days(3.0)
	var day3: float = PharmacologyEngine.get_state(pid)["exposures"]["aripiprazole"]
	_advance_days(25.0)
	var state: Dictionary = PharmacologyEngine.get_state(pid)
	var day28: float = state["exposures"]["aripiprazole"]
	print("  aripiprazole E: before %.2f, day 3 %.2f, day 28 %.2f; akathisia %.2f; CYP2D6 activity %.2f"
			% [before, day3, day28, state["akathisia"], state["pathway_activity"]["CYP2D6"]])
	_check(day28 / before > 1.5 and day28 / before < 2.2, "aripiprazole exposure ~1.7x at steady state")
	_check(day3 < day28, "interaction builds slowly (fluoxetine's long half-life)")
	_check(_has_alert(state, "AKATHISIA"), "akathisia alert raised")


func _test_lithium_nsaid_renal() -> void:
	print("\n[Case] Lithium + NSAID + reduced eGFR")
	var pid: String = _admit_inline({"id": "LI-1", "egfr": 100,
			"home_medications": [{"drug_id": "lithium", "daily_dose_mg": 900}]})
	var start: float = PharmacologyEngine.get_state(pid)["levels"]["lithium"]
	PharmacologyEngine.order_medication(pid, "ibuprofen", 1200.0)
	PharmacologyEngine.set_egfr(pid, 55.0) # Dehydration / AKI.
	_advance_days(5.0)
	var state: Dictionary = PharmacologyEngine.get_state(pid)
	var level: Dictionary = PharmacologyEngine.measure_drug_level(pid, "lithium")
	print("  lithium %.2f -> %.2f mmol/L (%s)" % [start, level["level"], level["flag"]])
	_check(is_equal_approx(start, 0.8), "900 mg gives 0.8 mmol/L at baseline")
	_check(level["flag"] == "critical", "NSAID + low eGFR pushes lithium into the toxic range")
	_check(_has_alert(state, "LEVEL_LITHIUM"), "lithium level alert raised")


func _test_carbamazepine_autoinduction_and_quetiapine() -> void:
	print("\n[Case] Carbamazepine autoinduction, then quetiapine induction")
	var pid: String = _admit_inline({"id": "CBZ-1"})
	PharmacologyEngine.order_medication(pid, "carbamazepine", 800.0)
	_advance_days(4.0)
	var week1: float = PharmacologyEngine.measure_drug_level(pid, "carbamazepine")["level"]
	_advance_days(24.0)
	var week4: float = PharmacologyEngine.measure_drug_level(pid, "carbamazepine")["level"]
	print("  carbamazepine 800 mg/day: day 4 = %.1f mg/L, day 28 = %.1f mg/L" % [week1, week4])
	_check(week4 < week1 * 0.85, "level falls despite unchanged dose (autoinduction)")
	_check(week4 >= 4.0 and week4 <= 12.0, "autoinduced level sits in the 4-12 mg/L range")

	var report: Dictionary = PharmacologyEngine.preview_order(pid, "quetiapine", 600.0)
	print("  quetiapine 600 mg predicted E = %.2f" % report["predicted_exposure"])
	_check(report["predicted_exposure"] < 0.35, "quetiapine exposure cut by > 65% under strong induction")


func _test_qtc_stacking() -> void:
	print("\n[Case] QTc: citalopram + quetiapine + clarithromycin, CYP2C19 PM, low K+")
	var pid: String = _admit_inline({"id": "QT-1", "sex": "F", "baseline_qtc_ms": 445, "potassium_mmol_l": 3.3,
			"phenotypes": {"CYP2C19": "PM"},
			"home_medications": [{"drug_id": "citalopram", "daily_dose_mg": 40}, {"drug_id": "quetiapine", "daily_dose_mg": 600}]})
	var report: Dictionary = PharmacologyEngine.order_medication(pid, "clarithromycin", 1000.0)
	for note: String in report["pharmacodynamic"]:
		print("  EHR: " + note)
	_advance_days(2.0)
	var state: Dictionary = PharmacologyEngine.get_state(pid)
	print("  QTc %d ms" % state["qtc_ms"])
	_check(_alert_severity(state, "QTC") == "critical", "stacked QTc risk becomes critical")


func _test_serotonin_toxicity() -> void:
	print("\n[Case] Sertraline + linezolid")
	var pid: String = _admit_inline({"id": "SS-1",
			"home_medications": [{"drug_id": "sertraline", "daily_dose_mg": 100}]})
	PharmacologyEngine.order_medication(pid, "linezolid", 1200.0)
	_advance_days(1.0)
	_check(_has_alert(PharmacologyEngine.get_state(pid), "SEROTONIN_TOXICITY"), "serotonin toxicity alert raised")


func _test_washout_after_stop() -> void:
	print("\n[Case] Stopping fluoxetine: inhibition persists for weeks")
	var pid: String = PharmacologyEngine.get_patient_ids().filter(func(id: String) -> bool: return id == "PT-002-A")[0]
	PharmacologyEngine.discontinue_medication(pid, "fluoxetine")
	_advance_days(7.0)
	var week1: float = PharmacologyEngine.get_state(pid)["pathway_activity"]["CYP2D6"]
	_advance_days(35.0)
	var week6: float = PharmacologyEngine.get_state(pid)["pathway_activity"]["CYP2D6"]
	print("  CYP2D6 activity 1 week after stop = %.2f, 6 weeks = %.2f" % [week1, week6])
	_check(week1 < 0.5, "still strongly inhibited one week after stopping")
	_check(week6 > 0.8, "recovers after ~5 half-lives")


func _test_preview_order_text() -> void:
	print("\n[Case] EHR preview: fluvoxamine added to clozapine")
	var pid: String = _admit_inline({"id": "PV-1",
			"home_medications": [{"drug_id": "clozapine", "daily_dose_mg": 300}]})
	var report: Dictionary = PharmacologyEngine.preview_order(pid, "fluvoxamine", 100.0)
	for interaction: Dictionary in report["interactions"]:
		print("  EHR: " + interaction["text"])
	_check(report["interactions"].size() == 1 and report["interactions"][0]["fold_change"] > 2.0,
			"warns that clozapine exposure will more than double")


# --- helpers -------------------------------------------------------------

## Advances shift by shift, exactly like the game, so clue gates and alerts
## are evaluated at every shift boundary.
func _advance_days(days: float) -> void:
	for _shift: int in roundi(days * 24.0 / PharmacologyEngine.SHIFT_HOURS):
		PharmacologyEngine.advance_hours(PharmacologyEngine.SHIFT_HOURS)

func _admit(path: String, override_id: String = "") -> String:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not override_id.is_empty():
		data["id"] = override_id
	return PharmacologyEngine.admit_patient(data)


func _admit_inline(data: Dictionary) -> String:
	return PharmacologyEngine.admit_patient(data)


func _has_alert(state: Dictionary, alert_id: String) -> bool:
	return not _alert_severity(state, alert_id).is_empty()


func _alert_severity(state: Dictionary, alert_id: String) -> String:
	for alert: Dictionary in state["alerts"]:
		if alert["id"] == alert_id:
			return alert["severity"]
	return ""


func _check(condition: bool, label: String) -> void:
	print("  %s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		_failures += 1
