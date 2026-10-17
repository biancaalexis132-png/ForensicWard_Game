@tool
class_name RoomShell
extends Node3D
## RoomShell: a modular greybox room (floor, walls, ceiling, light fixtures).
##
## Geometry is generated from exported parameters, both in the editor (so
## level designers see it) and at runtime. Generated nodes are not saved into
## scenes: edit the parameters, not the meshes.
##
## Local space: origin at floor centre; the room spans x ∈ [-w/2, w/2] and
## z ∈ [-d/2, d/2]. Walls sit *inside* the footprint, so two rooms placed
## edge to edge never z-fight; their walls stand back to back.
##
## Openings are Vector4(side, offset, width, height):
##   side   0 = north (-z), 1 = south (+z), 2 = west (-x), 3 = east (+x)
##   offset centre of the opening along the wall (local x for N/S walls,
##          local z for W/E walls)

const SIDE_NORTH: int = 0
const SIDE_SOUTH: int = 1
const SIDE_WEST: int = 2
const SIDE_EAST: int = 3

## Room size: x = width, y = height, z = depth (metres).
@export var size: Vector3 = Vector3(4.0, 3.0, 8.0):
	set(value):
		size = value
		_queue_rebuild()
@export var wall_thickness: float = 0.15:
	set(value):
		wall_thickness = value
		_queue_rebuild()
## Door/passage openings: Vector4(side, offset, width, height).
@export var openings: Array[Vector4] = []:
	set(value):
		openings = value
		_queue_rebuild()
## Sides left completely open (for chaining hallway modules).
@export_flags("North", "South", "West", "East") var open_sides: int = 0:
	set(value):
		open_sides = value
		_queue_rebuild()
@export var build_ceiling: bool = true:
	set(value):
		build_ceiling = value
		_queue_rebuild()

@export_group("Look")
@export var wall_color: Color = Color(0.5, 0.55, 0.52):
	set(value):
		wall_color = value
		_queue_rebuild()
@export var floor_color: Color = Color(0.32, 0.34, 0.33):
	set(value):
		floor_color = value
		_queue_rebuild()
@export var ceiling_color: Color = Color(0.78, 0.79, 0.77):
	set(value):
		ceiling_color = value
		_queue_rebuild()

@export_group("Lighting")
## Distance between ceiling lights along the room's longer axis. 0 = none.
@export var light_spacing: float = 4.0:
	set(value):
		light_spacing = value
		_queue_rebuild()
@export var light_color: Color = Color(0.88, 0.96, 1.0):
	set(value):
		light_color = value
		_queue_rebuild()
@export var light_energy: float = 0.75:
	set(value):
		light_energy = value
		_queue_rebuild()
@export var light_shadows: bool = true:
	set(value):
		light_shadows = value
		_queue_rebuild()

const GENERATED_NAME: String = "_Generated"

var _rebuild_queued: bool = false


func _ready() -> void:
	rebuild()


## Regenerates all geometry. Safe to call any time.
func rebuild() -> void:
	_rebuild_queued = false
	var old: Node = get_node_or_null(GENERATED_NAME)
	if old != null:
		remove_child(old)
		old.queue_free()
	var root: Node3D = Node3D.new()
	root.name = GENERATED_NAME
	add_child(root) # No owner: never saved into the scene file.

	var half_w: float = size.x * 0.5
	var half_d: float = size.z * 0.5
	var floor_material: StandardMaterial3D = _material(floor_color, 0.75)
	_add_box(root, "Floor", Vector3(0.0, -0.05, 0.0), Vector3(size.x, 0.1, size.z), floor_material)
	if build_ceiling:
		_add_box(root, "Ceiling", Vector3(0.0, size.y + 0.05, 0.0), Vector3(size.x, 0.1, size.z), _material(ceiling_color, 0.9))

	var wall_material: StandardMaterial3D = _material(wall_color, 0.85)
	var t: float = wall_thickness
	# North/south walls run along x; west/east walls run along z between them.
	_build_wall(root, SIDE_NORTH, Vector3(0.0, 0.0, -half_d + t * 0.5), size.x, wall_material)
	_build_wall(root, SIDE_SOUTH, Vector3(0.0, 0.0, half_d - t * 0.5), size.x, wall_material)
	_build_wall(root, SIDE_WEST, Vector3(-half_w + t * 0.5, 0.0, 0.0), size.z, wall_material)
	_build_wall(root, SIDE_EAST, Vector3(half_w - t * 0.5, 0.0, 0.0), size.z, wall_material)
	_build_lights(root)


