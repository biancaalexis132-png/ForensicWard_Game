# Naomi Bennett — Chapter 1 dialogue performance blueprint v1

**Status:** Proposed character acting/animation specification; no clinical content, approved dialogue text, save data or scene code changed.
**Character:** `staff_bennett`, Ashcroft Charge Nurse. Approved casting: Black woman in her early 40s, pulled-back natural twists, navy scrubs, approachable yet authoritative.
**Source of dialogue truth:** `data/narrative/chapter1.json` and `audio/voice/voice_lines.json` from repository `biancaalexis132-png/ForensicWard_Game`, checked October 17, 2026.
**Voice:** `audio/voice_profiles.json` -> `staff_bennett`, `af_sarah`, rate 1.0, 'Brisk, practical, warm under pressure.'

## Canon-preserving constraints

- Keep scene ID `ch1_b2_bennett_handover`, location `nursing_station`, character ID `staff_bennett`, and all line IDs unchanged.
- Do not edit line wording or regenerate voice in this production pass; narrative file says `provisional: true` and `clinical_review_status: PENDING`.
- Do not infer diagnoses, new history, patient risk, or treatment from expressions or animation. Facial affect is not a clinical rule.
- Use the existing AudioDirector/voice-line playback contract after inspecting the current code. Do not assume a new runtime API or replace functioning interactions.
- All times below are **relative acting windows**; play and stop are governed by the actual OGG waveform length (not hard-coded duration).

## Scene staging

**Initial state:** Naomi is at the nursing station workstation, hands at keyboard or chart, in `work_idle`. Quiet breathing, irregular blinking, mild weight adjustment. Natural posture, not a constant cyclic gesture.

**Trigger:** player enters talk range and interacts with Naomi; stop current typing action after it reaches a safe interrupt frame. Turn torso then head toward player in a 0.3–0.6 second soft transition. If seated, do not teleport her to standing. Lock conversation focus but allow natural glances and player accessibility controls.

**Camera:** first-person camera remains under player control; no forced close-up, head lock, or abrupt FOV change. NPC gaze target uses player eye position with small natural shifts; cap neck rotation within plausible human limits.

## Existing line-by-line cue sheet

### 1. `ch1_b2_bennett_001` — speaker `staff_bennett`
**Existing text:** “Doctor? You're the new attending. I'm Naomi Bennett, charge nurse on this unit.”
**Asset:** `audio/voice/ch1/ch1_b2_bennett_001.ogg`

**Performance:** attentive recognition → restrained welcome. A slight eyebrow lift on 'Doctor?', easy eye contact, modest warm half-smile after introducing herself. Right hand rests on station counter; left hand stops typing. Voice remains brisk, not exaggeratedly enthusiastic.

**Animation cues:** `turn_to_speaker` (pre-roll), `expression_attentive` into `expression_subtle_warmth`, `gesture_small_intro` once, `talk_face` driven by audio envelope or verified visemes, occasional blink between phrases. Re-enter `listen_idle` when audio stops.

### 2. `ch1_b2_player_001` — speaker `player`
**Existing text:** “Good to meet you. What do I need to know?”
**Asset:** `audio/voice/ch1/ch1_b2_player_001.ogg`

**Performance:** Naomi listens, a small nod at end, prepares the clinical handoff without interrupting. No mouth flapping while listening. Gaze shifts briefly to the screen/chart then back.

### 3. `ch1_b2_bennett_002` — speaker `staff_bennett`
**Existing text:** “Elias Ward. Twenty-nine. He hasn't said a word since admission, he's barely eating, and he's held the same posture for most of the afternoon.”
**Asset:** `audio/voice/ch1/ch1_b2_bennett_002.ogg`

**Performance:** tone turns precise and professionally serious. Expression neutral-concerned, not fearful or horrified. Brief glance at authorized handoff sheet while speaking. Small open-palm gesture only if natural to audio pacing. Do not mime or illustrate symptoms, label a diagnosis, or look ominously toward Ward Zero.

