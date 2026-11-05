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
## A shift began / ended. TimeManager emits these around every shift change
## (ended for the old shift, then started for the new one). Used by
## AudioDirector (day/night ambience) and PharmacologyEngine (12 h steps).
@warning_ignore("unused_signal")
signal shift_started(day: int, shift: String)
@warning_ignore("unused_signal")
signal shift_ended(day: int, shift: String)
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
## A structured note was saved to the patient's chart (append-only).
@warning_ignore("unused_signal")
signal patient_note_saved(patient_id: String, note_id: String)
@warning_ignore("unused_signal")
signal patient_location_changed(patient_id: String, from_location: String, to_location: String)
## A rule needs clinician attention (pending review, blocked transfer, unknown effect).
@warning_ignore("unused_signal")
signal clinical_review_flagged(rule_id: String, reason: String)

# --- Pharmacology (approved model, systems/pharmacology) ----------------------------

## A patient was admitted into the pharmacology simulation.
@warning_ignore("unused_signal")
signal patient_admitted(patient_id: String)
## A medication order was signed: {drug_id, daily_dose_mg}. Dose 0 stops the drug.
@warning_ignore("unused_signal")
signal medication_ordered(patient_id: String, order: Dictionary)
## A medication was stopped; it washes out over its half-life.
@warning_ignore("unused_signal")
signal medication_discontinued(patient_id: String, drug_id: String)
## PharmacologyEngine recalculated a patient's clinical state (see get_state()).
@warning_ignore("unused_signal")
signal patient_state_updated(patient_id: String, state: Dictionary)
## A safety threshold was crossed. `severity` is "warning" | "critical".
@warning_ignore("unused_signal")
signal clinical_alert_raised(patient_id: String, alert_id: String, severity: String)
## A lab panel (e.g. TDM level) is available.
@warning_ignore("unused_signal")
signal lab_results_ready(patient_id: String, panel_id: String, results: Dictionary)

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

# --- Legacy progress and Psychosomatic Bleed (GameState) ------------------------------

## The interaction layer changed (GameState.Mode values).
@warning_ignore("unused_signal")
signal game_mode_changed(previous_mode: int, new_mode: int)
## A physical item (key, badge, log) was collected through GameState.
@warning_ignore("unused_signal")
signal item_collected(item_id: String)
## A GameState narrative unlock fired (not an EvidenceManager clue).
@warning_ignore("unused_signal")
signal clue_unlocked(clue_id: String)
@warning_ignore("unused_signal")
signal evidence_pinned(clue_id: String)
## The physician's diagnostic objectivity changed (0 = lost .. 100 = clear).
@warning_ignore("unused_signal")
signal objectivity_changed(old_value: float, new_value: float)
## Objectivity crossed into a new bleed stage (0 = none .. 3 = severe).
@warning_ignore("unused_signal")
signal bleed_stage_changed(stage: int)

# --- Narrative and audio ----------------------------------------------------------------

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
## Reports whether a dialogue line ended naturally or was interrupted.
@warning_ignore("unused_signal")
signal dialogue_line_finished(line_id: String, completed: bool)

## A graphic-novel cutscene (CutsceneDirector) began. Cutscenes never change
## story, clinical or save state; these signals are for UI, audio and tests.
@warning_ignore("unused_signal")
signal cutscene_started(cutscene_id: String)
## reason: "completed" | "skipped" | "invalid" | "not_approved" | "interrupted" | "timeout".
@warning_ignore("unused_signal")
signal cutscene_finished(cutscene_id: String, reason: String)

# --- Staff trust and access --------------------------------------------------------

## axis: "respect" | "trust" | "suspicion".
@warning_ignore("unused_signal")
signal trust_changed(staff_id: String, axis: String, value: float)
@warning_ignore("unused_signal")
signal access_granted(access_id: String, source_id: String)
## A temporary pass ended; doors it opened close behind it.
@warning_ignore("unused_signal")
signal access_revoked(access_id: String)

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

# --- Story (ChapterDirector) ----------------------------------------------------------

## The current chapter objective changed ("" when every objective is done).
@warning_ignore("unused_signal")
signal objective_changed(objective_id: String, text: String)
## A one-shot story beat ran its actions.
@warning_ignore("unused_signal")
signal story_beat_fired(beat_id: String)
## The player used the shift handover board.
@warning_ignore("unused_signal")
signal shift_signout_requested()
@warning_ignore("unused_signal")
signal chapter_completed(chapter_id: String)
## Main's presentation state changed: TITLE, PROLOGUE, GAMEPLAY, MILESTONE,
## CHAPTER_RECAP or CHAPTER_COMPLETE (see Main.get_presentation_state()).
@warning_ignore("unused_signal")
signal presentation_state_changed(state: String)
## ChapterDirector moved to a chapter (a new run, a loaded save or a
## start_chapter story action). Earlier chapters keep their state.
@warning_ignore("unused_signal")
signal chapter_started(chapter_id: String)

# --- Environment ----------------------------------------------------------------------

## A toggleable environment state changed (e.g. a shutter closed, a seal removed,
## a Ward Zero anomaly variant shown). Geometry for every state always exists;
## only visibility changes, so it is reversible and save-safe.
@warning_ignore("unused_signal")
signal environment_state_changed(group: String, state: String)
## The player is now in another zone (data/zones.json): walked through a
## seamless connection, arrived by a fade transition, or a save was loaded.
@warning_ignore("unused_signal")
signal zone_changed(zone_id: String, previous_zone_id: String)

# --- Anomaly (AnomalyLedger, flag forensic_ward/narrative/anomaly_enabled) ---------------

## An anomaly episode (data/anomalies.json) was observed for the first time.
## Anomaly events never change clinical state, and clinical events never
## cause, reveal or count toward them.
@warning_ignore("unused_signal")
signal anomaly_episode_observed(episode_id: String)
## The evidence ladder moved (ContentSchemas.ANOMALY_LEVELS), capped by chapter.
@warning_ignore("unused_signal")
signal anomaly_threshold_changed(level: String, previous_level: String)

# --- Save and settings -------------------------------------------------------------------

@warning_ignore("unused_signal")
signal game_saved(slot: int)
@warning_ignore("unused_signal")
signal game_loaded(slot: int)
@warning_ignore("unused_signal")
signal save_failed(slot: int, reason: String)
@warning_ignore("unused_signal")
signal settings_changed(key: String, value: Variant)

## A displayed authored story option was selected (not a clinical action).
@warning_ignore("unused_signal")
signal story_option_selected(interaction_id: String, option_id: String)

@warning_ignore("unused_signal")
signal protagonist_profile_changed
@warning_ignore("unused_signal")
signal story_choice_committed(chapter_id: String, interaction_id: String, option_id: String)
