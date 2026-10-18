# Explicit Naomi v06 review selection

Branch: `codex/naomi-v06-review-preview`, from main `c09eb35` (merged audit PR #64).
Implementation: `ca8b689` (resolve full tip with `git ls-remote origin refs/heads/codex/naomi-v06-review-preview`).
The owner confirmed that the other agent sessions have stopped before these
previously claimed preview/test files were edited. This branch is independent
of source-validation draft PR #65; no asset/controller/clinical content changed.

The existing CharacterVisualPreview now accepts two explicit requests:

- `-- --character-preview=staff_bennett:v06`: ten stable shapes, no visemes.
- `-- --character-preview=staff_bennett:v06_mpfb`: 32 shapes including 22 visemes.

No preview flag still gives the capsule, and the unversioned preview flag
still selects v05. No review candidate is approved or attached by default.
The existing face, animation, gaze, gesture and static-shadow pipeline is reused.
This exposes the morphs for review; it does not implement dialogue viseme playback.

New integration coverage attaches both real GLBs, verifies their distinct shape
inventories, existing rigs and placement. The save/load, state equivalence,
counter-facing transform, interaction marker and zone-rebuild test now exercises
MPFB v06. Existing v05 attachment/dialogue coverage is retained.

## Executed validation

On implementation `ca8b689166e69fcb4cf97aab2d621789be04ac54` (only subsequent docs
changes), full `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`
completed with exit 0: Python 6+4+5+3, pharmacology 0 failures, QA 19/0/0,
GLB 161/0, TestRunner **177/0**, boot OK, audio **336/0**, and complete Chapter 1
audio sequence (`CH1_SEQUENCE_DONE`, `All executed checks passed`).
An additional headless main-scene boot with writable scratch XDG directories,
`--quit-after 60 -- --character-preview=staff_bennett:v06_mpfb`, printed both
the explicit candidate path and `Boot OK`, exit 0. No real saves touched.
`git diff --check` passed. Source PR #65 hosted validation was observed pending;
no hosted success claimed. Preview hosted CI has not yet been observed.

## Mac commands (not executed here)

After Godot import, run normal gameplay with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --character-preview=staff_bennett:v06_mpfb
```

The existing bounded benchmark can now resolve this version:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -s res://tools/godot/measure_character_frame_time.gd --resolution 1280x720 -- --version=v06_mpfb
```

The existing 19.5-second diagnostic performance take also resolves the version:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -s res://tools/godot/capture_character_performance.gd --resolution 1280x720 --fixed-fps 30 --quit-after 900 -- --out=/tmp/naomi_v06_take --version=v06_mpfb
```

These are diagnostic review tools. Source PR #65 still identifies significant
lid-rim and hem defects, and v06 has no dialogue viseme driver. No Mac frame-time,
in-game video, visual approval or technical-readiness result is claimed here.
Next implementation task: separately integrate deterministic approximate visemes
through the existing facial/dialogue lifecycle, including pause/skip/interruption
tests, while versioning significant asset corrections in their own increment.
