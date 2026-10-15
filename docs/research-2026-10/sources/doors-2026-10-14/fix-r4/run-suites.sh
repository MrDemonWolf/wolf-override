#!/usr/bin/env bash
# Fix round 4 (copied from fix-r3): import twice, then every suite with its own isolated HOME (scripts/check-game.sh's rules,
# minus the changelog export step: apps/docs is not exported). usage: run-suites.sh ROOT TAG [suite...]
set -uo pipefail
F=doors-r1/fix-r4
root="$1"; tag="$2"; shift 2
logs="$F/checks/$tag"
rm -rf "$logs" && mkdir -p "$logs"
source "$root/scripts/godot-helpers.sh"
export HOME_BASE="$F/homes/$tag"
mkdir -p "$HOME_BASE"
( isolate_godot_home "$HOME_BASE/import"; cd "$root"; import_game godot "$logs" 300 ) || { echo "IMPORT FAILED"; exit 1; }
echo "import ok"
run_suite() {
  name="$1"; started=$SECONDS
  ( isolate_godot_home "$HOME_BASE/$name"; cd "$root"
    bounded 300 godot --headless --path apps/game --script "res://tests/$name.gd" > "$logs/$name.log" 2>&1; echo $? > "$logs/$name.rc" )
  rc=$(cat "$logs/$name.rc")
  if [ "$rc" -ne 0 ] || grep -qE "$godot_error_lines" "$logs/$name.log"; then r="FAIL"; elif grep -q 'instances were leaked at exit' "$logs/$name.log"; then r="FAIL(leak)"; else r="pass"; fi
  echo "$r  $name ($((SECONDS-started))s rc=$rc)" > "$logs/$name.result"
}
export -f run_suite isolate_godot_home bounded
export logs root godot_error_lines
if [ $# -gt 0 ]; then printf '%s\n' "$@"; else ls "$root"/apps/game/tests/*_test.gd | xargs -n1 basename | sed 's/\.gd$//'; fi | xargs -P 4 -I{} bash -c 'run_suite {}'
cat "$logs"/*.result | sort -k2 > "$logs/SUMMARY.txt"
cat "$logs/SUMMARY.txt"
