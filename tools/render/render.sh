#!/usr/bin/env bash
# Runs Godot 4.7.2 against a copy of a project inside the render container (Xvfb plus Mesa software
# OpenGL), so rendered captures never open a window on this Mac. See tools/render/README.md.
#
#   tools/render/render.sh [--screen WxH] [--name JOB] [--driver DIR] [--timeout SEC] [--keyboard LAYOUT] PROJECT_DIR OUT_DIR -- GODOT_ARGS...
#
# PROJECT_DIR (a folder holding project.godot) is copied, without its .godot cache, to
# ~/Library/Caches/wolf-override-render/JOB/project, imported headless, and Godot then runs there with
# GODOT_ARGS. Inside the container the project is /work/project and the output folder is /work/out;
# whatever the run writes to /work/out is copied back to OUT_DIR. --driver DIR copies capture scripts
# into the project copy as res://review_capture/ (never into the real project). Every run is killed after
# --timeout seconds (default 900) and its log is kept at JOB/run.log. The exit status is Godot's (124 = timed out).
# --keyboard LAYOUT gives the virtual screen another keyboard layout (an XKB symbols name such as "fr" for
# AZERTY or "de" for QWERTZ), so a capture shows key names as a player with that keyboard reads them
# (localization PR L7a); without it the layout is Xvfb's default, US QWERTY.
set -euo pipefail

image="wolf-godot-render:4.7.2"
screen="2560x1440"
job="default"
driver=""
limit=900
keyboard=""
here="$(cd "$(dirname "$0")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --screen) screen="$2"; shift 2 ;;
    --name) job="$2"; shift 2 ;;
    --driver) driver="$(cd "$2" && pwd)"; shift 2 ;;
    --timeout) limit="$2"; shift 2 ;;
    --keyboard) keyboard="$2"; shift 2 ;;
    *) break ;;
  esac
done
if [[ $# -lt 3 || "$3" != "--" ]]; then
  echo "usage: $0 [--screen WxH] [--name JOB] [--driver DIR] [--timeout SEC] [--keyboard LAYOUT] PROJECT_DIR OUT_DIR -- GODOT_ARGS..." >&2
  exit 64
fi
project="$(cd "$1" && pwd)"
out="$2"
shift 3
[[ -f "$project/project.godot" ]] || { echo "no project.godot in $project" >&2; exit 66; }
command -v docker >/dev/null || { echo "docker is not available (start Colima: colima start)" >&2; exit 69; }

docker image inspect "$image" >/dev/null 2>&1 || docker build -t "$image" "$here" >&2

cache="${WOLF_RENDER_CACHE:-$HOME/Library/Caches/wolf-override-render}/$job"
mkdir -p "$cache/project" "$cache/out"
# The cache keeps its own .godot import folder between runs; the host's is never copied.
rsync -a --delete --exclude .godot --exclude review_capture "$project/" "$cache/project/"
rm -rf "$cache/project/review_capture"
if [[ -n "$driver" ]]; then
  mkdir -p "$cache/project/review_capture"
  cp -R "$driver/." "$cache/project/review_capture/"
fi
find "$cache/out" -mindepth 1 -delete

run() { docker run --rm -v "$cache":/work "$image" "$@"; }
first_import=0
[[ -d "$cache/project/.godot" ]] || first_import=1
run timeout "$limit" godot --headless --path /work/project --import >"$cache/import.log" 2>&1 || true
if [[ $first_import -eq 1 ]]; then
  # A fresh import can log font errors that the second pass clears.
  run timeout "$limit" godot --headless --path /work/project --import >"$cache/import.log" 2>&1 || true
fi

status=0
# With --keyboard, a small shell first makes the layout the throwaway container's default, then becomes
# the usual command ($1 is the layout; the rest is passed through untouched). Why not setxkbmap: on this
# image's Xvfb (Debian bookworm) setxkbmap and xkbcomp both exit 0 but leave the keymap US (measured
# October 19, 2026, dumping key <AC01> with xkbcomp), while the keymap Xvfb compiles at start-up follows
# the files. So the "us" symbols file, the one Xvfb's default rules (evdev, pc105, us) load, is replaced
# by one that includes LAYOUT. The empty array is spelled ${layout[@]+...} because macOS's bash 3.2 calls
# a plain empty "${layout[@]}" unbound.
layout=()
if [[ -n "$keyboard" ]]; then
  [[ "$keyboard" =~ ^[a-z_]+(\([a-z0-9_]+\))?$ ]] || { echo "--keyboard takes an XKB layout name such as fr or de(nodeadkeys)" >&2; exit 64; }
  layout=(sh -c 'printf "default partial alphanumeric_keys modifier_keys\nxkb_symbols \"basic\" { include \"%s\" };\n" "$1" > /usr/share/X11/xkb/symbols/us && shift && exec "$@"' sh "$keyboard")
fi
run timeout --kill-after=10 "$limit" ${layout[@]+"${layout[@]}"} xvfb-run -a -s "-screen 0 ${screen}x24" \
  godot --path /work/project --rendering-driver opengl3 --audio-driver Dummy "$@" 2>&1 | tee "$cache/run.log" || true
status=${PIPESTATUS[0]}
[[ $status -eq 124 ]] && echo "render.sh: Godot was stopped after ${limit}s (see $cache/run.log)" >&2

mkdir -p "$out"
cp -R "$cache/out/." "$out/"
exit "$status"
