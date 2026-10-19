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
## Where a clue's information comes from. Testimony (a patient's report, a
## staff member's account) is recorded and shown, but never counts toward
## the anomaly evidence ladder (F0 audit section 7).
const SOURCE_CLASSES: Array[String] = ["instrument", "document", "physical", "access_log", "staff_testimony",
		"patient_report"]
const TESTIMONY_SOURCE_CLASSES: Array[String] = ["staff_testimony", "patient_report"]
## A clue's authored standing before the player verifies anything.
const CLAIM_STATES: Array[String] = ["reported", "verified", "corroborated", "disputed", "refuted", "unresolved"]
## Non-medical effects ClinicalRules knows how to apply. Medical effects have
## no vocabulary yet: none are approved.
const NON_MEDICAL_EFFECTS: Array[String] = ["mark_assessment_started", "mark_medical_review_requested"]

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
	"optional": {
		"rapport_delta": {"type": "number"},
		## Authored observations of this patient that the physician witnesses
		## when this question is asked (recorded with provenance "interview:<choice>").
		"records_observations": _IDS,
	},
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

## A coded action the physician can commit from the EHR Orders tab.
## Outcomes come only from ClinicalRules; the action itself carries no effect.
const CLINICAL_ACTION: Dictionary = {
	"type": "object",
	"required": {
		"id": _ID,
		"patient_id": _ID,
		"label": _STRING,
		"description": _STRING,
		"time_minutes": {"type": "number"},
		"clinical_review_status": _REVIEW,
	},
}

const CLINICAL_RULES_FILE: Dictionary = {
	"type": "object",
	"required": {"schema_version": _STRING, "rules": {"type": "array", "items": CLINICAL_RULE}},
	"optional": {"actions": {"type": "array", "items": CLINICAL_ACTION}},
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
				"optional": {
					"source_class": {"type": "enum", "values": SOURCE_CLASSES},
					"claim_state": {"type": "enum", "values": CLAIM_STATES},
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


## A planned chapter is listed for ids and saves but has no content yet.
## A playable chapter names its story and world files.
const CHAPTER_STATUSES: Array[String] = ["playable", "planned"]
const CHAPTER_ID_PATTERN: String = "^ch[0-9]+$"
## Stable id prefixes per content kind, checked across every file so ids
## stay unique and readable through all five chapters.
const ID_PREFIXES: Dictionary = {
	"interaction": "interaction_",
	"patient": "pt_", "staff": "staff_", "clue": "clue_", "hypothesis": "hyp_",
	"objective": "obj_", "beat": "beat_", "zone": "zone_", "connection": "conn_", "anomaly": "anom_",
}

## Campaign index: institution, chapters and the files each one loads
## (see data/campaign.json). File names are relative to the data folder.
const CAMPAIGN_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"institution": {"type": "object", "required": {"name": _STRING}, "optional": {"short_name": _STRING}},
		"start_chapter": _ID,
		"dialogue_files": {"type": "array", "min_items": 1, "items": _STRING},
		"chapters": {
			"type": "array", "min_items": 1,
			"items": {
				"type": "object",
				"required": {"id": _ID, "title": _STRING, "status": {"type": "enum", "values": CHAPTER_STATUSES}},
				"optional": {"story": _STRING, "world": _STRING, "provisional": {"type": "bool"}},
			},
		},
	},
	"optional": {"notes": _STRING},
}


## Authored world wiring: which imported environment nodes become doors,
## terminals, documents and characters (see data/world_chapter1.json).
const WORLD_INTERACTABLE_TYPES: Array[String] = ["ehr_terminal", "clue_terminal", "clue_pickup", "system_status",
		"shift_signout", "story_terminal"]

