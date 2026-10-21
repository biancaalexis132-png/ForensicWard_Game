class_name WardCharacter
extends Node3D
## WardCharacter: a staff member or patient the player can approach.
## Optional imported visuals attach under VisualRoot; Body/Mesh remains the fallback.
##
## Staff: shows their authored intro line and grants any authored access
## (once, via TrustManager); the ChapterDirector may supply a situational
## line. Patients: opens the cinematic InterviewScreen.

enum Kind { STAFF, PATIENT }

## Every character in the world, for ConversationRange.
const GROUP: String = "ward_characters"

@export var kind: Kind = Kind.STAFF
## staff id (data/staff.json) or patient id (data/patients.json).
@export var character_id: String = ""
## Seated on a chair that has its own collider: shorter silhouette, no body collision.
@export var seated: bool = false
## Optional imported visual scene. The capsule stays only as a technical fallback:
## when a catalogued model fails it is shown as a development error, not a character.
@export var visual_scene: PackedScene
## Cosmetic model alignment, assigned before _ready by campaign casting.
var visual_placement: Transform3D = Transform3D.IDENTITY
## Optional StoryLogic condition: the character is only in the scene (visible,
## solid and interactable) while it holds. Re-checked whenever the objective
## changes, which includes every load.
var present_when: Dictionary = {}

@onready var _interactable: Interactable = $Interactable
@onready var _name_label: Label3D = $NameLabel
@onready var _placeholder_mesh: MeshInstance3D = $Body/Mesh
@onready var _visual_root: Node3D = $VisualRoot
var _naomi_acting: NaomiActingController
var _attached_visual: Node3D
var _visual_slot_ready: bool = false
## Why a catalogued model could not be shown ("" when there is no fault).
var visual_error: String = ""

## Magenta reads as "broken build" at a glance; no authored character uses it.
const MISSING_VISUAL_COLOR: Color = Color(1.0, 0.0, 0.85)
## Development errors already announced this session (one toast per actor id).
static var _announced_errors: Dictionary = {}


func _ready() -> void:
	add_to_group(GROUP)
	_visual_slot_ready = true
	if seated:
		# The legacy capsule is shortened; imported humanoid scenes stay unscaled.
		_placeholder_mesh.scale = Vector3(1.0, 0.65, 1.0)
		_placeholder_mesh.position.y = -0.1
		($Body/Collision as CollisionShape3D).disabled = true
		_name_label.position.y = 1.55
	_interactable.interactable_id = "character:" + character_id
	_interactable.interacted.connect(_on_interacted)
	if not present_when.is_empty():
		EventBus.objective_changed.connect(_update_presence.unbind(2))
		# Optional scenes set flags without moving the objective.
		EventBus.story_option_selected.connect(_on_story_option_selected)
		tree_entered.connect(_update_presence)
		_update_presence()
	var display_name: String = _display_name()
	_name_label.text = display_name
	_interactable.prompt = ("Talk to " if kind == Kind.STAFF else "Approach ") + display_name
	if visual_scene != null:
		if not set_visual_scene(visual_scene):
			mark_visual_missing("model could not be attached")
	elif not visual_error.is_empty():
		_show_visual_error()
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
	_attached_visual.transform = visual_placement * _attached_visual.transform
	CharacterAnimationRig.setup(_attached_visual)
	visual_scene = scene
	visual_error = ""
	_placeholder_mesh.material_override = null
	_placeholder_mesh.visible = false
	_name_label.text = _display_name()
	_name_label.modulate = Color(0.85, 0.9, 0.9, 0.85)
	return true


## Records a development error for a catalogued model that failed to load.
## Safe before or after _ready; the capsule turns magenta and is labelled.
func mark_visual_missing(reason: String) -> void:
	visual_error = reason
	# A warning, not push_error: the QA runner treats engine errors as test failures.
	push_warning("WardCharacter: DEVELOPMENT ERROR for %s: %s. Reimport assets in the Godot editor or update the checkout." % [character_id, reason])
	if _visual_slot_ready:
		_show_visual_error()


func _show_visual_error() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = MISSING_VISUAL_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_placeholder_mesh.material_override = material
	_placeholder_mesh.visible = true
	_name_label.text = "DEV ERROR: missing 3D model\n%s" % _display_name()
	_name_label.modulate = MISSING_VISUAL_COLOR
	if not _announced_errors.has(character_id):
		_announced_errors[character_id] = true
		EventBus.notification_requested.emit("Development error: %s's 3D model did not load (see the Output log)." % _display_name())


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


func is_present() -> bool:
	return visible


func _on_story_option_selected(_interaction_id: String, _option_id: String) -> void:
	# Deferred: ChapterDirector records the choice's flag in the same signal.
	_update_presence.call_deferred()


func _update_presence() -> void:
	if not is_inside_tree():
		return  # Re-checked on tree_entered (unloaded zones keep their characters).
	var director: Node = get_tree().get_first_node_in_group(ChapterDirector.GROUP)
	var present: bool = director == null or StoryLogic.evaluate(present_when, director.get_story_context())
	visible = present
	# Hidden alternate cast members must not keep evaluating skin/face/gaze rigs.
	process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED
	_interactable.enabled = present
	_interactable.collision_layer = (1 << (Interactable.INTERACTABLE_LAYER - 1)) if present else 0
	($Body/Collision as CollisionShape3D).disabled = seated or not present


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
	EventBus.ui_panel_requested.emit("info", {"title": staff.get("name", character_id), "body": body,
			"voice_speaker": character_id})


func _approach_patient() -> void:
	# A story scene with this patient (ChapterDirector opens it) replaces the interview.
	var director: Node = get_tree().get_first_node_in_group(ChapterDirector.GROUP)
	if director != null and director.has_open_interaction("character:" + character_id):
		return
	EventBus.ui_panel_requested.emit("interview", {"patient_id": character_id})
