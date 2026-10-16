#!/bin/bash
# Round 11: rebuild everything in add7/shots that is made from the captures (render.sh raw11 and the
# older raw8/raw9/raw10 runs), in order. Round 10's crops and measurement files are moved to
# add7/fix4/work/r10-package/ first, so nothing stale stays in shots/.
set -e
R=scratchpad/real-slice/add7
PY=scratchpad/venv/bin/python
T=$R/fix4/tools
mkdir -p $R/fix4/work/r10-package/crops $R/fix4/work/r10-package/opening-diff
mv $R/shots/crops/*.png $R/fix4/work/r10-package/crops/ 2>/dev/null || true
mv $R/shots/opening-diff/*.png $R/fix4/work/r10-package/opening-diff/ 2>/dev/null || true
for f in measure9.json measure10.json luminaire-check.json pulse.json opening-diff.json state-diff-720.json state-diff-phone.json perf.json perf-table.md sheet.png; do
  [ -f $R/shots/$f ] && mv $R/shots/$f $R/fix4/work/r10-package/ || true
done
$PY -I $T/state_diff11.py 720 | tail -3
$PY -I $T/state_diff11.py phone | tail -3
for s in opening_diff11 luminaire_check11 measure11 pulse11 perf_table11 package11; do
  echo "== $s"; $PY -I $T/$s.py | tail -4
done
