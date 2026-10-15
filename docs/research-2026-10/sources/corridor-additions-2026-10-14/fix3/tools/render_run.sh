#!/bin/bash
# Round 10 (add7 fix round 3; copied from add7/fix2/tools, logs10/raw10), copied from add7/integrate/tools (adapted copy of fix6/tools/render_run.sh): one route in one copy through the
# repo's tools/render/render.sh (Godot 4.7.2 in the Colima container, Xvfb + software GL; no window
# on the Mac). Copies: add = real-slice/game-add, r6 = real-slice/game-slice (read only, render.sh
# copies it), main = real-slice/game-main (read only, likewise).
# usage: render_run.sh <add|r6|main|r9> <route A|B|O|P> <WxH> <outname> [perf 0|1] [driver dir]
# R10: r9 = round 9's installed copy (add7/fix3/work/r9-game, read only); route P = the beacon pulse
# strip, from the separate driver add7/fix3/driver-pulse (pass it as the 6th argument).
set -u
[[ $# -ge 4 && ( "$1" == add || "$1" == r6 || "$1" == main || "$1" == r9 ) && "$2" =~ ^[ABOP]$ && "$3" =~ ^[0-9]+x[0-9]+$ ]] || { echo "bad args: $*"; exit 2; }
R=scratchpad/real-slice
case "$1" in add) P=$R/game-add/apps/game;; r6) P=$R/game-slice/apps/game;; main) P=$R/game-main/apps/game;; r9) P=$R/add7/fix3/work/r9-game;; esac
DRV="${6:-$R/add7/fix1/driver}"
SCR=realslice_capture.gd; [ "$2" == P ] && SCR=pulse_capture.gd
OUT="$R/add7/shots/raw10/$1/$4"
L="$R/add7/shots/logs10"
rm -rf "$OUT"; mkdir -p "$OUT" "$L"
~/Developer/mrdemonwolf/wolf-override/tools/render/render.sh --name "add7f3-$1-$2" --driver "$DRV" --timeout 1500 \
  "$P" "$OUT" -- --fixed-fps 60 --resolution "$3" --script res://review_capture/$SCR -- \
  --route="$2" --size="$3" --perf="${5:-0}" > "$L/run-$1-$4.log" 2>&1
st=$?
echo "$1 $4: exit $st, $(ls "$OUT" | wc -l | tr -d ' ') files"; grep -E "SCRIPT ERROR|route done" "$L/run-$1-$4.log" | head -5
