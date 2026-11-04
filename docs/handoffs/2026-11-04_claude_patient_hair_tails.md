# Handoff: ponytail strand cards and softer hairlines (Claude Code, 2026-11-04)

- Branch: `claude/patient-hair-tails`, stacked on `claude/ward-round-patient-voices` (#121). Draft PR; do not merge until the stack is reviewed.
- Builder (`tools/blender/characters/build_cast_member.py`), all opt-in per config:
  - `hair.tail_cards` {count, width_m, tip_spread, core_scale, seed}: strand cards wrapped round the ponytail centreline over a slimmer core (`core_scale`), ends spreading and finishing at different lengths. Weighted head → chest like the tail.
  - `hair.hairline_cards` {length_m, width_m, outside_share, v_scale, every, seed}: wisps rooted on the cap just inside its rim, running out over the skin, so the hairline is not a hard edge.
  - Shared card material per character (`card_material`), strip helper `_card_strip` (now with `v_scale`), `_card_object`.
- Configs: the 22 patients with hair cards gain `hairline_cards` and `hairline_taper_m` 0.035; the 14 ponytails gain `tail_cards` (64 cards for tails ≥ 0.14 m, else 48). Close crops (Achebe, Adeyemi, Brooks, Doyle, Osei, Whitaker) unchanged.
- Rebuilt 22 patients through stages 1–5; largest about 31.2k triangles. Imported in Godot; Chapter 1 bedside capture checked.
- Full QA passed: game 408/0, audio 1720/0, QA 19/0/0, GLB 199/0, Chapter 1 sequence done, exit 0.
- Known limits: hairline wisps read a little frayed on short dark crops (Ortiz); fringes are still part of the cap; nothing tested on the Mac.
- Review images: `/mnt/project-files/ward_round/patient_hair_tails_before_after.png`, `hair_tails_in_game_natarajan.png`.