func _queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	rebuild.call_deferred()


func _build_wall(root: Node3D, side: int, center: Vector3, length: float, material: Material) -> void:
	if open_sides & (1 << side):
		return
	var along_x: bool = side == SIDE_NORTH or side == SIDE_SOUTH
	# Collect this wall's openings as [start, end, height] along the wall.
	var gaps: Array[Vector3] = []
	for opening: Vector4 in openings:
		if int(opening.x) == side:
			gaps.append(Vector3(opening.y - opening.z * 0.5, opening.y + opening.z * 0.5, opening.w))
	gaps.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x < b.x)

	var cursor: float = -length * 0.5
	var index: int = 0
	for gap: Vector3 in gaps:
		_wall_piece(root, "%s_%d" % [_side_name(side), index], center, along_x, cursor, gap.x, 0.0, size.y, material)
		# Lintel above the opening.
		_wall_piece(root, "%s_lintel_%d" % [_side_name(side), index], center, along_x, gap.x, gap.y, gap.z, size.y, material)
		cursor = gap.y
		index += 1
	_wall_piece(root, "%s_%d" % [_side_name(side), index], center, along_x, cursor, length * 0.5, 0.0, size.y, material)


func _wall_piece(root: Node3D, piece_name: String, center: Vector3, along_x: bool, from: float, to: float,
		bottom: float, top: float, material: Material) -> void:
	var length: float = to - from
	var height: float = top - bottom
	if length <= 0.01 or height <= 0.01:
		return
	var mid: float = (from + to) * 0.5
	var position_3d: Vector3 = center + (Vector3(mid, 0.0, 0.0) if along_x else Vector3(0.0, 0.0, mid))
	position_3d.y = bottom + height * 0.5
	var box_size: Vector3 = Vector3(length, height, wall_thickness) if along_x else Vector3(wall_thickness, height, length)
	_add_box(root, piece_name, position_3d, box_size, material)


func _build_lights(root: Node3D) -> void:
	if light_spacing <= 0.0:
		return
	var along_x: bool = size.x > size.z
	var length: float = size.x if along_x else size.z
	var count: int = maxi(1, floori(length / light_spacing))
	var step: float = length / count
	var fixture_material: StandardMaterial3D = _material(Color(0.95, 0.97, 1.0), 0.4)
	fixture_material.emission_enabled = true
	fixture_material.emission = light_color
	fixture_material.emission_energy_multiplier = 2.0
	for i: int in count:
		var offset: float = -length * 0.5 + step * (i + 0.5)
		var position_3d: Vector3 = Vector3(offset, size.y - 0.03, 0.0) if along_x else Vector3(0.0, size.y - 0.03, offset)
		var fixture: MeshInstance3D = MeshInstance3D.new()
		fixture.name = "LightFixture_%d" % i
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(1.2, 0.04, 0.3) if along_x else Vector3(0.3, 0.04, 1.2)
		mesh.material = fixture_material
		fixture.mesh = mesh
		fixture.position = position_3d
		fixture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(fixture)
		var light: OmniLight3D = OmniLight3D.new()
		light.name = "Light_%d" % i
		light.position = position_3d - Vector3(0.0, 0.25, 0.0)
		light.light_color = light_color
		light.light_energy = light_energy
		light.omni_range = maxf(step, minf(size.x, size.z)) * 1.4
		light.shadow_enabled = light_shadows
		root.add_child(light)


func _add_box(root: Node3D, piece_name: String, center: Vector3, box_size: Vector3, material: Material) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = piece_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = box_size
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _side_name(side: int) -> String:
	return ["North", "South", "West", "East"][side]
