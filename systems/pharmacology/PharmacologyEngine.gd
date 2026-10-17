extends Node
## PharmacologyEngine — clinical pharmacology simulation (Autoload, "PharmacologyEngine").
##
## Turns medication orders into drug exposure, side effects, QTc, symptom
## control and safety alerts for every admitted patient. It has no visuals:
## the EHR terminal, interview system and Bleed system read its output through
## EventBus signals or get_state().
##
## MODEL OVERVIEW (grounded in the Day 4-7 lecture scripts / Stahl / Maudsley)
##
## 1. Exposure. One-compartment average-concentration model per drug.
##        target exposure  Css = (dose / reference_dose) / CL_rel
##        effective t1/2   = half_life / CL_rel
##    Exposure relaxes toward Css exponentially, so steady state takes ~4-5
##    half-lives and long-half-life drugs (fluoxetine) build up and wash out slowly.
##    E = 1.0 is the reference exposure of a normal metabolizer.
##
## 2. Clearance CL_rel = Σ pathway_fraction × pathway_activity, where activity =
##        genotype phenotype (PM/IM/NM/RM/UM)
##      × inhibition from co-prescribed perpetrators (fast onset, follows their washout)
##      × induction state (slow: relaxes over days, both when starting and stopping)
##      × inflammation suppression (mainly CYP1A2)
##    Renal pathways scale with eGFR instead of genotype. A drug that is both
##    substrate and inducer of a pathway (carbamazepine) autoinduces naturally.
##
## 3. Effects. Each drug has per-channel effects at E = 1.0. Efficacy channels
##    follow a saturating curve; adverse channels rise faster than linearly.
##    Channels combine across drugs as independent probabilities. QTc adds
##    linearly in ms (additive pharmacodynamic risk). Antipsychotic,
##    antidepressant and mood-stabilizer responses lag behind exposure.
##
## These are gameplay approximations calibrated to reference values. They
## are not clinical dosing tools.

const DRUG_DATABASE_PATH: String = "res://data/drugs/drugs.json"
const SHIFT_HOURS: float = 12.0
## Integration step. Exponential updates are exact for constant inputs; small
## steps keep induction/inhibition coupling stable.
const MAX_STEP_HOURS: float = 2.0
const LN2: float = 0.6931471805599453

## FDA strength class -> residual pathway activity at full inhibition.
## A strong inhibitor of a pathway carrying ≥ 90% of clearance gives ≥ 5x AUC.
const INHIBITION_ACTIVITY: Dictionary[String, float] = {
	"weak": 0.7, "moderate": 0.4, "strong": 0.15,
}
## FDA strength class -> pathway activity multiplier at full induction.
## Strong induction lowers a sensitive substrate's AUC by ≥ 80%.
const INDUCTION_ACTIVITY: Dictionary[String, float] = {
	"weak": 1.4, "moderate": 2.5, "strong": 5.0,
}
## Combustible smoke (polycyclic aromatic hydrocarbons, not nicotine) induces CYP1A2.
## Near-maximal at ~10 cigarettes/day.
const SMOKING_CYP1A2_INDUCTION: float = 1.8
const SMOKING_SATURATION_CIGS: float = 10.0
## Acute inflammation suppresses selected CYPs (phenoconversion).
const INFLAMMATION_ACTIVITY: Dictionary[String, float] = {
	"CYP1A2": 0.5, "CYP3A4": 0.75, "CYP2C19": 0.8,
}
## How quickly induction appears and disappears. CYP1A2 de-induction after
## smoking cessation has a half-life of ~1.6 days.
const INDUCTION_HALF_LIFE_HOURS: Dictionary[String, float] = {"CYP1A2": 38.0}
const DEFAULT_INDUCTION_HALF_LIFE_HOURS: float = 72.0

## Lagged channels -> half-time of the clinical response, in hours.
const RESPONSE_HALF_LIFE_HOURS: Dictionary[String, float] = {
	"antipsychotic": 72.0,
	"antidepressant": 168.0,
	"mood_stabilizer": 96.0,
	"eps": 24.0,
	"akathisia": 24.0,
}
const EFFICACY_CHANNELS: Array[String] = [
	"antipsychotic", "antidepressant", "mood_stabilizer",
	"agitation_control", "eps_relief", "akathisia_relief",
]
const ADVERSE_CHANNELS: Array[String] = [
	"sedation", "eps", "akathisia", "anticholinergic", "serotonergic",
]

