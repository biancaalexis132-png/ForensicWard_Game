#!/usr/bin/env python3
"""Builds audio/manifest.json and docs/AUDIO_MANIFEST.md from the files in audio/.

Authored fields (source, license, location, notes, review_status) are kept from
the existing manifest; measured fields (duration, sha256) and integration status
are recomputed. Voice clips are described from audio/voice/voice_lines.json and
data/narrative, so they never need hand-written entries.

    .venv-audio/bin/python tools/audio/build_manifest.py          # rewrite manifest
    .venv-audio/bin/python tools/audio/build_manifest.py --check  # fail if out of date
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

import soundfile as sf

from generate_voice import INDEX_PATH, PROFILES_PATH, line_hash, load_json, narrative_lines

ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "audio/manifest.json"
TABLE_PATH = ROOT / "docs/AUDIO_MANIFEST.md"
CUES_PATH = ROOT / "audio/cues.json"
AUDIO_EXTENSIONS = {".ogg", ".wav", ".mp3"}

VOICE_LICENSE = ("Generated offline with Kokoro-82M v1.0 (Apache-2.0) via kokoro-onnx (MIT); "
                 "stock synthetic voice, not cloned from a real person. Usable in the commercial game.")
REQUIRED = ("file", "ids", "category", "source", "license", "location", "duration_seconds",
            "integration_status", "review_status")


def measure(path):
    info = sf.info(str(path))
    return round(info.frames / info.samplerate, 3), hashlib.sha256(path.read_bytes()).hexdigest()


def references():
    """Maps res:// paths and line IDs to the cue/event IDs that use them."""
    cues = load_json(CUES_PATH)
    by_path, by_line = {}, {}
    scene_lines = {}
    for path in sorted((ROOT / "data/narrative").glob("*.json")):
        for scene in load_json(path).get("scenes", []):
            scene_lines[scene["id"]] = [line["id"] for line in scene.get("lines", [])]
    for cue_id, cue in cues["cues"].items():
        by_path.setdefault(cue["stream"].removeprefix("res://"), []).append(cue_id)
    for event_id, actions in cues["events"].items():
        for action in actions:
            for key in ("sfx", "stinger", "music"):
                if key in action:
                    stream = cues["cues"][action[key]]["stream"].removeprefix("res://")
                    by_path.setdefault(stream, []).append(event_id)
            if "line" in action:
                by_line.setdefault(action["line"], []).append(event_id)
            for line_id in scene_lines.get(action.get("scene"), []):
                by_line.setdefault(line_id, []).append(event_id)
    return by_path, by_line


def build():
    existing = {}
    if MANIFEST_PATH.exists():
        existing = {entry["file"]: entry for entry in load_json(MANIFEST_PATH)["assets"]}
    profiles = load_json(PROFILES_PATH)["profiles"]
    voice_index = load_json(INDEX_PATH) if INDEX_PATH.exists() else {}
    lines = {line["id"]: (chapter, line) for chapter, line in narrative_lines()}
    scene_locations = {}
    for path in sorted((ROOT / "data/narrative").glob("*.json")):
        for scene in load_json(path).get("scenes", []):
            for line in scene.get("lines", []):
                scene_locations[line["id"]] = scene.get("location", "")
    by_path, by_line = references()
    problems = []
    assets = []
    for path in sorted(p for p in (ROOT / "audio").rglob("*") if p.suffix in AUDIO_EXTENSIONS):
        relative = path.relative_to(ROOT).as_posix()
        duration, digest = measure(path)
        entry = dict(existing.get(relative, {"file": relative}))
        entry["duration_seconds"] = duration
        entry["sha256"] = digest
        if relative.startswith("audio/voice/"):
            line_id = path.stem
            if line_id not in lines:
                problems.append(f"{relative}: line '{line_id}' is not in data/narrative")
                continue
            chapter, line = lines[line_id]
            profile = profiles[line["speaker"]]
            record = voice_index.get(line_id, {})
            if record.get("source_hash") != line_hash(line, profile):
                problems.append(f"{relative}: stale; text or voice profile changed (run generate_voice.py)")
            entry.update({
                "ids": [line_id] + by_line.get(line_id, []),
                "category": "intercom" if profile["fx"] == "intercom" else "dialogue",
                "speaker": line["speaker"],
                "text": line["text"],
                "source": f"Kokoro TTS voice '{profile['voice']}' speed {profile['speed']}, fx '{profile['fx']}' (tools/audio/generate_voice.py)",
                "license": VOICE_LICENSE,
                "location": entry.get("location") or scene_locations.get(line_id, ""),
            })
            integrated = True
        else:
            entry["ids"] = by_path.get(relative, entry.get("ids", []))
            integrated = relative in by_path
        entry["integration_status"] = "integrated" if integrated else "not_integrated"
        entry.setdefault("review_status", "pending_listening_review")
        for field in REQUIRED:
            if entry.get(field) in (None, "", []):
                problems.append(f"{relative}: missing '{field}'")
        assets.append({key: entry[key] for key in sorted(entry, key=lambda k: (k != "file", k))})
    listed = {a["file"] for a in assets}
    for missing in sorted(set(existing) - listed):
        problems.append(f"{missing}: listed in manifest but file is missing")
    return {"schema_version": "0.1", "assets": assets}, problems


def table(manifest):
    rows = ["# Audio asset manifest", "",
            "Generated by `tools/audio/build_manifest.py` from `audio/manifest.json`; do not edit by hand.", "",
            "| File | IDs | Source / method | License | Location | Duration (s) | Integration | Review |",
            "|---|---|---|---|---|---|---|---|"]
    for a in manifest["assets"]:
        cells = [f"`{a['file']}`", ", ".join(f"`{i}`" for i in a["ids"]), a["source"], a["license"],
                 a["location"], f"{a['duration_seconds']:.2f}", a["integration_status"], a["review_status"]]
        rows.append("| " + " | ".join(str(c).replace("|", "\\|") for c in cells) + " |")
    return "\n".join(rows) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify without writing")
    args = parser.parse_args()
    manifest, problems = build()
    text = json.dumps(manifest, indent="\t", ensure_ascii=False) + "\n"
    if args.check:
        if not MANIFEST_PATH.exists() or MANIFEST_PATH.read_text(encoding="utf-8") != text:
            problems.append("audio/manifest.json is out of date (run build_manifest.py)")
        if not TABLE_PATH.exists() or TABLE_PATH.read_text(encoding="utf-8") != table(manifest):
            problems.append("docs/AUDIO_MANIFEST.md is out of date (run build_manifest.py)")
    else:
        MANIFEST_PATH.write_text(text, encoding="utf-8")
        TABLE_PATH.write_text(table(manifest), encoding="utf-8")
        print(f"wrote {MANIFEST_PATH.relative_to(ROOT)} ({len(manifest['assets'])} assets) and {TABLE_PATH.relative_to(ROOT)}")
    for problem in problems:
        print("problem:", problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
