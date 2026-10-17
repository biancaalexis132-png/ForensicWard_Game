class_name PatientRecord
extends RefCounted
## PatientRecord — one patient's physiology plus live pharmacology state.
##
## Built from a JSON file in res://data/patients/ (see docs/PATIENT_SCHEMA.md).
## The static half (genotype, renal function, baseline symptoms) is authored
## by the narrative team. The dynamic half (exposures, induction, treatment
## response, active alerts) is owned and mutated only by PharmacologyEngine.

## CYP metabolizer phenotypes (CPIC terminology) -> relative enzyme activity.
## These are game-model multipliers on pathway clearance, not CPIC values.
const PHENOTYPE_ACTIVITY: Dictionary[String, float] = {
	"PM": 0.05, ## Poor metabolizer: essentially no functional enzyme.
	"IM": 0.5,  ## Intermediate metabolizer.
	"NM": 1.0,  ## Normal metabolizer (default).
	"RM": 1.4,  ## Rapid metabolizer (CYP2C19 *1/*17).
	"UM": 2.0,  ## Ultrarapid metabolizer (CYP2D6 gene duplication, CYP2C19 *17/*17).
}

# --- Static (authored) -------------------------------------------------------
var id: String = ""
var display_name: String = ""
var age: int = 40
var sex: String = "M"
var weight_kg: float = 75.0
var egfr: float = 100.0
var baseline_qtc_ms: float = 410.0
var potassium_mmol_l: float = 4.2
## Pathway -> phenotype code ("PM" | "IM" | "NM" | "RM" | "UM").
var phenotypes: Dictionary[String, String] = {}
## Cigarettes per day before admission. Tobacco smoke (not nicotine) induces CYP1A2.
var cigarettes_per_day: int = 0
## The ward is smoke-free by default, so admitted smokers lose CYP1A2 induction.
var is_smoking_now: bool = false
var has_inflammation: bool = false
## Symptom domain -> untreated severity 0..1 ("psychosis", "depression", "mania", "agitation").
var baseline_symptoms: Dictionary[String, float] = {}
## Each gate: {"clue_id": String, "requires": Dictionary}.
var clue_gates: Array[Dictionary] = []

# --- Dynamic (engine-owned) ------------------------------------------------
## drug_id -> prescribed daily dose in mg (0 means discontinued / washing out).
var doses: Dictionary[String, float] = {}
## drug_id -> current relative exposure E (1.0 = reference steady state).
var exposures: Dictionary[String, float] = {}
## pathway -> current induction multiplier (relaxes toward its target over days).
var induction_state: Dictionary[String, float] = {}
## lagged efficacy channel -> current value (antipsychotic response takes days).
var response_state: Dictionary[String, float] = {}
## alert_id -> severity, so alerts are only emitted when they first appear.
var active_alerts: Dictionary[String, String] = {}
## The last computed clinical state (see PharmacologyEngine.get_state()).
var last_state: Dictionary = {}
## Hours since admission.
var hours_elapsed: float = 0.0


static func from_dict(data: Dictionary) -> PatientRecord:
	var patient: PatientRecord = PatientRecord.new()
	patient.id = str(data.get("id", ""))
	patient.display_name = str(data.get("name", patient.id))
	patient.age = int(data.get("age", 40))
	patient.sex = str(data.get("sex", "M")).to_upper()
	patient.weight_kg = float(data.get("weight_kg", 75.0))
	patient.egfr = float(data.get("egfr", 100.0))
	patient.baseline_qtc_ms = float(data.get("baseline_qtc_ms", 410.0))
	patient.potassium_mmol_l = float(data.get("potassium_mmol_l", 4.2))
	patient.has_inflammation = bool(data.get("inflammation", false))

	for pathway: String in data.get("phenotypes", {}):
		patient.phenotypes[pathway] = str(data["phenotypes"][pathway]).to_upper()

	var smoking: Dictionary = data.get("smoking", {})
	patient.cigarettes_per_day = int(smoking.get("cigarettes_per_day", 0))
	patient.is_smoking_now = bool(smoking.get("smoking_on_ward", false))

	for domain: String in data.get("baseline_symptoms", {}):
		patient.baseline_symptoms[domain] = clampf(float(data["baseline_symptoms"][domain]), 0.0, 1.0)

	for gate: Variant in data.get("clue_gates", []):
		if gate is Dictionary:
			patient.clue_gates.append(gate)
	return patient


## Genetic activity for a pathway. Renal and "OTHER" pathways have no phenotype.
func get_phenotype_activity(pathway: String) -> float:
	var code: String = phenotypes.get(pathway, "NM")
	return PHENOTYPE_ACTIVITY.get(code, 1.0)


## Clearance multiplier for renally cleared fractions. eGFR 100 mL/min = 1.0.
func get_renal_factor() -> float:
	return clampf(egfr / 100.0, 0.05, 1.5)


## Maudsley: QTc > 450 ms (men) / > 470 ms (women) is prolonged.
func get_qtc_prolonged_threshold() -> float:
	return 470.0 if sex == "F" else 450.0
