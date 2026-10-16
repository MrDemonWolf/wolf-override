#!/usr/bin/env bash
# Runs one command while holding the single heavy-run slot that the localization job shared with the
# opening-dock job (Nathanial asked for a calm Mac, 2026-10-15), and frees the slot when the command
# ends, also when it fails or is interrupted. A Godot import, a render.sh run or a full game:check
# counts as heavy.
#   HEAVY_SLOTS=<slot script> heavy.sh COMMAND [ARGS...]
# HEAVY_SLOTS is the session's slot script (it lived in the session scratch as dedupe/heavy.sh and is
# not part of the repository): `take` waits up to 9 minutes and prints a slot number, or exits 3 while
# the slot is still busy; `give N` frees slot N. This wrapper waits 60 s after a busy answer and asks
# again, up to 6 times, before giving up with status 3. The command's own exit status is returned.
# Nothing else is kept between runs.
# History: as run on 2026-10-16 the slot script's scratch path was written into this file; the filed
# copy reads it from HEAVY_SLOTS instead, so no session path is kept in the repository.
set -uo pipefail
slots="${HEAVY_SLOTS:?set HEAVY_SLOTS to the session's heavy-run slot script}"
slot=""
for _try in 1 2 3 4 5 6; do
  if slot="$(bash "$slots" take)"; then break; fi
  slot=""; sleep 60
done
[ -n "$slot" ] || { echo "heavy.sh: the heavy slot stayed busy" >&2; exit 3; }
trap 'bash "$slots" give "$slot"' EXIT
echo "heavy.sh: holding slot $slot for: $*" >&2
"$@"
