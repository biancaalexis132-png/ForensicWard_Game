#!/usr/bin/env python3
"""ACE-Step 1.5 music pipeline for The Forensic Ward (runs on the Mac, not in the game).

Talks to a local ACE-Step REST API server (start it with
tools/music_ai/ACE-Step-1.5/start_api_server_macos.sh), generates candidates
from tools/music_ai/score.json, verifies that each result is real, playable
audio, measures it, and imports approved takes into Godot. Standard library
only; needs ffmpeg/ffprobe on PATH (brew install ffmpeg).

    python3 tools/music_ai/generate_music.py check
    python3 tools/music_ai/generate_music.py list
    python3 tools/music_ai/generate_music.py generate --first-deliverable
    python3 tools/music_ai/generate_music.py generate clinical_routine_calm clinical_routine_tense
    python3 tools/music_ai/generate_music.py generate after_hours_calm --reference main_theme
    python3 tools/music_ai/generate_music.py qa tools/music_ai/output/main_menu_a_piano/main_menu_a_piano.wav
    python3 tools/music_ai/generate_music.py approve main_menu_b_strings --approved-by "Your Name"

Candidates go to tools/music_ai/output/<candidate>/ (ignored by Git):
  <candidate>.wav      untouched ACE-Step master
  <candidate>_preview.ogg  loudness-normalized preview for listening
  generation.json      exact request, returned metadata, seed, model, timings
  qa.json              duration, loudness, true peak, clipping, silence
`approve` normalizes, builds a seamless loop if the track loops, encodes OGG
into audio/music_ai/<track>/, and updates audio/music_ai/music_cues.json and
audio/music_ai/manifest.json (both read by Godot's AudioDirector).
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(os.environ.get("FW_ROOT", Path(__file__).resolve().parents[2]))
SCORE_PATH = ROOT / "tools/music_ai/score.json"
OUTPUT_DIR = ROOT / "tools/music_ai/output"
MUSIC_DIR = ROOT / "audio/music_ai"
DEFAULT_API = os.environ.get("ACESTEP_API_URL", "http://127.0.0.1:8001")

TARGET_LUFS = -20.0       # Music bed loudness before the in-game Music bus and ducking.
TARGET_TRUE_PEAK = -1.5   # dBTP, leaves room for OGG encoding overshoot.
LOOP_CROSSFADE = 4.0      # Seconds of equal-power overlap at the loop seam.
FIRST_DELIVERABLE = ["main_menu_a_piano", "main_menu_b_strings", "main_menu_c_analog"]
LICENSE_NOTE = ("Generated locally with ACE-Step 1.5 (code: MIT). Confirm the model-weight license on the "
                "Hugging Face/ModelScope model card before release; ACE-Step asks users to check originality "
                "and disclose AI involvement.")


# --- Score -----------------------------------------------------------------------

def load_score():
    return json.loads(SCORE_PATH.read_text(encoding="utf-8"))


def candidates(score):
    """All candidates as {id, track, variant, seed, caption, min_intensity, ...}."""
    result = {}
    prefix = score["identity"]["caption_prefix"]
    for track in score["tracks"]:
        for entry in track.get("candidates", []):
            variant = entry["id"].removeprefix(track["id"] + "_")
            result[entry["id"]] = dict(track_entry(track), variant=variant, seed=entry["seed"],
                                       min_intensity=0.0, caption=" ".join([prefix, track["caption"], entry["caption"]]))
        for entry in track.get("variants", []):
            candidate_id = f"{track['id']}_{entry['id']}"
            result[candidate_id] = dict(track_entry(track), variant=entry["id"], seed=entry["seed"],
                                        min_intensity=entry.get("min_intensity", 0.0),
                                        caption=" ".join([prefix, track["caption"], entry["caption"]]))
    for candidate_id, entry in result.items():
        entry["id"] = candidate_id
    return result


def track_entry(track):
    keys = ("bpm", "key_scale", "time_signature", "duration", "loop", "location", "title")
    return {"track": track["id"], **{key: track[key] for key in keys}}


# --- ffmpeg helpers ------------------------------------------------------------------

def require_ffmpeg():
    for tool in ("ffmpeg", "ffprobe"):
        if shutil.which(tool) is None:
            sys.exit(f"{tool} not found. Install it with: brew install ffmpeg")


def ffmpeg(*args):
    return subprocess.run(["ffmpeg", "-hide_banner", "-nostats", *args], capture_output=True, text=True)


def probe_duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True)
    return float(out.stdout.strip() or 0)


def measure(path):
    """Decodes the whole file (proves it is playable) and returns loudness/peak/silence metrics."""
    decode = ffmpeg("-v", "error", "-i", str(path), "-f", "null", "-")
    if decode.returncode != 0 or decode.stderr.strip():
        raise RuntimeError(f"{path} is not cleanly decodable: {decode.stderr.strip()[:300]}")
    stats = ffmpeg("-i", str(path), "-af", "ebur128=peak=true,astats=measure_overall=Peak_count+Peak_level:measure_perchannel=0,"
                   "silencedetect=noise=-50dB:d=2", "-f", "null", "-").stderr
    integrated = re.findall(r"I:\s+(-?[\d.]+|-inf) LUFS", stats)
    true_peak = re.findall(r"Peak:\s+(-?[\d.]+|-inf) dBFS", stats)
    peak_count = re.findall(r"Peak count:\s+([\d.]+)", stats)
    peak_level = re.findall(r"Peak level dB:\s+(-?[\d.]+|-inf)", stats)
    silence = sum(float(x) for x in re.findall(r"silence_duration:\s+([\d.]+)", stats))
    duration = probe_duration(path)
    metrics = {
        "duration_seconds": round(duration, 3),
        "integrated_lufs": float(integrated[-1]) if integrated else None,
        "true_peak_dbtp": float(true_peak[-1]) if true_peak else None,
        "sample_peak_db": float(peak_level[-1]) if peak_level else None,
        "samples_at_peak": int(float(peak_count[-1])) if peak_count else None,
        "silence_seconds_below_-50dB": round(silence, 2),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }
    metrics["warnings"] = qa_warnings(metrics)
    return metrics


def qa_warnings(m):
    warnings = []
    if m["integrated_lufs"] is None or m["integrated_lufs"] < -45:
        warnings.append("near-silent output")
    if m["sample_peak_db"] is not None and m["sample_peak_db"] > -0.1 and (m["samples_at_peak"] or 0) > 4:
        warnings.append("probable clipping (repeated full-scale samples)")
    if m["true_peak_dbtp"] is not None and m["true_peak_dbtp"] > -1.0:
        warnings.append("true peak above -1 dBTP")
    if m["duration_seconds"] and m["silence_seconds_below_-50dB"] > 0.5 * m["duration_seconds"]:
        warnings.append("more than half silent")
    return warnings


def loudnorm_filter(path):
    """Two-pass EBU R128 normalization: measure, then apply linearly (no pumping)."""
    first = ffmpeg("-i", str(path), "-af", f"loudnorm=I={TARGET_LUFS}:TP={TARGET_TRUE_PEAK}:LRA=11:print_format=json",
                   "-f", "null", "-").stderr
    data = json.loads(first[first.rindex("{"):first.rindex("}") + 1])
    return (f"loudnorm=I={TARGET_LUFS}:TP={TARGET_TRUE_PEAK}:LRA=11:linear=true:"
            f"measured_I={data['input_i']}:measured_TP={data['input_tp']}:measured_LRA={data['input_lra']}:"
            f"measured_thresh={data['input_thresh']}:offset={data['target_offset']}")


def encode(source, target, loop, quality=6):
    """Normalizes and encodes 48 kHz OGG. Loops get an equal-power seam so the end flows into the start."""
    target.parent.mkdir(parents=True, exist_ok=True)
    norm = loudnorm_filter(source)
    if loop:
        # Body (x..end) crossfades into the head (0..x): the file ends exactly
        # where it begins, so Godot's loop point is seamless.
        length = probe_duration(source)
        x = LOOP_CROSSFADE
        graph = (f"[0:a]{norm},aresample=48000,atrim={x}:{length},asetpts=PTS-STARTPTS[body];"
                 f"[1:a]{norm},aresample=48000,atrim=0:{x},asetpts=PTS-STARTPTS[head];"
                 f"[body][head]acrossfade=d={x}:c1=qsin:c2=qsin[out]")
        args = ["-i", str(source), "-filter_complex", graph, "-map", "[out]"]
    else:
        args = ["-af", f"{norm},aresample=48000,afade=t=out:st={max(probe_duration(source) - 2.0, 0)}:d=2"]
    result = ffmpeg("-y", "-v", "error", "-i", str(source), *args, "-c:a", "libvorbis", "-q:a", str(quality),
                    "-map_metadata", "-1", str(target))
    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg failed for {target}: {result.stderr[-500:]}")


# --- ACE-Step API ----------------------------------------------------------------------

def api(base, path, payload=None, timeout=60):
    data = None if payload is None else json.dumps(payload).encode()
    request = urllib.request.Request(base + path, data=data, method="POST" if data else "GET",
                                     headers={"Content-Type": "application/json"})
    if os.environ.get("ACESTEP_API_KEY"):
        request.add_header("Authorization", "Bearer " + os.environ["ACESTEP_API_KEY"])
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = json.loads(response.read())
    if body.get("code", 200) != 200 or body.get("error"):
        raise RuntimeError(f"ACE-Step API error on {path}: {body.get('error')}")
    return body.get("data")


def api_multipart(base, path, fields, file_field, file_path, timeout=120):
    """POST multipart/form-data (ACE-Step's way to upload reference audio)."""
    boundary = "----fw" + hashlib.sha1(str(time.time()).encode()).hexdigest()
    parts = []
    for key, value in fields.items():
        if isinstance(value, bool):
            value = "true" if value else "false"  # The server parses form booleans from text.
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode())
    parts.append((f'--{boundary}\r\nContent-Disposition: form-data; name="{file_field}"; filename="{file_path.name}"\r\n'
                  "Content-Type: application/octet-stream\r\n\r\n").encode() + file_path.read_bytes() + b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode())
    request = urllib.request.Request(base + path, data=b"".join(parts), method="POST",
                                     headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
    if os.environ.get("ACESTEP_API_KEY"):
        request.add_header("Authorization", "Bearer " + os.environ["ACESTEP_API_KEY"])
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = json.loads(response.read())
    if body.get("code", 200) != 200 or body.get("error"):
        raise RuntimeError(f"ACE-Step API error on {path}: {body.get('error')}")
    return body.get("data")


def resolve_reference(value):
    """A file path, or 'main_theme' = the approved main-menu track (carries the motif into other cues)."""
    if value is None:
        return None
    if value == "main_theme":
        sheet_path = MUSIC_DIR / "music_cues.json"
        sheet = json.loads(sheet_path.read_text(encoding="utf-8")) if sheet_path.exists() else {}
        variants = sheet.get("music_states", {}).get("main_menu", [])
        if not variants:
            sys.exit("--reference main_theme: no approved main-menu track yet (approve one first)")
        return ROOT / sheet["cues"][variants[0]["cue"]]["stream"].removeprefix("res://")
    path = Path(value).expanduser()
    if not path.is_file():
        sys.exit(f"reference audio not found: {path}")
    return path


def build_request(score, candidate, overrides):
    engine = score["engine"]
    request = {
        "prompt": candidate["caption"],
        "lyrics": engine["lyrics"],
        "vocal_language": engine["vocal_language"],
        "thinking": engine["thinking"],
        "bpm": candidate["bpm"],
        "key_scale": candidate["key_scale"],
        "time_signature": candidate["time_signature"],
        "audio_duration": candidate["duration"],
        "inference_steps": engine["inference_steps"],
        "use_random_seed": False,
        "seed": candidate["seed"],
        "batch_size": 1,
        "audio_format": engine["audio_format"],
        "lm_negative_prompt": engine["lm_negative_prompt"],
        "model": engine["model"],
    }
    request.update(overrides)
    return request


def generate_one(base, score, candidate, overrides, poll_seconds, timeout_seconds, reference=None):
    folder = OUTPUT_DIR / candidate["id"]
    folder.mkdir(parents=True, exist_ok=True)
    request = build_request(score, candidate, overrides)
    started = time.time()
    if reference is not None:
        task = api_multipart(base, "/release_task", request, "reference_audio", reference)
    else:
        task = api(base, "/release_task", request)
    task_id = task["task_id"]
    print(f"[{candidate['id']}] submitted task {task_id}; waiting (first run downloads and loads models)...")
    while True:
        if time.time() - started > timeout_seconds:
            raise TimeoutError(f"{candidate['id']}: no result after {timeout_seconds} s")
        time.sleep(poll_seconds)
        entry = api(base, "/query_result", {"task_id_list": [task_id]})[0]
        if entry["status"] == 2:
            raise RuntimeError(f"{candidate['id']}: ACE-Step reported failure: {entry.get('result')}")
        if entry["status"] == 1:
            break
    results = json.loads(entry["result"]) if isinstance(entry["result"], str) else entry["result"]
    result = results[0]
    raw = folder / f"{candidate['id']}.{request['audio_format']}"
    file_url = result["file"] if result["file"].startswith("http") else base + result["file"]
    urllib.request.urlretrieve(file_url, raw)
    elapsed = round(time.time() - started, 1)

    metrics = measure(raw)  # Raises if the file is not real, decodable audio.
    if metrics["duration_seconds"] < 0.8 * candidate["duration"]:
        metrics["warnings"].append(f"shorter than requested ({candidate['duration']} s)")
    preview = folder / f"{candidate['id']}_preview.ogg"
    encode(raw, preview, loop=False)
    record = {
        "candidate": candidate,
        "request": request,
        "task_id": task_id,
        "reference_audio": None if reference is None else {
            "file": str(reference.relative_to(ROOT)) if reference.is_relative_to(ROOT) else reference.name,
            "sha256": hashlib.sha256(reference.read_bytes()).hexdigest()},
        "returned": {key: result.get(key) for key in ("metas", "seed_value", "lm_model", "dit_model", "generation_info")},
        "acestep_commit": acestep_commit(),
        "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "generation_seconds": elapsed,
        "host": {"machine": os.uname().machine, "system": os.uname().sysname, "release": os.uname().release},
    }
    (folder / "generation.json").write_text(json.dumps(record, indent="\t") + "\n", encoding="utf-8")
    (folder / "qa.json").write_text(json.dumps(metrics, indent="\t") + "\n", encoding="utf-8")
    flag = "; WARNINGS: " + "; ".join(metrics["warnings"]) if metrics["warnings"] else ""
    print(f"[{candidate['id']}] OK {metrics['duration_seconds']:.1f} s, {metrics['integrated_lufs']} LUFS, "
          f"peak {metrics['true_peak_dbtp']} dBTP, {elapsed} s to generate -> {raw.relative_to(ROOT)}{flag}")
    return raw


def acestep_commit():
    repo = ROOT / "tools/music_ai/ACE-Step-1.5"
    out = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], capture_output=True, text=True)
    return out.stdout.strip() or "unknown (ACE-Step not at tools/music_ai/ACE-Step-1.5)"


