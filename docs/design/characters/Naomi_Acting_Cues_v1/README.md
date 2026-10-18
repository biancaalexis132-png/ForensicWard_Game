# Naomi Bennett — Chapter 1 machine-readable acting cues (proposal v1)

This add-on data file corresponds to the *existing*, provisional Chapter 1 nursing-station dialogue (scene `ch1_b2_bennett_handover`) and its stable IDs. It does not change text, recordings, medical data, scene graph, save schema, or clinical decisions. Clinical dialogue remains `PENDING` approval.

## Files
- `naomi_acting_cues.json`: deterministic emotional/body/gaze/gesture states for the three Bennett lines and two player lines.
- `validate_naomi_cues.py`: standalone stdlib validator using the real repo's narrative and audio mappings.
- `COPILOT_HANDOFF.md`: implementation brief.

## Validate
`python3 docs/design/characters/Naomi_Acting_Cues_v1/validate_naomi_cues.py .`

## Integration contract (proposed)
- Create a *presentation-only* adapter that maps the semantic cue names to whatever `AnimationTree`, skeleton, blend shapes and gaze controllers actually exist. Do not require these assets before the 3D builder lands.
- For the current placeholder, use safe idle and optional simple head orientation. Do not animate body motion that doesn't exist.
- Drive stage changes off **existing dialogue lifecycle events**; never advance or re-fire story events from animation.
- Map `during_speech` to audio start/end boundaries; viseme/lip-sync timing needs real audio analysis or reliable phoneme alignment and must not be invented from approximate timestamps.
- Skip/interrupt/save/load must not duplicate audio, hints, badges, clinical observations or story-state changes.
- Respect accessibility settings for head/camera motions. On audio failure, captions/dialogue and progression remain functional.
- `workstation_then_player` is a *semantic* gaze directive, not a forced eye movement without geometry checks.
- All motion and aesthetic choices remain subject to visual/gameplay approval.

## Recommended test cases
All mapped IDs valid; fallback on absent animation and voice; no clinical-state mutations; skip and interruption idempotent; re-enter scene after load without repeating grants; missing audio still progresses; animation events never create save-state differences.
