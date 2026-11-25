#!/usr/bin/env bash
# Import the game and boot its configured main scene without opening a window.
# Usage: scripts/check-game.sh
# GODOT_BIN selects the executable, SUITE_TIMEOUT bounds each command in seconds,
# and CHECK_LOG_DIR preserves the diagnostics outside the temporary work directory.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/godot-helpers.sh
source "$root/scripts/godot-helpers.sh"
cd "$root"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
logs="${CHECK_LOG_DIR:-$work/logs}"
mkdir -p "$logs"
godot="${GODOT_BIN:-godot}"
limit="${SUITE_TIMEOUT:-120}"
isolate_godot_home "$work/home"

python3 scripts/export_changelog.py --output "$work/changelog.txt"
if ! cmp -s "$work/changelog.txt" apps/game/assets/changelog.txt; then
  echo "Regenerate the changelog with python3 scripts/export_changelog.py" >&2
  exit 1
fi
import_game "$godot" "$logs" "$limit"
if ! bounded "$limit" "$godot" --headless --path apps/game --quit-after 3 > "$logs/boot.log" 2>&1 ||
   grep -qE "$godot_error_lines|instances were leaked at exit" "$logs/boot.log"; then
  cat "$logs/boot.log" >&2
  echo "Game startup failed. Check the configured main scene." >&2
  exit 1
fi
echo "Passed headless import, startup and changelog checks."
