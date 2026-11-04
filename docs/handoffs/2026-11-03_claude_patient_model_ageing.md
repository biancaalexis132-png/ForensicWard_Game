# Older, greying and heavier ward-round patients (Claude Code, 2026-11-03)

Branch `claude/patient-model-ageing`, stacked on `claude/ward-round-scoring` (#117). Draft PR, not merged.

## What changed

`tools/blender/characters/build_cast_member.py` gains three opt-in options (staff and other cast configs are unchanged unless they opt in; only the hair texture change applies to any future rebuild):

- `skin.age_marks.strength` (0 to 1): painted forehead lines, nasolabial and marionette folds, crow's feet, under-eye hollows, age spots on the face and hands, and slightly duller skin. Colour only, no new geometry. Patients aged 50+ use `(age - 40) / 40`, capped at 1.
- `hair.temple_recede_m` (with optional `recede_deg`): an M-shaped receding hairline. Used for Delaney, Kim, Brooks, Doyle and Whitaker.
- `macro.weight_any_age`: the young max-weight key also applies to older bodies (the base has no old weight key), so older patients can be heavier. Used with a higher `max_weight` for Delaney, Mensah, Quinn, Okafor, Doyle, Brennan, Kowalczyk and Wróbel.
- Hair texture: one-texel strands over a colour already blended toward grey by `grey_fraction`, softer clumping and darker roots, so greying hair reads silver rather than striped.

Rebuilt with the full pipeline (stages 1 to 5): Doyle, Whitaker, Brennan, Delaney, Kim, Mensah, Quinn, Okafor, Brooks, Lindqvist, Lebel, Haddad, Kowalczyk, Wróbel, Osei. Before/after faces: `assets/renders/characters/ward_patient_ageing_v1/before_after.png`.

## Limits

- Ageing is painted, so it shows less on darker skin (Mensah, Okafor) and under flat light.
- Every hairstyle is still a scalp cap; the women's ponytails still read as a short cap from the front. Real hair cards would be the next step.
- Body shape is still one base per sex; weight is the only build control used.

## Tests

Full headless QA after the rebuild: game 401/0, audio 1720/0, QA 19/0/0, GLB 199/0, CH1_SEQUENCE_DONE, exit 0. Not looked at on the Mac.
