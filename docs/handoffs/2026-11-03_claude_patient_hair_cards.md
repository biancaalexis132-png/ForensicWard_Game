# Hair cards for the ward-round patients (Claude Code, 2026-11-03)

Branch `claude/patient-hair-cards`, stacked on `claude/patient-model-ageing` (#118). Draft PR, not merged.

## What changed

- `tools/blender/characters/build_cast_member.py`: opt-in `hair.cards` (`count`, `length_m`, `width_m`, `lift_m`, `lift_spread`, `segments`, `seed`, `crown_back_m`). Alpha-clipped strand strips are laid over the scalp cap, flowing toward the tie for tied hair, or out from the crown and slightly down for short hair. Strand tips thin out, so the cap's hard outline breaks up. The material uses a Round node on alpha, so the glTF exports as alphaMode MASK and Godot uses alpha scissor. It is double-sided and adds about 3,000 triangles per patient.
- 23 patients rebuilt (stages 1 to 5): all 14 ponytails and the longer non-afro-textured crops (Delaney, Hughes, Kim, Kowalczyk, Novak, Ortiz, Reyes, Sato, Wróbel). Close crops (Achebe, Adeyemi, Brooks, Doyle, Osei, Whitaker) keep the textured cap, which reads right for very short hair. Doyle was rebuilt without cards after a trial. Crops with cards also get a slight temple shape (`temple_recede_m` 0.007) to soften the straight bowl line.
- Captures: `assets/renders/characters/ward_patient_hair_v1/` (before/after sheet; two in-game close-ups on the Compatibility renderer).

## Limits

- Fringes are still a fairly blunt line from the front.
- The ponytail tail itself is still a tube with a strand texture.
- Straight strands are used for every tied style, including patients whose hair would often be braided or textured; that is a draft choice for Bi.

## Tests

Full headless QA: game 401/0, audio 1720/0, QA 19/0/0, GLB 199/0, CH1_SEQUENCE_DONE, exit 0. Not looked at on the Mac.
