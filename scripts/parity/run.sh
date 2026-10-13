#!/usr/bin/env bash
# Parity and performance runs for the behaviour-identical refactor steps of the lighter-game plan
# (docs/research-2026-10/lighter-game/PLAN.md). Nothing here ships and no window opens on this
# machine: rendered captures run through tools/render/render.sh (Godot in a container with a virtual
# screen), and the UI dump and the performance probe run with godot --headless on a scratch copy.
#
# Usage:
#   scripts/parity/run.sh capture <out dir> [routes] [sizes] [variants]
#       Plays each route at each window size in each variant inside the render container and writes
#       stills, shots.json, text.log and audio.log to <out dir>/<route>/<variant>/<size>/.
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
#   PARITY_JOBS   routes captured at once (default 2).
#   PARITY_TIMEOUT  seconds one render run may take (default 2700; a 2340x1080 R2 or R4 run takes
#                 well over 1500 s when several render jobs share the machine).
#   GODOT_BIN     headless godot binary (default: godot).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
here="$root/scripts/parity"
godot="${GODOT_BIN:-godot}"
game_src="${PARITY_GAME:-$root/apps/game}"
errors='^ERROR:|SCRIPT ERROR|Parse Error|USER ERROR'

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
  local route="$1" out="$2" sizes="$3" variants="$4" driver="$5" status=0 dir variant size w h
  for variant in $variants; do
    for size in $sizes; do
      dir="$out/$route/$variant/$size"
      rm -rf "$dir"
      mkdir -p "$dir"
      w="${size%x*}" h="${size#*x}"
      "$root/tools/render/render.sh" --name "${PARITY_NAME:-lighter-parity}-$route" --driver "$driver" \
          --screen 2560x1440 --timeout "${PARITY_TIMEOUT:-2700}" "$game_src" "$dir" -- \
          --fixed-fps 60 --resolution "${w}x${h}" --script res://review_capture/capture.gd -- \
          --route="$route" --variant="$variant" --size="$size" --out=/work/out > "$dir/godot.log" 2>&1 || true
      if [ -f "$dir/shots.json" ] && grep -q '"failed": false' "$dir/shots.json" && ! grep -qE "$errors" "$dir/godot.log"; then
        echo "ok    $route $variant $size $(grep -o 'shots=[0-9]*' "$dir/godot.log" | tail -1)"
      else
        echo "FAIL  $route $variant $size (see $dir/godot.log)" >&2
        status=1
      fi
    done
  done
  return "$status"
}

cmd="${1:-}"
case "$cmd" in
  capture)
    out="$(mkdir -p "${2:?out dir}" && cd "$2" && pwd)"
    routes="${3:-R1 R2 R3 R4}"
    sizes="${4:-960x540 1280x720 2340x1080}"
    variants="${5:-kb-fx kb-calm touch-fx}"
    driver="$(mktemp -d)"
    trap 'rm -rf "$driver"' EXIT
    cp "$here/capture.gd" "$here/parity_sfx_bank.gd" "$driver/"
    status=0
    pids=()
    for route in $routes; do
      while [ "$(jobs -rp | wc -l | tr -d ' ')" -ge "${PARITY_JOBS:-2}" ]; do
        sleep 2
      done
      capture_route "$route" "$out" "$sizes" "$variants" "$driver" &
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
    sed -n '2,37p' "$0" >&2
    exit 2
    ;;
esac
