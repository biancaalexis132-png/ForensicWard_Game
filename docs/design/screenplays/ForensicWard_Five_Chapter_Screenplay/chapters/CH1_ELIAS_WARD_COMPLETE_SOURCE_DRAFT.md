# THE FORENSIC WARD — CHAPTER 1: THE ADMISSION
## Elias Ward first clinical evaluation — Scenes 5–10

**Status:** PROPOSED NARRATIVE DRAFT — PENDING OWNER NARRATIVE AND PSYCHIATRIST CLINICAL APPROVAL.  
**Not yet canonical, implemented, or committed to GitHub.**  
**Source:** ChatGPT working screenplay drafted with the project owner, 17 October 2026. Consolidated for line-by-line review.  
**Role:** Protagonist is always a psychiatrist at Ashcroft State Forensic Hospital.  
**Tone:** Realistic psychiatric hospital drama. Horror emerges slowly; no supernatural diagnosis or patient stereotype.

### Implementation source-of-truth references to inspect on current `main`
- `data/patients.json` — Elias Ward, age 29, competency-restoration transfer, initial concerns and provenance.
- `data/dialogue.json` — preliminary interview intents and structured examination route.
- `data/story_chapter1.json` — Chapter 1 objectives, handoff, archive comparison, late W0-B beat.
- `data/narrative/chapter1.json` — provisional Bennett dialogue and W-Zero-B intercom line (IDs must remain stable).
- `data/campaign.json` and `data/zones.json` — chapter state and location architecture.

**Important:** `data/patients/PT-001.json` is a separate pharmacology placeholder and must not be silently conflated with `pt_elias_ward`.

## Scene 5 — Before Entering the Room
**Setting:** Protagonist's office, EHR workstation. **Purpose:** Review patient, source provenance, and immediate safety questions before interviewing.

The player sits at their workstation. EHR census shows **Elias Ward, 29**, legal status **competency-restoration transfer**. Presenting concerns listed as **mutism, marked reduction in movement, reported posturing, poor oral intake**. These are concerns, not confirmed diagnoses.

EHR source entries (must be displayed with provenance):
- **Nursing report:** “Not speaking following transfer; duration not independently verified.”
- **Physician observation:** “Possible posturing requires structured bedside examination.”

Player can choose first review: (1) intake/hydration, (2) transfer/legal documents, (3) motor-symptom history. All remain accessible, regardless of choice. Do not generate negative/normal findings from an unopened chart.

**BENNETT:** Doctor? Just checking you found the chart.

**PLAYER:** I did. I'm reviewing the transfer information before I see him.

**BENNETT:** Good. He hasn't been saying much, so don't be surprised if you don't get a traditional interview.

**PLAYER:** Has he been medically assessed since arrival?

**BENNETT:** The observations are in the chart. I can help you confirm what's been checked and what's still outstanding.

**PLAYER:** Thank you. I'd like to review his intake and vital signs before we proceed.

**BENNETT:** Of course. Let me pull up the nursing flowsheet.

Audio direction: ordinary hospital ambience. No suspense stinger.

## Scene 6 — Elias Ward
**Setting:** Interview Room A. **Purpose:** Establish patient dignity and interview limits. **Estimated playtime:** 8–12 minutes.

Elias is seated quietly. His appearance is neat; regular hospital attire, no supernatural presentation. Player approaches at respectful distance.

**PLAYER:** Good morning, Mr. Ward. I'm Dr. [Player Name], one of the psychiatrists here at Ashcroft.

**STAGE DIRECTION:** No verbal response.

**PLAYER:** I know you've been transferred recently. I'd like to understand how you're doing and make sure we're addressing anything you need.

**STAGE DIRECTION:** No verbal response. The player waits without a horror audio cue.

**Choice A — Supportive:** “You don't have to answer everything right away. I'm going to give you some time.”
- **Observed response:** Elias remains silent; silence is not coded as opposition or unwillingness.

**Choice B — Immediate comfort:** “Are you in pain? Is there anything you need right now?”
- **Observed response:** No verbal response. Pain cannot be documented as absent on this basis.

**Choice C — Simple communication:** “I'm going to ask a few short questions. You can answer however you're able.”
- **Observed response:** Limited response. Nonverbal communication may be considered where feasible; orientation and thought content remain unassessable without evidence.

Player may observe movement and seek appropriate bedside assessment and collateral. No dialogue choice infers the absence of delusions, hallucinations, suicidality, violence risk, or impaired orientation.

## Scene 7 — Something More Than Silence
**Setting:** Interview Room A. **Purpose:** Structured medical/motor assessment and preliminary differential.

Objective: **Determine whether reduced communication and movement may represent catatonia or another urgent medical or psychiatric condition.**

Available actions, each of which must result in actual data collection or an explicit unknown state:
1. Check current vitals and medical stability.
2. Assess oral intake, hydration and elimination; confirm amounts/timing.
3. Perform an appropriate structured motor exam; inspect for signs rather than assume them.
4. Review medications, recent changes, exposures and withdrawal.
5. Review transfer chronology, baseline and collateral sources.
6. Consider urgent medical/neurologic assessment for red flags and complications.

Working differential: catatonia; medical/neurologic causes; medication-related syndromes; primary psychiatric illness. Differential entries are provisional and not a diagnosis.

