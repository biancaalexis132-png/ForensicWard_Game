# Handoff: static graphic-novel chapter recaps (Claude Code, 2026-10-19)

**Last updated:** 2026-10-19 (UTC), Claude Code cloud session.

## Objective

Bi approved the existing **Static Graphic-Novel Cutscenes Final v1** artwork for Chapters 1-5 (project file `ForensicWard_Static_Graphic_Novel_Cutscenes_Final_v1.zip`) and asked to integrate it into the existing CutsceneDirector as static illustrated panels: no regeneration, repainting, restyling or replacement; no new character animation; keep the five-chapter story, the three Chapter 5 endings, existing dialogue, soundtrack and reveal timing; simple transitions, music, captions and restrained camera movement; separate feature branch; current cutscene assets kept as rollback; Chapter 1 first, then 2-5 in order; tests and a playable preview per chapter; nothing merged.

## State

- **Branch:** `claude/static-graphic-novel-cutscenes` from `main` `e518f13` (PR #92 merged). Draft PR to `main`; never merge automatically.
- **Latest verified commit:** bac05fe (see `docs/AI_HANDOFF.md` entry).
- **Commits:** Chapter 1 (`2652f34`), Chapters 2-5 (`464cd03`), recap placement enabled on the branch (bac05fe), then this documentation commit.

## Done

1. `tools/cutscenes/import_static_graphic_novel.py` copies the 36 package panels **byte-identical** into `assets/cutscenes/static_gn_v1/ch0N/` and writes each folder's `manifest.json` (SHA-256 per file, art approval, warnings). Pages and the 7 alternate Chapter 1 illustrations are not committed (they stay in the zip; 26 MB).
2. `data/cutscenes/cs_ch01_static_gn.json` ... `cs_ch05_static_gn.json`: one panel per package panel, in package order (7/7/7/8/7), single layer, no glaze, `inset` frame, fade from black then dissolves, zoom 1.00-1.03 with ≤0.6 % drift, 40.5 s (Ch4 46 s). Music: existing contexts `mus_waiting_room`, `mus_transition_unease`, `mus_narrative`, `mus_procedure`, `mus_compassion` (no reserved reveal cue). No `line_id`. Caption only on Ch1 panel 2 (`institution.name`); every panel 1 has its chapter title painted in.
3. Placement: Bi chose **Chapter close** on the decision card (2026-10-19 12:09 UTC). New trigger `chapter_complete` in `CutsceneRegistry` (campaign + approved only; `chapter_complete_cutscene()`), and `Main._on_chapter_completed` opens the recap on `EventBus.chapter_completed`. The recap (layer 30) covers the end-of-chapter info panel (layer 10), which is still there when the recap ends or is skipped. The five files are `mode` `campaign`, `approved: true`, `trigger.kind` `chapter_complete` **on this branch only**.
4. Tests: `tests/qa/test_cutscenes.py` checks owner art stays byte-identical (SHA-256), all five recaps cover every package panel in order with one layer and no dialogue, and the approved-campaign list. `scripts/tests/test_cutscene.gd`: each recap plays every panel for its length, loads every texture and restores music; the title cards still open Chapters 2-5; completing Chapter 1 opens the recap over the end-of-chapter panel; `chapter_complete` needs owner approval.
5. Previews: Godot Movie Maker recordings of each chapter through the review scene (Compatibility renderer, Xvfb, 30 fps, with music), in the project's shared folder `static_gn_preview/cs_ch0N_static_gn.mp4`. Not Forward+, not the Mac.

## Tests

Container (Linux, Godot 4.7 stable official, headless) on `bac05fe`, same steps as `tests/qa/run.py` with an isolated XDG dir: test_json/test_audio_manifest/test_cutscenes (6/6)/music_ai OK; import exit 0; pharmacology 0 failures; QA 19/0/0; GLB 168/0; **game tests 266 passed, 0 failed**; boot OK (content valid); audio 336/0; CH1_SEQUENCE_DONE. The runner itself timed out at its 150 s import step on a cold cache in this container, so the steps were run by hand without that cap. An earlier mid-work run (while a preview recording ran in parallel) had one failure in `test_character_visual.gd` (zone unload timing); it passed on the final run. Mac not run.

After merging `main` `cca0615` (title screen, PR #93; only `docs/AI_HANDOFF.md` conflicted, both entries kept): game tests 268 passed, 1 failed, boot OK, cutscene contract OK. The one failure, `test_character_visual.gd::test_visual_is_not_saved_and_zone_rebuild_returns_to_fallback` ("unloaded zone forgets the old character"), fails the same way on untouched `main` `cca0615` in this container (265/1, and alone 4/1 three times), so it is environmental here, not this PR; hosted CI on `main` passes it.

## Not changed (rollback)

`cs_ch01_first_shift_pilot`, `cs_ch02..05_title` and every plate under `assets/cutscenes/ch0*` are untouched; the title cards still open Chapters 2-5. To turn the recaps off: set the five `cs_ch0N_static_gn.json` back to `review_only` / `approved: false` / `manual_preview` and drop them from `OWNER_APPROVED_CAMPAIGN` (or revert bac05fe).

## Findings for the owner (art not changed)

- Ch3 painted title reads "Chapter 3 — Ward Zero" (campaign: "Chapter 3: Beneath the Hospital") and opens on the Ward Zero sign; Ch4 panels 5 and 8 show the Scene 09 clock corridor; Ch5 panel 6 shows three folders for the three endings, panel 7 a shared epilogue (no ending-specific art). The chapter-close placement keeps these after their scenes.
- Paperwork, names, dates, record numbers in the art are illustrative only, not clinical or story data (`manifest.json` warnings).
- The art shows one fixed protagonist appearance and staff looks that differ from the 3D draft models.
- Art licence/tool terms are as recorded by the owner; not verified in the repo.

## Pending

- Owner: watch the previews, review the draft PR, merge when satisfied.
- Mac (Forward+ on the 8 GB M1): look, texture memory and frame time (2 × 1600x900 textures held), music mix over ambience. Not run.

## Next exact steps for a new session

1. `git fetch origin --prune`; check the PR state for `claude/static-graphic-novel-cutscenes`.
2. If the owner asks for changes to timing, music or captions, edit `data/cutscenes/cs_ch0N_static_gn.json` only; never edit the PNGs (the SHA-256 test fails if you do).
3. Re-run `python3 tests/qa/run.py --godot <Godot 4.7>`; in a slow container the runner's 150 s import step can time out on a cold cache, so run the import once with `--editor --import --quit` first.
