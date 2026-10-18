# Copilot task — independently build Elias Ward

Start in a clean GitHub branch, e.g. `characters/elias-ward-model`. Read `AGENTS.md`, `CLAUDE.md`, latest handoffs, `data/patients.json`, `data/world_chapter1.json`, character visual review and Naomi/Voss existing model-builder pipeline. Do not overwrite any active workstream.

1. Review this brief and audit current shared Blender character pipeline. Report conflicts, candidate mesh-generation tooling and licensing before implementing.
2. Create Elias in his dedicated folder; keep model output and neutral render separate from Naomi/Voss. If the project has a reusable builder, depend on its stable documented interface only.
3. Generate editable `.blend`, Godot-importable `.glb`, front/profile/three-quarter render, usage/license manifest, rig and facial support map, poly/material/texture statistics.
4. Integrate only as a model swap under the existing `pt_elias_ward` world character marker while preserving interaction, collision, seated placement and save/load. This integration can be staged as a later PR if no approved mesh exists.
5. Validate Godot 4.7 import and existing test suite; record exactly what ran and what remains untested, especially 8GB Mac GPU performance.
6. Do not add medically significant movements, unsupported patient data, special symbols, restraints or paranormal indications. Keep all clinical review gates pending.
7. Push commits and mandatory session handoffs before context/usage limits; create a separate reviewable PR; do not merge automatically.

**Acceptance:** believable neutral patient model in Chapter 1 interview room, independently licensed/reproducible pipeline, without changes to case facts or runtime clinical rules.
