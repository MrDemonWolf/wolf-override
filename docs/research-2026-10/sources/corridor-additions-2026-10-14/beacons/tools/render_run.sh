#!/bin/bash
# One capture route of one private copy through the repo's tools/render/render.sh (container; no window on the Mac).
# usage: render_run.sh <test-game|base-game> <route A|B|O> <WxH> <outname> [perf 0|1]
set -u
B=scratchpad/real-slice/add7/beacons
D=scratchpad/real-slice/fix3/driver
OUT="$B/shots/$1/$4"
rm -rf "$OUT"; mkdir -p "$OUT" "$B/logs/render"
~/Developer/mrdemonwolf/wolf-override/tools/render/render.sh --name "add7-beacons-$1" --driver "$D" --timeout 1500 \
  "$B/$1/apps/game" "$OUT" -- --fixed-fps 60 --resolution "$3" --script res://review_capture/realslice_capture.gd -- \
  --route="$2" --size="$3" --perf="${5:-0}" > "$B/logs/render/run-$1-$4.log" 2>&1
st=$?
echo "$1 $4: exit $st, $(ls "$OUT" | wc -l | tr -d ' ') files"; grep -E "SCRIPT ERROR|route done" "$B/logs/render/run-$1-$4.log" | head -5
