# The Forensic Ward — Naomi Bennett: Chapter 1 Performance Blueprint v1.0

**Status:** Production-direction proposal based on owner-approved Naomi likeness, pulled-back natural twists, navy scrubs and Charge Nurse role. Dialogue excerpts below are **acting examples**, not replacements for shipped dialogue. Compare all voice cues to existing `audio/voice/voice_lines.json` and `data/dialogue.json`. No clinical decisions are authorized by this document.

## Character performance identity
Naomi Bennett (`staff_bennett`) is an experienced charge nurse: attentive to patient safety, direct, warm under pressure and dryly funny. Her face balances approachability and authority. She never appears threatening, supernatural, melodramatically frightened or theatrically exhausted. Staff realism is shown through small actions and professional pacing.

## Chapter 1 encounter blocking

| Beat | Player trigger | Naomi action | Face/gaze | Sound/technical cue | Transition |
|---|---|---|---|---|---|
| 00 Nursing station baseline | Player enters station range | Types short EHR entry; pauses to check handoff sheet; weight shift | Neutral, eyes on screen/clipboard | Ambient nursing-station loop only | Interact-ready without teleport or instant snap |
| 01 Notice new physician | Player approaches talk marker | Look up; finish one task; rotate shoulders/head before body | Brief attentive glance, small welcome | Optional natural breath; no music sting | Uninterrupted proximity-safe talk initiation |
| 02 First greeting | Dialogue event supplied by existing script | Hands settle at desk edge; open hand toward census | Welcoming but brisk; natural blink | Route approved Bennett voice file; subtitle exactly matches authored line | Camera remains player-controlled unless existing director requires otherwise |
| 03 Handoff about Elias | Approved dialogue event | One-hand indication toward authorized summary; returns hand to clipboard | Focused, steady eye contact, brief gaze to paperwork | Voice line + subtitle; short pause after clinical information | Never invent diagnosis or imply paranormal attribution |
| 04 Player follow-up | Dialogue choice | Listening posture, minor head nod; no repeated gestural loop | Curious/firm as appropriate | Pause/resume between dialogue lines; no overlap | All choices preserve essential information |
| 05 Workload humor | Existing approved line (if available) | A restrained half smile as she resumes sorting paperwork | Light amusement | No laugh track | Reverts to practical neutral |
| 06 Conversation ends | Player exits conversation | Glance to task list; resume documentation | Neutral/task-focused | Audio fades naturally; text UI closes | Interaction can be re-entered safely |

## Animation catalogue: production requirements

**Core locomotion:** stand idle, walk forward, turn in place, walk-stop transitions, sit down, seated idle, stand up. Root motion strategy must match current Godot controller; default in-place until audited.

**Workstation interaction:** standing typing, seated typing, clipboard check, paper handoff, point toward workstation, pen note. Props attach to appropriate hand bones or are fixed to station; no floating or clipping.

**Face:** neutral, attentive, concerned, firm, warm smile, skepticism, restrained humor, tired-but-kind; procedural blinking and controlled eye gaze; avoid constant smiling. Begin with a small set of authorable expression blend shapes or rig controls; not all must ship in first prototype.

**Lip sync:** use authored audio duration/phoneme markers if available. If unavailable, an approved simple jaw-open envelope timed to voice energy is a temporary technical placeholder, never represented as completed realistic lip sync. Ensure silent lines keep mouth closed; test interruptions.

**Timing notes:** purposeful movements should generally lead speech by a fraction of a second rather than all cues firing at dialogue start; hold attentive gaze during listening; let facial changes settle. All concrete clip durations are to be measured in engine, not canonized from prose.

**Ward safety:** no loose hanging props unless consistent with local hospital safety policy. ID should use breakaway lanyard or secure clip; accessory designs should not introduce avoidable ligature-risk depictions in patient-contact areas.

## Technical deliverables

1. Authored `.blend` source + license/provenance manifest for each borrowed asset.
2. Game-ready `.glb` skeletal model with materials, usable skin weights and animation names.
3. Godot 4.7 Naomi scene compatible with existing character interaction and voice events; preserve `staff_bennett` ID.
4. Scripted visual QA scene: controlled daylight, hospital fluorescence, close portrait, full body, sitting and walking; screenshots at reproducible positions.
5. Automated checks: mesh import, required bones/animations, missing textures, missing audio/cue references, no duplicate ID, dialogue still reachable, interaction repeatable, scene can reload.
6. Manual tests on the actual 8GB Apple Silicon Mac: render frame time/peak memory and skin, hair, mouth, uniform clipping review. Goal: playable 30FPS initial character slice, not a guarantee.

## Acceptance gate
A believable fictional adult nurse, matching approved portrait/turnaround; full outfit and hair stable under animation; dialogue triggers intact; no loss of clinical interactions; no prohibited or unlicensed source; acceptable measured performance. A static portrait, a cardboard humanoid, or a moving nonrigged mesh is **not** accepted as finished character production.
