# Character production audit and Naomi Bennett-first proposal

2026-10-17 · **Proposal for owner approval before substantial modeling.** No character model, animation controller, facial rig or new clinical content is implemented by this document.

## What actually exists

Main inspected: `052859a984d7db599282914cbc300cc8cecc887b` (PR30). Proposal branch is stacked on screenplay/canon work at `0ead6cbd79710577852ab9a79522a5a61b960a46`. Open PR API now responds; list was empty at inspection. No other character-production file claim was found in the active table. Recheck before runtime work; do not assume remote users are inactive.

| Asset/capability | Evidence | Actual status |
|---|---|---|
| Runtime people | `scenes/props/Character.tscn`, `scripts/world/Character.gd` (`WardCharacter`) | Grey capsule mesh, static collision and name label; no humanoid geometry, rig, animation or facial features |
| Character placement | `scripts/world/AuthoredWorld.gd::_build_characters`, `data/world_chapter1.json` | Spawns Voss, Bennett and seated Elias at existing markers; floor origin/marker orientation preserved; Hale/Rahman/Mara not instantiated there |
| Character interaction | `WardCharacter` | Staff info/situational line, access grants and optional clue verification; patient opens InterviewScreen. This working logic must survive visual replacement |
| Seated pose | `WardCharacter._ready` | Squashes only `$Body/Mesh` Y-scale to0.65 and disables collision. This is a greybox silhouette, not a seated skeleton/animation; never apply it to a final skinned person |
| Tracked 3D exports | Binary JSON inspection of **all138 GLBs** | **0 skins, 0 animation clips, 0 morph-target primitives**. Existing exports are environment/prop assets, not a licensed character library. No tracked FBX/glTF/OBJ/DAE/BVH/VRM alternatives found |
| Blender sources | Ten `.blend` files under clinical/modular/security/research/historic | Environment/prop source families and generators exist; no character-named source. All ten compressed headers identify `v0500`; source pipeline docs require Blender5.0+. Local Blender4.3.2 failed opening first file (“incomplete header, may be from a newer version”). Full source armature/action inspection **not completed**; do not claim zero internal rigs solely from names |
| Environment toolchain | `tools/blender/fw_lib.py`, `fw_assets.py`, build scripts, `docs/ENVIRONMENT_PIPELINE.md` | Procedural architecture/props, GLB/marker/material/manifest utilities. Not a character topology/sculpt/retopology/rigging workflow. Do not extend box/sphere builders into “realistic production humans” |
| Original written guide | `.../Individual_Characters/Ashcroft_Character_Reference_Guide.pdf` | Six written casting/wardrobe/performance descriptions; read text directly. Old Rahman Staff Psychiatrist and Mara Ch1 labels superseded by owner amendments |
| Reference art | Six original portraits + six `Regenerated_2026_10_17/*_candidate_v2.png`, prompts/hash manifest | **2D reference only**. New six sheets on preceding feature branch, not main; candidate faces/technical consistency/rights still pending. Naomi original and corrected candidate visually re-inspected. No sheet is verified orthography, geometry, texture or likeness approval |
| Voice/subtitles | `audio/voice_profiles.json`, `data/narrative/chapter1.json`, existing OGGs/audio manifest | Bennett `af_sarah`, three provisional voiced lines; play_line supports optional spatial emitter, ducking and subtitle lifecycle. Lines remain provisional/pending listening/clinical review; no replacement or new casting here |
| Facial/locomotion systems | Search scripts/scenes/systems/tools | No character `Skeleton3D`, `AnimationPlayer`, `AnimationTree`, visemes, facial blend-shape controller, retarget pipeline or NavigationAgent3D found. No reusable skeletal clip library, crowd controller or foot/hand IK |

Only the final sentence's searched locations and tracked model formats establish that scope; private Claude tools/assets are not assumed accessible. Current shipped people are not production-ready realistic characters. Prior successful GLB tests validate environment imports, not skinning, facial quality or runtime character performance.

