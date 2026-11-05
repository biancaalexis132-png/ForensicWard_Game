class_name EncounterStage
extends Node3D
## EncounterStage: the people in the interview room during an encounter
## (EncounterScreen). Brings in the player's psychiatrist as a visible
## character (model and colours from ProtagonistProfile), and performs each
## examination step on screen: the psychiatrist walks to the patient's side,
## reaches, lifts and lets go, while the patient's own pose shows the finding
## (an arm that stays raised). The sitter reads from his clipboard and talks.
##
## Positions and cameras are derived from the patient's seat, so the stage
## works wherever the interview room is placed. Cosmetic only: nothing here
## writes story, clinical or save state.

const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")
const SHOT_ESTABLISHING: String = "CAM_IR_Establishing"
const TALK_GESTURES: Array[StringName] = [&"explain_open_hand", &"small_acknowledgement_nod", &"thinking_pause"]
const WALK_SPEED_M_S: float = 1.0
## Built model colours (tools/blender/characters/cast/protagonist_*.json).
const BUILT_SKIN: Color = Color("#B98463")
const BUILT_HAIR: Color = Color("#60432E")
const BUILT_OUTFIT: Color = Color("#263D56")

var patient: Node3D = null
var sitter: Node3D = null
var doctor: Node3D = null
var exam_camera: Camera3D = null
var current_action: String = ""

var _doctor_pose: ExamPoseModifier = null
var _patient_pose: ExamPoseModifier = null
var _sitter_pose: ExamPoseModifier = null
var _markers: Dictionary = {}  ## name -> Node3D target
var _talk_spot: Vector3 = Vector3.ZERO
var _exam_spot: Vector3 = Vector3.ZERO
var _seq: int = 0
var _props: Array[Node3D] = []


## Stages the room for one patient. Missing pieces (greybox room, no model)
## leave the encounter text-only rather than failing.
func begin(patient_id: String, sitter_id: String) -> void:
	var world: Node = get_parent()
	patient = world.find_child("Character_" + patient_id, true, false) as Node3D
	sitter = world.find_child("Character_" + sitter_id, true, false) as Node3D if not sitter_id.is_empty() else null
	if patient == null:
		return
	var forward: Vector3 = -patient.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	var base: Vector3 = patient.global_position
	_exam_spot = base + forward * 0.42 + right * 0.62
	_talk_spot = base + forward * 1.55 + right * 0.6
	_patient_pose = _attach_modifier(patient)
	_sitter_pose = _attach_modifier(sitter)
	_spawn_doctor(base + forward * 2.6 + right * 1.4)
	_make_markers(base, forward, right)
	exam_camera = Camera3D.new()
	exam_camera.name = "CAM_Encounter_Exam"
	exam_camera.fov = 52.0
	add_child(exam_camera)
	exam_camera.global_position = base + forward * 1.45 - right * 0.75 + Vector3.UP * 1.45
	exam_camera.look_at(base + Vector3.UP * 0.85 + right * 0.3 + forward * 0.25)
	_cut(SHOT_ESTABLISHING)
	if is_instance_valid(_doctor_pose):
		_doctor_pose.look_at_node(_markers.get("patient_head"), 1.0)


func end() -> void:
	_seq += 1
	for modifier: ExamPoseModifier in [_patient_pose, _sitter_pose]:
		if is_instance_valid(modifier):
			modifier.queue_free()
	for prop: Node3D in _props:
		if is_instance_valid(prop):
			prop.queue_free()
	if is_instance_valid(doctor):
		doctor.queue_free()


## Performs one action: the psychiatrist's movement and, when given, the
## patient's own response. Returns immediately; the motion plays on.
func perform(action: String, patient_action: String = "") -> void:
	current_action = action
	_seq += 1
	_run(action, patient_action, _seq)


