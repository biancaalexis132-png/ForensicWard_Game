# Dialogue viseme integration

Branch `codex/dialogue-viseme-integration`, based on main `8a86d53` (source
validation PR #65 merged). Preview PR #66 is independent; these tests attach
the existing GLB through WardCharacter without requiring that PR.
PR #66 subsequently merged at `996fd9a`; it is integrated by merge checkpoint
`d56c1c319855ceaeea19c9fb3c3f3539659136e0`, pushed and verified.

## Owner decision

On 2026-10-18 the owner said: **"continue i approve of the animations so far"**.
Record this as approval of animations shown so far. It does not assert approval
of the newly added viseme approximation, complete model geometry/likeness,
cutscene placement, or unmeasured Mac frame times. The owner previously
confirmed all other agent sessions stopped; face-controller ownership was
checked and no other implementation found before editing.

## Implementation

`DialogueVisemeTrack.gd` makes a deterministic grapheme-based approximation
over the existing subtitle/voice duration. No phoneme timing exists in the
current audio/data sources; this is **not true lip sync**. Punctuation produces
quiet slots; weights stay at or below 0.6. No inference or new content assets.

The existing `CharacterFaceRig` consumes subtitle and line-finished events,
matches the canonical speaker ID to its WardCharacter ancestor, and owns the
mouth clock. Scene pause freezes it. Completion, skip/interruption, replacement,
duration exhaustion and game load clear mouth shapes. Late completion of a
different old line is ignored. Cues can still gate speech, and manual capture
speech retains its old jaw fallback. Models without a selected viseme use
mouth_open; supported visemes do not stack with jaw opening. Expressions,
blinking, gaze, body/gesture playback and static shadow proxies stay separate.
Zero-valued visemes are not rewritten every frame.

Ten new real-model regressions cover deterministic schedules, actual audio
events, fallback, different shapes, expression/proxy preservation, stale
completion, skip/load, duration/punctuation, actor filtering, voiced/unvoiced
pause and scene gaps. Two existing AudioDirector timers (subtitle-only reading
duration and between-line gap) now pause with the scene. A regression first
failed on the original unvoiced timer, proving the real lifecycle edge case.
The original 176 tests passed at the branch baseline; the integrated preview
plus original eight viseme tests passed 185/0 before the two added pause checks.
An earlier pause-fixture failure was traced to a queued old test actor's
exit hook stopping newly started audio. The pause fixture now flushes queued
scene cleanup before starting audio; no production pause behavior was weakened.

## Diagnostic tool

`tools/godot/review_dialogue_visemes.gd` attaches v06_mpfb to the existing
nursing-station actor and plays the existing first Naomi line for a bounded
eight-second take. It is never invoked by normal gameplay. A manual invocation:

```sh
godot --path . -s res://tools/godot/review_dialogue_visemes.gd
```

An eight-second take is followed by bounded audio teardown. Optional engine
`--write-movie take.avi --fixed-fps 30 --quit-after 360` captures a diagnostic.
Linux Compatibility/llvmpipe
footage is not Mac Forward+/Metal appearance/performance evidence and does not
establish technical readiness. No new default character or cutscene was set.

## Remaining gates / next task

## Executed final validation / recovery

- Runtime implementation `44b2ff5418b027868ec562d8d98569ad06d909b2` pushed and
  confirmed via git ls-remote. A recovery/tool-viewport checkpoint follows.
- `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`:
  exit 0, Python 6+4+5+3, pharmacology 0 failures, QA 19/0/0, GLBs 161/0,
  TestRunner **187/0**, boot OK, audio **336/0**, `CH1_SEQUENCE_DONE`, and
  `All executed checks passed`. Logs: scratch `work/qa-visemes-final.log`.
- Final helper (respects project/caller viewport) with isolated writable XDG
  directories and `timeout 25s Godot --headless --path . -s res://tools/godot/review_dialogue_visemes.gd`:
  exit 0, `VISEME_REVIEW_DONE`, no engine errors/leak warnings. This is normal
  real-time mode, not accelerated headless fixed-fps without movie audio.
- Visually inspected differing mouth poses from the included 2.5-second Linux
  Godot excerpt. H.264/AAC, 640×480, 30fps, ffprobe duration 2.500000. Source
  project/assets unchanged. This is a diagnostic, not the final Mac review.
- `git diff --check` passed. Hosted CI not yet observed. No failed runtime tests,
  disabled tests, new clinical content, source asset edits or generated import
  file cleanup. Blender validation was not repeated on unchanged assets.

## Next exact task

Run the diagnostic on the target Mac, check natural speaking/blinking/gaze and
gestures, compare static shadow behavior and the 33 ms budget using existing
bounded tools. Source lid/hem issues remain tracked. Once technical gates pass,
present a short in-game video for the owner decision, stop cosmetic additions,
and prioritize Chapter 1 QA then canonical Chapter 2 gameplay vertical slices.
No clinical dialogue, findings or supernatural reveals changed in this increment.
