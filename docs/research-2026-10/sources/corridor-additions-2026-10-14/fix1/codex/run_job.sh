#!/bin/bash
# Runs one Codex built-in image-generation job (edit mode) from its own folder (add7 fix round 1).
# usage: run_job.sh <job dir>   (needs <job>/prompt.txt; <job>/refs/*.png are attached in name order)
J=$1
mkdir -p "$J/out"
cd "$J" || exit 1
IMGS=()
for f in refs/*.png; do IMGS+=("--image=$f"); done
PROMPT="$(cat prompt.txt)"
codex exec --skip-git-repo-check -s workspace-write --add-dir "$J" --add-dir "$HOME/.codex/generated_images" "${IMGS[@]}" "$PROMPT" < /dev/null > run.log 2>&1
echo "exit $?" >> run.log
grep -m1 -i "session id" run.log | awk '{print $NF}' > session.txt