## A line or caption begins: the speaker's body reacts.
func beat(speaker: String, act: String) -> void:
	match act:
		"read_clipboard":
			if is_instance_valid(_sitter_pose):
				_show_clipboard()
				_sitter_pose.reach("l", _markers.get("sitter_clipboard"), 1.0)
				_sitter_pose.reach("r", _markers.get("sitter_clipboard_r"), 1.0)
				_sitter_pose.look_at_node(_markers.get("sitter_clipboard"), 1.0)
		"look_at_player":
			if is_instance_valid(_patient_pose):
				_patient_pose.look_at_node(_markers.get("doctor_head"), 1.0)
		"arm_lower":
			if is_instance_valid(_patient_pose):
				_patient_pose.reach("r", null, 0.0)
	if speaker.begins_with("staff_") and is_instance_valid(_doctor_pose) and is_instance_valid(sitter):
		_doctor_pose.look_at_node(_markers.get("sitter_head"), 1.0)
	elif speaker == "pt_elias_ward" and is_instance_valid(_doctor_pose):
		_doctor_pose.look_at_node(_markers.get("patient_head"), 1.0)


func speaking(speaker: String) -> void:
	var actor: Node3D = doctor if speaker == "player" else sitter if speaker.begins_with("staff_") and sitter != null \
			and speaker == str(sitter.get("character_id")) else null
	var performer: CastPerformer = _performer(actor)
	if performer != null:
		performer.play_gesture(TALK_GESTURES[_seq % TALK_GESTURES.size()])


## The presentation ended: hands come back, the camera returns to the room.
## A finding the patient shows (an arm left raised) is lowered by the
## psychiatrist at the end, as on the ward.
func settle() -> void:
	_seq += 1
	if is_instance_valid(_doctor_pose):
		_doctor_pose.reach("r", null, 0.0)
		_doctor_pose.reach("l", null, 0.0)
		_doctor_pose.lean(0.0, 0.0)
		_doctor_pose.look_at_node(_markers.get("patient_head"), 1.0)
	if is_instance_valid(_patient_pose):
		_patient_pose.release_all()
	if is_instance_valid(_sitter_pose):
		_sitter_pose.release_all()
	_hide_props()
	_cut(SHOT_ESTABLISHING)


# --- Choreography ------------------------------------------------------------------

