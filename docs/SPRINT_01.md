# Sprint 1: Foundation

**Branch:** `claude/sprint-01-foundation` · **Engine:** Godot 4.7 (verified with 4.7-stable, headless, on Linux; target is macOS) · **Status:** ready for review

## Scope delivered

| Deliverable | Where |
|---|---|
| Valid `project.godot`: autoloads, input map, physics layer names, audio buses, clinical build mode | `project.godot`, `default_bus_layout.tres` |
| First-person keyboard/mouse controller with collision and camera | `scenes/player/FirstPersonController.tscn`, `scripts/player/FirstPersonController.gd` |
| Modular hospital hallway | `scenes/world/rooms/HallwaySegment.tscn` (chained three times), `scripts/world/RoomShell.gd` |
| Psychiatric interview room | `scenes/world/rooms/InterviewRoom.tscn` |
| Office and records archive | `scenes/world/rooms/Office.tscn`, `RecordsArchive.tscn` |
| Interactive doors (swing, locks tied to access grants, saved state) | `scenes/props/Door.tscn`, `scripts/world/Door.gd` |
| EHR terminal placeholder (census view; opens each record once per day) | `scenes/props/Terminal.tscn`, `scripts/world/Terminal.gd` |
| Interactable objects: documents, staff, patient | `scenes/props/CluePickup.tscn`, `Character.tscn` |
| JSON loading and validation (schema, types, ids, cross-references, actionable errors) | `scripts/content/`, `scripts/autoload/ContentRegistry.gd` |
| Foundational managers from the handoff | `scripts/autoload/*.gd` |
| HUD, info panel, pause menu (save/load, accessibility) | `scenes/ui/`, `scripts/ui/` |
| Test runner and 43 automated tests | `scripts/tests/` |

## Architecture

```
Autoloads (load order matters: earlier ones are ready before later ones)
  EventBus         domain signals only
  Settings         accessibility and input preferences (user://settings.cfg)
  SaveManager      versioned saves, providers, checksum, seeded RNG streams
  ContentRegistry  loads + validates res://data/*.json, freezes it read-only
  TimeManager      minute clock, shifts, pause reasons, deterministic schedule
  PatientManager   mutable patient state, event-id dedupe, location guard
  ClinicalRules    pure evaluator; honours review_status and build mode
  DialogueManager  dialogue graph, IntentMatcher, transcript, rapport
  EvidenceManager  clues + provenance, pins, links, hypotheses, verifications
  TrustManager     respect/trust/suspicion vectors, access grants

Main.tscn (composition root, also the "world" save provider)
  HospitalGreybox.tscn
    Rooms/ HallwayA..C (HallwaySegment), Office, RecordsArchive, InterviewRoom
    Doors/ Office, Interview, Archive (badge), W0-B (sealed)
    Props/ nursing-station desk, security access panel
    Characters/ Nurse Bennett, Dr Voss, Elias Ward
  Player (FirstPersonController)
  HUD · InfoPanel · PauseMenu
```

Key contracts:

- **Save providers** implement `to_save_data()`, `load_save_data(data)` and `reset_state()`. The save file holds `{save_version, seed, checksum, state}`; the checksum is SHA-256 of canonical JSON.
- **Interaction:** the player's `RayCast3D` hits an `Interactable` (an `Area3D` on physics layer 2). Walls (layer 1) block the ray. Props connect to `Interactable.interacted`.
- **Input mode:** `Main` alone decides mouse capture, player control, HUD visibility and the clock's `"ui"` pause reason.
- **Clinical governance:** `ClinicalRules` never applies `medical_effects`. Unapproved rules apply only `non_medical_effects`, only in `prototype` build mode, and every application emits `clinical_review_flagged`. Set `forensic_ward/clinical/build_mode` to `validated` to block all unapproved rules.

## Sprint 1 walkthrough (about 5 minutes)

