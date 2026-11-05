# Mac playtest fixes: Claude Code handoff, 2026-11-05

Requested by Bi after the first hands-on play of the packaged Mac app (2026-11-04), relayed by the coordinator. Branch `claude/mac-playtest-fixes` from `main` (`144e609`, then `fbd1544` merged in). Draft PR to `main`; nothing merged by the agent. The bigger asks from the same feedback (Elias on-screen physical exam and full history, 1:1 sitter, orders flow, background hospital staff) belong to a separate thread and are not touched here.

## What changed

1. **Naomi turns to you and moves when you talk to her.** She now gets the shared `CastPerformer` like the rest of the cast (turn to the player, listen, idle, talk gestures). During her cue-driven handover lines her own `NaomiActingController` keeps the body (`CastPerformer.body_busy`); the performer only turns her. `Character._on_interacted` starts both. Test: `test_naomi_keeps_her_controller_and_turns_to_the_player`.
2. **The protagonist's voice follows the character.** The wiring was already right (`ProtagonistProfile.gender()` picks the female or male take; all 47 female clips exist), but the choice was easy to miss. The profile screen labels it "Voice (gender)", and typing pronouns picks the matching voice (she/her → female, he/him → male; first slash segment). Test: `test_pronouns_pick_the_matching_voice_in_the_profile_screen`.
3. **Dr. Voss walks out of the office after the talk.** New `scripts/world/CastExit.gd`, authored per character as `exit_after_talk` in `data/world_chapter*.json` (points in the marker's frame, like `route`; optional `door`). Once the conversation is over and the chapter has nothing more for her (no situational line, no open story scene), she walks to the office door, it opens, she steps into the corridor and walks north, then leaves the scene and the door closes behind her. She comes back to her marker as soon as the story has something for her again, and on every load. Cosmetic, nothing saved. `WardCharacter.set_away()` hides her on top of `present_when`. Authored for Chapter 1 only (`door_office`); later chapters can add the same entry. Validated in `ContentSchemas`/`ContentValidator`. Tests: `test_exit_validation`, `test_voss_walks_out_of_the_office_after_the_talk_and_is_back_on_load` (path clear of walls and props with the door open, walk cycle used, door left as found, back on load).
4. **Ward round: no choices for patients you have not seen.** A patient who waits on the ward in 3D (`data/ward_round_bedside.json` `patients`) must be approached there first. From the EHR alone, their case shows "not seen yet" in the census, and the bedside, labs and plan show where they are ("Go to Room 01 on the ward and approach …") with Submit off. Approaching them (`Character` sends `at_bedside`) records `seen` in `WardRounds` (saved; older saves count a bedside talk or a submission as seen). The chapter-close notice now says to see them on the ward. EHR-only cases are unchanged. `WardRoundBedside.place_label_for()` added. Tests updated to reach the bedside the way a player does, plus `test_a_patient_on_the_ward_is_seen_there_before_the_plan_opens`.
5. **Theme music from launch, not buried under the "rain".** Nothing started the `main_menu` music context, so the title was silent. `TitleScreen.open()` now starts it (main theme, ambience stopped) and keeps `AudioDirector` processing while the title pauses the game; closing hands the music back (the prologue's own music, or the location's). The "rain" was the broadband corridor day bed (centroid about 3 kHz, -31.5 LUFS, as loud as the ward underscore): corridor day bed 0 → -6 dB and low-passed at 7 kHz, reception day bed -4 → -8 dB and 7 kHz. Underscore level unchanged, so its audio tests still hold. Test: `test_the_main_theme_plays_under_the_title_from_the_start`; `TestAudio` bed-level check updated to -6 dB.
6. **Cmd-Q.** `Main._quit_gracefully()` now waits three process frames (which arrive even while paused and at any time scale) instead of a 0.25 s timer, and a second close request quits at once. Probe in the container: a close request with the tree paused quit in 10 ms, exit 0. Still needs the real Cmd-Q check on the Mac.

## Validation (Linux container, Godot 4.7 stable)

See the newest `docs/AI_HANDOFF.md` entry for the full QA result and SHA.

## Not done

- Mac: rebuild the app from this branch and check Naomi, the voice, Voss, the ward round gate, title music and Cmd-Q by hand.
- Elias redesign and background staff: separate thread.

## Resume here

1. `git fetch origin --prune`; read the newest `docs/AI_HANDOFF.md` entry.
2. Mac (Remote Control or Bi): `cd ~/Developer/forensicward-release && git fetch && git checkout claude/mac-playtest-fixes` (or `main` once merged), `tools/release/export_macos.sh`, then open the app and check the six items above. Never run git on the SSK drive.
