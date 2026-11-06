# Choose your psychiatrist: character creator (Claude Code, 2026-11-05)

Bi's request (2026-11-05): "have a choose your psychiatrist where you can customize your style and aspects and voice changes based on if character is female or male". Thread "Add choose-your-psychiatrist character creator". Branch `claude/character-creator` from `main` `424a513`. Built on the existing profile screen (#135 added the female/male voice choice), not a new system.

Shared handoff docs (`AI_HANDOFF`, `AI_SESSION_HANDOFF`, `AI_PROGRESS_TRACKER`, `PROJECT_STATUS`) are left to the one PR that edits them (#149/#150 are open with edits), so these notes live here until they are folded in.

## What changed

- **New Game opens the creator.** `TitleScreen.choose_psychiatrist()` opens `ProtagonistScreen` in `new_game` mode ("Begin the shift" / "Back"); Begin saves the profile and then runs the old `TitleScreen.new_game()`. Back returns to the title. The separate "Customize new psychiatrist" title button is gone (the creator is now part of New Game). The title no longer steals keyboard focus from a screen over it.
- **`ProtagonistScreen` redesigned** ("Choose your psychiatrist"): live 3D preview on the left (drag or arrows to turn, Face / Full body, Hear voice), female or male psychiatrist cards on top, a Style tab (skin tone, hairstyle, hair colour, glasses, shirt, trousers as swatches and toggles) and a Name and background tab (name, pronouns, history, interest, reason, relationship). "Surprise me" randomises style only. Typing she/her or he/him still picks the matching body and voice.
- **Voice**: female or male picks the model and the psychiatrist's recorded voice (all 47 player lines already have a female clip). "Hear voice" plays real lines (`ch1_b2_player_001`, `_002`, `ch1_int_elias_ask_intake`) in the draft's voice without changing the game's voice until confirmed. New `AudioDirector.get_voice_path_for_variant`.
- **`scripts/protagonist/ProtagonistAppearance.gd`** (new) dresses either psychiatrist model: skin (body surface only, lashes untouched), hair colour, shirt and trousers tints; hairstyles borrow hair meshes across the two models (same bone names), fitted so the borrowed cap covers the wearer's own cap box; procedural glasses (round, rectangular, bold) on the head bone. Used by the preview and by `EncounterStage` (replaces its old colour code), so the Elias encounter shows the same person.
- **`scripts/ui/ProtagonistPreview.gd`** (new): SubViewport with its own world, studio light, idle_breathing loop.
- **Catalog** `data/protagonist_options.json`: 7 skin tones, 8 hair colours, 4 hairstyles (short, long, swept, none; old ids kept), 6 trousers, 7 shirts (new `tops`), 4 glasses (new `glasses`). Profile gains `top` and `glasses`; saves without them load with white shirt and no glasses (`ProtagonistProfile.LATER_DEFAULTS`).
- Removed `scripts/ui/ProfilePortrait.gd` (the old flat 2D portrait), now unused.

## Files

New: `scripts/protagonist/ProtagonistAppearance.gd`, `scripts/ui/ProtagonistPreview.gd`, `scripts/tests/test_character_creator.gd`, `tools/godot/capture_character_creator.gd`, `tools/godot/CaptureCharacterCreator.tscn`, this note.
Changed: `data/protagonist_options.json`, `scripts/protagonist/ProtagonistProfile.gd`, `scripts/ui/ProtagonistScreen.gd`, `scripts/ui/TitleScreen.gd`, `scripts/encounter/EncounterStage.gd`, `systems/audio/AudioDirector.gd`, `scripts/tests/test_playtest_voice.gd`, `scripts/tests/test_presentation.gd` (menu order now New Game, Continue, Settings, Quit).
Removed: `scripts/ui/ProfilePortrait.gd` (+ `.uid`).

## Tests

`test_character_creator` 7/0 (catalogs, save/load and old saves, model and voice swap, hair/glasses/tints, borrowed hair fit, Surprise me, New Game flow). `test_playtest_voice` 8/0 and `test_presentation` 7/0 after updating them to the new screen. Full QA (`tests/qa/run.py`, Linux headless, Godot 4.7 stable): game **480/0**, audio **1760/0**, QA **19/0/0**, GLB **211/0**, 0 ERROR lines, exit 0.

Review captures (Compatibility renderer under Xvfb, not Mac evidence): `tools/godot/CaptureCharacterCreator.tscn`; copies in the project files under `character_creator/`.

## Known limits and next steps

1. Untested on the Mac: look, preview performance, drag feel, voice preview level.
2. Hair borrowed across models is fitted by box, so the hairline is close but not sculpted; both body textures have a painted hairline band that shows a little above the ears with some styles.
3. The models have no separate jacket or coat mesh, so "style" is colours, hair and glasses; a white coat or blazer would need new meshes in Blender.
4. Only one voice per gender exists (Kokoro `am_liam` and `af_heart`). More voice choices need new clips generated with the local Kokoro setup on the Mac (`tools/audio/generate_voice.py`, `VOICE_VARIANTS`).
5. In first-person play the psychiatrist's body is seen only in the encounter stage.
