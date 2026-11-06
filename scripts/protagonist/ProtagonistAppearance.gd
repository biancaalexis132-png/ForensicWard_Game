class_name ProtagonistAppearance
extends RefCounted
## Dresses a psychiatrist model (Psychiatrist_Female/Male_v01_draft.glb) to match a
## profile: skin, hair colour and style, shirt, trousers and glasses. Shared by the
## character creator's preview and the encounter stage, so both show the same person.
##
## Hair styles borrow hair meshes from either model. Both rigs share bone names, so
## a borrowed mesh is rebound to the wearer's skeleton and fitted so the borrowed
## hair cap covers exactly where the wearer's own cap sits (their heads differ in size).
## Presentation only: no clinical or competence effect.

## Average albedo of each part as built (texture mean), so a tint can aim for a colour.
const BUILT_SKIN: Color = Color("#B98463")
const BUILT_HAIR: Color = Color("#533A28")
const BUILT_TROUSERS: Color = Color("#263C55")
const BUILT_SHIRT: Color = Color("#D6DADE")

const MODEL_SCENES: Dictionary = {
	"female": "res://assets/exports/characters/Psychiatrist_Female_v01_draft.glb",
	"male": "res://assets/exports/characters/Psychiatrist_Male_v01_draft.glb",
}
## Each model's main hair mesh: the cap that fits borrowed hair to a head.
const HAIR_CAPS: Dictionary = {"female": "PsyF_Hair", "male": "PsyM_Hair"}
## hair_style id -> [model the hair comes from, mesh names].
const HAIR_STYLES: Dictionary = {
	"short": ["male", ["PsyM_Hair"]],
	"long": ["female", ["PsyF_Hair", "PsyF_Hair_Ponytail", "PsyF_Hair_Tie"]],
	"swept": ["female", ["PsyF_Hair", "PsyF_Hair_Tie"]],
	"none": ["", []],
}
## glasses id -> [lens radius m, rim thickness m, square lenses, frame colour].
const GLASSES: Dictionary = {
	"round": [0.0175, 0.0016, false, Color("#8a7a62")],
	"rectangular": [0.0165, 0.0014, true, Color("#3c3f44")],
	"bold": [0.0185, 0.0032, true, Color("#151517")],
}
const BORROWED_META: String = "protagonist_borrowed"

## Mesh nodes from each model, kept so borrowing hair does not reload the scene.
static var _source_cache: Dictionary = {}


## Applies `profile` to `root`, any node that contains a psychiatrist model. Safe to
## call again with a new profile: earlier tints, borrowed hair and glasses are replaced.
static func apply(root: Node, profile: Dictionary, options: Dictionary) -> void:
	var skeleton: Skeleton3D = _skeleton(root)
	if skeleton == null:
		return
	for child: Node in skeleton.get_children():
		if child.has_meta(BORROWED_META):
			child.free()
	var skin: Color = _colour(options, "skin_tones", profile.get("skin_tone"), BUILT_SKIN)
	var hair: Color = _colour(options, "hair_colors", profile.get("hair_color"), BUILT_HAIR)
	var trousers: Color = _colour(options, "outfits", profile.get("outfit"), BUILT_TROUSERS)
	var shirt: Color = _colour(options, "tops", profile.get("top"), BUILT_SHIRT)
	var style: Array = HAIR_STYLES.get(str(profile.get("hair_style", "")), HAIR_STYLES["short"])
	var wearer: String = _model_of(skeleton)
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		var mesh_name: String = mesh.name.to_lower()
		if mesh_name.ends_with("_body"):
			_tint(mesh, _ratio(skin, BUILT_SKIN), 0)
		elif mesh_name.contains("_hair"):
			mesh.visible = style[0] == wearer and mesh.name in style[1]
			_tint(mesh, _ratio(hair, BUILT_HAIR))
		elif mesh_name.ends_with("_trousers"):
			_tint(mesh, _ratio(trousers, BUILT_TROUSERS))
		elif mesh_name.ends_with("_shirt"):
			_tint(mesh, _ratio(shirt, BUILT_SHIRT))
	if not str(style[0]).is_empty() and style[0] != wearer and not wearer.is_empty():
		for mesh_name: String in style[1]:
			var borrowed: MeshInstance3D = _borrow(skeleton, str(style[0]), mesh_name)
			if borrowed != null:
				_tint(borrowed, _ratio(hair, BUILT_HAIR))
	var frames: Array = GLASSES.get(str(profile.get("glasses", "none")), [])
	if not frames.is_empty():
		_add_glasses(skeleton, frames)


## "female", "male", or "" when the skeleton is not one of the psychiatrist rigs.
static func _model_of(skeleton: Skeleton3D) -> String:
	for mesh: Node in skeleton.get_children():
		if mesh.name.begins_with("PsyF_") or mesh.name == "Psychiatrist_Female_Body":
			return "female"
		if mesh.name.begins_with("PsyM_") or mesh.name == "Psychiatrist_Male_Body":
			return "male"
	return ""


