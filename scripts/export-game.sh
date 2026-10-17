#!/usr/bin/env bash
# Export the macOS and Windows debug test builds and package each as one zip with its licence notices.
# Usage: scripts/export-game.sh OUTPUT_DIR
#   GODOT_BIN     the godot binary (default: godot on PATH); must be 4.7.2 to match the templates
#   GODOT_HOME    the isolated Godot data home holding the export templates; it is filled with
#                 scripts/get-export-templates.sh when they are missing (default: a temporary folder)
#   BUILD_COMMIT  the commit named in the zips (default: the checked-out commit)
#   EXPORT_TIMEOUT seconds an import pass or an export may take (default: 600)
# Writes wolf-override-macos-debug-<commit>.zip and wolf-override-windows-debug-<commit>.zip, plus the
# Godot logs under OUTPUT_DIR/logs/.
set -euo pipefail

out="${1:?usage: scripts/export-game.sh OUTPUT_DIR}"
root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/godot-helpers.sh
source "$root/scripts/godot-helpers.sh"
godot="${GODOT_BIN:-godot}"
limit="${EXPORT_TIMEOUT:-600}"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
logs="$out/logs"
mkdir -p "$logs"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cd "$root"
commit="${BUILD_COMMIT:-$(git rev-parse HEAD)}"
short="${commit:0:7}"
godot_home="${GODOT_HOME:-$work/godot-home}"
"$root/scripts/get-export-templates.sh" "$godot_home"
verify_export_templates "$(godot_template_dir "$godot_home")"
isolate_godot_home "$godot_home"

# Licence notices shipped beside each build: Godot's own (pinned to the 4.7.2 tag) and the two OFL texts.
notices="$work/notices"
mkdir -p "$notices"
curl --fail --location --retry 3 --silent --show-error \
  https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt -o "$notices/GODOT_LICENSE.txt"
curl --fail --location --retry 3 --silent --show-error \
  https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/COPYRIGHT.txt -o "$notices/GODOT_COPYRIGHT.txt"
(cd "$notices" && sha256_check <<'SUMS'
b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80  GODOT_LICENSE.txt
cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d  GODOT_COPYRIGHT.txt
SUMS
)
cp apps/game/assets/fonts/Roboto-OFL.txt apps/game/assets/fonts/Montserrat-OFL.txt "$notices/"

import_game "$godot" "$logs" "$limit"

# Godot prints this, as a plain line rather than a WARNING, when an export needs ICU line-breaking data
# (a Chinese, Japanese, Korean or Thai translation is registered) and the templates lack
# icudt_godot.dat: it then packs the editor's own copy, which may not match the template's ICU version.
icu_fallback='Using editor embedded text server data'

# export_preset PRESET PATH LOG: a debug export that must finish cleanly. Godot exits 0 even when an
# export "completed with warnings" (a failed macOS signature is only a warning), so the log decides; the
# ICU fallback above fails it too.
export_preset() {
  local rc=0
  bounded "$limit" "$godot" --headless --path apps/game --export-debug "$1" "$2" > "$3" 2>&1 || rc=$?
  if [ "$rc" -eq 124 ]; then
    echo "The $1 export did not finish within ${limit}s (see $3)" >&2
    return 1
  fi
  if [ "$rc" -ne 0 ] || grep -qE "$godot_error_lines|completed with warnings|^WARNING:|$icu_fallback" "$3"; then
    echo "The $1 export failed or reported problems (see $3):" >&2
    grep -E "$godot_error_lines|completed with warnings|^WARNING:|$icu_fallback" "$3" >&2 || true
    return 1
  fi
}

mkdir -p "$work/macos" "$work/windows"
export_preset "macOS" "$work/macos/WOLF-OVERRIDE.zip" "$logs/export-macos.log"
export_preset "Windows Desktop" "$work/windows/WOLF-OVERRIDE.exe" "$logs/export-windows.log"

python3 -I "$root/scripts/package_test_build.py" macos "$work/macos/WOLF-OVERRIDE.zip" \
  "$out/wolf-override-macos-debug-$short.zip" "$notices" "$commit"
python3 -I "$root/scripts/package_test_build.py" windows "$work/windows/WOLF-OVERRIDE.exe" \
  "$out/wolf-override-windows-debug-$short.zip" "$notices" "$commit"
ls -l "$out"/wolf-override-*-debug-"$short".zip
