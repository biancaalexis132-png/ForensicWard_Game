class_name AcceptancePerformance
extends Node
## Opt-in acceptance diagnostics. Measures CPU frame intervals, not GPU time.
## Bounded 600-frame rolling window; no campaign/save writes.
const PATH: String = "user://acceptance_perf.csv"
const WINDOW: int = 600
var _frames: Array[float] = []
var _previous_usec: int = 0
var _last_report_usec: int = 0
var _file: FileAccess

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_file = FileAccess.open(PATH, FileAccess.WRITE)
	if _file == null:
		set_process(false)
		return
	_file.store_line("unix_time,zone,paused,window_frames,p95_cpu_frame_interval_ms,max_cpu_frame_interval_ms,static_memory_bytes")
	_previous_usec = Time.get_ticks_usec()
	_last_report_usec = _previous_usec
	print("Acceptance performance CSV: ", ProjectSettings.globalize_path(PATH))

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	_frames.append(float(now - _previous_usec) / 1000.0)
	_previous_usec = now
	if _frames.size() > WINDOW:
		_frames.pop_front()
	if now - _last_report_usec < 1000000:
		return
	_last_report_usec = now
	var sorted: Array[float] = _frames.duplicate()
	sorted.sort()
	var director: ZoneDirector = get_tree().get_first_node_in_group(ZoneDirector.GROUP) as ZoneDirector
	_file.store_line("%s,%s,%s,%d,%.3f,%.3f,%d" % [str(Time.get_unix_time_from_system()), director.current_zone_id if director != null else "review", str(get_tree().paused), sorted.size(), sorted[ceili(sorted.size() * 0.95) - 1], sorted[-1], int(Performance.get_monitor(Performance.MEMORY_STATIC))])
	_file.flush()