## 1. Corrected appearance specification

Authority: owner decisions → GDD amendments/`CHARACTER_VISUAL_CANON.md` → written guide; generated pictures cannot resolve contradictions.

| Character | Required appearance/presentation | Still selectable/reviewable |
|---|---|---|
| Naomi Bennett | Charge Nurse; Black woman, early40s; practical natural textured hair, navy scrubs, comfortable work shoes, generic hospital ID. Warm, direct, observant, competent professional | Exact original face, skin shade, height/build, hair arrangement and scrub details; select one consistent production design without inventing biography |
| Leila Rahman | Consultant Psychiatrist; South Asian woman, late30s; business casual/appropriate clinic coat, ID/notebook; clinically rigorous and warm | Exact face/hair/optional accessories; no invented nationality, faith or duties; never pharmacist |
| Marcus Hale | Security Director; man mid40s; institutional charcoal uniform, radio/role badge, practical grooming | Exact face/skin tone/build; no tactical vest, military silhouette or psychiatric authority |
| Evelyn Voss | Medical Director; woman early50s; polished charcoal/navy tailoring, neat hair, understated jewelry | Written guide does not set ethnicity; original mature face, no villain coding |
| Elias Ward | Man29; clean ordinary inpatient clothes and grooming, respectful human presentation | All clinical movement/expressions require their own review; no disarray/diagnostic silhouette as identity |
| Mara Ellis | Woman37; ordinary slightly fatigued appearance, everyday clothes/cardigan; significant recurring patient introduced Ch2 | Voice/face/property specifics and clinical acting remain reviewed separately; autonomous care story, no supernatural witness role |

Bennett candidate now broadly communicates the written brief, but its front/profile/back silhouette, face, hands, shoe sole scale, garment folds and A-pose are not metrically reconciled. Original portrait wording and face are not equally authoritative. No generated face is approved merely because ethnicity/role are correct. Avoid recognizable actor likenesses and caricature; review skin under neutral and actual ward illumination.

## 2. Production turnaround gate

Artist-clean front/back/left/right orthographic views at one measured scale, neutral A-pose and separate hand/finger poses; three-quarter views for shape, not measurement. Include head front/profile/three-quarter, ears/hairline/nape, textured-hair construction, garment seams/looseness, shoe silhouette, ID attachment. Owner selects height/proportions/face rather than copying earlier proposed numeric heights.

Supply neutral plus attentive/concerned/reassuring/firm facial sheets, eyelid closure and mouth-open/lip-contact references; consistent facial landmarks across views. Separate naked anatomical topology reference from approved visible clothing as an artist source, never a game requirement. No patient-ID text or personal biography on badge. Validate head/body alignment, shoulder/arm reach, normal human anatomy and outfit design before modeling. Review status, author/tool, exact source references, hashes and commercial-use clearance recorded. References are requirements, not automatic proof of correct rig anatomy.

## 3. Game-ready model workflow and licensed resources

**Recommended:** an original Bennett sculpt/retopology by a character artist in Blender5.x, optionally starting from a separately cleared neutral commercial-use humanoid base mesh. Do not purchase/download a pack on this proposal alone. A tool's license does not establish the license of its output, bundled hair, skins, clothes, animation or scan subjects. A base mesh/library candidate needs exact SKU/version, source URL, receipt/license snapshot, game redistribution/derivative/rig rights, attribution and modification/source-sharing limits. Prefer original assets or explicit CC0/perpetual game rights that permit the required source handling. Reject editorial-only/noncommercial assets, unclear scraped scans and recognizable people. CC-BY assets require delivered attribution; no default approval of any marketplace or vendor.

Workflow: approved technical concept → anatomically credible sculpt/base customization → retopology with deformation loops at face/shoulders/elbows/hips/hands → closed garment geometry and footwear → UVs/material partition → baked detail → low/high/LOD comparison → deformation rig/weights → expressive face/visemes → Blender review → exported GLB → Godot lab → ward integration → actual Mac acceptance. Keep hands, oral cavity, eyelids, eyeballs and close-up facial silhouette credible. Hidden body surfaces can be culled only where outfit never exposes them during movement; retain an editable source.

