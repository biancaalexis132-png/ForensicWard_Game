# Remaining build review — 2026-10-20

## Implementation update — completion candidate

`codex/environment-finish` now contains `codex/gameplay-completion` and current main's PR #110 documentation. Candidate runtime `ca8789395834ee647fda6bae4cf9246f7375232c` implements the chart-backed journal, current-floor spatial map, optional protagonist profile/save v4, Continuing Practice lifecycle and UI, Stage 7 environment candidates and an initial architectural finish pass. The original missing-build review below is a historical baseline, not a claim that those systems remain unbuilt.

Jordan is the **same patient** as provisional Chapter 1 Scene 07, as explicitly confirmed by the owner. No unimplemented earlier visit or clinical finding is added to existing saves. CP-001's exact 19 dialogue pairs and linked case material remain PENDING clinical activation; the worklist is review-only until explicit approval.

Remaining acceptance is concrete: [clinical activation packet](CP001_ACTIVATION_REVIEW.md), [presentation decisions and screenshots](PRESENTATION_APPROVAL_PACKET.md), and [target-Mac checks and collector](MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md). Full test evidence is recorded in the latest handoff/status entry when complete. Actual Mac acceptance, full-body/hands protagonist assets, Jordan voice/model, a full Stage 1–6 trim-sheet/UV rebake, and reviewed medication/laboratory simulation are not claimed by this candidate. See [implemented scope](GAMEPLAY_BUILD_REPORT.md).

## Verified scope

Reviewed GitHub main `1afd31183e7bc9c98f9df7ca85c879ec1e2ca5d1` and PR #104 head `24fc99366d161e66b7a8c6b73efe1734a4c00d55`. The Mac QA branch exists at `057c1f50ae3b1ca1fa0d56d65135d5bb36161410`; PR #103 was merged into main at `477fed42c15cbd813f3ae6378224d0b8e358fa65`. At initial inspection, PR #104 was the only open PR returned by the connected repository search. Historical status tables retain obsolete “not merged” and “planned” entries; current GitHub history takes precedence.

Main already contains playable Chapters 1–5 and endings, title cards, static illustrated recaps with all 38 narrator tracks, seven normal-gameplay cast models, counter interaction, dialogue-viseme support, and the player-experience work from merged PRs #102/#105–108 (voiced choices, EHR orders, objectives, title/settings/preload, presentation states). These are not missing builds. Naomi v07 supersedes the older v06 candidates; plain v06's absent visemes remain a correct historical finding, not a reason to rebuild the current model.

## Priority and next concrete deliverables

