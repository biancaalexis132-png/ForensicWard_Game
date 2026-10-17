# AI session handoff (living document)

Updated 2026-10-17 · Codex · protagonist specification and save QA.

## Objective and last completed milestone

Continued the existing game without redesigning foundations. Reconciled main, delivered a phased protagonist specification, and completed four independent save-compatibility regression tests. Full development QA passed. No creator, personality system, clinical effect, visual asset, runtime or save schema change was implemented.

## Repository and remote checkpoint

- Branch: `codex/protagonist-foundation-cont-1`, based on verified `origin/main` `fb078877c59273c0856ec29f29e4ae43d3fc3125` (PR #28 merge).
- Latest verified implementation commit: `01739ff70136d191704b694fbf32d6b9e28ee26d` “Guard save rejection and optional provider compatibility”; pushed, and `git ls-remote origin refs/heads/codex/protagonist-foundation-cont-1` returned that exact SHA. A documentation-only final checkpoint follows it; resolve the final remote tip with the same command.
- Prior checkpoint `2d30785b3394d7faf5fc5826bf8a460e0a591277` contains reconciliation and proposal.
- PR: **not created**. `gh pr create --draft --base main --head codex/protagonist-foundation-cont-1 --title ... --body-file /workspace/protagonist-foundation-pr.md` failed: `Post "https://api.github.com/graphql": Forbidden`. REST listing also fails; direct API CONNECT is denied with 403. Current open PRs/reviews and hosted CI remain unverified.
- F0 #20, F1 #21, F2 #26 and visual review #28 are merged. No merge or push to main was performed.
- Historical soundtrack PR #27 (`claude/ashcroft-soundtrack`) and off-repository Stage 6 environment thread remain coordination reservations. Pull refs exist but do not establish open status. No overlap with their files.
- Working tree after import cleanup: intended changes committed; generated reference `.import` companions removed because absent at clean baseline; ignored `.godot/` retained. No pre-existing changes were present.

## Files and workstream ownership

Created `docs/REPOSITORY_RECONCILIATION.md`, `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`, `scripts/tests/test_save_compatibility.gd` and `.uid`. Updated `docs/PROJECT_STATUS.md`, `docs/AI_PROGRESS_TRACKER.md`, `docs/design/GDD_AMENDMENTS.md`, this file and append-only `docs/AI_HANDOFF.md`. These are the only changed paths versus main. Claim is complete, awaiting review; do not take audio/environment/character-model ownership from this entry.

## Technical findings and decisions

Actual runtime save version is 3 with v1→v2 chapter and v2→v3 zone migrations. ContentRegistry owns the immutable campaign catalog, not a separate `campaign` save provider (the historical F1 proposal differs). Keep the existing provider/checksum architecture. New tests prove rejected files preserve current providers, seed and successful-load events, added providers reset when absent, real legacy fixtures remain compatible, and added provider state round-trips/resets.

Owner-approved requirements are recorded in GDD amendments: fixed psychiatrist role, customizable professional/appearance background, moderate personal life, emergent personality and equal essential care/evidence/outcome access. The proposed provider, v4 migration, catalog, UI and callback design are **not approved implementation**. P1 is the next review gate.

## Validation

From `/workspace/ForensicWard_Game`:

`python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`

- Baseline on `fb07887`: exit 0; Python 6+3+3 passed; pharmacology 0 failures; QA 19/0/0; GLB 138/138; TestRunner 112/0; main boot OK; audio 271/0; complete Chapter 1 sequence.
- Development tree matching `01739ff` (only later docs changed): exit 0; same checks, TestRunner **116 passed / 0 failed**. `CH1_SEQUENCE_DONE` and `All executed checks passed` observed. New test file was unchanged between run and commit. Four new tests include five rejection variants.
- `git diff --check` passed. Test slot 99 and isolated temporary XDG directories used by the standard runner. No real saves touched.
- Initial system-Godot run failed the version gate (4.6.3); corrected by SHA-512-verified official 4.7 install. It is not an unresolved test failure.
- Expected rejection/tamper warnings occur in negative tests; Python mock-server socket ResourceWarnings are non-fatal. No unexplained failures or skipped checks.
- Local logs `/tmp/forensic-ward-qa.log` and `/tmp/forensic-ward-development-qa.log` are not GitHub artifacts. Hosted CI not observed. Mac Forward+/Metal appearance, input, listening and memory/frame time remain untested.

## Cloud setup

Godot 4.7 standard lives outside checkout at `/workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`; system `godot` is 4.6.3 and must not be used. Python/ffmpeg already available. No persistent server is needed. Installation/QA script and startup instructions were saved in the environment draft; additive custom network domain `api.github.com` was saved, preserving package-manager presets. Saving does not apply runtime changes or publish. Review/save environment settings and publish through the UI, then retry PR access using existing authentication before considering credential requirements. No token is requested.

## Blockers and owner approvals

- The private v1.1 design-bible/clinical package is unavailable here and absent from Git. Available GDD DOCX, engineering contract, character PDF, reference guides and current code/data were inspected; missing canon was not reconstructed.
- Visual D1–D9 remain open: Rahman role, Hale title, written casting, Ward Zero date/signatory, 02:17 link, Mara voice, station layout, superseded boards and committing the bible.
- F0 C2 Concordance/chapter titles, C6 Bleed, C7 pharmacology clue gates, C11 original music export and precise anomaly mechanism remain unresolved. Pending clinical content remains pending. F3 is not implemented.
- Next substantial change needs owner review of `PROTAGONIST_CUSTOMIZATION_PLAN.md`, specifically P1 catalog/schema and pure validator scope. Fixed psychiatrist role/moderate personal life/emergent personality are already approved and should not be re-asked.

## Exact next steps

1. Read AGENTS.md, CLAUDE.md, current status/progress, reconciliation, proposal and newest append-only handoff. Fetch origin and compare this branch/main; do not reset or rewrite pushed commits.
2. Once API domain access is applied, retry `gh pr list --state open`, inspect relevant reviews, then open a **draft** PR from this branch to main with the prepared description (local `/workspace/protagonist-foundation-pr.md`, or reconstruct from this handoff and committed changes). Recheck PR state before creating a duplicate. Do not merge.
3. Obtain owner approval for P1. After approval, implement only immutable option schema and pure profile validation with synthetic test fixtures; no creator UI, save version bump, personality scoring, casting changes or new clinical/narrative canon in P1.
4. For later P2, capture real v3 save before adding a provider, implement explicit v3→v4 migration and test full v1/v2/v3 compatibility. Follow the plan’s small PR sequence, maintaining clinical independence and equal mandatory access.
5. Before any environment/audio/visual task, verify the reserved external workstreams. Request the actual missing bible through the owner’s normal file workflow before relying on it. Mac checks require the owner’s hardware.
