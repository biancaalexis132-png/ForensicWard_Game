# CHAPTER 1 — THE ADMISSION
## The Forensic Ward — Full proposed playable screenplay

**Status:** Complete *draft scene sequence*, NOT final approved canon or a production-ready implementation. The chapter titles follow the repository campaign index. Chapters 2–5 are proposed new narrative writing and require owner review.
**Hospital:** Ashcroft State Forensic Hospital. **Protagonist:** psychiatrist, customizable appearance, background, moderate personal history; personality determined through choices.
**Tone:** hospital drama first; escalating documentary and environmental anomalies; supernatural phenomenon genuine but independent from psychiatric illness.

---

## Scene 01 — New Badge
**Location/time:** Main staff entrance, 07:42  
**Dramatic function:** Professional welcome; player identity established  
**Cast:** Security officer, player

### Staging and playable action
The player arrives at a functioning secure hospital, signs for an ID badge and completes character onboarding as a psychiatrist. A facilities worker repairs a lamp. No ominous music.

### Screenplay dialogue

**OFFICER:** Morning. First day?

**PLAYER:** Yes. Clinical services.

**OFFICER:** Badge where we can see it, and give your ID to nobody. The tour starts with coffee if you are lucky.

### Branching player choices

**Choice A — Warm: “That obvious?”.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Formal: “I am here for the 8:00 orientation.”.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Observant: “Which door is staff access?”.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Employee badge and orientation email**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Arrival must not be an anomaly; show daylight, humane environment.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 02 — The Unit Has a Rhythm
**Location/time:** Clinical nursing station, 08:05  
**Dramatic function:** Meet Bennett, receive practical safety procedures  
**Cast:** Bennett, unit nurses, player

### Staging and playable action
Bennett manages a transportation call and a missing printer tray. She checks the incoming psychiatrist’s credentials without being either hostile or flattering.

### Screenplay dialogue

**BENNETT:** I am Naomi Bennett, charge nurse. We have a census, a schedule, and three different versions of the schedule.

**PLAYER:** Which one is correct?

**BENNETT:** The one we confirm with the people doing the work.

**BENNETT:** Please document what you observe, not what you hope it means.

### Branching player choices

**Choice A — Ask for EHR walkthrough.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Ask about secure-door practice.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Ask about the first patient.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Shift handoff; patient chart access**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Preserve original Bennett dialogue IDs when integrating.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 03 — Elias on Paper
**Location/time:** Psychiatrist office, 08:25  
**Dramatic function:** Document provenance, triage immediate safety  
**Cast:** Player, Bennett

### Staging and playable action
Elias Ward, 29, has been transferred for competency restoration and is reportedly mute, hypokinetic and taking little orally. Nursing observations and possible physician findings have different provenance.

### Screenplay dialogue

**PLAYER:** The intake concern and the motor history need separate verification.

**BENNETT:** I can show you the flowsheet. Tell me what has not been checked.

### Branching player choices

**Choice A — Review intake first.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Review medical and medication record first.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Review transfer and legal documents first.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Nursing and physician observations; no invented vital sign**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Do not confuse pharmacology test placeholders PT-001/002 with Elias.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 04 — A Patient Who Cannot Answer
**Location/time:** Interview Room A, morning  
**Dramatic function:** Respectful first contact; limits of interview  
**Cast:** Elias, player

### Staging and playable action
The psychiatrist introduces themself, asks about comfort and waits. Elias cannot provide a conventional history. Silence is never scored as refusal or evidence of secrets.

### Screenplay dialogue

**PLAYER:** Mr. Ward, I am Dr. [NAME]. I want to understand what you need.

*Elias gives no verbal response.*

**PLAYER:** You are not required to answer quickly. I will explain what I am doing.

### Branching player choices

**Choice A — Supportive pause.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Simple yes/no questions.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Immediate pain and medical comfort inquiry.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Observed mutism only; do not infer a negative symptom review**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** No horror audio, jump scare or unusual animation.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 05 — The Clinical Differential
**Location/time:** Interview Room A / EHR, morning  
**Dramatic function:** Structured exam, urgent medical awareness  
**Cast:** Player, Bennett

### Staging and playable action
A structured bedside assessment may identify signs relevant to catatonia; alternate medical, neurologic and drug-related explanations remain open. Inadequate intake triggers appropriate medical follow-up.

### Screenplay dialogue

**BENNETT:** Do you think he is doing this on purpose?

**PLAYER:** I do not have evidence to say that. We need an assessment, and we need to protect his health while we do it.

### Branching player choices

**Choice A — Medical stabilization and examination.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Obtain targeted collateral.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Document provisional motor findings.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Structured exam and verified laboratory/vital data, if authored**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Do not select specific drug treatment or dosage without approved rules.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 06 — What We Can Actually Write
**Location/time:** EHR, late morning  
**Dramatic function:** MSE, formulation and uncertainty  
**Cast:** Player

### Staging and playable action
Player documents speech unassessable beyond absence of response, movement reduced, thought content and orientation not reliably established, and incomplete suicide/violence inquiry.

### Screenplay dialogue

**PLAYER (DICTATION):** Nonverbal during encounter. Unable to reliably assess thought content or orientation. Differential remains open pending examination and collateral.

### Branching player choices

**Choice A — Use qualified observations.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Escalate incomplete medical data.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Request specialist/medical input if indicated.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Saved EHR note**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Incomplete interview is not equivalent to normal findings.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 07 — An Ordinary Follow-up
**Location/time:** Interview Room B, early afternoon  
**Dramatic function:** Second patient; coordination and respect  
**Cast:** Jordan Vale (provisional), player

