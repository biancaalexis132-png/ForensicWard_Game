extends TestCase
## "Choose your psychiatrist": the character creator that New Game opens. Female or
## male picks the model and the recorded voice; style choices dress the real model
## (ProtagonistAppearance) the same way in the preview and in the encounter.

const MAIN_SCENE: String = "res://scenes/main/Main.tscn"
const SCREEN_SCENE: String = "res://scenes/ui/ProtagonistScreen.tscn"

var _main: Node3D = null
var _panel: ProtagonistScreen = null
var _started: int = 0


func after_each() -> void:
	if is_instance_valid(_panel):
		_panel.free()
	if is_instance_valid(_main):
		_main.free()
	ProtagonistProfile.reset_state()
	super.after_each()


func _open_panel() -> ProtagonistScreen:
	_panel = load(SCREEN_SCENE).instantiate()
	runner.add_child(_panel)
	_panel.open()
	return _panel


func _on_started() -> void:
	_started += 1


func test_style_catalogs_offer_real_variety() -> void:
	var options: Dictionary = ProtagonistProfile.options
	check(options["skin_tones"].size() >= 6, "at least six skin tones")
	check(options["hair_colors"].size() >= 6, "at least six hair colours")
	check_eq(options["hair_styles"].keys(), ["short", "long", "swept", "none"], "four hairstyles, old ids kept")
	check(options["tops"].size() >= 5 and options["outfits"].size() >= 5, "shirts and trousers to choose from")
	check_eq(options["glasses"].keys(), ["none", "round", "rectangular", "bold"], "glasses choices")
	for catalog: String in ["skin_tones", "hair_colors", "tops", "outfits"]:
		for id: String in options[catalog]:
			check(str(options[catalog][id]).begins_with("#"), "%s.%s is a colour" % [catalog, id])
	for style: String in options["hair_styles"]:
		check(ProtagonistAppearance.HAIR_STYLES.has(style), "hairstyle %s has meshes" % style)
	for id: String in options["glasses"]:
		check(id == "none" or ProtagonistAppearance.GLASSES.has(id), "glasses %s has frames" % id)


func test_new_style_fields_save_and_old_profiles_still_load() -> void:
	var draft: Dictionary = ProtagonistProfile.get_profile()
	check_eq(draft["top"], "white", "default shirt")
	check_eq(draft["glasses"], "none", "no glasses by default")
	draft["top"] = "sage"
	draft["glasses"] = "round"
	draft["hair_style"] = "swept"
	check(ProtagonistProfile.apply_draft(draft), "new style choices are accepted")
	var saved: Variant = JSON.parse_string(JSON.stringify(ProtagonistProfile.to_save_data()))
	ProtagonistProfile.reset_state()
	ProtagonistProfile.load_save_data(saved)
	check_eq(ProtagonistProfile.get_profile()["glasses"], "round", "glasses survive save and load")
	check_eq(ProtagonistProfile.get_profile()["top"], "sage", "shirt survives save and load")
	var legacy: Dictionary = ProtagonistProfile.default_data()
	legacy.erase("top")
	legacy.erase("glasses")
	legacy["name"] = "Dr Older Save"
	check(ProtagonistProfile.validate_save_data(legacy), "a profile from before the style choices is valid")
	ProtagonistProfile.load_save_data(legacy)
	check_eq(ProtagonistProfile.get_profile()["name"], "Dr Older Save", "and loads")
	check_eq(ProtagonistProfile.get_profile()["glasses"], "none", "with no glasses")
	draft = ProtagonistProfile.get_profile()
	draft["glasses"] = "monocle"
	check(not ProtagonistProfile.apply_draft(draft), "an unknown style id is rejected")
	var bad: Dictionary = ProtagonistProfile.default_data()
	bad["top"] = 3
	check(not ProtagonistProfile.validate_save_data(bad), "a non-text shirt is rejected")


func test_creator_swaps_model_and_voice_with_the_body_choice() -> void:
	var panel: ProtagonistScreen = _open_panel()
	check(panel._preview.get_model() != null, "the preview shows a model")
	check(panel._preview.get_model().find_child("Psychiatrist_Male_Body", true, false) != null, "the default is the male psychiatrist")
	panel.choose("gender", "female")
	check(panel._preview.get_model().find_child("Psychiatrist_Female_Body", true, false) != null, "choosing female shows the female model")
	panel.play_voice_sample()
	check(panel._voice_player.stream != null and "/female/" in panel._voice_player.stream.resource_path, "Hear voice plays the female recording")
	panel.choose("gender", "male")
	panel.play_voice_sample()
	check(panel._voice_player.stream != null and not "/female/" in panel._voice_player.stream.resource_path, "and the male recording for a male psychiatrist")
	check_eq(AudioDirector.get_voice_variant("player"), "", "previewing does not change the game's voice before confirming")
	panel.choose("gender", "female")
	panel.confirm()
	check_eq(AudioDirector.get_voice_variant("player"), "female", "confirming switches every psychiatrist line to the female voice")


