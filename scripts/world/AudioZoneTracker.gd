class_name AudioZoneTracker
extends Node
## AudioZoneTracker: tells AudioDirector which location the player is in, from
## the floor-plan rectangles in data/zones.json (each zone's audio_zones, then
## its default_audio_location), so ambience and reverb follow the player
## between rooms and zones. Only zones on the player's level count, because
## levels share floor-plan coordinates. Checks a few times per second.
## Headless runs (tests, CI) track the location but play nothing: there is no
## audio device, and a stream still playing at quit is reported as a leak.

const CHECK_SECONDS: float = 0.25

var target: Node3D = null
var current_location: String = ""
## The level whose zones count ("ground", "research", ...); follows EventBus.zone_changed.
var level: String = ""
var drive_audio: bool = DisplayServer.get_name() != "headless"

var _elapsed: float = 0.0


func _ready() -> void:
	if ContentRegistry.is_valid:
		level = str(ContentRegistry.get_zone(ContentRegistry.get_world().get("start_zone", "")).get("level", ""))
	EventBus.zone_changed.connect(_on_zone_changed)
	update_now()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= CHECK_SECONDS:
		_elapsed = 0.0
		update_now()


func location_at(position: Vector3) -> String:
	var zones: Array[Dictionary] = []
	for zone_id: String in ContentRegistry.get_zone_ids():
		var zone: Dictionary = ContentRegistry.get_zone(zone_id)
		if zone["level"] == level:
			zones.append(zone)
	for zone: Dictionary in zones:
		for rect: Dictionary in zone.get("audio_zones", []):
			if _inside(rect, position):
				return rect["location"]
	for zone: Dictionary in zones:
		for rect: Dictionary in zone["bounds"]:
			if _inside(rect, position):
				return str(zone.get("default_audio_location", ""))
	return ""


func update_now() -> void:
	if target == null or not is_instance_valid(target):
		return
	var location: String = location_at(target.global_position)
	if location.is_empty() or location == current_location:
		return
	current_location = location
	if drive_audio:
		AudioDirector.set_location(location, 2.0)


func _on_zone_changed(zone_id: String, _previous_zone_id: String) -> void:
	level = str(ContentRegistry.get_zone(zone_id).get("level", level))
	update_now()


static func _inside(rect: Dictionary, position: Vector3) -> bool:
	return position.x >= rect["min_xz"][0] and position.x <= rect["max_xz"][0] \
			and position.z >= rect["min_xz"][1] and position.z <= rect["max_xz"][1]
