# AI handoff

This is where one agent tells the next exactly what it did and where to resume. Rules for writing and reading it are in `AGENTS.md` §7. Newest entry first; never edit or delete an older entry, add a correction in a new one.

A file cannot contain the SHA of the commit that adds it. So each entry records the **latest verified commit** it describes (the last commit whose contents and tests the entry vouches for). The commit that adds the entry sits on top of it; find it with `git ls-remote origin <branch>`. If the branch tip has more than that one doc commit on top of the recorded SHA, someone pushed after the entry was written: read `git log <recorded-sha>..origin/<branch>` before you trust it.

## Active workstreams

One row per branch that someone is working on. Claim the folders or files you will edit, so two agents never change the same file in parallel without a plan. Remove your row when the branch merges or is abandoned.

**GitHub state correction (verified 2026-10-18 12:54 UTC):** `origin/main` is `de5cbfcb6a269ffa48822030a06b74bb0b7d63d3`; PR #42 is merged there. PRs #43 and #44 are open against main. Older CIG snapshots and the 96ef65e current-state note below are preserved as history, not live state. Naomi v01 remains unapproved and not integrated; this feature branch now owns the procedural refinement workstream.

| Workstream | Branch | Agent / session | Latest verified commit | Claimed files | State |
|---|---|---|---|---|---|
| Naomi procedural visual refinement | `biancaalexis132-png-naomi-model-refinement` | Copilot / current session | `de5cbfcb6a269ffa48822030a06b74bb0b7d63d3` (main base; feature checkpoint to be pushed) | `tools/blender/characters/**`, Naomi-specific `.blend`/GLB/renders and asset manifests, Naomi continuity/status docs | Active audit/refinement; v01 fails visual review, v02 not generated. |

### 2026-10-18 12:55 UTC · Copilot · Naomi procedural visual refinement audit

- **Branch:** `biancaalexis132-png-naomi-model-refinement` (based on `main` at `de5cbfc`)
- **Latest verified commit:** `de5cbfcb6a269ffa48822030a06b74bb0b7d63d3` "Merge pull request #42 from biancaalexis132-png/biancaalexis132-png-cig-1-character-integration"
- **Confirmed on GitHub:** `origin/main` and local HEAD both point to `de5cbfcb6a269ffa48822030a06b74bb0b7d63d3`; new feature branch has not yet been pushed.
- **Pull request:** none for this branch. Open PRs at audit: #43 and #44.
- **State:** unfinished but coherent; audit checkpoint only, no model/code changes yet.

**Accomplished**
- Reconciled the older continuity snapshot with fetched GitHub state: PR #42 is merged in `de5cbfc`; PRs #43/#44 are open. The earlier notes calling #42 pending are historical and stale.
- Inspected the approved Naomi production spec and v01 Blender/GLB/render/provenance outputs. Generated renders show face/eyes obscured by broad hair strips, black/clipped/angular clothing regions and a skirt-like lower silhouette; v01 is unsuitable for runtime integration.
- Confirmed Blender 5.2.2 and an initialized MPFB extension are available at `/Applications/Blender.app/Contents/MacOS/blender`. Version-specific build validation remains to be run by the builder.

**Files modified**
- `docs/AI_HANDOFF.md`, `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`, `docs/PROJECT_STATUS.md`: this audit checkpoint and corrected active-workstream snapshot.

**Unfinished**
- `tools/blender/characters/build_naomi.py`: inspect and correct procedural face/hair/garment construction and preview staging; add versioned v02 outputs while preserving v01.
- `tools/blender/characters/validate_naomi.py`, configuration and Naomi asset manifests: support deterministic versioned output and explicit owner-review status.
- v02 review renders, Blender source and GLB have not yet been generated.

**Known errors**
- v01 preview visibly fails owner-review criteria as described above; no v02 build attempted yet. No software test failure is asserted at this audit checkpoint.

**Tests**
- No starting-commit tests rerun yet; changes in this checkpoint only record the audit. Historical checks for merged main are recorded below. New builder/refinement work must be validated on this branch.
- CI: not observed for this feature branch; no PR exists.

**Dependencies not available to remote agents**
- MPFB2 is an installed Blender extension, not vendored; the build must verify its loaded version and documented APIs. Owner appearance approval, Mac in-game performance review, animation and LOD remain pending.

**Next steps**
1. Push this audit checkpoint and confirm its exact remote SHA.
2. Inspect the complete builder, MPFB2 2.0.18 API/source references, validator and manifests; fix procedural occlusion, fit and silhouette without manual sculpting or unapproved canon.
3. Generate and validate versioned v02 `.blend`, `.glb`, manifest and review images, retaining v01.
4. Import the GLB in Godot 4.7, complete project QA, update handoffs with exact results, and open a draft PR without runtime integration.

**Notes for the other agent**
- Keep `staff_bennett` unmodified; do not attach the v01 or v02 asset to the runtime slot. No clinical, save, story or gameplay systems are in scope. Renders are for owner review, not proof of photorealism or Mac performance.

High-conflict files that need an agreed plan before editing: `project.godot`, `scripts/autoload/EventBus.gd`, `scenes/main/Main.*`, `tests/qa/run.py`, `.github/workflows/*`, `README.md`.

## Entry template

Copy this block to the top of the log and fill every field. Write "none" rather than leaving a field out.

```markdown
### YYYY-MM-DD HH:MM UTC · <agent> · <workstream>

- **Branch:** `<branch>` (based on `<base branch>` at `<short sha>`)
- **Latest verified commit:** `<full 40-character sha>` "<subject line>"
- **Confirmed on GitHub:** `git ls-remote origin <branch>` printed `<sha>` at <time>
- **Pull request:** #<n> (draft / ready / merged) or none
- **State:** finished / unfinished but coherent / WIP that does not import (say which file)

**Accomplished**
- <what now works, with file paths>

**Files modified**
- `<path>`: <one line on the change>

**Unfinished**
- `<path>` `<function or node>`: <what it does now, what it still has to do>

**Known errors**
- <exact error text, file:line, how to reproduce> or none

**Tests** (on `<sha>`)
- `<exact command>`: <pass/fail counts, or "not run" and why>
- CI: <link to the run, or "not observed">

**Dependencies not available to remote agents**
- <model weights, local paths, GPU-only tools, Mac-only checks, secrets> or none

**Next steps**
1. <specific action, file path, expected result>
2. ...

**Notes for the other agent**
- <decisions made, things not to touch, questions waiting on the owner>
```

## Log

### 2026-10-18 01:16 UTC · Copilot · CIG-1 optional character visual slot

- **Branch:** `biancaalexis132-png-cig-1-character-integration` (based on `main` at `96ef65e`)
- **Latest verified commit:** `d5d19f5ff329220bdbedfc006f632715923e8f87` "Record CIG-1 draft review state"; runtime tests were executed on code commit `387ceba5fc6d5abf9c564ef876c9c475825e2493`.
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/biancaalexis132-png-cig-1-character-integration` printed `d5d19f5ff329220bdbedfc006f632715923e8f87`.
- **Pull request:** #42 (draft, open, `MERGEABLE`); hosted `validate` pending on last-checked head `d5d19f5` (run 39085902026). This handoff update advances the PR head; refresh the new docs-only run.
- **State:** unfinished but coherent. Optional runtime slot/fallback groundwork is complete; the Naomi asset itself is not integrated.

**Accomplished**
- Added `VisualRoot` and an optional `PackedScene` visual slot to `WardCharacter`; retained `Body/Mesh`, collision, interaction, label, character IDs, dialogue flow and save providers.
- Seated scaling now applies only to the legacy placeholder capsule. Imported visuals keep their authored transform and are rejected (with a warning and visible fallback) when the root is not `Node3D` or no renderable mesh is present.
- Added deterministic tests for initial fallback, seated behavior, valid/invalid/empty visuals, pre-tree configuration, Naomi dialogue with a clipless visual, save/load state invariance, and character fallback after zone unload/rebuild.
- Confirmed the Naomi GLB is present and licensed in `assets/asset_manifest/naomi_character_manifest.json`, but its review status is pending; it is an automated base, not yet approved for integration, and has zero embedded animation clips. It was imported/validated by Godot but not attached to a game character.

**Files modified**
- `scripts/world/Character.gd`, `scenes/props/Character.tscn`: optional visual node/resource, validation and fallback.
- `scripts/tests/test_character_visual.gd` and `.uid`: focused regression coverage.
- `docs/AI_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`, `docs/AI_SESSION_HANDOFF.md`, `docs/PROJECT_STATUS.md`: current CIG checkpoint and refreshed GitHub state.

**Unfinished**
- Actual Naomi model integration, animation playback on her rig, rendered/pose review and owner Mac profiling: blocked pending owner visual approval and an authored animation deliverable. Do not claim the automated base is the approved integration target.
- Hosted `validate` is still pending on PR #42 head `d5d19f5`; CI is not yet observed as passed.

**Known errors**
- Full `python3 tests/qa/run.py --godot /tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot` exits 1 in `tests/music_ai/test_generate_music.py`: JSON 6/6 and audio-manifest 3/3 pass; music preview is 1 passed / 2 failed. The failures `test_generate_verify_and_approve` and `test_reference_audio_uses_approved_main_theme` report `Unknown encoder 'libvorbis'`. No FFmpeg/Vorbis replacement was installed; the runner stops before Godot suites, which were then executed directly.
- Godot emits expected warnings for deliberately invalid/empty visual test fixtures; no script errors remain.

**Tests** (on `387ceba`)
- `python3 -m unittest discover -s docs/design/characters/ForensicWard_Character_Integration_Gate_v1/tools -p 'test_*.py'`: 3 passed.
- `python3 docs/design/characters/ForensicWard_Character_Integration_Gate_v1/tools/check_character_glb.py assets/exports/characters/Naomi_Bennett_Base_v01.glb`: structurally valid; 17 meshes, 71 nodes, 1 skin, 0 animations, 12 materials, 2 textures.
- `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --version`: `4.7.stable.official.5b4e0cb0f`; official universal macOS release verified against its published SHA-512.
- `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import`: exit 0, no errors. `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/godot/validate_glb_imports.gd`: 139 assets checked, 0 failures.
- `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --headless --path . res://scripts/tests/TestRunner.tscn`: 127 passed / 0 failed.
- `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/TestPharmacology.tscn`: 0 failures; `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/qa/TestQA.tscn`: 19 passed / 0 failed / 0 skipped.
- `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 60`: boot OK; `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/audio/TestAudio.tscn`: 336 passed / 0 failed; `/tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot --headless --path . res://scenes/audio/Ch1AudioSequence.tscn -- --exit-when-done`: completed in 63.2 seconds with Naomi subtitles and `CH1_SEQUENCE_DONE`.
- `git diff --check`: passed. CI: not observed.

**Dependencies not available to remote agents**
- Naomi Blender builder dependency MPFB2 2.0.18 is local-only for rebuilding the source; no rebuild was done. Owner's visual and target-device review is still required.
- Full runner music tests need an FFmpeg build with the `libvorbis` encoder; none was installed during this work.

**Next steps**
1. Refresh hosted CI for PR #42 after this documentation update; retain draft status and leave merge to the owner.
2. Have the owner review the Naomi preview and approve/refine the base before attaching `Naomi_Bennett_Base_v01.glb` to `staff_bennett`.
3. Author/approve rig animations and validate actual animation/acting behavior before claiming CIG-1 model acceptance.
4. Run the documented visual/performance review on the owner's Apple Silicon 8 GB Mac; no rendering-quality or performance claim is made by headless tests.

**Notes for the other agent**
- Keep `data/world_chapter1.json`, dialogue/story/clinical state, save schema and Naomi builder sources unchanged.
- The historical latest handoff and project-status snapshot were stale at `47a68f4`; live `origin/main` advanced to `96ef65e` through #38/#40/#41 merges. No PR was open at the pre-creation check.

### 2026-10-18 00:56 UTC · Copilot · Jordan review final push verification