## Clinical alert thresholds (QTc thresholds follow Maudsley).
const QTC_CRITICAL_MS: float = 500.0
const QTC_CRITICAL_INCREASE_MS: float = 60.0
const SEDATION_WARNING: float = 0.65
const SEDATION_CRITICAL: float = 0.85
const EPS_WARNING: float = 0.5
const AKATHISIA_WARNING: float = 0.45
const ANTICHOLINERGIC_WARNING: float = 0.75
const SEROTONIN_TOXICITY_THRESHOLD: float = 0.8
## Predicted exposure changes smaller than this are not reported as interactions.
const INTERACTION_REPORT_THRESHOLD: float = 0.2

var _drugs: Dictionary[String, DrugProfile] = {}
var _patients: Dictionary[String, PatientRecord] = {}


func _ready() -> void:
	load_drug_database(DRUG_DATABASE_PATH)
	EventBus.medication_ordered.connect(_on_medication_ordered)
	EventBus.medication_discontinued.connect(_on_medication_discontinued)
	EventBus.shift_ended.connect(_on_shift_ended)


# ===========================================================================
# Data loading
# ===========================================================================

func load_drug_database(path: String) -> Error:
	var parsed: Variant = _read_json(path)
	if not parsed is Dictionary:
		return ERR_PARSE_ERROR
	_drugs.clear()
	for entry: Variant in parsed.get("drugs", []):
		if entry is Dictionary:
			var drug: DrugProfile = DrugProfile.from_dict(entry)
			_drugs[drug.id] = drug
	return OK


func get_drug(drug_id: String) -> DrugProfile:
	return _drugs.get(drug_id, null)


func get_drug_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_drugs.keys())
	return ids


## Admits a patient from a JSON file. Returns the patient id, or "" on failure.
func admit_patient_from_file(path: String) -> String:
	var parsed: Variant = _read_json(path)
	if not parsed is Dictionary:
		return ""
	return admit_patient(parsed)


## Admits a patient from parsed JSON. Home medications marked
## "at_steady_state" start at the steady state reached *before* admission,
## including smoking-related CYP1A2 induction that the smoke-free ward removes.
func admit_patient(data: Dictionary) -> String:
	var patient: PatientRecord = PatientRecord.from_dict(data)
	if patient.id.is_empty():
		push_error("PharmacologyEngine: patient data has no id")
		return ""
	_patients[patient.id] = patient

	var steady_meds: Array[String] = []
	for med: Variant in data.get("home_medications", []):
		if not med is Dictionary or get_drug(str(med.get("drug_id", ""))) == null:
			push_warning("PharmacologyEngine: unknown home medication %s" % [med])
			continue
		var drug_id: String = str(med["drug_id"])
		patient.doses[drug_id] = float(med.get("daily_dose_mg", 0.0))
		patient.exposures[drug_id] = 0.0
		if bool(med.get("at_steady_state", true)):
			steady_meds.append(drug_id)

	if not steady_meds.is_empty():
		_initialize_steady_state(patient, steady_meds)

	_refresh_patient(patient)
	EventBus.patient_admitted.emit(patient.id)
	return patient.id


func get_patient(patient_id: String) -> PatientRecord:
	return _patients.get(patient_id, null)


func get_patient_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_patients.keys())
	return ids


# ===========================================================================
# Orders
# ===========================================================================

## Starts, changes or stops (dose 0) a medication. Returns the same report as
## preview_order() so the EHR can show the predicted consequences.
## UI code should emit EventBus.medication_ordered instead of calling this.
func order_medication(patient_id: String, drug_id: String, daily_dose_mg: float) -> Dictionary:
	var patient: PatientRecord = get_patient(patient_id)
	var drug: DrugProfile = get_drug(drug_id)
	if patient == null or drug == null:
		push_error("PharmacologyEngine: bad order %s / %s" % [patient_id, drug_id])
		return {}
	var report: Dictionary = preview_order(patient_id, drug_id, daily_dose_mg)
	patient.doses[drug_id] = maxf(daily_dose_mg, 0.0)
	if not patient.exposures.has(drug_id):
		patient.exposures[drug_id] = 0.0
	_refresh_patient(patient)
	return report


func discontinue_medication(patient_id: String, drug_id: String) -> void:
	var patient: PatientRecord = get_patient(patient_id)
	if patient != null and patient.doses.has(drug_id):
		# Keep the exposure: the drug washes out over its own half-life.
		patient.doses[drug_id] = 0.0
		_refresh_patient(patient)


