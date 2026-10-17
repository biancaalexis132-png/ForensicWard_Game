extends Node
## EventBus — global signal hub (Autoload singleton, registered as "EventBus").
##
## Systems never call each other directly. They emit and listen here instead,
## so the FPS player, EHR terminal, PharmacologyEngine and Bleed system can be
## built, tested and replaced independently.
##
## Usage:
##     EventBus.patient_selected.emit("PT-0042")
##     EventBus.patient_selected.connect(_on_patient_selected)
##
## Convention: signals are named in the past tense ("something happened"),
## never as commands. Payloads use plain types or Dictionaries so JSON data
## authored by the narrative team can flow through without conversion.
##
## NOTE: @warning_ignore("unused_signal") is required because the signals are
## declared here but emitted from other scripts.

# --- Game flow -------------------------------------------------------------

## A new shift began. `day` is 1-based; `shift` is "day" | "night".
@warning_ignore("unused_signal")
signal shift_started(day: int, shift: String)

## The current shift ended (player clocked out or time ran out).
@warning_ignore("unused_signal")
signal shift_ended(day: int, shift: String)

## The game switched between first-person exploration and a 2D terminal UI.
## `mode` is one of GameState.Mode values.
@warning_ignore("unused_signal")
signal game_mode_changed(previous_mode: int, new_mode: int)

# --- Clinical (EHR / pharmacology) -----------------------------------------

## A patient was admitted and their pharmacology state initialized.
@warning_ignore("unused_signal")
signal patient_admitted(patient_id: String)

## The player opened a patient's chart.
@warning_ignore("unused_signal")
signal patient_selected(patient_id: String)

## A medication order was signed. `order` holds drug_id and daily_dose_mg
## (dose 0 stops the drug; it then washes out over its half-life).
@warning_ignore("unused_signal")
signal medication_ordered(patient_id: String, order: Dictionary)

## A medication was stopped. The drug washes out over its half-life.
@warning_ignore("unused_signal")
signal medication_discontinued(patient_id: String, drug_id: String)

## PharmacologyEngine finished recalculating a patient's clinical state.
## `state` is PharmacologyEngine.get_state(): sedation, eps, akathisia, qtc_ms,
## symptoms, interview_reliability, levels, alerts, ...
@warning_ignore("unused_signal")
signal patient_state_updated(patient_id: String, state: Dictionary)

## A safety threshold was crossed (e.g. QTc > 500 ms, toxicity, NMS risk).
## `severity` is "warning" | "critical".
@warning_ignore("unused_signal")
signal clinical_alert_raised(patient_id: String, alert_id: String, severity: String)

## A lab panel was ordered and its results are now available.
@warning_ignore("unused_signal")
signal lab_results_ready(patient_id: String, panel_id: String, results: Dictionary)

# --- Investigation / exploration -------------------------------------------

## The player picked up an item (keycard, log, document).
@warning_ignore("unused_signal")
signal item_collected(item_id: String)

## A clue became available, either from exploration or from treating a patient.
@warning_ignore("unused_signal")
signal clue_unlocked(clue_id: String)

## A clue was pinned onto the differential diagnosis / evidence board.
@warning_ignore("unused_signal")
signal evidence_pinned(clue_id: String)

# --- Psychosomatic Bleed ---------------------------------------------------

## The player's diagnostic objectivity changed. Range 0.0 (lost) .. 100.0 (clear).
@warning_ignore("unused_signal")
signal objectivity_changed(old_value: float, new_value: float)

## Objectivity crossed into a new bleed stage (0 = none .. 3 = severe).
## UI/shader systems listen to this to switch distortion presets.
@warning_ignore("unused_signal")
signal bleed_stage_changed(stage: int)

# --- Narrative and audio ---------------------------------------------------

## An authored story beat happened (e.g. "ch1_after_hours_intercom").
## AudioDirector maps event IDs to audio in res://audio/cues.json; events
## without audio are ignored. `payload` may carry "position" (Vector3).
@warning_ignore("unused_signal")
signal narrative_event_fired(event_id: String, payload: Dictionary)

## A dialogue line started. Subtitles show `text` for `duration` seconds,
## which matches the voice clip, so no information depends on audio alone.
@warning_ignore("unused_signal")
signal subtitle_shown(line_id: String, speaker_name: String, text: String, duration: float)

## The line ended or was skipped; hide its subtitle.
@warning_ignore("unused_signal")
signal subtitle_cleared(line_id: String)
