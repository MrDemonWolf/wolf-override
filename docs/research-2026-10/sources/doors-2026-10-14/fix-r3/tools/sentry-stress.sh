#!/usr/bin/env bash
# fix round 3: sentry_test under load, doors copy vs main 8cb4301, 4 at a time, isolated HOMEs
F=doors-r1/fix-r3
one() { tag=$1; root=$2; h=$F/homes/sentry-stress/$tag; mkdir -p $h/.local/share $h/.config $h/.cache
  ( cd $root && env HOME=$h XDG_DATA_HOME=$h/.local/share XDG_CONFIG_HOME=$h/.config XDG_CACHE_HOME=$h/.cache timeout 300 godot --headless --path apps/game --script res://tests/sentry_test.gd > $F/checks/sentry-stress/$tag.log 2>&1 )
  if grep -q "ERROR" $F/checks/sentry-stress/$tag.log; then echo "FAIL $tag: $(grep -m1 ERROR $F/checks/sentry-stress/$tag.log | cut -c1-150)"; else echo "pass $tag"; fi; }
D=$F/../game-doors; M=$F/base/main-8cb
for r in 1 2 3; do one doors-$r-a $D & one doors-$r-b $D & one main-$r-a $M & one main-$r-b $M & wait; done