**Animation cues:** `expression_focused_concern`, optional `glance_chart`, `gesture_handoff_once`, facial speech; ease to attentive listening after line.

### 4. `ch1_b2_player_002` — speaker `player`
**Existing text:** “Has anyone checked his vitals and fluid intake today?”
**Asset:** `audio/voice/ch1/ch1_b2_player_002.ogg`

**Performance:** Naomi attends with focused listening, slight acknowledging nod. Do not fabricate verification actions or numbers; the scripted answer handles facts.

### 5. `ch1_b2_bennett_003` — speaker `staff_bennett`
**Existing text:** “Vitals at two. The intake chart is at the station. He's in the interview room now, and I'd like you to see him before the evening round.”
**Asset:** `audio/voice/ch1/ch1_b2_bennett_003.ogg`

**Performance:** matter-of-fact professional guidance. Gentle directional gesture toward workstation when mentioning intake chart. For 'interview room', a small directional glance may be used if spatially valid in actual scene. Finish firm but cordial; do not signal supernatural significance.

**Animation cues:** `gesture_reference_workstation`, `expression_practical`, `talk_face`, `soft_nod`, transition to `work_idle` after interaction completes.

## Interaction branching (proposal only)

Do **not** add improvised clinical questions or new voiced lines during the initial animation PR. Instead, connect to existing dialogue as authored. Later optional player responses may vary Naomi's acknowledgment (attentive, cooperative, respectfully firm), but clinical access and mandatory information remain identical. Add any new line to the authoring registry with a new stable ID and narrative/clinical approval before audio synthesis.

## Animator state sketch

`work_idle` → `turn_to_speaker` → `talk_intro` → `listen_idle` → `talk_handoff` → `listen_idle` → `talk_followup` → `conversation_exit` → `work_idle`.

- Speech states are *presentation only*: never gate dialogue, save data, clues, or access permissions on animation completion.
- A skip, pause, cutscene interruption, scene unload, or reload must safely restore neutral face, stop/transfer audio, and release animation focus.
- Player movement away should use existing interaction rules; do not invent teleport or persistent stare behavior.
- Face rig: blink, jaw, mouth open/close, brow raise/furrow, smile, neutral, and eye aim as available. If full phonemes unavailable, implement a restrained envelope-driven jaw fallback and document fidelity honestly.

## Suggested 8 GB Mac acceptance criteria

1. In Chapter 1, Naomi can be identified by stable ID `staff_bennett` and spawned at existing `MARK_*` location without modifying scene landmarks.
2. Correct OGG plays exactly once per line ID; NPC lip movement begins and ends with relevant voice playback.
3. During player lines, Naomi stops lip motion and displays listening behavior.
4. Completing or skipping the conversation returns her to a non-stuck work idle.
5. Missing animation, rig node, or OGG gracefully falls back to a neutral pose or subtitle, never blocks progression.
6. NPC does not visually stutter at blend transitions, snap its neck, or slide across floor during stationary gestures.
7. Interaction remains usable with reduced-motion settings; no forced cinematic camera motion.
8. After save/load, no duplicated dialogue grant, audio replay, or broken animation state.
9. Repeated visits do not create duplicate humanoid meshes, materials or AudioStreamPlayer instances.
10. Record actual scene FPS, frame time, memory pressure and any texture-budget issues on the 8 GB Mac; don't claim 30 FPS without measurement.

## First PR scope and handoff

First PR should add *data-driven acting cues keyed by existing dialogue IDs* and deterministic validation tests, ideally separate from MPFB model-building PR. Until `Naomi_Bennett_Base_v01.glb` exists, use existing `WardCharacter` stand-in but do not claim realistic character implementation. Coordinate with active Naomi Blender builder branch. Include provenance and exact source files in handoff. No automatic merge.
