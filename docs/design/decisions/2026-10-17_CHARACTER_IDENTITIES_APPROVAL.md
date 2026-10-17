# APPROVED CANON UPDATE — ASHCROFT CHARACTER IDENTITIES AND VISUAL CASTING
## The Forensic Ward | Owner Decision | 17 October 2026

**Repository:** `biancaalexis132-png/ForensicWard_Game`

**Status: APPROVED — D1, D2 and D3**

The following decisions supersede contradictory provisional references in `docs/design/VISUAL_PRODUCTION_REVIEW.md`, character concept boards, and earlier planning discussions.

These decisions must be reflected in the game's authoritative documentation and relevant content definitions.

## DECISION D1 — DR. LEILA RAHMAN

**Approved role: Consultant Psychiatrist.**

Leila Rahman is a psychiatrist, not a clinical pharmacist.

Her professional identity, character biography, and future narrative interactions should reflect her position as a consultant psychiatrist at Ashcroft State Forensic Hospital.

Review relevant references, including:

- `data/staff.json`
- `audio/voice_profiles.json`
- Existing dialogue and character records
- Character reference documentation
- Relevant Game Design Document sections

Identify and reconcile contradictory role labels.

Do not change dialogue identifiers, voice casting, clinical treatment logic, or existing game functionality unnecessarily.

Her exact responsibilities, interpersonal dynamics, and story involvement must remain consistent with the approved character bible.

## DECISION D2 — MARCUS HALE

**Approved title: Security Director.**

Marcus Hale is Ashcroft's Security Director.

Use this title consistently across character documentation, organizational records, staff data, dialogue, signage specifications, and future character interfaces.

His visual presentation should reflect a senior professional responsible for hospital security operations.

Do not use militarized or tactical visual styling as the default.

Preserve the distinction between security responsibilities and psychiatric clinical authority.

## DECISION D3 — WRITTEN CASTING AUTHORITY

**APPROVED: The written character guide is authoritative.**

AI-generated character reference images are provisional visual concepts.

Where generated artwork conflicts with the approved written guide, the written guide takes precedence.

This includes age, appearance, identity, professional attire, role, and character presentation.

In particular:

- Preserve Naomi Bennett's approved written casting as a Black woman.
- Preserve Leila Rahman's approved written casting as a South Asian woman.
- Preserve each remaining character's established written description where available.
- Correct portraits that depict characters at substantially inconsistent ages.
- Avoid tactical styling for Marcus Hale.
- Avoid unnecessarily disheveled or stigmatizing visual depictions of patients.
- Do not depict psychiatric patients as supernatural entities merely because they are associated with the Ward Zero narrative.
- Do not use real actors or identifiable real-person likenesses as character designs without authorization.

The existing six character references are starting points, not final production models.

Regenerate inconsistent portraits so each character receives a coherent set of original references suitable for a future 3D modeling workflow.

Do not silently reinterpret an unclear written description. Flag genuine ambiguities for approval.

## REQUIRED DOCUMENTATION

First inspect the actual repository state and read:

- `AGENTS.md`
- `CLAUDE.md`
- `docs/design/VISUAL_PRODUCTION_REVIEW.md`
- Existing character guide and visual-reference materials
- `docs/design/GDD_AMENDMENTS.md`
- The applicable design bible, if accessible
- Current staff and patient records

Then:

1. Record D1–D3 as resolved and owner-approved.
2. Update the authoritative character-canon documentation.
3. Update `docs/design/VISUAL_PRODUCTION_REVIEW.md` with a dated owner-decision addendum or status update, preserving historical review findings.
4. Propose `docs/design/CHARACTER_VISUAL_CANON.md`, or update it if it already exists.
5. Identify the exact artwork that must be regenerated.
6. Prepare individual character regeneration specifications with consistent appearance, clothing, expressions, and modeling views.
7. Keep D4–D9 unresolved unless the owner separately approves them.
8. Reconcile relevant staff and audio metadata only where the approved decisions clearly determine the correct values.

Do not delete older artwork. Mark superseded references clearly and preserve provenance.

## APPROVED PROTAGONIST CANON — PRESERVE

The playable protagonist is always a psychiatrist at Ashcroft State Forensic Hospital.

Appearance and professional background are customizable.

Personal-life customization is MODERATE.

Players can choose meaningful elements of their history, personal connections, motivation for joining Ashcroft, and limited outside-work preferences.

Personality emerges through gameplay decisions, not permanent character classes.

Preserve essential clinical competence and story access across all character configurations.

Continue using the existing campaign save architecture.

## DEVELOPMENT AND REVIEW BOUNDARIES

Continue approved, non-conflicting development work.

These character approvals do not authorize a large rewrite of the game or unrestricted changes to clinical rules.

Do not overwrite another agent's active work or merge pull requests automatically.

Separate documentation/canon updates from substantial 3D production work wherever practical.

Follow `CLAUDE.md` and maintain:

- `docs/AI_SESSION_HANDOFF.md`
- `docs/AI_PROGRESS_TRACKER.md`
- `docs/AI_HANDOFF.md`
- `docs/PROJECT_STATUS.md`

Update checkpoint files throughout your work rather than waiting until the session ends.

## EXPECTED DELIVERABLES

Return:

1. Confirmation that D1–D3 are recorded as approved.
2. A list of contradictory files and proposed corrections.
3. The updated character-canon specification.
4. A list of portraits that require regeneration.
5. A phased character-production plan.
6. Any remaining decisions requiring owner approval.
7. Tests performed and results.
8. Branch, commit SHA, and PR link if changes were pushed.
9. An updated session handoff with exact continuation instructions.

**Begin by verifying the latest repository state and coordinating with the active Codex development workstream. Do not restart development or overwrite its work.**