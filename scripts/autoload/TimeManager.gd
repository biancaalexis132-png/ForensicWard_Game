extends Node
## TimeManager: in-game clock, shifts and scheduled events (Autoload "TimeManager").
##
## Time is an integer count of minutes since Day 1 00:00. It advances in two ways:
##   1. advance(minutes, reason): deterministic, used by actions
##      ("interview takes 15 minutes"). Tests use only this.
##   2. Real-time flow during exploration: `exploration_minutes_per_second`
##      game minutes per real second, whenever no pause reason is active.
## Pause policy: any system can push a named pause reason (menu, ui,
## cutscene). The clock flows only while the pause set is empty.
##
## Scheduled events fire in (time, insertion order) order, so the same
## inputs always give the same sequence.

const MINUTES_PER_DAY: int = 24 * 60
const DAY_SHIFT_START: int = 7 * 60   ## 07:00
const NIGHT_SHIFT_START: int = 19 * 60 ## 19:00
const START_MINUTES: int = 8 * 60     ## Day 1, 08:00

## Game minutes per real second while exploring. 0 disables real-time flow.
var exploration_minutes_per_second: float = 0.25

var total_minutes: int = START_MINUTES

var _pause_reasons: Dictionary[String, bool] = {}
var _realtime_accumulator: float = 0.0
## Each entry: {at, seq, event_id, payload}
var _queue: Array[Dictionary] = []
var _sequence: int = 0


func _ready() -> void:
	SaveManager.register_provider("time", self)


func _process(delta: float) -> void:
	if not _pause_reasons.is_empty() or exploration_minutes_per_second <= 0.0:
		return
	_realtime_accumulator += delta * exploration_minutes_per_second
	if _realtime_accumulator >= 1.0:
		var whole: int = floori(_realtime_accumulator)
		_realtime_accumulator -= whole
		advance(whole, "exploration")


# --- Queries -----------------------------------------------------------------------

func get_day() -> int:
	return total_minutes / MINUTES_PER_DAY + 1


func get_minute_of_day() -> int:
	return total_minutes % MINUTES_PER_DAY


## "day" from 07:00 to 19:00, otherwise "night".
func get_shift() -> String:
	return shift_for(total_minutes)


## The day a shift belongs to: a night shift that runs past midnight still
## belongs to the day it started (Day 1 night ends at Day 2 07:00).
func get_shift_day() -> int:
	return shift_day_for(total_minutes)


func shift_day_for(minutes: int) -> int:
	var day: int = minutes / MINUTES_PER_DAY + 1
	return day - 1 if minutes % MINUTES_PER_DAY < DAY_SHIFT_START else day


func shift_for(minutes: int) -> String:
	var minute_of_day: int = minutes % MINUTES_PER_DAY
	return "day" if minute_of_day >= DAY_SHIFT_START and minute_of_day < NIGHT_SHIFT_START else "night"


func get_clock_string() -> String:
	return format_minutes(total_minutes)


## "Day 2  14:05" for an absolute minute count (EHR timestamps, audit).
func format_minutes(minutes: int) -> String:
	var minute_of_day: int = minutes % MINUTES_PER_DAY
	return "Day %d  %02d:%02d" % [minutes / MINUTES_PER_DAY + 1, minute_of_day / 60, minute_of_day % 60]


func is_paused() -> bool:
	return not _pause_reasons.is_empty()


# --- Control -------------------------------------------------------------------------

func push_pause(reason: String) -> void:
	_pause_reasons[reason] = true


func pop_pause(reason: String) -> void:
	_pause_reasons.erase(reason)


## Advances the clock, firing due scheduled events in order.
func advance(minutes: int, reason: String) -> void:
	if minutes <= 0:
		return
	var target: int = total_minutes + minutes
	while not _queue.is_empty() and _queue[0]["at"] <= target:
		var entry: Dictionary = _queue.pop_front()
		_move_to(entry["at"], reason)
		EventBus.scheduled_event_fired.emit(entry["event_id"], entry["payload"])
	_move_to(target, reason)


## Schedules an event at an absolute minute. Returns false if the id is
## already queued (dedupe) or the time is in the past.
func schedule(at_minutes: int, event_id: String, payload: Dictionary = {}) -> bool:
	if at_minutes < total_minutes:
		return false
	for entry: Dictionary in _queue:
		if entry["event_id"] == event_id:
			return false
	_sequence += 1
	_queue.append({"at": at_minutes, "seq": _sequence, "event_id": event_id, "payload": payload})
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["at"] < b["at"] or (a["at"] == b["at"] and a["seq"] < b["seq"]))
	return true


func get_scheduled_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in _queue:
		ids.append(entry["event_id"])
	return ids


## Moves to the start of the next shift (07:00 or 19:00), firing anything scheduled before it.
func advance_to_next_shift() -> void:
	var minute_of_day: int = get_minute_of_day()
	var target: int
	if minute_of_day < DAY_SHIFT_START:
		target = total_minutes - minute_of_day + DAY_SHIFT_START
	elif minute_of_day < NIGHT_SHIFT_START:
		target = total_minutes - minute_of_day + NIGHT_SHIFT_START
	else:
		target = total_minutes - minute_of_day + MINUTES_PER_DAY + DAY_SHIFT_START
	advance(target - total_minutes, "shift_change")


## Sets the clock to the start of a shift (story set-up, tests, legacy
## GameState.start_shift). May move backwards; queued events are kept.
## Always announces shift_started, as the original GameState did.
func jump_to_shift(day: int, shift: String) -> void:
	var previous_day: int = get_shift_day()
	var previous_shift: String = get_shift()
	total_minutes = (maxi(day, 1) - 1) * MINUTES_PER_DAY + (NIGHT_SHIFT_START if shift == "night" else DAY_SHIFT_START)
	_realtime_accumulator = 0.0
	if previous_day != get_shift_day() or previous_shift != get_shift():
		EventBus.shift_changed.emit(get_shift_day(), get_shift())
	EventBus.shift_started.emit(get_shift_day(), get_shift())


func _move_to(minutes: int, reason: String) -> void:
	if minutes <= total_minutes:
		return
	var previous: int = total_minutes
	var previous_shift: String = get_shift()
	var previous_day: int = get_shift_day()
	total_minutes = minutes
	EventBus.time_advanced.emit(total_minutes, total_minutes - previous, reason)
	if get_shift() != previous_shift or get_shift_day() != previous_day:
		EventBus.shift_ended.emit(previous_day, previous_shift)
		EventBus.shift_started.emit(get_shift_day(), get_shift())
		EventBus.shift_changed.emit(get_shift_day(), get_shift())


# --- Save provider -------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {"total_minutes": total_minutes, "queue": _queue.duplicate(true), "sequence": _sequence}


func load_save_data(data: Dictionary) -> void:
	total_minutes = int(data.get("total_minutes", START_MINUTES))
	_sequence = int(data.get("sequence", 0))
	_queue.clear()
	for entry: Variant in data.get("queue", []):
		var item: Dictionary = entry
		_queue.append({"at": int(item["at"]), "seq": int(item["seq"]),
				"event_id": str(item["event_id"]), "payload": item.get("payload", {})})
	_realtime_accumulator = 0.0


func reset_state() -> void:
	total_minutes = START_MINUTES
	_queue.clear()
	_sequence = 0
	_realtime_accumulator = 0.0
