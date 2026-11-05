# Mac release build and acceptance

Added 2026-11-04 on `claude/mac-release-polish`. This is the path from the repository to a standalone macOS app that runs without the Godot editor, and the hands-on pass that decides what still blocks release. The detailed per-system checks stay in `docs/MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md`; this file adds the packaging steps and the release-specific checks.

Hardware target: Apple Silicon MacBook Air, 8 GB. Never build on the SSK external-drive working copy: clone into `~/Developer` first.

## 1. What is set up in the repository

- `export_presets.cfg` is now committed (it was in `.gitignore`). Three presets:
  - **macOS**: universal app (`build/macos/The Forensic Ward.zip`), bundle id `com.forensicward.game`, version 1.0.0 (1), category Games, ad-hoc signing (Godot's built-in signer), no notarization. Godot's official macOS template only ships universal binaries, so arm64-only is not an option without a custom template.
  - **Linux (container smoke test)**: same content filters, for checking the pack in a Linux container.
  - **Linux (export QA, with tests)**: the same pack plus the game tests and their fixtures, so the whole test suite can run from a packed build.
- Content filters: every authored JSON the game reads at run time (`data/**`, `audio/**`, the Naomi acting cues and the three `tools/character_animation` JSON libraries) is included; the test suite, capture tools, handoffs and narration-review pages are excluded from the player build. Review-only folders already carry `.gdignore`.
- `project.godot`: `rendering/textures/vram_compression/import_etc2_astc=true`. Godot refuses a universal or arm64 macOS export without it. It made no difference to the pack size here (606 MB either way), because the game's textures are not VRAM-compressed.
- `tools/release/export_macos.sh`: imports, exports, unpacks with `ditto`, verifies the signature and runs a launch check (the app starts on its own pack, validates all content and quits).

## 2. Build on the Mac

```sh
cd ~/Developer
git clone https://github.com/biancaalexis132-png/ForensicWard_Game.git forensicward-release
cd forensicward-release
git checkout claude/mac-release-polish        # or main once merged
git rev-parse HEAD                             # record with the report
GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/release/export_macos.sh
```

If the 4.7 export templates are not installed, the script downloads the official archive (about 1.3 GB), checks its SHA-512 and installs only `macos.zip`. The editor route works too: Editor, Manage Export Templates, Download and Install; then Project, Export, macOS, Export Project.

Expected: `LAUNCH_CHECK PASS: content valid at boot`, and `build/macos/The Forensic Ward.app` about 780 MB.

Known log noise in exported builds: ten lines `Attempt to disconnect a nonexistent connection ... AnimationLibrary ... animation_added/animation_removed` when the cast load. They come from `CharacterAnimationRig._prepare_players()` swapping the imported animation library for an edited copy; the swap still works (the cast animate) and the editor does not print them. Treat any other `ERROR` line as a finding.

## 3. Play the packaged app

Open `build/macos/The Forensic Ward.app` from Finder (not the editor). The first launch of an ad-hoc signed app may need right-click, Open. Record PASS, FAIL or NOT TESTED for each line, with the commit.

| Area | Check | Pass when |
|---|---|---|
| Launch | Double-click the app | Title screen within a few seconds; no Godot editor needed; window title "The Forensic Ward" |
| New game | New Game | Prologue plays (Esc skips), then Chapter 1 on the ward |
| HUD | Talk to Naomi, then walk to Interview Room A | "Objective complete" then "New objective" appear top right under the clock, never over a name tag; the objective shows once (checklist top left), with no second "Objective:" line at the bottom; toasts appear top right under the banner |
| Dialogue | Naomi's handover; Elias's interview, every choice | Voices and subtitles match; nothing overlaps |
| Elias | Look at his shoulders in the interview | No dark marks where the sweatshirt meets the shoulders |
| EHR orders | J, Orders tab, place and confirm an order | Status and history update |
| Journal, map | Open each from the pause menu or their keys | Entries and current floor shown |
| Customization | Title, Customize new psychiatrist | Choices save and the female/male voice follows the choice |
| Continuing Practice | Jordan's case in Chapter 1 | Opens, completes, and the shift can close |
| Ward rounds | One patient per chapter | Labs, plan, accepted |
| Save and load | Save mid-chapter, quit the app, reopen, Continue | Same place, same objective, no repeated banners |
| Chapter transitions | Finish Chapter 1 to 2, and so on | Recap, end panel, next chapter title card |
| Endings | All three endings (a save before the final choice helps) | Each ending text and recap plays and returns to the title |
| Listening | Voice timing, subtitle timing, music under voices | No clipped or late lines; voices audible over music |
| Performance | Activity Monitor while playing | Memory well inside 8 GB; no stutter when a voice starts |
| Quit and reopen | Quit from the menu; reopen | Settings kept; Continue offers the save |

Saves and settings of the packaged app live in `~/Library/Application Support/Godot/app_userdata/The Forensic Ward/`, the same folder the editor uses for this project, so delete that folder for a clean first-run test.

## 4. Giving the app to other people

The ad-hoc signature is enough on the Mac that built it. A copy downloaded on another Mac will be blocked by Gatekeeper. For that, the owner needs an Apple Developer ID (paid Apple Developer Program), then in the macOS preset: `codesign/codesign` set to the Developer ID identity and `notarization/notarization` set up with an App Store Connect API key. Those credentials stay in Godot's local credential store, never in the repository.

## 5. What the container verified (2026-11-04, Godot 4.7 stable, Linux)

- macOS preset exported: `The Forensic Ward.zip` 652 MB (app 777 MB, pack 606 MB), `Info.plist`, `_CodeSignature`, privacy manifest present. Not run: there is no Mac in the container.
- Linux release export run headless from its own pack: boots, "Boot OK (content valid)", exit 0.
- The editor binary on the exported Linux pack (`--main-pack`): Chapter 1 audio sequence done at 62.0 s with every voiced line playing its clip.
- The export-QA pack: the full game test suite run from the pack, 408 passed and 5 failed. All five are in `test_narration.gd` and fail at the same setup step: they copy a raw `.ogg` into `res://audio/narration/` as a temporary stimulus, which a read-only pack cannot accept. They pass in the editor run. Every other system (saves, chapters 1 to 5, endings, EHR, journal, map, ward rounds, Continuing Practice, cast, cutscenes) passed from the packed files.

## 6. Mac result

- Mac run 2026-11-04 (Bi's MacBook Air M1, Godot 4.7.2.stable.official.ed1daf0bf, fresh clone `~/Developer/forensicward-release` at `c96f5f2`, same code as `main` `144e609`; nothing on the SSK drive): `tools/release/export_macos.sh` PASS (4.7.2 templates SHA-512 OK, ad-hoc signature valid, app 741 MB, LAUNCH_CHECK PASS, 0 ERROR lines); `tools/qa/mac_acceptance.py` exit 0 (QA 19/0/0, GLB 199/0, game 417/0, audio 1720/0, pharmacology 0 failures, Python tests passed, Chapter 1 sequence done); the packaged app opened from Finder-equivalent `open` and showed the title screen (New Game, Customize, Continue greyed, Settings, Quit, Ready.). App at `/Users/bi/Developer/forensicward-release/build/macos/The Forensic Ward.app`. Hands-on playthrough, endings and listening: NOT TESTED, waiting on Bi.
