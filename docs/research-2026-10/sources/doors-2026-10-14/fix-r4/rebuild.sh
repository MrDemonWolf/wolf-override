#!/bin/bash
# Fix round 4 assets (from fix round 3's rebuild.sh). Deterministic. With --from-r3 it first re-runs round 3's
# rebuild (which reproduces every round-3 asset in the game copy); then round 4's one asset change:
# the junction entry atlas with the mid plate's steam lapping onto the cross-wall's face (review r4 S1).
set -e
F=doors-r1/fix-r4
R3=$F/../fix-r3
PY=$F/../../venv/bin/python
G=$F/../game-doors/apps/game
if [ "$1" = "--from-r3" ]; then bash $R3/rebuild.sh; fi
mkdir -p $F/jentry
$PY $F/tools/steamlap.py $R3/jentry/out/assets/props/junction-entry-atlas.png $R3/jentry/out/assets/rooms/junction-mid.png $F/jentry/junction-entry-atlas.png $F/jentry/preview > $F/jentry/steamlap.log
$PY $R3/tools/fringecheck.py $F/jentry/junction-entry-atlas.png
cp $F/jentry/junction-entry-atlas.png $G/assets/props/
echo "rebuild r4 done"
