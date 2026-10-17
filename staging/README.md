# Staging: approved clinical modules awaiting integration

Godot ignores this folder (`.gdignore`), so nothing here is loaded, compiled or exported.

## `pharmacology/`

An exposure model for CYP/renal clearance, side-effect burden and QTc (PharmacologyEngine, the drug database and its scenario tests), written before Master GDD v0.1 was adopted.

- **Clinical review:** approved by the executive producer (psychiatrist) on 2026-10-17. See `docs/clinical_review_log.md`.
- **Integration status:** not yet wired in. It targets the earlier project layout (old `EventBus` signals, `GameState`), and GDD §8 requires every rule to carry an id, source, review date, approval and test examples inside the governed rule system.
- **Planned:** Sprint 2, together with the `ClinicalRules` scaffolding. The model will be re-expressed as governed rule data evaluated through `ClinicalRules.gd`, and its scenario tests ported to `scripts/tests/`.
