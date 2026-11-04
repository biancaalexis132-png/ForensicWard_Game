class_name WardRoundBedside
extends Node3D
## WardRoundBedside: ward-round patients waiting on the ward in 3D.
##
## Patients whose plan is not yet accepted sit on the bed in the patient rooms
## (data/ward_round_bedside.json), oldest admission first. Approaching one opens
## the ward-round screen on their case. When a plan is accepted the patient
## leaves and the next one takes the room, with a notice. Staging only: reads
## WardRounds and writes no clinical, story or save state.

const DATA_PATH: String = "res://data/ward_round_bedside.json"
const SCHEMA_VERSION: int = 1
const NODE_NAME: String = "WardRoundBedside"
const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")

var _data: Dictionary = {}
## slot id -> the WardCharacter sitting there (absent when the slot is empty).
var _occupants: Dictionary = {}
## The zone root slot positions are relative to.
var _zone_root: Node3D


## Adds the staging node under the zone root when this zone holds the slots.
static func attach(zone_root: Node3D, zone_id: String) -> WardRoundBedside:
	var data: Dictionary = load_data()
	if data.is_empty() or str(data.get("zone", "")) != zone_id:
		return null
	var bedside: WardRoundBedside = WardRoundBedside.new()
	bedside.name = NODE_NAME
	bedside._data = data
	bedside._zone_root = zone_root
	zone_root.add_child(bedside)
	return bedside


static func load_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary or not validate(parsed).is_empty():
		push_warning("WardRoundBedside: invalid %s; no patients on the ward" % DATA_PATH)
		return {}
	return parsed


static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var version: Variant = data.get("schema_version")
	if not (version is int or version is float) or int(version) != SCHEMA_VERSION:
		errors.append("ward_round_bedside: schema_version must be %d" % SCHEMA_VERSION)
	if str(data.get("review_status", "")).is_empty():
		errors.append("ward_round_bedside: review_status is required")
	if str(data.get("zone", "")).is_empty():
		errors.append("ward_round_bedside: zone is required")
	var slots: Variant = data.get("slots")
	if not slots is Array or (slots as Array).is_empty():
		errors.append("ward_round_bedside: slots must be a non-empty array")
	else:
		var seen: Dictionary = {}
		for slot: Variant in slots:
			if not slot is Dictionary:
				errors.append("ward_round_bedside: each slot must be an object")
				continue
			var id: String = str(slot.get("id", ""))
			if id.is_empty() or seen.has(id):
				errors.append("ward_round_bedside: slot ids must be unique and non-empty")
			seen[id] = true
			if str(slot.get("label", "")).is_empty():
				errors.append("ward_round_bedside: slot %s needs a label" % id)
			var position: Variant = slot.get("position")
			if not position is Array or position.size() != 3:
				errors.append("ward_round_bedside: slot %s position must be [x, y, z]" % id)
			else:
				for value: Variant in position:
					if not (value is int or value is float) or not is_finite(float(value)):
						errors.append("ward_round_bedside: slot %s position must be numbers" % id)
			var yaw: Variant = slot.get("yaw_degrees")
			if not (yaw is int or yaw is float) or not is_finite(float(yaw)):
				errors.append("ward_round_bedside: slot %s yaw_degrees must be a number" % id)
	var patients: Variant = data.get("patients")
	if not patients is Dictionary:
		errors.append("ward_round_bedside: patients must be an object (case id -> character id)")
	else:
		for case_id: String in patients:
			if str(patients[case_id]).is_empty():
				errors.append("ward_round_bedside: case %s has no character id" % case_id)
	return errors


func _ready() -> void:
	WardRounds.case_changed.connect(_on_case_changed)
	EventBus.chapter_started.connect(refresh.unbind(1))
	EventBus.game_loaded.connect(refresh.unbind(1))
	# An unloaded zone keeps its nodes out of the tree; catch up on return.
	tree_entered.connect(refresh.call_deferred)
	refresh.call_deferred()


## The character id that plays this case, or "" when it is seen in the EHR only.
func character_for(case_id: String) -> String:
	return str(_data.get("patients", {}).get(case_id, ""))


## Cases who should be on the ward now: admitted, plan not accepted, with a model.
func waiting_case_ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in WardRounds.admitted_case_ids():
		if WardRounds.status(id) != WardRounds.STATUS_ACCEPTED and not character_for(id).is_empty():
			result.append(id)
	return result


## slot id -> case id for everyone currently seated.
func occupancy() -> Dictionary:
	var result: Dictionary = {}
	for slot_id: String in _occupants:
		var character: WardCharacter = _occupants[slot_id]
		if is_instance_valid(character):
			result[slot_id] = character.ward_round_case_id
	return result


func occupant(slot_id: String) -> WardCharacter:
	var character: Variant = _occupants.get(slot_id, null)
	return character if is_instance_valid(character) else null


## Seats the waiting patients. A patient already seated keeps their room; a
## room whose patient has left takes the next one waiting. Returns the
## arrivals as {slot id: case id}.
func refresh(announce: bool = false) -> Dictionary:
	if not is_inside_tree():
		return {}
	var waiting: Array[String] = waiting_case_ids()
	var arrivals: Dictionary = {}
	var notes: Array[String] = []
	# Patients who no longer wait (plan accepted, or a load) leave first.
	for slot_id: String in _occupants.keys():
		var character: WardCharacter = occupant(slot_id)
		if character == null or not character.ward_round_case_id in waiting:
			_remove(slot_id)
	var seated: Array = occupancy().values()
	var queue: Array[String] = []
	for id: String in waiting:
		if not id in seated:
			queue.append(id)
	for slot: Dictionary in _data.get("slots", []):
		var slot_id: String = str(slot["id"])
		if occupant(slot_id) != null or queue.is_empty():
			continue
		var case_id: String = queue.pop_front()
		_seat(slot, case_id)
		arrivals[slot_id] = case_id
		notes.append("%s is waiting in %s" % [WardRounds.get_case(case_id)["patient"]["name"], slot["label"]])
	# One notice for everyone who arrived, so notices do not stack.
	if announce and not notes.is_empty():
		EventBus.notification_requested.emit("Ward round: %s." % "; ".join(notes))
	return arrivals


func _seat(slot: Dictionary, case_id: String) -> void:
	var character: WardCharacter = CHARACTER_SCENE.instantiate()
	character.kind = WardCharacter.Kind.WARD_ROUND
	character.character_id = character_for(case_id)
	character.ward_round_case_id = case_id
	character.seated = true
	character.name = "WardRound_" + str(slot["id"])
	var offset: Vector3 = CampaignCastVisuals.configure(character, "WardRound_" + str(slot["id"]))
	add_child(character)
	var position: Array = slot["position"]
	var basis: Basis = Basis(Vector3.UP, deg_to_rad(float(slot["yaw_degrees"])))
	var local: Transform3D = Transform3D(basis, Vector3(position[0], position[1], position[2])) \
			* Transform3D(Basis.IDENTITY, offset)
	character.global_transform = _zone_root.global_transform * local
	_occupants[str(slot["id"])] = character


func _remove(slot_id: String) -> void:
	var character: WardCharacter = occupant(slot_id)
	_occupants.erase(slot_id)
	if character != null:
		remove_child(character)
		character.queue_free()


func _on_case_changed(_case_id: String) -> void:
	refresh(true)