func _run(action: String, patient_action: String, seq: int) -> void:
	var exam: bool = action.begins_with("exam_") or action in ["offer_hand", "offer_cup"]
	if action == "talk_to_sitter":
		if is_instance_valid(_doctor_pose):
			_doctor_pose.look_at_node(_markers.get("sitter_head"), 1.0)
		return
	await _walk_doctor(_exam_spot if exam else _talk_spot, seq)
	if seq != _seq:
		return
	if exam:
		_cut_camera(exam_camera)
	if not is_instance_valid(_doctor_pose):
		return
	match action:
		"observe":
			_doctor_pose.look_at_node(_markers.get("patient_head"), 1.0)
		"exam_pulse":
			_doctor_pose.lean(14.0)
			_doctor_pose.reach("r", _markers.get("patient_wrist"))
			_doctor_pose.look_at_node(_markers.get("patient_wrist"))
			await _wait(1.4, seq)
			_doctor_pose.reach("l", _markers.get("doctor_watch"))
		"exam_penlight":
			_doctor_pose.lean(18.0)
			_doctor_pose.reach("r", _markers.get("patient_face"))
			_doctor_pose.look_at_node(_markers.get("patient_head"))
		"exam_scratch_head":
			_doctor_pose.look_at_node(_markers.get("patient_head"))
			_doctor_pose.reach("r", _markers.get("doctor_scratch"))
		"exam_lift_arm", "offer_hand", "exam_palm":
			_doctor_pose.lean(16.0)
			_doctor_pose.reach("r", _markers.get("patient_wrist"))
			_doctor_pose.look_at_node(_markers.get("patient_wrist"))
			if action == "exam_lift_arm" and is_instance_valid(_patient_pose):
				await _wait(1.0, seq)
				if seq != _seq:
					return
				_patient_pose.reach("r", _markers.get("patient_arm_raised"), 1.0)
				await _wait(1.4, seq)
				if seq != _seq:
					return
				# Let go: the doctor's hand comes away; whether the arm stays is the patient's.
				_doctor_pose.reach("r", _markers.get("doctor_let_go"))
				_doctor_pose.look_at_node(_markers.get("patient_arm_raised"))
				if patient_action != "arm_hold_raised":
					_patient_pose.reach("r", null, 0.0)
		"exam_flex_elbow":
			_doctor_pose.lean(16.0)
			_doctor_pose.reach("r", _markers.get("patient_wrist"))
			if is_instance_valid(_patient_pose):
				for i: int in 3:
					_patient_pose.reach("r", _markers.get("patient_elbow_bent"), 0.8)
					await _wait(0.9, seq)
					if seq != _seq:
						return
					_patient_pose.reach("r", null, 0.0)
					await _wait(0.9, seq)
					if seq != _seq:
						return
		"exam_ankle":
			_doctor_pose.lean(48.0)
			_doctor_pose.reach("r", _markers.get("patient_ankle"))
			_doctor_pose.look_at_node(_markers.get("patient_ankle"))
		"offer_cup":
			_show_cup()
			_doctor_pose.lean(10.0)
			_doctor_pose.reach("r", _markers.get("patient_wrist"))
			if patient_action == "take_cup" and is_instance_valid(_patient_pose):
				await _wait(1.2, seq)
				if seq != _seq:
					return
				_doctor_pose.reach("r", null, 0.0)
				_patient_pose.reach("r", _markers.get("patient_mouth"), 1.0)
				_patient_pose.look_at_node(_markers.get("doctor_head"), 0.6)


func _walk_doctor(target: Vector3, seq: int) -> void:
	if not is_instance_valid(doctor):
		return
	var start: Vector3 = doctor.global_position
	var flat: Vector3 = Vector3(target.x, start.y, target.z)
	var distance: float = start.distance_to(flat)
	if distance < 0.05:
		_face(patient.global_position)
		return
	_cut(SHOT_ESTABLISHING)
	var performer: CastPerformer = _performer(doctor)
	_face(flat)
	if performer != null:
		performer.set_walking(true)
	var travelled: float = 0.0
	while travelled < distance and seq == _seq and is_instance_valid(doctor):
		var step: float = minf(WALK_SPEED_M_S * get_process_delta_time(), distance - travelled)
		travelled += step
		doctor.global_position = start.lerp(flat, travelled / distance)
		await get_tree().process_frame
	if performer != null:
		performer.set_walking(false)
	if is_instance_valid(doctor) and is_instance_valid(patient):
		_face(patient.global_position)


func _face(point: Vector3) -> void:
	var to: Vector3 = point - doctor.global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	doctor.rotation.y = atan2(-to.x, -to.z)
	var performer: CastPerformer = _performer(doctor)
	if performer != null:
		performer.set_home_yaw(doctor.rotation.y)


func _wait(seconds: float, seq: int) -> void:
	var waited: float = 0.0
	while waited < seconds and seq == _seq:
		await get_tree().process_frame
		waited += get_process_delta_time()


# --- Set-up -------------------------------------------------------------------------

func _spawn_doctor(at: Vector3) -> void:
	var character: WardCharacter = CHARACTER_SCENE.instantiate()
	character.kind = WardCharacter.Kind.STAFF
	character.character_id = "protagonist_" + ProtagonistProfile.gender()
	character.name = "EncounterPsychiatrist"
	CampaignCastVisuals.configure(character, "")
	add_child(character)
	character.global_position = Vector3(at.x, 0.0, at.z)
	doctor = character
	# The player's own character is not something to walk up to and talk to.
	var interactable: Node = character.get_node_or_null("Interactable")
	if interactable != null:
		interactable.process_mode = Node.PROCESS_MODE_DISABLED
		for shape: Node in interactable.find_children("*", "CollisionShape3D", true, false):
			(shape as CollisionShape3D).disabled = true
	var label: Node3D = character.get_node_or_null("NameLabel") as Node3D
	if label != null:
		label.visible = false
	_apply_profile_colours(character)
	_doctor_pose = _attach_modifier(character)
	_face(patient.global_position)


