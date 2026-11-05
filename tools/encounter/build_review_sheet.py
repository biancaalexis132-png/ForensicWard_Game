"""Write the clinical review sheet for data/elias_encounter.json (Markdown).

    python3 tools/encounter/build_review_sheet.py OUTPUT.md
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
data = json.loads((ROOT / "data/elias_encounter.json").read_text())
names = {"pt_elias_ward": "Elias", "staff_sitter_adler": "Tom (sitter)", "staff_bennett": "Bennett"}
out = []
w = out.append
w("# Elias Ward encounter: clinical review sheet")
w("")
if data["clinical_review_status"] == "APPROVED":
    w("Status: **APPROVED** by Bi on 2026-11-05, as written (see `docs/clinical_review_log.md`). Every fact, finding, lab result, order verdict and outcome below is fictional. Source: `data/elias_encounter.json`.")
else:
    w(f"Status: **{data['clinical_review_status']}**. Every fact, finding, lab result, order verdict and outcome below is new, fictional, and needs your clinical approval. Mark each item approve / revise (with wording) / cut. Source: `data/elias_encounter.json`.")
w("")
w("## How it plays")
w("")
w("1. **Introduction.** You sit across from Elias. Tom Adler, his 1:1 sitter, is in the room with the transfer packet and nursing flowsheet.")
w("2. **History.** A checklist of ten history domains fills in as you ask. You ask Elias first; he does not answer (his model stays still, eyes fixed: nothing is narrated). Tom answers from what he has seen and from the packet. Every fact is written to the EHR with its source and reliability.")
w("3. **Examination.** You perform each step on screen (pulse, penlight, imitation, arm lift, elbow tone, palm, ankles). Findings appear as short captions, not narration.")
w("4. **Orders at the bedside.** No split screen. You pick orders and tell Tom and Bennett; each is logged to the EHR. Lab results arrive in the EHR later in the shift.")
w("5. **Consequences.** An antipsychotic order is challenged by Bennett (you can cancel it; if you insist she holds it and pages medical, and her trust drops). A lorazepam challenge brings a call back 45 game-minutes later: Elias tracks you, drinks, says \"Thank you\", and his arm no longer stays raised.")
w("6. The EHR note step stays; the Chapter 1 split-screen milestone after orders is switched off.")
w("")
w(f"**Informant:** {data['informant']['name']}, {data['informant']['role']}. {data['informant']['intro']}")
w("")
for section in data["sections"]:
    w(f"## {section['label']}")
    w("")
    for step in [s for s in data["steps"] if s["section"] == section["id"]]:
        w(f"### {step['label']}  `{step['id']}`")
        w("")
        w(f"- **You:** {step['player']}")
        for beat in step["beats"]:
            who = names.get(beat["speaker"], beat["speaker"])
            if "text" in beat:
                w(f"- **{who}:** {beat['text']}")
            if "shown" in beat:
                w(f"- *{who}, shown on screen:* {beat['shown']}")
        if step.get("records_observations"):
            w(f"- Records findings: {', '.join(step['records_observations'])}")
        for fid in step.get("records_facts", []):
            f = data["history_facts"][fid]
            w(f"- EHR fact `{fid}` ({f['reliability']}): {f['text']}")
        w("")
w("## New findings for the EHR")
w("")
w("obs_immobility, obs_staring, obs_tachycardia, obs_dry_mucosa, obs_waxy_flexibility (added to Elias in `data/patients.json`, wording in that file). Existing obs_mutism and obs_posturing are reused.")
w("")
w("## Orders and verdicts")
w("")
w("| Order | Verdict | Feedback shown after the shift |")
w("|---|---|---|")
for item in data["orders"]["items"]:
    w(f"| {item['label']} | {item['verdict']} | {item['feedback']} |")
w("")
w("## Lab results (arrive in the EHR later in the shift)")
w("")
for lab, text in data["orders"]["lab_results"].items():
    w(f"- **{lab}:** {text}")
w("")
w("## Consequences")
w("")
c = data["consequences"]["antipsychotic_hold"]
w(f"**Antipsychotic ordered.** Bennett: {c['text']}")
for ch in c["choices"]:
    w(f"- *{ch['label']}* → Bennett: {ch['reply']} (trust {ch['trust_delta']:+d}){' Chart: ' + ch['chart_entry'] if 'chart_entry' in ch else ''}")
w("")
r = data["consequences"]["lorazepam_reassessment"]
w(f"**Lorazepam challenge ordered.** {r['delay_minutes']} game-minutes later, Tom: {r['call']['text']}")
for step in r["steps"]:
    for beat in step["beats"]:
        who = names.get(beat["speaker"], beat["speaker"])
        if "shown" in beat:
            w(f"- {step['label']}: *{beat['shown']}*")
        if "text" in beat:
            w(f"- {who}: \"{beat['text']}\"")
w(f"- Tom: {r['sitter_close']}")
w("")
w("## Questions for you")
w("")
w("1. Is a mildly rising temperature and pulse after recent IM haloperidol the right level of medical concern for Chapter 1, or should his vitals be normal so the chapter stays about catatonia alone?")
w("2. Lorazepam challenge: the order says \"as per protocol\" with no dose shown in game. Do you want a dose and route stated?")
w("3. Should Elias speak at all in Chapter 1 (the \"Thank you\" after lorazepam), or stay mute until later?")
w("4. Sitter name and role: Tom Adler, mental health technician. OK?")
Path(sys.argv[1]).write_text("\n".join(out) + "\n")