- **Branch:** `biancaalexis132-png-jordan-vale-v2-review`, includes merge commit from `origin/main` `47a68f40b09423b3253091e25b4715ce82447113`
- **Latest verified commit:** `3f162e3caee3739137ec0cf9df93f226dc72023c` "Record Jordan review merge checkpoint"
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/biancaalexis132-png-jordan-vale-v2-review` returned `3f162e3caee3739137ec0cf9df93f226dc72023c`.
- **Pull request:** #38 remains open/draft; GitHub reports `MERGEABLE`. Hosted `validate` is pending on this head (run 39084612239).
- **State:** PR #38 now includes current main; the four handoff conflicts are resolved. This review branch has not been merged.

`git show --check --oneline HEAD`, JSON syntax parsing, and `git diff --check` passed. The nine Jordan source files still match `origin/docs/jordan-vale-v2`. Full local Godot QA was not run. No runtime, SaveManager, schema or clinical status changed.

Next: refresh CI/mergeability after this handoff update is pushed; keep PR #38 draft and do not merge. Owner and qualified psychiatrist decisions remain pending.

### 2026-10-18 00:54 UTC · Copilot · Jordan review merge reconciliation

- **Branch:** `biancaalexis132-png-jordan-vale-v2-review`, merged with `origin/main` `47a68f40b09423b3253091e25b4715ce82447113`
- **Latest verified commit:** `0279db890abb05483feb6b08463d63a738b51810` "Merge origin/main and reconcile Jordan review handoffs"
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/biancaalexis132-png-jordan-vale-v2-review` returned `0279db890abb05483feb6b08463d63a738b51810`.
- **Pull request:** draft PR #38 to `main`; open, GitHub reports `MERGEABLE`; `validate` is pending on this exact head.
- **State:** conflict merge resolved without rewriting history. Naomi PR #37 and production documentation PR #39 additions were preserved; #37 and #39 are merged in current main. Jordan’s nine source files and review report are unchanged.

**Accomplished**
- Resolved conflicts in the continuity/status files and merged the fetched main commit, preserving both Jordan and upstream Naomi/production-batch records.
- Updated PR inventory and current workstream status to show #35, #36, #37, and #39 merged, while #38 remains draft and unmerged.

**Files modified**
- `docs/AI_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`, `docs/AI_SESSION_HANDOFF.md`, `docs/PROJECT_STATUS.md`: combined the conflicting status/handoff records and corrected live PR state.
- Incoming Naomi assets/builder and Elias/Rahman production specifications from main were preserved unchanged by the merge.

**Validation** (on `0279db8`)
- `python3 -m json.tool docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/case_cp001_v2.json`: passed JSON syntax parsing.
- `git show --check --oneline HEAD`: passed.
- `git diff --quiet origin/docs/jordan-vale-v2 -- docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/{CHANGELOG.md,CLINICAL_REVIEW_MATRIX.md,COPILOT_HANDOFF.md,FIVE_SHIFT_SCREENPLAY.md,GAMEPLAY_CONTRACT.md,LONGITUDINAL_TIMELINE.md,PATIENT_DOSSIER.md,README.md,case_cp001_v2.json}`: passed; all nine source files remain unchanged.
- Hosted PR #38 `validate`: pending on `0279db8` when checked; GitHub reported `MERGEABLE`, status `UNSTABLE` pending required check.
- Full local Godot QA: not run; no Jordan runtime or schema changes were made.

**Next steps**
1. Check PR #38 hosted validation after this handoff checkpoint is pushed; retain draft status and do not merge.
2. Owner resolves canon/source/authority questions and a qualified psychiatrist reviews the case-specific clinical material before any schema/runtime proposal.

**Notes for the other agent**
- Keep clinical content pending; do not activate case JSON/rules or change SaveManager/runtime/schema.
- PR #37’s base milestone is merged, but Naomi refinement remains a separate workstream. PR #39 adds production specifications only; their gates do not constitute clinical or canon approval.

### 2026-10-18 00:52 UTC · Copilot · Final CP-001 review checkpoint

- **Branch:** `biancaalexis132-png-jordan-vale-v2-review`, based on `origin/main` `03f1585a62bd33db7dcfe8116b50db71f8ee171b`
- **Latest verified content checkpoint:** `ef22d090c926f2fa50115478ed5eed95dee93b77` "Record CP-001 review validation result"; `git ls-remote` returned this exact branch SHA.
- **Pull request:** draft PR #38 to `main`, https://github.com/biancaalexis132-png/ForensicWard_Game/pull/38; open, no reviews/comments observed.
- **Hosted CI:** `validate` passed on `b79ea11d675f40aeee3420676890e4a3ba8bcd7f` in 3m50s (run 39083958547). The latest docs-only checkpoint `ef22d09` has no check reported: `gh pr checks 38` returned “no checks reported on the 'biancaalexis132-png-jordan-vale-v2-review' branch”; `gh run list` shows the most recent run is still the successful `b79ea11` run.
- **State:** review report and continuity documents are pushed; nine source files, runtime, clinical rules and save schema remain unchanged. No clinical approval is granted.

JSON syntax, `git show --check`, `git diff --check`, and source-package unchanged checks passed. Full local Godot QA was not run because the diff is documentation-only. Treat the successful hosted check as evidence for its exact head SHA only, not as clinical review or validation of a later commit.

Next step: owner reviews the draft report; owner resolves canon/source/authority decisions and the qualified psychiatrist completes section-specific content approval before any implementation.

### 2026-10-18 00:50 UTC · Copilot · CP-001 review CI checkpoint

- **Branch:** `biancaalexis132-png-jordan-vale-v2-review` (based on `origin/main` `03f1585a62bd33db7dcfe8116b50db71f8ee171b`)
- **Latest verified review checkpoint:** `b79ea11d675f40aeee3420676890e4a3ba8bcd7f` "Record CP-001 review PR state"
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/biancaalexis132-png-jordan-vale-v2-review` returned `b79ea11d675f40aeee3420676890e4a3ba8bcd7f`.
- **Pull request:** draft PR #38 to `main`, https://github.com/biancaalexis132-png/ForensicWard_Game/pull/38.
- **CI:** hosted `validate` check passed on this checkpoint in 3m50s: https://github.com/biancaalexis132-png/ForensicWard_Game/actions/runs/39083958547/job/117546508688. This is not clinical validation.
- **State:** documentation-only review is complete and pushed; no clinical-content or runtime changes.

The findings and approval gates in the preceding review entry remain current. Owner and qualified psychiatrist decisions are pending. The final PR-state checkpoint below this entry is documentation-only; refresh the live PR/check state after any further push.

### 2026-10-18 00:37 UTC · Copilot · Jordan Vale CP-001 v2 review

- **Branch:** `biancaalexis132-png-jordan-vale-v2-review` (based on `origin/main` at `03f1585a62bd33db7dcfe8116b50db71f8ee171b`)
- **Reviewed source:** `origin/docs/jordan-vale-v2` at `8131b240afd77710b277f010b8b096c1a6b684d2`; merged as PR #36. PR #35 and PR #34 are also merged. `gh pr list --state open` returned no open PRs.
- **Latest verified commit:** `7876d53317da79b375a33ae06a2b66020928dc9b` "Review Jordan Vale CP-001 v2 package"
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/biancaalexis132-png-jordan-vale-v2-review` returned the exact SHA above.
- **Pull request:** draft PR #38 to `main`, https://github.com/biancaalexis132-png/ForensicWard_Game/pull/38.
- **State:** documentation review report pushed; no clinical approval, runtime/data adoption, SaveManager change, or source-package edits.

**Accomplished**
- Reviewed all nine files in the CP-001 v2 package and compared the claims against current main’s patient schema/content loader, PatientManager, SaveManager v3/migrations, ChapterDirector/campaign, Chapter 5 ending proposal, clinical approval register and historical references.
- Added `docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/REVIEW.md` with eight ranked findings, evidence citations, approval dispositions and gated implementation sequence.
- Verified the Jordan source branch/merge and PR state against fetched GitHub refs. Current main is beyond the older `fb07887` handoff baseline. Historical handoff entries are retained.
- Confirmed no CP-001 v1 path/package in the fetched repository refs/file history; the v2 claim to retain/derive from v1 is not independently verifiable.
- Confirmed PR #35 acting cues merged; the Naomi 3D/model pipeline is still a separate active session/branch. The review’s proposed Naomi dialogue remains unlinked and untouched; the owner of that session was notified of the boundary.

**Files modified at the verified report commit**
- `docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/REVIEW.md`: design-only, clinical-content and implementation review. The nine source files are unchanged.

**Findings / approvals**
- P1: reconcile Jordan’s identity with the existing Chapter 1 “provisional, not canon” character; owner decision and author correction.
- P1: historical diagnosis provenance and specific symptom/dialogue review; psychiatrist decision required. Mood/anxiety statements remain symptoms/proposed dialogue, not diagnoses.
- P1: review safety, legal-authority, consent and collateral scope; do not infer risk, capacity, legal status, or treatment.
- P1: author source/event provenance, then add a separate schema/validator and coordinated lifecycle/save contract. No case runtime or case validator exists; current SaveManager remains v3 and Chapter 5 is planned.
- P2: define source-time versus in-game time, task ownership/acknowledgment semantics, and recover the referenced v1 baseline or correct its provenance claim.
- All clinical content stays pending; Ward Zero remains independent from clinical state. No rules or patient content were activated.

**Tests**
- `python3 -m json.tool docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/case_cp001_v2.json`: passed JSON syntax parsing; no CP schema validation exists.
- `git show --check --oneline 7876d53317da79b375a33ae06a2b66020928dc9b`: passed.
- `git diff --check`: passed on the continuity-doc working tree.
- Full Godot QA: not run; documentation-only review with no runtime or shipped content changes.
- Hosted CI: not observed.

**Next steps**
1. Push and verify the final PR-head SHA with `git ls-remote`; confirm the PR remains draft.
2. Owner resolves canon/source questions; psychiatrist reviews case-specific clinical material before any schema/runtime PR.
3. Do not merge or change clinical status; any implementation must follow the gated sequence in `REVIEW.md`.

**Notes for the other agent**
- Keep the nine source package files, runtime, patient data, clinical rules and SaveManager unchanged in this review.
- Use one shared, reviewed v3→v4 plan only after Continuing Practice, finale and protagonist state ownership are approved.
- Naomi’s model work remains on its separate branch; no proposed CP dialogue is an approved acting cue.
### 2026-10-18 00:43 UTC · Copilot · Naomi 3D PR checkpoint

- **Branch:** `biancaalexis132-png-naomi-character-pipeline` (based on `origin/main` at `21205c3c71d4543a2fa4abe0d54e172ce725db01`)
- **Latest verified commit:** `ff1b4059f5d728d37c24fe47762ecb7bff8948fd` "Document Naomi builder checkpoint"
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/biancaalexis132-png-naomi-character-pipeline` printed `ff1b4059f5d728d37c24fe47762ecb7bff8948fd` at 2026-10-18 00:43 UTC.
- **Pull request:** draft PR #37 to `main`; at creation GitHub reported OPEN/DRAFT at head `ff1b4059f5d728d37c24fe47762ecb7bff8948fd`. This handoff commit will advance the PR head; verify both refs after pushing.
- **State:** unfinished but coherent, submitted for review; no merge.

**Accomplished**
- Created a draft review PR for the pinned Blender builder, editable base, GLB, renders and complete asset provenance. This status-only commit updates the PR handoff after creation.
- The tested code checkpoint is `2a6ffda5e580c551b0f2f235861960e0d7662657`; this documentation commit contains no code or asset changes, so the validation recorded in the immediately preceding Naomi base entry still applies.

**Files modified**
- `docs/AI_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`, `docs/AI_SESSION_HANDOFF.md`, `docs/PROJECT_STATUS.md`: current draft-PR state and checkpoint.

**Unfinished**
- Owner visual review and the remaining character refinement/integration work listed in the preceding Naomi base entry.

**Known errors**
- The local `libvorbis` music-preview blocker is unchanged; see the preceding entry for the exact error and all executed Godot results.

**Tests** (code at `2a6ffda`; this checkpoint is documentation-only)
- `git diff --check`: passed.
- Godot/Blender: not rerun because only handoff/status documentation changed; see the preceding Naomi base entry for exact commands and results.
- CI: not observed.

**Dependencies not available to remote agents**
- MPFB2 v2.0.18 must be installed/enabled locally in Blender 5.2.2 to reproduce the build; local Godot 4.7 binary and FFmpeg limitation are recorded in the preceding entry.

**Next steps**
1. Owner reviews draft PR #37 and the four renders; do not merge automatically.
2. Continue the model in small reviewable milestones only after feedback; preserve existing dialogue, clinical and save behavior.

**Notes for the other agent**
- PR #35 is merged in main at `21205c3`; its adapter is model-independent and no CP-001 screenplay content is linked to Naomi.

### 2026-10-18 00:41 UTC · Copilot · Naomi 3D character base

- **Branch:** `biancaalexis132-png-naomi-character-pipeline` (started from `origin/main` at `29f1e3386ffe0f0907ef698859fa27c05da9b9d8`, then merged current `origin/main` at `21205c3c71d4543a2fa4abe0d54e172ce725db01`)
- **Latest verified commit:** `2a6ffda5e580c551b0f2f235861960e0d7662657` "Merge remote-tracking branch 'origin/main' into biancaalexis132-png-naomi-character-pipeline"
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/biancaalexis132-png-naomi-character-pipeline` printed `2a6ffda5e580c551b0f2f235861960e0d7662657` at 2026-10-18 00:38 UTC. This handoff commit will sit on top; verify the final branch ref after pushing it.
- **Pull request:** none yet; create a draft against `main` after this handoff checkpoint is pushed.
- **State:** unfinished but coherent; the repeatable builder and generated base are pushed. The asset is not a finished realistic Naomi and is not integrated into a game scene.

