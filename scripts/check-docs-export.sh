#!/usr/bin/env bash
# Guard the static site export in apps/docs/out. `bun run docs:build` runs this right
# after `next build`, so it always checks a fresh export; `bun run docs:check-export`
# re-runs it on the last build without rebuilding.
# Fails when any exported page references the /_next/image optimiser (absent on
# GitHub Pages), lacks the #main-content skip-link target, carries no robots meta tag or more
# than one (robots and googlebot counted together), or when any page or stylesheet
# references a .ttf font. Also fails when robots.txt lacks its Sitemap line, sitemap.xml
# has a guide page without <lastmod>, the landing page or a guide page lacks its JSON-LD
# block, any JSON-LD block is not valid JSON, a guide page's social card is not og:type article
# with the game name in its og:title, or llms.txt, llms-full.txt or a guide
# page's Markdown copy is missing or carries a raw component tag, or when the press kit zip is missing.
# Also checks the referrer policy and the Content-Security-Policy meta tag, and resolves internal links and fragments with check-docs-links.py.
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
  if ! grep -q '<meta name="referrer" content="strict-origin-when-cross-origin"' "$page"; then
    echo "FAIL  $rel has no strict-origin-when-cross-origin referrer policy" >&2
    status=1
  fi
  # GitHub Pages cannot send headers, so the root layout writes the policy as a meta tag (apps/docs/lib/csp.ts).
  if ! grep -q '<meta http-equiv="Content-Security-Policy" content="default-src ' "$page"; then
    echo "FAIL  $rel has no Content-Security-Policy meta tag" >&2
    status=1
  fi
  # grep exits 1 when a page has none; under pipefail that ended the whole script with no FAIL line
  # (Codex review finding M3), so the count is taken even then.
  robots="$( (grep -oE '<meta name="(robots|googlebot)"' "$page" || true) | wc -l | tr -d ' ')"
  # Every page gets one: the root layout's index/follow, or Next's own noindex on the 404 page.
  if [ "$robots" -eq 0 ]; then
    echo "FAIL  $rel has no robots meta tag (the root layout gives every page one)" >&2
    status=1
  elif [ "$robots" -gt 1 ]; then
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

# Social cards (apps/docs/lib/seo.ts pageMetadata): every guide page is og:type article and its
# og:title carries the game name, so a shared link never reads as a bare "Controls".
while IFS= read -r guide; do
  rel="${guide#"$out"/}"
  if ! grep -q '<meta property="og:type" content="article"/>' "$guide"; then
    echo "FAIL  $rel is not og:type article" >&2
    status=1
  fi
  if ! grep -qE '<meta property="og:title" content="[^"]+ \| WOLF OVERRIDE"/>' "$guide"; then
    echo "FAIL  $rel has no og:title ending in ' | WOLF OVERRIDE'" >&2
    status=1
  fi
done < <(find "$out/docs" -name index.html | sort)

# llms.txt files (apps/docs/app/llms*, lib/source.ts): the index opens with the project H1 and
# summary, the full text has no [#heading-id] suffixes, no Markdown copy has a raw component tag, and every guide page
# has the Markdown copy its rel=alternate link names.
if ! head -n 3 "$out/llms.txt" 2>/dev/null | tr '\n' ' ' | grep -q '^# WOLF OVERRIDE  > '; then
  echo "FAIL  llms.txt is missing or does not start with '# WOLF OVERRIDE' and a '> ' summary" >&2
  status=1
fi
if [ ! -s "$out/llms-full.txt" ]; then
  echo "FAIL  llms-full.txt is missing or empty" >&2
  status=1
elif grep -q '\[#' "$out/llms-full.txt"; then
  echo "FAIL  llms-full.txt has [#heading-id] suffixes" >&2
  status=1
fi
# A component without a Markdown form (apps/docs/app/docs/guide-components.tsx) is written as a bare
# JSX tag under its minified build name, such as <eg title="Status">, at the start of a line. Tags
# inside code fences are examples (the style guide shows <Callout>), so fenced lines are skipped.
# Markdown copies are listed with find, so the check also covers pages added later.
if ! find "$out/llms-full.txt" "$out/llms.mdx" \( -name '*.txt' -o -name '*.md' \) -print0 | xargs -0 awk '
  FNR == 1 { fenced = 0 }
  /^ *```/ { fenced = !fenced; next }
  !fenced && /^<\/?[A-Za-z][A-Za-z0-9]*( |>|\/|$)/ { print "FAIL  " FILENAME ":" FNR " has a raw component tag: " $0 > "/dev/stderr"; bad = 1 }
  END { exit bad }'; then
  status=1
fi
while IFS= read -r guide; do
  rel="${guide#"$out"/docs}"
  if [ ! -s "$out/llms.mdx/docs${rel%index.html}index.md" ]; then
    echo "FAIL  docs${rel} has no Markdown copy at llms.mdx/docs${rel%index.html}index.md" >&2
    status=1
  fi
done < <(find "$out/docs" -name index.html | sort)

# The press kit zip is git-ignored and built by apps/docs/scripts/build-press-kit.ts as part of the
# docs build, so the export must contain it or the design-system page's download link is dead.
if [ ! -s "$out/press/wolf-override-press-kit.zip" ]; then
  echo "FAIL  press/wolf-override-press-kit.zip is missing from the export (the docs build script makes it)" >&2
  status=1
fi

# Run the checker against planted failures too, so a broken checker cannot silently pass CI.
python3 -I "$root/scripts/check-docs-links.py" --self-test || status=1
python3 -I "$root/scripts/check-docs-links.py" "$out" || status=1

if [ "$status" -eq 0 ]; then
  echo "pass  $count exported pages: no /_next/image, one #main-content each, a CSP meta tag each, exactly one robots meta, no .ttf references; robots.txt names the sitemap; every guide URL in sitemap.xml has <lastmod>; valid JSON-LD on the landing and guide pages; guide pages are og:type article with the game name in og:title; llms.txt, llms-full.txt and a Markdown copy of every guide page, with no raw component tags; the press kit zip"
fi
exit "$status"
