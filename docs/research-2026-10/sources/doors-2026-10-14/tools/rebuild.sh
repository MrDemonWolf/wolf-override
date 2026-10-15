#!/bin/bash
# Fix round 3 (from fix round 2's rebuild.sh): grade -> r3 passes -> install -> copy into the game copy.
# Deterministic. The cleanups of records, jentry and the junction (fix round 2) are inputs; the hatch's
# cleanup carries its grade and fix round 3's exit changes (leaf fringe, pipe runs, deck at the wall's foot),
# so it runs here.
set -e
F=doors-r1/fix-r3
PY=$F/../../venv/bin/python
G=$F/../game-doors/apps/game
cd $F
# Records and the junction entry: walls, passages (r3: battens), leaf faces (r3: designed wear, grain)
$PY tools/rgrade2.py records exit:records-exit entry:records-entry > records/layers/graded/rgrade2.log
$PY tools/rgrade2.py jentry entry:junction-entry > jentry/layers/graded/rgrade2.log
# the blast door: grade (r3: threshold at the deck, fresh fracture and torn steel lighter), then the thrown leaf
$PY junction/tools/jgrade2.py > junction/layers/graded/jgrade2.log
$PY junction/tools/lying3.py > junction/layers/graded/lying3.log
# the exit: cleanup with its grade (r3: violet fringe, pipe runs and escutcheons, the deck at the wall's foot)
(cd hatch/tools && $PY cleanup.py $F/hatch > ../cleanup-r3.log 2>&1)
# installs (r3: jentry keeps the room's elbow, no pasted pipes; the junction atlas skyline-packed)
(cd records/tools && $PY install.py > ../install-r3.log 2>&1)
(cd jentry/tools && $PY jeinstall.py > ../install-r3.log 2>&1)
(cd junction/tools && $PY install.py > ../install-r3.log 2>&1)
(cd hatch/tools && $PY hinstall.py $F/hatch $F/main-hatch/apps/game/assets > ../hinstall.log 2>&1)
# the atlas check: no key-coloured (violet) pixel in any door atlas
$PY tools/fringecheck.py records/out/assets/props/records-doors-atlas.png jentry/out/assets/props/junction-entry-atlas.png junction/layers/final/junction-door-atlas.png hatch/layers/junction-exit-atlas.png
cp records/out/assets/props/records-doors-atlas.png $G/assets/props/
cp records/out/assets/rooms/records-far.png records/out/assets/rooms/records-mid.png $G/assets/rooms/
cp jentry/out/assets/props/junction-entry-atlas.png $G/assets/props/
cp jentry/out/assets/rooms/junction-far.png jentry/out/assets/rooms/junction-mid.png $G/assets/rooms/
cp junction/layers/final/junction-door-atlas.png $G/assets/props/
cp junction/layers/final/junction_door_layout.gd $G/scripts/
cp hatch/layers/junction-exit-atlas.png $G/assets/props/
echo "rebuild done"
