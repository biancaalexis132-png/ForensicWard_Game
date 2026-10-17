"""Content checks, not a replacement for runtime validation in gameplay code."""
import copy
import json
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]


def is_macos_metadata(path):
    """macOS writes AppleDouble "._name" companions on exFAT/FAT/network drives."""
    return path.name.startswith("._") or "__MACOSX" in path.parts


def content_files(directory, pattern="*.json", recursive=True):
    found = directory.rglob(pattern) if recursive else directory.glob(pattern)
    return sorted(p for p in found if p.is_file() and not is_macos_metadata(p))


def read_json(path):
    return decode(path.read_text(encoding="utf-8"))


def decode(text):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"duplicate JSON key: {key}")
            result[key] = value
        return result
    def invalid(value):
        raise ValueError(f"non-finite JSON number: {value}")
    return json.loads(text, object_pairs_hook=unique, parse_constant=invalid)


def number(value, minimum=0):
    return type(value) in (int, float) and value >= minimum


def patient_errors(data, drug_ids):
    if not isinstance(data, dict):
        return ["patient must be an object"]
    errors = []
    if not isinstance(data.get("id"), str) or not data["id"].strip():
        errors.append("patient requires a nonempty string id")
    meds = data.get("home_medications", [])
    if not isinstance(meds, list):
        return errors + ["home_medications must be an array"]
    seen = set()
    for med in meds:
        if not isinstance(med, dict):
            errors.append("medication must be an object")
            continue
        drug = med.get("drug_id")
        if not isinstance(drug, str) or drug not in drug_ids:
            errors.append("unknown drug_id")
        elif drug in seen:
            errors.append("duplicate medication")
        else:
            seen.add(drug)
        if not number(med.get("daily_dose_mg")):
            errors.append("dose must be a nonnegative number")
    for key in ("age", "weight_kg", "egfr", "baseline_qtc_ms", "potassium_mmol_l"):
        if key in data and not number(data[key]):
            errors.append(f"{key} must be a nonnegative number")
    return errors


class ContentTests(unittest.TestCase):
    def test_all_json_syntax(self):
        paths = content_files(ROOT / "data")
        self.assertTrue(paths, "no content discovered")
        for path in paths:
            with self.subTest(path=path.relative_to(ROOT)):
                read_json(path)

    def test_drugs_and_patient_references(self):
        database = read_json(ROOT / "data/drugs/drugs.json")
        self.assertIsInstance(database, dict)
        drugs = database["drugs"]
        self.assertIsInstance(drugs, list)
        self.assertTrue(drugs)
        ids = set()
        for drug in drugs:
            with self.subTest(drug=drug.get("id")):
                self.assertIsInstance(drug["id"], str)
                self.assertTrue(drug["id"])
                self.assertNotIn(drug["id"], ids)
                ids.add(drug["id"])
                for key in ("half_life_hours", "reference_daily_dose_mg", "max_daily_dose_mg"):
                    self.assertTrue(number(drug[key]) and drug[key] > 0, key)
                self.assertGreaterEqual(drug["max_daily_dose_mg"], drug["reference_daily_dose_mg"])
                self.assertIsInstance(drug["pathways"], dict)
                self.assertTrue(all(number(v) for v in drug["pathways"].values()))
                self.assertAlmostEqual(sum(drug["pathways"].values()), 1.0, places=5)
        paths = content_files(ROOT / "data/patients", recursive=False)
        self.assertTrue(paths)
        patient_ids = set()
        for path in paths:
            with self.subTest(patient=path.name):
                data = read_json(path)
                self.assertEqual(patient_errors(data, ids), [])
                self.assertNotIn(data["id"], patient_ids)
                patient_ids.add(data["id"])

    def test_macos_metadata_is_skipped_not_genuine_content(self):
        for name in ("data/patients/._PT-001.json", "data/__MACOSX/patients/PT-001.json"):
            self.assertTrue(is_macos_metadata(ROOT / name), name)
        for name in ("data/patients/PT-001.json", "data/patients/_draft.json", "data/patients/.hidden.json"):
            self.assertFalse(is_macos_metadata(ROOT / name), name)

    def test_no_macos_metadata_tracked(self):
        git = shutil.which("git")
        if not git or not (ROOT / ".git").exists():
            self.skipTest("not a git checkout")
        listed = subprocess.run([git, "-C", str(ROOT), "ls-files", "-z"], capture_output=True, check=True)
        tracked = [p for p in listed.stdout.decode("utf-8", "replace").split("\0") if p]
        bad = [p for p in tracked if is_macos_metadata(Path(p)) or Path(p).name == ".DS_Store"]
        self.assertEqual(bad, [], "macOS metadata committed; git rm --cached it (see .gitignore)")

    def test_reject_invalid_json(self):
        for text in ('{', '{"id":1,"id":2}', '{"dose":NaN}', '{"dose":Infinity}'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                decode(text)

    def test_reject_invalid_patient_content(self):
        valid = {"id": "QA", "home_medications": [{"drug_id": "clozapine", "daily_dose_mg": 300}]}
        self.assertEqual(patient_errors(valid, {"clozapine"}), [])
        invalid = [[], {}, dict(valid, id=42), dict(valid, home_medications={}), dict(valid, egfr=-1)]
        for field, value in (("drug_id", "missing"), ("daily_dose_mg", -1), ("daily_dose_mg", "300"), ("daily_dose_mg", True)):
            sample = copy.deepcopy(valid)
            sample["home_medications"][0][field] = value
            invalid.append(sample)
        for sample in invalid:
            with self.subTest(sample=sample):
                self.assertTrue(patient_errors(sample, {"clozapine"}))


if __name__ == "__main__":
    unittest.main(verbosity=2)
