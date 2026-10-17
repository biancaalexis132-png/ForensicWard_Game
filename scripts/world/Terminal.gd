class_name Terminal
extends Node3D
## Terminal: a workstation that opens a read-only info panel.
##
## Modes:
##   PATIENT_ROSTER  lists admitted patients (opens each record once per day)
##   CLUE_DOCUMENT   shows a clue's document and acquires it for the player
##   SYSTEM_STATUS   content validation report (useful during development)
## The full EHR UI is Sprint 2; this proves the interaction pipeline.

enum Mode { PATIENT_ROSTER, CLUE_DOCUMENT, SYSTEM_STATUS }

@export var terminal_id: String = ""
@export var title: String = "Terminal"
@export var mode: Mode = Mode.PATIENT_ROSTER
## For CLUE_DOCUMENT: the clue this terminal reveals.
@export var clue_id: String = ""

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interactable_id = terminal_id
	_interactable.prompt = "Use " + title
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(_interactor: Node) -> void:
	match mode:
		Mode.PATIENT_ROSTER:
			EventBus.ui_panel_requested.emit("info", {"title": title, "body": _roster_text()})
		Mode.CLUE_DOCUMENT:
			_show_clue()
		Mode.SYSTEM_STATUS:
			EventBus.ui_panel_requested.emit("info", {"title": title, "body": _status_text()})


func _roster_text() -> String:
	var lines: PackedStringArray = ["[b]Current census[/b]  (EHR record view arrives in Sprint 2)", ""]
	for patient_id: String in ContentRegistry.get_patient_ids():
		var patient: Dictionary = ContentRegistry.get_patient(patient_id)
		PatientManager.open_record(patient_id) # Deduped: once per patient per day.
		lines.append("[b]%s[/b], %d. Legal status: %s" % [patient["name"], patient["age"], patient["legal_status"].replace("_", " ")])
		lines.append("    Location: %s   Clinical content: %s" % [
			PatientManager.get_location(patient_id).replace("_", " "), patient["clinical_review_status"]])
		lines.append("    Presenting concerns: %s" % ", ".join(Array(patient["presentation"]["complaints"]).map(
				func(c: String) -> String: return c.replace("_", " "))))
	return "\n".join(lines)


func _show_clue() -> void:
	var clue: Dictionary = ContentRegistry.get_clue(clue_id)
	if clue.is_empty():
		push_error("Terminal %s: unknown clue '%s'" % [terminal_id, clue_id])
		return
	var is_new: bool = EvidenceManager.acquire_clue(clue_id, "terminal:" + terminal_id)
	EventBus.ui_panel_requested.emit("info", {"title": clue["title"], "body": ClueText.describe(clue)})
	if is_new:
		EventBus.notification_requested.emit("Evidence recorded: " + clue["title"])


func _status_text() -> String:
	var lines: PackedStringArray = []
	lines.append("Content valid: %s" % ("yes" if ContentRegistry.is_valid else "NO"))
	lines.append("Clinical build mode: %s" % ClinicalRules.build_mode)
	lines.append("Warnings: %d" % ContentRegistry.warnings.size())
	for message: String in ContentRegistry.warnings:
		lines.append("  - " + message)
	return "\n".join(lines)
