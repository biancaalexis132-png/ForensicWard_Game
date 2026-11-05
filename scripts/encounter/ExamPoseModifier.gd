class_name ExamPoseModifier
extends SkeletonModifier3D
## ExamPoseModifier: procedural reach, look and lean on top of a character's
## playing clips, for the bedside examination (EncounterStage).
##
## Runs after the AnimationPlayer each frame. Each arm chain (upper arm,
## forearm, hand) reaches a Node3D target with analytic two-bone IK bent
## toward a pole; the head turns toward a look target; the upper spine leans
## forward. Every effect has its own weight, eased by ease_to(), so the clip
## underneath shows through at weight 0. Bones use the shared game_engine rig
## names (upperarm_r, lowerarm_r, hand_r, spine_02, head). Cosmetic only.

const ARMS: Dictionary = {
	"r": ["upperarm_r", "lowerarm_r", "hand_r"],
	"l": ["upperarm_l", "lowerarm_l", "hand_l"],
}
const MAX_LOOK_DEGREES: float = 75.0
const EASE_RATE: float = 2.6

## side ("r"/"l") -> {target: Node3D, weight: float, goal: float}
var arms: Dictionary = {}
var look_target: Node3D = null
var look_weight: float = 0.0
var look_goal: float = 0.0
var lean_degrees: float = 0.0
var lean_weight: float = 0.0
var lean_goal: float = 0.0

var _forward: Vector3 = Vector3.ZERO  ## character forward in skeleton space (rest)


## Reach with an arm ("r"/"l") toward target; goal 0 releases it.
func reach(side: String, target: Node3D, goal: float = 1.0) -> void:
	var entry: Dictionary = arms.get(side, {"target": target, "weight": 0.0, "goal": 0.0})
	if target != null:
		entry["target"] = target
	entry["goal"] = goal
	arms[side] = entry


func look_at_node(target: Node3D, goal: float = 1.0) -> void:
	if target != null:
		look_target = target
	look_goal = goal


func lean(degrees: float, goal: float = 1.0) -> void:
	lean_degrees = degrees
	lean_goal = goal


func release_all() -> void:
	for side: String in arms:
		arms[side]["goal"] = 0.0
	look_goal = 0.0
	lean_goal = 0.0


## True while any effect is still easing.
func is_settling() -> bool:
	if absf(look_weight - look_goal) > 0.01 or absf(lean_weight - lean_goal) > 0.01:
		return true
	return arms.values().any(func(a: Dictionary) -> bool: return absf(float(a["weight"]) - float(a["goal"])) > 0.01)


func hand_bone_position(side: String) -> Vector3:
	var skeleton: Skeleton3D = get_skeleton()
	var idx: int = skeleton.find_bone(ARMS[side][2]) if skeleton != null else -1
	if idx < 0:
		return Vector3.ZERO
	return skeleton.global_transform * skeleton.get_bone_global_pose(idx).origin


