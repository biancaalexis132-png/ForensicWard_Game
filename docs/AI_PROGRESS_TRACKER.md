# AI progress tracker

Task-level view of the foundation work, required by the session continuity protocol in `CLAUDE.md`. Per-system status and evidence live in `docs/PROJECT_STATUS.md`; per-session detail lives in `docs/AI_HANDOFF.md` (shared with Codex) and `docs/AI_SESSION_HANDOFF.md`. Update this table when a task changes state.

**Last updated:** 2026-10-18 01:40 UTC by Claude Code, on `claude/f3-anomaly-model` (based on `main` at `9558c77`).

## Completed

| Task | Merged | Validation | Paths |
|---|---|---|---|
| F0 foundation audit and five-chapter architecture | PR #20 | Docs only; owner approved | `docs/F0_FOUNDATION_AUDIT.md` |
| F1 campaign contract, chapter-scoped story state, save v2 | PR #21 | CI green; 97 tests | `data/campaign.json`, `scripts/content/*`, `scripts/narrative/*`, `scripts/tests/test_campaign.gd` |
| F2 zones, ZoneDirector, transitions, save v3 | PR #26 | CI green; 112 tests | `data/zones.json`, `scripts/world/ZoneDirector.gd`, `scripts/tests/test_zones.gd` |

## In progress

| Task | Branch | Depends on | Validation | Next action |
|---|---|---|---|---|
| F3 anomaly evidence model and clinical/supernatural separation, flag off | `claude/f3-anomaly-model` (draft PR) | F1, F2 (merged); Bleed answered: presentation only | 127 tests pass; QA green; CI pending | Owner review; fix CI if red |

## Blocked

| Task | Blocked on | Who |
|---|---|---|
| F3 merge | Owner review of the draft PR | Owner |
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