## Story conditions and actions are checked in depth by StoryLogic
## (vocabulary and references); here they only need to be objects.
const _CONDITION: Dictionary = {"type": "any"}
## The last chapter's closing summary: shown after its chapter_complete choice,
## with every line whose condition holds (decisions from any chapter).
const _CAMPAIGN_END: Dictionary = {
	"type": "object",
	"required": {
		"title": _STRING, "body": _STRING,
		"lines": {"type": "array", "items": {"type": "object", "required": {"when": _CONDITION, "text": _STRING}}},
	},
}
const _TRUST_CHANGE: Dictionary = {
	"type": "object",
	"required": {"staff_id": _ID, "axis": {"type": "enum", "values": ["respect", "trust", "suspicion"]},
			"delta": {"type": "number"}},
}

const _STORY_INTERACTION: Dictionary = {
	"type": "object",
	"required": {
		"id": _ID, "interactable_id": _STRING, "title": _STRING, "body": _STRING, "unavailable_body": _STRING,
		"when": _CONDITION,
		"options": {"type": "array", "min_items": 1, "items": {
			"type": "object", "required": {"id": _ID, "label": _STRING, "response": _STRING},
			## grants_access/revokes_access: scene-scoped passes, recorded with source "story:<interaction id>".
			"optional": {"flag": _ID, "grants_access": _IDS, "revokes_access": _IDS},
		}},
	},
	"optional": {"expires_when": _CONDITION, "completed_body": _STRING},
}

const STORY_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"chapter": _ID,
		"title": _STRING,
		"clinical_review_status": _REVIEW,
		"objectives": {
			"type": "array", "min_items": 1,
			"items": {
				"type": "object",
				"required": {"id": _ID, "text": _STRING, "complete_when": _CONDITION},
				"optional": {"expires_when": _CONDITION},
			},
		},
		"beats": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {"id": _ID, "when": _CONDITION, "actions": {"type": "array", "min_items": 1, "items": {"type": "any"}}},
				"optional": {"delay_minutes": {"type": "int"}},
			},
		},
		"staff_lines": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {"staff_id": _ID, "when": _CONDITION, "text": _STRING},
				"optional": {"verify_clue": _ID},
			},
		},
		"sign_out": {
			"type": "object",
			"required": {
				"title": _STRING, "handover_patients": _IDS,
				"documented_trust": {"type": "array", "items": _TRUST_CHANGE},
				"undocumented_trust": {"type": "array", "items": _TRUST_CHANGE},
				"undocumented_message": _STRING,
			},
		},
	},
	"optional": {"provisional": {"type": "bool"}, "notes": _STRING,
		"next_chapter": _ID, "interactions": {"type": "array", "items": _STORY_INTERACTION},
		"campaign_end": _CAMPAIGN_END},
}

const WORLD_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"world_id": _ID,
		## The zone the chapter starts in (data/zones.json); spawn_marker is in it.
		"start_zone": _ID,
		"spawn_marker": _STRING,
		"doors": {
			"type": "map",
			"values": {
				"type": "object",
				"required": {"display_name": _STRING},
				"optional": {"open_angle_degrees": {"type": "number"}, "locked_message": _STRING, "zone": _ID},
			},
		},
		"interactables": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {"node": _STRING, "type": {"type": "enum", "values": WORLD_INTERACTABLE_TYPES}},
				"optional": {"title": _STRING, "clue_id": _ID, "zone": _ID},
			},
		},
		"characters": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {"marker": _STRING, "kind": {"type": "enum", "values": ["staff", "patient"]},
						"character_id": _ID},
				## present_when: StoryLogic condition; the character is in the scene only while it holds.
				"optional": {"seated": {"type": "bool"}, "zone": _ID, "present_when": _CONDITION,
					"interaction_box": {"type": "object", "required": {
						"center": {"type": "array", "items": {"type": "number"}, "min_items": 3},
						"size": {"type": "array", "items": {"type": "number"}, "min_items": 3},
					}}},
			},
		},
	},
	## Entries name nodes inside one zone's environments: "zone" says which,
	## and defaults to start_zone. They are wired when that zone loads.
	"optional": {
		"flicker_lights": _STRINGS,
		"notes": _STRING,
	},
}


