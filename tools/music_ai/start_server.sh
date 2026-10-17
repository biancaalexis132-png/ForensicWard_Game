#!/usr/bin/env bash
# Starts ACE-Step's own macOS (MLX) REST API server on http://127.0.0.1:8001.
# Leave this terminal open while generate_music.py runs in another one.
# LM_MODEL_PATH=acestep-5Hz-lm-0.6B bash tools/music_ai/start_server.sh   # for 8-16 GB Macs
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACE_DIR="$HERE/ACE-Step-1.5"
[[ -x "$ACE_DIR/start_api_server_macos.sh" ]] || { echo "Run tools/music_ai/install_acestep_mac.sh first."; exit 1; }
cd "$ACE_DIR"
if [[ -n "${LM_MODEL_PATH:-}" ]]; then
  sed -i '' "s/^LM_MODEL_PATH=\"[^\"]*\"/LM_MODEL_PATH=\"$LM_MODEL_PATH\"/" start_api_server_macos.sh
fi
# Skip the interactive update prompt so the pinned commit stays pinned.
sed -i '' 's/^CHECK_UPDATE="true"/CHECK_UPDATE="false"/' start_api_server_macos.sh
exec ./start_api_server_macos.sh
