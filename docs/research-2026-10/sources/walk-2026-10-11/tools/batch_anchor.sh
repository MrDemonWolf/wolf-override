#!/bin/bash
A=/private/tmp/claude-501/-Users-nathanialhenniges-Developer-mrdemonwolf-wolf-override/eb713cd4-8931-48d7-8c83-5b0b0d1e9cf3/scratchpad/walk2/A
cd $A
run() { # row tag
  local row=$1 tag=$2 kind=${1#wolf-}
  bash tools/run_codex.sh $row-a$tag $A/guides/$row-a$tag.png $A/raw/$row-a$tag.png $A/prompts/wolf-$kind-anchored.txt $A/refs/wolf-side-right.png $A/raw/wolf-walk-1.png
}
for job in "$@"; do run ${job%:*} ${job#*:} & sleep 3; done
wait
echo BATCH DONE "$@"
