"""Parse the Language table out of saved Steam Hardware & Software Survey pages.

Purpose: give the i18n market research one repeatable measurement of Steam's
per-language user share, for the latest month and for a 12-month view built
from Wayback Machine snapshots of
https://store.steampowered.com/hwsurvey/Steam-Hardware-Software-Survey-Welcome-to-Steam

Usage:  python3 -I steamlang.py [--table] FILE...
  FILE   a saved survey page; plain HTML or gzip (Wayback serves gzip bodies).
  --table  print a language x month table (percent) instead of JSON.

Contract: each page yields {"month": "<Month YYYY>" or None, "langs": {name: pct}}
where pct is the share of surveyed Steam users (percent, 0-100) whose Steam
client language is that language. The month is read from the page header
("... September 2026 ..."), so the Wayback capture date is not trusted.

Gotchas:
- The language block starts at " Language " and ends at "Free Hard Drive";
  the first row repeats the top language with a change column, so duplicate
  names are harmless (same value).
- Steam lists Arabic and Malay at 0.00% because those client languages are
  new or tiny; a 0.00 is a real reading, not a parse failure.
- Run with python3 -I: inputs are downloaded, untrusted files.
"""
import gzip
import html
import json
import re
import sys

MONTH_RE = r'((?:January|February|March|April|May|June|July|August|September|October|November|December) 20\d\d)'


def read_text(path):
    """Return the page as text, transparently un-gzipping Wayback bodies."""
    raw = open(path, 'rb').read()
    if raw[:2] == b'\x1f\x8b':
        raw = gzip.decompress(raw)
    return raw.decode('utf-8', errors='replace')


def parse(path):
    """Return {'month', 'langs'} for one saved survey page (see module doc)."""
    t = read_text(path)
    s = re.sub(r'<script.*?</script>', ' ', t, flags=re.S)
    s = re.sub(r'<style.*?</style>', ' ', s, flags=re.S)
    s = re.sub(r'<[^>]+>', ' ', s)
    s = html.unescape(re.sub(r'\s+', ' ', s))
    i = s.find(' Language ')
    # The survey header names its month before the tables; take the first hit
    # after the page chrome so the language picker text cannot confuse it.
    m = re.search(MONTH_RE, s)
    j = s.find('Free Hard Drive', i) if i >= 0 else -1
    seg = s[i:j] if i >= 0 and j > i else ''
    langs = {}
    for r in re.finditer(r'([A-Z][A-Za-z \-]+?) (\d+\.\d+)% ([+\-]?\d+\.\d+)%', seg):
        langs[r.group(1).strip()] = float(r.group(2))
    return {'month': m.group(1) if m else None, 'langs': langs}


def main(argv):
    table = '--table' in argv
    files = [a for a in argv if a != '--table']
    res = {f.split('/')[-1]: parse(f) for f in files}
    if not table:
        print(json.dumps(res, indent=0))
        return
    # Wayback often captures the same survey month twice (a capture taken just
    # before Valve posts the next month), so keep one column per survey month;
    # otherwise the mean double-counts those months.
    cols, seen = [], set()
    for c in res.values():
        if c['month'] not in seen:
            seen.add(c['month'])
            cols.append(c)
    names = sorted({n for c in cols for n in c['langs']},
                   key=lambda n: -cols[-1]['langs'].get(n, 0))
    print('language\t' + '\t'.join((c['month'] or '?')[:3] + (c['month'] or '')[-2:] for c in cols) + '\tmean')
    for n in names:
        vals = [c['langs'].get(n) for c in cols]
        got = [v for v in vals if v is not None]
        print(n + '\t' + '\t'.join('-' if v is None else f'{v:.2f}' for v in vals)
              + f'\t{sum(got)/len(got):.2f}')


if __name__ == '__main__':
    main(sys.argv[1:])
