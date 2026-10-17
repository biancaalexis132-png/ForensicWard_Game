class_name DrugProfile
extends RefCounted
## DrugProfile — immutable pharmacology data for one drug, parsed from
## res://data/drugs/drugs.json.
##
## All "effect" values are the effect produced at relative exposure E = 1.0,
## i.e. the steady-state exposure of a CYP normal-metabolizer adult with
## normal renal function taking `reference_daily_dose_mg`.
##
## Clearance model (Day 6 lecture, "The Interaction Equation"):
##     average exposure ∝ dose × F / CL
## CL is split into fractions (`pathways`) that each scale independently
## with genotype, inhibition, induction, inflammation and renal function.

## Pathway keys starting with this prefix are scaled by renal function (eGFR).
const RENAL_PREFIX: String = "RENAL"

var id: String = ""
var display_name: String = ""
var drug_class: String = ""

# --- Pharmacokinetics ------------------------------------------------------
var half_life_hours: float = 24.0
var reference_daily_dose_mg: float = 1.0
var max_daily_dose_mg: float = 0.0
## Fraction of clearance per pathway, e.g. {"CYP2D6": 0.5, "CYP3A4": 0.5}.
## Values should sum to ~1.0. Use "OTHER" for non-modelled routes (UGT etc.).
var pathways: Dictionary[String, float] = {}

# --- Perpetrator roles ------------------------------------------------------
## Pathway -> "weak" | "moderate" | "strong" (FDA interaction strength classes).
var inhibits: Dictionary[String, String] = {}
var induces: Dictionary[String, String] = {}

# --- Pharmacodynamics --------------------------------------------------------
## Effect channel -> magnitude at E = 1.0. See PharmacologyEngine.CHANNELS.
var effects: Dictionary[String, float] = {}
## Added QTc in milliseconds at E = 1.0 (scales linearly with exposure).
var qtc_ms: float = 0.0

# --- Therapeutic drug monitoring (optional) --------------------------------
var tdm_enabled: bool = false
var level_unit: String = ""
## Plasma level at E = 1.0.
var level_at_reference: float = 0.0
var therapeutic_range: Vector2 = Vector2.ZERO
var level_warning: float = INF
var level_critical: float = INF

var source_note: String = ""


static func from_dict(data: Dictionary) -> DrugProfile:
	var drug: DrugProfile = DrugProfile.new()
	drug.id = str(data.get("id", ""))
	drug.display_name = str(data.get("name", drug.id))
	drug.drug_class = str(data.get("class", ""))
	drug.half_life_hours = maxf(float(data.get("half_life_hours", 24.0)), 0.5)
	drug.reference_daily_dose_mg = maxf(float(data.get("reference_daily_dose_mg", 1.0)), 0.001)
	drug.max_daily_dose_mg = float(data.get("max_daily_dose_mg", 0.0))
	drug.qtc_ms = float(data.get("qtc_ms", 0.0))
	drug.source_note = str(data.get("source", ""))

	for key: String in data.get("pathways", {}):
		drug.pathways[key] = float(data["pathways"][key])
	for key: String in data.get("inhibits", {}):
		drug.inhibits[key] = str(data["inhibits"][key])
	for key: String in data.get("induces", {}):
		drug.induces[key] = str(data["induces"][key])
	for key: String in data.get("effects", {}):
		drug.effects[key] = float(data["effects"][key])

	var tdm: Dictionary = data.get("tdm", {})
	if not tdm.is_empty():
		drug.tdm_enabled = true
		drug.level_unit = str(tdm.get("unit", ""))
		drug.level_at_reference = float(tdm.get("level_at_reference", 0.0))
		var range_values: Array = tdm.get("therapeutic_range", [0.0, 0.0])
		drug.therapeutic_range = Vector2(float(range_values[0]), float(range_values[1]))
		drug.level_warning = float(tdm.get("warning_above", INF))
		drug.level_critical = float(tdm.get("critical_above", INF))
	return drug


func is_renal_pathway(pathway: String) -> bool:
	return pathway.begins_with(RENAL_PREFIX)


func get_effect(channel: String) -> float:
	return effects.get(channel, 0.0)
