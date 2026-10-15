#!/bin/bash
# Runs the relief-valve paint job (Codex built-in image generation, edit mode) from its own folder.
J=scratchpad/real-slice/add7/plume/codex/${1:-paint-relief}
mkdir -p $J/out
cd $J || exit 1
IMGS=()
for f in refs/*.png; do IMGS+=("--image=$f"); done
PROMPT="$(cat prompt.txt)"
codex exec --skip-git-repo-check -s workspace-write --add-dir "$J" --add-dir "$HOME/.codex/generated_images" "${IMGS[@]}" "$PROMPT" < /dev/null > run.log 2>&1
echo "exit $?" >> run.log
grep -m1 -i "session id" run.log | awk '{print $NF}' > session.txt
