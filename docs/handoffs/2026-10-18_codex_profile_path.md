# Character builder external-profile checkpoint

Branch: `codex/character-profile-path`, based on `main` `f9dba61` (PR #54 merged; PR #52 is also an ancestor). No model or manifest outputs changed.

The builder used `profile_path.relative_to(ROOT)` in both the report and manifest after writing the model files. External profiles raised ValueError at that point. `provenance.py` now resolves paths, records repository-relative paths for repository files and absolute paths for external files, including symlink destinations. Both records also store the profile SHA-256. External render output paths use the same rule; missing manifest parent directories are created.

Validation:

- `python3 -m unittest discover -s tools/character_animation/tests -v`: 3 passed (internal profile, external profile/render paths, external symlink).
- From `tools/character_animation/ForensicWard_Animation_Pipeline_v03`, `python3 -m unittest discover -s tests -v`: 6 passed. Running discovery from the repository root initially failed because this existing suite requires its documented working directory; rerunning there passed.
- Full Godot QA on latest main is being recorded in the continuation handoff; no music tests removed.
- Full Blender export not run: installed cloud Blender is 4.3.2, while the project requires 5.2.2. No claim of an executed Mac rebuild. No v04 files overwritten.

PR #54 review: actual committed MP4 is H.264, 1280x720, 30 fps, 584 frames, 19.466667 seconds. Reviewed the five stills through the take overview and a close-up frame sequence around the scripted blink (2.5 seconds): a narrow eye gap remains and the brows form hard repeated strips. This is a forced-frame visual recording, not a real-time performance measurement. Its handoff reports 155 unit tests, 157 model imports, QA 19 and audio 336; it explicitly says the historical Mac full run omitted music and the separate PR #52 music check passed 3/3. Current complete cloud QA is separate evidence.

The requested `docs/handoffs/2026-10-18_naomi_local_build.md` is absent from the merged tree; the toolkit's LOCAL_MAC_RUN.md and PR #54 handoff supply the available local-build record. Current shared continuity docs still describe merged PRs as draft; do not infer active ownership from those historical entries. GitHub API queries return Forbidden; Git refs and merge ancestry are the verified source here.

Next: bounded foreground Mac benchmark and separate v05 preparation, preserving v04. This cloud has no Mac connection or installed MPFB packs. Never claim M1 measurements or MPFB-derived assets from cloud tests.
