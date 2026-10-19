# Campaign 3D cast integration

The owner requested normal-gameplay 3D character integration after the completed narration delivery. The seven existing cast models now replace the greybox capsules wherever Chapters 1–5 already place those characters. This does not approve the draft likenesses, clothing, hair or final visual quality.

## Casting and placement

`data/character_visuals.json` maps character IDs to existing GLBs and marker-relative placement. `CampaignCastVisuals` validates this cosmetic catalogue and configures each actor before its `_ready`, so its animation, face, gaze and Naomi acting controllers see the imported model immediately. Models are not regenerated or rescaled. All existing chapter character lists, story conditions, dialogue, access and clinical logic remain unchanged.

| Character | Existing model | Integration |
|---|---|---|
| Naomi Bennett | `Naomi_Bennett_v07.glb` | Behind the nursing-station counter, facing the player side |
| Evelyn Voss | `Evelyn_Voss_v01_draft.glb` | Existing office marker |
| Marcus Hale | `Marcus_Hale_v01_draft.glb` | Existing chapter marker; standing clear of the office-chair position when using that marker |
| Leila Rahman | `Leila_Rahman_v01_draft.glb` | Standing beside the office chair |
| Facilities technician | `Facilities_Tech_v01_draft.glb` | Existing story-gated interview-room marker |
| Elias Ward | `Elias_Ward_v01_draft.glb` | Seated on the existing weighted interview chair |
| Mara Ellis | `Mara_Ellis_v01_draft.glb` | Same interview chair, only when her existing story condition is satisfied |

The imported humanoids face +Z; the authored markers use -Z as forward, so the catalogue supplies a 180-degree model alignment. Cosmetic position offsets move the whole actor, including collision and interaction area, rather than leaving an invisible interaction box at the old position. Inactive alternate characters retain their authored visibility/collision rules and now stop inherited skin/face/gaze processing until shown again.

## Animation, fallback and persistence

The existing `CharacterAnimationRig` still prepares neutral body loops, gestures, face morphs, dialogue visemes, gaze and shadow selection. Naomi's authored acting cues remain connected. No symptom animation or new clinical behavior is introduced. Lip sync remains the existing approximate text-based system, not phoneme-aligned performance.

Unknown, unavailable or invalid cosmetic assets retain the capsule fallback. Explicit `--character-preview=<id>:<version>` overrides still work; their historical transforms and standalone preview tests remain supported. Previewing one actor does not remove the normal models from other campaign actors.

Models, placement and review status are authored presentation data, not save providers. Loading and zone streaming reconstruct them from the current catalogue without storing model paths in saves or changing saved story progress. The narration layer, 38 recordings and all approved cutscene artwork are unchanged.

## Review

Run the normal project with Godot 4.7; no character-preview argument is required. Start with Chapter 1, verify Naomi and Voss, then the seated Elias interview. During normal progression, inspect Mara when introduced, Hale and the facilities technician when their conditions activate, and Rahman in later chapters. Check approach prompts, dialogue, patient replacement, save/load and return visits after streaming a zone.

Actual in-engine views are in `assets/renders/characters/campaign_integration_v1/` (seven cast portraits and two patient side views). `capture_report.json` records models and transforms. These captures use Linux Compatibility/llvmpipe with shadows disabled **only in the capture utility**; they establish geometric integration, not Mac/Metal appearance or performance. The utility independently loads chapter layouts and temporarily exposes hidden actors for inspection without changing story flags, so its HUD objective is not evidence of campaign progression. Normal gameplay keeps the existing lighting/shadows and story conditions.

To reproduce the views in a window:

```
Godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
  res://tools/characters/CaptureCampaignCast.tscn -- --output-dir=/path/to/review
```

Existing limitations remain visible in the models: shell-based clothing/hair and provisional likenesses. Final visual acceptance, refinement and Mac frame time require owner review; integration is not a photorealism or performance certification. See the latest `docs/AI_HANDOFF.md` entry for exact executed test results and branch SHA.
