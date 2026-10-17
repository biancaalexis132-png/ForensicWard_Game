# Chapter 1 opening: approved direction and phased alignment

**Creative direction approved by the owner in this Codex session, 2026-10-17; implementation changes below are proposals.** No existing Chapter 1 scene, dialogue, clinical rule, beat ID, timing or save schema is changed by this document.

## Approved opening contract

The opening is primarily an engaging, realistic psychiatric hospital drama. Sequence: normal arrival and psychiatrist onboarding at Ashcroft → Bennett’s realistic ward orientation/morning handoff → a substantial Elias evaluation (EHR preparation, interview, MSE, formulation, documentation) → a small objectively observable documentation discrepancy with plausible administrative explanations → a subtle inconsistency in older infrastructure/service access.

Hospital routine, authentic professional interactions, nuanced patients and environmental realism carry the first **20–25 minutes**. No immediate supernatural reveal, frightening patient stereotypes, jump scares, apparitions or persistent ominous score. The supernatural emerges gradually. Personality arises through choices while essential clinical competence and mandatory story access remain equivalent across protagonist backgrounds.

This approves tone and structure, not a Chapter 1 rewrite, new clinical content or a full F3 implementation. The separate Elias encounter summary remains a screenplay draft pending clinical review; see [ELIAS_EVALUATION_DRAFT_COMPARISON.md](ELIAS_EVALUATION_DRAFT_COMPARISON.md).

## Verified current baseline

Compared against main after PR #29 (`dd247be`) and the unchanged runtime on the P1 continuation. PR #27’s soundtrack changes are separately resolved/pushed at `412b5010c8ccd8ba0e19e983b4346b5d90482d34`; do not silently treat them as merged into this baseline.

| Approved sequence | Existing implementation | Gap / proposed change |
|---|---|---|
| Normal arrival and onboarding | `Main.tscn` places player at `MARK_PlayerSpawn` in the clinical wing; Voss is in the office; `data/staff.json` has a placeholder greeting. `docs/CHAPTER1_PLAYABLE.md` places spawn near the W0-B door | No substantial arrival/onboarding sequence. Review an ordinary arrival route and Voss orientation using existing scenes/markers before adding exterior geometry. Coordinate any spawn/scene edits with environment owner |
| Bennett orientation and morning handoff | First objective `obj_meet_bennett`; interaction fires `beat_b2_handover` and `ch1_bennett_handover`; badge grant and three Bennett handoff lines already work | Expand reviewed routine/orientation content without replacing IDs or granting extra clinical/narrative privileges. New wording gets new voice line IDs and transcript parity |
| Substantial Elias evaluation | `pt_elias_ward`; two clinical questions plus an immediate Ward Zero question; `assessment` contains a placeholder. EHR has Summary/Observations/Notes/Orders/Audit; notes cite findings/differentials/free-text plan | No complete structured motor/medical exam, MSE/formulation workflow or risk documentation. Extend existing UI/content in reviewed increments; never turn silence into refusal or a normal risk finding |
| Objective administrative discrepancy | Transfer summary, 1968 roster and access-log clues; EvidenceManager and manual hypothesis linking already work; clue provenance retained | Stage one small discrepancy after sufficient routine/clinical context, retaining plausible administrative explanations and redundant routes. Do not imply medical symptoms corroborate it |
| Subtle older infrastructure inconsistency | W0-B panel is already in the starting wing; shutter world-state group and after-hours beats exist | Early access-log acquisition can trigger unease immediately. Review a gentle service/infrastructure cue after the routine sequence; do not create new anomaly mechanics or patient-linked effects |

### Confirmed early-unease mismatch

`data/story_chapter1.json` `beat_b6_unease` has only `clue_acquired: clue_access` as its condition. Its actions emit `ch1_w0b_unease` (mapped to `mus_transition_unease`) and close `interviewA_observation_shutter`. `data/world_chapter1.json` places `clue_access` on `W0B_AccessPanel` without a late-shift prerequisite. The interview also exposes `ask_ward_zero` in the initial state.

A temporary isolated headless probe instantiated the real Main, subscribed to `narrative_event_fired`, then called the public `EvidenceManager.acquire_clue("clue_access", "probe:W0B_AccessPanel")`. Output: **day shift, zero Elias observations and zero notes; `ch1_w0b_unease` emitted and `beat_b6_unease` fired**. The final probe exited 0 without script/resource errors after deferred teardown. This confirms event-gating behavior, not a manual walk-through or subjective audio judgement. Source inspection and existing world tests establish the terminal’s mapping; no gameplay file was altered by the probe.