Use one character family directory, separate from generated environment scripts, e.g. proposed `assets/characters/naomi_bennett/{source,exports,textures,provenance}`; `.blend` plus export preset/readme, GLB, texture sources/licenses, hashes and exporter/Blender versions. No new LFS patterns without owner review of checkout/CI impact. Preserve third-party contractual source restrictions: if source cannot be distributed in this repository, record approved secure location/access and obtain an allowed export; don't leak a licensed source. No private source package is presumed available.

Pin one Blender5.x patch/exporter after compatible open/export smoke test; installed4.3.2 is insufficient for existing5.0 sources. Do not resave/downgrade environment files or regenerate the hospital to install a character workflow. Direct `.blend` import would depend on Blender on each machine; ship versioned GLB plus editable source instead. Build/render/bake offline on an appropriate workstation, not at runtime on the8GB Air.

## 4. Rig and skeletal animation contract

One documented rest pose, metre scale, floor-centred root and forward convention (Blender+Y → Godot−Z, with export verified); neutral object transforms, no negative skeleton scale. Separate a rich Blender animator control rig from an export **deform-only skeleton**: root → pelvis/spine/chest/neck/head, clavicles/arms/hands/fingers, legs/feet/toes, limited twist helpers. Target ≤80 deform bones, four normalized nonzero influences per vertex. Bake constraints/IK to deformation keys; export no helper cameras/lights/control bones. Pin bone names/parentage/rest matrices in a rig manifest and test retarget on different approved proportions before cast expansion.

Use Godot Skeleton3D with AnimationPlayer clips and AnimationTree for locomotion/upper-body layers. First slice stays at Bennett's station: idle/breathe, look-at/attention, modest handover gesture and return-to-idle. Later walking/turn/stop, seated transitions and task interactions need authored motion and path/movement ownership. Use in-place locomotion with controller-owned translation as the default; don't combine duplicate root motion and physical translation. Define pelvis/root tracks and seat/hand/foot anchors explicitly. Future IK/gaze is constrained, subtle and optional at distance; no 180° head snaps. Validate Godot4.7's current API before writing controller/IK code.

Animation changes are presentation; do not infer clinical state/trust/consent from pose or generate medical effects. Patient reduced movement, posturing, examination response and other symptom-specific performance require clinical review. Shared rig does not mean shared stereotyped mannerisms.

## 5. Face, dialogue and lip-sync

Start with blink L/R, gaze/eyelids, jaw/open-close, lip seal/pucker/spread, corners, brows and a small artist-reviewed set of visemes. Target ~24–32 morph shapes; cap simultaneously active close-up shapes (~8) and validate no topology change between targets. Neutral/attentive/concerned/reassuring/firm are layered authored expressions, not mood/diagnostic meters. Eye/mouth interiors and eyelid fit must work at conversational distance. Optional jaw/eye bones must not double-drive morph motion.

Existing `AudioDirector.play_line(line_id, emitter)` and EventBus subtitle_shown/cleared provide line lifecycle, but **not a verified audio playback clock or phoneme timings**. Proposal: offline reviewed phoneme/viseme cues, per-line sidecar keyed by stable line ID, clip SHA256, seconds, viseme name/weight. Choose/clear a timing tool separately (or hand-author first short clip); no voice cloning, inference service or language model runtime. Drive cues from a supported playback-clock adapter after a bounded audio contract review; do not reach into `_current_voice` internals or treat subtitle duration as word alignment.

Test mute, pause/resume, skip, replacement, subtitle-only fallback, missing/mismatched cue hash and zone-unload. Reset mouth to neutral on stop/unload; silence must not leave a speaking face. Missing cues show neutral expression/subtitles rather than random mouth flapping. Runtime uses the existing synthetic voice/profile and approved line text; first visual lab can use a reviewed existing **nonclinical** greeting excerpt for timing, without changing shipped narrative wording. If excerpt text/audio differs, give it a new lab-only ID/manifest, not an existing production line ID. Owner narrative/listening approval before production use.

