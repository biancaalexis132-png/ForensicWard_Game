# Copilot continuation — Naomi acting cue fixture

This package can be added as a documentation/data-only PR **independently** of the active 3D model builder branch.

1. Confirm `data/narrative/chapter1.json` and `audio/voice/voice_lines.json` still contain the five stable beat-2 dialogue IDs.
2. Run the bundled Python validator from the repository root.
3. Review existing `Ch1AudioSequence.gd`, `DialogueManager`, and `WardCharacter` APIs. Present an additive event-flow design before editing runtime code.
4. When approved, write a presentation-only Godot adapter accepting cue dictionaries with animation fallback, not a parallel dialogue director. It must not modify clinical/decision/save state.
5. Add negative and lifecycle tests; verify on Godot 4.7. Preserve source dialogue as `PENDING` clinical review.
6. Work on a separate branch. No auto-merge. Update and push mandatory AI handoff checkpoints before context exhaustion.
