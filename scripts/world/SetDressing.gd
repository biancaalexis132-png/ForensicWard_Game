class_name SetDressing
extends RefCounted
## Places the cosmetic props listed in data/set_dressing.json into a freshly
## built zone (hand gel by the doors, an AED cabinet, a notice board, ceiling
## cameras). Display only: nothing here is interactive, saved or story-bearing.

const DATA_PATH: String = "res://data/set_dressing.json"
const NODE_PREFIX: String = "Dressing_"
const FACING_YAW: Dictionary = {"south": 0.0, "east": 90.0, "north": 180.0, "west": -90.0}

static var _data: Dictionary = {}


static func entries(zone_id: String) -> Array:
	if _data.is_empty():
		var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			_data = parsed if parsed is Dictionary else {}
	return _data.get("zones", {}).get(zone_id, [])


## Adds the zone's props under a "SetDressing" node; returns how many were placed.
static func attach(root: Node3D, zone_id: String) -> int:
	var list: Array = entries(zone_id)
	if list.is_empty():
		return 0
	var holder: Node3D = Node3D.new()
	holder.name = "SetDressing"
	root.add_child(holder)
	for entry: Dictionary in list:
		var scene: PackedScene = load(str(entry["scene"])) as PackedScene
		if scene == null:
			push_warning("SetDressing: missing scene " + str(entry["scene"]))
			continue
		var prop: Node3D = scene.instantiate() as Node3D
		prop.name = NODE_PREFIX + str(entry["id"])
		var at: Array = entry["at"]
		prop.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		prop.rotation_degrees.y = float(FACING_YAW.get(str(entry.get("facing", "south")), 0.0))
		holder.add_child(prop)
	return holder.get_child_count()


## Problems in the data, for tests: unknown facings, missing scenes, duplicate ids.
static func validate() -> Array[String]:
	var problems: Array[String] = []
	_data = {}
	entries("")
	for zone_id: String in _data.get("zones", {}):
		var seen: Dictionary = {}
		for entry: Dictionary in _data["zones"][zone_id]:
			var id: String = str(entry.get("id", ""))
			if id.is_empty() or seen.has(id):
				problems.append("%s: missing or duplicate id '%s'" % [zone_id, id])
			seen[id] = true
			if not ResourceLoader.exists(str(entry.get("scene", ""))):
				problems.append("%s/%s: scene not found" % [zone_id, id])
			if not FACING_YAW.has(str(entry.get("facing", "south"))):
				problems.append("%s/%s: unknown facing" % [zone_id, id])
			if (entry.get("at", []) as Array).size() != 3:
				problems.append("%s/%s: 'at' needs x, y, z" % [zone_id, id])
	return problems
