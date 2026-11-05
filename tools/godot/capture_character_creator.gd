extends Node
## Review captures of "Choose your psychiatrist" (New Game > character creator):
## the default male psychiatrist, a styled female psychiatrist, borrowed hairstyles
## on each model and face close-ups with glasses. Windowed Compatibility-renderer
## capture; not Mac acceptance.
##
##   Godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
##       --resolution 1920x1080 res://tools/godot/CaptureCharacterCreator.tscn -- --output-dir=/absolute/dir
## Writes creator_*.png.

const SHOTS: Array = [
	["creator_default_male.png", {}, "body"],
	["creator_female_styled.png", {"gender": "female", "skin_tone": "brown", "hair_color": "black", "hair_style": "long", "top": "sage", "outfit": "charcoal", "glasses": "rectangular"}, "body"],
	["creator_male_long_hair.png", {"gender": "male", "skin_tone": "light", "hair_color": "auburn", "hair_style": "long", "top": "sky", "outfit": "khaki"}, "body"],
	["creator_female_short_hair.png", {"gender": "female", "skin_tone": "porcelain", "hair_color": "copper", "hair_style": "short", "top": "lilac", "outfit": "black"}, "body"],
	["creator_face_male_round.png", {"gender": "male", "skin_tone": "deep", "hair_color": "grey", "hair_style": "short", "glasses": "round", "top": "white"}, "face"],
	["creator_face_female_bold.png", {"gender": "female", "skin_tone": "tan", "hair_color": "blond", "hair_style": "swept", "glasses": "bold", "top": "plum"}, "face"],
	["creator_face_female_short.png", {"gender": "female", "skin_tone": "porcelain", "hair_color": "copper", "hair_style": "short", "glasses": "none", "top": "lilac"}, "face"],
	["creator_face_male_long.png", {"gender": "male", "skin_tone": "light", "hair_color": "auburn", "hair_style": "long", "glasses": "none", "top": "sky"}, "face"],
]


func _ready() -> void:
	var output_dir: String = "user://"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	Settings.persist = false
	SaveManager.reset_all()
	var main: Node = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	await _frames(10)
	AudioDirector.cancel_pending_events()
	# Only the title art shows behind the creator; skip drawing the ward.
	var world: Node3D = main.get_node_or_null("World") as Node3D
	if world != null:
		world.visible = false
	var title: TitleScreen = main.get_node("TitleScreen")
	title.open()
	await _frames(4)
	title.choose_psychiatrist()
	await _frames(10)
	var creator: ProtagonistScreen = main.get_node("ProtagonistScreen")
	for shot: Array in SHOTS:
		for field: String in shot[1]:
			creator.choose(field, str(shot[1][field]))
		creator._preview.framing = shot[2]
		await _frames(6)
		await _save(output_dir, shot[0])
		creator._preview.turn(PI * 0.75)
		await _save(output_dir, shot[0].replace(".png", "_side.png"))
		creator._preview.turn(-PI * 0.75)
	AudioDirector.stop_music(0.01)
	main.free()
	await _frames(4)
	print("CREATOR_CAPTURE_DONE")
	get_tree().quit()


func _save(output_dir: String, file_name: String) -> void:
	await _frames(8)
	var path: String = output_dir.path_join(file_name)
	var result: Error = get_viewport().get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Capture failed: %s (%s)" % [path, error_string(result)])
	else:
		print("wrote ", path)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame
