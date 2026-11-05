"""Static contract for graphic-novel cutscenes (data/cutscenes/*.json).

Mirrors the runtime checks in scripts/cutscene/CutsceneRegistry.gd so a broken
cutscene is caught before Godot starts, and adds repository-level checks:
every panel texture has a provenance entry, and no cutscene is enabled in the
campaign before the owner approves it.
"""
import hashlib
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
CUTSCENES = ROOT / "data/cutscenes"
OWNER_SUPPLIED = "owner_supplied:"
REVIEW_STATUSES = {"UNAPPROVED_REVIEW_ONLY", "OWNER_APPROVED_ART_REVIEW_ONLY_PLACEMENT"}
RESERVED_CUES = {"mus_temporal_fracture", "mus_final_revelation", "mus_ending_credits"}


def res_path(path):
    assert path.startswith("res://"), path
    return ROOT / path[len("res://"):]


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


# Cutscenes the owner approved for the campaign (2026-10-19), with their trigger:
# title cards open Chapters 2-5, the static graphic-novel pages recap Chapters 1-5
# when each is completed. Any other cutscene stays review-only until the owner
# approves it and it is added here.
OWNER_APPROVED_CAMPAIGN = {
    **{f"cs_ch0{n}_title": "chapter_start" for n in (2, 3, 4, 5)},
    **{f"cs_ch0{n}_static_gn": "chapter_complete" for n in (1, 2, 3, 4, 5)},
    "cs_ch01_prologue": "new_game",  # Owner approved 2026-10-21.
}


class CutsceneContractTests(unittest.TestCase):
    def setUp(self):
        self.files = sorted(p for p in CUTSCENES.glob("*.json") if not p.name.startswith("._"))
        campaign = load(ROOT / "data/campaign.json")
        self.chapters = [c["id"] for c in campaign["chapters"]]
        self.captions = {"institution.name": campaign["institution"]["name"]}
        self.captions.update({f"chapter.{c['id']}.title": c["title"] for c in campaign["chapters"]})
        self.cues = set(load(ROOT / "audio/cues.json")["cues"])
        self.lines = {}
        for path in (ROOT / "data/narrative").glob("*.json"):
            narrative = load(path)
            for scene in narrative.get("scenes", []):
                for line in scene.get("lines", []):
                    self.lines[line["id"]] = narrative.get("chapter", "")

    def test_cutscenes_exist(self):
        self.assertTrue(self.files, "no cutscenes found")

    def test_review_only_until_approved(self):
        for path in self.files:
            data = load(path)
            with self.subTest(path=path.name):
                self.assertEqual(path.stem, data["cutscene_id"])
                if path.stem in OWNER_APPROVED_CAMPAIGN:
                    self.assertEqual(data["mode"], "campaign")
                    self.assertIs(data["approved"], True)
                    self.assertEqual(data["trigger"], {"kind": OWNER_APPROVED_CAMPAIGN[path.stem]})
                    continue
                self.assertEqual(data["mode"], "review_only")
                self.assertIs(data["approved"], False, "only the owner approves a cutscene")
                self.assertEqual(data["trigger"], {"kind": "manual_preview"})
                self.assertEqual(data["fallback_action"], "restore_world")

    def test_references_exist(self):
        for path in self.files:
            data = load(path)
            chapter = self.chapters.index(data["chapter_id"])
            music = data.get("music")
            if music:
                self.assertIn(music["cue"], self.cues, path.name)
                self.assertNotIn(music["cue"], RESERVED_CUES, f"{path.name}: reveal cue used in a cutscene")
            for panel in data["panels"]:
                with self.subTest(path=path.name, panel=panel["id"]):
                    self.assertGreater(panel["duration_seconds"], 0)
                    self.assertTrue(1 <= len(panel["layers"]) <= 3)
                    for layer in panel["layers"]:
                        self.assertTrue(res_path(layer["texture"]).is_file(), layer["texture"])
                    for key in ("text", "caption", "subtitle"):
                        self.assertNotIn(key, panel, "no literal text in panels")
                    if panel.get("caption_ref") is not None:
                        self.assertIn(panel["caption_ref"], self.captions)
                    if panel.get("line_id") is not None:
                        self.assertIn(panel["line_id"], self.lines, "dialogue must already exist")
                        self.assertLessEqual(self.chapters.index(self.lines[panel["line_id"]]), chapter)

    def test_every_texture_has_provenance(self):
        for path in self.files:
            for panel in load(path)["panels"]:
                for layer in panel["layers"]:
                    texture = res_path(layer["texture"])
                    manifest = load(texture.parent / "manifest.json")
                    entries = {a["path"]: a for a in manifest["assets"]}
                    rel = texture.relative_to(ROOT).as_posix()
                    with self.subTest(texture=rel):
                        self.assertIn(rel, entries)
                        self.assertIn(manifest["review_status"], REVIEW_STATUSES)
                        source = entries[rel]["source"]
                        if source.startswith(OWNER_SUPPLIED):
                            # Owner art kept outside the repo: the copy must stay byte-identical.
                            digest = hashlib.sha256(texture.read_bytes()).hexdigest()
                            self.assertEqual(entries[rel]["sha256"], digest, "owner art was modified")
                        elif source != "procedural":
                            self.assertTrue((ROOT / source).is_file(), source)

    def test_static_graphic_novel_covers_every_chapter(self):
        # Owner-approved static art (2026-10-19): one chapter recap per chapter,
        # every package panel in order, single unmodified layer, no dialogue.
        for number, chapter in enumerate(self.chapters, start=1):
            path = CUTSCENES / f"cs_ch{number:02d}_static_gn.json"
            if not path.is_file():
                continue
            data = load(path)
            manifest = load(ROOT / f"assets/cutscenes/static_gn_v1/ch{number:02d}/manifest.json")
            with self.subTest(cutscene=path.stem):
                self.assertEqual(data["chapter_id"], chapter)
                self.assertEqual(manifest["review_status"], "OWNER_APPROVED_ART_REVIEW_ONLY_PLACEMENT")
                expected = [f"res://{a['path']}" for a in manifest["assets"]]
                self.assertEqual([p["layers"][0]["texture"] for p in data["panels"]], expected)
                for panel in data["panels"]:
                    self.assertEqual(len(panel["layers"]), 1, "no overlay painted on owner art")
                    self.assertIsNone(panel["line_id"])

    def test_pilot_shape(self):
        data = load(CUTSCENES / "cs_ch01_first_shift_pilot.json")
        self.assertEqual(len(data["panels"]), 7)
        self.assertEqual(sum(p["duration_seconds"] for p in data["panels"]), 52)
        self.assertEqual(data["chapter_id"], "ch1")


if __name__ == "__main__":
    unittest.main(verbosity=2)