func _process_modification_with_delta(delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null:
		return
	if _forward == Vector3.ZERO:
		_forward = _rest_forward(skeleton)
	look_weight = move_toward(look_weight, look_goal, EASE_RATE * delta)
	lean_weight = move_toward(lean_weight, lean_goal, EASE_RATE * delta)
	for side: String in arms:
		arms[side]["weight"] = move_toward(float(arms[side]["weight"]), float(arms[side]["goal"]), EASE_RATE * delta)
	if lean_weight > 0.001:
		_apply_lean(skeleton, _smooth(lean_weight))
	for side: String in arms:
		var weight: float = _smooth(float(arms[side]["weight"]))
		var target: Node3D = arms[side]["target"]
		if weight > 0.001 and is_instance_valid(target):
			_apply_arm(skeleton, ARMS[side], skeleton.global_transform.affine_inverse() * target.global_position, weight)
	if look_weight > 0.001 and is_instance_valid(look_target):
		_apply_look(skeleton, skeleton.global_transform.affine_inverse() * look_target.global_position, _smooth(look_weight))


static func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


## Forward at rest, from the heel-to-toe direction of the left foot.
static func _rest_forward(skeleton: Skeleton3D) -> Vector3:
	var foot: int = skeleton.find_bone("foot_l")
	var ball: int = skeleton.find_bone("ball_l")
	if foot < 0 or ball < 0:
		return Vector3(0, 0, 1)
	var d: Vector3 = skeleton.get_bone_global_rest(ball).origin - skeleton.get_bone_global_rest(foot).origin
	d.y = 0.0
	return d.normalized() if d.length() > 0.001 else Vector3(0, 0, 1)


func _set_global_rotation(skeleton: Skeleton3D, idx: int, global_basis: Basis, weight: float) -> void:
	var parent: int = skeleton.get_bone_parent(idx)
	var parent_basis: Basis = skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var local: Quaternion = (parent_basis.inverse() * global_basis).get_rotation_quaternion()
	var current: Quaternion = skeleton.get_bone_pose_rotation(idx)
	skeleton.set_bone_pose_rotation(idx, current.slerp(local.normalized(), weight))


func _apply_lean(skeleton: Skeleton3D, weight: float) -> void:
	var idx: int = skeleton.find_bone("spine_02")
	if idx < 0:
		return
	var axis: Vector3 = Vector3.UP.cross(_forward).normalized()
	var pose: Transform3D = skeleton.get_bone_global_pose(idx)
	_set_global_rotation(skeleton, idx, Basis(Quaternion(axis, deg_to_rad(lean_degrees))) * pose.basis, weight)


func _apply_arm(skeleton: Skeleton3D, bones: Array, target: Vector3, weight: float) -> void:
	var upper: int = skeleton.find_bone(bones[0])
	var lower: int = skeleton.find_bone(bones[1])
	var hand: int = skeleton.find_bone(bones[2])
	var chest: int = skeleton.find_bone("spine_03")
	if upper < 0 or lower < 0 or hand < 0:
		return
	var upper_pose: Transform3D = skeleton.get_bone_global_pose(upper)
	var lower_pose: Transform3D = skeleton.get_bone_global_pose(lower)
	var hand_pose: Transform3D = skeleton.get_bone_global_pose(hand)
	var a: Vector3 = upper_pose.origin
	var b: Vector3 = lower_pose.origin
	var c: Vector3 = hand_pose.origin
	var l1: float = a.distance_to(b)
	var l2: float = b.distance_to(c)
	var to_target: Vector3 = target - a
	var d: float = clampf(to_target.length(), 0.05, l1 + l2 - 0.002)
	var n: Vector3 = to_target.normalized()
	# The elbow bends outward and down, away from the chest.
	var side: Vector3 = a - (skeleton.get_bone_global_pose(chest).origin if chest >= 0 else a - Vector3.RIGHT)
	side.y = 0.0
	var pole: Vector3 = a + side.normalized() * 0.4 + Vector3.DOWN * 0.6 - _forward * 0.15
	var m: Vector3 = (pole - a) - n * (pole - a).dot(n)
	m = m.normalized() if m.length() > 0.0001 else Vector3.DOWN
	var cos_a: float = clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0)
	var elbow: Vector3 = a + l1 * (n * cos_a + m * sqrt(1.0 - cos_a * cos_a))
	var reach_point: Vector3 = a + n * d
	var q1: Quaternion = Quaternion((b - a).normalized(), (elbow - a).normalized())
	var upper_basis: Basis = Basis(q1) * upper_pose.basis
	_set_global_rotation(skeleton, upper, upper_basis, weight)
	# Recompute the forearm from the blended upper arm before aiming it.
	var upper_new: Transform3D = skeleton.get_bone_global_pose(upper)
	var lower_new: Transform3D = upper_new * skeleton.get_bone_pose(lower)
	var hand_new: Vector3 = (lower_new * skeleton.get_bone_pose(hand)).origin
	var q2: Quaternion = Quaternion((hand_new - lower_new.origin).normalized(), (reach_point - lower_new.origin).normalized())
	var parent_basis: Basis = upper_new.basis
	var local: Quaternion = (parent_basis.inverse() * (Basis(q2) * lower_new.basis)).get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(lower, skeleton.get_bone_pose_rotation(lower).slerp(local.normalized(), weight))


func _apply_look(skeleton: Skeleton3D, target: Vector3, weight: float) -> void:
	var idx: int = skeleton.find_bone("head")
	if idx < 0:
		return
	var pose: Transform3D = skeleton.get_bone_global_pose(idx)
	var rest: Transform3D = skeleton.get_bone_global_rest(idx)
	var facing: Vector3 = pose.basis * (rest.basis.inverse() * _forward)
	var wanted: Vector3 = (target - pose.origin).normalized()
	var angle: float = facing.angle_to(wanted)
	if angle < 0.001:
		return
	var limit: float = minf(1.0, deg_to_rad(MAX_LOOK_DEGREES) / angle)
	var q: Quaternion = Quaternion(facing.normalized(), wanted)
	q = Quaternion.IDENTITY.slerp(q, limit)
	_set_global_rotation(skeleton, idx, Basis(q) * pose.basis, weight)
