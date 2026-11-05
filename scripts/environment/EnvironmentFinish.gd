class_name EnvironmentFinish
extends RefCounted
## Shared procedural finishes for previously flat environment materials.
## Textured cast, labels, screens and glass are preserved. Cache keys are stable
## across zone unload/reload, so material instances cannot accumulate per visit.
static var _materials: Dictionary = {}
static var _grain: Texture2D
static var _roughness: Texture2D
static var _normal: Texture2D

static func apply(root: Node) -> void:
	if _grain == null:
		_grain = load("res://assets/textures/environment_finish/grain.png")
		_roughness = load("res://assets/textures/environment_finish/roughness.png")
		_normal = load("res://assets/textures/environment_finish/normal.png")
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var original: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
			if original == null or original.albedo_texture != null:
				continue
			var name: String = original.resource_name.to_lower()
			var eligible: bool = false
			for token: String in ["wall", "paint", "wood", "concrete", "brick", "terrazzo", "linoleum", "plaster", "tile"]:
				if token in name:
					eligible = true
			if not eligible:
				continue
			var key: String = "%s:%s:%s:%s" % [name, original.albedo_color.to_html(), original.metallic, original.roughness]
			if not _materials.has(key):
				var material: StandardMaterial3D = original.duplicate() as StandardMaterial3D
				material.albedo_texture = _grain
				material.roughness_texture = _roughness
				material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
				material.normal_enabled = true
				material.normal_texture = _normal
				material.normal_scale = 0.16
				material.uv1_triplanar = true
				material.uv1_world_triplanar = true
				material.uv1_scale = Vector3.ONE * 0.7
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				_materials[key] = material
			mesh.set_surface_override_material(surface, _materials[key])

static func material_count() -> int:
	return _materials.size()