### Staging and playable action
A provisional stable patient wants truthful information about delayed forensic planning and changing clinicians. His legal status must be authored before final integration.

### Screenplay dialogue

**JORDAN:** Three psychiatrists in two weeks. I am tired of starting over.

**PLAYER:** You should not have to keep retelling everything. What do you most need clarified today?

**JORDAN:** Who decides what happens next.

### Branching player choices

**Choice A — Validate frustration.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Explain verified process.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Arrange team communication.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Provisional patient follow-up; no definitive discharge authority**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Jordan is NOT approved canon; substitute approved patient if available.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 08 — The Work Between Emergencies
**Location/time:** Nursing station / corridor, afternoon  
**Dramatic function:** Interprofessional teamwork  
**Cast:** Bennett, social worker, player

### Staging and playable action
Transport delays, referral questions and schedule changes show the reality of ward care. Player can help correct communication without taking over another profession’s role.

### Screenplay dialogue

**SOCIAL WORKER:** The referral is in. There is not an answer yet.

**BENNETT:** Then we should tell him that in plain language.

**PLAYER:** I will document what we know and who is following up.

### Branching player choices

**Choice A — Patient advocacy.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Collaborative plan.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Pragmatic documentation.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Treatment coordination note**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** No personality choice changes baseline professional competence.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 09 — The Duplicate Transfer ID
**Location/time:** Records archive, afternoon  
**Dramatic function:** Investigative evidence provenance  
**Cast:** Player, records technician

### Staging and playable action
The player compares Elias’s transfer identifier against the archive and finds a collision. The system also shows an authorizing credential not currently active.

### Screenplay dialogue

**RECORDS TECHNICIAN:** Old identifiers sometimes survive a migration. I can pull the source record.

**PLAYER:** Please preserve the original entry. I do not want a corrected screen to erase the discrepancy.

### Branching player choices

**Choice A — Clerical hypothesis.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Credential audit concern.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Withhold explanation pending records.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Original transfer, archive record, audited change history**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Anomaly not inferred from data error.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 10 — Hand Off a Human Being
**Location/time:** Nursing station, evening  
**Dramatic function:** Responsibility and trust  
**Cast:** Bennett, player

### Staging and playable action
Player signs out current observations, pending tests, safety concerns and clear ownership for follow-up. Bennett responds to completeness, not flattery.

### Screenplay dialogue

**BENNETT:** Is everything the night team needs in the note?

**PLAYER:** I documented what we know, what we do not, and who needs to follow up.

**BENNETT:** That is a useful handoff.

### Branching player choices

**Choice A — Complete documentation.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Review missed item.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Correct missing handoff information.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **Sign-out state**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Safety-critical omissions cannot be bypassed by romance or charisma.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 11 — W-Zero-B
**Location/time:** Clinical corridor, after night shift begins  
**Dramatic function:** Quiet first mystery  
**Cast:** Bennett, intercom, player

### Staging and playable action
The intercom calls a transfer to W-Zero-B. An EHR alert appears for Elias under an inactive staff credential. The player holds the transfer until verified. No paranormal certainty.

### Screenplay dialogue

**INTERCOM:** Transfer team to W-Zero-B. Transfer team to W-Zero-B, please.

**BENNETT:** That is not on my board.

**PLAYER:** Do not move him on an unverified request. Let us check the audit trail.

**BENNETT:** Some old location codes are still in the archive. The credential worries me more.

### Branching player choices

**Choice A — Request credential audit.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Compare access logs.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Ask for old floor plan.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **clue_access; intercom_heard; evidence source**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Keep existing event timing and IDs: ch1_b6_intercom_001.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---

## Scene 12 — First Shift, Last Light
**Location/time:** Exit corridor / staff entrance  
**Dramatic function:** Chapter close without horror reveal  
**Cast:** Player, optional personal contact

### Staging and playable action
A cleaner changes a bin liner; two nurses discuss tomorrow’s roster. A page from the authorized audit printer repeats the unverified request. Outside the hospital, nothing dramatic occurs.

### Screenplay dialogue

**PLAYER (OPTIONAL REFLECTION):** A transfer order can be wrong. The question is why nobody can identify its source.

### Branching player choices

**Choice A — Report to supervisor.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice B — Preserve audit reference.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

**Choice C — Leave record for designated records team.** The camera remains in-character. The choice is acknowledged through a short natural conversational response and, where relevant, an optional future callback. The player still has access to core evidence and clinically required actions.

### Exit beat and recorded state
The scene advances only after the relevant factual information is reviewed, or after the player explicitly schedules appropriate follow-up. The working lead or record is: **chapter_ch1_complete; authenticated evidence only**. Record who supplied it, what was actually observed, and any uncertainty. A discreet objective update replaces an overt horror sting.

**Continuity / safety boundary:** Do not take protected patient records outside authorized systems.

### Performance and interaction directions
Actors hold the emotional tone of a grounded clinical drama: pauses, paperwork, professional disagreement and ordinary ambient activity carry the tension. No character’s distress, illness or diagnostic history is visual shorthand for evil or the paranormal. Interactions should remain reversible until a verified document or action is committed. The player’s choice changes tone and optional follow-up, not baseline clinical competence or necessary story access.

### Scene-state and implementation notes
This is proposed authored content, not an existing Godot event. Implementers should map to established identifiers and avoid inventing a shipped `dialogue_id` or `evidence_id`. Scene assets are concept requirements only. Preserve source classifications, original timestamps and audit evidence. Technical and clinical approval flags must be respected before activation.

---
