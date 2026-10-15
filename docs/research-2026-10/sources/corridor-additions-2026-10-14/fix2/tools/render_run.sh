#!/bin/bash
# Round 9 (add7 fix round 2; copied from add7/fix1/tools), copied from add7/integrate/tools (adapted copy of fix6/tools/render_run.sh): one route in one copy through the
# repo's tools/render/render.sh (Godot 4.7.2 in the Colima container, Xvfb + software GL; no window
# on the Mac). Copies: add = real-slice/game-add, r6 = real-slice/game-slice (read only, render.sh
# copies it), main = real-slice/game-main (read only, likewise).
# usage: render_run.sh <add|r6|main> <route A|B|O> <WxH> <outname> [perf 0|1]
set -u
[[ $# -ge 4 && ( "$1" == add || "$1" == r6 || "$1" == main ) && "$2" =~ ^[ABO]$ && "$3" =~ ^[0-9]+x[0-9]+$ ]] || { echo "bad args: $*"; exit 2; }
R=scratchpad/real-slice
case "$1" in add) P=$R/game-add/apps/game;; r6) P=$R/game-slice/apps/game;; main) P=$R/game-main/apps/game;; esac
OUT="$R/add7/shots/raw9/$1/$4"
L="$R/add7/shots/logs9"
rm -rf "$OUT"; mkdir -p "$OUT" "$L"
~/Developer/mrdemonwolf/wolf-override/tools/render/render.sh --name "add7f2-$1-$2" --driver "$R/add7/fix1/driver" --timeout 1500 \
  "$P" "$OUT" -- --fixed-fps 60 --resolution "$3" --script res://review_capture/realslice_capture.gd -- \
  --route="$2" --size="$3" --perf="${5:-0}" > "$L/run-$1-$4.log" 2>&1
st=$?
echo "$1 $4: exit $st, $(ls "$OUT" | wc -l | tr -d ' ') files"; grep -E "SCRIPT ERROR|route done" "$L/run-$1-$4.log" | head -5