## Predicts what an order would do without applying it. Returns:
##   predicted_exposure: steady-state E of the ordered drug (1.0 = reference)
##   interactions: Array of {victim, perpetrator, pathways, fold_change, onset, text}
##   pharmacodynamic: Array of String (additive QTc / serotonergic / sedation)
##   warnings: Array of String (max dose, phenotype notes)
func preview_order(patient_id: String, drug_id: String, daily_dose_mg: float) -> Dictionary:
	var patient: PatientRecord = get_patient(patient_id)
	var drug: DrugProfile = get_drug(drug_id)
	var report: Dictionary = {
		"drug_id": drug_id, "daily_dose_mg": daily_dose_mg, "predicted_exposure": 0.0,
		"interactions": [], "pharmacodynamic": [], "warnings": [],
	}
	if patient == null or drug == null:
		return report

	if drug.max_daily_dose_mg > 0.0 and daily_dose_mg > drug.max_daily_dose_mg:
		report["warnings"].append("%s %.0f mg/day exceeds the usual maximum of %.0f mg/day."
				% [drug.display_name, daily_dose_mg, drug.max_daily_dose_mg])
	for pathway: String in drug.pathways:
		var code: String = patient.phenotypes.get(pathway, "NM")
		if code != "NM" and drug.pathways[pathway] >= 0.3:
			report["warnings"].append("%s is a %s metabolizer; %s relies on %s for %d%% of clearance."
					% [patient.display_name, code, drug.display_name, pathway, roundi(drug.pathways[pathway] * 100.0)])

	# The ordered drug as a victim of what the patient already takes.
	var clearance: float = _clearance(patient, drug, null, true)
	report["predicted_exposure"] = (daily_dose_mg / drug.reference_daily_dose_mg) / clearance
	var baseline_clearance: float = _clearance(patient, drug, null, true, true)
	var victim_fold: float = baseline_clearance / clearance
	if absf(victim_fold - 1.0) >= INTERACTION_REPORT_THRESHOLD:
		report["interactions"].append(_describe_interaction(drug, null, victim_fold,
				_shared_perpetrator_pathways(patient, drug)))

	# Existing drugs as victims of the new order (only if it is newly started).
	var is_new: bool = patient.doses.get(drug_id, 0.0) <= 0.0
	if is_new and daily_dose_mg > 0.0 and (not drug.inhibits.is_empty() or not drug.induces.is_empty()):
		for other_id: String in patient.doses:
			if other_id == drug_id or patient.doses[other_id] <= 0.0:
				continue
			var victim: DrugProfile = get_drug(other_id)
			var now_cl: float = _clearance(patient, victim, null, true)
			var new_cl: float = _clearance(patient, victim, drug, true)
			var fold: float = now_cl / new_cl
			if absf(fold - 1.0) >= INTERACTION_REPORT_THRESHOLD:
				report["interactions"].append(_describe_interaction(victim, drug, fold, _affected_pathways(victim, drug)))

	if is_new and daily_dose_mg > 0.0:
		report["pharmacodynamic"] = _describe_pharmacodynamic(patient, drug)
	return report


# ===========================================================================
# Time
# ===========================================================================

## Advances every admitted patient. Called automatically on EventBus.shift_ended.
func advance_hours(hours: float) -> void:
	for patient: PatientRecord in _patients.values():
		var remaining: float = hours
		while remaining > 0.0:
			var dt: float = minf(remaining, MAX_STEP_HOURS)
			_step(patient, dt)
			remaining -= dt
		_refresh_patient(patient)


# ===========================================================================
# Patient modifiers (story events)
# ===========================================================================

func set_smoking(patient_id: String, smoking: bool) -> void:
	var patient: PatientRecord = get_patient(patient_id)
	if patient != null:
		patient.is_smoking_now = smoking
		_refresh_patient(patient)


func set_inflammation(patient_id: String, inflamed: bool) -> void:
	var patient: PatientRecord = get_patient(patient_id)
	if patient != null:
		patient.has_inflammation = inflamed
		_refresh_patient(patient)


func set_egfr(patient_id: String, egfr: float) -> void:
	var patient: PatientRecord = get_patient(patient_id)
	if patient != null:
		patient.egfr = maxf(egfr, 1.0)
		_refresh_patient(patient)


func set_potassium(patient_id: String, potassium_mmol_l: float) -> void:
	var patient: PatientRecord = get_patient(patient_id)
	if patient != null:
		patient.potassium_mmol_l = potassium_mmol_l
		_refresh_patient(patient)


# ===========================================================================
# Queries
# ===========================================================================

