#!/usr/bin/env bash
# Run the Godot import and every headless suite with an isolated user data directory.
# Usage: scripts/check-game.sh   (GODOT_BIN overrides the godot binary)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
godot="${GODOT_BIN:-godot}"
work="$(mktemp -d)"
logs="${CHECK_LOG_DIR:-$work/logs}"
mkdir -p "$logs" "$work/home"
trap 'rm -rf "$work/home"' EXIT
# Godot resolves user:// from HOME on macOS and XDG_DATA_HOME on Linux; isolate both so
# checks never touch real saves or editor settings.
export HOME="$work/home" XDG_DATA_HOME="$work/home/.local/share" XDG_CONFIG_HOME="$work/home/.config"

cd "$root"
before="$(git status --porcelain -- apps/game)"

# The in-game changelog is generated from the public changelog; the committed export must match.
python3 scripts/export_changelog.py --output "$work/changelog.txt"
if ! cmp -s "$work/changelog.txt" apps/game/assets/changelog.txt; then
  echo "apps/game/assets/changelog.txt is out of date: run python3 scripts/export_changelog.py and commit the result" >&2
  exit 1
fi

# A fresh checkout's first import loads the project theme before its fonts exist; the second must be clean.
"$godot" --headless --path apps/game --import > "$logs/import-first.log" 2>&1 || true
"$godot" --headless --path apps/game --import > "$logs/import.log" 2>&1
if grep -qE '^ERROR:|SCRIPT ERROR|Parse Error' "$logs/import.log"; then
  echo "Second import reported errors (see $logs/import.log)" >&2
  exit 1
fi

status=0
# A suite also fails if it leaks objects at exit, so a leak in the game's own nodes or audio shows up.
for test in apps/game/tests/*_test.gd; do
  name="$(basename "$test" .gd)"
  if "$godot" --headless --path apps/game --script "res://tests/$name.gd" > "$logs/$name.log" 2>&1 \
    && ! grep -qE '^ERROR:|SCRIPT ERROR|Parse Error|instances were leaked at exit' "$logs/$name.log"; then
    echo "pass  $name"
  else
    echo "FAIL  $name (see $logs/$name.log)" >&2
    status=1
  fi
done

if [ "$(git status --porcelain -- apps/game)" != "$before" ]; then
  echo "Checks changed files under apps/game:" >&2
  git status --porcelain -- apps/game >&2
  status=1
fi
exit "$status"
