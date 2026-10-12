#!/bin/bash
# usage: run_codex.sh <job-name> <guide.png> <out.png> <image-prompt-file> [extra-ref ...]
set -u
A=/private/tmp/claude-501/-Users-nathanialhenniges-Developer-mrdemonwolf-wolf-override/eb713cd4-8931-48d7-8c83-5b0b0d1e9cf3/scratchpad/walk2/A
W=/private/tmp/claude-501/-Users-nathanialhenniges-Developer-mrdemonwolf-wolf-override/eb713cd4-8931-48d7-8c83-5b0b0d1e9cf3/scratchpad/walk2
job=$1; guide=$2; out=$3; pfile=$4; shift 4
ident=$1; shift
refs="Image 1 (EDIT TARGET and pose guide): $guide
Image 2 (IDENTITY reference, design only): $ident"
i=3
for r in "$@"; do refs="$refs
Image $i (CONSISTENCY reference: finished frames of this same character; match its rendering, colours, proportions and scale exactly): $r"; i=$((i+1)); done
prompt="Use your \$imagegen skill with the BUILT-IN image_gen tool in EDIT mode (not the CLI, not the API, no scripts). Do exactly one image generation.
Step 1: load each of these local files with view_image so they are in context, in this order:
$refs
Step 2: call image_gen once, editing Image 1, with the other images attached as references, using exactly this prompt text:
---
$(cat "$pfile")
---
Step 3: copy the generated PNG (from \$CODEX_HOME/generated_images/...) to $out . Do not change, create or delete any other file. Do not run any image processing on it.
Final reply: exactly two lines: saved=<absolute path> and source=<absolute path of the original generated file>. No images, no markdown."
cd "$W"
codex exec --skip-git-repo-check -s workspace-write --add-dir "$W" -c model_reasoning_effort='"medium"' "$prompt" < /dev/null > "$A/logs/$job.log" 2>&1
echo "exit=$? job=$job" >> "$A/logs/$job.log"
# Codex sessions running in parallel can copy each other's newest file, so take the image
# from this session's own folder (generated_images/<session id>/) instead of trusting the copy.
sid=$(grep -m1 "session id:" "$A/logs/$job.log" | awk '{print $3}')
src=$(ls -t "$HOME/.codex/generated_images/$sid/"*.png 2>/dev/null | head -1)
if [ -n "$src" ]; then cp "$src" "$out"; echo "$job <- $sid $(shasum -a 256 "$src" | cut -c1-64)" >> "$A/raw/provenance.txt"; else echo "$job NO IMAGE in session $sid" >> "$A/raw/provenance.txt"; rm -f "$out"; fi