## 6. Hair, skin, clothing and PBR

Model natural textured hair as controlled mesh clumps plus restrained hair cards/alpha scissor where useful; no runtime strand simulation or vast transparent layers. Preserve hairline/texture dignity and silhouette at all LODs. Baked scalp/occlusion and low overdraw matter more than strand count. Hair design must first match selected technical reference.

UV/bake original high-resolution detail to glTF metallic/roughness PBR maps. Base colour authored without painted lighting; sRGB base colour, linear normal/roughness/metal/AO; confirm tangent/normal convention and ORM channel mapping on import. Skin should retain hue/detail at Black skin tones under neutral and ward lights, with physically plausible roughness and modest specular, not over-bright albedo/flattened “skin tint.” Subsurface scattering is optional quality tier, not a baseline dependency. Eye/cornea use limited layers with tested sorting/reflections; no real-time mirrors required.

Scrubs: authentic loose navy fabric, seams/normal/roughness, skinning plus corrective shapes for shoulder/elbow bends; no runtime cloth required for slice. Shoes, badge and practical accessories constrained to body with bounded draw calls. Bake garment folds, not hundreds of skinned decorative pieces. No fabricated real hospital logo or personal data. Test wrists/neck/hips, garment-body intersections and seated/walk deformation. Licensed scan/cloth/hair textures require separate asset clearance.

## 7. Godot4.7 integration without replacing working systems

Proposed visual `NaomiVisual.tscn`: GLB instance/Skeleton3D, animation controller, optional mouth/emitter/eye markers and shared materials. Keep WardCharacter interaction ID, label, body collision and staff access/verification behavior. Add visual attachment behind a narrow reviewed seam with capsule fallback for missing assets; don't mutate imported scenes or replace ContentRegistry/TrustManager.

`AuthoredWorld` currently constructs one CHARACTER_SCENE and tracks typed WardCharacter; a resource mapping keyed by `staff_bennett` can select the approved visual without changing patient/staff identity. Preserve `MARK_Character_NurseBennett`, marker rotation and F2 zone ownership. Keep floor-origin placement; do not reuse squash-to-seat or force seat-height rules for the new skeleton. Future seat metadata/controller is a separate tested change. No authored navigation or room enlargement in first slice.

F2 unload must free mesh/animation/audio attachments, unsubscribe events and stop mouth/gaze tasks; reload reattaches a fresh visual at saved logical location. Animation phases/blinks are transient presentation, not a reason for save-version bump. Any later durable NPC location/task schedule needs explicit provider/migration review. SaveManager v3/F1 history remain unchanged. Lab loads only a small character stage or existing nursing-station zone, not all five chapters/levels. Test no collisions blocking player/doors and keep interaction reach unchanged.

## 8. Reusable animation library

| Set | First deliverable | Expansion gate |
|---|---|---|
| Neutral professional | standing idle, listening, small handover gesture, acknowledge/turn head, return to rest | Bennett art/deformation quality approved; avoid loops that look robotic |
| Locomotion | later walk/turn/start/stop, unobtrusive avoidance | Navigation/physics scope and root-motion policy tested separately |
| Work tasks | later seated idle/sit/stand, chart review, desk interaction | Furniture/hand/seat anchors; no floating hands or stature-based mesh scaling |
| Conversation | blink, gaze, reviewed expression/viseme set | Audio clock/skip contract and close-up approval |
| Patient performance | ordinary movement/agency as authored; no automatic diagnostic pose | Patient-specific clinical review before symptom/exam motion; never reuse staff clips as clinical evidence |

Store canonical authored clips separately with source skeleton/rest pose, duration/frame rate/loop/root policy, rights/provenance and retarget verification. Shared motion libraries retarget to each body, with per-character timing/correctives and no ethnicity/diagnosis stereotypes. Do not expand to the remaining cast until Bennett's model→rig→face→clip→Godot→Mac pipeline passes end to end.

