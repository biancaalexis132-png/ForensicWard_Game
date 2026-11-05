# Gameplay completion candidate — 2026-10-20

Branch: `codex/gameplay-completion`, based on main after PR #109 repaired PR #104.

## Implemented

- Signed EHR notes and committed clinical actions now produce deduplicated journal references. The chart retains ownership of signed text; legacy chart reconciliation runs silently after load. Player text displays literally. No evidence-board, clinical or story state is inferred from a journal entry.
- The map projects actual geometry on the current loaded floor, with player position/heading, room names, real door access/open state and EHR locations. It loads no other floors and grants no access.
- Optional protagonist identity, professional interest, acceptance reason, relationship, personal history and appearance choices have an independent profile/save provider. The professional role remains psychiatrist. A procedural portrait previews appearance. Choices alter no competence, trust or access. Confirm commits atomically; Cancel discards the draft. Notes keep the author's display name as it was when signed.
- Committed story choices have a deduplicated profile ledger, without personality classes or medical interpretation.
- Save version 4 migrates existing v1/v2/v3 saves with neutral profile and Continuing Practice defaults. Invalid optional provider data is rejected before any live provider is mutated.
- Continuing Practice has a typed five-encounter case lifecycle, post-campaign acceptance gate, real dialogue/chart routing, persistence, hold/resume, follow-up tasks, accountable handoff states, source categories and consent boundaries. A completed interview and signed note are both required. Time does not resolve tasks or finish encounters; handoff acknowledgment does not mean clinical resolution.

## Jordan identity and activation

The owner confirmed **“Same patient; preserve continuity”** for Jordan Vale and the provisional Chapter 1 Scene 07 Jordan. `pt_cp001_jordan_vale` is the continuing identity. The current campaign has not implemented that earlier Jordan encounter, so no previous visit, finding, relationship or signed note is invented during migration.

The original dossier and five-encounter screenplay have been preserved. Nineteen exact question/response pairs are compiled into normal dialogue graphs. Unpaired staging/staff lines remain in review documents rather than being invented as patient speech. Sources unavailable in the authored package remain unavailable. No doses, treatment effects, medical findings, risk negatives or discharge outcome were added.

**Clinical activation remains PENDING.** Pending case content never enters the patient registry/census or clinical play. The worklist exposes drafts for review only. The exact packet is [CP001_ACTIVATION_REVIEW.md](CP001_ACTIVATION_REVIEW.md); AGENTS.md §6 requires the owner's explicit clinical approval before flags can change. Test-only approved fixtures do not approve shipped content.

## Acceptance limits

This branch provides the journal, map, profile and Continuing Practice engineering. `codex/environment-finish` stacks environment assets, finish materials, UI layout refinements, additional integration checks, presentation review and Mac tooling on it. The profile currently previews a 2D procedural bust; no full-body protagonist model or Jordan voice/model is claimed.

Actual Mac visual/audio/input/performance acceptance and newer presentation decisions remain pending. The cloud has no connected Mac or SSK volume. All source and runtime changes can be synced from Git after owner review; no external-drive repository was accessed. Merging is owner-only.
