#!/bin/bash
# usage: run_codex.sh <job> <guide.png> <prompt-file> [role=path ...]
# One Codex built-in image_gen EDIT from its own folder (real-slice/add7/codex/crank-<job>/); copies the
# generated PNG byte for byte to crank/raw/<job>.png (metadata and C2PA kept), records the session id,
# hashes and cwd in real-slice/add7/provenance.txt, then archives the session.
# Adapted from walk3/death-poses/tools/run_codex.sh.
set -u
S=scratchpad
A=$S/real-slice/add7
X=$A/crank
job=$1; guide=$2; pfile=$3; shift 3
out=$X/raw/$job.png
J=$A/codex/crank-$job; mkdir -p "$J" "$X/logs"
refs="Image 1 (EDIT TARGET and pose guide): $guide"
i=2
for r in "$@"; do role=${r%%=*}; path=${r#*=}; refs="$refs
Image $i ($role): $path"; i=$((i+1)); done
prompt="Use your \$imagegen skill with the BUILT-IN image_gen tool in EDIT mode (not the CLI, not the API, no API key, no scripts). Do exactly one image generation.
Step 1: load each of these local files with view_image so they are in context, in this order:
$refs
Step 2: call image_gen once, editing Image 1, with the other images attached as references, using exactly this prompt text:
---
$(cat "$pfile")
---
Step 3: copy the generated PNG (from \$CODEX_HOME/generated_images/...) to $out with a plain byte-for-byte copy (cp). KEEP ALL METADATA, including any C2PA content credentials: never strip, clean, re-encode, convert or rewrite the file or its metadata. Do not change, create or delete any other file. Do not run any image processing on it.
Final reply: exactly two lines: saved=<absolute path> and source=<absolute path of the original generated file>. No images, no markdown."
echo "$prompt" > "$J/prompt-sent.txt"
cd "$J" || exit 1
codex exec --skip-git-repo-check -s workspace-write --add-dir "$X" -c model_reasoning_effort='"medium"' "$prompt" < /dev/null > "$X/logs/$job.log" 2>&1
echo "exit=$? job=$job" >> "$X/logs/$job.log"
sid=$(grep -m1 "session id:" "$X/logs/$job.log" | awk '{print $3}')
# take the image from this session's own folder, never another session's newest file
src=$(ls -t "$HOME/.codex/generated_images/$sid/"*.png 2>/dev/null | head -1)
roll=$(/usr/bin/find "$HOME/.codex/sessions" -name "rollout-*$sid.jsonl" 2>/dev/null | head -1)
cwd=$(head -n 1 "$roll" 2>/dev/null | python3 -c "import sys,json; print(json.loads(sys.stdin.readline())['payload'].get('cwd',''))" 2>/dev/null)
if [ -n "$src" ]; then
  [ -f "$out" ] && cmp -s "$src" "$out" || cp -p "$src" "$out"
  echo "crank/$job <- session $sid | sha256 $(shasum -a 256 "$src" | cut -c1-64) | src $src | out $out | cwd $cwd | $(date -u +%FT%TZ)" >> "$A/provenance.txt"
else
  echo "crank/$job NO IMAGE | session $sid | cwd $cwd | $(date -u +%FT%TZ)" >> "$A/provenance.txt"; rm -f "$out"
fi
if [ -n "$sid" ]; then codex archive "$sid" > "$X/logs/$job.archive.txt" 2>&1; echo "archive exit=$? session=$sid" >> "$X/logs/$job.archive.txt"; echo "crank/$job archived $sid" >> "$A/provenance.txt"; fi
echo "$sid" > "$J/session.txt"
