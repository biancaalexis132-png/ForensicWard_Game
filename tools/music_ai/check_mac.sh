#!/usr/bin/env bash
# Reports whether this Mac can run ACE-Step 1.5 (MLX) and the audio tools.
# Read-only: installs nothing. Run from the repository root:
#   bash tools/music_ai/check_mac.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACE_DIR="$HERE/ACE-Step-1.5"
status=0
ok()   { printf '  [ OK ] %s\n' "$*"; }
warn() { printf '  [WARN] %s\n' "$*"; }
fail() { printf '  [FAIL] %s\n' "$*"; status=1; }

echo "== Hardware and OS"
if [[ "$(uname)" != "Darwin" ]]; then
  fail "Not macOS ($(uname)). These steps are for an Apple Silicon Mac."
else
  chip="$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
  ram_gb=$(( $(sysctl -n hw.memsize) / 1073741824 ))
  echo "  $(sw_vers -productName) $(sw_vers -productVersion), $chip, ${ram_gb} GB unified memory"
  [[ "$(uname -m)" == "arm64" ]] && ok "Apple Silicon (arm64): MLX backend available" || fail "Intel Mac: MLX needs Apple Silicon; ACE-Step would fall back to slow CPU PyTorch"
  if (( ram_gb >= 32 )); then ok "Memory: comfortable for turbo DiT + 1.7B LM (XL models possible)"
  elif (( ram_gb >= 16 )); then ok "Memory: turbo DiT + 1.7B LM should fit; close other apps while generating"
  else warn "Memory under 16 GB: use the 0.6B LM (LM_MODEL_PATH=acestep-5Hz-lm-0.6B) or thinking=false"; fi
  case "$(sw_vers -productVersion)" in 1[4-9].*|2*) ok "macOS 14 or newer";; *) warn "macOS older than 14: MLX wheels may not install";; esac
fi
free_gb=$(df -k "$HERE" | awk 'NR==2 {print int($4 / 1048576)}')
(( free_gb >= 30 )) && ok "Disk: ${free_gb} GB free" || warn "Disk: ${free_gb} GB free; keep at least 30 GB for models, environment and outputs"

echo "== Tools"
for tool in git python3 ffmpeg ffprobe; do
  command -v "$tool" >/dev/null && ok "$tool: $(command -v "$tool")" || fail "$tool missing (brew install ${tool/ffprobe/ffmpeg})"
done
if command -v uv >/dev/null || [[ -x "$HOME/.local/bin/uv" ]]; then ok "uv installed"; else warn "uv missing: install_acestep_mac.sh will offer to install it"; fi
command -v git-lfs >/dev/null && ok "git-lfs installed" || warn "git-lfs missing (brew install git-lfs && git lfs install); needed to commit approved music"
xcode-select -p >/dev/null 2>&1 && ok "Xcode command line tools" || warn "Xcode command line tools missing (xcode-select --install)"

echo "== Network (model downloads)"
for url in https://huggingface.co https://modelscope.cn https://github.com; do
  code=$(curl -s -o /dev/null -m 15 -w '%{http_code}' -I "$url")
  [[ "$code" =~ ^[23] ]] && ok "$url reachable ($code)" || warn "$url not reachable (HTTP $code)"
done

echo "== ACE-Step installation"
if [[ -d "$ACE_DIR/.git" ]]; then
  ok "repository at tools/music_ai/ACE-Step-1.5 ($(git -C "$ACE_DIR" rev-parse --short HEAD))"
  [[ -d "$ACE_DIR/.venv" || -d "$ACE_DIR/python_embedded" ]] && ok "Python environment present" || warn "environment not built yet (run install_acestep_mac.sh)"
  ckpt="${ACESTEP_CHECKPOINTS_DIR:-$ACE_DIR/checkpoints}"
  for model in acestep-v15-turbo vae Qwen3-Embedding-0.6B acestep-5Hz-lm-1.7B; do
    if [[ -d "$ckpt/$model" ]] && [[ -n "$(find "$ckpt/$model" -name '*.safetensors' -o -name '*.bin' 2>/dev/null | head -1)" ]]; then
      ok "model $model ($(du -sh "$ckpt/$model" | cut -f1))"
    else warn "model $model not downloaded"; fi
  done
else
  warn "ACE-Step not installed yet (run: bash tools/music_ai/install_acestep_mac.sh)"
fi

echo "== API server"
if curl -s -m 5 "${ACESTEP_API_URL:-http://127.0.0.1:8001}/health" | grep -q '"ok"'; then ok "API server responding"; else warn "API server not running (bash tools/music_ai/start_server.sh)"; fi
exit $status
