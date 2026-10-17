#!/usr/bin/env bash
# Extracts the game's translation template (POT) with Godot 4.7.2's own generator, headlessly. It is the
# one extractor (DESIGN.md, "One extraction tool"): no second parser of GDScript or scenes exists.
#   scripts/i18n/extract_pot.sh ROOT OUT.pot LOG_DIR
#     ROOT     a checkout holding apps/game and scripts/godot-helpers.sh (whose isolate_godot_home,
#              bounded and import_game it reuses)
#     OUT.pot  where the template goes; the repository keeps it at i18n/messages.pot, outside res://
#              (a template inside the project would be scanned, and a .csv one imported)
#     LOG_DIR  logs and the isolated Godot home (deleted at the end)
#   GODOT_BIN  the godot binary (default: godot on PATH), as in scripts/check-game.sh
# The files scanned are project.godot's internationalization/locale/translations_pot_files, which
# `i18n_tool.py potfiles --check` keeps equal to every .tscn and .gd of the game.
# Steps: import apps/game if it has no .godot yet (import_game's two passes), copy pot_addon/ (next to
# this script) into apps/game/addons/i18n_pot, enable it in project.godot, run the editor headless with
# I18N_POT_OUT set, then remove the addon and put project.godot back exactly as it was, also on failure.
# Exit status: the editor run's (0 when the POT was written), or import_game's failure.
# Heavy (an import and an editor start): on a shared machine, take the heavy-run slot first.
# Gotchas:
# - It edits ROOT's project.godot and apps/game/addons/ for the length of the run, and the trap puts both
#   back; only a hard kill (SIGKILL) can leave them changed, so prefer a scratch copy on a working
#   checkout, and check `git status` if a run was killed.
# - The editor writes its own state under apps/game/.godot, which Git ignores.
# - No headless window opens: --headless runs the editor with no display server.
# History: moved from the research branch codex/localization-research at 520cad1
# (docs/research-2026-10/localization/prototype/tools/extract_pot.sh) in PR L2; it now takes GODOT_BIN,
# and the heavy-slot wrapper it ran under there stayed on that branch.
set -euo pipefail
root="$(cd "$1" && pwd)" out="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")" logs="$3"
here="$(cd "$(dirname "$0")" && pwd)"
godot="${GODOT_BIN:-godot}"
mkdir -p "$logs"
logs="$(cd "$logs" && pwd)"
# shellcheck source=scripts/godot-helpers.sh
source "$root/scripts/godot-helpers.sh"
project="$root/apps/game"
addon="$project/addons/i18n_pot"
backup="$logs/project.godot.before"
cp "$project/project.godot" "$backup"
restore() {
  cp "$backup" "$project/project.godot"
  rm -rf "$addon"
  rmdir "$project/addons" 2>/dev/null || true
  rm -rf "$logs/home"
}
trap restore EXIT
isolate_godot_home "$logs/home"
cd "$root"
if [ ! -d "$project/.godot" ]; then
  started=$SECONDS
  import_game "$godot" "$logs" 400 || echo "extract_pot.sh: the import reported problems (see $logs)" >&2
  echo "import took $((SECONDS - started))s"
fi
mkdir -p "$addon"
cp "$here/pot_addon/pot_probe.gd" "$here/pot_addon/plugin.cfg" "$addon/"
printf '\n[editor_plugins]\n\nenabled=PackedStringArray("res://addons/i18n_pot/plugin.cfg")\n' >> "$project/project.godot"
started=$SECONDS
rc=0
I18N_POT_OUT="$out" bounded 300 "$godot" --headless --editor --path apps/game > "$logs/pot.log" 2>&1 || rc=$?
echo "editor POT run rc=$rc took $((SECONDS - started))s"
grep -E "POT_PROBE" "$logs/pot.log" || true
exit "$rc"
