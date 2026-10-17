# P1 protagonist input contracts

P1 implements a pure creation-draft validator and catalog schema. The owner authorized this bounded scope by replying “continue” to the P1 approval question in the Codex session. Actual catalog choices, callback prose, assets and later phases remain unapproved.

## API and ownership

`ProtagonistValidator.validate_catalog(value)` and `validate_profile(profile, catalog)` accept parsed values and return `{errors: Array[String], warnings: Array[String]}`. A nonempty error list means rejection. Invalid shapes produce path-specific errors before semantic/reference checks. The calls do not read files, load assets, emit events, change run state or seed, or normalize their input. Callers must supply parsed input; JSON/file errors belong to their future loader. Frozen inputs are supported.

Schemas in `scripts/protagonist/ProtagonistSchemas.gd` reuse the existing ContentValidator vocabulary. Unknown fields are errors only for these new contracts; existing content policy remains unchanged. Neither class is an autoload. No production ContentRegistry hook or data file is introduced. Fixtures under `scripts/tests/fixtures/protagonist/` are deliberately synthetic and must never be used as authored player choices.

## Catalog v1

`{catalog_version: 1, groups: {...}}` requires groups for pronouns, body/face presets, skin tones, hair styles/textures/colors, outfits, accessories, voices, professional interests, acceptance reasons, formative experiences, relationships and outside life. Each group is an array and may be empty. Options contain only an `id` and nonempty `label`; pronoun options additionally require `forms` with subject/object/possessive strings. All option IDs use `popt_` and are globally unique within this catalog. Selections resolve in the specified group, so a hair ID cannot stand in for skin tone.

Asset paths, fallback rules, clinical effects, access grants, mandatory-evidence conditions, gender gates and personality classes are not part of this catalog contract. Later approved work may extend the version deliberately.

## Creation draft v1

The draft has only `profile_version`, `creation_state`, `identity`, `appearance` and `background`, as illustrated by `unconfigured_fixture.json`. This is not the future save payload: the choice ledger and delivered callbacks are deferred to P5, and no save provider/version/migration changes here. Existing save version remains 3.

Role is always `psychiatrist`. A configured draft requires a nonempty name; unconfigured drafts may leave it blank. Other single selections may be empty strings, and multiple selections may be empty arrays. Professional interest is one optional selection. No background or relationship is required for either state. Personal history is limited to three formative experiences and two relationships; the limits from the proposal are technical v1 bounds, not authored content approval. Appearance categories are independent and do not gate one another or voice.

Names allow 64 Unicode code points and pronoun forms 32; leading/trailing whitespace and control characters are rejected rather than silently rewritten. All-empty forms mean unspecified pronouns. Custom forms use an empty preset ID and must be complete. Selected presets must exactly match their catalog forms. This three-form structure is a technical starting point, not a completed localization/grammar design. Text remains literal; a later UI must escape markup at the rendering boundary. Validation does not make a string safe as a file path or rich-text fragment.

Unknown IDs are rejected in this **creation-draft** API. This does not implement or change the proposed saved-profile compatibility policy: P2 must preserve unknown stored appearance IDs and design safe presentation fallbacks, with explicit migration and preflight validation. Do not wire this draft API blindly into existing-save loading.

## Validation and next gate

Run the standard `python3 tests/qa/run.py --godot <Godot 4.7>`; TestRunner discovers `test_protagonist.gd`. It checks valid empty/Unicode/custom cases, exact versions including JSON floats, fixed role, wrong shapes, unknown fields and IDs, duplicate IDs/selections, selection limits, pronoun consistency, read-only input support, and unchanged inputs/run state.

P2 is separate: capture a real v3 save, add a profile provider and explicit v3→v4 migration, validate all providers before changing live state, and test real v1/v2/v3 compatibility. The owner has not approved a major persistence rewrite or unresolved visual/clinical/narrative canon by approving P1. Verify P1 review and P2 scope before beginning it.
