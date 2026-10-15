#!/bin/bash
# Round 8 (add7 fix round 1; adapted from integrate/tools/headless_perf.sh): CPU-side frame times per
# state, godot --headless (no window, no GPU work), routes A and B, 300 uncapped frames per state, with
# round 6's unchanged headless driver (fix3/driver-headless), in game-add and in the private main and
# round-6 copies (add7/integrate/probe/{main,r6}-copy, diff-identical to game-main and game-slice).
# The driver is copied in for the run and removed after.
S=scratchpad
R=$S/real-slice
mkdir -p $R/add7/shots/logs10
for c in add; do   # R9/R10: main and round 6 are unchanged; their round-8 headless runs (raw8) stand
  case $c in main) G=$R/add7/integrate/probe/main-copy/apps/game;; r6) G=$R/add7/integrate/probe/r6-copy/apps/game;; add) G=$R/game-add/apps/game;; esac
  mkdir -p $G/realslice_capture
  cp $R/fix3/driver-headless/realslice_capture_headless.gd $G/realslice_capture/
  for r in A B; do
    OUT=$R/add7/shots/raw10/$c/$r-headless; rm -rf $OUT; mkdir -p $OUT
    env HOME=$S/home-realslice godot --headless --fixed-fps 60 --path $G --script res://realslice_capture/realslice_capture_headless.gd -- --route=$r --out=$OUT --perf=1 > $R/add7/shots/logs10/headless-$c-$r.log 2>&1
    echo "$c $r exit $? $(ls $OUT)"
  done
  rm -rf $G/realslice_capture
done
