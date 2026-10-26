#!/usr/bin/env bash
# Run the Godot import and every headless suite, each suite with its own temporary user data folder.
# Usage: scripts/check-game.sh
#   GODOT_BIN      the godot binary (default: godot on PATH)
#   CHECK_JOBS     how many suites run at once (default: the CPU count, at most 4; 1 runs them in turn)
#   SUITE_TIMEOUT  seconds a suite or an import pass may take before it counts as hung (default: 240)
#   CHECK_LOG_DIR  where logs go (CI keeps them); without it they are kept only when a check fails
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/godot-helpers.sh
source "$root/scripts/godot-helpers.sh"
godot="${GODOT_BIN:-godot}"
limit="${SUITE_TIMEOUT:-240}"

# Internal: `check-game.sh --suite NAME LOG_DIR WORK_DIR` runs one suite and writes NAME.result.
if [ "${1:-}" = "--suite" ]; then
  name="$2" logs="$3" work="$4" rc=0 started="$SECONDS"
  isolate_godot_home "$work/home-$name"
  cd "$root"
  # --language en pins every suite to English whatever the OS locale is: the suites assert English, and
  # I18n.saved() follows the start-up locale when nothing is saved (tests/i18n_test.gd checks the pin).
  bounded "$limit" "$godot" --headless --language en --path apps/game --script "res://tests/$name.gd" > "$logs/$name.log" 2>&1 || rc=$?
  if [ "$rc" -eq 124 ]; then
    echo "FAIL  $name (hung: still running after ${limit}s and was stopped; see $logs/$name.log)" > "$logs/$name.result"
  elif [ "$rc" -ne 0 ] || grep -qE "$godot_error_lines" "$logs/$name.log"; then
    echo "FAIL  $name (see $logs/$name.log)" > "$logs/$name.result"
  elif grep -q 'instances were leaked at exit' "$logs/$name.log"; then
    # A suite also fails if it leaks objects at exit, so a leak in the game's own nodes or audio shows up.
    # Run it once more with --verbose so the log names the leaked objects; the suite still fails.
    bounded "$limit" "$godot" --headless --verbose --language en --path apps/game --script "res://tests/$name.gd" > "$logs/$name.verbose.log" 2>&1 || true
    echo "FAIL  $name (leaked objects at exit; see $logs/$name.log, and $logs/$name.verbose.log for their names)" > "$logs/$name.result"
  else
    echo "pass  $name ($((SECONDS - started))s)" > "$logs/$name.result"
  fi
  rm -rf "$work/home-$name"
  exit 0
fi

work="$(mktemp -d)"
logs="${CHECK_LOG_DIR:-$work/logs}"
mkdir -p "$logs"
keep_work=0
cleanup() {
  if [ "$keep_work" -eq 1 ] && [ -z "${CHECK_LOG_DIR:-}" ]; then
    echo "Logs kept in $logs" >&2
    find "$work" -mindepth 1 -maxdepth 1 ! -name logs -exec rm -rf {} +
  else
    rm -rf "$work"
  fi
}
trap cleanup EXIT
isolate_godot_home "$work/home"

cd "$root"
before="$(git status --porcelain -- apps/game)"

# The in-game changelog is generated from the public changelog; the committed export must match.
python3 scripts/export_changelog.py --output "$work/changelog.txt"
if ! cmp -s "$work/changelog.txt" apps/game/assets/changelog.txt; then
  echo "apps/game/assets/changelog.txt is out of date: run python3 scripts/export_changelog.py and commit the result" >&2
  exit 1
fi

if ! import_game "$godot" "$logs" "$limit"; then
  keep_work=1
  exit 1
fi

cpus="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
jobs="${CHECK_JOBS:-$((cpus < 4 ? cpus : 4))}"
# The slowest suites start first, so none is left running alone at the end while the other slots sit
# idle (longest first; alphabetical order put text_boxes_test last and made a 404 s run on CI). Keep it
# to the slow ones, slowest first, and re-measure when a suite grows: the "pass NAME (Ns)" lines below.
# Seconds per suite on CI (ubuntu-24.04, 4 at a time), run 40141935412 (2026-10-24): 235 s of suites
# in all, against 404 s in run 39370708132 before this order and the text-box split.
heavy_suites=(
  full_slice_test             # 127 on a Mac (added after that CI run): plays the whole slice in game time
  companion_rules_test        # 87
  wolf_space_test             # 86
  sentry_test                 # 84
  approved_wording_test       # 82
  follow_spacing_test         # 74
  m0_scene_test               # 72
  junction_test               # 47
  text_boxes_languages_1_test # 45
  text_boxes_languages_2_test # 45
  opening_timing_test         # 39
  debug_tools_test            # 33
  i18n_test                   # 32
  text_boxes_test             # 16
)
suites=()
for name in "${heavy_suites[@]}"; do
  if [ ! -f "apps/game/tests/$name.gd" ]; then
    echo "scripts/check-game.sh lists $name first, but apps/game/tests/$name.gd does not exist: update heavy_suites" >&2
    exit 1
  fi
  suites+=("$name")
done
# Then every other suite, alphabetically (the glob's order).
for test in apps/game/tests/*_test.gd; do
  name="$(basename "$test" .gd)"
  if [[ " ${heavy_suites[*]} " != *" $name "* ]]; then
    suites+=("$name")
  fi
done
started="$SECONDS"
printf '%s\n' "${suites[@]}" | xargs -P "$jobs" -I{} "$root/scripts/check-game.sh" --suite {} "$logs" "$work"

status=0
for name in "${suites[@]}"; do
  if [ ! -f "$logs/$name.result" ]; then
    echo "FAIL  $name (did not report a result; see $logs/$name.log)" >&2
    status=1
  elif grep -q '^pass' "$logs/$name.result"; then
    cat "$logs/$name.result"
  else
    cat "$logs/$name.result" >&2
    status=1
  fi
done
echo "${#suites[@]} suites in $((SECONDS - started))s, $jobs at a time"

if [ "$(git status --porcelain -- apps/game)" != "$before" ]; then
  echo "Checks changed files under apps/game:" >&2
  git status --porcelain -- apps/game >&2
  status=1
fi
[ "$status" -eq 0 ] || keep_work=1
exit "$status"
