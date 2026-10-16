"""Fetch Steam store language lists for comparable narrative games.

Purpose: measure which interface/subtitle and full-audio languages shipped
narrative side-scrollers list on Steam, to benchmark WOLF//OVERRIDE's list.

Usage: python3 -I steamapps.py OUTDIR "Title=appid" ...
  appid may be '?' to resolve it through Steam's public storesearch API.
Output: one JSON per app saved under OUTDIR (raw appdetails), then a TSV on
stdout: title, appid, release date, language count, languages (Steam names;
'*' marks full audio, per Steam's own markup).

Gotchas:
- supported_languages is HTML: '<strong>*</strong>' after a name means full
  audio; the trailing '<br>...' note explains the star. Both are stripped here.
- Uses only the public storefront API (no key, no account); one request per
  app with a 1.5 s pause so Valve's rate limit (about 200 per 5 min) is never near.
- Inputs fetched are untrusted data; run with python3 -I.
"""
import json, re, sys, time, urllib.parse, urllib.request

UA = {'User-Agent': 'wolf-override-i18n-research/1.0'}


def get(url):
    """GET a URL and parse JSON (Steam storefront returns JSON for both calls)."""
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        return json.load(r)


def resolve(title):
    """Return the first storesearch hit's appid for a title, or None."""
    q = urllib.parse.quote(title)
    items = get(f'https://store.steampowered.com/api/storesearch/?term={q}&l=english&cc=US').get('items', [])
    return str(items[0]['id']) if items else None


def langs(raw):
    """Split Steam's supported_languages HTML into names; '*' = full audio."""
    raw = raw.split('<br>')[0]
    raw = raw.replace('<strong>*</strong>', '*')
    raw = re.sub(r'<[^>]+>', '', raw)
    return [x.strip() for x in raw.split(',') if x.strip()]


def main(outdir, pairs):
    for p in pairs:
        title, appid = p.split('=', 1)
        if appid == '?':
            appid = resolve(title)
            time.sleep(1.5)
        d = get(f'https://store.steampowered.com/api/appdetails?appids={appid}&l=english&cc=US&filters=basic,release_date')
        json.dump(d, open(f'{outdir}/{appid}.json', 'w'))
        data = d.get(appid, {}).get('data', {})
        ls = langs(data.get('supported_languages', ''))
        print('\t'.join([data.get('name', title), appid, data.get('release_date', {}).get('date', ''), str(len(ls)), ', '.join(ls)]))
        time.sleep(1.5)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2:])
