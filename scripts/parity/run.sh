#!/usr/bin/env bash
# Parity and performance runs for the behaviour-identical refactor steps of the lighter-game plan
# (1cf8d73:docs/research-2026-10/lighter-game/PLAN.md). Nothing here ships and no window opens on this
# machine: rendered captures run through tools/render/render.sh (Godot in a container with a virtual
# screen), and the UI dump and the performance probe run with godot --headless on a scratch copy.
#
# Usage:
#   scripts/parity/run.sh capture [--language <code>] <out dir> [routes] [sizes] [variants]
#       Plays each route at each window size in each variant inside the render container and writes
#       stills, shots.json, text.log and audio.log to <out dir>/<route>/<variant>/<size>/.
#       --language plays the routes in that language (any code of apps/game/i18n/languages.json, or
#       "pseudo" for English with pseudolocalization; capture.gd's --language), for the language PRs'
#       stills; without it the run is the English parity run. A language run (en included) turns every
#       language on for the run, so R1 adds the GENERAL tab and the open language list. Every still's shots.json entry carries
#       the language audit (overflows, missing glyphs, and untranslated text under pseudo) either way.
#       Defaults: routes "R1 R2 R3 R4", sizes "960x540 1280x720 2340x1080" (2340x1080 is the phone
#       landscape aspect), variants "kb-fx kb-calm touch-fx" (keyboard with effects on, keyboard
#       with effects off and Reduced Motion, touch layout with effects on). Every route also takes
#       controller-prompt stills, and R2-R4 switch input devices mid-play (see capture.gd). The
#       2340x1080 window letterboxes the 16:9 game (stretch aspect "keep"), so its stills are the
#       1920x1080 picture inside the bars. Routes run side by side, PARITY_JOBS at a time (default 2).
#   scripts/parity/run.sh ui <out file>
#       Headless resolved-property dump of every visible HUD and menu control in 13 states.
#   scripts/parity/run.sh perf <out dir> <label>
#       Headless CPU-side performance probe (startup including load(main.tscn), per-state frame and
#       _process time, _refresh_ui, and the junction room's and its Recesses' _draw in microseconds,
#       node and object counts) into <out dir>/<label>.json. Texture memory is 0 headless; the
#       capture driver records RENDER_TEXTURE_MEM_USED per still in the render container instead.
#   Compare captures with scripts/parity/compare.py (exact changed-pixel counts; --self-test checks
#   it), UI dumps with diff, and perf runs with scripts/parity/perf_summary.py.
#
# Environment:
#   PARITY_HOME   HOME (and XDG dirs) for headless Godot; required for ui and perf, so the real
#                 saves and settings are never touched. Captures use the container's own user data.
#   PARITY_NAME   render.sh job-name prefix (default lighter-parity); each route gets its own job
#                 and cache folder (<prefix>-<route>), so give every parallel harness its own prefix.
#   PARITY_WORK   scratch folder for the headless game copy (default: $TMPDIR/wolf-parity).
#   PARITY_GAME   game folder to use (default: apps/game in this checkout).
#   PARITY_JOBS   routes captured at once (default 2; a whole number of at least 1).
#   PARITY_KEYBOARD  XKB keyboard layout for the captures (render.sh --keyboard; "fr" is AZERTY), for
#                 stills of key names as a player with that keyboard reads them; unset: US QWERTY.
#   PARITY_TIMEOUT  seconds one render run may take (default 2700; a 2340x1080 R2 or R4 run takes
#                 well over 1500 s when several render jobs share the machine).
#   GODOT_BIN     headless godot binary (default: godot).
#
# Routes, variants, sizes and PARITY_NAME are checked by tools/render/validate_names.sh before any
# folder is cleared (they become paths for rm -rf and render.sh's cache), and a capture counts as ok
# only when render.sh exits 0, shots.json says "failed": false and the log has no errors.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
here="$root/scripts/parity"
godot="${GODOT_BIN:-godot}"
game_src="${PARITY_GAME:-$root/apps/game}"
errors='^ERROR:|SCRIPT ERROR|Parse Error|USER ERROR'
# shellcheck source-path=SCRIPTDIR source=../../tools/render/validate_names.sh
source "$root/tools/render/validate_names.sh"

isolate_home() {
  : "${PARITY_HOME:?set PARITY_HOME to a scratch folder so Godot never uses the real user data}"
  export HOME="$PARITY_HOME" XDG_DATA_HOME="$PARITY_HOME/.local/share" XDG_CONFIG_HOME="$PARITY_HOME/.config"
  mkdir -p "$HOME"
}

# A headless copy of the game with the parity scripts at res://parity/; its .godot is kept between runs.
prepare_headless() {
  work="${PARITY_WORK:-${TMPDIR:-/tmp}/wolf-parity}"
  game="$work/game"
  mkdir -p "$work"
  rsync -a --delete --exclude .godot --exclude parity "$game_src/" "$game/"
  mkdir -p "$game/parity"
  rsync -a --delete --include '*.gd' --exclude '*' "$here/" "$game/parity/"
  "$godot" --headless --path "$game" --import > "$work/import-first.log" 2>&1 || true
  "$godot" --headless --path "$game" --import > "$work/import.log" 2>&1
  if grep -qE "$errors" "$work/import.log"; then
    echo "import reported errors (see $work/import.log)" >&2
    exit 1
  fi
}

