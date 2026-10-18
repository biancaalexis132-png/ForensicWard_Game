# Copilot handoff — CIG-1

Review latest `main`, current PRs, `AGENTS.md`, `CLAUDE.md`, `docs/PROJECT_STATUS.md`, relevant Naomi character-builder branch and current Naomi acting adapter before changing code. This package is a **planning and validator artifact**, not owner approval of a new engine architecture.

Deliver one **small, separately reviewable** proof-of-integration PR after Naomi's model and asset license are available. Proposed changes:
- additive visual slot on WardCharacter;
- per-ID asset registry with placeholder fallback;
- isolated test scene and regression coverage;
- model import checks and documented performance measurement;
- *no* breaking changes to story/clinical/audio contracts.

Avoid simultaneous edits to the active Naomi 3D model builder, Voss, Elias, Rahman, Marcus or Mara production branches. Coordinate shared rig/export changes through separate review.

Important: `scripts/world/Character.gd` currently scales `$Body/Mesh` nonuniformly when `seated`; do NOT apply this scale to a humanoid imported rig. Keep named node paths needed by existing code, retaining static and interaction colliders. Confirm rig, facial targets and imported scene names rather than inventing them.

Validation reports must distinguish: Python GLB preflight, Godot 4.7 import/runtime, full QA suite, and owner's Mac visual/performance check. Don't claim completion based on one of these alone.

Commit/push handoff documents before usage limits. No automatic merge or unapproved clinical gameplay changes.
