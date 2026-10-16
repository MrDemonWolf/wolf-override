#!/bin/bash
# Round 11 (copied from add7/fix3/tools). Round 10 (add7 fix round 3; copied from add7/fix2/tools, logs10/raw10): the capture battery for one copy (add, r6 or main) through render.sh,
# all with the round-8 driver (add7/fix1/driver), so every copy is captured like for like.
T=scratchpad/real-slice/add7/fix4/tools/render_run.sh
C=$1
bash $T $C O 1280x720 O-720 0
if [ "$C" == add ]; then bash $T $C O 1280x720 O-720-r2 0; fi
bash $T $C O 2400x1080 O-phone 0
bash $T $C O 1600x900 O-1600 0
bash $T $C A 1280x720 A-720 0
bash $T $C B 1280x720 B-720 0
bash $T $C A 2400x1080 A-phone 0
bash $T $C B 2400x1080 B-phone 0
bash $T $C A 1280x720 A-720-perf 1
bash $T $C B 1280x720 B-720-perf 1
echo ALL DONE $C
