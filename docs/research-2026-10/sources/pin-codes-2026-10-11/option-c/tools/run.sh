#!/bin/bash
# Renders option C's stills on main at cfe304f: copies the mock scene into the shared scratch export
# (../../export-cfe304f) under res://pin_mock_c, imports once more, runs it in one window that quits itself.
S=/private/tmp/claude-501/-Users-nathanialhenniges-Developer-mrdemonwolf-wolf-override/eb713cd4-8931-48d7-8c83-5b0b0d1e9cf3/scratchpad
C=$S/pin-design/option-c
G=$S/pin-design/export-cfe304f/apps/game
mkdir -p $G/pin_mock_c $C/mocks
for f in pin_mock.gd keypad_card_mock.gd station_prop_mock.gd pin_mock.tscn; do sed 's#res://pin_mock/#res://pin_mock_c/#g' $C/export/apps/game/pin_mock/$f > $G/pin_mock_c/$f; done
env HOME=$S/home-pin godot --headless --path $G --import > $C/import-cfe304f.log 2>&1 || true
env HOME=$S/home-pin godot --resolution 1280x720 --path $G res://pin_mock_c/pin_mock.tscn -- --out=$C/mocks > $C/run-cfe304f.log 2>&1
grep -E "saved|ERROR|SCRIPT|Jumped" $C/run-cfe304f.log | head -30
