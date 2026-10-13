#!/bin/bash
# Renders option A's stills on main at cfe304f (export in ../export-cfe304f, imported twice headless first).
S=${SESSION_SCRATCH:?session scratch, not kept}
A=$S/pin-design/option-a
G=$S/pin-design/export-cfe304f/apps/game
rm -rf $A/shots/mock
env HOME=$S/home-pin godot --resolution 1280x720 --path $G --script $A/driver/mock.gd -- $A/shots/mock > $A/mock.log 2>&1 &
PID=$!
for i in $(seq 1 120); do sleep 1; kill -0 $PID 2>/dev/null || break; done
kill $PID 2>/dev/null
grep -E "shot|ERROR|SCRIPT|error" $A/mock.log | head -30
