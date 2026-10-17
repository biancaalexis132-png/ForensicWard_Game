class_name ImportedInteractable
extends Node
## ImportedInteractable: makes an imported Blender prop usable with E.
##
## Added as a child of the prop's root node. Builds an Interactable whose box
## covers the prop's meshes (padded so the ray reaches it before any desk
## collider underneath) and dispatches to WorldActions by type:
##   ehr_terminal   opens the EHR screen
##   clue_terminal  reveals a clue from a terminal/panel
##   clue_pickup    reveals a clue and removes the physical document
##   system_status  content/debug report
##   shift_signout  shift handover board (ChapterDirector.sign_out)

const PADDING: float = 0.12
const MIN_SIZE: float = 0.3

var kind: String = ""
var title: String = ""
var clue_id: String = ""
var interactable: Interactable = null

var _target: Node3D = null


func setup(target: Node3D, config: Dictionary) -> void:
	_target = target
	kind = str(config["type"])
	clue_id = str(config.get("clue_id", ""))
	var clue: Dictionary = ContentRegistry.get_clue(clue_id) if not clue_id.is_empty() else {}
	title = str(config.get("title", clue.get("title", target.name)))
	interactable = Interactable.new()
	interactable.name = "Interactable"
	interactable.interactable_id = target.name
	interactable.prompt = ("Take " if kind == "clue_pickup" else "Use ") + title
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	var aabb: AABB = _local_mesh_aabb(target)
	box.size = Vector3(maxf(aabb.size.x + PADDING, MIN_SIZE), maxf(aabb.size.y + PADDING, MIN_SIZE),
			maxf(aabb.size.z + PADDING, MIN_SIZE))
	shape.shape = box
	shape.position = aabb.get_center()
	interactable.add_child(shape)
	target.add_child(interactable)
	interactable.interacted.connect(_on_interacted)
	if kind == "clue_pickup":
		EventBus.game_loaded.connect(func(_slot: int) -> void: _refresh())
		_refresh()


func _on_interacted(_interactor: Node) -> void:
	match kind:
		"ehr_terminal":
			WorldActions.open_ehr(title)
		"clue_terminal":
			WorldActions.reveal_clue(clue_id, "terminal:" + _target.name)
		"clue_pickup":
			WorldActions.reveal_clue(clue_id, "pickup:" + _target.name)
			_refresh()
		"system_status":
			WorldActions.show_system_status(title)
		"shift_signout":
			EventBus.shift_signout_requested.emit()


## Picked-up documents disappear; state comes from EvidenceManager, so it is
## always correct after loading a save.
func _refresh() -> void:
	var taken: bool = EvidenceManager.has_clue(clue_id)
	_target.visible = not taken
	interactable.enabled = not taken
	interactable.monitorable = not taken


func _local_mesh_aabb(root: Node3D) -> AABB:
	var result: AABB = AABB()
	var first: bool = true
	for node: Node in [root] + root.find_children("*", "MeshInstance3D", true, false):
		if not node is MeshInstance3D or (node as MeshInstance3D).mesh == null:
			continue
		var mesh_instance: MeshInstance3D = node
		var xf: Transform3D = root.global_transform.affine_inverse() * mesh_instance.global_transform \
				if root.is_inside_tree() else Transform3D.IDENTITY
		var aabb: AABB = xf * mesh_instance.get_aabb()
		result = aabb if first else result.merge(aabb)
		first = false
	return result if not first else AABB(Vector3(-0.15, 0, -0.15), Vector3(0.3, 0.3, 0.3))
