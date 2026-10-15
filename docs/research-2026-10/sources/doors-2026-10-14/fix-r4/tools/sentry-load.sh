#!/usr/bin/env bash
# fix round 4: sentry_test under heavy CPU load (N busy loops beside it, standing in for a render.sh run), doors copy vs main 0c5d1ae,
# 4 at a time, isolated HOMEs. usage: sentry-load.sh BUSY ROUNDS
F=doors-r1/fix-r4
O=$F/checks/sentry-load; rm -rf $O; mkdir -p $O
source $F/../game-doors/scripts/godot-helpers.sh
one() { tag=$1; root=$2; h=$F/homes/sentry-load/$tag; mkdir -p $h/.local/share $h/.config $h/.cache
  ( cd $root && isolate_godot_home $h && export XDG_CACHE_HOME=$h/.cache && bounded 300 godot --headless --path apps/game --script res://tests/sentry_test.gd > $O/$tag.log 2>&1 )
  if grep -q "ERROR" $O/$tag.log || ! grep -q "Sentry checks passed" $O/$tag.log; then echo "FAIL $tag: $(grep -m1 ERROR $O/$tag.log | cut -c1-170)"; else echo "pass $tag"; fi; }
pids=(); for i in $(seq 1 $1); do ( while :; do :; done ) & pids+=($!); done
D=$F/../game-doors; M=$F/main-0c5
for r in $(seq 1 $2); do ( one doors-$r-a $D & one doors-$r-b $D & one main-$r-a $M & one main-$r-b $M & wait ); done
kill "${pids[@]}" 2>/dev/null
