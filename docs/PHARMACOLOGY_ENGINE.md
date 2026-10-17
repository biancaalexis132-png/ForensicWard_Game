# PharmacologyEngine

`systems/pharmacology/PharmacologyEngine.gd` is an autoload (always loaded). It turns medication orders into drug exposure, side effects, QTc, symptom control, safety alerts and clue unlocks for every admitted patient.

## Knowledge base

The model follows the PSYCH folder's Day 4–7 resident lecture scripts, which cite Stahl 5e, Maudsley 15e, Kaplan & Sadock 12e, the FDA and CPIC:

| Lecture concept | How the engine implements it |
|---|---|
| Average exposure ∝ dose × F / CL | `Css = (dose / reference_dose) / CL_rel` |
| Steady state takes ~4–5 half-lives | Exposure moves toward Css at an effective half-life of `t½ / CL_rel` |
| FDA inhibitor strength (strong ≥ 5×, moderate 2–5×, weak 1.25–2× AUC) | `INHIBITION_ACTIVITY` (0.15 / 0.4 / 0.7 residual activity) |
| FDA inducer strength (strong ≥ 80% AUC drop, …) | `INDUCTION_ACTIVITY` (5.0 / 2.5 / 1.4) |
| Inhibition is fast; induction takes days to weeks to start and to wear off | Inhibition follows the inhibitor's own exposure. Induction is a lagging state (CYP1A2 t½ ≈ 38 h, others 72 h) |
| Phenoconversion (a normal metabolizer on fluoxetine behaves like a poor metabolizer) | Inhibition multiplies the genetic phenotype activity |
| Smoke (not nicotine) induces CYP1A2 | `SMOKING_CYP1A2_INDUCTION`. The ward is smoke-free, so smokers de-induce after admission |
| Inflammation suppresses CYP1A2 | `set_inflammation()` → CYP1A2 × 0.5, CYP3A4 × 0.75 |
| Carbamazepine autoinduction | Emerges from the model, because the drug is both a CYP3A4 substrate and a CYP3A4 inducer |
| Lithium is cleared only by the kidney | `RENAL_LITHIUM` pathway scales with eGFR and is inhibited by NSAIDs |
| PK and PD interactions are separate | PK: clearance math. PD: additive QTc (ms), combined sedation, serotonergic and anticholinergic burden |
| Plan the stop as well as the start | Stopped drugs wash out over their half-life, and their inhibition/induction fades with them |

The Stahl Prescriber's Guide and Maudsley PDFs in Drive are too large for the connector to return in full (only about the first 200k characters come back), so per-drug values in `data/drugs/drugs.json` are standard reference values. Each one carries a `source` note. Effect magnitudes are game calibrations: **this is a game model, not a dosing tool.**

## Using it from other systems

```gdscript
# Admit (usually done by the ward/story system)
var pid: String = PharmacologyEngine.admit_patient_from_file("res://data/patients/PT-001.json")

# EHR: preview an order before signing (interaction text for the UI)
var report: Dictionary = PharmacologyEngine.preview_order(pid, "fluoxetine", 20.0)
# report.interactions[i].text -> "Aripiprazole exposure predicted to increase 1.7x via CYP2D6 ..."
# report.pharmacodynamic      -> ["Additive QTc prolongation with Citalopram: obtain ECG."]
# report.warnings             -> dose ceiling and phenotype notes

# EHR: sign the order (the engine listens for this signal)
EventBus.medication_ordered.emit(pid, {"drug_id": "fluoxetine", "daily_dose_mg": 20.0})
EventBus.medication_discontinued.emit(pid, "fluoxetine")

# Labs: therapeutic drug monitoring (also emits EventBus.lab_results_ready)
var level: Dictionary = PharmacologyEngine.measure_drug_level(pid, "clozapine")

# Story events
PharmacologyEngine.set_smoking(pid, true)       # smuggled cigarettes
PharmacologyEngine.set_inflammation(pid, true)  # pneumonia
PharmacologyEngine.set_egfr(pid, 45.0)          # dehydration / AKI
PharmacologyEngine.set_potassium(pid, 3.2)      # hypokalemia adds QTc risk
```

Time advances 12 hours on every `EventBus.shift_ended` (`GameState.advance_shift()`).

### Signals emitted

| Signal | When |
|---|---|
| `patient_admitted(patient_id)` | After admission |
| `patient_state_updated(patient_id, state)` | After every order, story event or shift |
| `clinical_alert_raised(patient_id, alert_id, severity)` | Only when an alert first appears or changes severity |
| `lab_results_ready(patient_id, "TDM_<drug>", result)` | After `measure_drug_level()` |
| `clue_unlocked(clue_id)` | Through `GameState.unlock_clue()` when a clue gate is met |

### `get_state(patient_id)` keys

`exposures` (drug → E, where 1.0 is the reference), `levels` (drug → plasma level for drugs with monitoring), `sedation`, `eps`, `akathisia`, `anticholinergic`, `serotonergic` (each 0–1), `qtc_ms`, `symptoms` {`psychosis`, `depression`, `mania`, `agitation`} (0–1, remaining severity), `interview_reliability` (0–1: how trustworthy interview answers are), `pathway_activity` (CYP → net activity, for showing phenoconversion in the EHR), and `alerts` [{`id`, `severity`, `message`}].

Alert ids: `QTC`, `SEDATION`, `EPS`, `AKATHISIA`, `ANTICHOLINERGIC`, `SEROTONIN_TOXICITY`, `LEVEL_<DRUG>`.

## Patient JSON schema (for ChatGPT / the narrative team)

```json
{
  "id": "PT-003",
  "name": "Display name",
  "age": 45, "sex": "M", "weight_kg": 80,
  "egfr": 95,                       // mL/min/1.73m²; 100 = normal clearance
  "baseline_qtc_ms": 420,
  "potassium_mmol_l": 4.2,
  "phenotypes": {"CYP2D6": "PM", "CYP2C19": "UM"},   // PM | IM | NM | RM | UM; missing = NM
  "smoking": {"cigarettes_per_day": 20, "smoking_on_ward": false},
  "inflammation": false,
  "baseline_symptoms": {"psychosis": 0.8, "depression": 0.2, "mania": 0.0, "agitation": 0.5},
  "home_medications": [
    {"drug_id": "olanzapine", "daily_dose_mg": 20, "at_steady_state": true}
  ],
  "clue_gates": [
    {"clue_id": "pt003_basement_key",
     "requires": {"psychosis_max": 0.3, "sedation_max": 0.5, "interview_reliability_min": 0.6,
                  "min_hours_treated": 72, "no_critical_alerts": true}}
  ]
}
```

Clue gate keys: `psychosis_max`, `depression_max`, `mania_max`, `agitation_max`, `sedation_max`, `interview_reliability_min`, `min_hours_treated`, `no_critical_alerts`. Use `drug_id` values from `data/drugs/drugs.json`.

## Adding a drug

Add an entry to `data/drugs/drugs.json`; no code changes are needed. Set the `reference_daily_dose_mg` and effects so that E = 1.0 is a typical therapeutic exposure in a normal metabolizer, then add a scenario to `tests/TestPharmacology.gd`.

## Tests

Open `tests/TestPharmacology.tscn` and press **F6** (Run Current Scene). Results print in the **Output** panel. The eight cases are: clozapine with smoking cessation, aripiprazole with fluoxetine, lithium with an NSAID and low eGFR, carbamazepine autoinduction plus quetiapine induction, QTc stacking, serotonin toxicity, fluoxetine washout, and the interaction preview text.
