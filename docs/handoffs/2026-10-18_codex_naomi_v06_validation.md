# Naomi v06 validation — Codex, 2026-10-18

## Continuation: source gate resolved

Draft source-continuation PR: https://github.com/biancaalexis132-png/ForensicWard_Game/pull/65.
Checkpoint `e75064907ef8588a8c497803a0a2725e0d339b77` pushed and verified on
`codex/naomi-v06-validation-cont-1`; this documentation-link checkpoint follows.

Official bpy **5.2.2 LTS** under Python 3.13 now opens both original sources.
Implementation `0d6e36989019a7dea4d59484b6b514ca8caafaca` is pushed and verified.
`tools/character_animation/audit_naomi_source.py` inspects material dependencies,
decodes all ten packed images per file, checks source skin groups and morphs,
and evaluates nine meshes at five frames for each of ten actions. Every clip
has sampled pose motion and finite evaluated geometry. Both source SHA-256s
are unchanged. There are no missing external material-image or library paths.
Plain v06 still lacks 22 visemes; MPFB has 32 morphs. Body (5,194 vertices) and
hair cap (287) have unnormalized source weight sums in both files, but no zero,
negative or nonfinite influences; the independently validated GLBs normalize
them correctly. Keep export normalization; do not silently alter source weights.

Four explicit Blender integration regressions pass, including disposable
missing-texture and unweighted-mesh rejection. The normal payload suite still
passes 3/0. Source summaries and four reproducible CPU Cycles stills are in
`docs/handoffs/naomi_v06_source_review/`, excluded from Godot import by .gdignore.

Source visual findings: **significant** wavy/dark closed-lid rims and jagged
trouser hems; **cosmetic** angular shoe silhouette in these views. Eyeballs are
covered at blink=1, but natural, unclipped blink acceptance is not granted.
The sampled chart pose has no obvious body tear in the render; motion, Godot
placement/gaze/shadows and Mac performance remain unverified. These are source
diagnostics, not an in-game owner-review video or visual approval.

The owner confirmed in this continuation that all other sessions have stopped;
their historical asset/face/preview claims are released for coordinated Codex
continuations. Next exact task: correct significant lid/hem defects in a new
version and expose
explicit v06_mpfb review selection. Re-run both auditors after an asset change,
then complete Mac motion/shadow/performance validation and the in-game video.
The older source-unavailable findings below describe the initial attempt only.

Branch: `codex/naomi-v06-validation`, based on fetched main
`0c104b264a985522643c60d1c059c37c24c7d881`. GitHub API confirmed PR #63
merged (head `c67a40934c4f6d2f425c9142640a823446ee021d`), no comments or
reviews; open PR list was empty. PR #62's merge is in main's ancestry.
No other agent's branch or existing runtime/controller/asset was changed.
Initial audit PR #64 merged at `c09eb35` during this continuation. The new source
audit is on `codex/naomi-v06-validation-cont-1` for a separate draft PR.
Implementation `3621ae1e679577c50009dc1f1837d2b5600b9e6e` and recovery docs
`c417f2c4f7c8d118ab577564cedf5097eb210fe7` were pushed and verified via
`git ls-remote`. A PR-link-only documentation checkpoint follows; resolve the
final tip with `git ls-remote origin refs/heads/codex/naomi-v06-validation`.
Existing face/animation/preview claims in AI_HANDOFF remain reservations;
local processes and unpushed work on the owner's Mac are not observable here.

## Executed asset findings

The new Python auditor reads GLB binary accessors, including sparse morphs,
embedded image signatures, animation samples and exported skin weights.
The standalone Godot 4.7 probe loads both actual imported scenes and sets and
resets every available expected shape. Both probes fail deliberately on the
incomplete plain v06; this is a product finding, not a skipped test.

| Asset | Embedded images | Clips | Morphs | Skin weights/joint indices |
|---|---:|---:|---:|---|
| `Naomi_Bennett_v06.glb` | 10 | 10 | 10 stable; **0 visemes** | valid |
| `Naomi_Bennett_v06_mpfb.glb` | 10 | 10 | 10 stable + 22 visemes | valid |

All ten expected clip names exist in each payload. MPFB non-silence shapes
have nonzero finite position offsets; silence remains neutral. Weight sums
are within 0.002 of one, nonnegative, with joint indices inside the skin.
All image records in these files are embedded, with valid image signatures;
there are no external GLB image paths to go missing. Standard Godot import
completed without decode errors. This does not prove Blender images load.
The auditor's hashes identify the exact binaries; JSON evidence is saved next
to this handoff as `2026-10-18_codex_naomi_v06_payload_report.json`.