static func _skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root
	for node: Node in root.find_children("*", "Skeleton3D", true, false):
		return node as Skeleton3D
	return null


static func _colour(options: Dictionary, catalog: String, id: Variant, fallback: Color) -> Color:
	var value: String = str(options.get(catalog, {}).get(id, ""))
	return Color(value) if value.begins_with("#") else fallback


static func _ratio(wanted: Color, built: Color) -> Color:
	return Color(wanted.r / maxf(built.r, 0.02), wanted.g / maxf(built.g, 0.02), wanted.b / maxf(built.b, 0.02))


## Tints the given surface (or every surface) through override materials, so the
## imported materials and other characters sharing them are left untouched. A
## single-surface mesh takes a material_override: the headless renderer errors when
## a node freed in the same frame carries a surface override.
static func _tint(mesh: MeshInstance3D, tint: Color, only_surface: int = -1) -> void:
	if mesh.mesh == null:
		return
	if mesh.mesh.get_surface_count() == 1 and only_surface <= 0:
		var single: StandardMaterial3D = mesh.mesh.surface_get_material(0) as StandardMaterial3D
		if single != null:
			var tinted: StandardMaterial3D = single.duplicate() as StandardMaterial3D
			tinted.albedo_color = single.albedo_color * tint
			mesh.material_override = tinted
		return
	for surface: int in mesh.mesh.get_surface_count():
		if only_surface >= 0 and surface != only_surface:
			continue
		var base: StandardMaterial3D = mesh.mesh.surface_get_material(surface) as StandardMaterial3D
		if base == null:
			continue
		var copy: StandardMaterial3D = base.duplicate() as StandardMaterial3D
		copy.albedo_color = base.albedo_color * tint
		mesh.set_surface_override_material(surface, copy)


static func _source(model: String) -> Dictionary:
	if _source_cache.has(model):
		return _source_cache[model]
	var found: Dictionary = {"meshes": {}, "eyes": Vector3.ZERO, "cap": AABB()}
	var scene: PackedScene = load(str(MODEL_SCENES.get(model, ""))) as PackedScene if ResourceLoader.exists(str(MODEL_SCENES.get(model, ""))) else null
	if scene != null:
		var instance: Node = scene.instantiate()
		var skeleton: Skeleton3D = _skeleton(instance)
		if skeleton != null:
			found["eyes"] = _eye_centre(skeleton)
			for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
				found["meshes"][str(mesh.name)] = {"mesh": mesh.mesh, "skin": mesh.skin}
				if mesh.name == HAIR_CAPS.get(model, ""):
					found["cap"] = mesh.get_aabb()
		instance.free()
	_source_cache[model] = found
	return found


## Midpoint between the eyes, in skeleton space at rest.
static func _eye_centre(skeleton: Skeleton3D) -> Vector3:
	var left: int = skeleton.find_bone("eye_l")
	var right: int = skeleton.find_bone("eye_r")
	if left < 0 or right < 0:
		var head: int = skeleton.find_bone("head")
		return skeleton.get_bone_global_rest(head).origin if head >= 0 else Vector3.ZERO
	return (skeleton.get_bone_global_rest(left).origin + skeleton.get_bone_global_rest(right).origin) * 0.5


## The rest-space transform that lays `model`'s hair cap over `wearer`'s: scale and
## move the borrowed cap's box onto the wearer's own cap box. Falls back to lining
## up the eyes when either box is unknown.
static func hair_fit(model: String, wearer: String, wearer_eyes: Vector3) -> Transform3D:
	var source: Dictionary = _source(model)
	var from: AABB = source["cap"]
	var to: AABB = _source(wearer)["cap"] if not wearer.is_empty() else AABB()
	if from.size.x <= 0.0 or to.size.x <= 0.0:
		return Transform3D(Basis.IDENTITY, wearer_eyes - (source["eyes"] as Vector3))
	var scale: Vector3 = to.size / from.size
	return Transform3D(Basis.from_scale(scale), to.position - from.position * scale)


## Puts one of the other model's hair meshes on this skeleton. Each bind is replaced
## by this skeleton's own inverse rest pose times the cap fit, so at rest the hair
## covers the wearer's head and moves with the wearer's bones once they animate.
static func _borrow(skeleton: Skeleton3D, model: String, mesh_name: String) -> MeshInstance3D:
	var source: Dictionary = _source(model)
	var entry: Dictionary = source["meshes"].get(mesh_name, {})
	if entry.is_empty() or entry["skin"] == null:
		return null
	var offset: Transform3D = hair_fit(model, _model_of(skeleton), _eye_centre(skeleton))
	var original: Skin = entry["skin"]
	var skin: Skin = Skin.new()
	for bind: int in original.get_bind_count():
		var bone: int = skeleton.find_bone(original.get_bind_name(bind))
		if bone < 0:
			bone = 0  # A helper bone the wearer lacks: unused by hair, bound to the root.
		skin.add_named_bind(skeleton.get_bone_name(bone), skeleton.get_bone_global_rest(bone).affine_inverse() * offset)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Borrowed_" + mesh_name
	mesh.mesh = entry["mesh"]
	mesh.skin = skin
	mesh.set_meta(BORROWED_META, true)
	skeleton.add_child(mesh)
	mesh.skeleton = NodePath("..")
	return mesh