## Latest clinical state. Keys: patient_id, hours, exposures, levels,
## sedation, eps, akathisia, anticholinergic, serotonergic, qtc_ms,
## symptoms {psychosis, depression, mania, agitation}, interview_reliability,
## pathway_activity, alerts [{id, severity, message}].
func get_state(patient_id: String) -> Dictionary:
	var patient: PatientRecord = get_patient(patient_id)
	return patient.last_state if patient != null else {}


## Therapeutic drug monitoring: returns {drug_id, level, unit, therapeutic_range, flag}
## and emits EventBus.lab_results_ready with panel id "TDM_<drug_id>".
func measure_drug_level(patient_id: String, drug_id: String) -> Dictionary:
	var patient: PatientRecord = get_patient(patient_id)
	var drug: DrugProfile = get_drug(drug_id)
	if patient == null or drug == null or not drug.tdm_enabled:
		return {}
	var level: float = patient.exposures.get(drug_id, 0.0) * drug.level_at_reference
	var flag: String = "therapeutic"
	if level > drug.level_critical:
		flag = "critical"
	elif level > drug.therapeutic_range.y:
		flag = "high"
	elif level < drug.therapeutic_range.x:
		flag = "low"
	var result: Dictionary = {
		"drug_id": drug_id, "level": snappedf(level, 0.01), "unit": drug.level_unit,
		"therapeutic_range": [drug.therapeutic_range.x, drug.therapeutic_range.y], "flag": flag,
	}
	EventBus.lab_results_ready.emit(patient_id, "TDM_" + drug_id, result)
	return result


# ===========================================================================
# Core pharmacokinetics
# ===========================================================================

## How strongly a perpetrator acts at exposure E (≈ full effect at reference exposure).
func _perpetrator_fraction(exposure: float) -> float:
	if exposure <= 0.0:
		return 0.0
	return clampf(exposure / (exposure + 0.25) * 1.25, 0.0, 1.0)


func _induction_target(patient: PatientRecord, pathway: String, extra: DrugProfile = null) -> float:
	var target: float = 1.0
	for drug_id: String in patient.exposures:
		var inducer: DrugProfile = get_drug(drug_id)
		if inducer.induces.has(pathway):
			var full: float = INDUCTION_ACTIVITY.get(inducer.induces[pathway], 1.0)
			target *= lerpf(1.0, full, _perpetrator_fraction(patient.exposures[drug_id]))
	if extra != null and extra.induces.has(pathway):
		target *= INDUCTION_ACTIVITY.get(extra.induces[pathway], 1.0)
	if pathway == "CYP1A2" and patient.is_smoking_now and patient.cigarettes_per_day > 0:
		var smoke_fraction: float = minf(patient.cigarettes_per_day / SMOKING_SATURATION_CIGS, 1.0)
		target *= lerpf(1.0, SMOKING_CYP1A2_INDUCTION, smoke_fraction)
	return target


## Net activity of one clearance pathway for this patient.
##   extra: a hypothetical perpetrator at full strength (used by preview_order).
##   steady: use induction targets instead of the current lagging state.
##   baseline: ignore all perpetrators (genotype, organ function, inflammation only).
##   substrate_id: the drug being cleared. A drug's inhibition of its own
##     pathway is ignored so reference doses stay calibrated (autoinduction,
##     which is clinically important for carbamazepine, is kept).
func _pathway_activity(patient: PatientRecord, pathway: String, extra: DrugProfile = null,
		steady: bool = false, baseline: bool = false, substrate_id: String = "") -> float:
	var activity: float = 1.0
	if pathway.begins_with(DrugProfile.RENAL_PREFIX):
		activity = patient.get_renal_factor()
	elif pathway != "OTHER":
		activity = patient.get_phenotype_activity(pathway)
		if patient.has_inflammation:
			activity *= INFLAMMATION_ACTIVITY.get(pathway, 1.0)
	if baseline:
		return activity

	for drug_id: String in patient.exposures:
		var inhibitor: DrugProfile = get_drug(drug_id)
		if inhibitor.inhibits.has(pathway) and drug_id != substrate_id:
			var full: float = INHIBITION_ACTIVITY.get(inhibitor.inhibits[pathway], 1.0)
			var exposure: float = patient.exposures[drug_id]
			if steady:
				exposure = maxf(exposure, patient.doses.get(drug_id, 0.0) / inhibitor.reference_daily_dose_mg)
			activity *= lerpf(1.0, full, _perpetrator_fraction(exposure))
	if extra != null and extra.inhibits.has(pathway):
		activity *= INHIBITION_ACTIVITY.get(extra.inhibits[pathway], 1.0)

	if not pathway.begins_with(DrugProfile.RENAL_PREFIX) and pathway != "OTHER":
		if steady:
			activity *= _induction_target(patient, pathway, extra)
		else:
			activity *= patient.induction_state.get(pathway, 1.0)
	return maxf(activity, 0.02)


