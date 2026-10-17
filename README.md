# The Forensic Ward

A 3D psychological thriller / clinical forensic psychiatry simulator built in **Godot 4.7** (Forward+ renderer).

## Getting the project onto your computer (first time)

You need two free programs: **Godot 4.7** and **GitHub Desktop**.

1. Install **GitHub Desktop** from https://desktop.github.com and sign in with your GitHub account.
2. In GitHub Desktop, choose **File → Clone repository…**, pick `biancaalexis132-png/ForensicWard_Game` and choose a local folder (for example `Documents/ForensicWard_Game`). Click **Clone**.
3. Open **Godot**. In the Project Manager, click **Import**, browse to the cloned folder, select `project.godot`, then click **Import & Edit**.
4. Press **F5** (or the ▶ Play button, top right) to run the game. You should see a dim room and a clinical monitor for sample patient PT-001:
   - Press **N** a few times to end shifts. Watch the clozapine level climb and a sedation alert appear, because the ward is smoke-free and the patient's CYP1A2 induction wears off.
   - Press **R** to cut clozapine to 300 mg/day, then keep pressing **N**. Sedation falls and a story clue unlocks.
   - Press **O** and **P** to drain and restore Objectivity.

## Getting updates

When new code is pushed to GitHub, open GitHub Desktop and click **Fetch origin** and then **Pull origin**. Godot reloads the changed files on its own. If it asks, click **Reload**.

If you change things in Godot (scenes, settings), GitHub Desktop lists the changed files. Write a short summary, click **Commit to main** and then **Push origin**.

## Project layout

| Folder | Contents |
|---|---|
| `autoload/` | Global singletons, always loaded: `EventBus` (signal hub) and `GameState` (save data, time, Objectivity) |
| `systems/pharmacology/` | `PharmacologyEngine` (autoload): CYP/renal pharmacokinetics, side effects, QTc, alerts. See `docs/PHARMACOLOGY_ENGINE.md` |
| `tests/` | Scenario tests. Open `tests/TestPharmacology.tscn` and press **F6** |
| `docs/` | System documentation and the patient JSON schema |
| `scenes/` | `.tscn` scenes; `scenes/main/Main.tscn` is the current boot scene |
| `systems/` | Gameplay logic: PharmacologyEngine, Bleed system and similar |
| `player/` | First-person controller |
| `ui/` | EHR terminal, evidence board, HUD |
| `data/patients/`, `data/drugs/` | JSON data authored by the narrative / clinical team |
| `shaders/` | Visual distortion shaders (chromatic aberration, flicker) |

## Architecture rules

- Systems communicate **only through `EventBus` signals** and never hold direct references to each other.
- Persistent facts live in `GameState`. Game rules live in `systems/`.
- Clinical and story content is data (JSON) and is never hard-coded.
