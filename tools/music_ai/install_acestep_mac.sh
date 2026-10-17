#!/usr/bin/env bash
# Installs ACE-Step 1.5 for The Forensic Ward on an Apple Silicon Mac and
# downloads/verifies the model weights. Safe to re-run.
#   bash tools/music_ai/install_acestep_mac.sh            # pinned, tested commit
#   ACESTEP_REF=main bash tools/music_ai/install_acestep_mac.sh   # latest upstream
# Everything lands in tools/music_ai/ACE-Step-1.5/ (ignored by Git).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACE_DIR="$HERE/ACE-Step-1.5"
REF="${ACESTEP_REF:-ca1e85fe9430179831e6bc6be790c332190a3866}"
LM_MODEL="${LM_MODEL:-acestep-5Hz-lm-1.7B}"

[[ "$(uname)" == "Darwin" && "$(uname -m)" == "arm64" ]] || { echo "This installer is for Apple Silicon Macs."; exit 1; }
command -v git >/dev/null || { echo "Install the Xcode command line tools first: xcode-select --install"; exit 1; }
command -v ffmpeg >/dev/null || echo "NOTE: ffmpeg is missing; install it before generating: brew install ffmpeg"

if [[ ! -d "$ACE_DIR/.git" ]]; then
  echo "== Cloning ACE-Step 1.5"
  git clone https://github.com/ACE-Step/ACE-Step-1.5.git "$ACE_DIR"
fi
echo "== Checking out $REF"
git -C "$ACE_DIR" fetch --quiet origin
# -f drops the two launcher edits start_server.sh makes; it re-applies them.
git -C "$ACE_DIR" checkout --quiet -f "$REF"
chmod +x "$ACE_DIR"/start_gradio_ui_macos.sh "$ACE_DIR"/start_api_server_macos.sh

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
if ! command -v uv >/dev/null; then
  read -rp "uv (Python package manager) is required. Install it now from astral.sh? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Install uv yourself: brew install uv"; exit 1; }
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "== Building the Python environment (first run: several minutes)"
(cd "$ACE_DIR" && uv sync)
(cd "$ACE_DIR" && uv run python -c "import mlx.core as mx; print('MLX OK, default device:', mx.default_device())")

echo "== Downloading model weights (main model: turbo DiT, VAE, text encoder, default LM)"
echo "   Source is chosen automatically (Hugging Face, falling back to ModelScope)."
(cd "$ACE_DIR" && uv run acestep-download)
if [[ "$LM_MODEL" != "acestep-5Hz-lm-1.7B" ]]; then
  (cd "$ACE_DIR" && uv run acestep-download --model "$LM_MODEL")
fi

echo "== Verifying downloaded weights"
ckpt="${ACESTEP_CHECKPOINTS_DIR:-$ACE_DIR/checkpoints}"
missing=0
for model in acestep-v15-turbo vae Qwen3-Embedding-0.6B "$LM_MODEL"; do
  files=$(find "$ckpt/$model" \( -name '*.safetensors' -o -name '*.bin' \) 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$files" -gt 0 ]]; then
    echo "  OK  $model: $files weight file(s), $(du -sh "$ckpt/$model" | cut -f1)"
    # A truncated download usually fails to parse; read each safetensors header.
    (cd "$ACE_DIR" && uv run python - "$ckpt/$model" <<'PY')
import sys, pathlib
from safetensors import safe_open
for f in pathlib.Path(sys.argv[1]).rglob("*.safetensors"):
    with safe_open(str(f), framework="numpy") as handle:
        assert len(list(handle.keys())) > 0, f
print("      safetensors headers readable")
PY
  else
    echo "  MISSING  $model"; missing=1
  fi
done
(( missing == 0 )) || { echo "Some weights are missing. See docs/MUSIC_AI_MAC_GUIDE.md, 'Troubleshooting'."; exit 1; }
echo
echo "Installed. Next:"
echo "  bash tools/music_ai/start_server.sh        # terminal 1"
echo "  python3 tools/music_ai/generate_music.py check"
echo "  python3 tools/music_ai/generate_music.py generate --first-deliverable"
