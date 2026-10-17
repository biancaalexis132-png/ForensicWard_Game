# AI progress tracker

Required by the Ashcroft Session Continuity Protocol in `CLAUDE.md` §3. One row per task; each session updates only its own rows.

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Ashcroft score integration | In review (draft PR #27) | none | `audio/cues.json`, `systems/audio/AudioDirector.gd`, `tests/audio/TestAudio.gd` | Godot suite green locally; CI pending | Owner review |
| Chapter 1 music realignment per the bible | Approved by owner, in PR #27 | none | `audio/cues.json` (`records_archive`) | Tests green | Merges with PR #27 |
| Reception and records archive audio zones | Pending | Zone geometry for those areas | `data/zones.json` `audio_zones` | not started | World owner adds the rectangles |
| Suno licence confirmation (11 tracks) | Blocked on owner | Owner's Suno plan | `audio/manifest.json` | n/a | Owner records the terms |
| Listening pass on the Mac | Pending | Owner hardware | n/a | n/a | Owner listens to each context |