In the initial attempt, both actual Blender files were inspected and decompressed read-only into
scratch. They have Zstandard framing and a `BLENDER17-01` decompressed header.
Installed Blender 4.3.2 refuses them: `incomplete header, may be from a newer
version of Blender`. Opening the decompressed MPFB copy gives the same error.
Source images, material paths, actions and deformations were then unvalidated.
This obstacle was resolved in the continuation above; no sources were saved
with either Blender version. It was not evidence of corruption.

## Acceptance issues

| Severity | Finding / unresolved gate | Required next action |
|---|---|---|
| Blocking | Plain v06 lacks all 22 advertised visemes | Agree which candidate is authoritative; retain both versions and select MPFB explicitly for review |
| Blocking | No runtime viseme driver found in scripts/systems; CharacterFaceRig drives mouth_open only | Resolve face-controller ownership before a separate dialogue integration increment |
| Significant | Source body/hair-cap weights need normalization | Preserve normalized GLB export; source findings now validated in matching bpy |
| Significant | Closed-lid rims and trouser hems visibly irregular in source stills | Owning asset workstream corrects these in a versioned candidate; repeat visual checks |
| Blocking | Mac frame time, complete blink closure, natural gaze, gesture clipping/shadows and nursing-station placement untested for v06 | Run bounded target-device capture/benchmark; do not claim readiness from headless checks |
| Significant | CharacterVisualPreview has no v06/v06_mpfb entry and still defaults to v05 | Existing preview owner adds explicit review-only selection in an independent increment |
| Significant | v06 rig report lists only ten shapes while combined manifest lists 32 | Regenerate candidate-specific reports from each actual final payload |
| Significant | Static shadow proxies intentionally freeze rest-pose shadows | Compare gestures with proxies on/off on Mac before accepting the optimization |
| Cosmetic | No new cosmetic defect confirmed | Full-body scrubs/footwear and close-face visual review still required |

Unknown visual outcomes are gates, not fabricated defects. Technical readiness
requires idle, breathing, listening and gestures; full unclipped blinks; face
and dialogue mouth animation; natural gaze; no major scrubs/shoe defects; no
required missing assets; and preserved dialogue, interaction, saves and cutscenes.
Measure the existing 33 ms frame-time budget on the M1 Mac with mean/p95,
draw calls, primitives and memory, including proxy comparison and historical
capsule/v04/v05/v05_mpfb baselines. No v06 Mac result was measured here.
Once those gates pass, stop cosmetic additions and present a short in-game
video for owner visual approval. Technical readiness never grants approval.

## Generated dependencies and preservation

The `.blend` files are authoring sources; GLBs are reproducible runtime exports.
Embedded textures are part of those exports. Tracked extracted PNGs and adjacent
`.import` sidecars already exist in main: keep them while investigating their
references and importer settings; this increment removes none. Sidecars encode
UIDs/settings and are not equivalent to `.godot/imported` cache. Version only
dependencies/settings needed by a clean checkout. Regeneration/deduplication
needs a separate reference audit and clean-import comparison. Ignored `.godot/`
and scratch `work/` are disposable caches/evidence, never staged wholesale.
No new large-file or LFS pattern is introduced.

## Reproduce / next exact tasks

Executed full QA: exit 0, Python 6+4+5+3, pharmacology 0 failures, QA 19/0/0,
GLB 161/0, TestRunner 176/0, boot OK, audio 336/0, complete Chapter 1 audio
sequence. New audit regressions 3/0. Probes report 22 expected acceptance
failures on plain v06 and zero payload failures on MPFB. These results do not
establish target-device appearance or performance. See AI_HANDOFF for commands,
implementation SHA and corrected sandbox/XDG startup failures.

1. `python3 tests/qa/test_naomi_v06_audit.py -v` — three real-asset regressions,
   including intentionally corrupted skin-weight rejection.
2. `python3 tools/character_animation/audit_naomi_v06.py` — exit 1 expected while
   plain v06 is incomplete; MPFB should have zero blocking payload failures.
3. With isolated writable XDG directories, run Godot 4.7:
   `--headless --path . --script tools/godot/validate_naomi_v06.gd` — exit 1,
   `NAOMI_VALIDATION_FAILURES=22`, MPFB missing list empty.
4. In matching Blender, inspect both source assets and resolve candidate naming
   with the owning workstream. Then the preview owner exposes v06_mpfb, followed
   by bounded Mac gesture/blink/gaze and proxy performance/video review.
5. Continue separate viseme integration only after ownership is clear. After
   owner-review checkpoint, prioritize Chapter 1 QA then Chapter 2 vertical slices:
   routine clinical work, Naomi handoff, records discrepancy, approved Mara
   content, saved objectives/continuity. Reuse campaign contracts; no invented
   clinical facts, Ward Zero access or early supernatural reveals.
