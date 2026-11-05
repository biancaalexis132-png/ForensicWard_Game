extends TestCase
## Faces, eyes and the beat before a reply for the shared cast (ConversationPerformance).

const CHARACTER_SCENE: PackedScene = preload("res://scenes/props/Character.tscn")
const VOSS_LINE: String = "ch1_v_3556aa2f5b"
const MARA_LINE: String = "ch2_v_0112ade4ec"

var _characters: Array[WardCharacter] = []


func before_each() -> void:
	super.before_each()
	CharacterVisualPreview.set_requests({})


func after_each() -> void:
	AudioDirector.stop_dialogue()
	for character: WardCharacter in _characters:
		if is_instance_valid(character):
			character.free()
	_characters.clear()
	CharacterVisualPreview.reset()
	super.after_each()


func test_data_is_valid_and_patients_stay_neutral() -> void:
	check_eq(ConversationPerformance.validate(), [] as Array[String], "cast_performance.json is valid")
	var patient: Dictionary = ConversationPerformance.profile_for("pt_elias_ward", false)
	check_eq(str(patient["speaking_face"]), "neutral", "patients keep a neutral face while they speak")
	check((patient["gaze_breaks"] as Array).is_empty(), "patients never look away mid-line")
	check_eq(float(patient["beat_seconds"]), 0.0, "patients never pause before replying")
	var hale: Dictionary = ConversationPerformance.profile_for("staff_hale", true)
	var voss: Dictionary = ConversationPerformance.profile_for("staff_voss", true)
	check(hale["speaking_face"] != voss["speaking_face"] or hale["gaze_breaks"] != voss["gaze_breaks"],
			"Hale and Voss each have their own manner")


func test_every_draft_cast_member_gets_the_layer_except_naomi() -> void:
	for id: String in ["staff_voss", "staff_hale", "staff_rahman", "staff_facilities_tech", "pt_elias_ward"]:
		var character: WardCharacter = _spawn(id)
		check(character.performer != null and character.performer.conversation != null, id + " gets faces and eyes")
		check(character.performer.conversation.gaze != null, id + " has a gaze rig to drive")
	var naomi: WardCharacter = _spawn("staff_bennett")
	check(naomi.performer == null or naomi.performer.conversation == null, "Naomi keeps her own acting controller")


func test_face_follows_listening_and_speaking() -> void:
	var voss: WardCharacter = _spawn("staff_voss")
	var acting: ConversationPerformance = voss.performer.conversation
	acting.tick(0.1)
	check_eq(acting.wanted_face(), "neutral", "idle is neutral")
	voss.performer.begin_conversation()
	_step(acting, 1.0)
	var listening: String = str(acting.profile["listening_face"])
	check_eq(acting.wanted_face(), listening, "listening shows the listening face")
	check(acting.face_weight(listening) > 0.95, "and it eases fully in")
	EventBus.subtitle_shown.emit(VOSS_LINE, "Dr. Voss", "A test line.", 6.0)
	_step(acting, 1.0)
	var speaking: String = str(acting.profile["speaking_face"])
	check_eq(acting.wanted_face(), speaking, "speaking shows the speaking face")
	if speaking != listening:
		check(acting.face_weight(listening) < 0.05, "the listening face eases out")
	check(acting.face_weight(speaking) > 0.95, "the speaking face eases in")


func test_eyes_look_away_at_their_own_rhythm_while_speaking() -> void:
	var voss: WardCharacter = _spawn("staff_voss")
	var acting: ConversationPerformance = voss.performer.conversation
	voss.performer.begin_conversation()
	EventBus.subtitle_shown.emit(VOSS_LINE, "Dr. Voss", "A long line.", 20.0)
	var away: int = 0
	var on_player: int = 0
	for i: int in 180:
		acting.tick(0.1)
		match acting.gaze.get_gaze_directive():
			&"away":
				away += 1
			&"player":
				on_player += 1
	check(away > 0, "they look away at least once in a long line")
	check(on_player > away * 4, "but mostly hold your eyes (%d on you, %d away)" % [on_player, away])


