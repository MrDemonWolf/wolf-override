#!/bin/bash
# Runs one Codex built-in image-generation job (edit mode) from its own folder.
# usage: run_job.sh <job>   (needs codex/<job>/prompt.txt; codex/<job>/refs/ holds the images)
# CONFIG: R is the working folder the piece was built in (codex/<job>/ lives under it). It was a
# temporary session folder; set WOLF_DOOR_END_WORK to your own copy.
R="${WOLF_DOOR_END_WORK:-$PWD/door-end-work}"
J=$R/codex/$1
mkdir -p $J/out
cd $J || exit 1
IMGS=()
for f in refs/*.png; do IMGS+=("--image=$f"); done
PROMPT="$(cat prompt.txt)"
codex exec --skip-git-repo-check -s workspace-write --add-dir "$J" --add-dir "$HOME/.codex/generated_images" "${IMGS[@]}" "$PROMPT" < /dev/null > run.log 2>&1
echo "exit $?" >> run.log
grep -m1 -i "session id" run.log | awk '{print $NF}' > session.txt
