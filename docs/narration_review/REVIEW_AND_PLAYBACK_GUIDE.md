# The Forensic Ward — narration approval package

Review checkpoint, 19 October 2026. This is NOT the completed narrated game or a final release ZIP.

## Verified baseline and handoff corrections

Inspected fetched GitHub main `2779875` (PR #94 merged), from clean continuation branch `codex/cutscene-narration-sample`. No open PRs existed at review start. The local original checkout was behind main. Historical handoff rows saying static recaps, cast drafts, title screen and campaign finish are unmerged are stale: their delivered code is now on main. Branch `claude/static-graphic-novel-cutscenes` was deleted after merge; runtime checkpoint `bac05fe` is preserved in main's ancestry. Older handoff claims do not establish current readiness.

All five entries in `data/campaign.json` say playable. Chapters 2–5 still carry `provisional: true`; the top-level notes incorrectly say those chapters remain planned. Authored end-to-end story and three ending test paths exist. This means playable campaign logic exists, not that every expanded screenplay shot, clinical content or visual asset is production complete.

Realistic 3D cast completion remains pending. `CharacterVisualPreview.gd` explicitly retains placeholder characters in normal play and exposes Naomi v07 and six draft cast models only through review arguments. Models, clothes/hair finish, likeness, integration, Mac visual review and performance must be resolved before presenting the campaign as playable with finished realistic characters. Do not infer model approval from approval of illustrations or earlier animations.

## What is included

- Existing approved artwork, unchanged: 36 PNGs, chapter manifests, five runtime recap JSON files.
- Supplied five narration scripts and original draft authoring manifest, preserved as DRAFT source references.
- SHA-256 inventory independently checked against every approved art manifest.
- Chapter 1 narrator audition: a completed 17.04-second ElevenLabs recording, linked below with voice attribution. The binary could not be archived because the workspace download request returned HTTP 403; it is available in the connected speech view. No local recording or synchronized audition movie is claimed.
- This review, placement guide, integration specification and test evidence. No runtime changes, narration activation, new character approval or merge.

Optional concept art from the attachment was not imported or used as replacement art. Do not add words directly to approved PNGs. Captions/subtitles should be separate UI overlays to preserve hashes.

## Listen and approve

https://elevenlabs.io/app/flows/u4R8fakQoM6M80IFufxG

Narrator: Shawn – Calm & Grounded, ElevenLabs library voice `d8XDgkC47nxEyrCyckjI`; model `eleven_multilingual_v2`; one take. See `audio/narration_review/ch01/voice_source.json` for source, text and generation IDs. No voice cloning was performed. Distribution rights under the account plan have not been independently verified; this is an approval sample.

The sample uses the supplied Chapter 1 p01–p02 text verbatim. Those two images were visually inspected: arrival/security and entry into the ward match their narration without introducing patient outcomes. The sample does not repeat gameplay dialogue. It is a voice/writing audition, without score or timed picture edits. Its 39 whitespace-delimited words over 17.04 seconds give approximately 137 words/minute, within the draft's 125–145 target; audible pacing still requires owner review. Remaining panels still require image-by-image continuity review against actual story flags and screenplay versions.

Owner approval of voice, pacing and writing is required by the current user request BEFORE producing Chapters 2–5 recordings and final integration. No approval has been inferred from silence. All later work below is pending.

## When cutscenes play

Keep gameplay → illustrated chapter recap → normal completion panel → next chapter. On final chapter, return to the campaign completion summary; never invent Chapter 6. Existing chapter-start title cards remain separate.

| Chapter | End recap ID | Panels | Existing silent timing | Existing music |
|---|---|---:|---:|---|
| 1 The Admission | cs_ch01_static_gn | 7 | 40.5 s | mus_waiting_room |
| 2 The Missing Hours | cs_ch02_static_gn | 7 | 40.5 s | mus_transition_unease |
| 3 Beneath the Hospital | cs_ch03_static_gn | 7 | 40.5 s | mus_narrative |
| 4 The Official Record | cs_ch04_static_gn | 8 | 46 s | mus_procedure |
| 5 Beyond the Lines | cs_ch05_static_gn | 7 | 40.5 s | mus_compassion |

Trigger only from actual `chapter_completed(chapter_id)`, never on entering an incomplete slice or loading a chapter. `Main._on_chapter_completed` currently opens the approved recap over the already-created completion panel; closing the recap exposes that panel. Preserve this ordering and gate next-chapter input until the recap exits. Do not fire chapter completion again for replay.

Narration must extend these existing short panel holds; never crop speech to the silent timings. Existing `line_id` slots are null. The draft JSON cannot be placed directly into CutsceneRegistry.

## Panel mapping and editorial work still needed

Use the existing runtime panel IDs and texture paths as authority. The authoring manifest has seven narration beats per chapter, but Chapter 4 has EIGHT approved panels. Inspect all eight images and author/map eight distinct narration/caption units; do not discard, renumber or replace a panel, or attach the seventh line blindly to the last image. The other chapters have seven panels each. Approved art incidental chart text, names and diagnoses are not canonical evidence.

Chapter 1: first shift, unit, Bennett, transfer, interview uncertainty, restricted access, documented handoff. Check optional gameplay: an interview or corroboration must not be asserted just because the chapter has completed if those events were optional. Select supported variants or use neutral framing.

Chapter 2: Mara's autonomous care, source discrepancy, staff handoff, contradictory records and access limits. Avoid suggesting her condition explains institutional records. Chapter 3: authorized inspection, documentation, route check and safe return. Do not retrospectively claim a confirmed loop in Chapter 3. Chapter 4: source independence, controlled observations and the repetition recorded as `observed_repetition_unverified`; no diagnosis or mechanism inferred. Chapter 5: accountable ending, unresolved questions, Mara and continuing care. Audit literal and semantic overlap with gameplay dialogue before recording.

### Chapter 5 endings (shared artwork)

| Variant | Existing story flag | Draft ending insert |
|---|---|---|
| A | ch5_ending_review | Independent Review |
| B | ch5_ending_restricted | Restricted Access |
| C | ch5_ending_inquiry | Continuing Inquiry |

Resolve exactly one ending from saved story state at recap entry and retain it for replay. Replace the generic p06 'Three Paths' narration with the selected insert, subject to visual review of that shared panel; do not narrate all three alternatives as accomplished events. Common p01–p05 and p07 remain shared unless completed events require a variant. For absent or conflicting flags, use neutral caption/music fallback, log the inconsistency and allow completion; never randomly choose an ending. No new ending illustrations are authorized for this work.

## Integration after approval

Extend existing CutsceneDirector, CutsceneRegistry validation and AudioDirector with an optional narration track. Do not create a replacement director or hard-code authored text in GDScript. Use EventBus and existing story state interfaces. Keep separate reviewable `audio/narration/` assets, source metadata and a continuation branch; final PR stays draft and unmerged.

- One offline voice clip per panel/branch, imported as OGG with measured duration and exact subtitle cues; retain source masters under existing asset/LFS rules. Document provider, voice/model IDs, actual settings, rights/review state and SHA-256. Register audio through existing manifest tooling.
- AudioDirector owns voice bus, ducking, subtitle lifecycle and pause position. Reuse its existing dialogue duck behavior through a supported narration API; CutsceneDirector must not call its private internals. Existing score cue choices remain as above until a separate owner decision.
- Drive subtitle cues from voice playback position, adjusted for audio latency; pause voice and cue clock together. Match the text actually spoken. Keep captions visible when narration is off, even if spoken-subtitle preference is off.
- Expose pause/resume, skip, replay and persisted narration on/off setting. Esc retains skip; use a distinct pause action. Replay works in campaign as well as preview and cannot mutate story progress or duplicate clinical/evidence events.
- On a healthy clip, hold its panel until audio finishes plus 0.5 seconds, then transition. Missing/unloadable clip: show caption and use max(existing duration, caption word count / 130 * 60 + 0.5). Watchdog: measured voice length + 5 seconds of ACTIVE time (pause excluded); on stall stop voice, finish remaining readable caption time, then continue. Bound invalid duration with a 120-second per-panel recovery ceiling, show a recoverable error, and allow skip. Update the director's total watchdog so normal narration cannot trigger it.
- All exits (skip, completion, load, error, replay, tree exit) stop owned voice, clear subtitles, release ducking and restore previous soundtrack context/input/mouse state exactly once. Keep reduced-motion panels static and transitions accessible. Do not reset user bus volumes as a substitute for releasing ducking.
- Preserve the existing safe load behavior (`_on_game_loaded` interrupts the overlay). Persist narration preference, chapter completion/ending state and any added mutable recap checkpoint via existing save providers; explicitly define whether resume restarts the current panel. Never replay gameplay completion side effects.

## Required evidence before final ZIP

Run existing automated tests unchanged plus meaningful narration regressions: all 36 panels and three ending variants, disabled/missing voice fallback, panel finish waits, paused watchdog, skip at every panel, replay during/after playback, toggle mid-clip, audio restoration after every exit, load during playback, legacy saves, reduced motion, subtitle clock synchronization and next-chapter gating. Verify all 36 original art hashes after integration and after ZIP extraction. Perform audible mix/pacing and Forward+/Metal character/scene checks on the owner's Mac. Headless checks alone cannot establish realistic appearance or a good audio mix.

Final delivery must contain the integrated project/patch, full chapter voice assets including A/B/C, timed captions, source attribution, exact placement/trigger guide and executed test results. This review archive intentionally does not claim that final milestone.
