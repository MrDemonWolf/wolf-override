#!/usr/bin/env bash
# render_one.sh NAME PROJECT SIZE ROUTES PERF TOUCH: one render.sh run of the landing driver
# (all ROUTES in one Godot run); frames under land-corridor/raw/NAME/<route>/.
set -u
L=scratchpad/land-corridor
name="$1" proj="$2" size="$3" routes="$4" perf="$5" touch="$6"
out="$L/raw/$name"
rm -rf "$out"; mkdir -p "$out" "$L/logs/render"
~/Developer/mrdemonwolf/wolf-override/tools/render/render.sh --name "$name" --driver "$L/driver" --timeout ${TIMEOUT:-3000} \
  "$proj" "$out" -- --fixed-fps 60 --resolution "$size" --script res://review_capture/realslice_capture.gd -- \
  --routes="$routes" --size="$size" --perf="$perf" --touch="$touch" > "$L/logs/render/$name.log" 2>&1
st=$?
echo "$name: exit $st, $(find "$out" -name '*.png' | wc -l | tr -d ' ') pngs"; grep -E "SCRIPT ERROR|route done|all routes" "$L/logs/render/$name.log" | cut -c1-300
