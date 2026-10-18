# CHAPTER 1 — THE ADMISSION
## Expanded end-to-end playable screenplay | production draft v1.0

> **Status:** Proposed narrative/production manuscript. Not a shipped Godot runtime or a clinically approved treatment simulation. Source baseline: GitHub five-chapter draft and later Chapter 2–5 creative expansions.

## Chapter intent
A credible first clinical shift evolves into an administrative mystery without exposing Ward Zero.

## Scene 01 — New Badge
**Location:** Staff entry / clinical corridor
**Function:** A daylight arrival establishes the psychiatrist’s professional role. The playable build may begin at its existing corridor spawn; the staff-entry dialogue may be a future cinematic rather than an invented room.

### Screenplay & blocking
**SECURITY**: First day? Badge visible, please.  
**PLAYER**: Clinical services. Where do I report?  
**SECURITY**: The medical director first. People here take the sign-in seriously, including me.  

### Player choices (all preserve required access)
- **A.** Respond warmly
- **B.** Ask for the route
- **C.** Clarify access policy

**Scene exit / continuity:** Orientation acknowledged; access never expands from personality choice.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc01_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 02 — The Unit Has a Rhythm
**Location:** Dr. Voss’s office
**Function:** A clinical unit carries on around the newcomer. Voss explains the review of assignments and the boundary between psychiatry, nursing, security and Facilities.

### Screenplay & blocking
**VOSS**: You’re here to practice medicine. Start by understanding the people already caring for these patients.  
**PLAYER**: Who should I speak to first?  
**VOSS**: Naomi Bennett. She knows how this unit actually runs.  

### Player choices (all preserve required access)
- **A.** Ask about patient assignments
- **B.** Clarify nursing workflow
- **C.** Ask where records live

**Scene exit / continuity:** Existing office and EHR location preserved.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc02_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 03 — Elias on Paper
**Location:** Nursing station
**Function:** Naomi pauses work to give the existing spoken handoff, and returns to the workstation afterward. Existing recorded text must take precedence over dramatized rehearsal.

### Screenplay & blocking
**BENNETT**: Doctor? You’re the new attending. I’m Naomi Bennett, charge nurse on this unit.  
**PLAYER**: Good to meet you. What do I need to know?  
**BENNETT**: Elias Ward. Twenty-nine. He hasn’t said a word since admission, he’s barely eating, and he’s held the same posture for most of the afternoon.  
**PLAYER**: Has anyone checked his vitals and fluid intake today?  
**BENNETT**: Vitals at two. The intake chart is at the station. He’s in the interview room now, and I’d like you to see him before the evening round.  

### Player choices (all preserve required access)
- **A.** Review nursing chart
- **B.** Ask what is directly observed
- **C.** Proceed to interview room

**Scene exit / continuity:** Canonical line IDs: ch1_b2_bennett_001 to _003; ch1_b2_player_001 to _002. All clinical wording PENDING.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc03_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 04 — A Patient Who Cannot Answer
**Location:** Interview Room A
**Function:** Elias is seated and minimally responsive. The psychiatrist attempts contact respectfully and records only what is witnessed; alternatives may be medically relevant but never become automatic diagnoses.

### Screenplay & blocking
**PLAYER**: Hello, Elias. I’m one of the psychiatrists on your team. May I speak with you?  
**STAGE**: Elias gives no verbal reply. No dramatic sound cue.  
**PLAYER**: I’ll explain what I’m doing and give you time to respond.  
**STAGE**: The room’s ordinary ventilation continues.  

### Player choices (all preserve required access)
- **A.** Ask about food and fluids
- **B.** Examine motor behavior
- **C.** Offer quiet time

**Scene exit / continuity:** Preserve existing ask_intake, assess_motor, ask_ward_zero and observation IDs; no automatic diagnosis.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc04_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 05 — The Clinical Differential
**Location:** Interview room / chart
**Function:** The player weighs observable behavior, nursing report, missing measurements and alternative explanations. The interface shows what is known rather than presenting an answer key.

### Screenplay & blocking
**PLAYER**: What have we actually observed, rather than assumed?  
**BENNETT (if consulted)**: I can tell you what the shift documented, not what it means.  
**PLAYER**: That distinction matters.  

### Player choices (all preserve required access)
- **A.** Review observations
- **B.** Request available medical data
- **C.** Record uncertainty

**Scene exit / continuity:** Patient safety and clinical review gates are independent of paranormal state.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc05_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 06 — What We Can Actually Write
**Location:** EHR workstation
**Function:** The note composer distinguishes reported, witnessed and unavailable data; append-only note history remains intact.

### Screenplay & blocking
**PLAYER (internal)**: Reported by nursing. Observed by me. Not yet available. Those are three different things.  
**STAGE**: The EHR highlights the source and time for each item.  

### Player choices (all preserve required access)
- **A.** Draft neutral note
- **B.** Document remaining questions
- **C.** Request approved follow-up

**Scene exit / continuity:** Existing EHR/PatientManager operations only; pending actions do not become medically validated.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc06_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 07 — An Ordinary Follow-up
**Location:** Nursing station
**Function:** The player communicates documented concerns to Naomi without treating note-saving as proof the next staff member received them.

