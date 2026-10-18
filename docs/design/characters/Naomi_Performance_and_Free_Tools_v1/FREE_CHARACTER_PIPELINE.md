# Free Character Toolchain — Decision and License Notes

**Recommended workflow (not yet validated on this Mac):** MPFB (MakeHuman in Blender) → sculpt and customize Naomi in Blender → rig and animate (Blender native and/or Mixamo) → convert and optimize GLB → Godot 4.7; Copilot can automate Blender Python scene prep, export, file manifests and GDScript interactions, but cannot obtain restricted asset licenses automatically.

## Options

| Tool | Role | Cost/licensing note | Caveat |
|---|---|---|---|
| **MPFB2 / MakeHuman** | Generate proportionate adult humanoid base, wardrobe and rigs | Free/open-source. Their **bundled assets** and output are under CC0 per license; **third-party downloads may differ**. https://github.com/makehumancommunity/mpfb2 | Best starting point for realistic Naomi, still requires skilled face, twist hair, scrubs and shaders. Verify installed Blender add-on compatibility. |
| **Blender** | Face refinement, twists, scrub mesh, textures, rig, animation, GLB export | Free/open-source; https://www.blender.org | Mac 8GB: limit texture size, render samples and simultaneous apps. |
| **Adobe Mixamo** | Auto-rig and human locomotion/action animations | Free with Adobe ID; licensed for commercial games per official FAQ: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html | Some restrictions on redistribution of raw character/animation assets; public GitHub source must be checked against license; use appropriately restricted asset management. Facial performance not provided. |
| **VRoid Studio** | Fast avatar creation and stylized hair | Free; creator guidelines permit many commercial game uses but third-party asset terms apply: https://vroid.com/en/studio/guidelines | Anime/stylized by default; **not recommended** as Naomi's final photorealistic base. |
| **Godot** | Runtime character scene and animation tree | Free/open-source; GLB/glTF recommended for character export: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html | Imported rig, clip naming and lighting need testing. |

## Source-control and production rules

- `docs/design/characters/`: approved reference images, specifications and provenance statements.
- `assets/blender/characters/`: authored `.blend` source, **only** if all embedded content may be redistributed in the repo.
- `assets/exports/characters/`: `.glb` for game runtime, respecting all licenses; do not push raw restricted animation libraries indiscriminately.
- `scenes/characters/`: reusable `.tscn` character scene; keep `staff_bennett` mapping.
- `docs/ASSET_PROVENANCE.md`: URL, author, asset title, license, date retrieved, modifications, allowed redistributions, storage policy.
- `.godot/` and `._*` AppleDouble metadata stay out of Git. Make a safe APFS clone rather than repairing Git pack indices destructively on exFAT.
- Generated reference art is visual direction, **not** a mesh and not proof of real-world licensing for an unrelated base model.

## Small PR progression

1. **Review:** confirm MPFB works in installed Blender and asset licensing; update provenance, create no scene changes.
2. **Base mesh:** build Naomi-like adult geometry and approved costume; export to GLB; inspect in neutral lighting; do not claim final portrait match.
3. **Rig and movement:** skeletal locomotion and seated interaction, deterministic animation test scene.
4. **Facial performance:** expressions, voice cue hookup, lip-sync approximations, clipping fixes.
5. **Chapter 1 integration:** nursing-station scene, dialogue and existing content tests, Mac frame-time and memory QA.

No feature work should overwrite another agent's active branch or prematurely merge to main. Handoff after each milestone, with branch, SHA, test evidence and next action.
