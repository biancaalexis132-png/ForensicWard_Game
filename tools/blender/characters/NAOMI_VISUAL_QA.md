# Naomi visual QA checklist

**Review state:** pending owner appearance review. This checklist does not approve the model or its use in game.

Open the generated preview and front/right/back views at 100% before considering runtime integration. Record pass/fail and reviewer notes for each item; do not infer approval from successful generation or import.

**Automated build observation:** v02 makes the facial features visible in the close view, but the generated full-body views still read as a continuous lower garment and show angular garment/skin boundaries. These are known visual failures, not owner approval; do not integrate this candidate.

## Appearance and silhouette

- [ ] Face reads clearly from front and 3/4 views; hair does not cross the eyes, eyebrows, nose or mouth.
- [ ] Both eyes are visible and aligned to the face; eyebrows are distinct without looking like raised beads.
- [ ] Nose and mouth remain legible in the close review preview under neutral lighting.
- [ ] Hair is visibly pulled back into a compact low arrangement; twists stay off the face and do not form broad flat strips.
- [ ] Front, side and back views describe one consistent head, hairline and body silhouette.
- [ ] The outfit reads as a fitted navy scrub top and separate straight-cut scrub trousers, not a dress, apron or exposed body under broken fabric.
- [ ] Garment boundaries, hems and sleeves have no jagged gaps, black clipping patches, z-fighting or skin showing through intended cloth.
- [ ] Shoes are cleanly placed and do not intersect the body or clothing; no unapproved badge is present.

## Asset and technical checks

- [ ] Compare v02 against the approved written Naomi spec; treat the reference board's precise likeness details as proposals.
- [ ] Confirm the mesh stays within the configured triangle budget and all three generated textures are embedded.
- [ ] Confirm the Blender file remains editable and the generated GLB imports in Godot 4.7.
- [ ] Review skin/fabric color and roughness at ordinary game-view distance; headless preview is not Mac renderer/performance evidence.
- [ ] Confirm owner appearance decision before attaching this asset to `staff_bennett`.

**Current disposition:** all owner-dependent visual items remain pending; no photorealism claim, animation approval, runtime integration, or target-device performance claim is made.