## 9. Provisional performance budgets and measurement

These are proposed acceptance targets, not achieved measurements. First establish an empty/greybox ward baseline on the owner's actual8GB Apple Silicon Air (exact chip/OS/resolution recorded). Desktop headless renderer results do not substitute for Metal.

| Resource | Initial target for the vertical slice |
|---|---|
| Visible geometry | Bennett LOD0 ≤45k triangles including clothes/hair; LOD1 ≤22k, LOD2 ≤8k; artist-managed face/morph/skinning validation per LOD, not blind decimation |
| Skeleton/weights | ≤80 deform bones, ≤4 influences; throttle distant updates, full rate only near conversation |
| Surfaces | ≤6 material surfaces/draw submissions per visible LOD before shadow passes; count real draws/overdraw, not material-file names |
| Textures | head/body base+normal up to2K; ORM1K; hair/accessories1K or smaller, eyes512 as starting point; mipmaps and measured supported Mac compression |
| Character residency | aim ≤128MiB incremental GPU resources/character including mesh/morph/texture; measure actual imported format. CPU allocations/source copies separately counted; no guarantee from disk size |
| Active cast | initial1 hero; stress2 near +4 distant in the loaded ward; shared resources, reduced distant face updates/shadows; off-zone visuals freed |
| Frame target | target60fps/16.7ms at a recorded practical render resolution, acceptable floor30fps/33.3ms after sustained thermal load; character incremental CPU ≤1ms/GPU ≤2ms for stress mix as a starting budget |
| Whole game | target sustained process footprint ≤3GiB, investigate peaks >4GiB; observe OS memory pressure/swap and GPU/shared allocations, don't double-count unified resources or call this an OS memory guarantee |

A 2K RGBA8 texture is16MiB before mipmaps (~21.3MiB with full chain); six such maps already use~128MiB before hair/meshes. Therefore ORM/accessory reductions and actual compression are necessary, not optional hand-waving. Do not assume every texture compresses to the same format/size. Full facial morphs duplicate vertex data; measure them at import/VRAM, remove unused targets and preserve corresponding LOD topology/weights. Animation key reduction verified against facial/body quality; no disabling animation to claim a full slice passes.

Profile baseline, Bennett only, stress mix, close-up dialogue, zone-unload/reload20cycles, worst lighting/shadows, mute/pause/skip and15–30minute thermal run. Capture frame p50/p95/p99, main/animation CPU, GPU time, triangle/draw count, texture/mesh memory, process footprint, OS pressure/swap and stutter. Use Godot monitors/profiler plus Instruments/Activity Monitor on Mac; record tool/version/resolution/render scale and before/after samples. Lower tier: reduced shadow casters, LOD, face update range, hair layers and texture resolution; preserve readable face and correct skin tone. No clinical/narrative evidence changes with graphics tier.

## 10. Small PRs and explicit approval gates

| PR | Scope | Required acceptance |
|---|---|---|
| P0 this proposal/audit | Verified inventory, corrected canon, chapter3 boundary, budgets and recoverable handoff | Owner approves Bennett workflow/art direction/budget/procurement route; no modeling yet |
| P1 technical reference + license selection | Artist-clean Bennett orthographic/face/hair/clothing pack; exact base mesh/tool/resource rights if used | Owner selects original face/appearance; commercial/source handling verified; compatible Blender5.x baseline recorded |
| P2 Bennett body/outfit GLB | Anatomically credible sculpt/retopo/UV/PBR + .blend/manifest/LOD; small lab preview | Owner/artist silhouette/skin/clothing close-up review, topology/material/import budgets, no capsule masquerading as human |
| P3 body rig + first clips | Deform skeleton/weights, idle/listen/handover/return, source/baked export | joint extremes/loop seams/finger and clothing checks; Godot4.7 skin import/playback validated; no new medical gestures |
| P4 face + one timed line | Expressions/visemes and reviewed sidecar; narrow audio adapter after coordination | blink/lip contact/eye quality; mute/pause/skip/unload/subtitle-only/clock mismatch tests; license/listening/narrative approval |
| P5 ward integration | Visual selection for staff_bennett, capsule fallback elsewhere; retain markers/interactions/F2 | full QA; no duplicate grants/verification, save compatibility, unload/reload stability, Mac acceptance/performance |
| P6 library/next person | extract validated reusable skeleton/clips/material conventions | Bennett whole pipeline approved first; separate character casting and patient clinical movement gates |

