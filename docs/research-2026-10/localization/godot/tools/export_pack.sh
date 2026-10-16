#!/usr/bin/env bash
# Imports a scratch copy of the game and exports a .pck of its macOS preset, to see which translation
# files and which ICU line-breaking data an export carries (research-godot step, 2026-10-16; evidence:
# ../evidence/pck-translation-files.log and measurements.txt).
#   export_pack.sh ROOT LOG_DIR
# ROOT is a scratch export of the repository (it holds apps/game and scripts/godot-helpers.sh, whose
# isolate_godot_home, bounded and import_game this reuses); never the real checkout. Godot's user data
# goes to LOG_DIR/home and is deleted at the end, also on failure. Writes LOG_DIR/game.pck and
# LOG_DIR/pck.log; the "Storing File:" lines of pck.log are the files the export packed.
# Heavy (an import plus an export): run it under ../../prototype/tools/heavy.sh, which holds the one
# shared heavy-run slot.
# History: run as bin/heavy_run.sh, which also took the slot itself, sourced the helpers from the main
# checkout and ran the first version of the POT plugin. The slot now lives only in heavy.sh and the POT
# run only in ../../prototype/tools/extract_pot.sh, so each of those is written once.
# Gotcha: a first import under an isolated HOME and a /private/tmp project path logged
# "Could not create ObjectDB Snapshots directory", which godot-helpers.sh's import_game counts as a
# failure although the import finished (../evidence/pot.log); the run goes on and says so.
set -euo pipefail
root="$(cd "$1" && pwd)" logs="$2"
mkdir -p "$logs"
logs="$(cd "$logs" && pwd)"
# shellcheck source=/dev/null
source "$root/scripts/godot-helpers.sh"
trap 'rm -rf "$logs/home"' EXIT
isolate_godot_home "$logs/home"
cd "$root"
started=$SECONDS
import_game godot "$logs" 300 || echo "export_pack.sh: the import reported problems (see $logs)" >&2
echo "import took $((SECONDS - started))s"
started=$SECONDS
rc=0
bounded 240 godot --headless --path apps/game --export-pack "macOS" "$logs/game.pck" > "$logs/pck.log" 2>&1 || rc=$?
echo "export-pack rc=$rc took $((SECONDS - started))s"
exit "$rc"