## Simple procedural frames on the head bone: two lens rims, a bridge and two arms.
static func _add_glasses(skeleton: Skeleton3D, frames: Array) -> void:
	var head: int = skeleton.find_bone("head")
	if head < 0:
		return
	var attachment: BoneAttachment3D = BoneAttachment3D.new()
	attachment.name = "Glasses"
	attachment.set_meta(BORROWED_META, true)
	skeleton.add_child(attachment)
	attachment.bone_name = "head"
	var radius: float = frames[0]
	var rim: float = frames[1]
	var square: bool = frames[2]
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = frames[3]
	material.roughness = 0.35
	material.metallic = 0.0 if square else 0.6
	var lens_material: StandardMaterial3D = StandardMaterial3D.new()
	lens_material.albedo_color = Color(0.85, 0.9, 0.95, 0.12)
	lens_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lens_material.roughness = 0.05
	# Glasses sit in front of the eyes; place them in the head bone's rest space.
	var head_rest: Transform3D = skeleton.get_bone_global_rest(head)
	var eyes: Vector3 = _eye_centre(skeleton)
	var half_gap: float = absf(skeleton.get_bone_global_rest(skeleton.find_bone("eye_l")).origin.x - eyes.x) if skeleton.find_bone("eye_l") >= 0 else 0.03
	var front: float = eyes.z + 0.026
	var holder: Node3D = Node3D.new()
	holder.transform = head_rest.affine_inverse()
	attachment.add_child(holder)
	for side: float in [-1.0, 1.0]:
		var centre: Vector3 = Vector3(eyes.x + side * half_gap, eyes.y, front)
		var ring: MeshInstance3D = MeshInstance3D.new()
		if square:
			ring.mesh = _square_rim(radius * 1.25, radius * 0.9, rim)
		else:
			var torus: TorusMesh = TorusMesh.new()
			torus.inner_radius = radius - rim
			torus.outer_radius = radius
			torus.rings = 24
			torus.ring_segments = 6
			ring.mesh = torus
			ring.rotation = Vector3(PI / 2.0, 0.0, 0.0)
		ring.material_override = material
		ring.position = centre
		holder.add_child(ring)
		var lens: MeshInstance3D = MeshInstance3D.new()
		var disc: CylinderMesh = CylinderMesh.new()
		disc.top_radius = radius - rim
		disc.bottom_radius = radius - rim
		disc.height = 0.001
		lens.mesh = disc
		lens.rotation = Vector3(PI / 2.0, 0.0, 0.0)
		lens.material_override = lens_material
		lens.position = centre
		holder.add_child(lens)
		var arm: MeshInstance3D = MeshInstance3D.new()
		var arm_box: BoxMesh = BoxMesh.new()
		arm_box.size = Vector3(rim * 1.2, rim * 1.6, 0.1)
		arm.mesh = arm_box
		arm.material_override = material
		var outer: float = radius * (1.25 if square else 1.0)
		arm.position = Vector3(centre.x + side * (outer + 0.004), eyes.y + 0.004, front - 0.05)
		arm.rotation = Vector3(0.0, side * 0.12, 0.0)
		holder.add_child(arm)
	var bridge: MeshInstance3D = MeshInstance3D.new()
	var bridge_box: BoxMesh = BoxMesh.new()
	var lens_half: float = radius * (1.25 if square else 1.0)
	bridge_box.size = Vector3(maxf(half_gap * 2.0 - lens_half * 2.0, 0.006), rim * 1.4, rim * 1.4)
	bridge.mesh = bridge_box
	bridge.material_override = material
	bridge.position = Vector3(eyes.x, eyes.y + radius * 0.25, front)
	holder.add_child(bridge)


## A rectangular rim facing +Z, built from four thin boxes.
static func _square_rim(half_width: float, half_height: float, thickness: float) -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var tool: SurfaceTool = SurfaceTool.new()
	var parts: Array = [
		[Vector3(0, half_height, 0), Vector3(half_width * 2.0, thickness, thickness)],
		[Vector3(0, -half_height, 0), Vector3(half_width * 2.0, thickness, thickness)],
		[Vector3(half_width, 0, 0), Vector3(thickness, half_height * 2.0, thickness)],
		[Vector3(-half_width, 0, 0), Vector3(thickness, half_height * 2.0, thickness)],
	]
	for part: Array in parts:
		var box: BoxMesh = BoxMesh.new()
		box.size = part[1]
		tool.append_from(box, 0, Transform3D(Basis.IDENTITY, part[0]))
	tool.commit(mesh)
	return mesh
