# AI session handoff (living document)

Updated 2026-10-17 · Codex · immediate owner-requested continuity checkpoint.

## Current objective and exact stopping point

Complete authorized P1 validation, record D1–D3 character canon and reference regeneration, propose Chapter 1 opening alignment and compare the Elias screenplay **summary**. Current code/proposals are written; full combined QA and image generation/correction are still running. No Chapter 1 content/rules/beat timing or save version has been changed. Before any new substantial task, this checkpoint is being committed/pushed with permanent shared continuity rules.

## Branch and verified checkpoints

- Active branch: `codex/character-canon-opening-cont-1`, stacked on `codex/protagonist-schema-p1`; current pre-checkpoint HEAD `16b9761d8528f807caa8f10d76fcfeb9db7b5683`.
- Latest verified remote P1 commit: `16b9761d8528f807caa8f10d76fcfeb9db7b5683`, pushed to `codex/protagonist-schema-p1`, confirmed by `git ls-remote`.
- Main fetched at `dd247bed93fca9bb95cbf2864eae964975358c23` (PR #29 merged the earlier proposal/save tests).
- Owner-confirmed PR #27 conflicts were resolved against that main. Original `claude/ashcroft-soundtrack` was fast-forward updated and verified at **`412b5010c8ccd8ba0e19e983b4346b5d90482d34`**. No agent merge or push to main. PR link: https://github.com/biancaalexis132-png/ForensicWard_Game/pull/27.
- New P1/canon PRs are not created; current enforced network policy blocks `api.github.com` (CONNECT 403), although Git fetch/push works. Domain requirement is already saved in environment draft, not applied. Do not request a duplicate token or bypass proxy.

## Last completed milestones

1. PR #27 continuity conflicts combined without losing either workstream; preserved pushed history. A timing-sensitive existing audio test was diagnosed (3.4s sound took up to 3.804s to free) and changed to a bounded actual-player cleanup wait, retaining leak assertions. Full QA on `7feb43e` passed: Python 6+3+3, pharmacology 0 failures, QA 19/0/0, GLB 138/138, TestRunner 112/0, boot OK, audio 334/0 and complete Chapter 1 playback. Main then gained four save tests/docs via #29; combined TestRunner passed 116/0 on `f59da08`.
2. P1 modules, synthetic fixtures and 15 tests are committed/pushed at `16b9761`. Import passed and TestRunner **131 passed / 0 failed**. Pure creation-draft/catalog validation only: no authored options, ContentRegistry hook, provider, creator UI, personality system or save-schema change.
3. D1–D3 canon and two comparison proposals are drafted locally. Voice metadata changes only Rahman's direction from Clinical pharmacist to Consultant psychiatrist; all voice/line IDs, speed/language/FX/recordings unchanged. Hale staff title already correct; Rahman is absent from staff data and no speculative record is added.

## Files changed / work in progress

P1 pushed files: `scripts/protagonist/{ProtagonistSchemas,ProtagonistValidator}.gd` + UIDs, `scripts/tests/test_protagonist.gd` + UID, `scripts/tests/fixtures/protagonist/*`, `docs/design/PROTAGONIST_INPUT_CONTRACT.md`, proposal/ID/continuity updates.

Current uncommitted canon/proposal work (to commit next): `audio/voice_profiles.json`, reference README; `docs/design/GDD_AMENDMENTS.md`, `VISUAL_PRODUCTION_REVIEW.md`; new `CHARACTER_VISUAL_CANON.md`, `CHARACTER_REFERENCE_REGENERATION.md`, `CHAPTER1_OPENING_ALIGNMENT.md`, `ELIAS_EVALUATION_DRAFT_COMPARISON.md`; owner decision record under `docs/design/decisions/`; new ignored-for-Godot candidate reference folder. Original artwork/PDF/GDD binaries remain unchanged. Generated `.import` companions under reference folders are tool outputs absent at the initial baseline; clean only those untracked outputs before final commit. Never delete existing tracked imports.

Shared continuity addition now prepared: `AGENTS.md` §9 and the explicit both-agent scope sentence in `CLAUDE.md`; this preserves prior rules and requires checkpointing after each significant milestone.

## Running validations and reference generation

- Full combined command from repo root: `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`; running, log `/tmp/forensic-p1-canon-final-qa.log`, shell session 21770. Do not claim completion until exit status and final runner marker are verified.
- A clean isolated opening probe confirmed `clue_access` can fire `ch1_w0b_unease` on day shift with zero Elias observations/notes. This is event-gating evidence, not a manual playthrough. Probe/log are local `/tmp/forensic-opening-probe.gd` and `.log`; final deferred teardown is clean.
- Generated Bennett reference candidate is local `/workspace/generated_images/exec-446a72d7-2b17-48c0-a999-f6779616a27b.png`; original source remains in Git. Other candidates are generating via tool cell 109. Voss and Elias initial outputs introduced unsupported height/biographical or DOB/prop text; corrective edits are running in cell 117. Do not promote those initial outputs as approved canon or copy them as final candidates.
- Prompts are local `/workspace/character-generation-prompts.json` and `/workspace/character-correction-prompts.json`. Before finishing, copy inspected final candidates, exact prompts and a hash/provenance manifest into `assets/creative_references/Visual_References/Individual_Characters/Regenerated_2026_10_17/` (has `.gdignore`). Keep original generated files in place. Candidate faces/geometry are not final casting or riggable models. Record unresolved details and visual review limitations honestly.

## Owner decisions and missing resources

D1 **Consultant Psychiatrist** for Rahman; D2 **Security Director** for Hale; D3 written guide authority, including Bennett Black woman/Rahman South Asian woman, are explicitly approved by the owner’s pasted file. **D4–D9 stay unresolved**, including Mara voice and missing v1.1 bible. No new clinical rule is approved. Fixed psychiatrist protagonist, moderate personal life and emergent personality remain approved requirements; later implementation phases are separate scopes.

The owner approved a realistic first 20–25 minutes (arrival, Bennett handoff, substantial Elias clinical encounter, small administrative discrepancy, subtle infrastructure inconsistency), explicitly **not** overwriting the current chapter. Existing late-shift intercom day 1 + night + 15 in-game minutes, `pt_elias_ward`, beat IDs and review flags must remain.

The owner confirmed the full Elias screenplay is currently in ChatGPT, not in the repository/PR, and will be supplied standalone. Continue the requirements/approval mapping now; defer line-by-line review until supplied. Do not infer approved exam findings, refusal or normal suicide-risk findings from silence, and never causally link symptoms to the supernatural.

Private v1.1 bible is unavailable; do not reconstruct it. Mac rendering/input/listening/frame time and optional generation dependencies remain untested. Hosted CI unobserved. Related soundtrack/environment/Stage 6 owners retain their files; this workstream edits no scene, zone, clinical rule or Chapter 1 dialogue/data file.

## Exact next steps

1. Verify this checkpoint push via `git ls-remote origin refs/heads/codex/character-canon-opening-cont-1`; record actual remote SHA. Commit/push the existing coherent canon/proposal files next, explicitly marking tests/candidates pending.
2. Poll shell session 21770 or inspect `/tmp/forensic-p1-canon-final-qa.log`; require exit 0 and `All executed checks passed`. Diagnose any failure without disabling assertions. P1 import/TestRunner already passed 131/0.
3. Finish/inspect reference generation and corrections, preserve old art, copy only reviewed candidates with exact prompt/hash manifest. Mark unapproved faces/details and D4–D9 clearly. No 3D production or automatic scene replacement.
4. Finalize the canon/opening/Elias comparison docs and checkpoint all four continuity files after the validation/image milestone. The full screenplay line review waits for the owner's standalone file.
5. Fetch main before final push, detect newer merges, resolve only supported conflicts while preserving history and current work. Push feature branches, verify exact SHAs; create draft PRs only if API access is applied. Never push main or auto-merge.
6. End with the owner's CODEX SESSION HANDOFF fields. P2 persistence/provider and actual opening/clinical implementation remain separate review tasks; do not silently start a major rewrite.

## Canon documentation milestone

D1–D3 specification, historical-review addendum, clear voice-role correction, preserved old-portrait notice and per-character regeneration briefs are complete as documentation. Opening/Elias comparisons are written; full screenplay is explicitly off-repository and pending. These files are now being committed/pushed; candidate images/manifest and final QA remain in progress. A pending clinical-review-log entry records the summary without changing existing flags. No next implementation task is started.
