# The Forensic Ward

A first-person psychological thriller and forensic psychiatry simulation for **macOS**, built in **Godot 4.7** (GDScript, Forward+ renderer).

- Design: `docs/design/` (Master GDD v0.1, engineering handoff)
- Sprint 1 report (file tree, architecture, test checklist): `docs/SPRINT_01.md`
- Clinical review record: `docs/clinical_review_log.md`

## macOS setup

You need two free programs:

1. **Godot 4.7 (standard, not .NET).** Download it from <https://godotengine.org/download/macos/>, open the `.zip`, and drag **Godot.app** into **Applications**.
   - On first launch, if macOS says the app "can't be opened", **right-click Godot.app → Open → Open**. You only need to do this once.
2. **GitHub Desktop.** Download it from <https://desktop.github.com> and sign in with your GitHub account.

### Get the project

1. In GitHub Desktop, click **File → Clone repository…**, choose `biancaalexis132-png/ForensicWard_Game`, pick a folder and click **Clone**. Skip this if you've already cloned it.
2. To test a branch before it's merged (for example Sprint 1), click **Current Branch** at the top of GitHub Desktop and choose the branch, such as `claude/sprint-01-foundation`. Then click **Fetch origin**.
3. Open Godot. If the project is already in the Project Manager list, double-click **The Forensic Ward**. Otherwise click **Import**, select the `project.godot` file in the cloned folder, and click **Import & Edit**.
4. The first import takes a few seconds. The **Output** panel should show no red errors.

### Run the game

- Press **Cmd + B**, or click **▶** at the top right of the editor.
- Click inside the game window once so it captures the mouse.
- To stop, press **Cmd + .** or close the window.

| Control | Action |
|---|---|
| W A S D (or arrow keys) | Walk |
| Shift | Walk faster |
| Mouse | Look around |
| E | Use the door / terminal / document / person under the crosshair |
| Esc | Close the open panel, or open the pause menu (save, load, accessibility, quit) |
| F1 | Pause menu (accessibility options) |
| J / Tab | EHR / evidence board (placeholders until Sprints 2–3) |

If the game shows **"Content validation failed"**, a file in `data/` has an error. The screen lists the file, the JSON path and what to fix.

### Run the automated tests

- **In the editor:** in the FileSystem panel, double-click `scripts/tests/TestRunner.tscn`, then press **Cmd + R** (Run Current Scene). The results appear on screen and in the **Output** panel.
- **In Terminal:** from the project folder, run:
  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://scripts/tests/TestRunner.tscn
  ```
  Exit code `0` means every test passed.

### Renderer

The project uses **Forward+** (Metal on Apple Silicon). If your Mac shows rendering problems or low frame rates, go to **Project → Project Settings → Rendering → Renderer → Rendering Method**, choose **mobile** (or **gl_compatibility** for older Intel GPUs), and restart the editor.

## Project layout

```
data/                  Authored JSON content (validated at boot)
docs/                  Design docs, sprint reports, clinical review log
scenes/main/           Main.tscn: composition root (world + player + UI)
scenes/world/          HospitalGreybox.tscn and modular rooms/
scenes/player/         FirstPersonController.tscn
scenes/props/          Door, Terminal, CluePickup, Character, furniture
scenes/ui/             HUD, InfoPanel, PauseMenu
scripts/autoload/      Manager singletons (EventBus, ContentRegistry, TimeManager, ...)
scripts/content/       JSON schemas and validator
scripts/dialogue/      IntentMatcher (bounded free-text matching)
scripts/player/        First-person controller
scripts/interaction/   Interactable component
scripts/world/         Room builder, doors, terminals, pickups, characters
scripts/ui/, main/     UI controllers, Main
scripts/tests/         TestRunner + test_*.gd suites
staging/               Approved modules awaiting integration (ignored by Godot)
```

## Ground rules

- Clinical rules are data with a `review_status`. Rules not marked `APPROVED` never apply in validated builds (GDD §8).
- Authored content (`data/`) is immutable at runtime; managers own run state, and `SaveManager` saves it.
- Systems talk through `EventBus` signals, never through each other's internals.
- All patient data is fictional.
