extends SceneTree
## Bounded, read-only import and morph smoke test for both v06 candidates.
## godot --headless --path . --script tools/godot/validate_naomi_v06.gd
## This proves Godot accepts shape values, not that the face looks correct.

func _initialize() -> void:
	call_deferred("_validate")


func _validate() -> void:
	var failures: int = 0
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/character_animation/mpfb_face_mapping.json"))
	var expected: Array = mapping["stable_shapes"].keys()
	for viseme: String in mapping["visemes"]:
		expected.append("viseme_" + viseme)
	for version: String in ["v06", "v06_mpfb"]:
		var path: String = "res://assets/exports/characters/Naomi_Bennett_%s.glb" % version
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			push_error("Cannot load " + path)
			failures += 1
			continue
		var model: Node = packed.instantiate()
		root.add_child(model)
		var body: MeshInstance3D = null
		for node: Node in model.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.find_blend_shape_by_name(&"mouth_open") >= 0:
				body = mesh
		if body == null:
			push_error(version + ": no face mesh")
			failures += 1
		else:
			var missing: Array[String] = []
			for shape: String in expected:
				var index: int = body.find_blend_shape_by_name(StringName(shape))
				if index < 0:
					missing.append(shape)
					continue
				body.set_blend_shape_value(index, 1.0)
				if not is_equal_approx(body.get_blend_shape_value(index), 1.0):
					failures += 1
				body.set_blend_shape_value(index, 0.0)
			print("NAOMI_IMPORT ", version, " shapes=", body.mesh.get_blend_shape_count(), " missing=", missing)
			failures += missing.size()
		var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			failures += 1
		else:
			var player: AnimationPlayer = players[0] as AnimationPlayer
			print("NAOMI_CLIPS ", version, " ", player.get_animation_list())
		model.free()
	print("NAOMI_VALIDATION_FAILURES=", failures)
	quit(1 if failures > 0 else 0)
