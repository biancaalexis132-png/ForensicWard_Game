extends SceneTree
## Review-only: frame time at the nursing station with Naomi's placeholder capsule or
## a preview model, from the counter and from close up. Prints one PERF line per view.
##
## Usage (from the project root, after importing; needs a window, not --headless):
##   godot --path . -s res://tools/godot/measure_character_frame_time.gd --resolution 1280x720 -- --version=v04
## Omit --version for the capsule baseline. Every frame is drawn with force_draw, so the
## numbers hold even when macOS throttles a window that is not on screen.

const WARMUP: int = 30
const SAMPLES: int = 300
const VIEWS: Array = [["counter", 3.2, 1.6], ["close", 1.25, 1.5]]

var _version: String = ""
var _world: Node
var _viewport: RID


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--version="):
			_version = arg.trim_prefix("--version=")
	CharacterVisualPreview.set_requests({} if _version.is_empty() else {"staff_bennett": _version})
	_world = (load("res://scenes/world/HospitalGreybox.tscn") as PackedScene).instantiate()
	get_root().add_child(_world)
	_viewport = get_root().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_viewport, true)
	_run.call_deferred()


func _run() -> void:
	for i: int in 10:
		await process_frame
	var bennett: Node3D = _world.find_child("NurseBennett", true, false)
	var root: Node3D = bennett.get_node("VisualRoot")
	var model: Node3D = root.get_child(root.get_child_count() - 1) if root.get_child_count() > 0 else bennett
	if not _version.is_empty() and model == bennett:
		push_error("measure_character_frame_time: preview %s did not load" % _version)
		quit(1)
		return
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		if player.name != "GestureAnimationPlayer" and player.has_animation("idle_breathing"):
			player.play("idle_breathing")
	var front: Vector3 = model.global_basis.z.normalized()
	var camera: Camera3D = Camera3D.new()
	_world.add_child(camera)
	camera.current = true
	var label: String = _version if not _version.is_empty() else "capsule"
	for view: Array in VIEWS:
		camera.global_position = model.global_position + front * float(view[1]) + Vector3(0.0, float(view[2]), 0.0)
		camera.look_at(model.global_position + Vector3(0.0, 1.2, 0.0))
		var gpu: PackedFloat64Array = []
		var cpu: PackedFloat64Array = []
		var wall: PackedFloat64Array = []
		for i: int in WARMUP + SAMPLES:
			var start: int = Time.get_ticks_usec()
			RenderingServer.force_draw(true, 1.0 / 60.0)
			if i >= WARMUP:
				wall.append((Time.get_ticks_usec() - start) / 1000.0)
				gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(_viewport))
				cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(_viewport) + RenderingServer.get_frame_setup_time_cpu())
			await process_frame
		print("PERF %s %s gpu_mean=%.2fms gpu_p95=%.2fms cpu_mean=%.2fms frame_mean=%.2fms frame_p95=%.2fms primitives=%d draw_calls=%d" % [
			label, view[0], _mean(gpu), _p95(gpu), _mean(cpu), _mean(wall), _p95(wall),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	print("PERF %s video_memory_mb=%.0f" % [label, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0])
	quit(0)


func _mean(values: PackedFloat64Array) -> float:
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / maxf(values.size(), 1)


func _p95(values: PackedFloat64Array) -> float:
	var sorted: PackedFloat64Array = values.duplicate()
	sorted.sort()
	return sorted[int(sorted.size() * 0.95)]
