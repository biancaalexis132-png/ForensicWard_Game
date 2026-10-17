# Protagonist customization: phased implementation proposal

**Status: proposed engineering design, awaiting owner approval before implementation.** This session implements only independent save regression tests. No character creator, personality system, authored background content or save-version change ships with this document.

## Approved requirements and source boundaries

The owner’s “CONTINUE DEVELOPMENT — THE FORENSIC WARD” handoff in this Codex session (2026-10-17) approves the following: every protagonist is a psychiatrist at Ashcroft; appearance and professional background are customizable; personal-life customization is **moderate**; personality emerges through choices rather than a permanent class. Essential competence, psychiatric responsibilities, mandatory evidence and major outcomes remain accessible for every selection. Clinical correctness is independent of personality and background. The supernatural phenomenon is real and cannot be explained away through personal history or psychiatric symptoms.

These decisions supersede the locked GDD’s limited personal-life scope. They do not approve this implementation design, any particular callback text, the visual review’s D1–D9 recommendations, or F3 in full. Proposed fields, IDs, budgets and PR boundaries below need review. The private v1.1 bible package is absent; do not reconstruct it. Available sources: GDD v0.1, engineering handoff, GDD amendments, F0 audit, current F1/F2 code, character guide PDF and visual review. Imported portraits are references, not meshes or approved casting.

## Verified integration points

| Existing system | Proposed use; preserved responsibility |
|---|---|
| `ContentRegistry`, `ContentSchemas`, `ContentValidator` | Validate immutable option catalogs in JSON using F1 campaign collection; no hardcoded background prose in scripts |
| `SaveManager` | Add one `protagonist` provider; keep sorted canonical state/checksum, existing providers and migrations |
| `ChapterDirector` / F1 campaign catalog | Keep current chapter, fired beats and chapter flags; optional callbacks reference stable chapter IDs |
| `ZoneDirector` / F2 `zones` state | Unchanged; customization cannot grant access, load zones or bypass gates |
| `DialogueManager` / `StoryLogic` | Add small closed, validated optional selectors only after approval; preserve existing interview logic |
| `TrustManager` | Continue owning respect/trust/suspicion and access grants; no second relationship store |
| `PatientManager` / `ClinicalRules` | Unchanged; no identity, personality or history input to medical evaluation |
| FirstPersonController / HUD / PauseMenu | Preserve movement/capture; creator uses established modal and pause conventions |
| `AudioDirector` / voice profiles | Optional approved player voice IDs, with text fallback; no cloned voices or regenerated existing lines |

Propose a narrowly scoped `ProtagonistProfile` autoload as provider owner, with deep-copy queries and explicit commands. Communication uses EventBus facts, e.g. `protagonist_profile_changed` and a deduplicated authored choice event; names remain proposed. Do not add a parallel save manager or repurpose `GameState.objectivity`, rapport, or clinical fields. Provider initialization must precede consumers; register/unregister with existing provider APIs. Queries for optional presentation must not mutate state or consume RNG.

## Proposed data and run-state schema

An immutable catalog, tentatively `data/protagonist_options.json`, supplies labels, option IDs, prerequisites for presentation assets, fallback IDs, and reviewed callback references. Extend F1 collection/schema validation and reserve IDs before introducing real content. A stable catalog version accompanies content migrations; file paths are resolved from a whitelist, never from free text.

Illustrative provider payload (design example, not shipped data):

```json
{
  "profile_version": 1,
  "creation_state": "unconfigured",
  "identity": {
    "name": "",
    "pronouns": {"preset_id": "", "subject": "", "object": "", "possessive": ""},
    "professional_role": "psychiatrist"
  },
  "appearance": {
    "body_preset_id": "", "face_preset_id": "", "skin_tone_id": "",
    "hair_style_id": "", "hair_texture_id": "", "hair_color_id": "",
    "outfit_id": "", "accessory_ids": [], "voice_id": ""
  },
  "background": {
    "professional_interest_id": "", "acceptance_reason_id": "",
    "formative_experience_ids": [], "relationship_ids": [], "outside_life_ids": []
  },
  "choices": [],
  "delivered_callbacks": []
}
```

