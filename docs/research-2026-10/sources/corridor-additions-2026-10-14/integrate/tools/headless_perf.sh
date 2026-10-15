#!/bin/bash
# Round 7 integration (adapted copy of fix6/tools/headless_perf.sh): CPU-side frame times per state in
# game-add, godot --headless (no window, no GPU work), routes A and B, 300 uncapped frames per state,
# with round 6's unchanged headless driver (fix3/driver-headless), copied in for the run and removed after.
S=scratchpad
R=$S/real-slice
G=$R/game-add/apps/game
mkdir -p $G/realslice_capture $R/add7/shots/logs
cp $R/fix3/driver-headless/realslice_capture_headless.gd $G/realslice_capture/
for r in A B; do
  OUT=$R/add7/shots/raw7/add/$r-headless; rm -rf $OUT; mkdir -p $OUT
  env HOME=$S/home-realslice godot --headless --fixed-fps 60 --path $G --script res://realslice_capture/realslice_capture_headless.gd -- --route=$r --out=$OUT --perf=1 > $R/add7/shots/logs/headless-add-$r.log 2>&1
  echo "add $r exit $? $(ls $OUT)"
done
rm -rf $G/realslice_capture