1. Spawn at the south end of the corridor. The clock reads Day 1 08:00 and advances slowly while you explore.
2. **Office** (first door on the left): talk to Dr Voss (E). Use the **EHR Workstation** for the census, and take the **Transfer Summary** from the desk.
3. **Corridor:** the **Records Archive** (second door on the left) is locked. Talk to **Nurse Bennett** at the nursing station to receive the archive badge.
4. **Records Archive:** take the **1968 Ward Roster**.
5. **Interview Room** (door on the right): approach **Elias Ward** to see the authored observations and the interview topics.
6. **End of corridor:** check the **Security Access Log** (third clue). The **W0-B** door stays sealed.
7. Press **Esc → Save Game**. Move somewhere else, then **Esc → Load Game**: doors, clues, clock and position are restored.

## Test checklist

Automated (`scripts/tests/TestRunner.tscn`, 43 tests, all passing on Godot 4.7):

- [x] Shipped JSON validates; content is read-only after load
- [x] Missing field, wrong type, non-fictional patient, bad id format, duplicate id, unknown clue/observation/dialogue-state reference each produce an error naming the file and JSON path
- [x] Broken JSON reports the file and line; unknown fields are warnings only
- [x] "Is he eating?" maps to the nutrition topic; paraphrases match; unsupported input gets the authored fallback; matching is deterministic
- [x] Dialogue state transitions and transcript; transcript survives save/load
- [x] Opening a record twice, or replaying a clinical action, does not duplicate events
- [x] A pending rule applies only non-medical effects in prototype mode and nothing in validated mode
- [x] Identical action sequences from a fresh run produce identical state (including seeded RNG)
- [x] An automatic transfer is blocked while the patient is medically unstable; one location at a time
- [x] Scheduled events fire in time order, and shift changes are detected
- [x] Two clues can be pinned, linked, unlinked, relinked, and persist through save/load
- [x] A false hypothesis can be registered and refuted without side effects
- [x] Trust axes are bounded and independent; access grants work
- [x] Accessibility toggles are independent; a tampered save is rejected
- [x] Main boots; W moves the player; walls block; the ray focuses a door and E opens it; the door panel physically swings clear
- [x] The archive needs the nurse's badge; W0-B stays sealed; panels freeze/restore control and the clock
- [x] Picking up a document records provenance and removes it; world state (doors, player) survives save/load

Manual, on your Mac:

- [ ] Project opens in Godot 4.7 with no red errors in Output
- [ ] Cmd + B launches; WASD, mouse look, Shift, E and Esc all work
- [ ] Clicking back into the window after Cmd + Tab recaptures the mouse
- [ ] Doors swing smoothly; with **Reduce motion** on they snap and head bob stops
- [ ] With **Flashing / flickering lights** off, the light near W0-B is steady
- [ ] Save, quit and relaunch, then Load restores the session
- [ ] Frame rate is smooth (Forward+ / Metal)

## Decisions and deviations to review

1. **`data/dialogue.json` had a dangling state.** Choice `assess_motor` pointed to `"assessment"`, which wasn't defined, and the validator caught it. I added a clearly marked placeholder `assessment` state with one "Return to general questions" choice. The real assessment content should be authored in Sprint 2.
2. **New data files** (non-clinical, provisional): `data/staff.json` (working staff names from GDD §5, placeholder intro lines, access grants) and `data/intent_lexicon.json` (stopwords and synonyms for the intent matcher).
3. **Hypotheses stay in `clues.json`,** matching the supplied fixture, rather than a separate `hypotheses.json`.
4. **`Settings` autoload added** (not in the handoff list), for the accessibility toggles required by GDD §11 and acceptance test 10.
5. **Effect path vocabulary.** `mark_assessment_started` sets `patients.<id>.assessment.started = true`. Only the `assessment` and `flags` roots are writable by rules.
6. **The pharmacology model is approved but staged** (`staging/pharmacology/`, ignored by Godot). Integration into `ClinicalRules` is planned for Sprint 2.
7. **Visual check.** Screenshots were taken with the Compatibility renderer under a virtual display, which is all this environment supports. Forward+ on your Mac will look different (SSAO, glow, fog). Please confirm on hardware.

## Next (Sprint 2 per the handoff)

Patient record (EHR) view · cinematic Interview UI with typed questions · observation capture · `ClinicalRules` scaffolding plus pharmacology integration · save/load UI polish.
