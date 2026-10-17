extends Node
## EventBus: global domain-event hub (Autoload "EventBus").
##
## Managers and scenes never hold references to each other's internals. They
## emit and subscribe here. Signals describe facts in the past tense; requests
## end in `_requested`. Payloads are plain types or Dictionaries so they
## serialize cleanly into saves and test logs.
##
## @warning_ignore("unused_signal") is needed because the signals are emitted
## from other scripts.

# --- Content -----------------------------------------------------------------

## All data files loaded. `report` = {errors, warnings, files}.
@warning_ignore("unused_signal")
signal content_loaded(report: Dictionary)

# --- Time --------------------------------------------------------------------

@warning_ignore("unused_signal")
signal time_advanced(total_minutes: int, delta_minutes: int, reason: String)
@warning_ignore("unused_signal")
signal shift_changed(day: int, shift: String)
@warning_ignore("unused_signal")
signal scheduled_event_fired(event_id: String, payload: Dictionary)

# --- Patients and clinical ------------------------------------------------------

## A clinical action passed dedupe and was evaluated. Story systems subscribe
## to this explicitly; ClinicalRules never unlocks narrative content itself.
@warning_ignore("unused_signal")
signal clinical_action_committed(patient_id: String, action_id: String, event_id: String)
@warning_ignore("unused_signal")
signal patient_record_opened(patient_id: String, event_id: String)
@warning_ignore("unused_signal")
signal patient_state_changed(patient_id: String, field_path: String, value: Variant)
@warning_ignore("unused_signal")
signal observation_recorded(patient_id: String, observation_id: String)
@warning_ignore("unused_signal")
signal patient_location_changed(patient_id: String, from_location: String, to_location: String)
## A rule needs clinician attention (pending review, blocked transfer, unknown effect).
@warning_ignore("unused_signal")
signal clinical_review_flagged(rule_id: String, reason: String)

# --- Dialogue ------------------------------------------------------------------

@warning_ignore("unused_signal")
signal dialogue_started(patient_id: String)
## speaker: "physician" | "patient" | "system".
@warning_ignore("unused_signal")
signal dialogue_line_added(patient_id: String, speaker: String, text: String)
@warning_ignore("unused_signal")
signal dialogue_ended(patient_id: String)
@warning_ignore("unused_signal")
signal rapport_changed(patient_id: String, value: float)

# --- Evidence --------------------------------------------------------------------

@warning_ignore("unused_signal")
signal clue_acquired(clue_id: String)
@warning_ignore("unused_signal")
signal clue_pinned(clue_id: String, pinned: bool)
@warning_ignore("unused_signal")
signal clues_linked(clue_a: String, clue_b: String, linked: bool)
@warning_ignore("unused_signal")
signal hypothesis_updated(hypothesis_id: String, status: String)

# --- Staff trust and access --------------------------------------------------------

## axis: "respect" | "trust" | "suspicion".
@warning_ignore("unused_signal")
signal trust_changed(staff_id: String, axis: String, value: float)
@warning_ignore("unused_signal")
signal access_granted(access_id: String, source_id: String)

# --- Interaction and UI ----------------------------------------------------------------

## The interactable under the crosshair changed. Empty prompt = nothing focused.
@warning_ignore("unused_signal")
signal interaction_focus_changed(prompt: String)
@warning_ignore("unused_signal")
signal interacted(interactable_id: String)
## Ask Main to open a panel. panel_id: "info". data: {title, body}.
@warning_ignore("unused_signal")
signal ui_panel_requested(panel_id: String, data: Dictionary)
@warning_ignore("unused_signal")
signal ui_panel_closed(panel_id: String)
## Short on-screen toast.
@warning_ignore("unused_signal")
signal notification_requested(text: String)

# --- Save and settings -------------------------------------------------------------------

@warning_ignore("unused_signal")
signal game_saved(slot: int)
@warning_ignore("unused_signal")
signal game_loaded(slot: int)
@warning_ignore("unused_signal")
signal save_failed(slot: int, reason: String)
@warning_ignore("unused_signal")
signal settings_changed(key: String, value: Variant)
