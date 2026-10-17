#!/usr/bin/env bash
# Guard the static site export in apps/docs/out. `bun run docs:build` runs this right
# after `next build`, so it always checks a fresh export; `bun run docs:check-export`
# re-runs it on the last build without rebuilding.
# Fails when any exported page references the /_next/image optimiser (absent on
# GitHub Pages), lacks the #main-content skip-link target, carries more than one
# robots meta tag (robots and googlebot counted together), or when any page or stylesheet
# references a .ttf font. Also fails when robots.txt lacks its Sitemap line, sitemap.xml
# has a guide page without <lastmod>, the landing page or a guide page lacks its JSON-LD
# block, or any JSON-LD block is not valid JSON.
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
  robots="$(grep -oE '<meta name="(robots|googlebot)"' "$page" | wc -l | tr -d ' ')"
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

# Crawl files (apps/docs/app/robots.ts and sitemap.ts): robots.txt advertises the sitemap, and
# every guide URL in the sitemap carries its Git date (the landing page has none by design).
if ! grep -q '^Sitemap: https://' "$out/robots.txt" 2>/dev/null; then
  echo "FAIL  robots.txt is missing or has no Sitemap line" >&2
  status=1
fi
if [ ! -f "$out/sitemap.xml" ]; then
  echo "FAIL  sitemap.xml is missing" >&2
  status=1
else
  # Next writes <loc> and <lastmod> on separate lines, so join the file before matching;
  # `|| true` keeps a zero count from tripping pipefail before the message below.
  sitemap="$(tr -d '\n' < "$out/sitemap.xml")"
  guide_urls="$( (grep -o '<loc>[^<]*/docs/[^<]*</loc>' <<< "$sitemap" || true) | wc -l | tr -d ' ')"
  dated="$( (grep -o '<loc>[^<]*/docs/[^<]*</loc><lastmod>' <<< "$sitemap" || true) | wc -l | tr -d ' ')"
  if [ "$guide_urls" -eq 0 ] || [ "$dated" -ne "$guide_urls" ]; then
    echo "FAIL  sitemap.xml: $dated of $guide_urls guide URLs have <lastmod>" >&2
    status=1
  fi
fi

# Structured data (apps/docs/lib/structured-data.tsx): the landing page carries the site graph and
# every guide page one BreadcrumbList; each block must parse as JSON, or search engines drop it.
if ! python3 -I - "$out" <<'PY'
import json, pathlib, re, sys
out = pathlib.Path(sys.argv[1])
failed = False
for page in sorted(out.rglob('*.html')):
    rel = page.relative_to(out).as_posix()
    if rel.startswith('_next/'):
        continue
    blocks = re.findall(r'<script type="application/ld\+json">(.*?)</script>', page.read_text(), re.S)
    expected = 1 if rel == 'index.html' or rel.startswith('docs/') else 0
    if len(blocks) != expected:
        print(f'FAIL  {rel} has {len(blocks)} JSON-LD blocks (expected {expected})', file=sys.stderr)
        failed = True
    for block in blocks:
        try:
            json.loads(block)
        except ValueError as error:
            print(f'FAIL  {rel} has a JSON-LD block that is not valid JSON: {error}', file=sys.stderr)
            failed = True
sys.exit(1 if failed else 0)
PY
then
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "pass  $count exported pages: no /_next/image, one #main-content each, at most one robots meta, no .ttf references; robots.txt names the sitemap; every guide URL in sitemap.xml has <lastmod>; valid JSON-LD on the landing and guide pages"
fi
exit "$status"