# --- Import into Godot -----------------------------------------------------------------------

def approve(candidate_id, approved_by, notes):
    folder = OUTPUT_DIR / candidate_id
    if not (folder / "generation.json").exists():
        sys.exit(f"no generated candidate at {folder.relative_to(ROOT)}; run generate first")
    record = json.loads((folder / "generation.json").read_text(encoding="utf-8"))
    candidate = record["candidate"]
    raw = folder / f"{candidate_id}.{record['request']['audio_format']}"
    cue_id = f"mus_ai_{candidate_id}"
    relative = f"audio/music_ai/{candidate['track']}/{cue_id}.ogg"
    target = ROOT / relative
    encode(raw, target, loop=candidate["loop"])
    metrics = measure(target)

    cues_path = MUSIC_DIR / "music_cues.json"
    sheet = json.loads(cues_path.read_text(encoding="utf-8")) if cues_path.exists() else {
        "schema_version": "0.1", "cues": {}, "music_states": {}, "location_music": {}, "events": {}}
    sheet["cues"][cue_id] = {"stream": "res://" + relative, "bus": "Music", "loop": candidate["loop"]}
    variants = [v for v in sheet["music_states"].get(candidate["track"], []) if v["cue"] != cue_id]
    if candidate["track"] == "main_menu":
        variants = []  # Main-menu directions are alternatives: the approved one replaces the others.
    variants.append({"cue": cue_id, "min_intensity": candidate["min_intensity"]})
    sheet["music_states"][candidate["track"]] = sorted(variants, key=lambda v: v["min_intensity"])
    cues_path.parent.mkdir(parents=True, exist_ok=True)
    cues_path.write_text(json.dumps(sheet, indent="\t") + "\n", encoding="utf-8")

    manifest_path = MUSIC_DIR / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {
        "schema_version": "0.1", "assets": []}
    manifest["assets"] = [a for a in manifest["assets"] if a["file"] != relative]
    manifest["assets"].append({
        "file": relative,
        "ids": [cue_id, f"music_state:{candidate['track']}"],
        "category": "music_ai",
        "title": candidate["title"],
        "variant": candidate["variant"],
        "location": candidate["location"],
        "source": f"ACE-Step 1.5 {record['request']['model']} (LM {record['returned'].get('lm_model')}), "
                  f"seed {record['request']['seed']}, {record['request']['inference_steps']} steps, "
                  f"ACE-Step commit {record['acestep_commit']}"
                  + (f", reference audio {record['reference_audio']['file']}" if record.get("reference_audio") else ""),
        "prompt": record["request"]["prompt"],
        "request": record["request"],
        "license": LICENSE_NOTE,
        "duration_seconds": metrics["duration_seconds"],
        "integrated_lufs": metrics["integrated_lufs"],
        "true_peak_dbtp": metrics["true_peak_dbtp"],
        "loop": candidate["loop"],
        "sha256": metrics["sha256"],
        "integration_status": "integrated",
        "review_status": f"approved by {approved_by}",
        "notes": notes,
    })
    manifest["assets"].sort(key=lambda a: a["file"])
    manifest_path.write_text(json.dumps(manifest, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"approved {candidate_id} -> {relative} ({metrics['duration_seconds']:.1f} s, {metrics['integrated_lufs']} LUFS)")
    print("Next: open Godot once so it imports the new file, then run python3 tests/qa/run.py.")


# --- Commands -----------------------------------------------------------------------------------

def command_check(args):
    require_ffmpeg()
    print("ffmpeg/ffprobe: OK")
    try:
        health = api(args.api, "/health", timeout=10)
        print("ACE-Step API:", json.dumps(health))
    except (urllib.error.URLError, OSError) as error:
        sys.exit(f"ACE-Step API not reachable at {args.api} ({error}). Start it with tools/music_ai/start_server.sh")
    try:
        print("Models:", json.dumps(api(args.api, "/v1/models", timeout=10)))
    except Exception as error:  # Older servers may not expose /v1/models.
        print("Model listing unavailable:", error)


def command_list(_args):
    for candidate_id, c in candidates(load_score()).items():
        print(f"{candidate_id:34s} {c['duration']:4d} s  seed {c['seed']}  {'loop' if c['loop'] else 'once'}  {c['title']}")


def command_generate(args):
    require_ffmpeg()
    score = load_score()
    table = candidates(score)
    wanted = FIRST_DELIVERABLE if args.first_deliverable else args.candidates
    if args.all:
        wanted = list(table)
    unknown = [c for c in wanted if c not in table]
    if unknown or not wanted:
        sys.exit("unknown or missing candidate ids: " + ", ".join(unknown) + " (see: generate_music.py list)")
    overrides = json.loads(args.overrides) if args.overrides else {}
    reference = resolve_reference(args.reference)
    failures = 0
    for candidate_id in wanted:
        candidate = dict(table[candidate_id])
        if args.seed_offset:
            candidate["seed"] += args.seed_offset
            candidate["id"] = f"{candidate_id}_s{candidate['seed']}"
        try:
            generate_one(args.api, score, candidate, overrides, args.poll, args.timeout, reference)
        except Exception as error:
            failures += 1
            print(f"[{candidate_id}] FAILED: {error}", file=sys.stderr)
    sys.exit(1 if failures else 0)


def command_qa(args):
    require_ffmpeg()
    print(json.dumps(measure(Path(args.file)), indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--api", default=DEFAULT_API, help=f"ACE-Step API base URL (default {DEFAULT_API})")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("check", help="verify ffmpeg and that the ACE-Step API server is up").set_defaults(func=command_check)
    sub.add_parser("list", help="list candidate ids from score.json").set_defaults(func=command_list)
    gen = sub.add_parser("generate", help="generate candidates")
    gen.add_argument("candidates", nargs="*")
    gen.add_argument("--first-deliverable", action="store_true", help="the three main-menu directions")
    gen.add_argument("--all", action="store_true", help="every candidate in score.json")
    gen.add_argument("--seed-offset", type=int, default=0, help="explore alternates without editing score.json")
    gen.add_argument("--reference", help="reference audio for style/motif: a file path, or 'main_theme' for the approved main-menu track")
    gen.add_argument("--overrides", help='JSON merged into the request, e.g. \'{"inference_steps": 12}\'')
    gen.add_argument("--poll", type=float, default=5.0)
    gen.add_argument("--timeout", type=float, default=3600.0)
    gen.set_defaults(func=command_generate)
    qa = sub.add_parser("qa", help="measure an audio file")
    qa.add_argument("file")
    qa.set_defaults(func=command_qa)
    app = sub.add_parser("approve", help="import a listened-to candidate into Godot")
    app.add_argument("candidate")
    app.add_argument("--approved-by", required=True, help="who listened and approved it")
    app.add_argument("--notes", default="")
    app.set_defaults(func=lambda a: (require_ffmpeg(), approve(a.candidate, a.approved_by, a.notes)))
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
