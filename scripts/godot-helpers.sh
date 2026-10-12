# shellcheck shell=bash
# Shared helpers for the scripts that drive the pinned Godot binary headlessly.
# Source this file from bash (scripts/check-game.sh, scripts/export-game.sh); do not run it.

# isolate_godot_home DIR: point Godot's user and editor data at DIR, so a run never touches real saves,
# editor settings or export templates. Godot resolves them from HOME on macOS and XDG_* on Linux.
isolate_godot_home() {
  mkdir -p "$1"
  export HOME="$1" XDG_DATA_HOME="$1/.local/share" XDG_CONFIG_HOME="$1/.config"
}

# bounded SECONDS COMMAND...: run COMMAND, stopping it after SECONDS. Returns the command's status, or
# 124 when it was stopped for running too long. Linux has `timeout`; macOS has none by default (Homebrew's
# coreutils adds `gtimeout`), so fall back to perl, whose alarm survives exec and ends the command.
bounded() {
  local limit="$1" start="$SECONDS" rc=0
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout --kill-after=10 "$limit" "$@" || rc=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout --kill-after=10 "$limit" "$@" || rc=$?
  else
    perl -e 'alarm shift; exec { $ARGV[0] } @ARGV or die "cannot run $ARGV[0]: $!\n"' "$limit" "$@" || rc=$?
  fi
  if [ "$rc" -ne 0 ] && [ $((SECONDS - start)) -ge "$limit" ]; then
    rc=124
  fi
  return "$rc"
}

# Lines Godot prints for errors, script errors and parse errors.
godot_error_lines='^ERROR:|SCRIPT ERROR|Parse Error'

# A fresh checkout's first import loads the project theme before its two variable fonts are imported,
# which logs these sixteen errors and nothing else. They are allowed in that pass only.
first_import_known_errors="$(cat <<'EOF'
^ERROR: Cannot open file 'res://\.godot/imported/(Roboto|Montserrat)-Variable\.ttf-[0-9a-f]+\.fontdata'\.$
^ERROR: Failed loading resource: res://\.godot/imported/(Roboto|Montserrat)-Variable\.ttf-[0-9a-f]+\.fontdata\.$
^ERROR: Failed loading resource: res://assets/fonts/(Roboto|Montserrat)-Variable\.ttf\.$
^ERROR: res://assets/fonts/(Roboto-Regular|Montserrat-Semibold|game_theme)\.tres:[0-9]+ - Parse Error: \[ext_resource\] referenced non-existent resource at: res://assets/fonts/(Roboto-Variable\.ttf|Montserrat-Variable\.ttf|Roboto-Regular\.tres)\.$
^ERROR: Failed loading resource: res://assets/fonts/(Roboto-Regular|Montserrat-Semibold|game_theme)\.tres\.$
^ERROR: Error loading custom project theme 'res://assets/fonts/game_theme\.tres'$
EOF
)"

# import_game GODOT LOG_DIR SECONDS: import apps/game twice from the repository root. The first pass may
# only log the known font errors above; the second must log no error at all. Either pass failing to
# finish in SECONDS, or crashing, fails the import.
import_game() {
  local godot="$1" logs="$2" limit="$3" rc=0 unexpected
  bounded "$limit" "$godot" --headless --path apps/game --import > "$logs/import-first.log" 2>&1 || rc=$?
  if [ "$rc" -eq 124 ]; then
    echo "The first import did not finish within ${limit}s (see $logs/import-first.log)" >&2
    return 1
  fi
  if [ "$rc" -ge 128 ]; then
    echo "The first import crashed with status $rc (see $logs/import-first.log)" >&2
    return 1
  fi
  unexpected="$(grep -E "$godot_error_lines" "$logs/import-first.log" | grep -vE "$first_import_known_errors" || true)"
  if [ -n "$unexpected" ]; then
    echo "The first import reported unexpected errors (see $logs/import-first.log):" >&2
    echo "$unexpected" >&2
    return 1
  fi
  rc=0
  bounded "$limit" "$godot" --headless --path apps/game --import > "$logs/import.log" 2>&1 || rc=$?
  if [ "$rc" -eq 124 ]; then
    echo "The second import did not finish within ${limit}s (see $logs/import.log)" >&2
    return 1
  fi
  if [ "$rc" -ne 0 ] || grep -qE "$godot_error_lines" "$logs/import.log"; then
    echo "The second import failed or reported errors (see $logs/import.log)" >&2
    return 1
  fi
}

# sha256_check / sha512_check: verify "HASH  FILE" lines on stdin, printing only mismatches. Uses sha*sum
# where it exists (GNU on Linux; recent macOS ships BSD versions with the same -c) and shasum otherwise.
sha256_check() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum -c - > /dev/null; else shasum -a 256 -c - > /dev/null; fi
}
sha512_check() {
  if command -v sha512sum >/dev/null 2>&1; then sha512sum -c - > /dev/null; else shasum -a 512 -c - > /dev/null; fi
}

# godot_template_dir GODOT_HOME: where Godot 4.7.2 looks for export templates under that data home.
godot_template_dir() {
  if [ "$(uname -s)" = "Darwin" ]; then
    echo "$1/Library/Application Support/Godot/export_templates/4.7.2.stable"
  else
    echo "$1/.local/share/godot/export_templates/4.7.2.stable"
  fi
}

# verify_export_templates DIR: the four template files the presets use, unchanged from the 4.7.2 release.
verify_export_templates() {
  (cd "$1" && sha256_check <<'SUMS'
88df5e2e6fee99088699be66e6d42e4da4fb0c5619d054297d755a49558a4792  macos.zip
51498b72b3a237f882ebd7d1787f06a4bc1eaf0572daab93837adcfd3cfdc107  windows_debug_x86_64.exe
5514c7645ee897a01f540d3cf22ede5badf92394521a08bfab66a54d7369e6e6  windows_debug_x86_64_console.exe
38885c88f75abbc797a1db7559719800279a00cfb9fa8b2e2868a7f6f84bad2e  version.txt
SUMS
  )
}
