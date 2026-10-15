#!/bin/bash
# Round 10: rebuild everything in add7/shots that is made from the captures (render.sh, raw10 and the
# older raw8/raw9 runs), in order. Round 9's crops are moved to add7/fix3/work/r9-crops first.
set -e
R=scratchpad/real-slice/add7
PY=scratchpad/venv/bin/python
T=$R/fix3/tools
mkdir -p $R/fix3/work/r9-crops
mv $R/shots/crops/*.png $R/fix3/work/r9-crops/ 2>/dev/null || true
for s in state_diff10 opening_diff10 luminaire_check10 measure10 pulse10 package10; do
  echo "== $s"; $PY -I $T/$s.py | tail -4
done
