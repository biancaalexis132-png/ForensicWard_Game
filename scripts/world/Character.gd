class_name WardCharacter
extends Node3D
## WardCharacter: a greybox staff member or patient the player can approach.
##
## Staff: shows their authored intro line and grants any authored access
## (once, via TrustManager). Patients: shows a short placeholder
## observation and starts DialogueManager. The cinematic Interview UI arrives
## in Sprint 2.

enum Kind { STAFF, PATIENT }

@export var kind: Kind = Kind.STAFF
## staff id (data/staff.json) or patient id (data/patients.json).
@export var character_id: String = ""

@onready var _interactable: Interactable = $Interactable
@onready var _name_label: Label3D = $NameLabel


func _ready() -> void:
	_interactable.interactable_id = "character:" + character_id
	_interactable.interacted.connect(_on_interacted)
	var display_name: String = _display_name()
	_name_label.text = display_name
	_interactable.prompt = ("Talk to " if kind == Kind.STAFF else "Approach ") + display_name


func _display_name() -> String:
	var data: Dictionary = ContentRegistry.get_staff(character_id) if kind == Kind.STAFF \
			else ContentRegistry.get_patient(character_id)
	return data.get("name", character_id)


func _on_interacted(_interactor: Node) -> void:
	if kind == Kind.STAFF:
		_talk_to_staff()
	else:
		_approach_patient()


func _talk_to_staff() -> void:
	var staff: Dictionary = ContentRegistry.get_staff(character_id)
	var body: String = "[i]%s[/i]\n\n%s" % [staff.get("role", ""), staff.get("intro_line", "...")]
	for access_id: String in staff.get("grants_access", []):
		if TrustManager.grant_access(access_id, character_id):
			EventBus.notification_requested.emit("Access granted: " + access_id.trim_prefix("access_").replace("_", " "))
	EventBus.ui_panel_requested.emit("info", {"title": staff.get("name", character_id), "body": body})


func _approach_patient() -> void:
	var patient: Dictionary = ContentRegistry.get_patient(character_id)
	DialogueManager.start_dialogue(character_id)
	var choices: PackedStringArray = []
	for choice: Dictionary in DialogueManager.get_choices():
		choices.append("  • " + choice["label"])
	DialogueManager.end_dialogue()
	# Only authored text is shown: no invented clinical description.
	var body: String = "[b]%s[/b], %d\n\n[b]Reported observations:[/b]\n" % [patient.get("name", ""), patient.get("age", 0)]
	for observation: Dictionary in patient.get("presentation", {}).get("observations", []):
		body += "  • %s (%s): %s\n" % [str(observation["source"]).replace("_", " "), observation["timestamp"], observation["text"]]
	body += "\n"
	body += "[b]Interview topics (Interview UI arrives in Sprint 2):[/b]\n" + "\n".join(choices)
	body += "\n\n[color=#9aa]Clinical content status: %s[/color]" % patient.get("clinical_review_status", "")
	EventBus.ui_panel_requested.emit("info", {"title": "Interview Room", "body": body})
