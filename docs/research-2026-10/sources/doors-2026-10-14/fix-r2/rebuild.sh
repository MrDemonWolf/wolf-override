#!/bin/bash
# Fix round 2: grade (grade2 + render feedback) -> install -> copy into the game copy. Deterministic.
# The cleanups (records/tools/cleanup.py, jentry/tools/jeclean.py, junction/tools/cleanup.py sealed|blown)
# run once before this; the hatch's cleanup carries its grade, so it runs here.
set -e
F=doors-r1/fix-r2
PY=$F/../../venv/bin/python
G=$F/../game-doors/apps/game
cd $F
$PY tools/rgrade2.py records exit:records-exit entry:records-entry
$PY tools/rgrade2.py jentry entry:junction-entry
$PY junction/tools/jgrade2.py > junction/layers/graded/jgrade2.log
(cd hatch/tools && $PY cleanup.py $F/hatch > ../cleanup-r2.log 2>&1)
(cd records/tools && $PY install.py > ../install-r2.log 2>&1)
(cd jentry/tools && $PY jeinstall.py > ../install-r2.log 2>&1)
(cd junction/tools && $PY install.py > ../install-r2.log 2>&1)
(cd hatch/tools && $PY hinstall.py $F/hatch $F/main-hatch/apps/game/assets > ../hinstall.log 2>&1)
cp records/out/assets/props/records-doors-atlas.png $G/assets/props/
cp records/out/assets/rooms/records-far.png records/out/assets/rooms/records-mid.png $G/assets/rooms/
cp jentry/out/assets/props/junction-entry-atlas.png $G/assets/props/
cp jentry/out/assets/rooms/junction-far.png jentry/out/assets/rooms/junction-mid.png $G/assets/rooms/
cp junction/layers/final/junction-door-atlas.png $G/assets/props/
cp junction/layers/final/junction_door_layout.gd $G/scripts/
cp hatch/layers/junction-exit-atlas.png $G/assets/props/
echo "rebuild done"
