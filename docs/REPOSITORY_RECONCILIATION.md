# Repository reconciliation — Codex continuation, 2026-10-17

## Verified repository state

Baseline `origin/main`: **`fb078877c59273c0856ec29f29e4ae43d3fc3125`**, confirmed with fetch and `git ls-remote origin HEAD`. Continuation branch: `codex/protagonist-foundation-cont-1`. Existing checkout reused; no worktree or history rewrite.

| Work | Git evidence | Meaning |
|---|---|---|
| F0 | PR #20 merge `33b2e8c` | Audit is merged; historical audit inventory is not current implementation status |
| F1 | PR #21 merge `4987123`, implementation `fa098c9` | Five-chapter catalog, chapter-scoped state, v1→v2 migration present |
| F2 | PR #26 merge `9558c77`, implementation `fb9fc52` | Zone transitions, per-zone objects, v2→v3 migration present |
| Reference integrations | PRs #22/#23/#24, then continuity #25 | Guides, boards, music reference files and protocol present |
| Visual review | PR #28 merge `fb07887` | Review and continuity docs are on main; recommendations remain proposals |

Current runtime `SAVE_VERSION = 3`; checksum precedes migration. `campaign` state is owned by ContentRegistry; `chapter` by ChapterDirector; `zones` by ZoneDirector; `world` by Main. Sorted provider load order and missing-provider reset support extension without replacing save architecture. F1 fixtures cover chapters 2–5; shipped later chapters remain planned. Main-scene boot, patient/evidence/trust/interview systems, imported environment geometry and audio passed baseline checks. This is no claim of completed five-chapter gameplay or medical validation.

## PRs, branches and ownership

Git fetch succeeds. Remote branches and pull refs were listed through Git. GitHub GraphQL and REST API calls fail; a direct API request fails the proxy CONNECT with HTTP 403. The active network policy does not list `api.github.com`. Thus current open/closed PR state, review comments and hosted CI cannot be verified. Pull refs do not establish a PR is open.

Historical living handoff mentions soundtrack PR #27 (`claude/ashcroft-soundtrack`, remote head `412a429a6e717ea00c96d2a9b8ad1987b82c7a58`) and an off-repository Stage 6 environment thread. Both remain coordination reservations until current status is checked. This workstream does not alter audio, models, Stage 6, zone architecture or character casting. F2’s active-workstream row was removed because its commit is merged; its append-only historical entries are preserved.

Claimed work: protagonist proposal, explicit canon amendments, reconciliation and continuity documents; new independent save test file plus UID. No new parallel agent work was started. No source/scene/data changes are needed for the selected test task.

## Baseline evidence

Command, from repository root:

```sh
python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64
```

On baseline SHA above: **exit 0**, runner completed with `All executed checks passed`.

| Check | Outcome |
|---|---|
| Python JSON/content | 6 passed |
| Python audio manifest | 3 passed |
| Python music client against mock server | 3 passed, no skips; non-fatal socket ResourceWarnings |
| Engine/version/import | Official 4.7 stable; SHA-512 verified; import passed |
| Pharmacology | 0 failures (runner completion marker) |
| TestQA | 19 passed / 0 failed / 0 skipped |
| GLB imports | 138 assets, 0 failures |
| TestRunner | 112 passed / 0 failed |
| Main-scene smoke | Boot OK, 60 frames |
| Audio | 271 passed / 0 failed |
| Chapter 1 audio sequence | Expected ordered beats and `CH1_SEQUENCE_DONE` at 61.8s |

System `/usr/local/bin/godot` is 4.6.3; the initial run correctly rejected its version after passing Python checks. Official 4.7 was installed outside checkout; no project version downgrade. Local baseline log `/tmp/forensic-ward-qa.log` is not a GitHub artifact. Hosted CI was not observed.

## Documentation reconciled

`PROJECT_STATUS.md`, progress tracker and living handoff described F2 or #28 as awaiting merge. Those claims are corrected using merge ancestry. The visual review’s branch description and F0 inventory describe their historical audit dates; they are retained as history, not converted into blanket approvals. New owner protagonist decisions are recorded in `GDD_AMENDMENTS.md`; all proposed implementation details are labelled in `PROTAGONIST_CUSTOMIZATION_PLAN.md`.

## Missing dependencies and remaining decisions

- The private v1.1 upload (including full clinical/bible package) is absent. Existing GDD DOCX, engineering handoff, reference PDF/READMEs, current JSON/script/save structures and relevant narrative/clinical docs were inspected. Do not recreate missing canon from earlier-session summaries.
- Mac Forward+/Metal rendering, mouse feel, audio mix and memory/frame-time profiling remain untested. Blender/model generation and optional offline audio tools are not installed for this runtime workflow.
- Visual D1–D9 remain pending: Rahman role, Hale title, casting, Ward Zero date/signatory, 02:17 link, Mara voice, station layout, superseded boards and bible publication.
- F0 C2 (Concordance/titles), C6 (Bleed), C7 (pharmacology story gates), C11 (unused music original export), precise anomaly mechanism and pending patient/clinical content remain unresolved. F3 is not implemented here.
- Fixed psychiatrist role, moderate personal life and emergent personality are explicit owner requirements, not new questions. The phased schema/UI/persistence proposal still requires review.

## Environment and next action

The cloud draft contains the tested Godot installation/QA script and startup instructions. An additive custom domain requirement `api.github.com` was saved to unblock PR inspection/creation; package-manager presets were preserved. Draft saving does not apply network changes or publish. Review/save environment settings, then publish as directed by the environment UI; retry the API afterward with existing authentication before requesting any credentials.

Independent task: add existing-save rejection/provider regression tests without changing production behavior. Final development results, exact verified feature-branch SHA and PR status are in `AI_SESSION_HANDOFF.md` and the newest append-only `AI_HANDOFF.md` entry. Next substantial work is owner review of `PROTAGONIST_CUSTOMIZATION_PLAN.md`, then only approved P1 scope.