# One route: every variant and size in turn, each in its own render.sh run.
capture_route() {
  local route="$1" out="$2" sizes="$3" variants="$4" driver="$5" language="$6" status=0 dir variant size w h rc
  for variant in $variants; do
    for size in $sizes; do
      # Checked again here, next to the rm -rf, so the guard travels with the deletion.
      check_route "$route" && check_variant "$variant" && check_size "$size" || return 64
      dir="$out/$route/$variant/$size"
      rm -rf "$dir"
      mkdir -p "$dir"
      w="${size%x*}" h="${size#*x}"
      rc=0
      "$root/tools/render/render.sh" --name "${PARITY_NAME:-lighter-parity}-$route" --driver "$driver" \
          --screen 2560x1440 --timeout "${PARITY_TIMEOUT:-2700}" ${PARITY_KEYBOARD:+--keyboard "$PARITY_KEYBOARD"} "$game_src" "$dir" -- \
          --fixed-fps 60 --resolution "${w}x${h}" --script res://review_capture/capture.gd -- \
          --route="$route" --variant="$variant" --size="$size" --out=/work/out ${language:+--language="$language"} \
          > "$dir/godot.log" 2>&1 || rc=$?
      # render.sh's status is Godot's (capture.gd quits 1 on a failed run; 124 is a timeout), so a
      # crash or a timeout with an old shots.json-shaped file left behind still fails here.
      if [ "$rc" -eq 0 ] && [ -f "$dir/shots.json" ] && grep -q '"failed": false' "$dir/shots.json" && ! grep -qE "$errors" "$dir/godot.log"; then
        echo "ok    $route $variant $size $(grep -o 'shots=[0-9]*' "$dir/godot.log" | tail -1)"
      else
        echo "FAIL  $route $variant $size (render.sh exit $rc; see $dir/godot.log)" >&2
        status=1
      fi
    done
  done
  return "$status"
}

cmd="${1:-}"
case "$cmd" in
  capture)
    shift
    language=""
    if [ "${1:-}" = "--language" ]; then
      language="${2:?--language needs a code}"
      shift 2
    fi
    : "${1:?out dir}"
    routes="${2:-R1 R2 R3 R4}"
    sizes="${3:-960x540 1280x720 2340x1080}"
    variants="${4:-kb-fx kb-calm touch-fx}"
    jobs_max="${PARITY_JOBS:-2}"
    # 0 or a word would never let a route start: the wait below would loop for ever.
    [[ "$jobs_max" =~ ^[1-9][0-9]*$ ]] || { echo "PARITY_JOBS must be a whole number of at least 1, not '$jobs_max'" >&2; exit 64; }
    bad=0
    for route in $routes; do
      check_route "$route" && check_name "${PARITY_NAME:-lighter-parity}-$route" PARITY_NAME || bad=1
    done
    for variant in $variants; do check_variant "$variant" || bad=1; done
    for size in $sizes; do check_size "$size" || bad=1; done
    [ "$bad" -eq 0 ] || exit 64
    out="$(mkdir -p "$1" && cd "$1" && pwd)"
    driver="$(mktemp -d)"
    trap 'rm -rf "$driver"' EXIT
    cp "$here/capture.gd" "$here/parity_sfx_bank.gd" "$here/parity_kit.gd" "$driver/"
    status=0
    pids=()
    for route in $routes; do
      while [ "$(jobs -rp | wc -l | tr -d ' ')" -ge "$jobs_max" ]; do
        sleep 2
      done
      capture_route "$route" "$out" "$sizes" "$variants" "$driver" "$language" &
      pids+=("$!")
    done
    for pid in "${pids[@]}"; do
      wait "$pid" || status=1
    done
    exit "$status"
    ;;
  ui)
    out="${2:?out file}"
    isolate_home
    prepare_headless
    "$godot" --headless --fixed-fps 60 --path "$game" --script res://parity/ui_dump.gd -- --out="$out" > "$out.log" 2>&1
    if grep -qE "$errors" "$out.log"; then
      echo "ui dump reported errors (see $out.log)" >&2
      exit 1
    fi
    echo "ok    ui dump $(wc -l < "$out" | tr -d ' ') lines -> $out"
    ;;
  perf)
    out="${2:?out dir}"
    label="${3:?label}"
    isolate_home
    [ "${PERF_SKIP_PREPARE:-0}" = 1 ] || prepare_headless
    game="${PARITY_WORK:-${TMPDIR:-/tmp}/wolf-parity}/game"
    mkdir -p "$out"
    load="$(uptime | sed 's/.*load averages*: //')"
    "$godot" --headless --fixed-fps 60 --path "$game" --script res://parity/perf.gd -- --out="$out/$label.json" --load="$load" > "$out/$label.log" 2>&1
    if grep -qE "$errors" "$out/$label.log" || [ ! -s "$out/$label.json" ]; then
      echo "perf run reported errors (see $out/$label.log)" >&2
      exit 1
    fi
    echo "ok    perf $label"
    ;;
  *)
    sed -n '2,48p' "$0" >&2
    exit 2
    ;;
esac