Role is fixed and validated, never an editable class. Professional catalog candidates are academic, community, consultation-liaison, forensic, emergency and general adult psychiatry. Selecting none remains valid. These are prior experiences/interests, not licenses or skill gates. Identity strings need Unicode support, trimmed length limits and UI escaping; custom pronouns need explicit grammar handling and a neutral fallback. Do not insert free text into resource paths, markup or executable expressions. Proposed limits: name 64 code points, pronoun forms 32, at most three formative experiences and two relationships; owner reviews these limits before implementation.

Personal options should include neutral and independent-life paths, declining any relationship and no traumatic history. Acceptance reasons may include opportunity, forensic interest, fresh start, complex care or geography, with optional explanation text only if a bounded use is designed. Store stable option IDs and small selected details, never third-party contact information. No romance, family or tragedy is mandatory. Optional omissions must remain meaningful choices, not deficits.

Each `choices` entry would contain a stable authored event ID, chapter ID, choice ID, in-game time and reviewed narrative tags. `delivered_callbacks` deduplicates actual deliveries across saves. Identity/background are campaign-wide; callbacks remain chapter-authored. Do not prepopulate later chapters with invented story content.

## Appearance architecture and accessibility

Stage appearance delivery: text identity and badge first; approved first-person hands/sleeves second; portrait and modular head/hair/body preview only after an asset pipeline is approved. Store IDs, not generated meshes or textures, in saves. Swapping one option reuses shared rig/materials and releases replaced preview resources. Skin tone and hair texture are independent; clothes/accessories and voice are not gender-locked. Missing content maps to an explicit neutral fallback and preserves the original ID for future restoration. Do not silently reinterpret an old selection as another identity.

A creator modal has Identity, Appearance, Professional Background, Personal History, and Review pages. Background/history pages offer “skip for now”; no Personality page. Explain fixed psychiatrist competence. Confirm applies a validated draft atomically; Back retains draft, Cancel leaves run state unchanged. Existing saves continue directly and can open customization voluntarily. Editing appearance/name later should not rewrite old signed chart entries; retain stable author IDs and decide display-name history in the relevant note UI PR.

Keyboard-only navigation, clear focus, controller-ready actions, text scaling, screen-reader-friendly labels where supported, labelled swatches, preview rotation alternatives and reduced-motion handling are acceptance requirements. Preview audio is optional, manually triggered, with transcript; missing voice never blocks completion. No body sliders or automatic rotating animated preview in the initial delivery.

## Evolving personality and narrative integration

Begin with an authored choice ledger and contextual reflections; do not commit to the suggested six numeric axes. Never show a good/evil bar or assign a permanent profile. An empathetic or reserved response can both be professionally appropriate; decisive and cautious responses can each fit context. Clinical decisions are evaluated by the existing reviewed rules, never these tags.

If a later approved design needs trends, derive them deterministically from bounded, reviewed narrative tags in the ledger, with context and recent behavior; preserve underlying events so interpretations can evolve. Deduplicate using event IDs. No trend changes on load, passive time, replayed UI or arbitrary free-text inference. No universal reward for any tendency.

Optional dialogue variants may check catalog IDs or authored prior choices through validated selectors. Every branch retains a neutral equivalent and converges before essential care/evidence. Background knowledge may add explanation, never remove the baseline assessment option. Relationship reactions go through TrustManager’s public API once per committed choice; they never auto-grant essential care permissions. Mandatory evidence requires redundant routes regardless of optional callback uptake.

Callback design must include an authoring table per chapter: selected option, optional delivery location, fallback text, dedupe ID, content approval and convergence point. Phone messages and reflections use established text UI first; no phone simulation, schedules, romance subsystem or new locations are implied. Clinical entries and anomaly evidence are separate domains and do not consume personality tags.

## Save compatibility strategy

Current runtime is save **v3**, with v1→v2 chapter wrapping and v2→v3 zone object migration. Verify the original checksum before migration, as implemented. Proposed first persistence PR increments to **v4**, adds `_migrate_from_3`, and supplies a neutral unconfigured protagonist payload without changing any prior provider, seed, chapter, door or pending event. All old saves continue without a forced creator and without retroactive personality inference. Re-saving produces v4; v1→v2→v3→v4 is tested through real committed fixtures.

