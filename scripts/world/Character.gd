class_name WardCharacter
extends Node3D
## WardCharacter: a greybox staff member or patient the player can approach.
##
## Staff: shows their authored intro line and grants any authored access
## (once, via TrustManager). Patients: opens the cinematic InterviewScreen.

enum Kind { STAFF, PATIENT }

@export var kind: Kind = Kind.STAFF
## staff id (data/staff.json) or patient id (data/patients.json).
@export var character_id: String = ""
## Seated on a chair that has its own collider: shorter silhouette, no body collision.
@export var seated: bool = false

@onready var _interactable: Interactable = $Interactable
@onready var _name_label: Label3D = $NameLabel


func _ready() -> void:
	if seated:
		# Scale only the visual: physics bodies must not be non-uniformly scaled.
		var mesh: Node3D = $Body/Mesh
		mesh.scale = Vector3(1.0, 0.65, 1.0)
		mesh.position.y = -0.1
		($Body/Collision as CollisionShape3D).disabled = true
		_name_label.position.y = 1.55
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
	EventBus.ui_panel_requested.emit("interview", {"patient_id": character_id})