## Relative clearance of `drug` in this patient (1.0 = reference adult NM).
func _clearance(patient: PatientRecord, drug: DrugProfile, extra: DrugProfile = null,
		steady: bool = false, baseline: bool = false) -> float:
	var total: float = 0.0
	var fraction_sum: float = 0.0
	for pathway: String in drug.pathways:
		var fraction: float = drug.pathways[pathway]
		fraction_sum += fraction
		total += fraction * _pathway_activity(patient, pathway, extra, steady, baseline, drug.id)
	# Any unassigned fraction behaves as an unaffected "OTHER" route.
	total += maxf(1.0 - fraction_sum, 0.0)
	return maxf(total, 0.02)


func _step(patient: PatientRecord, dt: float) -> void:
	patient.hours_elapsed += dt

	# 1. Induction relaxes toward its target (slow onset AND slow offset).
	for pathway: String in _all_metabolic_pathways(patient):
		var target: float = _induction_target(patient, pathway)
		var current: float = patient.induction_state.get(pathway, 1.0)
		var half_life: float = INDUCTION_HALF_LIFE_HOURS.get(pathway, DEFAULT_INDUCTION_HALF_LIFE_HOURS)
		patient.induction_state[pathway] = _relax(current, target, dt, half_life)

	# 2. Exposure relaxes toward steady state at the drug's effective half-life.
	var new_exposures: Dictionary[String, float] = {}
	for drug_id: String in patient.exposures:
		var drug: DrugProfile = get_drug(drug_id)
		var clearance: float = _clearance(patient, drug)
		var target: float = (patient.doses.get(drug_id, 0.0) / drug.reference_daily_dose_mg) / clearance
		var effective_half_life: float = clampf(drug.half_life_hours / clearance, 0.25, drug.half_life_hours * 50.0)
		new_exposures[drug_id] = _relax(patient.exposures[drug_id], target, dt, effective_half_life)
	for drug_id: String in new_exposures:
		if patient.doses.get(drug_id, 0.0) <= 0.0 and new_exposures[drug_id] < 0.005:
			patient.exposures.erase(drug_id)
			patient.doses.erase(drug_id)
		else:
			patient.exposures[drug_id] = new_exposures[drug_id]

	# 3. Clinical response lags behind exposure.
	var raw: Dictionary[String, float] = _raw_channels(patient)
	for channel: String in RESPONSE_HALF_LIFE_HOURS:
		var current: float = patient.response_state.get(channel, 0.0)
		patient.response_state[channel] = _relax(current, raw.get(channel, 0.0), dt, RESPONSE_HALF_LIFE_HOURS[channel])


func _initialize_steady_state(patient: PatientRecord, drug_ids: Array[String]) -> void:
	# Before admission the patient was still smoking.
	var smoking_on_ward: bool = patient.is_smoking_now
	patient.is_smoking_now = patient.cigarettes_per_day > 0
	# Fixed-point iteration: self-inhibition (paroxetine) and autoinduction
	# (carbamazepine) make steady state depend on itself.
	for _iteration: int in 40:
		for pathway: String in _all_metabolic_pathways(patient):
			patient.induction_state[pathway] = _induction_target(patient, pathway)
		for drug_id: String in drug_ids:
			var drug: DrugProfile = get_drug(drug_id)
			patient.exposures[drug_id] = (patient.doses[drug_id] / drug.reference_daily_dose_mg) / _clearance(patient, drug)
	var raw: Dictionary[String, float] = _raw_channels(patient)
	for channel: String in RESPONSE_HALF_LIFE_HOURS:
		patient.response_state[channel] = raw.get(channel, 0.0)
	patient.is_smoking_now = smoking_on_ward


func _relax(current: float, target: float, dt: float, half_life: float) -> float:
	return target + (current - target) * exp(-LN2 * dt / maxf(half_life, 0.01))


func _all_metabolic_pathways(patient: PatientRecord) -> Array[String]:
	var result: Array[String] = ["CYP1A2"] # Always tracked: smoking.
	for drug_id: String in patient.exposures:
		var drug: DrugProfile = get_drug(drug_id)
		for pathway: String in drug.pathways.keys() + drug.induces.keys():
			if not pathway in result and not pathway.begins_with(DrugProfile.RENAL_PREFIX) and pathway != "OTHER":
				result.append(pathway)
	return result