func _apply_profile_colours(character: Node3D) -> void:
	var profile: Dictionary = ProtagonistProfile.get_profile()
	var options: Dictionary = ProtagonistProfile.options
	var skin: Color = Color(str(options.get("skin_tones", {}).get(profile.get("skin_tone", ""), BUILT_SKIN.to_html())))
	var hair: Color = Color(str(options.get("hair_colors", {}).get(profile.get("hair_color", ""), BUILT_HAIR.to_html())))
	var outfit: Color = Color(str(options.get("outfits", {}).get(profile.get("outfit", ""), BUILT_OUTFIT.to_html())))
	for mesh: MeshInstance3D in character.find_children("*", "MeshInstance3D", true, false):
		var tint: Color = Color.WHITE
		var mesh_name: String = mesh.name.to_lower()
		if mesh_name.ends_with("_body"):
			tint = _ratio(skin, BUILT_SKIN)
		elif mesh_name.ends_with("_hair"):
			if str(profile.get("hair_style", "")) == "none":
				mesh.visible = false
			tint = _ratio(hair, BUILT_HAIR)
		elif mesh_name.ends_with("_trousers"):
			tint = _ratio(outfit, BUILT_OUTFIT)
		if tint == Color.WHITE or mesh.mesh == null:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
			if material == null:
				continue
			var copy: StandardMaterial3D = material.duplicate() as StandardMaterial3D
			copy.albedo_color = material.albedo_color * tint
			mesh.set_surface_override_material(surface, copy)


static func _ratio(wanted: Color, built: Color) -> Color:
	return Color(wanted.r / maxf(built.r, 0.02), wanted.g / maxf(built.g, 0.02), wanted.b / maxf(built.b, 0.02))


func _attach_modifier(actor: Node3D) -> ExamPoseModifier:
	if actor == null:
		return null
	var skeleton: Skeleton3D = null
	for node: Node in actor.find_children("*", "Skeleton3D", true, false):
		skeleton = node as Skeleton3D
		break
	if skeleton == null:
		return null
	var modifier: ExamPoseModifier = ExamPoseModifier.new()
	modifier.name = "ExamPoseModifier"
	skeleton.add_child(modifier)
	return modifier


func _bone_marker(actor: Node3D, bone: String, name_hint: String, offset: Vector3 = Vector3.ZERO) -> Node3D:
	var skeleton: Skeleton3D = null
	if actor != null:
		for node: Node in actor.find_children("*", "Skeleton3D", true, false):
			skeleton = node as Skeleton3D
			break
	var marker: Node3D = Node3D.new()
	marker.name = name_hint
	if skeleton == null or skeleton.find_bone(bone) < 0:
		add_child(marker)
		marker.global_position = (actor.global_position if actor != null else Vector3.ZERO) + Vector3.UP * 1.2 + offset
		return marker
	var attachment: BoneAttachment3D = BoneAttachment3D.new()
	attachment.name = "Attach_" + name_hint
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	_props.append(attachment)
	attachment.add_child(marker)
	marker.position = offset
	return marker


func _fixed_marker(name_hint: String, at: Vector3) -> Node3D:
	var marker: Node3D = Node3D.new()
	marker.name = name_hint
	add_child(marker)
	marker.global_position = at
	return marker