## Zones and connections (see data/zones.json and ZoneDirector).
## Zones on different levels share floor-plan coordinates, so they never
## load together; zones on one level must not overlap.
const ZONE_LEVELS: Array[String] = ["ground", "research", "sublevel", "exterior"]
const ZONE_STATUSES: Array[String] = ["built", "placeholder"]
## seamless: same level, walk through, no fade. fade: swap the loaded zones.
const ZONE_TRANSITIONS: Array[String] = ["seamless", "fade"]
const CONNECTION_KINDS: Array[String] = ["door", "lift", "hatch", "corridor"]
const _XZ: Dictionary = {"type": "array", "min_items": 2, "items": {"type": "number"}}
const _RECT: Dictionary = {"type": "object", "required": {"min_xz": _XZ, "max_xz": _XZ}}

const ZONES_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		"zones": {
			"type": "array", "min_items": 1,
			"items": {
				"type": "object",
				"required": {
					"id": _ID, "title": _STRING,
					"level": {"type": "enum", "values": ZONE_LEVELS},
					"status": {"type": "enum", "values": ZONE_STATUSES},
					"environments": _STRINGS,
					"bounds": {"type": "array", "items": _RECT},
				},
				"optional": {
					## AudioDirector location per floor-plan rectangle; anywhere
					## else in the zone uses default_audio_location.
					"default_audio_location": _ID,
					"audio_zones": {
						"type": "array",
						"items": {"type": "object", "required": {"location": _ID, "min_xz": _XZ, "max_xz": _XZ}},
					},
					"notes": _STRING,
				},
			},
		},
		"connections": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {
					"id": _ID,
					"kind": {"type": "enum", "values": CONNECTION_KINDS},
					"transition": {"type": "enum", "values": ZONE_TRANSITIONS},
					"ends": {
						"type": "array", "min_items": 2,
						"items": {
							"type": "object",
							"required": {"zone": _ID},
							"optional": {
								"node": _STRING, "prompt": _STRING,
								"arrival": {
									"type": "object",
									"required": {"position": {"type": "array", "min_items": 3, "items": {"type": "number"}}},
									"optional": {"yaw_degrees": {"type": "number"}},
								},
								"placeholder_arrival": {"type": "bool"},
							},
						},
					},
				},
				"optional": {
					"door_id": _ID, "door_zone": _ID, "anchor_xz": _XZ,
					"required_access": _ID, "locked_message": _STRING, "notes": _STRING,
				},
			},
		},
	},
	"optional": {"notes": _STRING},
}


## Anomaly evidence (data/anomalies.json, AnomalyLedger). The anomaly is a
## property of places, instruments and time: an episode's condition may only
## use these StoryLogic kinds, never patients, clinical actions, notes,
## staff relationships or the physician's strain.
const ANOMALY_CONDITIONS: Array[String] = ["shift", "day", "flag", "clue_acquired", "hypothesis_supported",
		"chapter_completed", "chapter_flag", "zone", "world_state", "all", "any"]
## How an episode shows itself. Each has a plausible mundane reading, which
## Chapter 1 needs (a sound, a device log entry, a changed room).
const ANOMALY_MANIFESTATIONS: Array[String] = ["audio_event", "device_log", "world_state"]
## The evidence ladder, lowest first. It is computed from evidence, never set
## by dialogue. "accepted" is not reachable from evidence alone yet.
const ANOMALY_LEVELS: Array[String] = ["none", "reported", "inconsistent_records", "instrumented", "corroborated",
		"accepted"]
## Chapter 1 stays ambiguous: its cap may not rise above this.
const ANOMALY_CHAPTER1_MAX_LEVEL: String = "reported"

const ANOMALIES_FILE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": _STRING,
		## Highest ladder level each chapter may reach; a chapter not listed stays at "none".
		"chapter_caps": {"type": "map", "values": {"type": "enum", "values": ANOMALY_LEVELS}},
		"episodes": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {
					"id": _ID, "chapter": _ID, "zone": _ID, "title": _STRING,
					"when": {"type": "any"},
					"manifestations": {"type": "array", "min_items": 1, "items": {"type": "any"}},
					"readings": _IDS,
				},
				"optional": {"notes": _STRING, "mundane_readings": _STRINGS},
			},
		},
	},
	"optional": {"notes": _STRING},
}
