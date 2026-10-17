class_name WorldActions
extends RefCounted
## WorldActions: shared behaviour behind world interactables, used by both
## the greybox props (Terminal, CluePickup) and imported Blender props
## (ImportedInteractable), so they cannot drift apart.


## Opens the EHR at a workstation. The record-opened audit event is logged
## once per patient per day when a chart is viewed (PatientManager dedupes).
static func open_ehr(title: String) -> void:
	EventBus.ui_panel_requested.emit("ehr", {"title": title})


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
