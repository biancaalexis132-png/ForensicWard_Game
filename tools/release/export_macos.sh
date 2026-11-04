#!/usr/bin/env bash
# Build the standalone macOS app of The Forensic Ward and check that it starts
# without the Godot editor. Run from a fresh clone (never on the SSK drive's
# working copy), for example ~/Developer/forensicward-release:
#
#   tools/release/export_macos.sh                 # export + launch check
#   tools/release/export_macos.sh --no-launch     # export only
#
# Needs Godot 4.7 (GODOT=/path/to/Godot, default /Applications/Godot.app) and its
# 4.7 export templates. If the templates are missing, the script downloads the
# official 4.7-stable template archive (about 1.3 GB) and checks its SHA-512
# against the release's SHA512-SUMS.txt before installing only macos.zip.
#
# Output: build/macos/The Forensic Ward.zip and the unpacked
# build/macos/The Forensic Ward.app, plus build/macos/launch_check.log.
# The app is ad-hoc signed (preset "macOS" in export_presets.cfg). It runs on the
# Mac that built it; giving it to other people needs an Apple Developer ID and
# notarization (see docs/MAC_RELEASE_BUILD.md).
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
LAUNCH=1
[[ "${1:-}" == "--no-launch" ]] && LAUNCH=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
[[ -f project.godot ]] || { echo "Run from the repository (project.godot not found)"; exit 1; }
case "$ROOT" in /Volumes/*) echo "Refusing to build on an external drive working copy: clone into ~/Developer first."; exit 1;; esac

version="$("$GODOT" --version | head -1)"
echo "Godot: $version"
[[ "$version" == 4.7.* ]] || { echo "Godot 4.7 is required"; exit 1; }
# "4.7.2.stable.official.abc123" -> "4.7.2.stable" (the template folder name)
tpl_version="$(echo "$version" | sed -E 's/^([0-9]+(\.[0-9]+)+\.[a-z]+[0-9]*)\..*$/\1/')"
templates="$HOME/Library/Application Support/Godot/export_templates/$tpl_version"
if [[ ! -f "$templates/macos.zip" ]]; then
	# 4.7.2.stable and similar patch releases use their own template folder and tag.
	tag="$(echo "$tpl_version" | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?)\.(stable)$/\1-\3/')"
	base="https://github.com/godotengine/godot-builds/releases/download/$tag"
	tmp="$(mktemp -d)"
	echo "Downloading export templates for $tag (about 1.3 GB) ..."
	curl --fail --location --retry 3 -o "$tmp/SHA512-SUMS.txt" "$base/SHA512-SUMS.txt"
	name="Godot_v${tag}_export_templates.tpz"
	curl --fail --location --retry 3 -o "$tmp/$name" "$base/$name"
	(cd "$tmp" && grep " $name\$" SHA512-SUMS.txt | shasum -a 512 -c -)
	mkdir -p "$templates"
	unzip -oqj "$tmp/$name" templates/macos.zip templates/version.txt -d "$templates"
	rm -rf "$tmp"
fi

echo "Importing assets ..."
"$GODOT" --headless --path . --editor --import > build_import.log 2>&1 || true
mkdir -p build/macos
rm -rf "build/macos/The Forensic Ward.zip" "build/macos/The Forensic Ward.app"
echo "Exporting ..."
"$GODOT" --headless --path . --export-release "macOS" "build/macos/The Forensic Ward.zip"
(cd build/macos && ditto -x -k "The Forensic Ward.zip" .)
app="build/macos/The Forensic Ward.app"
codesign --verify --deep "$app" && echo "Signature: valid (ad-hoc)"
du -sh "$app"

if [[ "$LAUNCH" == 1 ]]; then
	echo "Launch check: the app starts on its own pack, then quits after 600 frames ..."
	"$app/Contents/MacOS/The Forensic Ward" --quit-after 600 > build/macos/launch_check.log 2>&1 || true
	if grep -q "Boot OK (content valid)" build/macos/launch_check.log; then
		echo "LAUNCH_CHECK PASS: content valid at boot (log: build/macos/launch_check.log)"
	else
		echo "LAUNCH_CHECK FAIL: see build/macos/launch_check.log"; exit 1
	fi
	grep -E "^(ERROR|SCRIPT ERROR)" build/macos/launch_check.log | grep -v "Attempt to disconnect a nonexistent connection" | sort | uniq -c || true
fi
echo "Done. Open the app from Finder: build/macos/The Forensic Ward.app"
