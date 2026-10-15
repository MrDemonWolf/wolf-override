#!/bin/bash
# land-doors captures through tools/render/render.sh. usage: render.sh NAME PROJECT OUT SIZE PERF TOUCH [ONLY]
R=tools/render/render.sh
L=scratch/land-doors
name="$1"; proj="$2"; out="$3"; size="$4"; perf="$5"; touch="$6"; only="${7:-}"
screen=2560x1440; [ "$size" = "2400x1080" ] && screen=2400x1080
mkdir -p "$out"
"$R" --screen "$screen" --name "$name" --driver "$L/driver" --timeout 2400 "$proj" "$out" -- \
  --script res://review_capture/doors_capture.gd -- --size="$size" --perf="$perf" --touch="$touch" ${only:+--only=$only} > "$out.log" 2>&1
echo "exit $?" >> "$out.log"
