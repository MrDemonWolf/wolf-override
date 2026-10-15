#!/bin/bash
# Runs one Codex built-in image-generation job (edit mode) from its own folder under doors-r1/codex/.
J=doors-r1/codex/$1
cd "$J" || exit 1
mkdir -p out
IMGS=()
for f in refs/*.png; do IMGS+=("--image=$f"); done
date -u +%Y-%m-%dT%H:%MZ > started.txt
codex exec --skip-git-repo-check -s workspace-write --add-dir "$J" --add-dir "$HOME/.codex/generated_images" "${IMGS[@]}" "$(cat prompt.txt)" < /dev/null > run.log 2>&1
echo "exit $?" >> run.log
grep -m1 -i "session id" run.log | awk '{print $NF}' > session.txt
date -u +%Y-%m-%dT%H:%MZ > finished.txt
