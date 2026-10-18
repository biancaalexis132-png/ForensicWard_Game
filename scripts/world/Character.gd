class_name WardCharacter
extends Node3D
## WardCharacter: a greybox staff member or patient the player can approach.
## Optional imported visuals attach under VisualRoot; Body/Mesh remains the fallback.
##
## Staff: shows their authored intro line and grants any authored access
## (once, via TrustManager); the ChapterDirector may supply a situational
## line. Patients: opens the cinematic InterviewScreen.

enum Kind { STAFF, PATIENT }

@export var kind: Kind = Kind.STAFF
## staff id (data/staff.json) or patient id (data/patients.json).
@export var character_id: String = ""
## Seated on a chair that has its own collider: shorter silhouette, no body collision.
@export var seated: bool = false
## Optional imported visual scene. The placeholder remains available as a fallback.
@export var visual_scene: PackedScene

@onready var _interactable: Interactable = $Interactable
@onready var _name_label: Label3D = $NameLabel
@onready var _placeholder_mesh: MeshInstance3D = $Body/Mesh
@onready var _visual_root: Node3D = $VisualRoot
var _naomi_acting: NaomiActingController
var _attached_visual: Node3D
var _visual_slot_ready: bool = false


func _ready() -> void:
	_visual_slot_ready = true
	if seated:
		# The legacy capsule is shortened; imported humanoid scenes stay unscaled.
		_placeholder_mesh.scale = Vector3(1.0, 0.65, 1.0)
		_placeholder_mesh.position.y = -0.1
		($Body/Collision as CollisionShape3D).disabled = true
		_name_label.position.y = 1.55
	_interactable.interactable_id = "character:" + character_id
	_interactable.interacted.connect(_on_interacted)
	var display_name: String = _display_name()
	_name_label.text = display_name
	_interactable.prompt = ("Talk to " if kind == Kind.STAFF else "Approach ") + display_name
	if visual_scene != null:
		set_visual_scene(visual_scene)
	else:
		# Review-only: off unless the game was started with --character-preview.
		var preview: PackedScene = CharacterVisualPreview.scene_for(character_id)
		if preview != null and set_visual_scene(preview):
			_attached_visual.transform = CharacterVisualPreview.placement_for(character_id) * _attached_visual.transform
	if kind == Kind.STAFF and character_id == "staff_bennett":
		_naomi_acting = NaomiActingController.new()
		_naomi_acting.name = "NaomiActingController"
		_naomi_acting.actor_root = self
		add_child(_naomi_acting)


func set_visual_scene(scene: PackedScene) -> bool:
	if scene == null:
		push_warning("WardCharacter: visual scene is null for %s; keeping placeholder" % character_id)
		return false
	if not _visual_slot_ready:
		visual_scene = scene
		return true
	var instance: Node = scene.instantiate()
	if instance == null or not instance is Node3D:
		push_warning("WardCharacter: visual scene root must be Node3D for %s; keeping placeholder" % character_id)
		if instance != null:
			instance.free()
		return false
	var visual_root: Node3D = instance as Node3D
	if not _has_renderable_mesh(visual_root):
		push_warning("WardCharacter: visual scene has no renderable mesh for %s; keeping placeholder" % character_id)
		visual_root.free()
		return false
	_remove_attached_visual()
	_attached_visual = visual_root
	_visual_root.add_child(_attached_visual)
	CharacterAnimationRig.setup(_attached_visual)
	visual_scene = scene
	_placeholder_mesh.visible = false
	return true


func clear_visual_scene() -> void:
	visual_scene = null
	if not _visual_slot_ready:
		return
	_remove_attached_visual()
	_placeholder_mesh.visible = true


func _has_renderable_mesh(root: Node3D) -> bool:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
			return true
	return false


func _remove_attached_visual() -> void:
	if is_instance_valid(_attached_visual):
		if _attached_visual.get_parent() == _visual_root:
			_visual_root.remove_child(_attached_visual)
		_attached_visual.queue_free()
	_attached_visual = null


func _display_name() -> String:
	var data: Dictionary = ContentRegistry.get_staff(character_id) if kind == Kind.STAFF \
			else ContentRegistry.get_patient(character_id)
	return data.get("name", character_id)


func _on_interacted(_interactor: Node) -> void:
	if kind == Kind.STAFF:
		if is_instance_valid(_naomi_acting):
			_naomi_acting.begin_conversation()
		_talk_to_staff()
	else:
		_approach_patient()


func _talk_to_staff() -> void:
	var staff: Dictionary = ContentRegistry.get_staff(character_id)
	var text: String = staff.get("intro_line", "...")
	# The chapter's story data can give a situational line instead.
	var director: Node = get_tree().get_first_node_in_group(ChapterDirector.GROUP)
	var line: Dictionary = director.get_staff_line(character_id) if director != null else {}
	if not line.is_empty():
		text = line["text"]
		var clue_id: String = line.get("verify_clue", "")
		if not clue_id.is_empty() and EvidenceManager.add_verification(clue_id, "staff_testimony:" + character_id):
			EventBus.notification_requested.emit("Corroborated: " + ContentRegistry.get_clue(clue_id)["title"])
	var body: String = "[i]%s[/i]\n\n%s" % [staff.get("role", ""), text]
	for access_id: String in staff.get("grants_access", []):
		if TrustManager.grant_access(access_id, character_id):
			EventBus.notification_requested.emit("Access granted: " + access_id.trim_prefix("access_").replace("_", " "))
	EventBus.ui_panel_requested.emit("info", {"title": staff.get("name", character_id), "body": body})


func _approach_patient() -> void:
	EventBus.ui_panel_requested.emit("interview", {"patient_id": character_id})