# ===========================================================================
# Pharmacodynamics
# ===========================================================================

## Saturating efficacy curve normalized to 1.0 at E = 1.0 (max ≈ 1.35).
func _efficacy_curve(exposure: float) -> float:
	const EC50: float = 0.5
	const HILL: float = 1.5
	var e_n: float = pow(maxf(exposure, 0.0), HILL)
	var c_n: float = pow(EC50, HILL)
	return e_n * (1.0 + c_n) / (c_n + e_n)


## Adverse effects rise faster than linearly with exposure.
func _adverse_curve(exposure: float) -> float:
	return pow(maxf(exposure, 0.0), 1.3)


## Combines independent 0..1 effects: 1 - Π(1 - x).
func _combine(values: Array) -> float:
	var remaining: float = 1.0
	for value: float in values:
		remaining *= 1.0 - clampf(value, 0.0, 0.99)
	return 1.0 - remaining


## Un-lagged channel totals from current exposures.
func _raw_channels(patient: PatientRecord) -> Dictionary[String, float]:
	var per_channel: Dictionary[String, Array] = {}
	for channel: String in EFFICACY_CHANNELS + ADVERSE_CHANNELS:
		per_channel[channel] = []
	for drug_id: String in patient.exposures:
		var drug: DrugProfile = get_drug(drug_id)
		var exposure: float = patient.exposures[drug_id]
		for channel: String in drug.effects:
			if not per_channel.has(channel):
				continue
			var curve: float = _efficacy_curve(exposure) if channel in EFFICACY_CHANNELS else _adverse_curve(exposure)
			per_channel[channel].append(drug.effects[channel] * curve)
	var totals: Dictionary[String, float] = {}
	for channel: String in per_channel:
		totals[channel] = _combine(per_channel[channel])
	return totals


## Recomputes last_state, emits patient_state_updated, new alerts and clue unlocks.
func _refresh_patient(patient: PatientRecord) -> void:
	var raw: Dictionary[String, float] = _raw_channels(patient)
	var channel: Callable = func(name: String) -> float:
		return patient.response_state.get(name, raw[name]) if RESPONSE_HALF_LIFE_HOURS.has(name) else raw[name]

	var sedation: float = raw["sedation"]
	var eps: float = channel.call("eps") * (1.0 - raw["eps_relief"])
	var akathisia: float = channel.call("akathisia") * (1.0 - raw["akathisia_relief"])
	var anticholinergic: float = raw["anticholinergic"]
	var antipsychotic: float = channel.call("antipsychotic")

	var qtc: float = patient.baseline_qtc_ms
	var levels: Dictionary = {}
	var exposures: Dictionary = {}
	var serotonergic_drugs: int = 0
	for drug_id: String in patient.exposures:
		var drug: DrugProfile = get_drug(drug_id)
		var exposure: float = patient.exposures[drug_id]
		exposures[drug_id] = snappedf(exposure, 0.001)
		qtc += drug.qtc_ms * exposure
		if drug.tdm_enabled:
			levels[drug_id] = snappedf(exposure * drug.level_at_reference, 0.01)
		if drug.get_effect("serotonergic") > 0.0 and exposure > 0.1:
			serotonergic_drugs += 1
	if patient.potassium_mmol_l < 3.5:
		qtc += 10.0
	if patient.potassium_mmol_l < 3.0:
		qtc += 10.0

	var base: Dictionary[String, float] = patient.baseline_symptoms
	var symptoms: Dictionary = {
		"psychosis": base.get("psychosis", 0.0) * (1.0 - antipsychotic),
		"depression": base.get("depression", 0.0) * (1.0 - channel.call("antidepressant")),
		"mania": base.get("mania", 0.0) * (1.0 - _combine([channel.call("mood_stabilizer"), antipsychotic * 0.7])),
		"agitation": clampf(base.get("agitation", 0.0)
				* (1.0 - _combine([raw["agitation_control"], sedation * 0.6, antipsychotic * 0.5]))
				+ akathisia * 0.5, 0.0, 1.0),
	}
	var delirium: float = clampf((anticholinergic - 0.5) * 2.0, 0.0, 1.0)
	var reliability: float = (1.0 - 0.6 * symptoms["psychosis"]) * (1.0 - 0.8 * sedation) * (1.0 - 0.5 * delirium)

	var pathway_activity: Dictionary = {}
	for pathway: String in _all_metabolic_pathways(patient):
		pathway_activity[pathway] = snappedf(_pathway_activity(patient, pathway), 0.01)

	var state: Dictionary = {
		"patient_id": patient.id,
		"hours": patient.hours_elapsed,
		"exposures": exposures,
		"levels": levels,
		"sedation": sedation,
		"eps": eps,
		"akathisia": akathisia,
		"anticholinergic": anticholinergic,
		"serotonergic": raw["serotonergic"],
		"qtc_ms": roundf(qtc),
		"symptoms": symptoms,
		"interview_reliability": clampf(reliability, 0.0, 1.0),
		"pathway_activity": pathway_activity,
	}
	state["alerts"] = _evaluate_alerts(patient, state, serotonergic_drugs)
	patient.last_state = state

	_emit_alert_changes(patient, state["alerts"])
	EventBus.patient_state_updated.emit(patient.id, state)
	_evaluate_clue_gates(patient, state)


