# Pending handoff entry: Naomi v04 Mac validation

The four AI handoff docs belong to the cloud thread's `claude/naomi-animation-v04`. Copy this entry to the top of the `docs/AI_HANDOFF.md` log when integrating.

### 2026-10-18 16:50 UTC · Claude Code (owner's Mac, Remote Control) · Naomi v04 Mac validation

- **Branch:** `claude/naomi-v04-mac-review` (based on `claude/naomi-animation-v04` at `afdc3d0`)
- **Latest verified commit:** the commit that adds this file
- **Pull request:** draft, against `claude/naomi-animation-v04`
- **State:** finished; v04 stays **not approved**

**Accomplished**
- Rebuilt v04 on the Mac (Blender 5.2.2) with `build_animated_character.py` and `profiles/staff_bennett.json`, writing to a scratch folder. The GLB matches the committed v04 in structure: 9 meshes, 1 skin of 53 joints, the same 10 clips with the same channel counts, and the same 10 morph targets. Bytes differ (float output differs between platforms). Build plus Cycles review frames took 53 s.
- `tools/godot/capture_character_performance.gd`: scripted review take at the nursing station. Covers breathing idle, blink, greeting nod, warm speech, concerned listening, acknowledgement nod, serious speech and the chart gesture. It draws each frame with `force_draw`, and two runs produce identical frames.
- Review take: `docs/design/characters/Naomi_Bennett_Character_Production_v1/ingame_review_v04_mac/` (19.5 s MP4 and five stills, `.gdignore`).

**Files modified**
- `tools/godot/capture_character_performance.gd`: new, review-only, not run by QA
- `docs/design/characters/Naomi_Bennett_Character_Production_v1/ingame_review_v04_mac/`: new captures
- `docs/handoffs/2026-10-18_naomi_v04_mac_validation.md`: this entry

**Known errors**
- The builder raises `ValueError` from `profile_path.relative_to(ROOT)` (line 865) when `--profile` is outside the repository. It does so after it has saved the GLB and `.blend` but before the report and manifest. In-repo profiles are unaffected. Fix: fall back to the absolute path.
- On a Mac driven remotely, `--write-movie` repeats frames because macOS throttles the off-screen window (248 to 465 of 587 frames were new). Use the capture tool above.
- Speech mouth movement is subtle at counter distance (`MOUTH_MAX` 0.85 on a small `mouth_open` shape). The owner should judge it from the take.

**Tests** (Mac, Godot 4.7.2, branch `afdc3d0`)
- `tests/qa/run.py` with only the music step removed: exit 0. QA 19/0/0, GLB 157/0, TestRunner 155/0, pharmacology 0 failures, boot OK, audio 336/0, Ch1 sequence done.
- The full runner fails only in the music step on this branch, because the libvorbis fallback is in PR #52, which is not on it. With #52 applied, the music tests pass 3/3 on this Mac.

**Dependencies not available to remote agents**
- MPFB2 asset packs, now installed on the Mac only: system assets, eyebrows01, eyelashes01, visemes01, faceunits01.

**Next steps**
1. Owner reviews `naomi_v04_mac_performance.mp4`.
2. v05 (local thread): bake MPFB faceunits and visemes as shape keys on the v02 base before vertex deletion, then rerun the v03 steps and the v04 builder. Map them to the stable morph names.
