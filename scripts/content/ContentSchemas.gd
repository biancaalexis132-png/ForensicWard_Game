class_name ContentSchemas
extends RefCounted
## Load contracts for every file in res://data/.
##
## A schema is a Dictionary with a "type" key:
##   "object"  required: {field: schema}, optional: {field: schema}
##   "array"   items: schema, min_items: int
##   "map"     values: schema (object with arbitrary string keys)
##   "string"  non-empty unless allow_empty
##   "id"      stable identifier: lowercase letters, digits, underscores
##   "int", "number", "bool", "any"
##   "enum"    values: [allowed strings]
## Optional "const" forces an exact value (e.g. fictional = true).
## Unknown object fields produce warnings, not errors, so content can add
## fields ahead of code.

const ID_PATTERN: String = "^[a-z][a-z0-9_]*$"

const REVIEW_STATUSES: Array[String] = [
	"PENDING", "PENDING_PSYCHIATRIST_REVIEW", "APPROVED", "REJECTED",
]
## Where a patient can physically be. One value at a time, so a patient can
## never be in two places at once (MVP acceptance test 9).
const PATIENT_LOCATIONS: Array[String] = [
	"clinical_unit", "interview_room", "medical_unit", "seclusion", "ward_zero", "transferred_out",
]
const HYPOTHESIS_STATUSES: Array[String] = ["unresolved", "supported", "refuted"]
## Non-medical effects ClinicalRules knows how to apply. Medical effects have
## no vocabulary yet: none are approved.
const NON_MEDICAL_EFFECTS: Array[String] = ["mark_assessment_started"]

const _STRING: Dictionary = {"type": "string"}
const _ID: Dictionary = {"type": "id"}
const _STRINGS: Dictionary = {"type": "array", "items": _STRING}
const _IDS: Dictionary = {"type": "array", "items": _ID}
const _REVIEW: Dictionary = {"type": "enum", "values": REVIEW_STATUSES}

const OBSERVATION: Dictionary = {
	"type": "object",
	"required": {"id": _ID, "source": _STRING, "timestamp": _STRING, "text": _STRING},
	"optional": {"author": _STRING, "verified": {"type": "bool"}, "reliability": _STRING, "provenance": _STRING},
}

const PATIENT: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"id": _ID,
		"name": _STRING,
		"age": {"type": "int"},
		"fictional": {"type": "bool", "const": true},
		"legal_status": _STRING,
		"arrival_shift": {"type": "int"},
		"presentation": {
			"type": "object",
			"required": {
				"complaints": _STRINGS,
				"observations": {"type": "array", "items": OBSERVATION},
			},
		},
		"differential_tags": _STRINGS,
		"clinical_review_status": _REVIEW,
		"initial_rapport": {"type": "number"},
		"current_location": {"type": "enum", "values": PATIENT_LOCATIONS},
	},
	"optional": {
		"record_discrepancies": _STRINGS,
		"narrative_flags": _STRINGS,
		"must_not_auto_transfer_if": _STRING,
	},
}

const PATIENTS_FILE: Dictionary = {
	"type": "object",
	"required": {"patients": {"type": "array", "min_items": 1, "items": PATIENT}},
}

const DIALOGUE_CHOICE: Dictionary = {
	"type": "object",
	"required": {
		"id": _ID,
		"label": _STRING,
		"intents": {"type": "array", "min_items": 1, "items": _ID},
		"response": _STRING,
		"next": _ID,
	},
	"optional": {"rapport_delta": {"type": "number"}},
}

const DIALOGUE_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"patient_id": _ID,
		"states": {
			"type": "array", "min_items": 1,
			"items": {
				"type": "object",
				"required": {"id": _ID, "choices": {"type": "array", "items": DIALOGUE_CHOICE}},
			},
		},
		"fallback_response": _STRING,
		"clinical_review_status": _REVIEW,
	},
}

const CLINICAL_RULE: Dictionary = {
	"type": "object",
	"required": {
		"id": _ID,
		"review_status": _REVIEW,
		"trigger_action": _ID,
		"patient_id": _ID,
		"condition": {"type": "object", "optional": {"observations_present": _IDS}},
		"non_medical_effects": {"type": "array", "items": {"type": "enum", "values": NON_MEDICAL_EFFECTS}},
		"medical_effects": {"type": "array", "items": {"type": "any"}},
		"source_catalog_ids": _IDS,
	},
	"optional": {"notice": _STRING},
}

const CLINICAL_RULES_FILE: Dictionary = {
	"type": "object",
	"required": {"schema_version": _STRING, "rules": {"type": "array", "items": CLINICAL_RULE}},
}

const CLUES_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"clues": {
			"type": "array", "min_items": 1,
			"items": {
				"type": "object",
				"required": {
					"id": _ID, "title": _STRING, "source": _STRING, "provenance": _STRING,
					"verified": {"type": "bool"}, "description": _STRING,
				},
			},
		},
		"hypotheses": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {
					"id": _ID, "title": _STRING, "required_clues": {"type": "array", "min_items": 1, "items": _ID},
					"status": {"type": "enum", "values": HYPOTHESIS_STATUSES},
					"alternate_explanations": _STRINGS,
				},
			},
		},
	},
}

const SOURCE_CATALOG_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"review_state": _STRING,
		"items": {
			"type": "array",
			"items": {"type": "object", "required": {"id": _ID, "title": _STRING, "use": _STRING}},
		},
	},
}

const STAFF_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"staff": {
			"type": "array", "min_items": 1,
			"items": {
				"type": "object",
				"required": {
					"id": _ID, "name": _STRING, "role": _STRING,
					"initial_trust": {
						"type": "object",
						"required": {"respect": {"type": "number"}, "trust": {"type": "number"}, "suspicion": {"type": "number"}},
					},
				},
				"optional": {"intro_line": _STRING, "grants_access": _IDS},
			},
		},
	},
	"optional": {"provisional": {"type": "bool"}},
}

const INTENT_LEXICON_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"stopwords": _STRINGS,
		"synonyms": {"type": "map", "values": _STRINGS},
	},
	"optional": {"notes": _STRING},
}
