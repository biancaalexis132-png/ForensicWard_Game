extends Node
## Exercises real actor resolution and cancellation while a voiced shot is live.
func _ready() -> void:
	var pilot: Node3D = load("res://scenes/cinematic/NaomiHandover.tscn").instantiate() as Node3D
	add_child(pilot)
	await get_tree().process_frame
	await get_tree().process_frame
	var actor: WardCharacter = pilot.get("_actor") as WardCharacter
	var camera: Camera3D = pilot.get("_camera") as Camera3D
	if actor == null or not actor.visual_error.is_empty() or camera == null or not camera.current:
		push_error("Cinematic did not resolve the live cast and camera")
		get_tree().quit(1)
		return
	var expected: String = str(CampaignCastVisuals.load_data()["characters"]["staff_bennett"]["scene"])
	if actor.visual_scene.resource_path != expected or not AudioDirector.is_dialogue_playing():
		push_error("Cinematic is not using the gameplay cast and dialogue")
		get_tree().quit(1)
		return
	var cancel: InputEventAction = InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	pilot.call("_unhandled_input", cancel)
	await get_tree().process_frame
	if not pilot.get("_did_finish") or AudioDirector.is_dialogue_playing():
		push_error("Cinematic cancellation did not stop playback")
		get_tree().quit(1)
		return
	pilot.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	print("CINEMATIC_CANCEL_TEST: 3 passed / 0 failed")
	get_tree().quit()
