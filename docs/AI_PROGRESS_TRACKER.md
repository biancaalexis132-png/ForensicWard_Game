# AI progress tracker

Task-level view of the foundation work, required by the session continuity protocol in `CLAUDE.md`. Per-system status and evidence live in `docs/PROJECT_STATUS.md`; per-session detail lives in `docs/AI_HANDOFF.md` (shared with Codex) and `docs/AI_SESSION_HANDOFF.md`. Update this table when a task changes state.

**Last updated:** 2026-10-17 21:20 UTC by Claude Code, on `claude/f3-anomaly-model` (based on `main` at `9558c77`).

## Completed

| Task | Merged | Validation | Paths |
|---|---|---|---|
| F0 foundation audit and five-chapter architecture | PR #20 | Docs only; owner approved | `docs/F0_FOUNDATION_AUDIT.md` |
| F1 campaign contract, chapter-scoped story state, save v2 | PR #21 | CI green; 97 tests | `data/campaign.json`, `scripts/content/*`, `scripts/narrative/*`, `scripts/tests/test_campaign.gd` |
| F2 zones, ZoneDirector, transitions, save v3 | PR #26 | CI green; 112 tests | `data/zones.json`, `scripts/world/ZoneDirector.gd`, `scripts/tests/test_zones.gd` |

## In progress

| Task | Branch | Depends on | Validation | Next action |
|---|---|---|---|---|
| F3 anomaly evidence model and clinical/supernatural separation, flag off | `claude/f3-anomaly-model` | F1, F2 (merged); owner's Psychosomatic Bleed answer before merge | Not yet run | Build `data/anomalies.json`, `AnomalyLedger`, validator rules, `test_anomaly.gd` |

## Blocked

| Task | Blocked on | Who |
|---|---|---|
| F3 merge | Psychosomatic Bleed decision (F0 C6); F3 is built on "presentation only" | Owner |
| Pharmacology clue gates in gameplay | F0 C7: remove or move to story | Owner |
| Chapter 2–5 content, Mara Ellis | Narrative and clinical approval | Owner |
| Concordance thread, chapter titles, player title, staff roles | F0 C2, C3, C4 | Owner |

## Pending (not started)

| Task | Depends on | Paths |
|---|---|---|
| Arrival markers in the `.blend` files to replace placeholder arrivals | Environment workstream | `data/zones.json`, `tools/blender/*` |
| Security and research ambience | Audio workstream | `audio/cues.json` |
| Ward Zero environment (Stage 6), exterior (Stage 7), textures (Stage 8) | Environment workstream | `docs/ENVIRONMENT_STAGES.md` |
| `.gdignore` for `assets/creative_references/` (keeps 42 MB of references out of imports and exports) | Owner's go-ahead | `assets/creative_references/` |
| Mac checks: zone transition feel, streaming hitch, `perf_log` figures | Owner's Mac | `docs/PROJECT_STATUS.md` "Untested on hardware" |