**BENNETT:** Any luck getting him to talk?

**Response A — Diagnostic uncertainty:** “Not yet. I'm concerned about his movement and reduced intake. I need to complete the medical and motor assessment before drawing conclusions.”

**BENNETT:** All right. Tell me what you need from nursing, and we'll coordinate.

**Response B — Collateral priority:** “I haven't established when this began. Could we find out what staff observed before transfer and what his usual functioning was?”

**BENNETT:** I'll help identify the reporting staff and the available transfer documentation.

**Response C — Medical safety:** “Before anything else, we need to confirm his current medical stability and how much he's been taking by mouth.”

**BENNETT:** Understood. Let's review what's documented and address anything urgent.

These approaches need not be mutually exclusive in gameplay. Player expression may influence rapport, but appropriate assessment and escalation remain possible for every personality/background.

## Scene 8 — The Assessment Note
**Setting:** Protagonist's office. **Purpose:** Document observations vs unknowns, provisional risk, and plan.

EHR mental status draft options:

| Domain | Supported provisional wording | Incorrect inference to prevent |
| --- | --- | --- |
| Speech | “Nonverbal during this encounter; reason not yet established.” | “Speech normal” or “refuses to speak” |
| Motor | “Markedly reduced spontaneous movement; structured examination pending.” | “No abnormality” or definitive catatonia based on a label |
| Thought content | “Unable to adequately assess.” | “No delusions or suicidal ideation” based on silence |
| Orientation | “Unable to reliably assess.” | “Fully oriented” or “disoriented” without evidence |

**Provisional risk narrative:** Immediate concerns include poor oral intake/hydration, immobility complications, possible medical illness, and inability to obtain sufficient direct interview data. Suicide and violence risk cannot be adequately determined from this limited encounter. Obtain collateral, reassess, and employ clinically indicated precautions and medical escalation based on verified findings. No automatic observation order or drug treatment is specified in this draft.

**PLAYER:** I've documented what we could establish today and what still needs assessment. His intake and physical status need active follow-up.

**BENNETT:** Good. I'll make sure the next team sees the outstanding concerns.

**PLAYER:** And if anything changes before then, please contact me.

**BENNETT:** Absolutely.

Implementation mapping: existing `obj_document` and `obj_act` must remain; pending clinical rules remain unvalidated. Do not introduce medical treatment recommendations as approved content without owner clinical review.

## Scene 9 — Two Records, One Patient
**Setting:** Functional records archive. **Purpose:** Provenance-based evidence comparison, no supernatural inference.

The transfer documentation has two discrepancies already represented in the repository:
- `transfer_identifier_collision`
- `inactive_authorizer`

The player compares source documents and identifies competing hypotheses:
1. **Possible clerical error:** Request documented reconciliation.
2. **Unresolved discrepancy:** Preserve both sources, distinguish verified data from interpretation.
3. **Possible improper authorization:** Escalate an audit concern without identifying an unverified culprit.

All evidence paths must preserve provenance, uncertainty and appropriate confidentiality. No patient's symptoms trigger or confirm anomalies. The archive is staffed/operational, not a haunted set.

Implementation mapping: reuse `obj_compare_records`, the existing evidence board, and relevant hypothesis IDs. Do not change ids or force evidence conclusions.

## Scene 10 — The First Strange Entry (LATE SHIFT)
**Setting:** Corridor and EHR. **Timing:** Only after day-shift clinical activities and handoff, consistent with `beat_b6_intercom` and the 15-minute after-hours delay in the implementation. **Purpose:** Administrative mystery, subtle introduction of Ward Zero.

**INTERCOM:** Transfer team to W-Zero-B. Transfer team to W-Zero-B, please.

The announcement is matter-of-fact; no music sting, apparition or sudden camera effect.

An EHR alert records a **transfer request to W0-B under a credential marked inactive**. The requester is not identified. The request's existence does not establish its authorization, completion or medical appropriateness.

The player can investigate the log, ask Bennett and inspect the W0-B door/access evidence; urgent clinical safety actions are not optional merely to unlock mystery content.

Potential Bennett response with adequate trust: the transfer call came under an inactive credential, and nobody on her shift requested it. Without adequate trust, she supplies more limited information but essential investigation remains accessible.

End in unresolved uncertainty. No proof of supernatural activity in the first episode.

---

## Clinical and narrative review gate
- **Owner clinical review required:** Any examination findings, medical actions, differential consequences, risk assessment mechanics, diagnostic scoring, and treatment decisions.
- **Owner narrative approval required:** Dialogue, pacing and how new screenplay integrates with preexisting voice line IDs.
- **Codex implementation task initially:** Line-by-line compare this draft with repository source; report exact conflicts and safe changes; do not silently overwrite approved code or mark `PENDING` clinical statuses as validated.
- **Timing caution:** Chapter 1 is longer than the opening 30 minutes. This document outlines the complete Elias sequence *and* a later after-hours beat; the latter does not immediately follow the morning assessment.

## Requested comparison deliverable
| Script scene / dialogue line | Existing code or content file and identifier | Match / conflict / missing | Clinical or narrative approval needed | Smallest safe implementation change |
| --- | --- | --- | --- | --- |
| Populate after inspecting actual repository | | | | |