**Accomplished**
- Implemented the version-pinned MPFB2 builder, appearance configuration, Blender validator, and run instructions in `tools/blender/characters/`.
- Generated editable `Naomi_Bennett_Base_v01.blend`, self-contained Godot GLB, and preview/front/right/back renders. The GLB is 42,583 triangles, 53 joints, with two referenced embedded textures; the Blender source has 15 required scene objects.
- Added exact input-file and macro-target-weight provenance, output sizes, license evidence, generated-status caveats, and the shared GLB asset-manifest record. MPFB2 v2.0.18 assets used are CC0-1.0; MPFB2 code is GPL-3.0-or-later and only a local build tool. No Mixamo or non-MPFB external assets are used.
- Merged current `origin/main` after PR #35 merged at `21205c3`; the model branch does not duplicate or modify the acting controller, dialogue, clinical content, save schema, or gameplay state.

**Files modified**
- `tools/blender/characters/build_naomi.py`, `naomi_appearance.json`, `validate_naomi.py`, `README.md`: repeatable builder, approved appearance settings, output/provenance checks, and exact Mac commands.
- `assets/blender/characters/Naomi_Bennett_Base_v01.blend`, `assets/exports/characters/Naomi_Bennett_Base_v01.glb`, and four review renders: generated base outputs.
- `assets/asset_manifest/naomi_character_manifest.json`: exact CC0 inputs, source commit, macro targets, file sizes, metrics, and limitations.
- `assets/asset_manifest/asset_manifest.json`: shared Godot GLB record with imported dimensions and material names.
- Continuity/status files: this entry and the current workstream status; no runtime or save files were edited by this milestone.

**Unfinished**
- The base remains in a neutral T-pose. Facial likeness, hairline/twist silhouette, scrub seams/clipping/deformation and overall render quality need owner/artist review and manual refinement. Do not label the current base finished or photorealistic.
- No animation clips, LOD1, expression/jaw performance, or Chapter 1 scene integration are included. The 30 FPS / p95 33.3 ms target has not been measured in the actual Chapter 1 scene on the 8 GB Mac.

**Known errors**
- `python3 tests/qa/run.py --godot /tmp/godot-4.7-naomi/Godot.app/Contents/MacOS/Godot` exits 1 in `tests/music_ai/test_generate_music.py`: two preview-generation tests fail with `Unknown encoder 'libvorbis'`; the music suite is 1 passed / 2 failed. JSON and audio-manifest suites pass. All later Godot suites were run directly and passed.

**Tests**
- `/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tools/blender/characters/build_naomi.py`: exit 0; 42,583 export triangles; four renders written.
- `/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tools/blender/characters/validate_naomi.py`: passed; 15 required objects, 53 GLB joints, 42,583 triangles, two referenced embedded textures, four review renders, manifests/provenance current.
- `python3 tests/qa/run.py --godot /tmp/godot-4.7-naomi/Godot.app/Contents/MacOS/Godot`: JSON 6/6 and audio manifest 3/3 pass; music pipeline 1/3 pass, 2 fail as above; runner stops there.
- Godot 4.7 post-runner commands on the merged branch: editor import exit 0; `TestPharmacology.tscn` reports 0 failures; `TestQA.tscn` 19 passed / 0 failed / 0 skipped; `validate_glb_imports.gd` 139 assets / 0 failures; `scripts/tests/TestRunner.tscn` 122/0; boot OK; `tests/audio/TestAudio.tscn` 336/0; Chapter 1 audio sequence completed in 63.4 seconds.
- Exact Godot checks used `/tmp/godot-4.7-naomi/Godot.app/Contents/MacOS/Godot --headless --path /Users/bi/.copilot/repos/copilot-worktrees/ForensicWard_Game/biancaalexis132-png-literate-potato` followed by `--editor --import`; `res://tests/TestPharmacology.tscn`; `res://tests/qa/TestQA.tscn`; `-s res://tools/godot/validate_glb_imports.gd`; `res://scripts/tests/TestRunner.tscn`; `--quit-after 60`; `res://tests/audio/TestAudio.tscn`; and `res://scenes/audio/Ch1AudioSequence.tscn -- --exit-when-done`.
- Python AST/JSON checks and `git diff --check`: passed. CI: not observed.

**Dependencies not available to remote agents**
- Blender 5.2.2 LTS and MPFB2 2.0.18 enabled in the local Blender environment; MPFB2 is not vendored. Install the exact MPFB release before reproducing.
- Godot 4.7 binary used for validation: `/tmp/godot-4.7-naomi/Godot.app/Contents/MacOS/Godot`. Local FFmpeg lacks the `libvorbis` encoder required by two existing music-preview QA cases.
- The 8 GB Apple Silicon hardware performance target remains unmeasured in the in-game Chapter 1 scene.

**Next steps**
1. Owner reviews `assets/exports/characters/Naomi_Bennett_Base_v01_preview.png` and the `_front.png`, `_right.png` and `_back.png` orthographic renders, then gives targeted feedback on face, hair silhouette, scrubs and proportions.
2. Refine the Blender source and repeat the validator/render review; add authored performance clips and expression controls only as a separate, reviewable milestone.
3. Integrate the approved model with existing `staff_bennett` / `WardCharacter` behavior and merged `CharacterActingAdapter` without changing dialogue IDs, clinical review states, gameplay progression, or save schema.
4. Measure frame time and memory in the Chapter 1 nursing-station scene on the target 8 GB Mac before claiming the performance budget.

**Notes for the other agent**
- Acting-cue PR #35 merged into `main` at `21205c3`; its model-independent adapter does not require specific bones. Keep the 53-joint asset optional until visual review and scene integration. Preserve `staff_bennett`, existing voice/dialogue IDs, and all pending clinical review status.
### 2026-10-18 00:16 UTC · Copilot · Naomi Chapter 1 acting cues

- **Branch:** `biancaalexis132-png-naomi-chapter1-acting` (based on `origin/main` at `29f1e3386ffe0f0907ef698859fa27c05da9b9d8`)
- **Latest verified commit:** `9d27aa1dd1566d3b6c4adaaffed821b189383562` "Add Naomi acting cue system"
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/biancaalexis132-png-naomi-chapter1-acting` printed `9d27aa1dd1566d3b6c4adaaffed821b189383562` at 2026-10-18 00:16 UTC. This documentation checkpoint will sit on top; query the branch ref for its final SHA.
- **Pull request:** draft PR #35 to `main`, https://github.com/biancaalexis132-png/ForensicWard_Game/pull/35.
- **State:** implementation and handoff checkpoint pushed, finished for review; not merged.

**Accomplished**
- Added an additive `NaomiActingController` driven by the canonical `docs/design/characters/Naomi_Acting_Cues_v1/naomi_acting_cues.json`; cues use the existing five IDs in `ch1_b2_bennett_handover`, with no dialogue text, story, clinical content, or review-status changes.
- Added `CharacterActingAdapter`, which checks for optional semantic body animations, blend shapes and adapter groups rather than requiring named MPFB bones. Missing capabilities and clips remain safe no-ops; voice/subtitle timing drives speaking state.
- Added a presentation-only dialogue-finished event for natural completion versus interruption, with per-line tokens to ignore stale voice callbacks/timeouts. Save/load and transition fallbacks add no save provider or schema fields.
- Wired only `staff_bennett`; the placeholder remains valid without animation/face nodes. The separate model-builder branch and all character assets/provenance/render files were left untouched.

**Files modified**
- `scripts/acting/NaomiActingController.gd` and `.uid`: loads canonical cues, filters lines, follows subtitles, completion/interruption and game-load events.
- `scripts/acting/CharacterActingAdapter.gd` and `.uid`: capability checks, optional clip/face/gaze/gesture dispatch, safe fallback transitions.
- `scripts/world/Character.gd`: Bennett-only controller attachment and conversation start.
- `systems/audio/AudioDirector.gd`, `scripts/autoload/EventBus.gd`: line lifecycle signal and stale-callback protection.
- `scripts/tests/test_naomi_acting.gd` and `.uid`, `tests/audio/TestAudio.gd`: focused acting and dialogue lifecycle coverage.
- `docs/AUDIO.md`: lifecycle and rig adapter contract.
- `docs/AI_HANDOFF.md`, `docs/PROJECT_STATUS.md`, `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`: continuity and status checkpoint.

**Unfinished**
- No implementation items. Draft PR creation remains; no merge is authorized.
- Owner/Mac review of real-model expression, gesture, transition, rendering and audio feel remains untested here.

**Known errors**
- Full QA runner stops in `tests/music_ai/test_generate_music.py`: FFmpeg reports `Unknown encoder 'libvorbis'` for two generation tests. This is a local toolchain limitation, not an acting test failure; the runner does not proceed to later suites on that attempt.

**Tests** (on `9d27aa1`)
- `python3 docs/design/characters/Naomi_Acting_Cues_v1/validate_naomi_cues.py .`: passed; five dialogue IDs and all voice mappings valid.
- `/tmp/godot-4.7-acting/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import`: exit 0, no script diagnostics.
- `/tmp/godot-4.7-acting/Godot.app/Contents/MacOS/Godot --headless --path . res://scripts/tests/TestRunner.tscn`: **122 passed, 0 failed**.
- `/tmp/godot-4.7-acting/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/audio/TestAudio.tscn`: **336 passed, 0 failed**.
- `python3 tests/qa/run.py --godot /tmp/godot-4.7-acting/Godot.app/Contents/MacOS/Godot`: exit 1 at music generation; JSON 6/6, audio manifest 3/3, music pipeline 1 passed / 2 failed due to the quoted missing encoder. Later runner suites were not reached. `git diff --check`: passed.
- CI: not observed.

**Dependencies not available to remote agents**
- Local Godot 4.7 binary: `/tmp/godot-4.7-acting/Godot.app/Contents/MacOS/Godot`. The machine's FFmpeg 9.0.2 lacks the `libvorbis` encoder. Realistic Naomi model/rig remains under active work on a separate branch.

**Next steps**
1. Owner reviews draft PR #35; agent does not merge.
2. Keep future model integration behind the adapter capability contract; request owner/Mac review for animation, face, gesture and transition feel.

**Notes for the other agent**
- The source performance package is on `main` at `29f1e3386ffe0f0907ef698859fa27c05da9b9d8`. Do not copy its cue JSON into a duplicate file.
- Do not edit `tools/blender/**`, generated Naomi assets, model-builder scripts, provenance or visual-render files.
- Dialogue text and existing pending clinical review statuses remain unchanged.

### 2026-10-17 · Codex · Resolve owner-confirmed PR #27 conflicts

