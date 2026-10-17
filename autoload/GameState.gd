extends Node
## GameState — persistent run data (Autoload singleton, registered as "GameState").
##
## Owns the facts that must survive scene changes and be saved to disk:
## time (day/shift), the player's objectivity meter, collected items,
## unlocked/pinned clues and story flags.
##
## GameState only *stores* data and announces changes through EventBus.
## Game rules (how fast objectivity drains, what unlocks a clue) live in the
## individual systems, which call the mutator methods below.

## Which interaction layer currently has input focus.
enum Mode {
	EXPLORATION, ## First-person 3D movement.
	TERMINAL,    ## 2D point-and-click UI (EHR, interviews, evidence board).
	PAUSED,
}

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1

const OBJECTIVITY_MAX: float = 100.0
## Objectivity at or below each value enters bleed stage 1, 2, 3.
const BLEED_THRESHOLDS: Array[float] = [70.0, 45.0, 20.0]

# --- Time ------------------------------------------------------------------
var day: int = 1
var shift: String = "day"

# --- Player ----------------------------------------------------------------
var mode: Mode = Mode.EXPLORATION
var objectivity: float = OBJECTIVITY_MAX
var bleed_stage: int = 0

# --- Progress --------------------------------------------------------------
var collected_items: Array[String] = []
var unlocked_clues: Array[String] = []
var pinned_clues: Array[String] = []
## Free-form story switches set by narrative events, e.g. {"met_dr_hale": true}.
var flags: Dictionary = {}


# ===========================================================================
# Mode
# ===========================================================================

func set_mode(new_mode: Mode) -> void:
	if new_mode == mode:
		return
	var previous: Mode = mode
	mode = new_mode
	# Exploration needs a captured mouse for mouselook; terminals need a cursor.
	if mode == Mode.EXPLORATION:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	EventBus.game_mode_changed.emit(previous, mode)


# ===========================================================================
# Time
# ===========================================================================

func start_shift(new_day: int, new_shift: String) -> void:
	day = new_day
	shift = new_shift
	EventBus.shift_started.emit(day, shift)


## Ends the current shift and starts the next one (day -> night -> next day).
func advance_shift() -> void:
	EventBus.shift_ended.emit(day, shift)
	if shift == "day":
		start_shift(day, "night")
	else:
		start_shift(day + 1, "day")


# ===========================================================================
# Objectivity / Psychosomatic Bleed
# ===========================================================================

## Adds `delta` (negative to drain) and clamps to 0..OBJECTIVITY_MAX.
func change_objectivity(delta: float) -> void:
	set_objectivity(objectivity + delta)


func set_objectivity(value: float) -> void:
	var clamped: float = clampf(value, 0.0, OBJECTIVITY_MAX)
	if is_equal_approx(clamped, objectivity):
		return
	var old_value: float = objectivity
	objectivity = clamped
	EventBus.objectivity_changed.emit(old_value, objectivity)
	_update_bleed_stage()


func _update_bleed_stage() -> void:
	var stage: int = 0
	for threshold: float in BLEED_THRESHOLDS:
		if objectivity <= threshold:
			stage += 1
	if stage != bleed_stage:
		bleed_stage = stage
		EventBus.bleed_stage_changed.emit(bleed_stage)


# ===========================================================================
# Items & clues
# ===========================================================================

func has_item(item_id: String) -> bool:
	return item_id in collected_items


func collect_item(item_id: String) -> void:
	if has_item(item_id):
		return
	collected_items.append(item_id)
	EventBus.item_collected.emit(item_id)


func is_clue_unlocked(clue_id: String) -> bool:
	return clue_id in unlocked_clues


func unlock_clue(clue_id: String) -> void:
	if is_clue_unlocked(clue_id):
		return
	unlocked_clues.append(clue_id)
	EventBus.clue_unlocked.emit(clue_id)


## Only unlocked clues can be pinned. Returns true if the clue was pinned.
func pin_clue(clue_id: String) -> bool:
	if not is_clue_unlocked(clue_id) or clue_id in pinned_clues:
		return false
	pinned_clues.append(clue_id)
	EventBus.evidence_pinned.emit(clue_id)
	return true


func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value


func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)


# ===========================================================================
# Save / load
# ===========================================================================

func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"day": day,
		"shift": shift,
		"objectivity": objectivity,
		"collected_items": collected_items,
		"unlocked_clues": unlocked_clues,
		"pinned_clues": pinned_clues,
		"flags": flags,
	}


func from_dict(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	shift = str(data.get("shift", "day"))
	collected_items.assign(data.get("collected_items", []))
	unlocked_clues.assign(data.get("unlocked_clues", []))
	pinned_clues.assign(data.get("pinned_clues", []))
	flags = data.get("flags", {})
	# Route through the setter so the Bleed UI refreshes after loading.
	objectivity = OBJECTIVITY_MAX
	bleed_stage = 0
	set_objectivity(float(data.get("objectivity", OBJECTIVITY_MAX)))


func save_game() -> Error:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: cannot write save: %s" % error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return OK


func load_game() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return ERR_FILE_NOT_FOUND
	var text: String = FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameState: save file is corrupt: %s" % SAVE_PATH)
		return ERR_PARSE_ERROR
	from_dict(parsed)
	return OK


## Resets everything to a fresh run (used by "New Game").
func reset() -> void:
	from_dict({})
	mode = Mode.EXPLORATION