# ===========================================================================
# Alerts
# ===========================================================================

func _evaluate_alerts(patient: PatientRecord, state: Dictionary, serotonergic_drugs: int) -> Array[Dictionary]:
	var alerts: Array[Dictionary] = []
	var qtc: float = state["qtc_ms"]
	if qtc > QTC_CRITICAL_MS or qtc - patient.baseline_qtc_ms > QTC_CRITICAL_INCREASE_MS:
		alerts.append(_alert("QTC", "critical", "QTc %d ms: high risk of torsades de pointes." % qtc))
	elif qtc > patient.get_qtc_prolonged_threshold():
		alerts.append(_alert("QTC", "warning", "QTc %d ms is prolonged." % qtc))

	var sedation: float = state["sedation"]
	if sedation > SEDATION_CRITICAL:
		alerts.append(_alert("SEDATION", "critical", "Patient is over-sedated and cannot be interviewed."))
	elif sedation > SEDATION_WARNING:
		alerts.append(_alert("SEDATION", "warning", "Marked sedation."))

	if state["eps"] > EPS_WARNING:
		alerts.append(_alert("EPS", "warning", "Extrapyramidal signs: rigidity, tremor, bradykinesia."))
	if state["akathisia"] > AKATHISIA_WARNING:
		alerts.append(_alert("AKATHISIA", "warning", "Akathisia: inner restlessness, pacing."))
	if state["anticholinergic"] > ANTICHOLINERGIC_WARNING:
		alerts.append(_alert("ANTICHOLINERGIC", "warning", "High anticholinergic burden: delirium, ileus, urinary retention risk."))
	if serotonergic_drugs >= 2 and state["serotonergic"] > SEROTONIN_TOXICITY_THRESHOLD:
		alerts.append(_alert("SEROTONIN_TOXICITY", "critical", "Serotonin toxicity risk: check for clonus, hyperreflexia, hyperthermia."))

	for drug_id: String in state["levels"]:
		var drug: DrugProfile = get_drug(drug_id)
		var level: float = state["levels"][drug_id]
		if level > drug.level_critical:
			alerts.append(_alert("LEVEL_" + drug_id.to_upper(), "critical",
					"%s level %.2f %s: toxic range." % [drug.display_name, level, drug.level_unit]))
		elif level > drug.level_warning:
			alerts.append(_alert("LEVEL_" + drug_id.to_upper(), "warning",
					"%s level %.2f %s is above range." % [drug.display_name, level, drug.level_unit]))
	return alerts


func _alert(alert_id: String, severity: String, message: String) -> Dictionary:
	return {"id": alert_id, "severity": severity, "message": message}


## Emits clinical_alert_raised only for alerts that are new or changed severity.
func _emit_alert_changes(patient: PatientRecord, alerts: Array[Dictionary]) -> void:
	var current: Dictionary[String, String] = {}
	for alert: Dictionary in alerts:
		current[alert["id"]] = alert["severity"]
		if patient.active_alerts.get(alert["id"], "") != alert["severity"]:
			EventBus.clinical_alert_raised.emit(patient.id, alert["id"], alert["severity"])
	patient.active_alerts = current


# ===========================================================================
# Clue gates
# ===========================================================================

## A gate opens when every requirement holds, e.g.
##   {"clue_id": "pt001_memory", "requires": {"psychosis_max": 0.35, "sedation_max": 0.5}}
## Supported keys: psychosis_max, depression_max, mania_max, agitation_max,
## sedation_max, interview_reliability_min, min_hours_treated, no_critical_alerts.
func _evaluate_clue_gates(patient: PatientRecord, state: Dictionary) -> void:
	for gate: Dictionary in patient.clue_gates:
		var clue_id: String = str(gate.get("clue_id", ""))
		if clue_id.is_empty() or GameState.is_clue_unlocked(clue_id):
			continue
		if _gate_satisfied(gate.get("requires", {}), patient, state):
			GameState.unlock_clue(clue_id)