P2–P5 build one complete pipeline, not independent promises that count as a finished character. Asset-heavy PRs can split source/texture review where checkout constraints require, but retain a reviewable export+source provenance pair. Only P0 work is undertaken now. No exact paid asset/vendor choice, LFS policy change, external upload or major code rewrite is authorized by this proposal.

## Earliest realistic milestone and missing dependencies

**First animated Naomi in Godot:** one recognizably canon-consistent, textured and skinned Bennett in an isolated Godot4.7 stage, idle/listening/handover animation and neutral fallback face. This can precede lip-sync/world integration, but must be called an animation/deformation milestone, not “complete production character.” Earliest responsible sequence is P1→P2→P3 after owner art/workflow approval and character-artist availability. No ready character exists to integrate immediately.

Planning estimate (not a delivery commitment): with one experienced artist/technical animator available and a legally cleared adaptable base, ~1–2 focused working weeks to the first credible animated lab milestone; ~3–6 weeks total for complete face/voice/LOD/ward/Mac acceptance including iteration. Original topology/sculpt, licensing delays or unavailable art support can extend this considerably. Pure from-scratch work should not be scheduled on the base-mesh estimate. Re-estimate after P1 proves topology/rights/rig fit; an AI portrait does not remove artist work.

Dependencies missing/unvalidated: approved exact face/technical turnarounds; character artist/time and source base/texture/motion licenses; character source topology/UVs/rig/weights/morphs/clips; selected compatible Blender5.x runtime/export profile (only4.3.2 installed); audio phoneme timing/clock adapter; face/skin/material review; actual8GB Mac profiling; voice line narrative/listening approvals. Existing character guide and candidate references are accessible; private approved v1.1 bible and full clinical sources are not replaced by the new draft. No clinical rule or supernatural implementation is needed to demonstrate Bennett.

## Chapter3 continuation boundary

Owner now approves **Chapter3 as the first actual entry into WardZero, via a formal Security and Facilities inspection**. Supervision, safe return and independent evidence preservation are planning requirements; newly drafted dialogue and the possible repeated junction/temporary navigation discrepancy remain proposed. This does not authorize corridor-loop mechanics, supernatural evidence confirmation or new clinical logic. Current F2 WardZero remains an unbuilt placeholder; earlier evidence inspection of records/doors is not physical entry. Future entry/access checks must prevent accidental Ch1/2 entry without rewriting the existing world on this documentation change.

Exact new inspection scene text has not been supplied beyond the summary; do not claim line-by-line review of it. Existing package Ch3 generic supervised inspection is compatible with approved placement, but proposed Ch4 corridor repeat and new Ch3 possible repetition need an owner decision about perception vs independently verified contradiction and revelation timing. Retain chapter3 placement while leaving mechanics/content gates open. No new canon date/signatory or D4–D9 resolution is inferred.

## Executed validation

Tracked inventory/binary GLB audit:138 files, zero skins/animations/morph targets. Written PDF read and Naomi original/candidate visually inspected. All10 Blender source headers safely decoded read-only as5.0; installed4.3.2 cannot open source (diagnosed version mismatch, no files changed). Code search and scene/voice/marker inspection above are static evidence, not rig playback. Full standard Godot4.7 QA launched at proposal start; final counts in living handoff. No production character/animation visual validation or actual Mac test can run without the assets/hardware. Proposal changes are docs only; no assets, shaders, clinical or narrative runtime files changed.
