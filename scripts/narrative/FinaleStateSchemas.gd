class_name FinaleStateSchemas
extends RefCounted
## In-memory validation contracts for the proposed Chapter 5 finale state.
## These schemas are not registered with SaveManager or ContentRegistry.

const VERSION: int = 1
const ENDINGS: Array[String] = [
	"independent_review",
	"restricted_access",
	"continuing_inquiry",
]
const CLINICAL_OUTCOMES: Array[String] = ["pending", "completed", "safely_escalated"]
const AUTHENTICATION_STATUSES: Array[String] = ["pending", "authenticated", "failed"]
const EVIDENCE_REVIEW_STATUSES: Array[String] = ["pending", "accepted", "unresolved", "disputed", "refuted"]
const REPORT_STATUSES: Array[String] = ["not_started", "draft", "reviewed"]

const _ID: Dictionary = {"type": "id"}
const _IDS: Dictionary = {"type": "array", "items": _ID}

const CLINICAL_TASK_CATALOG: Dictionary = {
	"type": "map",
	"values": {
		"type": "object",
		"required": {
			"clinical_review_status": {
				"type": "enum",
				"values": ["PENDING", "PENDING_PSYCHIATRIST_REVIEW", "APPROVED", "REJECTED"],
			},
		},
	},
}

const STATE: Dictionary = {
	"type": "object",
	"required": {
		"schema_version": {"type": "int", "const": VERSION},
		"clinical_tasks": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {
					"task_id": _ID,
					"outcome": {"type": "enum", "values": CLINICAL_OUTCOMES},
				},
			},
		},
		"evidence": {
			"type": "array",
			"items": {
				"type": "object",
				"required": {
					"evidence_id": _ID,
					"derived_from": _IDS,
					"authentication_status": {"type": "enum", "values": AUTHENTICATION_STATUSES},
					"review_status": {"type": "enum", "values": EVIDENCE_REVIEW_STATUSES},
				},
				"optional": {"source_id": _ID},
			},
		},
		"report_status": {"type": "enum", "values": REPORT_STATUSES},
		"decision": {
			"type": "enum",
			"values": ["none", "independent_review", "restricted_access", "continuing_inquiry"],
		},
		"completed": {"type": "bool"},
	},
}

const REQUIRED_TASK_IDS: Dictionary = {"type": "array", "items": _ID}
