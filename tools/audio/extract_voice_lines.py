#!/usr/bin/env python3
"""Derive voice lines from the game's authored text so every spoken or narrated
passage has a clip. Writes data/narrative/voice_<chapter>.json.

The text is copied from the authored data, never written here:
  - data/story_chapter*.json  interaction bodies, option responses, unavailable /
                              completed bodies, staff lines, sign-out messages and
                              campaign-end lines (narrator unless a known speaker
                              prefix such as "Hale:" names the voice)
  - data/staff.json           each staff member's intro line, in their own voice
  - data/dialogue*.json       interview responses; spoken player questions where
                              the choice label is itself speech (Mara). Elias Ward
                              is mute, so his responses are narrated observations.
Each passage is split exactly as scripts/dialogue/VoiceScript.gd splits it at run
time, so the game finds the clip by (speaker, text). Line ids are a hash of
speaker and text: changed wording gets a new id and never reuses an old clip.

Usage, from the repository root:
    python3 tools/audio/extract_voice_lines.py           # rewrite the voice_*.json files
    python3 tools/audio/extract_voice_lines.py --check   # exit 1 if they are out of date
Then run tools/audio/generate_voice.py for the new lines.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
NARRATIVE = DATA / "narrative"
NARRATOR = "narrator"

# Keep in step with VoiceScript.SPEAKER_PREFIXES.
SPEAKER_PREFIXES = {
    "You": "player", "Player": "player",
    "Voss": "staff_voss", "Dr Voss": "staff_voss",
    "Hale": "staff_hale", "Hale (radio)": "staff_hale",
    "Bennett": "staff_bennett", "Nurse Bennett": "staff_bennett", "Naomi": "staff_bennett",
    "Rahman": "staff_rahman", "Dr Rahman": "staff_rahman",
    "Mara": "pt_mara_ellis",
    "Technician": "staff_facilities_tech", "Facilities": "staff_facilities_tech",
    "Engineer": "engineer", "Analyst": "analyst",
}
# Speakers whose words are never voiced: their passages are narrated observations.
MUTE = {"pt_elias_ward"}
SPEAKER_NAMES = {
    NARRATOR: "", "player": "You", "staff_voss": "Dr Voss", "staff_hale": "Hale", "staff_bennett": "Nurse Bennett",
    "staff_rahman": "Dr Rahman", "pt_mara_ellis": "Mara", "staff_facilities_tech": "Technician",
    "engineer": "Engineer", "analyst": "Analyst",
}
BBCODE = re.compile(r"\[/?[a-z_]+(=[^\]]*)?\]")
PREFIX = re.compile(r"^([A-Za-z][A-Za-z .'()-]{0,30}):\s+(.+)$", re.S)


def segments(text, default_speaker):
    """(speaker, text) pairs for one authored passage. Mirrors VoiceScript.segments()."""
    result = []
    for paragraph in BBCODE.sub("", text).split("\n\n"):
        paragraph = paragraph.strip()
        if not paragraph:
            continue
        speaker, spoken = default_speaker, paragraph
        if paragraph.startswith("(") and paragraph.endswith(")"):
            speaker = NARRATOR
        else:
            match = PREFIX.match(paragraph)
            if match and match.group(1) in SPEAKER_PREFIXES:
                speaker, spoken = SPEAKER_PREFIXES[match.group(1)], match.group(2).strip()
                if len(spoken) > 1 and spoken.startswith('"') and spoken.endswith('"'):
                    spoken = spoken[1:-1].strip()
        if speaker in MUTE:
            speaker = NARRATOR
        result.append((speaker, spoken))
    return result


def line_id(chapter, speaker, text):
    return "%s_v_%s" % (chapter, hashlib.sha1(f"{speaker}|{text}".encode()).hexdigest()[:10])


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def passages():
    """Yields (chapter, default_speaker, text) for every authored passage."""
    for staff in load(DATA / "staff.json")["staff"]:
        yield "ch1", staff["id"], staff.get("intro_line", "")
    dialogue_chapters = {"pt_elias_ward": "ch1", "pt_mara_ellis": "ch2"}
    for path in sorted(DATA.glob("dialogue*.json")):
        dialogue = load(path)
        patient = dialogue["patient_id"]
        chapter = dialogue_chapters.get(patient, "ch1")
        for state in dialogue["states"]:
            for choice in state["choices"]:
                # Elias's labels are topics; his spoken questions are authored in interview_ch1.json.
                if patient != "pt_elias_ward":
                    yield chapter, "player", choice["label"]
                yield chapter, patient, choice["response"]
    for path in sorted(DATA.glob("story_chapter*.json")):
        story = load(path)
        chapter = story["chapter"]
        for line in story.get("staff_lines", []):
            yield chapter, line["staff_id"], line["text"]
        sign_out = story.get("sign_out", {})
        if sign_out.get("undocumented_message"):
            yield chapter, NARRATOR, sign_out["undocumented_message"]
        for interaction in story.get("interactions", []):
            for key in ("body", "unavailable_body", "completed_body"):
                if interaction.get(key):
                    yield chapter, NARRATOR, interaction[key]
            for option in interaction.get("options", []):
                yield chapter, NARRATOR, option["response"]
        end = story.get("campaign_end")
        if end:
            yield chapter, NARRATOR, end["body"]
            for line in end["lines"]:
                yield chapter, NARRATOR, line["text"]


def authored_keys():
    """(speaker, text) already voiced by hand-authored narrative files."""
    keys = set()
    for path in sorted(NARRATIVE.glob("*.json")):
        if path.name.startswith(("._", "voice_")):
            continue
        for scene in load(path).get("scenes", []):
            for line in scene.get("lines", []):
                keys.add((line["speaker"], line["text"]))
    return keys


def build():
    seen = authored_keys()
    chapters = {}
    for chapter, default_speaker, text in passages():
        for speaker, spoken in segments(text, default_speaker):
            if (speaker, spoken) in seen:
                continue
            seen.add((speaker, spoken))
            chapters.setdefault(chapter, []).append(
                {"id": line_id(chapter, speaker, spoken), "speaker": speaker, "text": spoken})
    files = {}
    for chapter, lines in sorted(chapters.items()):
        speakers = sorted({line["speaker"] for line in lines})
        files[NARRATIVE / f"voice_{chapter}.json"] = {
            "schema_version": "0.1",
            "chapter": chapter,
            "generated_by": "tools/audio/extract_voice_lines.py",
            "_note": "Generated. Do not edit: change the authored text in data/ and re-run the tool, then generate_voice.py.",
            "speakers": {speaker: SPEAKER_NAMES.get(speaker, speaker) for speaker in speakers},
            "scenes": [{"id": f"voice_{chapter}_authored_text", "location": "", "lines": lines}],
        }
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="exit 1 if the generated files are out of date")
    args = parser.parse_args()
    files = build()
    stale = []
    for path, data in files.items():
        text = json.dumps(data, indent="\t", ensure_ascii=False) + "\n"
        if not path.exists() or path.read_text(encoding="utf-8") != text:
            stale.append(path)
            if not args.check:
                path.write_text(text, encoding="utf-8")
    for path in sorted(NARRATIVE.glob("voice_*.json")):
        if path not in files:
            stale.append(path)
            if not args.check:
                path.unlink()
    if args.check and stale:
        sys.exit("out of date: " + ", ".join(p.relative_to(ROOT).as_posix() for p in stale))
    count = sum(len(d["scenes"][0]["lines"]) for d in files.values())
    print(f"{count} derived voice lines in {len(files)} files" + (" (checked)" if args.check else ""))


if __name__ == "__main__":
    main()