- **Branch:** `claude/ashcroft-soundtrack` (PR #27), updated from a temporary continuation `codex/ashcroft-soundtrack-conflicts-cont-1` under the owner’s explicit request identifying PR #27.
- **Latest verified commit:** `f59da089582ef27a6e58fc5eecc21a48d381a876` “Merge latest main and reconcile active workstreams after PR 29”.
- **Confirmed on GitHub:** ordinary non-force push `HEAD:refs/heads/claude/ashcroft-soundtrack`; `git ls-remote` returned the exact SHA above. Parent history preserved; main not pushed or merged by the agent. This documentation-only checkpoint follows it.
- **State:** conflicts resolved against `origin/main` `dd247bed93fca9bb95cbf2864eae964975358c23`. `git merge-tree --write-tree origin/main HEAD` exited 0; no unmerged index entries. Existing PR #27 updated via its head branch; API/hosted CI status unavailable due enforced API domain restriction.

**Resolution:** preserve soundtrack and visual/protagonist continuity records in both living docs; combine active-workstream table, removing already merged F2/P0 claims. Keep all append-only historical entries. Audio integration content remains unchanged.

**Validation correction:** first full QA run found 333 audio assertions passed / 1 failed: the existing fixed 3.6-second cleanup wait was too short for a 3.4-second clip with Dummy audio buffering. A three-play probe measured 3.466, 3.587 and 3.804 seconds until both actual players freed themselves. `tests/audio/TestAudio.gd` now waits for those objects with a bounded clip-duration-plus-one-second deadline; the original leak assertion remains, including original child count. No runtime audio behavior changed.

**Tests:** full `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64` on `7feb43e`: exit 0, Python 6+3+3, pharmacology 0 failures, QA 19/0/0, GLB 138/138, TestRunner 112/0, boot OK, audio 334/0, complete Chapter 1 playback (`CH1_SEQUENCE_DONE`). Main then advanced by PR #29 (docs and four save tests only); isolated TestRunner on the combined `f59da08` tree passed **116/0** with no script errors. Other previously checked runtime/data/audio files unchanged. `git diff --check` passed. Hosted CI and Mac listening unobserved; licence confirmation remains owner task.

**Next:** owner reviews PR #27; no agent merge. Ongoing P1 validation, D1–D3 canon reconciliation and the newly approved opening-tone proposal use separate development commits/branch. Those approvals do not permit rewriting Chapter 1 or activating clinical effects. GitHub API remains blocked; use existing Git authentication, not a new token request.

### 2026-10-17 · Codex · Protagonist proposal and save QA complete

- **Branch:** `codex/protagonist-foundation-cont-1`, based on `origin/main` `fb078877c59273c0856ec29f29e4ae43d3fc3125`.
- **Latest verified commit:** `01739ff70136d191704b694fbf32d6b9e28ee26d` “Guard save rejection and optional provider compatibility”.
- **Confirmed on GitHub:** `git ls-remote origin refs/heads/codex/protagonist-foundation-cont-1` returned the exact SHA above after push. A docs-only checkpoint containing this entry follows it; resolve the final tip with the same command.
- **Pull request:** none created; `gh pr create --draft` failed with `Post "https://api.github.com/graphql": Forbidden`. API CONNECT is denied with HTTP 403. Open PR inventory/hosted CI remain unverified.
- **State:** complete and pushed for review; no runtime, clinical, asset or save-version changes.

**Accomplished / files:** proposal and reconciliation in `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md` and `docs/REPOSITORY_RECONCILIATION.md`; approved protagonist requirements in GDD amendments; status and continuity docs reconciled. New `scripts/tests/test_save_compatibility.gd` + UID tests rejection without provider/seed/event mutation, absent-provider reset, real v1/v2 migration compatibility and added-provider round trip/reset. All prior append-only entries retained.

**Tests:** standard `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`, from repo root: baseline `fb07887` exit 0 (TestRunner 112/0); development tree matching `01739ff` exit 0 (116/0). Python 6+3+3 passed, pharmacology 0 failures, QA 19/0/0, GLB 138/138, boot OK, audio 271/0, complete ordered Chapter 1 sequence. `git diff --check` passed. Expected negative-save warnings and non-fatal Python socket ResourceWarnings only. Hosted CI not observed; Mac validation not run.

**Known errors / unavailable dependencies:** GitHub API blocked by network policy; additive `api.github.com` requirement saved in cloud draft, not applied/published. Git push works. Private v1.1 bible unavailable; Mac and optional generation tools not validated. D1–D9 and F0 C2/C6/C7/C11 remain open; no new medical content is approved.

**Exact next steps:** apply saved environment network setting, retry PR inventory and create draft PR from this branch (avoid duplicate). Owner reviews proposal and authorizes P1 catalog/schema/pure validation scope before implementation. No full creator, v4 migration, personality meters or F3 without their review gates. Preserve audio PR #27 and Stage 6 ownership pending API verification. Full file list, PR body location and resume instructions: `docs/AI_SESSION_HANDOFF.md`. Never push main or merge.

### 2026-10-17 · Codex · Protagonist specification / save QA baseline

- **Branch:** `codex/protagonist-foundation-cont-1`, from `origin/main` at `fb078877c59273c0856ec29f29e4ae43d3fc3125`.
- **Latest verified commit:** `fb078877c59273c0856ec29f29e4ae43d3fc3125` “Merge pull request #28 from biancaalexis132-png/claude/visual-direction-review”.
- **Confirmed on GitHub:** `git ls-remote origin HEAD` returned that SHA; fetched history confirms F0 PR #20, F1 #21, F2 #26 and visual review #28 merged.
- **Pull request:** none yet. Existing open PRs cannot be listed: both REST and GraphQL return Forbidden. Historical audio PR #27 and Stage 6 work remain reserved pending verification.
- **State:** baseline complete; proposal written; independent regression tests in progress.

**Accomplished:** reconciled objectively stale F2/visual-review merge status, recorded the owner’s explicit protagonist decisions, and wrote the phased technical proposal. Review recommendations D1–D9 are not approved by merging #28.

**Files modified:** continuity/status docs, `docs/REPOSITORY_RECONCILIATION.md`, `docs/design/GDD_AMENDMENTS.md`, `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`; new save-compatibility tests are being validated. No runtime, data, asset or audio files changed.

**Tests on the base:** `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`: exit 0; Python 6+3+3 passed, pharmacology 0 failures, QA 19/0/0, GLB 138/138, TestRunner 112/0, boot OK, audio 271/0 and Chapter 1 `CH1_SEQUENCE_DONE`. Official engine archive SHA-512 verified. Hosted CI not observed. Development test run is separate and pending.

**Known errors / dependencies:** system Godot is 4.6.3 (runner rejects it); use pinned local 4.7. Python mock-server tests emit ResourceWarnings about unclosed sockets but pass. Missing private v1.1 bible. Mac rendering/performance/input/listening untested. Clinical approvals, visual D1–D9 and F0 C2/C6/C7 remain open. No unresolved decision is implemented.

**Next steps:** finish the new save regression suite and full QA, checkpoint results, push feature branch and verify exact SHA; create a draft PR if existing authentication permits. Do not start creator P1 before owner review of the proposal. Never merge or push main. The living handoff tracks remaining work.

### 2026-10-17 21:45 UTC · Claude Code · Foundation F2 zones

- **Branch:** `claude/f2-zones` (based on `main` at `4987123`)
- **Latest verified commit:** `fb9fc525fb8cefb0f63fd08ecda4051925ef72bc` "Add zone manifest, ZoneDirector and save version 3"
- **Confirmed on GitHub:** see `git ls-remote origin claude/f2-zones`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; waiting on owner review

**Accomplished**
- `data/zones.json` (global, in `ContentRegistry.MANIFEST`): zones `zone_clinical_wing`, `zone_security_admin` (ground), `zone_research_level` (research), `zone_historic_sublevel` (sublevel), `zone_ward_zero` (placeholder); connections `conn_ward_entry` (seamless door), `conn_restricted_lift` and `conn_service_hatch` (fade). Each zone has its environments, floor-plan bounds and audio rooms, which moved here from `world_chapter1.json`.
- Chapter world files now name a `start_zone`; entries may name a `zone` (default: the start zone) and are wired when that zone is built.
- `ContentValidator`: built zones need existing environments and bounds, zones on one level must not overlap, a connection joins two zones, seamless stays on one level and names door/door zone/anchor, fade names node and arrival per end, world `start_zone` is built, `zone_`/`conn_` prefixes.
- `AuthoredWorld`: `build_zone`, `unload_zone`, `has_zone`, `get_zone_ids`, `get_zone_root`, `get_persistent_nodes`, `find_zone_node`; builds only the start zone in `_ready`; `PlayerSpawn` lives on the world, not the zone.
- `ZoneDirector` (child of `Main`, provider `zones`): current zone from bounds, streams the zone behind a connection door when the player may open it and is within 10 m (or the door is open), always keeps the zone that holds a connection door, fade transitions (time paused, input off, free everything, build target, place on arrival), per-zone door state across unloads, perf CSV behind the `perf_log` setting. `EventBus.zone_changed` added.
- `ImportedDoor.before_open` hook (connection doors build the zone behind first); doors without config read "Records Office door". `ImportedInteractable` uses a method for `game_loaded` so unloaded zones disconnect cleanly; `mesh_aabb` is static.
- `SaveManager` v3: `_migrate_from_2` moves `world.objects` to `zones.objects.zone_clinical_wing`.

**Files modified**
- See commit `fb9fc52`; new `scripts/world/ZoneDirector.gd`, `scripts/tests/test_zones.gd`, `scripts/tests/fixtures/saves/save_v2_ch1_doors_open.json` (a real v2 save captured from `main` at `4987123`: office and interview doors open, player at (-0.5, 0, -12), 09:35).

**Unfinished**
- Arrival points in `zones.json` are hand-placed (`placeholder_arrival`); the environment workstream should add `MARK_Arrival_*` markers.
- Not built: Ward Zero connection, lift stop at the historic landing (needs a floor choice), quality presets.
- Security and research use the `corridor` ambience; `audio/cues.json` has no wing ambience for them.

**Known errors**
- none. Found while testing: Godot's dummy renderer (headless) is not thread-safe for mesh creation; threaded loading there logged "unimplemented base type encountered in renderer scene cull" and leaked meshes. `ZoneDirector.stream_on_threads` is false in headless runs, so CI loads on the main thread and the threaded path is untested until the Mac check.
- Not caused by F2: PR #22 put `assets/creative_references/` (about 42 MB of music and concept boards) inside the Godot project with no `.gdignore`, so Godot imports it and an export would ship it. A one-line `.gdignore` there would stop that if the owner wants.

**Tests** (on `fb9fc52`)
- `GODOT=<4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py`: exit 0. Python 6/6, 3/3, 3/3; TestQA 19/0/0; GLB 138/138; TestRunner 112 passed / 0 failed (97 before, 15 new in `test_zones.gd`); TestAudio 271/0.
- Ten lift round trips: static memory +8 KB, object count unchanged.
- CI: not observed yet for this branch

**Dependencies not available to remote agents**
- Mac: transition feel, streaming hitch, frame time and memory with `perf_log` on.

**Next steps**
1. Owner reviews the F2 PR.
2. F3 (anomaly evidence model, flag off) after the owner decides Psychosomatic Bleed (F0 §9).

**Notes for the other agent**
- Geometry belongs to zones (`data/zones.json`); chapter world files only wire gameplay onto it. Do not add `environments` back to a world file.
- Never build two levels at once; the validator rejects overlapping zones on one level.

### 2026-10-17 21:40 UTC · Claude Code · Ashcroft soundtrack

- **Branch:** `claude/ashcroft-soundtrack` (based on `main` at `65b598d`)
- **Latest verified commit:** `0f555939fd42fa3cd3dd7ccc2b412ad837eb6670` "Move exploration music to the records archive per the bible"
- **Confirmed on GitHub:** see `git ls-remote origin claude/ashcroft-soundtrack`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; waiting on owner review

**Accomplished**
- Six Ashcroft OGGs referenced in place from `assets/creative_references/Music/Ready_For_Godot/` (no copies; the `.m4a` sources are not used). Cues `mus_waiting_room`, `mus_compassion`, `mus_procedure`, `mus_temporal_fracture`, `mus_final_revelation`, `mus_main_theme_variant2`; state `hospital_ordinary` on a new `reception` location; contexts `patient_follow_up`, `oversight`, `ward_zero_anomaly`, `final_revelation`, `finale_motif` with begin/end events. Assignments and reasons in `docs/AUDIO.md` "Ashcroft score".
- Ward Zero temporal echo is event-only (`w0_temporal_echo_begin`); tests assert no location or intensity starts it.
- `AudioDirector._apply_music_context`: a play-once context cut short no longer blocks its own finished hook next time.
- Second commit: exploration music moved from the day corridor and nursing station to a new `records_archive` location, per the bible's Chapter 1 cue table. Droppable on its own.
- `.gdignore` in `Visual_References/` and `Music/Suno_Originals/`; manifest scans `Ready_For_Godot` and records Suno provenance.

**Files modified**
- Claimed files in the Active workstreams row.

**Unfinished**
- `data/world_chapter1.json` `audio_zones`: no `reception` or `records_archive` rectangle yet (world owner, F2 zones).
- No story data fires the new events yet.

**Known errors**
- none

**Tests** (on `0f55593`)
- `python3 tests/qa/run.py --godot <Godot 4.7>`: all suites pass; audio 334 passed, 0 failed.
- CI: not observed yet.

**Dependencies not available to remote agents**
- Listening review on the Mac; Suno licence terms for all Suno-tagged tracks (owner).

**Next steps**
1. Owner: listen, confirm the Suno licence, decide whether to keep the Chapter 1 realignment commit.
2. F2 zones: add `reception` and `records_archive` `audio_zones` rectangles when those areas exist.

**Notes for the other agent**
- Concept boards and notes reviewed but not used in game: board names/roles conflict with canon, board 2 cites real actors as likeness references, Ward Zero boards use occult imagery the bible rules out. Details in the PR description.

### 2026-10-17 20:50 UTC · Claude Code · Foundation F1 campaign contract

- **Branch:** `claude/f1-campaign-contract` (based on `main` at `33b2e8c`)
- **Latest verified commit:** `fa098c944aa9f33d9810649b5689c2504a2f5ffc` "Add campaign contract, chapter-scoped story state and save version 2"
- **Confirmed on GitHub:** see `git ls-remote origin claude/f1-campaign-contract`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; waiting on owner review

**Accomplished**
- `data/campaign.json`: institution "Ashcroft State Forensic Hospital", chapters `ch1` (playable) to `ch5` (planned, no content), dialogue file list.
- `ContentRegistry` loads global files from `MANIFEST`, then the dialogue, story and world files the campaign names (document keys `dialogue:<file>`, `story:<chapter>`, `world:<chapter>`). New queries: `get_story(chapter_id)`, `get_world(chapter_id)` (both default to the start chapter), `get_campaign`, `get_institution_name`, `get_chapter_ids`, `get_chapter`, `is_chapter_playable`, static `collect_documents`.
- `ContentValidator`: id prefixes (`ContentSchemas.ID_PREFIXES`) and uniqueness across every file and chapter; campaign rules (chapter id format, playable needs a story, planned ships nothing, start chapter playable); story `chapter` must match its campaign entry; one dialogue file per patient.
- `StoryLogic`: conditions `chapter_completed`, `chapter_flag`; action `start_chapter`. `ChapterDirector` keeps state per chapter; `start_chapter()`, `get_chapter_id()`, `has_completed()`, `get_chapter_flags()`. `EventBus.chapter_started` added.
- `SaveManager` v2: checksum verified on the file as written, then migrations; `_migrate_from_1` moves the flat `chapter` state under `ch1`.
- Docs: `docs/PROJECT_STATUS.md` rewritten from GitHub; `docs/ID_REGISTRY.md`; `docs/design/GDD_AMENDMENTS.md`.

**Files modified**
- See the commit; code in `scripts/autoload/ContentRegistry.gd`, `SaveManager.gd`, `EventBus.gd`, `scripts/content/ContentSchemas.gd`, `ContentValidator.gd`, `scripts/narrative/ChapterDirector.gd`, `StoryLogic.gd`; tests `scripts/tests/test_campaign.gd` (new), `test_content.gd` (fixture helper now uses `collect_documents`).
- Fixtures: `scripts/tests/fixtures/campaign/story_ch{2..5}_fixture.json` (placeholder text, test-only), `scripts/tests/fixtures/saves/save_v1_ch1_night_pending.json` (a real v1 save captured from `main` at `33b2e8c`: Bennett handover fired, Elias note saved, night shift, intercom pending).

**Unfinished**
- Not in F1 by design: observation polarity, zones (F2), anomaly model (F3).
- Known limitation: a delayed beat still pending when a chapter ends stays pending in that chapter; it does not fire after `start_chapter`. No shipped content does this.

**Known errors**
- none. Correction to the F0 entry below: `tools/godot/validate_glb_imports.gd` does not need a `._*` skip. `DirAccess.get_files_at` leaves out hidden files; a planted `._PROBE.glb` passed 138/138 on `main` and on this branch. F0 §1 is corrected.

**Tests** (on `fa098c9`)
- `GODOT=<4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py`: exit 0. Python 6/6, 3/3, 3/3; TestQA 19/0/0; GLB 138/138; TestRunner 97 passed / 0 failed (80 before, 17 new in `test_campaign.gd`); TestAudio 271/0.
- CI: not observed yet for this branch

**Dependencies not available to remote agents**
- none

**Next steps**
1. Owner reviews the F1 PR.
2. F2 on `claude/f2-zones` per `docs/F0_FOUNDATION_AUDIT.md` §8: `data/zones.json`, `ZoneDirector`, clinical wing to security wing prototype.
3. F3 waits on the owner's Psychosomatic Bleed decision (F0 §9).

**Notes for the other agent**
- New content goes through `data/campaign.json`; do not add story or world files to `ContentRegistry.MANIFEST`.
- Reserve ids in `docs/ID_REGISTRY.md` before using them. Merged branches' rows were removed from the workstream table above.

### 2026-10-17 20:30 UTC · Claude Code · Foundation F0 audit

- **Branch:** `claude/f0-foundation-audit` (based on `main` at `d21cff7`)
- **Latest verified commit:** `06fd50ad534dc0fb4847800eaf59b7bf6b513076` "Add F0 foundation audit and five-chapter architecture proposal"
- **Confirmed on GitHub:** see `git ls-remote origin claude/f0-foundation-audit`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; docs only, waiting on owner review

**Accomplished**
- `docs/F0_FOUNDATION_AUDIT.md`: implemented-vs-planned inventory, contradictions C1–C14 (Ward Zero canon, act names, player title, staff roles, Psychosomatic Bleed, pharmacology clue gates, stale PROJECT_STATUS), id scan (74 ids, no duplicates), proposed campaign/zone/anomaly architecture, reuse table, zone loading plan, clinical vs supernatural separation rules, F1–F3 scopes with acceptance tests, open approvals.

**Files modified**
- `docs/F0_FOUNDATION_AUDIT.md`: new.
- `docs/AI_HANDOFF.md`: this entry and a workstream row.

**Unfinished**
- none. `docs/PROJECT_STATUS.md` is stale (C14) but deliberately not edited here, to avoid conflicting with PR #19; F1 rewrites it.

**Known errors**
- none. Noted for F1: `tools/godot/validate_glb_imports.gd` does not skip `._*.glb` (local Mac only); `SaveManager.load_game` compares the checksum after migrating, so the first real migration needs the order fixed.

**Tests** (on `d21cff7`, the tree this branch adds docs to)
- `GODOT=<4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py`: exit 0; Python 6/6, 3/3, 3/3; TestQA 19/0/0; GLB 112/112; TestRunner 80/0; TestAudio 271/0.
- CI: not observed yet for this branch

**Dependencies not available to remote agents**
- none for F0. Mac checks listed in the audit stay untested.

**Next steps**
1. Owner reviews `docs/F0_FOUNDATION_AUDIT.md` and answers the approvals in its section 9.
2. After approval and after PR #19 merges: F1 on a new branch `claude/f1-campaign-contract` per section 8.

**Notes for the other agent**
- This branch and PR #19 both add an entry at the top of this log; whichever merges second resolves it by keeping both entries.
- Do not start F1–F3 structural changes before the owner approves F0 in the F0 thread or PR.

### 2026-10-17 20:20 UTC · Claude Code · Environment Stage 5 historic substructure

- **Branch:** `claude/environment-stage-5` (from `main` after PR #17), then `main` at `d21cff7` merged in
- **Latest verified commit:** `e57560e` "Build Stage 5 historic substructure: 13 props, 13 sublevel rooms", plus merge `faf6f50` of `main`
- **Confirmed on GitHub:** see `git ls-remote origin claude/environment-stage-5`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- 13 historic props (`assets/exports/historic/props/`): iron bed, instrument cabinet, hydrotherapy tub, exam table, steel desk, wooden chair, card index (one drawer missing), medication shelf, knife-switch fuse panel, caged bulkhead lamp, records vault door, steep service stair, cast-iron radiator. 17 aged palette materials in `fw_lib.py`.
- 13 spaces (`assets/exports/historic/env/`) on a sublevel with the Chapter 1 x/y and floor z = 0: a 24 m historic corridor with the lift landing under (0, 44), the mechanical corridor, the sealed connecting corridor (brick infill is `state_group: sealed_corridor_end` for Stage 6), records archive, admin office, former patient rooms 1 and 2, abandoned nursing station, two observation cells, hydrotherapy treatment room, medication storage, stairwell (stair top under the Stage 4a hatch, asserted) and the records vault.
- Uneven tungsten lighting: watts vary, some `LIGHTMARK_*` carry `flicker: true`, dead lamps have no light. Hooks carry `story_tag: historic_record`; medical-looking documents are `clinical_review_status: PENDING`.
- Render review fixed a black observation shot (camera moved into the lit cell; the dark cell keeps `CAM_OB_DarkCell`) and moved the vault shelving clear of the door swing.

**Files modified**
- New: `tools/blender/build_stage5_historic.py`, `assets/blender/historic/*.blend`, exports and their `.import` files, `assets/renders/stage5/*.png`.
- `tools/blender/fw_assets.py`, `tools/blender/fw_lib.py` (Stage 5 sections), `assets/asset_manifest/asset_manifest.{json,md}`, `docs/ENVIRONMENT_STAGES.md`, `docs/ENVIRONMENT_PIPELINE.md`, `docs/PROJECT_STATUS.md`, this file.

**Unfinished**
- Not wired into gameplay: no level scene, no stair climb interaction, no lift or hatch transition.
- Placement, layout, the hydrotherapy fit-out and every storytelling detail are assumptions for creative review.

**Known errors**
- The service stair is about 60 degrees, too steep to walk; it needs a climb interaction. Its collider only blocks walking through it.

**Tests** (on the merged tree, before this doc commit)
- `python3 tests/qa/run.py` with Godot 4.7 (4.7.stable.official.5b4e0cb0f): exit 0. Python suites 6/6, 3/3, 3/3, TestQA 19 / 0 / 0, `.glb` validation 138/138, TestRunner 80 / 0, TestAudio 271 / 0, "All executed checks passed".
- `build_stage5_historic.py` with Blender 5.0.1 (`bpy`): "STAGE5 HISTORIC OK: 13 props, 13 environments exported".

**Dependencies not available to remote agents**
- Mac-only checks (Forward+ look in Godot).

**Next steps**
1. Owner reviews and merges this PR.
2. Stage 6 Ward Zero, opened from the sealed corridor's brick `state_group`.
3. Gameplay: the stair climb and the lift and hatch transitions.

### 2026-10-17 19:55 UTC · Claude Code · Audio: original soundtrack

- **Branch:** `claude/audio-production` (based on `claude/remove-appledouble-metadata` at `9af90fc`; `main` at `cccbe09` merged in after PR #15 and PR #17 landed)
- **Latest verified commit:** `ab613f16ecbec0e3f774090de22f56dfe9cb9607` "Skip macOS AppleDouble files when AudioDirector loads narrative data"
- **Confirmed on GitHub:** `git ls-remote origin claude/audio-production` printed `ab613f1` at 19:52 UTC; this doc commit sits on top
- **Pull request:** #18 (draft) to `main`; PR #15 has merged
- **State:** finished; waits on the owner's listening review on the Mac

**Accomplished**
- The five tracks in `assets/audio/music/` play through `AudioDirector`, unmodified: main theme for the main menu, alternate theme for a cinematic, emotional theme for emotional scenes, narrative theme for exploration, credits theme for the ending. Details and the trigger events are in `docs/AUDIO.md` → Soundtrack.

**Files modified**
- `audio/cues.json`: five `mus_*` cues (levelled to about -20 LUFS with `volume_db`), `music_states.exploration`, `music_contexts` (`main_menu`, `cinematic`, `emotional`, `ending_credits`), exploration music for corridor and nursing station by day, events `music_main_menu`, `music_cinematic`, `music_emotional_begin`/`_end`, `music_credits`.
- `systems/audio/AudioDirector.gd`: music contexts (stacked, stop/duck ambience, play-once contexts end themselves), location music that fades out in rooms without a state, `loop_crossfade` and `tail_fade` + `repeat_after` repeats, context duck added to dialogue duck, `._*` skipped in `_load_narrative`.
- `scripts/ui/PauseMenu.gd`, `scenes/ui/PauseMenu.tscn`: Audio section with Master, Music, Dialogue, Sound effects and Ambience sliders and a reduce-startling-audio toggle, all through `AudioDirector.set_setting`. Panel is 200 px taller.
- `tools/audio/build_manifest.py`, `tests/qa/test_audio_manifest.py`: manifest also covers `assets/audio/`; references through music states and contexts; contexts validated.
- `audio/manifest.json`, `docs/AUDIO_MANIFEST.md`: five soundtrack entries (regenerated). `assets/audio/music/*.ogg.import`: committed import sidecars (`loop=false`).
- `tests/audio/TestAudio.gd`, `docs/AUDIO.md`.

**Unfinished**
- none in code. Nothing fires `music_main_menu`, `music_cinematic`, `music_emotional_begin`/`_end` or `music_credits` yet: there is no title screen, cinematic or credits scene, and no story beat is marked emotional.

**Known errors**
- none

**Tests** (on `ab613f1`)
- `python3 tests/qa/run.py --godot <4.7-stable linux, SHA-512 verified>` on `21cba85`: exit 0; QA_RESULT 19 passed / 0 failed / 0 skipped; sprint tests 80 passed / 0 failed; AUDIO_RESULT 271 passed / 0 failed (211 before); GLB validation 92 assets, 0 failures; Python content 6/6, audio manifest 3/3, music pipeline OK.
- `ab613f1` only adds the `._*` skip: `godot --headless --path . res://tests/audio/TestAudio.tscn` gave 271 passed / 0 failed, also with a planted `data/narrative/._probe.json`.
- CI: `validate` run 39063043515 passed on `f191570` (before the merge of `main`)
- Headless uses the Dummy audio driver: playback, timing, fades and ducks are checked, not how anything sounds.

**Dependencies not available to remote agents**
- Listening review of the mix, the loop crossfades and the exploration level needs the owner's Mac. `build_manifest.py` needs `soundfile`, `numpy`, `scipy` (`tools/audio/requirements.txt`).

**Next steps**
1. Owner: review PR #18; play the corridor by day and check the narrative theme sits under the ambience (`mus_narrative` `volume_db` in `audio/cues.json`).
2. Owner: record the soundtrack's authorship and licence; the manifest entries say it is still to be confirmed.
3. Whoever builds the title screen, cinematics, credits or an emotional story beat: fire the matching event from the table in `docs/AUDIO.md` → Soundtrack (for example `EventBus.narrative_event_fired.emit("music_main_menu", {})`), or call `AudioDirector.start_music_context`.
4. Optional: decide whether night exploration should get music; today night is deliberately silent.

**Notes for the other agent**
- Do not re-encode or normalize files in `assets/audio/music/`; change levels with `volume_db` in `audio/cues.json`. `music_main_theme.m4a` is an unused duplicate (Godot cannot import `.m4a`).
### 2026-10-17 19:45 UTC · Claude Code · Environment Stage 4b research wing

- **Branch:** `claude/environment-stage-4b` (from `claude/environment-stage-4` at `6e2fdf6`, then `main` at `66a274f` merged in)
- **Latest verified commit:** `90315575dd91f9fe8c8fd480b63c52309ed0c1cb` "Build Stage 4b research wing: 8 props, 12 rooms on the research level", plus merge `96b0f8b` of `main`
- **Confirmed on GitHub:** see `git ls-remote origin claude/environment-stage-4b`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- 8 research props (`assets/exports/research/props/`): reception counter, reclining assessment chair, lab bench, benchtop centrifuge, upright ultra-low freezer, dual-monitor workstation, server rack, whiteboard with wiped-marker residue.
- 12 rooms (`assets/exports/research/env/`) on the research level the restricted lift serves. It uses the same x/y as Chapter 1 with its floor at z = 0, and the lift sits at (0, 44) as below (asserted). Reception, a 12 m research corridor, a badge-and-PIN door at y = 28, and an 8 m restricted corridor. Rooms: physician offices A and B (B vacated), data analysis, records archive (one bay emptied), unsigned protocol office, clinical assessment room (one-way window into observation; clinician nearer the exit, asserted), observation and monitoring, lab support, secure sample storage (one unlabelled, double-locked freezer).
- Storytelling hooks carry `story_tag: research_inconsistency` and a `godot_hint` that describes only what the player sees. The protocol binder is `clinical_review_status: PENDING`.
- PR #14 merged at `bb4ecf7`, before the 4a facing fix (`400770b`, `6e2fdf6`). That fix reaches `main` through this branch.

**Files modified**
- New: `tools/blender/build_stage4_research.py`, `assets/blender/research/{FW_Props_Research,FW_ResearchWing}.blend`, exports and their `.import` files, `assets/renders/stage4/research_*.png`, `props_research.png`.
- `tools/blender/fw_assets.py` (Stage 4b section), `tools/blender/fw_lib.py` (8 palette materials), `assets/asset_manifest/asset_manifest.{json,md}` (112 records), `docs/ENVIRONMENT_STAGES.md`, `docs/ENVIRONMENT_PIPELINE.md`, `docs/PROJECT_STATUS.md`, this file.

**Unfinished**
- Not wired into gameplay: no level scene, and no lift transition between the security and research levels.
- Level placement, layout, the receptionist marker and every storytelling detail are assumptions for creative review. The GDD names no research staff, so no named markers.

**Known errors**
- Cycles previews show the one-way glass mirrored from both sides because Cycles renders back faces. Godot should cull them; not checked in Godot yet.

**Tests** (on the merged tree, before this doc commit)
- `python3 tests/qa/run.py` with Godot 4.7 (4.7.stable.official.5b4e0cb0f) after merging `main`: exit 0. Python content 6/6, audio manifest 3/3, `.glb` validation 112/112, TestRunner 80 / 0, TestQA 19 / 0 / 0, TestAudio 211 / 0, "All executed checks passed". The music `.ogg.import` files Godot generated were left uncommitted for the music workstream.
- `build_stage4_research.py` with Blender 5.0.1 (`bpy`): "STAGE4 RESEARCH OK: 8 props, 12 environments exported".

**Dependencies not available to remote agents**
- Mac-only checks (Forward+ look, one-way glass in Godot).

**Next steps**
1. Owner reviews and merges this PR.
2. Stage 5 historic asylum substructure, reached from the maintenance hatch (`MA_ServiceHatch`) and the lift's sublevels.
3. Gameplay: a lift transition between the security and research levels.

### 2026-10-17 19:30 UTC · Claude Code · CI fix: macOS AppleDouble files

- **Branch:** `claude/remove-appledouble-metadata` (based on `main` at `782f642`)
- **Latest verified commit:** `a0c00e8b97ee1d804d2ecb9484760b6f0b866483` "Remove macOS AppleDouble files and skip them in content QA"
- **Confirmed on GitHub:** `git ls-remote origin claude/remove-appledouble-metadata` printed `a0c00e8` at 19:28 UTC; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished

**Accomplished**
- `main` at `782f642` ("will music i think") tracked 583 `._*` AppleDouble files written by macOS on the exFAT SSD; `tests/qa/test_json.py` failed with `UnicodeDecodeError` on `data/patients/._PT-001.json`. All 583 untracked; every one had the AppleDouble magic and a genuine companion file, which is kept.

**Files modified**
- `.gitignore`: ignores `._*`, `.DS_Store`, `.AppleDouble`, `.Spotlight-V100`, `.Trashes`, `.fseventsd`, `__MACOSX/` and similar.
- `tests/qa/test_json.py`: `content_files()` skips `._*` and `__MACOSX`; UTF-8 reads; new tests for the skip rule and for no tracked macOS metadata.
- `tests/qa/test_audio_manifest.py`: same skip for `audio/` and `data/narrative/`.

**Unfinished**
- none

**Known errors**
- Runtime loaders that list folders (`systems/audio/AudioDirector.gd` `_load_narrative`, `tools/godot/validate_glb_imports.gd`) do not skip `._*`; on the exFAT drive untracked `._*.json` files would still reach them. Not changed here.

**Tests** (on `a0c00e8`)
- `GODOT=<4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py`: exit 0, QA_RESULT passed=19 failed=0 skipped=0, AUDIO_RESULT passed=211 failed=0, Python content 6/6 and audio 3/3 OK. Also passed with planted `._*` files in `data/patients`, `data/narrative` and `audio`.
- CI: not observed yet

**Dependencies not available to remote agents**
- none

**Next steps**
1. Owner: run `dot_clean -m .` in the project folder on the Mac (or keep the project on an APFS volume) so the files stop reappearing locally.
2. The headless import generated `.import` files for the five `assets/audio/music/*.ogg` tracks from `782f642`; they were not committed here. Commit them with the music workstream.

**Notes for the other agent**
- No PR #20 existed; the failure was on `main` itself, so the fix is on this branch per AGENTS.md §3.

### 2026-10-17 19:05 UTC · Claude Code · Stage 4a facing fix

- **Branch:** `claude/environment-stage-4` (PR #14)
- **Latest verified commit:** `400770b` "Fix facing of two terminals and the interview intercom in the security wing" (full SHA via `git log -1 400770b`)
- **State:** finished; this adds to the 18:45 entry below.

**Accomplished**
- `VS_Terminal_VisitorLog` and `MD_Terminal` now face their users, and `SI_Intercom` faces into the room. Only `ENV_VisitorScreening`, `ENV_MedicalDirectorOffice` and `ENV_SecureInterviewSuite` (plus the wing `.blend` and their renders) changed.

**Tests** (on `400770b`)
- `python3 tests/qa/run.py` with Godot 4.7: exit 0. 92/92 `.glb`, TestRunner 80/0, TestQA 19/0/0, TestAudio 211/0.

**Next steps**
- Unchanged from the 18:45 entry. Stage 4b research wing is on `claude/environment-stage-4b`, stacked on this branch.

### 2026-10-17 18:45 UTC · Claude Code · Environment Stage 4a security and admin wing

- **Branch:** `claude/environment-stage-4` (based on `main` at `6feaaa5`, which includes PR #13)
- **Latest verified commit:** `4180b3fa86a76065634587b47f7d42897f3be68b` "Build Stage 4a security and admin wing: 13 props, 11 rooms"
- **Confirmed on GitHub:** `git ls-remote origin claude/environment-stage-4` printed `4180b3f` at 18:43 UTC; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- 13 security and admin props (`assets/exports/security/props/`): security console, 3x2 video wall, key cabinet, staff lockers, walk-through detector, conference table, waiting seats, executive desk, badge printer, elevator doors (leaves `_Leaf_L/_R` with colliders), electrical panel, wall pipes, wall display.
- 11 rooms (`assets/exports/security/env/`) in the shared Chapter 1 frame, north of y = 20: security corridor with interlock doors at y = 32, visitor screening, credentialing, records office, medical director's office (Voss marker), conference room, secure interview suite (clinician seat nearer the exit, asserted), security control (Hale marker, window onto the corridor), surveillance monitoring, maintenance access (service hatch hinting at Stage 5), restricted lift lobby. Each has camera markers, collision and light markers.

**Files modified**
- New: `tools/blender/build_stage4_security_admin.py`, `assets/blender/security/{FW_Props_Security,FW_SecurityAdminWing}.blend`, the exports and their Godot `.import` files, `assets/renders/stage4/*.png`.
- `tools/blender/fw_assets.py` (Stage 4 section), `tools/blender/fw_lib.py` (10 palette materials), `tools/blender/build_stage2_chapter1.py` (`room_shell` optional `light_color`, default unchanged; Stage 2 not rebuilt).
- `assets/asset_manifest/asset_manifest.{json,md}`, `docs/ENVIRONMENT_STAGES.md`, `docs/ENVIRONMENT_PIPELINE.md`, `docs/PROJECT_STATUS.md`, this file.

**Unfinished**
- The floor plan and room adjacencies are assumptions (the GDD names the rooms, not a layout); labelled in `docs/ENVIRONMENT_STAGES.md`.
- The wing is not yet wired into gameplay (`data/world_chapter1.json`, `AuthoredWorld`); the clinical corridor's north end has no door into it yet.
- Stage 4b research wing not started.

**Known errors**
- none.

**Tests** (on `4180b3f`, plus this commit's doc-only changes)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f): exit 0. `.glb` validation 92/92, TestRunner 80 passed / 0 failed, TestQA 19 / 0 / 0, TestAudio 211 / 0, "All executed checks passed".
- `build_stage4_security_admin.py` with Blender 5.0.1 (`bpy`): "STAGE4 SECURITY OK: 13 props, 11 environments exported".
- CI: not observed yet; check the PR.

**Dependencies not available to remote agents**
- Mac-only checks (Forward+ look, walking the wing in play).

**Next steps**
1. Owner reviews and merges this PR.
2. Stage 4b research wing on a new branch from `main`: reception, clinical assessment, physician offices, lab support, secure sample storage, data analysis, research records archive, observation room, restricted corridor, the undisclosed protocol office. Keep it ordinary-looking, not overtly sinister.
3. Later: connect the clinical corridor's north end to the security corridor in gameplay.
4. Still open: close PRs #1, #6, #7 and #8, which are fully contained in `main`.

### 2026-10-17 18:35 UTC · Claude Code · Nursing-station equipment

- **Branch:** `claude/nursing-station-props` (based on `main` at `6742dc8`, which includes PR #12)
- **Latest verified commit:** `de77fe92e323cc998cb500aef2b8bff520ded842` "Place Stage 3 equipment at the nursing station"
- **Confirmed on GitHub:** `git ls-remote origin claude/nursing-station-props` printed `de77fe9` at 18:33 UTC; this doc commit sits on top
- **Pull request:** PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- `ENV_NursingStation` now holds `NS_MedicationCart` and `NS_SharpsBin` (west wall), plus `NS_CrashTrolley`, `NS_AED` and `NS_HandGel` (south wall). All are clear of the inward door swing (x -2.5..-1.5, y 8.5..9.5). Room bounds and existing node names are unchanged, so `data/world_chapter1.json` interactables (`NS_Terminal_EHR`, `NS_NoticeBoard`) still resolve.

**Files modified**
- `tools/blender/build_stage2_chapter1.py`: five `place()` calls in `build_nurse_station`.
- `assets/blender/clinical/FW_Chapter1_ClinicalWing.blend`, `assets/exports/clinical/env/ENV_NursingStation.glb`, `assets/asset_manifest/asset_manifest.json` (nursing-station record: materials, triangles), `assets/renders/stage2/{nursing_station,chapter1_plan}.png`.
- The rebuild also rewrote the corridor, interview-room and archive `.glb` files byte-wise with identical structure (as the integration entry observed); those were restored to the committed versions.
- `docs/ENVIRONMENT_STAGES.md`, `docs/PROJECT_STATUS.md` (environment rows), this file.

**Unfinished**
- The new items are geometry only: none is an interactable yet (no `data/world_chapter1.json` entries).
- The existing `CAM_NS_Establishing` render does not frame the south and west walls, so the new items show only in `chapter1_plan.png`.

**Known errors**
- none.

**Tests** (on `de77fe9`, plus this commit's doc-only changes)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f): exit 0. `.glb` validation 68/68 (`ENV_NursingStation`: 23 meshes, 11 colliders), TestRunner 80 passed / 0 failed, TestQA 19 / 0 / 0, TestAudio 211, "All executed checks passed".
- `tools/blender/build_stage2_chapter1.py` with Blender 5.0.1 (`bpy`): "STAGE2 OK: 7 environments exported".
- CI: not observed yet; check the PR.

**Dependencies not available to remote agents**
- Mac-only checks (Forward+ look, walking around the new trolley in play).

**Next steps**
1. Owner reviews and merges this PR.
2. Stage 4 (security, admin and research wings): new `tools/blender/build_stage4_*.py` on `claude/environment-stage-4` from `main`.
3. Optional: make `NS_MedicationCart` an interactable (locked drawer) once a medication-administration design is approved; it must not apply any clinical rule before psychiatrist review.
4. Still open: close PRs #1, #6, #7 and #8, which are fully contained in `main`.

### 2026-10-17 18:05 UTC · Claude Code · Environment Stage 3 props

- **Branch:** `claude/environment-stage-3` (based on `main` at `592c6af`)
- **Latest verified commit:** `5f5c51561ab139e22251bbce9869ec9a312b88a8` "Stop tracking the Blender backup FW_Modular_Kit.blend1"
- **Confirmed on GitHub:** `git ls-remote origin claude/environment-stage-3` printed `5f5c515` at 17:50 UTC; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- Environment Stage 3 is complete: 10 new library props for medication, ward beds, linen and emergency equipment (`PROP_Cart_Medication`, `PROP_Bed_Hospital_Adjustable`, `PROP_Trolley_Linen`, `PROP_Cart_Crash_Resus`, `PROP_Cabinet_AED_Wall`, `PROP_Cylinder_Oxygen_Trolley`, `PROP_Monitor_VitalSigns_Stand`, `PROP_Bin_Sharps`, `PROP_Dispenser_HandGel`, `PROP_Wheelchair`). Each has a `.blend` source, a `.glb` export, a manifest record (staff-only / supervised) and appears in a preview render.
- Removed the tracked `assets/blender/modular/FW_Modular_Kit.blend1` backup (follow-up 3 of the integration entry).

**Files modified**
- `tools/blender/fw_lib.py`: 5 palette materials (med-cart blue, sharps yellow, AED green, linen white, laundry-bag blue).
- `tools/blender/fw_assets.py`: `_castors` helper, 10 builders, `STAGE3_PROP_BUILDERS`. Existing builders unchanged.
- `tools/blender/build_stage3_props.py`: new generator writing `FW_Props_Clinical_Stage3.blend`, exports, manifest and `assets/renders/stage3/props_stage3.png`.
- `assets/exports/clinical/props/*.glb` (+ Godot `.import` files), `assets/asset_manifest/asset_manifest.{json,md}`: 10 new assets (68 total); no existing record changed.
- `docs/ENVIRONMENT_STAGES.md`, `docs/ENVIRONMENT_PIPELINE.md`, `docs/PROJECT_STATUS.md` (environment rows only), this file.

**Unfinished**
- The Stage 3 props are library assets only; none is placed in an `ENV_*` room or `scenes/world/Chapter1Ward.tscn` yet.

**Known errors**
- none.

**Tests** (on `5f5c515`, plus this commit's doc-only changes)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f, SHA-512 verified): exit 0. TestPharmacology 0 failures, TestQA 19 passed / 0 failed / 0 skipped, `.glb` validation 68/68, TestRunner 80 passed / 0 failed, TestAudio 211 passed, all Python suites OK, "All executed checks passed".
- Baseline on `main` `592c6af` before any change: same command, exit 0, 58/58 `.glb`, TestRunner 80/0, TestAudio 211.
- `tools/blender/build_stage3_props.py` with Blender 5.0.1 (`bpy`, Python 3.11): "STAGE3 PROPS OK: 10 assets exported".
- Render checked by eye in Cycles (CPU). Not evidence of the look in Forward+ on the Mac.
- CI: not observed yet; check the draft PR.

**Dependencies not available to remote agents**
- Mac-only checks (Forward+/Metal look of the new props). The `bpy` virtualenv used here is local to the container and not committed.

**Next steps**
1. Owner reviews and merges the Stage 3 draft PR.
2. Place the medication cart, crash trolley, AED cabinet and hand-gel dispenser at the nursing station: extend `build_stage2_chapter1.py` (`ENV_NursingStation`), rebuild, re-run `.glb` validation and `run.py`, and check `scenes/world/Chapter1Ward.tscn` still loads.
3. Stage 4 (security, admin and research wings): new `tools/blender/build_stage4_*.py` on a new `claude/environment-stage-4` branch from `main`.
4. Still open from earlier entries: close PRs #1, #6, #7 and #8, which are fully contained in `main`.

**Notes for the other agent**
- Do not rebuild the Stage 1 `.blend` just to pick up the new palette entries; Stage 1 assets do not use them.

### 2026-10-17 17:40 UTC · Claude Code · Sprints 1–3 integration

- **Branch:** `claude/integration-sprints-1-3` (based on `claude/chapter1-playable` at `b11f58c`, with `main` at `f6efda8` merged in)
- **Latest verified commit:** `99c2eaf453e13d44932f73a7c7f30ad54a18bf3e` "Merge main (audio PR #5) into the Sprints 1-3 integration branch"
- **Confirmed on GitHub:** `git ls-remote origin claude/integration-sprints-1-3` printed `99c2eaf` at 17:25 UTC; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- Checked every source branch with `git merge-base --is-ancestor`: `claude/chapter1-playable` already contained PRs #1, #8, #6, #9 and #10. Only `main`'s PR #5 (audio) was missing. Merged `origin/main` into a new branch from `claude/chapter1-playable`; no cherry-picks, no rewritten history.
- Compared every file on each source branch with the integrated tree. Nothing functional is missing; see `docs/INTEGRATION_SPRINTS_1_3.md` → Functionality check.

**Files modified**
- `README.md`: merge conflict resolved (integrated layout plus `main`'s audio, music AI and agent-rules entries).
- `docs/INTEGRATION_SPRINTS_1_3.md`: new. Branch provenance, conflict resolution, per-file preservation check, full test report, open items.
- `docs/PROJECT_STATUS.md`, `docs/AI_HANDOFF.md`: this branch's rows and entry.

**Unfinished**
- none in this branch.

**Known errors**
- none. Expected warnings come only from negative tests (save tamper, note validation, locked dialogue choice).

**Tests** (on `99c2eaf`)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f, SHA-512 verified): exit 0. JSON 4 OK, audio manifest 3 OK, music AI 3 OK, TestPharmacology 0 failures (8 cases), TestQA 19 passed / 0 failed / 0 skipped, `.glb` validation 58/58, TestRunner 80 passed / 0 failed, boot OK, TestAudio 211 passed, Ch1 audio sequence done.
- Blender 5.0.1 (`bpy`, Python 3.11) re-ran `tools/blender/build_stage1_modular.py`, `build_stage1_props.py`, `build_stage2_chapter1.py` in a scratch copy: STAGE1 OK 25, PROPS OK 26, STAGE2 OK 7; rebuilt exports pass `.glb` validation 58/58. 8 rebuilt `.glb` differ byte-wise from the committed ones with identical glTF structure; committed files left unchanged.
- CI: not observed yet; check the draft PR.

**Dependencies not available to remote agents**
- Mac-only checks (Forward+/Metal rendering, input feel, audio mix). ACE-Step and Stable Audio need the owner's Mac.

**Next steps**
1. Owner reviews and merges the integration draft PR into `main`.
2. After it merges, close PRs #1, #6, #7 and #8 (all fully contained). PRs #9 and #10 are already closed.
3. Follow-up: remove the tracked `assets/blender/modular/FW_Modular_Kit.blend1` backup (now gitignored).
4. Next feature work branches from `main` after the merge, in the `scripts/` layout.

**Notes for the other agent**
- `claude/environment-production` was still at `e321b4a` when this branch was built. If that session pushes more, merge `origin/claude/environment-production` into a continuation branch from this one rather than into the old PRs.
- Do not reintroduce `autoload/`, `staging/` or `main`'s old demo `scenes/main/Main.gd`.

### 2026-10-17 · Claude Code · Sprint 3 story, evidence board, shift loop

- **Branch:** `claude/sprint-03-evidence-shift` (based on `claude/sprint-02-ehr-interview` at `0f36185`)
- **Latest verified commit:** the commit carrying this entry; `git ls-remote origin claude/sprint-03-evidence-shift`
- **Pull request:** draft, stacked on #9 (merge order #8, #6, #7, #9, then this PR)
- **State:** finished; imports and passes every suite

**Accomplished**
- The Chapter 1 slice plays from start to finish:
  1. Bennett handover (audio scene and subtitles).
  2. Interview Elias, document, act.
  3. Collect the transfer summary and roster, link them on the evidence board, argue the hypothesis.
  4. Sign out at the handover board; a documented handover earns Bennett's trust.
  5. Night shift; 15 minutes later the intercom calls W-Zero-B and the EHR logs a transfer request under an inactive credential.
  6. Read the W0-B door log; a trusted Bennett corroborates it.
  7. Sign out for the night; the end summary appears.
- None of these steps blocks progress, and every one survives save and load.

**Files modified**
- New:
  - `scripts/narrative/StoryLogic.gd`: closed condition and action vocabulary, validated.
  - `scripts/narrative/ChapterDirector.gd`.
  - `data/story_chapter1.json`.
  - `scripts/ui/EvidenceBoard.gd` and `scenes/ui/EvidenceBoard.tscn`.
  - `scripts/world/AudioZoneTracker.gd`.
  - `scripts/tests/test_sprint3.gd`.
- `scripts/main/Main.gd`:
  - evidence panel and Tab handling;
  - director and audio tracker nodes;
  - `_silence_audio` on exit;
  - graceful quit on window close (`auto_accept_quit` false while Main lives).
- `scenes/main/Main.tscn`: EvidenceBoard, ChapterDirector and AudioZoneTracker nodes.
- `scripts/ui/PauseMenu.gd`: Quit uses the same graceful path.
- `scripts/ui/HUD.gd`: objective and subtitle labels.
- `scripts/autoload/EventBus.gd`: `objective_changed`, `story_beat_fired`, `shift_signout_requested`, `chapter_completed`.
- `scripts/autoload/EvidenceManager.gd`: `get_verifications`; verifications deduped per method.
- `scripts/autoload/PatientManager.gd`: `add_chart_entry` (audit only).
- `scripts/world/{Character,ImportedInteractable}.gd`: situational staff lines; `shift_signout` type.
- Content layer and data:
  - `scripts/content/*` and `ContentRegistry.gd`: story schema and validation;
  - world `audio_zones`;
  - `data/world_chapter1.json`: handover board and audio zones.

**Unfinished**
- GDD beat 4 (second stable patient hinting at a missing clinician) needs a second authored patient.
- Only the `corridor` and `nursing_station` audio locations exist; other rooms fall back to the corridor.
- Story lines are `[Placeholder]`.

**Known errors**
- none.
- Headless runs no longer start ambience. A stream still playing at quit was reported as `ERROR: resources still in use`, which run.py treats as a failure.

**Tests** (on this branch)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: exit 0.
  - TestQA: 19/0/0.
  - GLB validation: 58 assets.
  - TestRunner: 80 passed.
  - TestAudio: 92 passed.
  - Ch1 audio sequence: done.
- CI: not observed.

**Next steps**
1. Act I completion: author a second patient (GDD beat 4) in `data/patients.json` and `data/dialogue.json` (dialogue then needs one document per patient; `ContentRegistry` indexes a single dialogue file today), plus a Voss orientation beat (beat 1).
2. Environment Stage 3/4 on `claude/environment-production`: medication room, a second interview room, security control, plus character stand-in meshes better than capsules.
3. Pharmacology in the EHR as governed rules (needs approval records per rule).

### 2026-10-17 · Claude Code · Sprint 2 EHR and interview

- **Branch:** `claude/sprint-02-ehr-interview` (based on `claude/chapter1-playable` at `7b11143`)
- **Latest verified commit:** the commit carrying this entry; `git ls-remote origin claude/sprint-02-ehr-interview`
- **Pull request:** #9 (draft, stacked on #7; merge order #8, #6, #7, #9)
- **State:** finished; imports and passes every suite

**Accomplished**
- The GDD §13 MVP loop is playable end to end in the Blender-built wing:
  1. Interview Elias with the `CAM_IR_*` cameras, using typed or structured questions.
  2. Questions record the findings with provenance.
  3. Open the EHR (terminal or J) and save a structured note.
  4. Commit a clinical action through ClinicalRules; the chart updates deterministically.
  5. Save and load.

**Files modified**
- `scripts/ui/EHRScreen.gd`, `scripts/ui/InterviewScreen.gd`, `scripts/ui/UIStyle.gd`, and both `.tscn` files: new.
- `scripts/main/Main.gd`: panel routing (info / interview / ehr); Esc closes the topmost panel; J toggles the EHR.
- `scripts/autoload/PatientManager.gd`: `save_note`/`get_notes`, `perform_action`, `action_event_id`; review flags in the audit trail.
- `scripts/autoload/DialogueManager.gd`: `records_observations`, `last_recorded_observations`, `QUESTION_MINUTES`.
- `scripts/autoload/TimeManager.gd`: `format_minutes`.
- `scripts/autoload/EventBus.gd`: `patient_note_saved`.
- `scripts/content/*` and `scripts/autoload/ContentRegistry.gd`:
  - schema for `actions` and `records_observations`;
  - reference checks;
  - `get_actions`/`get_action`.
- `data/clinical_rules.json`: two actions and one new PENDING placeholder rule.
- `data/dialogue.json`: `records_observations` on two choices.
- `scripts/world/{Character,WorldActions,ImportedInteractable,Terminal}.gd`: patients open the interview; terminals open the EHR.

**Unfinished**
- No MAR/medication tab; PharmacologyEngine is still not used in play.
- The close-up and reverse interview shots are unused (capsule stand-ins).

**Known errors**
- none. Expected warnings come from negative tests.

**Tests** (on this branch)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: exit 0.
  - TestQA: 19/0/0.
  - GLB validation: 58 assets.
  - TestRunner: 62 passed.
  - TestAudio: 92 passed.
  - Ch1 audio sequence: done.
- CI: not observed.

**Next steps**
1. Sprint 3 on a new branch from this one:
   - evidence board UI (link and pin clues, hypotheses);
   - shift sign-in/sign-out loop;
   - Bennett trust effects;
   - the after-hours W0-B intercom beat and the disputed EHR transfer entry (GDD §12 beat 6).
2. Owner: review the new authored clinical wording listed in PR #9.

### 2026-10-17 · Claude Code · Chapter 1 playable

- **Branch:** `claude/chapter1-playable` (sprint 1 + PR #6, now with `claude/integrate-sprint-01` merged in)
- **Latest verified commit:** the merge commit this entry is part of (a file cannot hold its own SHA); `git ls-remote origin claude/chapter1-playable`
- **Pull request:** #7 (draft)
- **State:** finished; imports and passes every suite

**Accomplished**
- Merged the integration branch (PR #8) so PR #7 sits on top of `main`'s QA, audio and pharmacology. Conflicts were only `.gitignore` and the autoload list in `project.godot`; both sides kept (`WorldStateManager` precedes `GameState`).
- `tests/qa/run.py` now also runs `tools/godot/validate_glb_imports.gd`.

**Tests**
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: exit 0. TestPharmacology 0 failures, TestQA 19/0/0, GLB validation 58 assets 0 failures, TestRunner 46 passed / 0 failed, boot OK, TestAudio 92 passed, Ch1 audio sequence done.
- CI: not observed.

**Next steps**
1. Owner merges PR #8, then PR #6, then PR #7 (in that order; PR #7 contains both).
2. Sprint 2 on `claude/sprint-02-ehr-interview` from this branch.

### 2026-10-17 · Claude Code · Sprint 1 integration

- **Branch:** `claude/integrate-sprint-01` (based on `main` at `91ad354`)
- **Latest verified commit:** `8ca85bce79f08f19ce75e00c33502a4e4af14146` "Merge sprint-01 foundation into main's QA, audio and pharmacology". This entry's doc commit sits on top.
- **Confirmed on GitHub:** check with `git ls-remote origin claude/integrate-sprint-01`
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- Executed the integration plan from `docs/PROJECT_STATUS.md`: PR #1 merged into `main` on its own branch, every `main` suite kept green, and the Sprint 1 suite added to the runner.

**Files modified**
- `project.godot`: Sprint 1 autoloads, then `GameState`, `PharmacologyEngine`, `AudioDirector` (in that order; GameState needs TimeManager and SaveManager).
- `scripts/autoload/EventBus.gd`: added `shift_started`/`shift_ended`, pharmacology, legacy progress and narrative/audio signals. `autoload/EventBus.gd` removed.
- `scripts/autoload/GameState.gd` (moved from `autoload/`): `day`/`shift` are getters on TimeManager; `start_shift`/`advance_shift` call `TimeManager.jump_to_shift`/`advance_to_next_shift`; saved as SaveManager provider `game_state`; `to_dict`/`from_dict`/`save_game`/`load_game` kept.
- `scripts/autoload/TimeManager.gd`: `get_shift_day`, `shift_day_for`, `advance_to_next_shift`, `jump_to_shift`; emits `shift_ended`/`shift_started` on shift boundaries.
- `scripts/autoload/Settings.gd`: volume keys removed (AudioDirector owns them).
- `scripts/main/Main.gd`: prints `[The Forensic Ward] Boot OK (content valid|INVALID)`.
- `systems/pharmacology/**`, `data/drugs`, `data/patients`, `tests/TestPharmacology.*`, `docs/PHARMACOLOGY_ENGINE.md`: kept from `main`; `staging/` removed.
- `tests/qa/TestQA.gd`: demo-HUD checks and both SKIPs replaced by checks against the real Main (content valid, player control, forward movement, interactables, door interaction reaches EventBus, shift progression through TimeManager).
- `tests/qa/run.py`: requires `skipped=0`; runs `res://scripts/tests/TestRunner.tscn` and requires `PASSED: N passed, 0 failed`.
- `docs/TESTING.md`, `docs/PROJECT_STATUS.md`, this file.

**Unfinished**
- No gameplay path calls PharmacologyEngine yet (Sprint 2 `ClinicalRules` integration).
- `claude/chapter1-playable` (PR #7) still needs this branch merged in.

**Known errors**
- none. One expected `WARNING: SaveManager: slot 99: checksum mismatch` comes from the tamper test.

**Tests** (on `8ca85bc`)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: exit 0. JSON and audio-manifest checks OK, TestPharmacology 0 failures, TestQA 19 passed / 0 failed / 0 skipped, TestRunner 43 passed / 0 failed, boot OK, TestAudio 92 passed, Ch1 audio sequence done.
- CI: not observed yet; check the draft PR.

**Dependencies not available to remote agents**
- Mac-only checks (rendering, input feel, audio mix).

**Next steps**
1. Owner reviews and merges the integration draft PR; then close PR #1.
2. Merge this branch into `claude/chapter1-playable` and update PR #7.
3. Sprint 2 on a new branch: EHR UI, cinematic interview UI, observation capture.

**Notes for the other agent**
- Audio workstream: `AudioDirector` is unchanged; `GameState.shift` and `EventBus.shift_started` behave as before, but the clock is TimeManager's now.
- Do not reintroduce `autoload/EventBus.gd`; the one EventBus is `scripts/autoload/EventBus.gd`.

### 2026-10-17 15:40 UTC · Claude Code · Handoff system

- **Branch:** `claude/ai-handoff-system` (based on `main` at `8e64eaf`)
- **Latest verified commit:** `8e64eafb7ef7e8a68153852f97807eaee576dae4` "Merge pull request #3 from biancaalexis132-png/claude/quirky-ptolemy-6j16b7". This branch adds one documentation commit on top.
- **Confirmed on GitHub:** `git ls-remote origin` at 15:20 UTC showed `main` at `8e64eaf`, `claude/sprint-01-foundation` at `f626aad`, `codex/sprint-01-tests` at `d1d7479`, `claude/quirky-ptolemy-6j16b7` at `c58efc9`. `claude/audio-production` and `claude/environment-production` did not exist yet.
- **Pull request:** draft PR from `claude/ai-handoff-system` to `main`
- **State:** finished; documentation only, no game code changed

**Accomplished**
- Added the shared rules file, the Claude pointer, the status board and this handoff log.

**Files modified**
- `AGENTS.md`: new. Shared rules for Claude and Codex: read order, Godot 4.7 conventions, branch policy, test commands, asset standards, clinical governance, handoff protocol.
- `CLAUDE.md`: new. Points Claude Code to `AGENTS.md`; adds only Claude-specific notes.
- `docs/PROJECT_STATUS.md`: new. Every branch and system with status and evidence, blockers, PR #1 integration risks.
- `docs/AI_HANDOFF.md`: new. This file.

**Unfinished**
- none

**Known errors**
- none in this change. Separately, PR #1 conflicts with `main` (`project.godot`, `autoload/EventBus.gd`); see `docs/PROJECT_STATUS.md` → Integration risks.

**Tests**
- On `main` at `8e64eaf`: `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f, SHA-512 verified) passed: both JSON checks OK, TestPharmacology 0 failures, QA 16 passed / 0 failed / 2 skipped, TestAudio 92 passed, Ch1 sequence done, boot OK.
- On `claude/sprint-01-foundation` at `f626aad`: `godot --headless --path . res://scripts/tests/TestRunner.tscn` gave 43 passed, 0 failed, exit 0.
- CI: run 39043906579 on `main` at `8e64eaf` succeeded. This PR adds only Markdown; its CI run should be checked on the PR.

**Dependencies not available to remote agents**
- none for this change. For other workstreams: Kokoro model files in `tools/audio/models/` (ignored, download per `tools/audio/requirements.txt` and the audio session's notes); ACE-Step and Stable Audio need the owner's Mac; Mac rendering and input checks need the owner.

**Next steps**
1. Owner reviews and merges this PR so `AGENTS.md` is on `main` and every new branch inherits it.
2. Audio and environment sessions: at your first push, replace your row's "none pushed yet" with the full SHA, list your claimed paths, and add a log entry using the template.
3. Owner decides the PR #1 integration plan in `docs/PROJECT_STATUS.md`. Then one agent runs it on `claude/integrate-sprint-01` from `main`, and records it here.
4. After PR #1 lands, move `docs/clinical_review_log.md` and `docs/design/` references in `AGENTS.md` from "on the foundation branch" to plain paths.

**Notes for the other agent**
- No `CLAUDE.md` or `AGENTS.md` existed on any branch before this; established decisions were taken from `README.md`, `docs/TESTING.md`, `docs/SPRINT_01.md`, `docs/design/*`, `docs/clinical_review_log.md` and `staging/README.md`, which are unchanged.
- The owner merges to `main`. Do not merge, push to `main` or enable auto-merge.
