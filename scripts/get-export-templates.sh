#!/usr/bin/env bash
# Install the parts of the Godot 4.7.2 export templates that the macOS and Windows debug presets use
# into an isolated Godot data home, checking every file against pinned checksums.
# Usage: scripts/get-export-templates.sh GODOT_HOME
# The full template archive is about 1.28 GB; only four files from it (about 227 MB) are kept.
set -euo pipefail

home="${1:?usage: scripts/get-export-templates.sh GODOT_HOME}"
root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/godot-helpers.sh
source "$root/scripts/godot-helpers.sh"
dest="$(godot_template_dir "$home")"

if verify_export_templates "$dest" 2>/dev/null; then
  echo "Export templates already installed in $dest"
  exit 0
fi

url="https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
sha512="ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079"
download="$(mktemp -d)"
trap 'rm -rf "$download"' EXIT
curl --fail --location --retry 3 --silent --show-error "$url" -o "$download/templates.tpz"
printf '%s  %s\n' "$sha512" "$download/templates.tpz" | sha512_check
mkdir -p "$dest"
unzip -q -o -j "$download/templates.tpz" \
  templates/macos.zip templates/windows_debug_x86_64.exe templates/windows_debug_x86_64_console.exe templates/version.txt \
  -d "$dest"
verify_export_templates "$dest"
echo "Export templates installed in $dest"
