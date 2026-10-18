# Independent Blender workstreams and integration gates

1. Read `AGENTS.md`, `CLAUDE.md`, `docs/PROJECT_STATUS.md`, `docs/AI_HANDOFF.md`, `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`, visual production review, and latest approved character dossier.
2. Check active branches/PRs and file ownership before changing shared Blender helpers. Model creation should use independently scoped folders and new commits.
3. Builder must discover/verify installed MPFB/Blender API before importing it; don't invent addon modules or assume Blender 5.2 compatibility. Any dependency or third-party mesh requires express license provenance and commercial-use check. No scraping or unlicensed likeness reuse.
4. Output an editable .blend and one self-contained Godot-compatible glTF .glb per character, neutral turntable stills, simple rig/mesh/material report, source/license manifest, reproducible build command, and tests. Report failures honestly; don't claim outputs before generated and opened.
5. Do not connect clinical flags, risk scores, hallucinations, access grants or mystery evidence to animations. Display conditions flow from authored scene data with appropriate approval.
6. Integration branch replaces only the visual child of the existing `WardCharacter`, preserving collider, ID, dialogue, marker and fallback. Handle absent rigs/assets gracefully; preserve save compatibility.
7. Test import and regressions on Godot 4.7, then owner visually tests on 8 GB Apple Silicon Mac before merging. Handoffs updated and pushed with every checkpoint.

## Scene and role differentiation
- Hale: present as security director, professional neutral demeanor, staff access procedures distinct from physical performance.
- Mara: patient with agency and distinct independently verified record provenance; first Chapter 2 major role per campaign direction, not a Ward Zero avatar.

## Staged delivery
P0 owner chooses/approves likeness details; P1 pipeline feasibility; P2 Blender model/rig and local previews; P3 Godot import and animation adapter; P4 scene placement/voice and visual QA; P5 approved integration PR. P0/P1 may proceed now; no asset branch should be merged early.