func _gate_satisfied(requires: Dictionary, patient: PatientRecord, state: Dictionary) -> bool:
	var symptoms: Dictionary = state["symptoms"]
	for key: String in requires:
		var limit: Variant = requires[key]
		match key:
			"psychosis_max", "depression_max", "mania_max", "agitation_max":
				if symptoms.get(key.trim_suffix("_max"), 0.0) > float(limit):
					return false
			"sedation_max":
				if state["sedation"] > float(limit):
					return false
			"interview_reliability_min":
				if state["interview_reliability"] < float(limit):
					return false
			"min_hours_treated":
				if patient.hours_elapsed < float(limit):
					return false
			"no_critical_alerts":
				if bool(limit) and "critical" in patient.active_alerts.values():
					return false
			_:
				push_warning("PharmacologyEngine: unknown clue gate requirement '%s'" % key)
	return true


# ===========================================================================
# Report text helpers
# ===========================================================================

func _describe_interaction(victim: DrugProfile, perpetrator: DrugProfile, fold: float, pathways: Array[String]) -> Dictionary:
	var direction: String = "increase" if fold > 1.0 else "decrease"
	var cause: String = perpetrator.display_name if perpetrator != null else "current medications / phenotype"
	var is_induction: bool = fold < 1.0
	var onset: String = "over 1-3 weeks (induction)" if is_induction else "within days (inhibition)"
	var text: String = "%s exposure predicted to %s %.1fx via %s (%s), %s." % [
		victim.display_name, direction, fold if fold > 1.0 else 1.0 / fold,
		", ".join(pathways) if not pathways.is_empty() else "clearance pathways", cause, onset]
	return {
		"victim": victim.id,
		"perpetrator": perpetrator.id if perpetrator != null else "",
		"pathways": pathways,
		"fold_change": snappedf(fold, 0.01),
		"onset": onset,
		"text": text,
	}


func _affected_pathways(victim: DrugProfile, perpetrator: DrugProfile) -> Array[String]:
	var result: Array[String] = []
	for pathway: String in victim.pathways:
		if perpetrator.inhibits.has(pathway) or perpetrator.induces.has(pathway):
			result.append(pathway)
	return result


func _shared_perpetrator_pathways(patient: PatientRecord, victim: DrugProfile) -> Array[String]:
	var result: Array[String] = []
	for drug_id: String in patient.doses:
		if patient.doses[drug_id] <= 0.0 or drug_id == victim.id:
			continue
		for pathway: String in _affected_pathways(victim, get_drug(drug_id)):
			if not pathway in result:
				result.append(pathway)
	return result


func _describe_pharmacodynamic(patient: PatientRecord, drug: DrugProfile) -> Array[String]:
	var notes: Array[String] = []
	for other_id: String in patient.doses:
		if other_id == drug.id or patient.doses[other_id] <= 0.0:
			continue
		var other: DrugProfile = get_drug(other_id)
		if drug.qtc_ms >= 3.0 and other.qtc_ms >= 3.0:
			notes.append("Additive QTc prolongation with %s: obtain ECG." % other.display_name)
		if drug.get_effect("serotonergic") > 0.0 and other.get_effect("serotonergic") > 0.0:
			notes.append("Two serotonergic drugs with %s: monitor for serotonin toxicity." % other.display_name)
		if drug.get_effect("sedation") >= 0.3 and other.get_effect("sedation") >= 0.3:
			notes.append("Additive sedation with %s." % other.display_name)
		if drug.get_effect("anticholinergic") >= 0.3 and other.get_effect("anticholinergic") >= 0.3:
			notes.append("Additive anticholinergic burden with %s." % other.display_name)
	return notes


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("PharmacologyEngine: missing file %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("PharmacologyEngine: invalid JSON in %s" % path)
	return parsed


func _on_medication_ordered(patient_id: String, order: Dictionary) -> void:
	order_medication(patient_id, str(order.get("drug_id", "")), float(order.get("daily_dose_mg", 0.0)))


func _on_medication_discontinued(patient_id: String, drug_id: String) -> void:
	discontinue_medication(patient_id, drug_id)


func _on_shift_ended(_day: int, _shift: String) -> void:
	advance_hours(SHIFT_HOURS)
