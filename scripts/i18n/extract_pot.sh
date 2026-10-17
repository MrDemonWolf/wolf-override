#!/usr/bin/env bash
# Extracts the game's translation template (POT) with Godot 4.7.2's own generator, headlessly, from a
# scratch copy of the repository (never the real checkout).
#   extract_pot.sh ROOT OUT.pot LOG_DIR
# ROOT holds apps/game and scripts/godot-helpers.sh (whose isolate_godot_home, bounded and import_game it
# reuses). The files scanned are the project's internationalization/locale/translations_pot_files.
# Steps: import apps/game if it has no .godot yet (import_game's two passes), copy pot_addon/ (next to
# this script) into apps/game/addons/i18n_pot, enable it in project.godot, run the editor headless with
# I18N_POT_OUT set, then remove the addon and put project.godot back exactly as it was, also on failure.
# Heavy: run it under heavy.sh. Godot's user data goes to LOG_DIR/home (isolated, deleted at the end).
# Gotcha: the editor writes .godot/editor state into the project; that is the scratch copy's own cache.
set -euo pipefail
root="$(cd "$1" && pwd)" out="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")" logs="$3"
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$logs"
logs="$(cd "$logs" && pwd)"
# shellcheck source=/dev/null
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
  import_game godot "$logs" 400 || echo "extract_pot.sh: the import reported problems (see $logs)" >&2
  echo "import took $((SECONDS - started))s"
fi
mkdir -p "$addon"
cp "$here/pot_addon/pot_probe.gd" "$here/pot_addon/plugin.cfg" "$addon/"
printf '\n[editor_plugins]\n\nenabled=PackedStringArray("res://addons/i18n_pot/plugin.cfg")\n' >> "$project/project.godot"
started=$SECONDS
rc=0
I18N_POT_OUT="$out" bounded 300 godot --headless --editor --path apps/game > "$logs/pot.log" 2>&1 || rc=$?
echo "editor POT run rc=$rc took $((SECONDS - started))s"
grep -E "POT_PROBE" "$logs/pot.log" || true
exit "$rc"
