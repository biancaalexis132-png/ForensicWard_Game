# Draft cast models with shared animation

- **Branch:** `claude/cast-models`, started from `claude/naomi-v07-refine` (merged to `main` as PR #84). Draft PR to `main`.
- **Owner request (2026-10-19):** "continue to finish all necessary animation and i will chec on my mac"; on the follow-up card the owner chose "Naomi, then cast": draft models plus the shared animations for the others, Voss and Hale first, then the technician, Elias, Mara and Rahman. **None of these models is approved**: geometry, likeness, ethnicity, clothing and Mac performance all wait on the owner.

## What exists now

Six draft characters, each with Naomi's rig, the ten shared clips and all 32 of Naomi v07's face morphs (10 expressions and blinks, 22 visemes), so they can talk with the same lip-sync and act with the same gestures.

| Character id | Model | Body (draft choice) | Clothing | Pose |
|---|---|---|---|---|
| `staff_voss` | `Evelyn_Voss_v01_draft` | woman, 52, 1.68 m | blouse, blazer, glasses, badge, chignon | standing |
| `staff_hale` | `Marcus_Hale_v01_draft` | man, 45, 1.83 m | shirt with standing collar, belt, radio and keys, badge, crop | standing |
| `staff_rahman` | `Leila_Rahman_v01_draft` | woman, 38, 1.63 m | sage V-neck blouse, trousers, badge, ponytail | standing |
| `staff_facilities_tech` | `Facilities_Tech_v01_draft` | man, 40, 1.76 m | work polo, khaki trousers, belt kit, boots, badge | standing |
| `pt_elias_ward` | `Elias_Ward_v01_draft` | man, 29, 1.78 m | grey sweatshirt, soft trousers, slip-ons, no badge | seated |
| `pt_mara_ellis` | `Mara_Ellis_v01_draft` | woman, 37, 1.62 m | top and open cardigan, soft trousers, slip-ons, ponytail | seated |

Elias has **no symptom movement**: only the shared neutral clips (his clinical presentation is PENDING_PSYCHIATRIST_REVIEW). The seated patients sit on nothing yet; the greybox has no chair at `MARK_Seat_Patient`.

## Pipeline

Each character is one JSON file in `tools/blender/characters/cast/` and four stages (intermediates go to the git-ignored `build/cast/`):

1. `tools/blender/characters/build_cast_member.py --config cast/<id>.json`: MPFB base body (male Base_v01 or female Base_v02) shaped by age, ethnicity mix, muscle and weight; Naomi's rig fitted (limb joints refitted to the skin, which fixed male shins and feet sitting 4 to 6 cm high); optional seated rest pose; skin, garments, accessories, hair; writes the three profiles below.
2. `tools/character_animation/build_animated_character.py --profile profiles/<id>_v01_anim.json --no-render`: the ten shared clips.
3. `tools/character_animation/transfer_face_shapes.py --profile profiles/<id>_v01_face.json`: Naomi's 32 morphs, matched vertex by vertex through the shared base mesh and scaled by eye spacing.
4. `tools/character_animation/refine_character.py --profile profiles/<id>_v01_draft.json`: Naomi v07's lash, lid, hem and shoe clean-up.

`tools/character_animation/review_cast_member.py --profile profiles/<id>_v01_draft.json` renders the review sheets: `assets/renders/characters/<Display_Name>_v01_draft_review_{body,face}.png` (rest, listening, chart gesture, greeting nod; neutral, two expressions, three visemes) plus `_v01_draft_refine_sheet.png` (blink and hems) and `<Stem>_v01_sheet.png` (static turnaround).

Tops are cut from a cloth proxy of the body that fills hollows and rounds points, so cloth does not cling to the chest.

## In game

`CharacterVisualPreview` has a `v01_draft` candidate for all six (default version for each). Preview stays off unless asked for:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --character-preview=staff_voss,staff_hale,pt_elias_ward
```

Only Bennett, Voss and Elias have markers in the Chapter 1 greybox; the others attach where their chapters place them.

## Known limitations

- Hair is a painted shell: it reads as a cap or helmet, with visible strand stripes.
- Clothes are offset shells; they do not fold or drape, and the chart gesture's hand presses into the trouser leg on the wider bodies.
- Faces, ages and ethnicities are draft choices for the owner to change in the JSON configs.
- Lip sync is the existing text-based track (no phoneme timing).
- The facilities technician's renders are named `Facilities_Technician_*` and its model `Facilities_Tech_*`.
- Mac frame time not measured. Six extra skinned characters have not been tested together on the Mac.
