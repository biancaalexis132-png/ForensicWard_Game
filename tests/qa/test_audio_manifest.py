"""Audio manifest checks with the standard library only (durations are checked in Godot)."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
AUDIO_EXTENSIONS = {".ogg", ".wav", ".mp3"}
REQUIRED = ("file", "ids", "category", "source", "license", "location", "duration_seconds",
            "integration_status", "review_status", "sha256")


def load(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


class AudioManifestTests(unittest.TestCase):
    def test_manifest_matches_files(self):
        assets = load("audio/manifest.json")["assets"]
        listed = {asset["file"] for asset in assets}
        on_disk = {p.relative_to(ROOT).as_posix() for p in (ROOT / "audio").rglob("*")
                   if p.suffix in AUDIO_EXTENSIONS and "music_ai" not in p.parts}
        self.assertEqual(listed, on_disk)
        for asset in assets:
            with self.subTest(file=asset["file"]):
                for field in REQUIRED:
                    self.assertNotIn(asset.get(field), (None, "", []), field)
                self.assertGreater(asset["duration_seconds"], 0)

    def test_every_line_has_profile_and_clip(self):
        profiles = load("audio/voice_profiles.json")["profiles"]
        index = load("audio/voice/voice_lines.json")
        ids = set()
        for path in sorted((ROOT / "data/narrative").glob("*.json")):
            data = json.loads(path.read_text(encoding="utf-8"))
            for scene in data["scenes"]:
                for line in scene["lines"]:
                    with self.subTest(line=line["id"]):
                        self.assertNotIn(line["id"], ids, "duplicate line id")
                        ids.add(line["id"])
                        self.assertIn(line["speaker"], profiles)
                        self.assertIn(line["speaker"], data["speakers"])
                        self.assertTrue((ROOT / f"audio/voice/{data['chapter']}/{line['id']}.ogg").exists())
                        self.assertIn(line["id"], index)

    def test_cue_references(self):
        cues = load("audio/cues.json")
        lines = {line["id"] for p in (ROOT / "data/narrative").glob("*.json")
                 for scene in json.loads(p.read_text(encoding="utf-8"))["scenes"] for line in scene["lines"]}
        scenes = {scene["id"] for p in (ROOT / "data/narrative").glob("*.json")
                  for scene in json.loads(p.read_text(encoding="utf-8"))["scenes"]}
        for cue_id, cue in cues["cues"].items():
            with self.subTest(cue=cue_id):
                for stream in cue.get("streams", [cue.get("stream")]):
                    self.assertTrue((ROOT / stream.removeprefix("res://")).exists(), stream)
                self.assertIn(cue["bus"], {"Music", "AmbienceBed", "SFX", "Voice"})
        for location_id, location in cues["locations"].items():
            for shift in ("day", "night"):
                if shift in location:
                    self.assertIn(location[shift]["ambience"], cues["cues"], location_id)
                    if location[shift].get("detail"):
                        self.assertIn(location[shift]["detail"], cues["cues"], location_id)
        for cue_id, cue in cues["cues"].items():
            if cue_id.startswith(("sfx_w0_", "amb_w0_")):
                with self.subTest(anomaly=cue_id):
                    self.assertTrue(cue.get("startle"), "Ward Zero anomaly cues must be startle-flagged")
        for event_id, actions in cues["events"].items():
            for action in actions:
                with self.subTest(event=event_id):
                    for key in ("sfx", "stinger", "music"):
                        if key in action:
                            self.assertIn(action[key], cues["cues"])
                    if "line" in action:
                        self.assertIn(action["line"], lines)
                    if "scene" in action:
                        self.assertIn(action["scene"], scenes)


if __name__ == "__main__":
    unittest.main(verbosity=2)
