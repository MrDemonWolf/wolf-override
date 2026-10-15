#!/bin/bash
# render.sh captures of the track's game copy (container; no window on the Mac), with round 6's own
# driver and arguments (real-slice/fix6/tools/render_run.sh), so frames compare with raw6.
# usage: capture.sh <route A|B> <WxH> <outname> <perf 0|1>
P=scratchpad/real-slice/add7/plume
R=~/Developer/mrdemonwolf/wolf-override/tools/render/render.sh
rm -rf "$P/shots/$3"; mkdir -p "$P/shots/$3"
"$R" --name "add7-plume" --driver "$P/driver" --timeout 1500 "$P/game-plume/apps/game" "$P/shots/$3" -- \
  --fixed-fps 60 --resolution "$2" --script res://review_capture/realslice_capture.gd -- --route="$1" --size="$2" --perf="$4" > "$P/logs/render-$3.log" 2>&1
echo "$3 exit $?: $(ls "$P/shots/$3" | tr '\n' ' ')"
