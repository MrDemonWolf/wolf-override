#!/usr/bin/env bash
# Guard the static site export in apps/docs/out. `bun run docs:build` runs this right
# after `next build`, so it always checks a fresh export; `bun run docs:check-export`
# re-runs it on the last build without rebuilding.
# Fails when any exported page references the /_next/image optimiser (absent on
# GitHub Pages), lacks the #main-content skip-link target, carries more than one
# robots meta tag, or when any page or stylesheet references a .ttf font.
# Usage: scripts/check-docs-export.sh   (DOCS_OUT_DIR overrides the export directory)
# Fails when apps/docs/out is missing rather than passing silently.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="${DOCS_OUT_DIR:-$root/apps/docs/out}"

if [ ! -d "$out" ]; then
  echo "No export at $out; run 'bun run docs:build' first." >&2
  exit 1
fi

pages="$(find "$out" -name '*.html' -not -path '*/_next/*' | sort)"
if [ -z "$pages" ]; then
  echo "No HTML pages found under $out." >&2
  exit 1
fi

status=0
count=0
while IFS= read -r page; do
  count=$((count + 1))
  rel="${page#"$out"/}"
  if grep -q '/_next/image' "$page"; then
    echo "FAIL  $rel references /_next/image (the static export has no image optimiser)" >&2
    status=1
  fi
  if ! grep -q 'id="main-content"' "$page"; then
    echo "FAIL  $rel has no #main-content skip-link target" >&2
    status=1
  fi
  robots="$(grep -o '<meta name="robots"' "$page" | wc -l | tr -d ' ')"
  if [ "$robots" -gt 1 ]; then
    echo "FAIL  $rel has $robots robots meta tags (expected at most one)" >&2
    status=1
  fi
  if grep -qi '\.ttf' "$page"; then
    echo "FAIL  $rel references a .ttf font (fonts ship as WOFF2)" >&2
    status=1
  fi
done <<< "$pages"

if find "$out" -name '*.css' -print0 | xargs -0 grep -li '\.ttf' 2>/dev/null | grep -q .; then
  echo "FAIL  an exported stylesheet references a .ttf font (fonts ship as WOFF2)" >&2
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "pass  $count exported pages: no /_next/image, one #main-content each, at most one robots meta, no .ttf references"
fi
exit "$status"
