#!/usr/bin/env bash
# dryrun.sh PROJECT LOG: the capture driver headless (no images), with an isolated Godot home and a
# throwaway copy of the project (the driver is copied in as review_capture/).
set -u
proj="$1" log="$2"
L=scratchpad/land-corridor
work="$(mktemp -d "${TMPDIR:-/tmp}/dry.XXXXXX")"
rsync -a --exclude .godot "$proj/" "$work/project/"
mkdir -p "$work/project/review_capture" && cp "$L/driver/realslice_capture.gd" "$work/project/review_capture/"
export HOME="$work/home" XDG_DATA_HOME="$work/home/.local/share" XDG_CONFIG_HOME="$work/home/.config"
mkdir -p "$HOME"
godot --headless --path "$work/project" --import > "$work/import.log" 2>&1
godot --headless --path "$work/project" --import > "$work/import.log" 2>&1
perl -e 'alarm shift; exec @ARGV' ${LIMIT:-600} godot --headless --path "$work/project" --fixed-fps 60 --script res://review_capture/realslice_capture.gd -- --routes=${ROUTES:-OAB} --perf=${PERF:-0} --out="$work/out" > "$log" 2>&1
echo "rc=$?"
find "$work/out" -name _run.json -exec cat {} \; > "$log.runs.json"
rm -rf "$work"
