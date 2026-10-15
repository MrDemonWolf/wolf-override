#!/bin/bash
# Fix round 2 captures through tools/render/render.sh (container, software GL). usage: render.sh TAG PROJECT SIZE PERF
F=doors-r1/fix-r2
R=tools/render/render.sh
tag="$1"; proj="$2"; size="$3"; perf="$4"
mkdir -p "$F/captures"
"$R" --screen 2560x1440 --name "doors-r1-fix2-$tag" --driver "$F/driver" --timeout 1500 "$proj" "$F/captures/$tag" -- \
  --script res://review_capture/doors_capture.gd -- --size="$size" --perf="$perf" > "$F/captures/$tag.log" 2>&1
echo "exit $?" >> "$F/captures/$tag.log"
