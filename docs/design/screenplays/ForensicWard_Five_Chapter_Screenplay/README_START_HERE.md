# THE FORENSIC WARD — FIVE-CHAPTER SCREENPLAY DEVELOPMENT PACKAGE

**Release:** Proposed full five-chapter screenplay **draft** v1.0 (17 October 2026)

This is a complete chapter-by-chapter **scene treatment / playable screenplay draft** for all five chapters, with scripted anchor dialogue, staging, branching choices, scenes, chapter arcs and continuity notes. It is **not** a fully voiced shooting script for every possible branch and not a fully clinically approved or canonical final manuscript. The user requested a final ZIP: "final" here describes a finished distributable ZIP of the *draft manuscript*, NOT clinical or owner sign-off. Further line-by-line script expansion and approvals are necessary before coding.

## Critical source-of-truth separation
- `chapters/CH1_ELIAS_WARD_COMPLETE_SOURCE_DRAFT.md` is the exact existing standalone Elias screenplay supplied earlier in this conversation; preserved without creative substitution.
- `chapters/CH01_THE_ADMISSION_FULL_SCREENPLAY_DRAFT.md` is the unified 12-scene Chapter 1 adaptation. Scenes 3–6 summarize existing Elias beats; for detailed Elias lines use the standalone document. Scene 7's Jordan Vale is **provisional, not approved canon**.
- Chapters 2–5 are **NEW AUTHORIAL PROPOSALS**, not verified repo story text. Chapter titles align with `data/campaign.json` but are provisional there, as the Concordance thread/titles were previously unresolved.
- Actual Godot clinical data/dialogue/beat IDs come from the repo; see `production/IMPLEMENTATION_CROSSWALK.md`.
- No generated scene text is approved medical advice or a validated clinical rule.

## Package map
- `chapters/CH01...CH05...` — playable story scene drafts for five chapters.
- `chapters/CH1_ELIAS_WARD_COMPLETE_SOURCE_DRAFT.md` — detailed Elias evaluation screenplay retained verbatim.
- `production/CHARACTER_AND_ENDING_BIBLE.md` — ensemble, player personalization, arc and ending logic.
- `production/IMPLEMENTATION_CROSSWALK.md` — mapping of creative screenplay beats to current repo files and planned implementation.
- `clinical/CLINICAL_APPROVAL_REGISTER.md` — clinical review gate with no fabricated approval.

## Continuity rulings already supplied by owner
- Ashcroft State Forensic Hospital; realistic psychiatric drama with slowly emerging genuine supernatural mystery.
- Protagonist always a psychiatrist; customizable appearance, background, moderate personal history; personality emerges from choice.
- Rahman = Consultant Psychiatrist; Hale = Security Director; written casting takes precedence; revise inconsistent generated portraits.
- Medical and patient behavioral findings NEVER cause or substantiate supernatural events.

## Integration rules
1. Review against the latest `origin/main` and `AGENTS.md`, `CLAUDE.md`, both session handoffs, GDD and `VISUAL_PRODUCTION_REVIEW.md`.
2. Preserve existing IDs, source provenance, save migrations, Chapter 1 beat timing and approved gameplay.
3. Obtain clinical review of the Elias and all later patient-facing content before making treatment logic live.
4. Seek owner approval of the NEW Chapters 2–5 storyline, second patient, historic details, mechanisms and endings.
5. Commit small docs-only PR first; only then implement short vertical slices behind feature flags.
