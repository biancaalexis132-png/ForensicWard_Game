#!/usr/bin/env python3
"""Collect Mac acceptance evidence without declaring visual/audio approval.

Run from a clean internal-disk checkout. No third-party Python dependencies.
"""
import argparse
import datetime
import json
from pathlib import Path
import platform
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="/Applications/Godot.app/Contents/MacOS/Godot")
    parser.add_argument("--output", type=Path, default=ROOT / "work/mac-acceptance")
    args = parser.parse_args()
    if sys.platform != "darwin":
        parser.error("Mac acceptance requires macOS; Linux evidence cannot substitute.")
    args.output.mkdir(parents=True, exist_ok=True)

    def capture(command):
        return subprocess.check_output(command, cwd=ROOT, text=True).strip()

    report = {
        "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "commit": capture(["git", "rev-parse", "HEAD"]),
        "tracked_changes": capture(["git", "status", "--short", "--untracked-files=no"]),
        "macos": platform.mac_ver()[0], "architecture": platform.machine(),
        "memory_bytes": int(capture(["sysctl", "-n", "hw.memsize"])),
        "godot": capture([args.godot, "--version"]),
        "automated_qa": "NOT_RUN", "visual_acceptance": "PENDING_OWNER_PLAYTEST",
        "listening_acceptance": "PENDING_OWNER_LISTENING",
    }
    report_path = args.output / "report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    with (args.output / "qa.log").open("w") as log:
        result = subprocess.run([sys.executable, "tests/qa/run.py", "--godot", args.godot],
                                cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    report["automated_qa"] = "PASS" if result.returncode == 0 else "FAIL"
    report["qa_exit_code"] = result.returncode
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Saved {report_path} and qa.log. Visual and listening acceptance remain pending.")
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