### Screenplay & blocking
**PLAYER**: I’ve recorded what I could establish. There are still things to clarify.  
**BENNETT**: Tell me what is outstanding and who needs to see it.  
**PLAYER**: I’ll make sure the handoff reflects that.  

### Player choices (all preserve required access)
- **A.** Ask for acknowledgment
- **B.** Clarify responsibilities
- **C.** Review outstanding data

**Scene exit / continuity:** Any acknowledgment is a proposed future event, not currently shipped.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc07_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 08 — The Work Between Emergencies
**Location:** Clinical corridor
**Function:** Ambient work, a printer problem, checks and distant staff conversations continue. Human-scale routines provide contrast before the first unexplained administrative item.

### Screenplay & blocking
**DISTANT STAFF**: The printer’s jammed again. No, the other one.  
**BENNETT**: It’s a hospital. Something always needs fixing.  
**PLAYER**: I’m noticing.  

### Player choices (all preserve required access)
- **A.** Return to office
- **B.** Review sign-out board
- **C.** Walk the corridor

**Scene exit / continuity:** Use existing walla_ns IDs as non-clinical texture; do not promote to evidence.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc08_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 09 — The Duplicate Transfer ID
**Location:** Medical records / office
**Function:** Two administrative entries reference a transfer identifier in conflicting ways. The player flags the contradiction and establishes custody without inferring a patient transfer occurred.

### Screenplay & blocking
**PLAYER**: There are two entries with the same identifier.  
**VOSS**: Which entries, and what system produced each?  
**PLAYER**: I’ll document the conflict before calling it anything else.  

### Player choices (all preserve required access)
- **A.** Compare records
- **B.** Request audit history
- **C.** Note unresolved conflict

**Scene exit / continuity:** Introduce source-specific administrative evidence, not a clinical finding.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc09_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 10 — Hand Off a Human Being
**Location:** Nursing station
**Function:** The day’s clinical obligations are completed or safely assigned to an authorized team. The professional ethic frames the chapter’s central mystery.

### Screenplay & blocking
**BENNETT**: Have we covered the things that can’t wait?  
**PLAYER**: The outstanding items are documented and assigned for follow-up.  
**BENNETT**: Good. We can deal with the rest tomorrow.  

### Player choices (all preserve required access)
- **A.** Review clinical worklist
- **B.** Confirm communication
- **C.** Check the archive ticket

**Scene exit / continuity:** Clinical sign-out does not resolve patient status automatically.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc10_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 11 — W-Zero-B
**Location:** Corridor / secure door
**Function:** An after-hours announcement uses a designation absent from the current unit map. The sealed W0-B entrance remains inaccessible.

### Screenplay & blocking
**INTERCOM**: Transfer team to W-Zero-B. Transfer team to W-Zero-B, please.  
**PLAYER**: That designation isn’t in the route list.  
**SECURITY (optional)**: Then we verify who sent it. Nobody opens a restricted door over a PA call.  

### Player choices (all preserve required access)
- **A.** Read access log
- **B.** Notify Security
- **C.** Record the announcement

**Scene exit / continuity:** Existing voice ID ch1_b6_intercom_001. No opening of Ward Zero.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc11_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---

## Scene 12 — First Shift, Last Light
**Location:** Clinical corridor
**Function:** The player leaves a factual incident report and resumes routine life. A personal-history message may appear if supported by the profile system.

### Screenplay & blocking
**VOSS**: We’ll investigate the routing entry. You’ve done what was appropriate today.  
**PLAYER**: And if the record is wrong?  
**VOSS**: Then we correct the record. We don’t guess.  

### Player choices (all preserve required access)
- **A.** Sign out clinically
- **B.** Check personal message
- **C.** Save and continue

**Scene exit / continuity:** Chapter exits with administrative discrepancy unresolved; no overt paranormal confirmation.

### Performance, camera and environment
- Play in first person. Camera stays at conversational height; never frame psychiatric symptoms as horror imagery.
- Background staff continue lightweight tasks unless a scripted conversation takes focus. Use existing walla and room tone sparingly, with dialogue ducking.
- Dialogue delivery is restrained and human: subtle gaze shifts, breathing, hand movements, and pauses; no compulsory jump-scare or ominous score.
- Available choices change emphasis and optional relational callbacks. They never block core facts or required clinical care.


### Gameplay and state contract
- **Entry:** The preceding scene has concluded or been appropriately deferred; any clinical obligations have approved follow-up.
- **Interact:** Review documents or converse with authorized actors. Use evidence provenance and institutional permissions; never transform a copied file into independent corroboration.
- **Completion:** Use a distinct authored event ID proposed as `proposed_ch01_sc12_complete` (NOT an existing shipped ID). Complete only when required interactions or safe escalation are recorded.
- **Resume:** Reentry must be idempotent. Save/load may restore the scene or its safe checkpoint without duplicating dialogue, evidence, actors or handoffs.
- **Review:** All new clinical dialogue and medical actions are `PENDING` until approved.

---
