# Godot 4.7 implementation roadmap (proposed; not implemented)

## Small PR sequence
- G0: audit latest main, handoffs and active Naomi builder branch; run tests; record current Chapter 1 vertical-slice baseline.
- G1: Hospital Life H1: deterministic, low-frequency ambient work loops for existing WardCharacter, pause/resume, no extra moving patients; existing walla only.
- G2: Naomi builder integration after approved mesh/rig/GLB license and preview: replacement visual child, preserve existing staff ID, collider/interaction/voice events.
- G3: Chapter 1 EHR provenance and note usability; never modify clinical validation rules from narrative.
- G4: Elias E1/E2 observation recording, interrupted assessment, safe escalation and no invented patient records.
- G5: Chapter 2 record/custody content and Mara independent encounter with verified dossier; separate clinical and investigation state.
- G6: Chapter 3 inspection safe-return and rollback tests *before* any entry scene effects. No corridor loop.
- G7: Evidence independence ledger and Chapter 4 replay/safety gates, then Scene 09 controlled reveal.
- G8: Coordinated save schema migration (only after plan approval), Chapter 5 review lifecycle and A/B/C operation-specific endings.
- G9: integration/asset QA, accessibility, 8GB Apple Silicon profiling, credits/licenses, editorial and clinical review sign-offs.

## Acceptance matrix
- Every scene loads or safely skips optional audiovisual asset; missing voice, animation or ambience never blocks progression.
- Chapter 1 existing dialogue IDs unchanged and pending reviews respected. `walla` cannot generate observations.
- No clinical state changes when environmental clues unlock, including replay and save/load.
- Every restricted doorway has an authorized traversal contract, no navigation path crosses sealed entrances.
- NPC ambient loops stop on conversation, zone unload and pause; no duplicate timers on save/load.
- Source dependency graph rejects direct and transitive copies, shared clocks and derived files as independent.
- First corridor loop event only Chapter 4 Scene 09, with provenance predicate satisfied.
- Every ending reachable with all legal protagonist/background profiles and relationships, and completion occurs exactly once.
- Automated Godot and Python test results recorded separately; do not claim Godot tests passed if Godot unavailable.
- 8 GB RAM Mac rendering acceptance is measured, with reduced texture and animation LOD as necessary.

## Branching policy and handoff
Dedicated documentation PR for this package; no direct merge. Every implementation branch reads `AGENTS.md`, `CLAUDE.md`, `docs/PROJECT_STATUS.md`, `docs/AI_HANDOFF.md`, `docs/AI_SESSION_HANDOFF.md` where present. Write/push verified commits and continuity docs regularly, before session limits. Do not stage AppleDouble `._*` files on exFAT. Verify published SHA and check actual assets before claiming integration.
