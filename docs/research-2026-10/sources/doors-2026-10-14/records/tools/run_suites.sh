#!/bin/bash
# usage: run_suites.sh <project dir> <log dir> [suite...]  (headless, isolated HOME per suite, 4 at a time)
P="$1"; L="$2"; shift 2
mkdir -p "$L"
H=doors-r1/home
suites=("$@")
if [ ${#suites[@]} -eq 0 ]; then for f in "$P"/tests/*_test.gd; do suites+=("$(basename "$f" .gd)"); done; fi
run() { n="$1"; mkdir -p "$H/suite-$n"; env HOME="$H/suite-$n" perl -e "alarm shift; exec @ARGV" 420 godot --headless --path "$P" --script "res://tests/$n.gd" > "$L/$n.log" 2>&1; rc=$?
  if [ $rc -ne 0 ] || grep -qE "SCRIPT ERROR|^ERROR:|Parse Error|FAIL" "$L/$n.log" || grep -q "leaked at exit" "$L/$n.log"; then echo "FAIL $n rc=$rc"; else echo "pass $n"; fi; }
export -f run; export P L H
printf "%s\n" "${suites[@]}" | xargs -P 4 -I{} bash -c 'run {}'