Propose, for review, retaining the clue as canonical evidence while preventing the unease presentation from firing before its intended late-shift context (e.g. require the existing `intercom_heard` fact). Do not change `clue_access`, `pt_elias_ward`, `beat_b6_unease` or the night intercom’s identity/timing. Review any replacement early service cue separately; an illustrative maintenance/document inconsistency is not approved authored canon.

### Preserve late-shift timing

`beat_b6_intercom` already requires day 1 + night shift, then delays **15 in-game minutes**. It plays `ch1_after_hours_intercom`, appends the inactive-credential transfer-request audit entry, notifies the player and sets `intercom_heard`. Keep that scheduling, pending queue and save/load dedupe unchanged. A request in an audit log is not a physical transfer of Elias or a clinical finding. Existing tests must keep proving safe location invariants and no duplicate beats after migration/reload.

### Music and appearance

Current main assigns exploration music to day corridor/nursing station. PR #27 moves it to the records archive and keeps handover/clinical areas without foreground score; Ward Zero music needs explicit events. Review/listen to the resulting ordinary-hospital mix before further cue edits; do not duplicate the audio workstream or assume a track is ominous from its file name. Early-trigger suppression is a narrative review issue even when a stinger has an accessibility reduction.

Existing gameplay characters are stand-ins, not the legacy concept portraits. Corrected reference sheets do not replace scene characters automatically. Patient visual stereotypes are explicitly prohibited, but no claim is made that a discarded concept face currently appears in-game.

## Proposed small PR sequence

| Phase | Scope | Acceptance / dependency |
|---|---|---|
| O0 (this document) | Record approved direction and exact gaps, preserve IDs/timing, coordinate ownership | No scene/content changes; owner reviews implementation slices |
| O1 | Ordinary arrival/Voss onboarding and Bennett orientation, reusing current systems | Reviewed staff text; stable controls; no early mystery reveal; scene/spawn changes agreed with environment owner |
| O2 | Elias EHR preparation, interview attempts and reviewed exam/MSE/formulation/documentation content | Clinical approval matrix in comparison document; unknown/not assessed distinct from normal; no new prescribing logic |
| O3 | Stage the small documentation discrepancy with an ordinary explanation still credible | Canonical provenance/manual comparison; essential route available for all backgrounds; no unsafe-care neglect requirement |
| O4 | Review early W0-B question/unease gating and a subtle service-infrastructure cue | Daytime routine cannot fire horror presentation; preserve existing night + 15-minute event and save dedupe; no full F3 or disputed Bleed behavior |
| O5 | Tune pacing, sound and visual presentation on the owner’s Mac | Complete first-session playtest; first 20–25 minutes carried by hospital drama, no jump scare/continuous ominous score; accessibility and performance checks |

Provisional playtest windows might be arrival 0–3, orientation 3–7, evaluation 7–20, discrepancy 20–23, infrastructure 23–25 minutes. These are authoring/playtest targets, **not mandatory waiting periods**, new TimeManager values or a promise that all players take the same time. Preserve pause policies and allow different reading speeds, accessibility settings and appropriate clinical escalation.

## Required checks and open gates

Add reviewed regressions for early clue pickup without unease, no Ward Zero reveal during initial clinical interview, same essential options/evidence across all backgrounds, explicit unknown risk/MSE entries, night intercom at its original offset, and save/reload without duplicate audit/beat entries. Run standard QA and world/campaign/zone regressions for any implementation. Listen and play through on Mac; headless tests do not establish dramatic pacing, clinical correctness, input feel, lighting or mix.

Owner review is still required for new clinical wording/findings, detailed screenplay lines, added staff/arrival dialogue and any newly authored discrepancy/environment cue. F0 Bleed/pharmacology-gate decisions and D4–D9 remain open. This proposal does not authorize structural rework, new medical rules, later-chapter anomaly canon or Stage 6 geometry changes.

## Repository update after comparison

The owner subsequently merged PR #27 at `6d2dd2d`; it is incorporated in the final development branch. The soundtrack alignment described above is now on main, including no foreground score under corridor/handover clinical work and the bounded audio cleanup test. The opening narrative trigger/dialogue gaps identified above remain unchanged; no proposed chapter edit is implemented here.

## Screenplay availability correction — 2026-10-17

Owner merged the full 11-file draft package in PR #30 (`052859a`). Earlier statements that the full screenplay was unavailable describe the earlier checkpoint. The complete review, including conditional examination findings, late-shift preservation and chapter dependencies, is now in [FIVE_CHAPTER_SCREENPLAY_CONTINUITY_AUDIT.md](FIVE_CHAPTER_SCREENPLAY_CONTINUITY_AUDIT.md). No clinical or dialogue approval is inferred from the package merge.
