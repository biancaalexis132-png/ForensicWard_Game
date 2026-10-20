#!/usr/bin/env python3
"""Generate an offline owner review page from exact shipped assets and text."""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    output = ROOT / "docs/presentation_review.html"
    sections = ["""<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Forensic Ward — presentation review</title><style>
body{font:18px/1.55 system-ui;background:#172321;color:#ece5d7;max-width:1100px;margin:2rem auto;padding:1rem}
img{max-width:100%;height:auto}article{border-top:1px solid #6d8176;padding:1.4rem 0}audio{width:100%}
a{color:#bdd9ca}summary{cursor:pointer}code{overflow-wrap:anywhere}
</style><h1>Presentation review</h1><p>Exact repository art, text and existing offline voice clips.
This page records no approval and changes no game state. Listen on the target Mac and report decisions separately.</p>
<p>Preview the full transitions in Godot using the commands in <a href="MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md">the Mac checklist</a>.</p>"""]
    prologue = json.loads((ROOT / "data/narrative/prologue_ch1.json").read_text())
    lines = {line["id"]: line for scene in prologue["scenes"] for line in scene["lines"]}
    cutscene = json.loads((ROOT / "data/cutscenes/cs_ch01_prologue.json").read_text())
    sections.append("<h2>Prologue — pending approval</h2>")
    for panel in cutscene["panels"]:
        line = lines[panel["line_id"]]
        art = panel["layers"][0]["texture"].removeprefix("res://")
        sections.append(f'<article><img alt="{html.escape(panel["id"])}" src="../{art}"><p>{html.escape(line["text"])}</p><audio controls preload="none" src="../audio/voice/ch1/{line["id"]}.ogg"></audio><code>{line["id"]}</code></article>')
    sections.append('<h2>Milestone — pending approval</h2><p>Seven seconds, after the first assessment objective. These panels reuse pilot plates.</p>')
    milestone = json.loads((ROOT / "data/milestones.json").read_text())["milestones"][0]
    for side in ["left", "right"]:
        art = milestone[side]["texture"].removeprefix("res://")
        sections.append(f'<img alt="Milestone {side}" style="width:49%" src="../{art}">')
    sections.append('<h2>Voice and interview wording — pending listening/content acceptance</h2><p>All generated chapter lines, including interviewer questions and narrated responses. No patient voice is implied by narrator clips.</p>')
    for chapter in range(1, 6):
        data = json.loads((ROOT / f"data/narrative/voice_ch{chapter}.json").read_text())
        sections.append(f'<details><summary>Chapter {chapter}</summary>')
        for scene in data["scenes"]:
            for line in scene["lines"]:
                sections.append(f'<article><strong>{html.escape(line["speaker"])}</strong><p>{html.escape(line["text"])}</p><audio controls preload="none" src="../audio/voice/ch{chapter}/{line["id"]}.ogg"></audio><code>{line["id"]}</code></article>')
        sections.append('</details>')
    sections.append('<h2>New UI and environment candidates</h2><p>UI images use Godot 4.7, Linux X11 and Mesa llvmpipe. Environment plates use Blender 4.3.2 Cycles. These are review evidence, not Mac acceptance.</p>')
    for name in ["map", "protagonist", "continuing_practice", "case_journal"]:
        sections.append(f'<article><h3>{name.replace("_", " ").title()}</h3><img alt="{name}" src="../assets/renders/gameplay_completion/{name}.png"></article>')
    for name in ["CampusGrounds", "HospitalExterior", "Apartment"]:
        sections.append(f'<article><h3>{name}</h3><img alt="{name}" src="../assets/renders/stage7/{name}.png"></article>')
    sections.append('<p>Jordan clinical activation is a separate decision: <a href="CP001_ACTIVATION_REVIEW.md">exact case packet</a>.</p></html>')
    output.write_text("\n".join(sections), encoding="utf-8")
    print(output.relative_to(ROOT))


if __name__ == "__main__":
    main()
