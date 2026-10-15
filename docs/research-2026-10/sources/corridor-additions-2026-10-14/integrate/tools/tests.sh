#!/bin/bash
# Round 7 integration (copied from fix6/tools/tests.sh): import the add copy twice and run every headless suite (godot --headless; no window).
# Each suite gets its own HOME. Logs: add7/shots/logs/.
S=scratchpad
R=$S/real-slice
C=${1:-add}
G=$R/game-$C/apps/game
L=$R/add7/shots/logs
mkdir -p $L/tests-$C
for i in 1 2; do env HOME=$S/home-realslice godot --headless --path $G --import > $L/import-$C-$i.log 2>&1; echo "import $i exit $?"; done
grep -E '^ERROR:|SCRIPT ERROR|Parse Error' $L/import-$C-2.log | head -5
pass=0; fail=0
for t in $G/tests/*_test.gd; do
  n=$(basename $t .gd)
  rm -rf $S/home-realslice-add-t/$n; mkdir -p $S/home-realslice-add-t/$n
  env HOME=$S/home-realslice-add-t/$n perl -e "alarm 300; exec @ARGV" godot --headless --path $G --script res://tests/$n.gd > $L/tests-$C/$n.log 2>&1
  rc=$?
  if [ $rc -ne 0 ] || grep -qE '^ERROR:|SCRIPT ERROR|Parse Error|instances were leaked' $L/tests-$C/$n.log; then echo "FAIL $n ($rc)"; fail=$((fail+1)); else pass=$((pass+1)); fi
done
echo "tests $C: $pass pass, $fail fail"
