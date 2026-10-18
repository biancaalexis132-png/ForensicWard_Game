# Naomi Bennett — Character Production Specification v1

**Project:** The Forensic Ward · Ashcroft State Forensic Hospital  
**Status:** Visual design proposal for owner signoff; pulled-back natural twists APPROVED. Not a completed 3D model or approval to alter narrative/clinical canon.  
**Identity key:** `staff_bennett` · **Role:** Charge Nurse.

## Authority and appearance

Repo `data/staff.json` establishes Naomi Bennett as Charge Nurse. `docs/design/VISUAL_PRODUCTION_REVIEW.md` records the original written character guide: Black woman, early 40s, navy scrubs, practical natural hairstyle. Her performance is practical, responsive, slightly dry, warm under pressure, and strongly patient-safety focused. Existing voice profile is `af_sarah` (voice direction, not proof of a final approved voice performer). **Owner decision in current session: pulled-back natural twists**.

The enclosed reference board proposes a single consistent look: adult Black woman in her early 40s with a mature yet approachable face, visible natural skin texture, soft under-eye and smile lines, dark brown eyes, and pulled-back medium-small natural two-strand twists tied into a low compact arrangement. Minor loose tendrils are *optional* and may be omitted for simpler rigging. No glamorized makeup or menacing horror styling.

**Owner review needed before lock:** precise facial likeness, skin shade, face shape, body proportions, twist size/length, earrings, whether to include grey scrub jacket, and whether to use a badge clip instead of a breakaway lanyard. Never infer final identity or badges from approximate AI-rendered text.

## Orthographic modeling and texture brief

- Produce matching front, left/right profile, back and 3/4 turnarounds from ONE consistent 3D base mesh; the AI reference collage is NOT accurate orthography. Maintain head proportions and skin tone across views.
- Professional navy-blue scrub V-neck top and matching straight-cut scrub trousers. Option: heather-grey zip scrub jacket for an evening variation, not a distinct identity. Functional shoes with non-slip soles, modest pockets, clipped ID or approved breakaway badge system. No dangly accessories, theatrical stethoscope, tactical gear or punitive imagery. Minimal jewelry only if unit policy allows; avoid projecting the AI board's hoop earrings as authoritative.
- Skin: physically based base color, roughness variation, subtle pore/normal detail at speaking distance. Do not exaggerate fatigue, illness, or skin blemishes. Hair: scalp base plus compact grouped twist geometry/cards, carefully authored alpha if used; test transparency and shadows in Godot.
- Rig: humanoid skeleton with predictable root, pelvis, spine, neck, head, shoulders, arms, hands and legs; eye aim and eyelids; jaw plus facial blendshapes or bone drivers. Document rest pose, bind pose, animation names and orientation.
- Animation priority: breathing idle; standing-to-walk; walk and turn; idle typing/chart review; conversational listening and eye contact; speaking with small gestures; neutral-to-concerned; reassuring smile; firm clarification; chair approach, sit, idle seated, rise. Avoid constant looping arm motion or exaggerated lip movement.
- Dialogue: start with natural blink and jaw-envelope/lip timing; expand to phoneme visemes only after a verified audio workflow. Sync facial animation to available/approved voice assets and subtitle timings. Preserve existing line IDs.
- Export: Blender source file and glTF 2.0 `.glb`; Godot 4.7 scene should instantiate one Naomi entity through the current character system rather than bypass it.

## Suggested provisional performance budget (requires device test)

Mac target: Apple Silicon MacBook Air, 8 GB unified memory, Godot 4.7. First benchmark: stable playable 30 FPS in Chapter 1 nursing station with Naomi plus actual UI/audio, rather than an empty scene. Initial **proposals**, not fixed quality/canon standards: character LOD0 approximately 20k–45k triangles incl. clothes/hair, 2K skin/face atlas if performance permits, 1K clothes and hair maps, compressed textures, no unnecessary 4K maps; LOD1 approximately half LOD0 and impostor/culling beyond conversational distance. Track triangle count, texture VRAM estimate, draw calls, material count, animation CPU, worst-frame time and peak memory. Reduce shader complexity before reducing facial readability.

## Production acceptance gates

1. Explicit owner signoff on the definitive face/uniform reference.
2. Licensed source mesh, textures and animations documented with usage rights and credits; no recognizable celebrity likeness.
3. Same character identity across front, side, back, 3/4, conversation and day/evening variants.
4. Correct role/title/appearance, no stigma/horror tropes, no unapproved named character details.
5. Mesh deformation, eye tracking, blink, mouth, walk, sit, listen, speak and handoff gestures reviewed.
6. Proper scale, orientation, skeleton animation import, collisions, nav and animation transitions in Godot 4.7.
7. Tested with Chapter 1 nursing station, audio, subtitle and player camera at actual Mac memory/performance limits.
8. All new source files staged without macOS `._*`, generated cache, secrets or irrelevant binaries; separate asset PR and code PR as needed. No automatic merge.

## Source precedence

Approved owner decisions / repo written guide > verified clinical and staff data > previous draft descriptions > generated reference illustration. This image is an *art direction reference*, not a geometric model, validated badge, licensed production mesh, or reliable orthographic blueprint.
