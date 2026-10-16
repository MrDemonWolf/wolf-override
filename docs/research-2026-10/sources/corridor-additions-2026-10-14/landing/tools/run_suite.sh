#!/usr/bin/env bash
# run_suite.sh WT SUITE LOG: one headless suite with an isolated Godot home.
set -u
wt="$1" suite="$2" log="$3"
source "$wt/scripts/godot-helpers.sh"
home="$(mktemp -d "${TMPDIR:-/tmp}/ws-home.XXXXXX")"
isolate_godot_home "$home"
cd "$wt"
bounded 500 godot --headless --path apps/game --script "res://tests/$suite.gd" > "$log" 2>&1
rc=$?
rm -rf "$home"
echo "rc=$rc"