Keep a separate `profile_version` for future profile shape. Validate provider payloads before applying them; a failed load must not partially replace live state. Decide explicitly whether malformed optional profile data rejects the whole save or uses a visible recovery flow; recommend rejection with a useful message until a tested recovery UX exists. Unknown catalog IDs preserve stored identity with safe presentation fallback; wrong types and invalid professional role fail validation. Future save versions remain rejected, never silently downgraded. Missing-provider reset behavior is existing fallback infrastructure, not a substitute for an explicit v3→v4 migration.

No save schema change is implemented here. Atomicity/type validation enhancements, if required, need a separate bounded save PR and regression tests rather than being hidden in UI work.

## Hardware limits and asset coordination

Target is Apple Silicon MacBook Air, 8 GB unified memory. Reuse F2; never load hospital zones solely for the creator preview. Provisional added creator budget: one mannequin, one portrait target at at most 512×512, shared 1K/2K materials, no runtime generative models, no SSR or extra shadow lights. Release the preview on close. Measure total process memory, peak option-swap memory and frame time on the Mac before declaring a budget met. The visual review’s 15–25k triangle character target is a proposal; confirm with the asset workstream. Headless Linux validates logic/imports only.

Stage 6 geometry, character casting D1–D3, Ward Zero D4–D8, new voices, lighting and audio cues remain with their owners. Review shared rig/licensing/provenance before adding assets. The private bible (D9) is an external dependency, not grounds to invent content.

## Small PR sequence and acceptance gates

| PR | Scope | Required acceptance |
|---|---|---|
| P0 (this proposal) | Canon amendments, reconciliation, plan; independent existing-save tests | Owner approves plan/next bounded scope; baseline QA remains green |
| P1 | Catalog schema + pure profile validation, synthetic fixtures only | Reject wrong role/types/IDs, exercise empty/Unicode/skip cases; no gameplay or save version change |
| P2 | Profile provider + v4 migration | Real v1/v2 and captured v3 saves migrate; prior state identical; checksum/future-version failures preserve live state; deterministic round trip and reset |
| P3 | Text creator + voluntary existing-save entry | Keyboard navigation, cancel/confirm atomicity, skip paths, no mandatory permissions/evidence changes; Mac manual UI check |
| P4 | Approved hands/sleeves/badge appearance | Asset provenance, all tone/texture/outfit combinations valid, missing-ID fallback, resource release, Mac memory/render check |
| P5 | One reviewed optional background callback + choice ledger | Neutral equivalent, no clinical/anomaly coupling, no duplicate event/delivery after reload or chapter transition |
| P6 | Reviewed callbacks across five chapters as each chapter is authored | Branch reachability matrix for all backgrounds/history omissions; major outcomes accessible; clinical review where relevant |
| P7 | Optional richer preview/voice and contextual personality interpretation | Owner approves scope; performance and accessibility gates; no permanent class or universal scoring |

Each PR is a feature branch and draft PR; owner merges. Dependencies P1→P2→P3; P4/P5 follow P3 and their content approvals. Do not begin P1 until the owner approves this design. Full `tests/qa/run.py` is required for gameplay/persistence changes; use existing runner discovery for new GDScript suites. Fixtures for unapproved future content remain under tests, not shipped `data/`.

## Validation matrix and decisions needed

Test real migration chains, old saves with missing optional providers, rejection without state/seed/event changes, deterministic replay/dedupe, Unicode/length/escaping, unknown appearance IDs, new run reset and interrupted draft creation. Compare PatientManager/ClinicalRules results across every background and narrative tendency; assert no mandatory clue or clinical option is lost. Verify optional callbacks persist across chapter changes, cannot alter anomaly evidence, and tolerate decline/skip paths. Audio tests need text fallback and no autoplay requirement. Visual/input/accessibility/frame-time claims require Mac checks.

Owner decisions needed: approve phased architecture and P1 scope; approve option catalog/limits and wording; choose whether professional background is single primary interest or multiple experiences (recommend one initially); review custom pronoun form set/localization; approve edit policy and name history; choose appearance pipeline and assets; approve each optional personal callback and any later trend interpretation. Fixed psychiatrist role, moderate personal life and emergent personality are already decided and are not re-requested. D1–D9 and F0 C2/C6/C7 remain separate open decisions; no blanket visual or F3 approval is inferred.
