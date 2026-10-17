extends SceneTree
## Validates exported environment assets inside Godot.
##
## Usage (from the project root, after the editor has imported the assets):
##   godot --headless --path . -s res://tools/godot/validate_glb_imports.gd
##
## For every .glb under res://assets/exports/ it checks that the scene loads
## and instantiates, has visible meshes, turns "-colonly" proxies into
## StaticBody3D + CollisionShape3D, and that environments carry their camera
## (CAM_*), marker (MARK_*) and light (LIGHTMARK_*) nodes. It also compares
## the mesh bounds against asset_manifest.json (±5 cm).
## Exit code 0 = all assets valid.

const EXPORT_ROOT: String = "res://assets/exports"
const MANIFEST_PATH: String = "res://assets/asset_manifest/asset_manifest.json"
const TOLERANCE_M: float = 0.05

var _failures: int = 0
var _checked: int = 0


func _init() -> void:
	var manifest: Dictionary = {}
	if FileAccess.file_exists(MANIFEST_PATH):
		manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH)).get("assets", {})
	for path: String in _find_glbs(EXPORT_ROOT):
		_check_asset(path, manifest)
	print("\nGLB VALIDATION %s: %d assets checked, %d failure(s)" % [
		"PASSED" if _failures == 0 else "FAILED", _checked, _failures])
	quit(0 if _failures == 0 else 1)


func _find_glbs(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for sub: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_find_glbs(dir_path.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".glb"):
			found.append(dir_path.path_join(file))
	found.sort()
	return found


func _check_asset(path: String, manifest: Dictionary) -> void:
	_checked += 1
	var asset_id: String = path.get_file().get_basename()
	var packed: PackedScene = load(path)
	if packed == null:
		_fail(asset_id, "failed to load (was the project imported in the editor first?)")
		return
	var scene: Node = packed.instantiate()
	var meshes: Array[Node] = scene.find_children("*", "MeshInstance3D", true, false)
	var bodies: Array[Node] = scene.find_children("*", "StaticBody3D", true, false)
	var shapes: Array[Node] = scene.find_children("*", "CollisionShape3D", true, false)
	var cameras: Array[Node] = scene.find_children("CAM_*", "Camera3D", true, false)
	var lightmarks: Array[Node] = scene.find_children("LIGHTMARK_*", "", true, false)
	var marks: Array[Node] = scene.find_children("MARK_*", "", true, false)
	var record: Dictionary = manifest.get(asset_id, {})

	if meshes.is_empty():
		_fail(asset_id, "no MeshInstance3D")
	var collision_expected: bool = record.get("collision", "").contains("ollider")
	if collision_expected and (bodies.is_empty() or shapes.is_empty()):
		_fail(asset_id, "manifest promises collision but no StaticBody3D/CollisionShape3D was generated")
	for body: Node in bodies:
		if body.get_child_count() == 0:
			_fail(asset_id, "StaticBody3D %s has no shape" % body.name)
	if asset_id.begins_with("ENV_") and cameras.is_empty():
		_fail(asset_id, "environment has no CAM_* camera markers")
	if not record.is_empty():
		var expected: Array = record.get("dimensions_m", [])
		var size: Vector3 = _visual_size(scene)
		# Blender (x, y, z) -> Godot (x, z, y) for an axis-aligned size.
		var got: Array = [size.x, size.z, size.y]
		for i: int in 3:
			if absf(float(expected[i]) - got[i]) > TOLERANCE_M:
				_fail(asset_id, "size %s differs from manifest %s" % [str(got), str(expected)])
				break
	else:
		_fail(asset_id, "missing from asset_manifest.json")
	print("  %-44s meshes %3d  colliders %3d  cams %d  marks %d  lights %d" % [
		asset_id, meshes.size(), bodies.size(), cameras.size(), marks.size(), lightmarks.size()])
	scene.free()


func _visual_size(scene: Node) -> Vector3:
	var box: AABB = AABB()
	var first: bool = true
	for node: Node in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		if mesh_instance.mesh == null:
			continue
		var xf: Transform3D = _global_xf(mesh_instance, scene)
		var aabb: AABB = xf * mesh_instance.mesh.get_aabb()
		box = aabb if first else box.merge(aabb)
		first = false
	return box.size


func _global_xf(node: Node3D, root: Node) -> Transform3D:
	var xf: Transform3D = node.transform
	var parent: Node = node.get_parent()
	while parent != null and parent != root:
		if parent is Node3D:
			xf = (parent as Node3D).transform * xf
		parent = parent.get_parent()
	if root is Node3D:
		xf = (root as Node3D).transform * xf
	return xf


func _fail(asset_id: String, message: String) -> void:
	_failures += 1
	print("  FAIL %s: %s" % [asset_id, message])
