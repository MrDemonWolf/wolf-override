#!/bin/bash
# Import a private copy twice headless and run its headless test suites (no window).
# usage: tests.sh <test-game|base-game> [test names...]
S=scratchpad
B=$S/real-slice/add7/beacons
C=$1; shift
G=$B/$C/apps/game
L=$B/logs/$C
mkdir -p $L
for i in 1 2; do env HOME=$S/home-realslice godot --headless --path $G --import > $L/import-$i.log 2>&1; echo "import $i exit $?"; done
grep -E '^ERROR:|SCRIPT ERROR|Parse Error' $L/import-2.log | head -5
pass=0; fail=0
if [ $# -gt 0 ]; then TS="$@"; else TS=$(cd $G/tests && ls *_test.gd | sed 's/\.gd$//'); fi
for n in $TS; do
  env HOME=$S/home-realslice perl -e "alarm 300; exec @ARGV" godot --headless --path $G --script res://tests/$n.gd > $L/$n.log 2>&1
  rc=$?
  if [ $rc -ne 0 ] || grep -qE '^ERROR:|SCRIPT ERROR|Parse Error|instances were leaked' $L/$n.log; then echo "FAIL $n ($rc)"; fail=$((fail+1)); else pass=$((pass+1)); fi
done
echo "tests $C: $pass pass, $fail fail"
