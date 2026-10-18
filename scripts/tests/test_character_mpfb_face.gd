extends TestCase
## Verifies Naomi v05_mpfb: the MPFB2 faceunit bake keeps the cast's stable morph names
## (so CharacterFaceRig and the acting adapter work unchanged), adds every viseme, and the
## shapes really move the face.

const GLB: String = "res://assets/exports/characters/Naomi_Bennett_v05_mpfb.glb"
const MAPPING: String = "res://tools/character_animation/mpfb_face_mapping.json"
const CLIP_LIBRARY: String = "res://tools/character_animation/clip_library.json"

var _model: Node


func after_each() -> void:
	if is_instance_valid(_model):
		_model.free()
	super.after_each()


func test_mapping_covers_the_cast_face_shapes() -> void:
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAPPING))
	var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CLIP_LIBRARY))
	var stable: Array = (mapping["stable_shapes"] as Dictionary).keys()
	for name: String in ["blink", "blink_L", "blink_R", "mouth_open"]:
		check(stable.has(name), "mapping builds %s" % name)
	for name: String in (library["face_shapes"]["expressions"] as Dictionary).keys():
		check(stable.has(name), "mapping builds expression %s" % name)
	check_eq((mapping["visemes"] as Array).size(), 22, "all 22 MPFB visemes are listed")


func test_glb_has_stable_morphs_and_visemes() -> void:
	var mesh: MeshInstance3D = _face_mesh()
	check(mesh != null, "v05_mpfb has a face mesh with a blink morph")
	if mesh == null:
		return
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAPPING))
	for name: String in (mapping["stable_shapes"] as Dictionary).keys():
		check(mesh.find_blend_shape_by_name(StringName(name)) >= 0, "morph %s exported" % name)
	for viseme: String in mapping["visemes"]:
		check(mesh.find_blend_shape_by_name(StringName("viseme_" + viseme)) >= 0, "viseme %s exported" % viseme)


func test_blink_and_mouth_move_the_face() -> void:
	var mesh: MeshInstance3D = _face_mesh()
	if mesh == null:
		check(false, "v05_mpfb face mesh missing")
		return
	check(_largest_offset(mesh, "blink") > 0.006, "blink closes the lids by more than 6 mm")
	check(_largest_offset(mesh, "mouth_open") > 0.004, "mouth_open moves the jaw by more than 4 mm")
	check(_largest_offset(mesh, "viseme_aa_02") > 0.004, "the 'aa' viseme opens the mouth")
	check(_largest_offset(mesh, "viseme_sil_00") < 0.0005, "the silence viseme is neutral")


func _face_mesh() -> MeshInstance3D:
	_model = (load(GLB) as PackedScene).instantiate()
	for node: Node in _model.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).find_blend_shape_by_name(&"blink") >= 0:
			return node as MeshInstance3D
	return null


## Largest vertex offset of a morph across the mesh's surfaces, in metres.
func _largest_offset(mesh: MeshInstance3D, shape: String) -> float:
	var index: int = mesh.find_blend_shape_by_name(StringName(shape))
	var array_mesh: ArrayMesh = mesh.mesh as ArrayMesh
	var largest: float = 0.0
	for surface: int in array_mesh.get_surface_count():
		var base: PackedVector3Array = array_mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		var target: PackedVector3Array = array_mesh.surface_get_blend_shape_arrays(surface)[index][Mesh.ARRAY_VERTEX]
		var relative: bool = array_mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_RELATIVE
		for i: int in base.size():
			var offset: Vector3 = target[i] if relative else target[i] - base[i]
			largest = maxf(largest, offset.length())
	return largest
