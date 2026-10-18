#!/usr/bin/env python3
"""Portable, fail-closed Godot runner; no third-party Python dependencies."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def run(command, env, expected=None):
    print("+", " ".join(map(str, command)), flush=True)
    result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=150)
    print(result.stdout, end="", flush=True)
    if result.returncode or re.search(r"(?m)^(?:SCRIPT ERROR:|ERROR:|FAIL(?:ED)?:)", result.stdout):
        raise RuntimeError(f"command failed (exit {result.returncode})")
    if expected and not re.search(expected, result.stdout):
        raise RuntimeError(f"missing completion evidence: {expected}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    args = parser.parse_args()
    # Isolate Linux cache/config so save/load tests never touch real user data.
    with tempfile.TemporaryDirectory(prefix="forensic-ward-qa-") as directory:
        env = dict(os.environ, XDG_DATA_HOME=directory,
                   XDG_CACHE_HOME=directory, XDG_CONFIG_HOME=directory)
        run([sys.executable, "tests/qa/test_json.py"], env, r"\bOK\b")
        run([sys.executable, "tests/qa/test_audio_manifest.py"], env, r"\bOK\b")
        run([sys.executable, "tests/qa/test_cutscenes.py"], env, r"\bOK\b")
        run([sys.executable, "tests/music_ai/test_generate_music.py"], env, r"\bOK\b")
        run([args.godot, "--version"], env, r"(?m)^4\.7\.")
        base = [args.godot, "--headless", "--path", str(ROOT)]
        run(base + ["--editor", "--import"], env)
        run(base + ["res://tests/TestPharmacology.tscn"], env, r"PASSED: 0 failure\(s\)")
        run(base + ["res://tests/qa/TestQA.tscn"], env,
            r"QA_RESULT passed=[1-9][0-9]* failed=0 skipped=0")
        run(base + ["-s", "res://tools/godot/validate_glb_imports.gd"], env,
            r"GLB VALIDATION PASSED: [1-9][0-9]* assets checked, 0 failure\(s\)")
        run(base + ["res://scripts/tests/TestRunner.tscn"], env, r"(?m)^PASSED: [1-9][0-9]* passed, 0 failed")
        run(base + ["--quit-after", "60"], env, r"\[The Forensic Ward\] Boot OK")
        run(base + ["res://tests/audio/TestAudio.tscn"], env, r"AUDIO_RESULT passed=[1-9][0-9]* failed=0")
        run(base + ["res://scenes/audio/Ch1AudioSequence.tscn", "--", "--exit-when-done"], env,
            r"(?s)corridor ambience \(day\).*secure door.*pager.*SUBTITLE ch1_b2_bennett_001.*"
            r"SUBTITLE ch1_b2_bennett_003.*night shift.*SUBTITLE ch1_b6_intercom_001.*unease transition.*CH1_SEQUENCE_DONE")
    print("All executed checks passed (see docs/TESTING.md).")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"QA runner failed: {error}", file=sys.stderr)
        sys.exit(1)
