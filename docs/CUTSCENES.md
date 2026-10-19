# Graphic-novel cutscenes

Review-only motion-comic cutscenes in the locked "cinematic painted graphic novel" style. **Nothing here is enabled in the campaign.** A cutscene plays only when the owner asks for it with a preview argument or the review scene, until the owner approves both its visuals and its placement.

## How to watch the Chapter 1 pilot

On the Mac (Godot 4.7):

```sh
# Inside the real game, over the Chapter 1 ward, then back to gameplay:
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --cutscene-preview=cs_ch01_first_shift_pilot

# Standalone review scene (no save, stand-in backdrop). Also: open
# scenes/cutscene/CutscenePreview.tscn in the editor and press Cmd+R.
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/cutscene/CutscenePreview.tscn
```

Controls: **Esc** skips, **Enter / Space / E** advances one panel, **R** replays. Settings > Reduce Motion holds every panel still; subtitles follow the Subtitles setting.

Review stills (captured from the review scene, Compatibility renderer in a Linux container, not the Mac's Forward+): `docs/design/cutscenes/ch01_pilot_review/`.

## Pieces

| Path | Role |
|---|---|
| `scripts/cutscene/CutsceneDirector.gd`, `scenes/cutscene/CutsceneDirector.tscn` | CanvasLayer player. Panels, parallax layers, push/pan, dissolve/cut/fade-through-black, captions, subtitles, music context, skip/advance/replay, watchdog, one idempotent restore path. A child of `Main` (panel id `cutscene`), so Main's existing input mode, HUD and clock pause apply. |
| `scripts/cutscene/CutsceneRegistry.gd` | Loads and validates `data/cutscenes/*.json`; cross-checks line ids, cues, captions, textures. |
| `scripts/cutscene/CutscenePreview.gd`, `scenes/cutscene/CutscenePreview.tscn` | Review scene; `--capture-dir=<dir>` saves the middle of every panel. |
| `data/cutscenes/cs_ch01_first_shift_pilot.json` | The pilot: 7 panels, 52 s. |
| `tools/cutscenes/paint_panels.py`, `tools/cutscenes/ch01_pilot_plates.json` | Repaints the project's own renders into panel plates (numpy + Pillow, seeded, reproducible). |
| `assets/cutscenes/ch01_pilot/` | Painted plates (1600x900 PNG), shared glaze layer, provenance `manifest.json`. |
| `scripts/tests/test_cutscene.gd`, `tests/qa/test_cutscenes.py` | Godot behaviour tests and the static data contract (both run by `tests/qa/run.py`). |
| `scripts/autoload/EventBus.gd` | Two signals: `cutscene_started(id)`, `cutscene_finished(id, reason)`. |

Rules the code enforces:

- `approved: false` cutscenes refuse to play unless the director's `review_mode` is on; only `--cutscene-preview`, the review scene and tests turn it on. A `review_only` cutscene uses `trigger.kind` `manual_preview`. The only campaign placement is `mode` `campaign` with `trigger.kind` `chapter_start`, which the validator allows only on `approved: true` cutscenes; Main opens it when its chapter starts. No story beat can start a cutscene.
- Panels carry **no literal text**. Captions are `caption_ref` keys resolved from `data/campaign.json` (`institution.name`, `chapter.<id>.title`); speech is an existing `line_id` from `data/narrative/*.json`, played through `AudioDirector.play_line` (voice, ducking, subtitles as in gameplay). Lines from a later chapter are rejected.
- Music is an `AudioDirector` music context registered at runtime and ended on every exit, so the location's music comes back. `mus_temporal_fracture` is never allowed in a cutscene; `mus_final_revelation` and `mus_ending_credits` only from Chapter 5.
- Skip, a loaded save, the node leaving the tree, invalid data and the watchdog all go through one restore: stop the line, end the music context, restore the mouse mode, free the panels, emit `ui_panel_closed`. No story, clinical, evidence or save state is written (`test_cutscene_writes_no_game_state` compares `SaveManager.capture_state()`).
- Memory: only the current and the next panel's textures are held; the next one loads on a background thread. Plates are 1600x900, at most 3 layers per panel (the M1 8 GB starting budget from the cinematic spec).

## Schema (version 1)

```json
{
  "schema_version": 1,
  "cutscene_id": "cs_<chapter>_<name>",          // file name = <cutscene_id>.json
  "chapter_id": "ch1",                             // must exist in data/campaign.json
  "source_scene_id": "CH01_S01",                   // screenplay scene it covers
  "mode": "review_only",
  "approved": false,                               // only the owner changes this
  "trigger": {"kind": "manual_preview"},
  "fallback_action": "restore_world",
  "music": {"cue": "mus_waiting_room", "ambience": "duck", "ambience_db": -8.0, "fade": 2.0},
  "panels": [{
    "id": "p01_staff_entry",
    "duration_seconds": 8.0,
    "transition": "fade_black",                    // cut | dissolve | fade_black
    "transition_seconds": 1.2,                     // at most half the panel
    "frame": "inset",                              // inset (bordered) | full_bleed
    "layers": [{"texture": "res://...png", "parallax": 1.0}],   // 1 to 3; parallax 0..3 multiplies pan
    "motion": {"zoom_from": 1.06, "zoom_to": 1.02, "pan_from": [0.015, 0.0], "pan_to": [-0.01, 0.0]},
    "caption_ref": "institution.name",             // or null
    "line_id": null                                // or an existing dialogue line id
  }]
}
```

## Chapter 1 pilot: reconciliation with the two packages

Sources read (read-only, from the owner's SSK drive): `fw_cinematic_master/` (Five-Chapter Cinematic Master v1: spec, sample JSON, CH01–CH05 shotbooks, music plan) and `ForensicWard_Production_Roadmap_and_Cutscenes_v3/` (CH01 graphic-novel pilot, beat map, `cutscene_ch01_pilot.json`). Neither package is committed; both describe themselves as proposals, not canon. Canon checked against `docs/design/screenplays/ForensicWard_Complete_Campaign_Package_v1/chapters/CH01_THE_ADMISSION_EXPANDED_SCREENPLAY.md`, `data/narrative/chapter1.json`, `data/campaign.json`, `audio/cues.json`.

| # | Panel (time) | Source plate | Decision and why |
|---|---|---|---|
| 1 | Staff entry (0–8 s), caption "Ashcroft State Forensic Hospital" | `assets/renders/stage4/visitor_screening.png` | The spec's exterior panel is replaced: no exterior asset exists and Scene 01 is set at the staff entry. The screening room is from the security wing render (stage 4); **placement needs the owner's call**. |
| 2 | Badge door (8–14 s), caption "Chapter 1: The Admission" | `stage4/security_corridor.png` | Title comes from `campaign.json` (still provisional, F0 C2), not the packages' "CHAPTER ONE — THE ADMISSION". |
| 3 | Office desk (14–20 s) | `stage2/psychiatrist_office.png` | Closed chart only; no patient details. |
| 4 | Working corridor (20–29 s) | `stage2/corridor_20m.png` | |
| 5 | Naomi at the nursing station (29–39 s) | Naomi v04 in-game capture `ingame_review_v04/v04_listen.png` | **No dialogue**: `ch1_b2_bennett_001` is her first line in the playable Scene 03 handover and would be heard twice. Naomi v04 is not an approved likeness. |
| 6 | Records shelf (39–45 s) | `stage2/records_archive.png` | Sealed, unlabelled boxes. No Ward Zero name, signage or imagery (first authorised entry stays in Chapter 3). |
| 7 | Corridor return (45–52 s), full bleed | `stage2/corridor_20m.png` (crop) | Pushes in, then the director's exit fade dissolves into gameplay. |

Other reconciliations:

- **Panel count and length:** the Master spec's 7 panels / 52 s (as the owner asked), not the v3 package's 5 panels / 48 s.
- **Music:** `mus_waiting_room` (Master spec default), registered as a cutscene context that ducks ambience by 8 dB. The v3 package suggested `mus_main_theme_alt` (the existing `cinematic` context). One-line change in the JSON if the owner prefers it.
- **"DAY 1 · MORNING SHIFT" caption (v3) omitted.** The game clock starts Day 1 08:01, day shift, but Naomi's canonical handover says Elias held his posture "for most of the afternoon" and asks for a review "before the evening round". That timing conflict is the owner's to settle; no caption is shown until then.
- **Security officer lines** in Scene 01 ("First day? Badge visible, please.") have no line ids in `data/narrative`, so they are not used. They can be added once they are authored as real lines.
- **Sample JSON fields** adapted to the real systems: `subtitle_line_id` → `line_id` (must exist), `text_overlay` → `caption_ref` (approved text only), `music_candidate` → `music` context, `manual_debug_only` → `manual_preview`.
- **Reveal boundaries** (Ch3 first authorised Ward Zero entry, Ch4 Scene 09 corridor loop, three Ch5 endings): nothing in the pilot touches them; the registry blocks the reserved cues and later-chapter lines.

## Known limits

- Plates are repainted Blender/in-game renders, not hand-painted art; the brush and ink treatment is procedural (`paint_panels.py`). Naomi's plate keeps 60% of the unpainted capture so her face is not smeared, and inherits v04's known face issues.
- Not yet seen on the Mac: Forward+ look, frame time and memory on the 8 GB M1, audio mix of `mus_waiting_room` over ward ambience.
- Quitting with `--quit-after` while a cutscene's music is playing reports "resources still in use" (the music stream is still fading). The normal window-close path silences audio first.

## Chapter 2-5 title cards (review-only)

`cs_ch02_title` to `cs_ch05_title`: three panels each (20 s), opening on the chapter's title from `campaign.json`, with no dialogue and environment plates only (no character likeness). Plates come from `tools/cutscenes/ch0N_title_plates.json` via `paint_panels.py`. Chapter 3's card shows only the historic sublevel, and Chapter 4's shows the threshold room already seen in Chapter 3, so neither reveals Ward Zero or the corridor loop early. The owner approved the visuals and their placement on 2026-10-19, so they are `approved: true`, `mode` `campaign` and `trigger.kind` `chapter_start`: each plays when its chapter opens, and Esc skips it. The Chapter 1 pilot stays review-only.

## Static graphic-novel chapter recaps (owner-approved art and placement)

Bi approved the **Static Graphic-Novel Cutscenes Final v1** artwork for Chapters 1-5 on 2026-10-19 (project thread "Graphic-novel cutscenes"). The art is used as **static illustrated panels**: no character animation, no regeneration, repainting or restyling. Each chapter is one cutscene, `cs_ch0N_static_gn`, that shows the package's panels in the package's order. Bi chose the placement the same day: each one plays **when its chapter is completed** (`mode` `campaign`, `trigger.kind` `chapter_complete`, `approved: true`), drawn over the end-of-chapter panel, which is still there to continue from when the recap ends or is skipped. A recap only shows what the chapter has already played, so no reveal comes early. This is on the feature branch only; `main` gets it when the owner merges.

| Cutscene | Panels | Length | Music | Captions |
|---|---|---|---|---|
| `cs_ch01_static_gn` | 7 | 40.5 s | `mus_waiting_room` | panel 2: `institution.name` |
| `cs_ch02_static_gn` | 7 | 40.5 s | `mus_transition_unease` | none |
| `cs_ch03_static_gn` | 7 | 40.5 s | `mus_narrative` | none |
| `cs_ch04_static_gn` | 8 | 46.0 s | `mus_procedure` | none |
| `cs_ch05_static_gn` | 7 | 40.5 s | `mus_compassion` | none |

How to watch on its own (Mac): `/Applications/Godot.app/Contents/MacOS/Godot --path . -- --cutscene-preview=cs_ch01_static_gn` (in the game) or `... res://scenes/cutscene/CutscenePreview.tscn -- --cutscene=cs_ch01_static_gn` (review scene). Esc skips, Enter advances, R replays; Reduce Motion holds every panel still.

How it is built:

- `tools/cutscenes/import_static_graphic_novel.py <zip> --chapter N` copies the panels byte-identical from the owner's zip into `assets/cutscenes/static_gn_v1/ch0N/` and writes `manifest.json` with each file's SHA-256. `tests/qa/test_cutscenes.py` fails if a copy stops matching its hash. The package's full pages and the seven alternate Chapter 1 illustrations are **not** committed; they stay in the owner's zip.
- One layer per panel and no glaze overlay, so nothing is painted over the art. Motion is restrained: zoom 1.00-1.03 with at most 0.6 % drift, alternating push in and pull out. First panel fades from black, the rest dissolve.
- No `line_id`: dialogue stays in gameplay exactly as written, so no line is heard twice and no line from a later chapter can play. The soundtrack is unchanged; each cutscene uses an existing music context and ends it on exit. The reserved reveal cues are never used.
- Captions come only from `data/campaign.json`. Every package panel 1 already has the chapter title painted in, so no title caption is added on top.

Code: `CutsceneRegistry` accepts `chapter_complete` only on an approved campaign cutscene and finds it with `chapter_complete_cutscene()`; `Main._on_chapter_completed` opens it on `EventBus.chapter_completed`.

Rollback: the existing cutscenes are untouched. `cs_ch02..05_title` still open Chapters 2-5 in the campaign, and the Chapter 1 pilot and every plate under `assets/cutscenes/ch0*` stay in place. To turn the recaps off without deleting anything, set a file back to `mode` `review_only`, `approved: false`, `trigger.kind` `manual_preview` (and drop it from `OWNER_APPROVED_CAMPAIGN` in `tests/qa/test_cutscenes.py`); reverting the branch's last code commit does this for all five. Deleting the five `cs_ch0N_static_gn.json` files and `assets/cutscenes/static_gn_v1/` removes the new work completely.

Findings for the owner (the art itself is not changed):

- **Reveal timing (why the recap placement).** Chapter 3's page opens on the Ward Zero sign, and its painted title reads "Chapter 3 — Ward Zero" while `campaign.json` says "Chapter 3: Beneath the Hospital". Chapter 4 panels 5 and 8 show the repeating clock corridor from Scene 09. Chapter 5 panel 6 shows three folders that stand for the three endings, and panel 7 a shared epilogue; there is no ending-specific art. Played at chapter start these would come before their scenes; as chapter-close recaps they come after.
- Paperwork, names, dates and record numbers in the art (for example Mara's record cards in Chapter 2) are illustrative only and are not clinical or story data.
- The art shows one fixed protagonist appearance and staff looks that differ from the 3D draft models.
- Not seen on the Mac yet: Forward+ look, texture memory and frame time on the 8 GB M1 (only the current and next 1600x900 texture are held), audio mix.
