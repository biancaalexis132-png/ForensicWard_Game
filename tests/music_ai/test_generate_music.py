"""Pipeline test for tools/music_ai/generate_music.py against a MOCK ACE-Step server.

The mock serves an existing procedural file, so this proves the client's
submit/poll/download/verify/normalize/loop/import path, not ACE-Step itself
or music quality. Skipped when ffmpeg is unavailable.
"""
import http.server
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import threading
import unittest

REPO = Path(__file__).resolve().parents[2]
SOURCE = REPO / "audio/music/mus_transition_unease_01.ogg"


class MockAceStep(http.server.BaseHTTPRequestHandler):
    wav = None
    requests = []
    uploads = []

    def log_message(self, *args):
        pass

    def reply(self, data):
        body = json.dumps({"data": data, "code": 200, "error": None}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            return self.reply({"status": "ok", "service": "mock"})
        if self.path.startswith("/v1/audio"):
            self.send_response(200)
            self.end_headers()
            return self.wfile.write(self.wav.read_bytes())
        self.send_error(404)

    def do_POST(self):
        body = self.rfile.read(int(self.headers["Content-Length"]))
        if self.headers["Content-Type"].startswith("multipart/form-data"):
            MockAceStep.uploads.append(body)
            payload = {}
        else:
            payload = json.loads(body)
        if self.path == "/release_task":
            MockAceStep.requests.append(payload)
            return self.reply({"task_id": "t1", "status": "queued"})
        if self.path == "/query_result":
            result = [{"file": "/v1/audio?path=x.wav", "status": 1, "metas": {"bpm": 66},
                       "seed_value": "41011", "lm_model": "mock-lm", "dit_model": "mock-dit"}]
            return self.reply([{"task_id": "t1", "status": 1, "result": json.dumps(result)}])
        self.send_error(404)


@unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "ffmpeg not installed")
class GenerateMusicPipelineTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="fw-music-"))
        (self.root / "tools/music_ai").mkdir(parents=True)
        shutil.copy(REPO / "tools/music_ai/score.json", self.root / "tools/music_ai/score.json")
        MockAceStep.wav = self.root / "mock.wav"
        # 30 s stand-in: the 9.5 s procedural transition repeated (main menu asks for 90 s).
        subprocess.run(["ffmpeg", "-v", "error", "-stream_loop", "3", "-i", str(SOURCE), "-t", "30",
                        str(MockAceStep.wav)], check=True)
        MockAceStep.requests = []
        MockAceStep.uploads = []
        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), MockAceStep)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.api = f"http://127.0.0.1:{self.server.server_port}"

    def tearDown(self):
        self.server.shutdown()
        shutil.rmtree(self.root)

    def run_tool(self, *args):
        env = dict(os.environ, FW_ROOT=str(self.root))
        return subprocess.run([sys.executable, str(REPO / "tools/music_ai/generate_music.py"), "--api", self.api, *args],
                              env=env, capture_output=True, text=True)

    def test_generate_verify_and_approve(self):
        result = self.run_tool("generate", "main_menu_b_strings", "--poll", "0.05")
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        request = MockAceStep.requests[0]
        self.assertEqual(request["lyrics"], "[Instrumental]")
        self.assertEqual(request["seed"], 41023)
        self.assertFalse(request["use_random_seed"])
        self.assertIn("Direction B", request["prompt"])
        folder = self.root / "tools/music_ai/output/main_menu_b_strings"
        qa = json.loads((folder / "qa.json").read_text())
        self.assertAlmostEqual(qa["duration_seconds"], 30.0, delta=0.1)
        self.assertIn("shorter than requested (90 s)", qa["warnings"])
        self.assertTrue((folder / "main_menu_b_strings_preview.ogg").exists())

        result = self.run_tool("approve", "main_menu_b_strings", "--approved-by", "QA mock")
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        cues = json.loads((self.root / "audio/music_ai/music_cues.json").read_text())
        self.assertEqual(cues["music_states"]["main_menu"], [{"cue": "mus_ai_main_menu_b_strings", "min_intensity": 0.0}])
        manifest = json.loads((self.root / "audio/music_ai/manifest.json").read_text())
        asset = manifest["assets"][0]
        self.assertAlmostEqual(asset["duration_seconds"], 30.0 - 4.0, delta=0.15)  # Loop seam overlap.
        self.assertLess(asset["true_peak_dbtp"], -1.0)
        self.assertAlmostEqual(asset["integrated_lufs"], -20.0, delta=1.5)

    def test_reference_audio_uses_approved_main_theme(self):
        result = self.run_tool("generate", "after_hours_calm", "--reference", "main_theme")
        self.assertNotEqual(result.returncode, 0, "must refuse before a main theme is approved")
        self.assertIn("no approved main-menu track", result.stderr + result.stdout)
        for args in (("generate", "main_menu_a_piano", "--poll", "0.05"),
                     ("approve", "main_menu_a_piano", "--approved-by", "QA mock"),
                     ("generate", "after_hours_calm", "--reference", "main_theme", "--poll", "0.05")):
            result = self.run_tool(*args)
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        body = MockAceStep.uploads[0]
        self.assertIn(b'name="reference_audio"; filename="mus_ai_main_menu_a_piano.ogg"', body)
        self.assertIn(b'name="seed"\r\n\r\n46011\r\n', body)
        self.assertIn(b'name="use_random_seed"\r\n\r\nfalse\r\n', body)
        self.assertIn(b'name="lyrics"\r\n\r\n[Instrumental]\r\n', body)
        record = json.loads((self.root / "tools/music_ai/output/after_hours_calm/generation.json").read_text())
        self.assertEqual(record["reference_audio"]["file"], "audio/music_ai/main_menu/mus_ai_main_menu_a_piano.ogg")

    def test_failed_task_is_reported(self):
        result = self.run_tool("generate", "unknown_candidate")
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
