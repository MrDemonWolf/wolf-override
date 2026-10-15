#!/bin/bash
# Headless import (twice) and every test suite on a scratch game copy, with an isolated HOME.
# usage: run_checks.sh GAME_DIR LOG_DIR
G="$1"; L="$2"; mkdir -p "$L"
export HOME=doors-r1/home
mkdir -p "$HOME"
for i in 1 2; do godot --headless --path "$G" --import > "$L/import$i.log" 2>&1; echo "import $i: $?"; done
for t in "$G"/tests/*_test.gd; do
  n=$(basename "$t" .gd)
  godot --headless --path "$G" --script "res://tests/$n.gd" > "$L/$n.log" 2>&1; rc=$?
  errs=$(grep -cE "SCRIPT ERROR|ERROR:|FAIL" "$L/$n.log")
  echo "$n rc=$rc error_lines=$errs"
done
