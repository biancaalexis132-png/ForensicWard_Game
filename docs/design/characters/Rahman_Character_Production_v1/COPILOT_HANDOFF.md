# Copilot: Dr. Leila Rahman separate model workstream

Read `AGENTS.md`, `CLAUDE.md`, latest `docs/PROJECT_STATUS.md`, `docs/AI_SESSION_HANDOFF.md`, `docs/design/VISUAL_PRODUCTION_REVIEW.md`, `data/staff.json`, `audio/voice_profiles.json`, and this package. Treat current GitHub `main` as source of truth; update statuses from latest refs.

Owner-selected canon: Consultant Psychiatrist. The legacy `audio/voice_profiles.json` says Clinical Pharmacist and Rahman does not yet appear in `data/staff.json`. Fix those only through a small, separately reviewed canon PR with regression tests; don't silently rewrite executable content or agent branches.

Goal: Build a reproducible, game-ready, visually distinct Rahman 3D model in an independent branch while Naomi/Voss/Elias development proceeds. First inventory Naomi builder for stable reusable interfaces and verified Blender/MPFB APIs (do not assume the builder has completed). Then create Rahman-only Blender build assets, run unattended, validate genuine outputs and Godot 4.7 imports. Keep skin/hair/likeness customizable until owner casting approval. Capture neutral previews, provenance, and Mac performance budget.

Deliverable gate: a specification PR first if owner likeness/reference is missing; do not claim mesh/model complete until `.blend`, `.glb`, preview and validation actually exist. Do not merge automatically. Commit/push session handoffs before usage or context limits interrupt.
