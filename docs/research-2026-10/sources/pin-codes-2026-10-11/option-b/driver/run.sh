#!/bin/bash
# Renders option B's stills on main at cfe304f (shared scratch export ../../export-cfe304f).
set -e
S=${SESSION_SCRATCH:?session scratch, not kept}
B=$S/pin-design/option-b
G=$S/pin-design/export-cfe304f/apps/game
mkdir -p $G/pin_mock_b $B/shots $B/logs
cp $B/driver/keypad_card_mock.gd $B/driver/pin_mock_capture.gd $G/pin_mock_b/
if [ "$1" != "skipimport" ]; then
env HOME=$S/home-pin godot --headless --path $G --import > $B/logs/import-cfe304f.log 2>&1 || true
fi
env HOME=$S/home-pin godot --path $G --script res://pin_mock_b/pin_mock_capture.gd -- --out=$B/shots > $B/logs/run.log 2>&1
grep -E "ERROR|SCRIPT|shot|DONE" $B/logs/run.log | head -30
