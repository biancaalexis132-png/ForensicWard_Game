class_name WorldActions
extends RefCounted
## WorldActions: shared behaviour behind world interactables, used by both
## the greybox props (Terminal, CluePickup) and imported Blender props
## (ImportedInteractable), so they cannot drift apart.


## EHR census placeholder. Opening it logs one record-opened event per
## patient per day (deduped by PatientManager).
static func open_ehr_census(title: String) -> void:
	var lines: PackedStringArray = ["[b]Current census[/b]  (full EHR record view arrives in Sprint 2)", ""]
	for patient_id: String in ContentRegistry.get_patient_ids():
		var patient: Dictionary = ContentRegistry.get_patient(patient_id)
		PatientManager.open_record(patient_id)
		lines.append("[b]%s[/b], %d. Legal status: %s" % [patient["name"], patient["age"],
				patient["legal_status"].replace("_", " ")])
		lines.append("    Location: %s   Clinical content: %s" % [
			PatientManager.get_location(patient_id).replace("_", " "), patient["clinical_review_status"]])
		lines.append("    Presenting concerns: %s" % ", ".join(Array(patient["presentation"]["complaints"]).map(
				func(c: String) -> String: return c.replace("_", " "))))
	EventBus.ui_panel_requested.emit("info", {"title": title, "body": "\n".join(lines)})


## Shows a clue's document and records it with provenance. Returns true if
## it was newly acquired.
static func reveal_clue(clue_id: String, provenance: String) -> bool:
	var clue: Dictionary = ContentRegistry.get_clue(clue_id)
	if clue.is_empty():
		push_error("WorldActions: unknown clue '%s' (%s)" % [clue_id, provenance])
		return false
	var is_new: bool = EvidenceManager.acquire_clue(clue_id, provenance)
	EventBus.ui_panel_requested.emit("info", {"title": clue["title"], "body": ClueText.describe(clue)})
	if is_new:
		EventBus.notification_requested.emit("Evidence recorded: " + clue["title"])
	return is_new


static func show_system_status(title: String) -> void:
	var lines: PackedStringArray = []
	lines.append("Content valid: %s" % ("yes" if ContentRegistry.is_valid else "NO"))
	lines.append("Clinical build mode: %s" % ClinicalRules.build_mode)
	lines.append("Warnings: %d" % ContentRegistry.warnings.size())
	for message: String in ContentRegistry.warnings:
		lines.append("  - " + message)
	EventBus.ui_panel_requested.emit("info", {"title": title, "body": "\n".join(lines)})
