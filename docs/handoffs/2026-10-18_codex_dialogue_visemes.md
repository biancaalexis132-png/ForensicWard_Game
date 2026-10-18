# Dialogue viseme integration

Branch `codex/dialogue-viseme-integration`, based on main `8a86d53` (source
validation PR #65 merged). Preview PR #66 is independent; these tests attach
the existing GLB through WardCharacter without requiring that PR.

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

Eight new real-model regressions cover deterministic schedules, actual audio
events, fallback, different shapes, expression/proxy preservation, stale
completion, skip/load, duration/punctuation, actor filtering and scene pause.
The original 176 tests passed at the branch baseline; development TestRunner
passes 184/0. The initial pause failure was traced to a queued old test actor's
exit hook stopping newly started audio. The pause fixture now flushes queued
scene cleanup before starting audio; no production pause behavior was weakened.

## Diagnostic tool

`tools/godot/review_dialogue_visemes.gd` attaches v06_mpfb to the existing
nursing-station actor and plays the existing first Naomi line for a bounded
eight-second take. It is never invoked by normal gameplay. A manual invocation:

```sh
godot --path . -s res://tools/godot/review_dialogue_visemes.gd --quit-after 300
```

Optional `--write-movie` captures a diagnostic. Linux Compatibility/llvmpipe
footage is not Mac Forward+/Metal appearance/performance evidence and does not
establish technical readiness. No new default character or cutscene was set.

## Remaining gates / next task

Run the diagnostic on the target Mac, check natural speaking/blinking/gaze and
gestures, compare static shadow behavior and the 33 ms budget using existing
bounded tools. Source lid/hem issues remain tracked. Once technical gates pass,
present a short in-game video for the owner decision, stop cosmetic additions,
and prioritize Chapter 1 QA then canonical Chapter 2 gameplay vertical slices.
No clinical dialogue, findings or supernatural reveals changed in this increment.