func test_a_choice_brings_a_beat_before_the_reply() -> void:
	var voss: WardCharacter = _spawn("staff_voss")
	var acting: ConversationPerformance = voss.performer.conversation
	var gestures: AnimationPlayer = _model(voss).find_child(CharacterActingAdapter.GESTURE_PLAYER_NAME, true, false) as AnimationPlayer
	voss.performer.begin_conversation()
	gestures.stop()
	EventBus.story_option_selected.emit("test_interaction", "test_option")
	EventBus.subtitle_shown.emit(VOSS_LINE, "Dr. Voss", "A reply.", 6.0)
	acting.tick(0.05)
	check(acting.in_beat(), "the reply opens with a beat")
	check_eq(acting.gaze.get_gaze_directive(), &"away", "eyes lowered while they gather themselves")
	check_eq(gestures.current_animation, ConversationPerformance.BEAT_GESTURE, "with the thinking gesture")
	check_eq(acting.wanted_face(), str(acting.profile["beat_face"]), "and their thinking face")
	_step(acting, 1.5)
	check(not acting.in_beat(), "the beat is short")
	check_eq(acting.gaze.get_gaze_directive(), &"player", "then they look at you")
	EventBus.dialogue_line_finished.emit(VOSS_LINE, true)
	EventBus.subtitle_shown.emit(VOSS_LINE, "Dr. Voss", "Another line.", 6.0)
	acting.tick(0.05)
	check(not acting.in_beat(), "only the reply to a choice gets a beat")


func test_patients_never_pause_or_look_away() -> void:
	check_eq(str(AudioDirector.get_line(MARA_LINE).get("speaker", "")), "pt_mara_ellis", "fixture line is Mara's")
	var mara: WardCharacter = _spawn("pt_mara_ellis", true)
	var acting: ConversationPerformance = mara.performer.conversation
	mara.performer.begin_conversation()
	EventBus.story_option_selected.emit("test_interaction", "test_option")
	EventBus.subtitle_shown.emit(MARA_LINE, "Mara Ellis", "A long answer.", 20.0)
	acting.tick(0.05)
	check(mara.performer.is_speaking(), "she is speaking")
	check(not acting.in_beat(), "no beat for a patient")
	check_eq(acting.wanted_face(), "neutral", "a neutral face while she speaks")
	var averted: bool = false
	for i: int in 180:
		acting.tick(0.1)
		averted = averted or acting.gaze.get_gaze_directive() == &"away"
	check(not averted, "a patient's eyes never avert")


func test_idle_eyes_rest_instead_of_staring() -> void:
	var voss: WardCharacter = _spawn("staff_voss")
	var acting: ConversationPerformance = voss.performer.conversation
	acting.tick(0.1)
	check_eq(acting.gaze.get_gaze_directive(), &"rest", "nobody is talking to her and you are not close: eyes rest")


func test_gaze_rig_point_and_away_directives() -> void:
	var gaze: CharacterGazeRig = CharacterGazeRig.new()
	gaze.look_away(Vector2(90.0, -90.0))
	check_eq(gaze.get_gaze_directive(), &"away", "look_away sets the away directive")
	check_eq(gaze._target_angles(), Vector2(CharacterGazeRig.MAX_YAW_DEG, -CharacterGazeRig.MAX_PITCH_DEG), "clamped to what eyes can do")
	gaze.free()


# --------------------------------------------------------------------------- helpers

func _step(acting: ConversationPerformance, seconds: float) -> void:
	var steps: int = int(seconds / 0.05)
	for i: int in steps:
		acting.tick(0.05)


func _spawn(id: String, seated: bool = false) -> WardCharacter:
	var character: WardCharacter = CHARACTER_SCENE.instantiate() as WardCharacter
	character.kind = WardCharacter.Kind.PATIENT if id.begins_with("pt_") else WardCharacter.Kind.STAFF
	character.character_id = id
	character.seated = seated
	character.visual_scene = load(CampaignCastVisuals.load_data()["characters"][id]["scene"]) as PackedScene
	runner.add_child(character)
	_characters.append(character)
	return character


func _model(character: WardCharacter) -> Node3D:
	var root: Node3D = character.get_node("VisualRoot")
	return root.get_child(0) as Node3D if root.get_child_count() > 0 else null