func test_style_choices_dress_the_preview_model() -> void:
	var panel: ProtagonistScreen = _open_panel()
	panel.choose("hair_style", "long")
	var model: Node3D = panel._preview.get_model()
	check(model.find_child("Borrowed_PsyF_Hair_Ponytail", true, false) != null, "long hair on the male model borrows the tied-back hair")
	check(not (model.find_child("PsyM_Hair", true, false) as MeshInstance3D).visible, "and hides his own short hair")
	panel.choose("hair_style", "none")
	check(model.find_child("Borrowed_PsyF_Hair_Ponytail", true, false) == null, "changing style removes the borrowed hair")
	check(not (model.find_child("PsyM_Hair", true, false) as MeshInstance3D).visible, "no hair shows nothing")
	panel.choose("gender", "female")
	panel.choose("hair_style", "short")
	model = panel._preview.get_model()
	check(model.find_child("Borrowed_PsyM_Hair", true, false) != null, "short hair on the female model borrows the short crop")
	check(not (model.find_child("PsyF_Hair_Ponytail", true, false) as MeshInstance3D).visible, "and hides the ponytail")
	panel.choose("glasses", "round")
	check(model.find_child("Glasses", true, false) is BoneAttachment3D, "glasses sit on the head bone")
	panel.choose("glasses", "none")
	check(model.find_child("Glasses", true, false) == null, "and come off again")
	panel.choose("top", "plum")
	var shirt: MeshInstance3D = model.find_child("PsyF_Shirt", true, false)
	var tinted: StandardMaterial3D = shirt.material_override as StandardMaterial3D
	check(tinted != null, "the shirt gets its own material")
	if tinted != null:
		var wanted: Color = Color(str(ProtagonistProfile.options["tops"]["plum"]))
		var built: Color = ProtagonistAppearance.BUILT_SHIRT
		check(absf(tinted.albedo_color.r * built.r - wanted.r) < 0.01, "tinted toward the chosen colour")
	var body: MeshInstance3D = model.find_child("Psychiatrist_Female_Body", true, false)
	check(body.get_surface_override_material(1) == null, "eyelashes keep their own colour")


func test_borrowed_hair_sits_on_the_wearers_head() -> void:
	var panel: ProtagonistScreen = _open_panel()
	panel.choose("hair_style", "long")
	var model: Node3D = panel._preview.get_model()
	var skeleton: Skeleton3D = ProtagonistAppearance._skeleton(model)
	var borrowed: MeshInstance3D = model.find_child("Borrowed_PsyF_Hair", true, false)
	var head: int = skeleton.find_bone("head")
	var bind: Transform3D = Transform3D.IDENTITY
	for index: int in borrowed.skin.get_bind_count():
		if borrowed.skin.get_bind_name(index) == "head":
			bind = borrowed.skin.get_bind_pose(index)
	# At rest the borrowed cap's box must land on the wearer's own cap box.
	var from: AABB = ProtagonistAppearance._source("female")["cap"]
	var to: AABB = ProtagonistAppearance._source("male")["cap"]
	check(from.size.x > 0.0 and to.size.x > 0.0, "both models have a hair cap")
	for corner: Vector3 in [from.position, from.end]:
		var placed: Vector3 = skeleton.get_bone_global_rest(head) * (bind * corner)
		var wanted: Vector3 = to.position if corner == from.position else to.end
		check(placed.distance_to(wanted) < 0.001, "borrowed hair covers the wearer's own hair line")


func test_surprise_me_keeps_body_voice_and_name() -> void:
	var panel: ProtagonistScreen = _open_panel()
	panel.choose("gender", "female")
	(panel._fields["name"] as LineEdit).text_changed.emit("Dr Ana Ruiz")
	for i: int in 6:
		panel.randomize_style()
	check_eq(panel.selected("gender"), "female", "body and voice stay as chosen")
	check_eq(str(panel._draft["name"]), "Dr Ana Ruiz", "name stays")
	for spec: Array in ProtagonistScreen.STYLE_ROWS:
		check(ProtagonistProfile.options[spec[1]].has(panel.selected(spec[0])), "%s is a valid choice" % spec[0])
	panel.confirm()
	check_eq(ProtagonistProfile.get_profile()["name"], "Dr Ana Ruiz", "confirm saves the result")


func test_new_game_opens_the_creator_before_the_shift() -> void:
	_main = load(MAIN_SCENE).instantiate()
	runner.add_child(_main)
	await runner.get_tree().process_frame
	var title: TitleScreen = _main.get_node("TitleScreen")
	title.open()
	title.new_game_started.connect(_on_started)
	_started = 0
	title.choose_psychiatrist()
	var creator: ProtagonistScreen = _main.get_node_or_null("ProtagonistScreen")
	check(creator != null and creator.is_open, "New Game opens the character creator")
	if creator == null:
		return
	check_eq(creator._confirm_button.text, "Begin the shift", "the creator starts the game")
	check(title.is_open and _started == 0, "the title waits behind it")
	creator.close()
	check(title.is_open and _started == 0, "Back returns to the title without starting")
	title.choose_psychiatrist()
	creator.choose("gender", "female")
	creator.confirm()
	check_eq(_started, 1, "Begin starts the new game")
	check(not title.is_open and not creator.is_open, "and both screens close")
	check_eq(ProtagonistProfile.gender(), "female", "with the chosen psychiatrist")
	check(ProtagonistProfile.get_profile()["configured"], "the profile is marked chosen")