| Priority | Remaining work | Completion evidence / source |
|---|---|---|
| 1 | Finish PR #104's functional foundation | Autoload parses; notes survive real JSON saves; both panels open from the pause menu, block movement, release the mouse, pause the clock, close with Escape, and reuse their instance. Continuation provides regression tests. |
| 2 | Make the case journal part of real clinical play | Current `add_clinical_entry` has no production callers. Decide which existing documentation actions create entries and whether entries are authored, player-written, or a view of existing EHR notes. Then add event IDs/deduplication and tests for repeated events/save-load. Preserve EHR ownership and separation from EvidenceBoard; do not invent clinical notes or duplicate medical state. PR #104 is scaffolding, not a complete clinical documentation loop. |
| 3 | Build a real spatial map if required | The current map is a text directory for the clinical wing. It has no floor plan, player marker, zone-aware filtering, route guidance or access-state display. Use existing zone/world data and preserve reveal/access gates; do not expose Ward Zero or other restricted floors early. |
| 4 | Complete Mac acceptance and fix measured failures | Use `docs/MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md` on current main (its old top-stack branch instruction is stale after #108 merged). Check Forward+/Metal appearance, models/acting/visemes, voiced turn order, mix/subtitles, controls and Cmd-Tab recovery, objective save/load, recap return, zone hitches, memory on 8 GB hardware and p95 frame time. Asset import and headless tests do not establish these. |
| 5 | Review new presentation/wording and enable approved pieces | Prologue and split-screen milestone are implemented but review-only. Follow their preview steps; enable only after owner approval. The newer Kokoro profiles, interview/narration additions, replacement return text, order catalog wording and title-background usage have separate review items in `docs/handoffs/2026-10-20_claude_player_experience.md`. Earlier campaign/cast approvals do not imply approval of later additions. |
| 6 | Environment production and polish | Stage 7 apartment/parking/exterior is not started. Stage 8 textures/UVs, trim sheets, LODs/lightmap UV2 and visual polish is not started per `docs/ENVIRONMENT_STAGES.md`; Stages 1–6 are predominantly untextured v1. Select scope and target-device budgets before generating more assets. |
| 7 | Protagonist customization | `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md` remains a proposal. No creator/profile provider, background/appearance catalog, personality callbacks or proposed v4 migration ships. Review that design before implementation. |
| 8 | Continuing Practice / CP-001 | The Jordan Vale v2 authoring package exists; a runtime case schema/validator/loader, longitudinal shift lifecycle, reviewed case rules and save integration are still required. Keep its clinical/canon review separate from the main campaign. |
| 9 | Broader medical simulation scope | The EHR currently supports assessment/referral only. Medication orders and laboratory tests are explicitly unavailable in `data/order_catalog.json`; results and treatment outcomes require reviewed rules and implementation if they are part of the intended release. Preserve these honest limits until that work exists. Current content loading also reports the two PT-001/PT-002 pharmacology clue gates as known F0 C7 exceptions; that owner decision remains open. |
| 10 | Release packaging | Produce a tested Mac export and source/sync bundle with required assets/LFS objects and provenance. Verify it on the target Mac and verify external-drive sync separately. This cloud session has no mounted SSK drive and makes no claim of syncing it. |

Recommended next implementation after #104: settle the journal's EHR relationship and connect one approved clinical documentation action end-to-end, including persistence and duplicate-event handling. Run Mac acceptance in parallel with that decision; it may reveal higher-priority presentation defects.

## PR #104 findings

- Reproduced Godot import failure: `Class "CaseJournal" hides an autoload singleton.` Remove the conflicting global class declaration while retaining the autoload name.
- Journal script referenced `VBox/Entries` and `VBox/Details`; the scene nests both under `HBox`. Correct the paths and provide a scroll container for entries.
- Lazy panels were absent from Main's `_panels`, so input mode and Escape ignored them. Register each new instance in the existing panel lifecycle.
- No normal gameplay UI requested either panel. Add pause-menu access without changing existing EvidenceBoard/EHR bindings.
- Save deserialization assigned an untyped JSON array to `Array[Dictionary]`. Rebuild typed storage entry by entry; verify through SaveManager's actual JSON round trip.
- Nested tags were caller-owned through a shallow copy. Deep-copy them to protect journal state.
- Directory prose was hard-coded and claimed I opened EHR; move it to validated-at-load JSON and show the real J binding.

No clinical content, models, audio, existing authored campaign lines, or save version was changed by these repairs. The directory remains deliberately labelled and described as a directory, not a spatial map.

## Repair delivery

PR #109 (`codex/chapter1-vertical-slice-cont-1`) was merged externally at `6cf4656e5bc868b3b3419f82210860e134f6d78a` and includes #104 and its repairs, plus current-main integration and isolated test cleanup at `ed43cefff6e3a12c0de0b3dd81e7fa727b649de1`. Its diff excluded already merged player-experience work. Original #104 was subsequently closed/merged; its commit is an ancestor of #109 and its branch was not rewritten. New gameplay panel buttons are hidden from title-screen Settings. Four focused regressions pass. Full standard QA results are recorded in the newest AI handoff entry. No merge was performed by the agent, and no external-drive operation was performed. Final validation/review documentation was pushed after #109 merged and is delivered in a documentation-only follow-up.
