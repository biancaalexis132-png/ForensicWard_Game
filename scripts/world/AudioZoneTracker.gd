class_name AudioZoneTracker
extends Node
## AudioZoneTracker: tells AudioDirector which location the player is in, from
## the world config's floor-plan rectangles (audio_zones), so ambience and
## reverb follow the player between rooms. Checks a few times per second.
## Headless runs (tests, CI) track the location but play nothing: there is no
## audio device, and a stream still playing at quit is reported as a leak.

const CHECK_SECONDS: float = 0.25

var target: Node3D = null
var current_location: String = ""
var drive_audio: bool = DisplayServer.get_name() != "headless"

var _zones: Array = []
var _default: String = ""
var _elapsed: float = 0.0


func _ready() -> void:
	var world: Dictionary = ContentRegistry.get_world() if ContentRegistry.is_valid else {}
	_zones = world.get("audio_zones", [])
	_default = world.get("default_audio_location", "")
	update_now()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= CHECK_SECONDS:
		_elapsed = 0.0
		update_now()


func location_at(position: Vector3) -> String:
	for zone: Dictionary in _zones:
		if position.x >= zone["min_xz"][0] and position.x <= zone["max_xz"][0] \
				and position.z >= zone["min_xz"][1] and position.z <= zone["max_xz"][1]:
			return zone["location"]
	return _default


func update_now() -> void:
	if target == null or not is_instance_valid(target):
		return
	var location: String = location_at(target.global_position)
	if location.is_empty() or location == current_location:
		return
	current_location = location
	if drive_audio:
		AudioDirector.set_location(location, 2.0)
