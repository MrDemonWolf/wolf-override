#!/bin/bash
# Runs every headless suite of the track's own game copy, 4 at a time, each with its own HOME.
P=scratchpad/real-slice/add7/plume
G=$P/game-plume/apps/game
H=scratchpad/home-realslice
run_one() {
  n=$1
  env HOME="$H/plume-$n" perl -e "alarm shift; exec @ARGV" 300 godot --headless --path "$G" --script "res://tests/$n.gd" > "$P/logs/$n.log" 2>&1
  echo "$n rc=$?"
}
export -f run_one; export P G H
ls "$G/tests" | grep '_test.gd$' | sed 's/\.gd$//' | xargs -P 4 -n 1 bash -c 'run_one "$0"'
