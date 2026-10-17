extends Node3D
## Main — temporary boot scene and live PharmacologyEngine demo.
##
## Admits the sample patient PT-001 (a heavy smoker stable on clozapine,
## admitted to the smoke-free ward) and shows their clinical state.
## Controls:
##   N  end the shift (advance 12 hours)
##   R  reduce clozapine to 300 mg/day
##   O / P  drain / restore the player's objectivity
## This scene will be replaced by the ward level once FPSPlayer.gd exists.

const DEMO_PATIENT_PATH: String = "res://data/patients/PT-001.json"

@onready var _status_label: Label = $HUD/StatusLabel

var _patient_id: String = ""
var _log: Array[String] = []


func _ready() -> void:
	EventBus.objectivity_changed.connect(_on_objectivity_changed)
	EventBus.patient_state_updated.connect(_on_patient_state_updated)
	EventBus.clinical_alert_raised.connect(_on_clinical_alert_raised)
	EventBus.clue_unlocked.connect(_on_clue_unlocked)

	GameState.start_shift(1, "day")
	_patient_id = PharmacologyEngine.admit_patient_from_file(DEMO_PATIENT_PATH)
	_refresh_label()
	print("[The Forensic Ward] Boot OK - EventBus, GameState and PharmacologyEngine loaded.")


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_N:
			GameState.advance_shift() # Emits shift_ended -> engine advances 12 h.
		KEY_R:
			EventBus.medication_ordered.emit(_patient_id, {"drug_id": "clozapine", "daily_dose_mg": 300.0})
			_add_log("Order signed: clozapine 300 mg/day")
		KEY_O:
			GameState.change_objectivity(-10.0)
		KEY_P:
			GameState.change_objectivity(10.0)


func _on_objectivity_changed(_old_value: float, _new_value: float) -> void:
	_refresh_label()


func _on_patient_state_updated(_patient_id_updated: String, _state: Dictionary) -> void:
	_refresh_label()


func _on_clinical_alert_raised(patient_id: String, alert_id: String, severity: String) -> void:
	_add_log("ALERT %s %s: %s" % [patient_id, severity.to_upper(), alert_id])


func _on_clue_unlocked(clue_id: String) -> void:
	_add_log("CLUE UNLOCKED: " + clue_id)


func _add_log(line: String) -> void:
	_log.append("Day %d %s - %s" % [GameState.day, GameState.shift, line])
	if _log.size() > 6:
		_log.pop_front()
	_refresh_label()


func _refresh_label() -> void:
	if _status_label == null:
		return
	var text: String = "THE FORENSIC WARD - systems online\n"
	text += "Day %d (%s shift)   Objectivity %.0f   Bleed stage %d\n\n" % [
		GameState.day, GameState.shift, GameState.objectivity, GameState.bleed_stage]

	var state: Dictionary = PharmacologyEngine.get_state(_patient_id)
	if not state.is_empty():
		var levels: Dictionary = state["levels"]
		text += "%s (smoke-free ward)\n" % _patient_id
		text += "  Clozapine level: %.0f ng/mL (target 350-600)\n" % levels.get("clozapine", 0.0)
		text += "  Sedation %.2f   EPS %.2f   Anticholinergic %.2f\n" % [
			state["sedation"], state["eps"], state["anticholinergic"]]
		text += "  QTc %d ms   Psychosis %.2f   Interview reliability %.2f\n" % [
			state["qtc_ms"], state["symptoms"]["psychosis"], state["interview_reliability"]]
		text += "  CYP1A2 activity %.2f\n" % state["pathway_activity"].get("CYP1A2", 1.0)
		for alert: Dictionary in state["alerts"]:
			text += "  [%s] %s\n" % [alert["severity"].to_upper(), alert["message"]]

	text += "\n" + "\n".join(_log)
	text += "\n\n[N] end shift   [R] clozapine -> 300 mg   [O]/[P] objectivity"
	_status_label.text = text
