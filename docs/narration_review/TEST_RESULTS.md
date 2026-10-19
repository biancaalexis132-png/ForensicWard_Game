# Executed validation — 19 October 2026

Runtime baseline: GitHub main `27798757a8e8844a7301910a4610d0ec5817a0d2`. Review checkpoint `f498682f1c3e64429b28b9742dc59ff9fecac701` adds only documents, supplied draft text, HTML and voice metadata. No runtime/asset bytes changed.

- Independently hashed every approved PNG against its manifest: 36/36 match. Also verified 36/36 after reading the local review ZIP entries.
- `git diff --check`: pass.
- Initial installed Godot is 4.6.3; standard runner correctly rejected it. No engine gate changed.
- Downloaded official Godot 4.7 stable; SHA512 verified against official SHA512-SUMS.txt. Reported version: `4.7.stable.official.5b4e0cb0f`.
- `python3 tests/qa/run.py --godot /workspace/work/godot47/Godot_v4.7-stable_linux.x86_64`: Python JSON 6/0, audio manifest 4/0, cutscene contracts 6/0, music pipeline 3/0; import completed; pharmacology 0 failures; gameplay QA 19 passed/0 failed/0 skipped; GLB 168 assets/0 failures. Runner then timed out in TestRunner at its unchanged 150-second per-command cap. The full runner did NOT pass.
- Ran the unchanged `res://scripts/tests/TestRunner.tscn` separately with a 240-second external cap and isolated XDG directories: exit 0, **269 passed / 0 failed**. No SCRIPT ERROR/ERROR/FAILED markers in its log. This is newer executed evidence than the handoff's historical 266/0.
- Independent remaining steps with isolated XDG directories: boot exit 0 (content valid); audio suite **336 passed / 0 failed**, exit 0. Chapter 1 sequence reached `CH1_SEQUENCE_DONE` at 63.1 seconds and exited 0.
- Mac Forward+/Metal look, realistic character quality/performance, audible sample/mix/pacing, and all new narration behaviors: NOT validated. Narration is not integrated; no narration runtime tests are claimed.
- Hosted PR validation was in progress when checked; no hosted CI success claimed.

Raw logs are retained locally in `/workspace/work/qa47.log`, `/workspace/work/game-tests.log` and `/workspace/work/remaining-qa.log`; these paths are disposable and not a substitute for the pushed summary.
