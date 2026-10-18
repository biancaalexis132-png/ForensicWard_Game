# Character integration contract — CIG-1 proposal

## Existing integration points verified on GitHub
- Existing `WardCharacter` scene: `scenes/props/Character.tscn` with `Body/Mesh`, `Body/Collision`, `Interactable`, `NameLabel`.
- Existing `WardCharacter._ready()` scales `Body/Mesh` for seated roles and disables its body collider. This **must be refactored carefully before using imported visual meshes**; do not deform a full humanoid character with the placeholder's 0.65 Y scaling.
- The player interaction route is `Interactable.interacted` -> `_talk_to_staff()` or `_approach_patient()`; preserve this.
- Naomi acting cues are handled by `NaomiActingController` and `CharacterActingAdapter` using `staff_bennett`; preserve those stable IDs and event semantics.
- `data/world_chapter1.json` instantiates `staff_voss`, `staff_bennett`, `pt_elias_ward`; no filename or skeleton name may change these identities.

## Proposed implementation order
1. Establish a new optional `VisualRoot` child/slot. Preserve existing collision, `NameLabel`, `Interactable`, and stage data. Hide (do not immediately delete) the capsule placeholder when a valid character visual has been loaded.
2. Use a **character asset registry** mapping stable IDs to approved imported scene paths. Unknown IDs or invalid resources use the neutral placeholder. Do not infer role from a model filename.
3. Ensure the seated/standing posture comes from authored scene configuration and animation; remove hard-coded nonuniform mesh scaling *only when the proper visual is active*. Keep collision and physical access predictable.
4. Attach the approved model's animation adapter. Animation is optional/fail-safe: missing bones, shape keys or clips never prevent interacting or progressing Chapter 1.
5. Implement one controlled model swap for Naomi first; Godot validation, scene integration tests and Mac profiling are gates before porting to the other cast.

## Asset ownership
Each character has an isolated builder and source/output directory, e.g. `tools/blender/characters/naomi/` and `assets/characters/naomi/`; characters cannot modify each other's builder files or shared skeleton/export adapters without a reviewed dependency PR. Do not commit huge generated model files until size, licensing and Git LFS policy are approved. Preserve `.blend` source and provenance separately from the runtime export.

## Tentative technical checks (not approved numerical budgets)
- Standard coordinate and scale: scene exported in meters, upright feet-on-ground, Godot facing convention documented in manifest.
- Visible meshes, skeleton/rig and facial controls audited separately. A rigid mesh may pass GLB structural audit but fail character acceptance.
- Clothes must be independently licensable, rigged with skin deformation and appropriate to each character's profession/role.
- No real person's likeness or identifiable voice clone without clear rights; no horror styling on psychiatric patients.
- Standardized material names and texture dimensions for review, rather than declaring arbitrary triangle/VRAM thresholds unsupported by benchmarks.
- Existing save version is v3. Character visuals should not trigger a save migration.

## Explicit exclusions
No rewriting clinical diagnoses, no new treatment effects, no changes to story progression, no activation of pending clinical rules, no supernatural effects attached to patients, and no blanket character replacement before QA.
