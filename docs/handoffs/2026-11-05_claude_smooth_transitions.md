# Smooth dialogue, subtitle and menu transitions (Claude Code, 2026-11-05)

Roadmap point 6 (smooth dialogue, subtitle and menu transitions), thread "Make the game more compelling". Branched from `main`.

## What changed

- **`scripts/ui/UITransition.gd`**: a short ease-out fade (0.16 s for screens, 0.12 s for text). It is presentation only: visibility, focus, pausing and input change at once, exactly as before. With **reduce motion** on, nothing fades.
- **`Main._on_ui_panel_requested`** fades in any screen that this request newly opened. A screen that was already open is not re-faded. The cutscene and the interview keep their own presentation. The pause menu fades in as well, and the fade runs while the game is paused.
- **InfoPanel**: when a choice's response or the next scene replaces the text in an open panel, only the new text and choices fade in, so the panel no longer flashes.
- **HUD subtitles** fade in when a line appears after silence. Consecutive lines swap at once.

## Files

New: `scripts/ui/UITransition.gd`, `scripts/tests/test_ui_transitions.gd`.
Changed: `scripts/main/Main.gd` (panel opening split into `_open_panel`, plus the fade), `scripts/ui/InfoPanel.gd`, `scripts/ui/HUD.gd`.

## Tests

`test_ui_transitions` (5). Full QA: see the `docs/AI_HANDOFF.md` entry. Not tested on the Mac, where the feel of the fade needs Bi's eye.
