#!/usr/bin/env bash
# run named suites headless, each with its own isolated HOME, 3 at a time
W=scratch/wt-doors
L=scratch/land-doors
run() {
  n=$1; h=$L/homes/$n; mkdir -p $h
  cd $W && HOME=$h XDG_DATA_HOME=$h/.local/share XDG_CONFIG_HOME=$h/.config perl -e 'alarm 300; exec @ARGV' godot --headless --path apps/game --script res://tests/$n.gd > $L/logs/$n.log 2>&1; rc=$?
  if [ $rc -ne 0 ] || grep -qE '^ERROR:|SCRIPT ERROR|Parse Error' $L/logs/$n.log; then echo "FAIL $n rc=$rc"; else echo "pass $n"; fi
  rm -rf $h
}
export -f run; export W L
printf '%s\n' "$@" | xargs -P 3 -I{} bash -c 'run {}'
