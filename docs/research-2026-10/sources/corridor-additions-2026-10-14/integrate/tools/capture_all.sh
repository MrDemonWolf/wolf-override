#!/bin/bash
# Round 7 integration: the capture battery for one copy (add, r6 or main) through render.sh.
T=scratchpad/real-slice/add7/integrate/tools/render_run.sh
C=$1
if [ "$C" == add ]; then bash $T $C O 1280x720 O-720 0; bash $T $C O 1280x720 O-720-r2 0; fi
bash $T $C A 1280x720 A-720 0
bash $T $C B 1280x720 B-720 0
bash $T $C A 2400x1080 A-phone 0
bash $T $C B 2400x1080 B-phone 0
if [ "$C" == add ]; then bash $T $C A 1280x720 A-720-perf 1; bash $T $C B 1280x720 B-720-perf 1; fi
echo ALL DONE $C
