# Cast v02: hair and clothing (Claude Code, 2026-11-05)

## Objective

Bi (2026-10-19): "I approve all cast models ... Create completed cast models. Improve hair and clothing." This branch finishes the six campaign cast models as v02: Evelyn Voss, Marcus Hale, Leila Rahman, the facilities technician, Elias Ward and Mara Ellis. The game now loads v02. The v01 draft files are kept.

## Branch and PR

- Branch `claude/cast-hair-clothing`, from `main` after #100, with `origin/main` `b1c3e63` (#133) merged in. It ships as a draft PR to `main`, and Bi merges it.
- Commits: tooling (`39b3d7c`), owner approval and v02 defaults (`26b37f0`), models checkpoint (`5aab249`), hair refinement (the "Cast v02 hair" commit), the merge of main, and the clips/neckline/docs commit on top.

## What changed

**Clothing** (`tools/blender/characters/cast_garment_detail.py`, `build_cast_member.py`):
- Garment trims: blazer lapels and buttons, pockets, cuffs and trouser hems.
- Baked fold normal maps, and jacket skirts that hang straight below the waist.
- Reading-glasses lenses for Voss.

**Hair** (`tools/blender/characters/cast_hair_cards.py`):
- Layered alpha-scissor hair cards over a thin, dark scalp base, with a procedural strand atlas.
- Chignon (Voss): combed cards to the tie, plus a wrapped bun of cards.
- Ponytail (Rahman, Mara): combed cards, plus a tail of cards round a slim core.
- Crop (Hale, technician, Elias): short cards radiating from the crown.
- The refinement in this session fixed the first v02 pass, where the cards read as wide tiles with hard roots and spiky outliers:
  - Narrower cards (6 to 9.5 mm) at about twice the density.
  - Strand starts staggered over a 2.2 cm root fade.
  - Combed cards laid in one shell over the scalp base in three thin layers, with no per-card arc.
  - No flyaways on the chignon and ponytails.
  - Flatter crops with tapered tips.
- The config key is `hair.layered_cards`. It is separate from the ward-round patients' `hair.cards` system on main (a different implementation in `build_cast_member.py`), so patient configs still build exactly as before.

**Post-merge steps on the v02 models:**
- `tools/character_animation/add_motion_clips.py` now derives the anim-profile and report names from the profile's `version`, so it accepts `_v02` profiles. It added main's walk, arm-swing and six gesture clips: 18 clips for standing characters, and 15 for seated Elias and Mara.
- `tools/character_animation/tuck_neckline.py` was run on `Elias_Ward_v02.blend` (`Elias_Sweatshirt`) before his GLB export. This is the same shoulder-seam fix main applied to v01.

**Data:**
- `data/character_visuals.json` points the six cast entries at `*_v02.glb`, marked `OWNER_APPROVED_VISUAL` (Bi, 2026-10-19).
- The file-level status stays `PENDING_OWNER_VISUAL_REVIEW` because the ward-round patient drafts are still unreviewed.
- No clinical content changed.

## Outputs

- `assets/exports/characters/*_v02.glb` (7.2 to 9.2 MB) and `assets/blender/characters/*_v02.blend`.
- `assets/asset_manifest/*_character_manifest_v02.json`.
- Profiles in `tools/character_animation/profiles/*_v02*.json`.
- Reports in `tools/character_animation/reports/*_v02_*`.
- Review sheets: `assets/renders/characters/<Name>_v02_{review_body,review_face,refine_sheet,sheet}.png`, also copied to `/mnt/project-files/cast_v02/` for Bi.
- Triangles, refined: Voss 54k, Mara 56k, Rahman 46k, Elias 41k, Hale 38k, technician 37k. Each is within the 8 GB M1 budget used for the v01 drafts.

## Rebuild

Run from the repository root with the bpy 5.2.2 module, for each `<id>` in `staff_voss staff_hale staff_rahman staff_facilities_tech pt_elias_ward pt_mara_ellis`:

1. `build_cast_member.py --config tools/blender/characters/cast/<id>.json`
2. `build_animated_character.py --profile tools/character_animation/profiles/<id>_v02_anim.json --no-render`
3. `transfer_face_shapes.py --profile .../<id>_v02_face.json`
4. `refine_character.py --profile .../<id>_v02.json`
5. `review_cast_member.py --profile .../<id>_v02.json`
6. For Elias only: `tuck_neckline.py --blend assets/blender/characters/Elias_Ward_v02.blend --garment Elias_Sweatshirt`
7. `add_motion_clips.py --profile .../<id>_v02.json`

The review sheets were rendered before steps 6 and 7. Those steps change only Elias's shoulder rim and the GLB clip list.

## Tests

See the AI_HANDOFF log entry for the full QA result on the final commit. The Mac was not run.

## Owner approval

Bi approved PR #136 in the project thread on 2026-11-05 08:02 UTC ("approve"). The PR was marked ready for review; Bi merges it.

## Pending / next

- Bi merges PR #136.
- A thin dark sliver can still show on Elias's far shoulder at a 3/4 angle. A larger `--band-m` would close it if Bi notices it.
- The hair is game-ready alpha-scissor cards, not strand simulation. Further realism would need hand-authored hair textures.
