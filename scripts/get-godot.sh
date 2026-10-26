#!/usr/bin/env bash
# Download the pinned Godot 4.7.2 Linux editor binary, check it against its pinned SHA-256 and make it
# runnable. It is the one place CI gets Godot: .github/workflows/game.yml and builds.yml both run it
# (each had its own copy of these lines before; CI audit finding CI-4).
# Usage: scripts/get-godot.sh DIR
#   DIR  where the zip is unpacked; the binary lands at DIR/Godot_v4.7.2-stable_linux.x86_64
# Output: the binary's path on stdout's last line, after Godot's own --version line. When GITHUB_ENV is
# set (inside a GitHub Actions step) it also appends GODOT_BIN=<path> to it, so later steps, and
# scripts/check-game.sh and export-game.sh, use this binary.
# Exit status: non-zero when the download fails, the checksum differs or the binary does not start.
# Linux x86_64 only: it is the build the runners (ubuntu-24.04) can run. On a Mac, install Godot 4.7.2
# yourself and set GODOT_BIN (see the development docs).
# Export templates are a separate, larger download: scripts/get-export-templates.sh.
set -euo pipefail

dir="${1:?usage: scripts/get-godot.sh DIR}"
root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/godot-helpers.sh
source "$root/scripts/godot-helpers.sh"

# The 4.7.2-stable release asset and the SHA-256 CI has pinned for it since the project moved to 4.7.2.
# A changed or truncated download fails the check instead of running unknown code.
url="https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip"
sha256="cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"

mkdir -p "$dir"
dir="$(cd "$dir" && pwd)"
curl --fail --location --retry 3 --silent --show-error "$url" -o "$dir/godot.zip"
printf '%s  %s\n' "$sha256" "$dir/godot.zip" | sha256_check
unzip -q -o "$dir/godot.zip" -d "$dir"
rm -f "$dir/godot.zip"
godot_bin="$dir/Godot_v4.7.2-stable_linux.x86_64"
chmod +x "$godot_bin"
"$godot_bin" --version
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "GODOT_BIN=$godot_bin" >> "$GITHUB_ENV"
fi
echo "$godot_bin"
