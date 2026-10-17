"""Content checks, not a replacement for runtime validation in gameplay code."""
import copy
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


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
        paths = sorted((ROOT / "data").rglob("*.json"))
        self.assertTrue(paths, "no content discovered")
        for path in paths:
            with self.subTest(path=path.relative_to(ROOT)):
                decode(path.read_text())

    def test_drugs_and_patient_references(self):
        database = decode((ROOT / "data/drugs/drugs.json").read_text())
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
        paths = sorted((ROOT / "data/patients").glob("*.json"))
        self.assertTrue(paths)
        patient_ids = set()
        for path in paths:
            with self.subTest(patient=path.name):
                data = decode(path.read_text())
                self.assertEqual(patient_errors(data, ids), [])
                self.assertNotIn(data["id"], patient_ids)
                patient_ids.add(data["id"])

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