func _make_markers(base: Vector3, forward: Vector3, right: Vector3) -> void:
	_markers["patient_head"] = _bone_marker(patient, "head", "patient_head", Vector3(0, 0.08, 0))
	_markers["patient_wrist"] = _bone_marker(patient, "hand_r", "patient_wrist")
	_markers["patient_ankle"] = _bone_marker(patient, "foot_r", "patient_ankle")
	var head: Vector3 = (_markers["patient_head"] as Node3D).global_position
	var shoulder_height: float = head.y - 0.3
	_markers["patient_face"] = _fixed_marker("patient_face", head + forward * 0.28 - Vector3.UP * 0.05)
	_markers["patient_mouth"] = _fixed_marker("patient_mouth", head + forward * 0.16 - Vector3.UP * 0.14 + right * 0.04)
	_markers["patient_arm_raised"] = _fixed_marker("patient_arm_raised", base + forward * 0.6 + right * 0.2 + Vector3.UP * shoulder_height)
	_markers["patient_elbow_bent"] = _fixed_marker("patient_elbow_bent", base + forward * 0.32 + right * 0.2 + Vector3.UP * (shoulder_height - 0.05))
	_markers["doctor_head"] = _bone_marker(doctor, "head", "doctor_head", Vector3(0, 0.08, 0))
	_markers["doctor_scratch"] = _bone_marker(doctor, "head", "doctor_scratch", Vector3(0, 0.16, 0))
	_markers["doctor_watch"] = _bone_marker(doctor, "hand_r", "doctor_watch", Vector3(0, 0, 0))
	_markers["doctor_let_go"] = _fixed_marker("doctor_let_go", _exam_spot + forward * 0.25 + Vector3.UP * 1.0)
	_markers["sitter_head"] = _bone_marker(sitter, "head", "sitter_head", Vector3(0, 0.08, 0))
	if sitter != null:
		var s_forward: Vector3 = -sitter.global_basis.z
		s_forward.y = 0.0
		var chest: Vector3 = sitter.global_position + Vector3.UP * 1.12 + s_forward.normalized() * 0.32
		var s_right: Vector3 = s_forward.normalized().cross(Vector3.UP)
		_markers["sitter_clipboard"] = _fixed_marker("sitter_clipboard", chest - s_right * 0.08)
		_markers["sitter_clipboard_r"] = _fixed_marker("sitter_clipboard_r", chest + s_right * 0.1 - Vector3.UP * 0.05)


func _show_clipboard() -> void:
	if _markers.has("clipboard_prop"):
		(_markers["clipboard_prop"] as Node3D).visible = true
		return
	var hand: Node3D = _bone_marker(sitter, "hand_l", "clipboard_prop", Vector3(0.0, 0.08, 0.04))
	var board: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.23, 0.31, 0.012)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#8C6A48")
	box.material = material
	board.mesh = box
	hand.add_child(board)
	_markers["clipboard_prop"] = hand


func _show_cup() -> void:
	if _markers.has("cup_prop"):
		(_markers["cup_prop"] as Node3D).visible = true
		return
	var hand: Node3D = _bone_marker(patient, "hand_r", "cup_prop", Vector3(0.0, 0.06, 0.03))
	var cup: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.04
	cylinder.bottom_radius = 0.034
	cylinder.height = 0.1
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#E9ECEF")
	cylinder.material = material
	cup.mesh = cylinder
	hand.add_child(cup)
	_markers["cup_prop"] = hand


func _hide_props() -> void:
	for key: String in ["clipboard_prop"]:
		if _markers.has(key):
			(_markers[key] as Node3D).visible = false


func _performer(actor: Node3D) -> CastPerformer:
	if actor == null:
		return null
	return actor.find_child("CastPerformer", true, false) as CastPerformer


func _cut(shot: String) -> void:
	var world: Node = get_parent()
	var camera: Camera3D = world.find_child(shot, true, false) as Camera3D if world != null else null
	if camera != null:
		camera.make_current()


func _cut_camera(camera: Camera3D) -> void:
	if is_instance_valid(camera):
		camera.make_current()
