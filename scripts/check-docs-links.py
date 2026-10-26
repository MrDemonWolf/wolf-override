#!/usr/bin/env python3
"""Check local links and fragments in a static export without making network requests."""

from html.parser import HTMLParser
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from urllib.parse import unquote, urljoin, urlsplit


class Page(HTMLParser):
    """Collect rendered IDs, anchor destinations and the canonical URL from HTML."""

    def __init__(self, text):
        super().__init__()
        self.ids = set()
        self.links = []
        self.canonical = None
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        """Read HTML attributes; scripts and text are deliberately ignored."""
        attrs = dict(attrs)
        if attrs.get('id'):
            self.ids.add(attrs['id'])
        if tag == 'a' and attrs.get('href'):
            self.links.append(attrs['href'])
        if tag == 'link' and attrs.get('rel') == 'canonical':
            self.canonical = attrs.get('href')


def check(root):
    """Return errors and the number of checked links; resolve URLs as the static host does."""
    root = root.resolve()
    pages = {path: Page(path.read_text()) for path in sorted(root.rglob('*.html'))}
    home = pages.get(root / 'index.html')
    if not home or not home.canonical:
        return ['index.html is missing or has no canonical URL'], 0
    origin = urlsplit(home.canonical)
    errors = []
    count = 0
    for path, page in pages.items():
        rel = path.relative_to(root).as_posix()
        route = rel.removesuffix('index.html') if rel.endswith('index.html') else rel
        for href in page.links:
            url = urlsplit(urljoin(home.canonical, route))
            target_url = urlsplit(urljoin(url.geturl(), href))
            if (target_url.scheme, target_url.netloc) != (origin.scheme, origin.netloc):
                continue
            count += 1
            target = (root / unquote(target_url.path).lstrip('/')).resolve()
            # Encoded traversal must never make the checker inspect files outside the export.
            if not target.is_relative_to(root):
                errors.append(f'{rel}: {href} escapes the export')
                continue
            if target.is_dir():
                target /= 'index.html'
            if not target.is_file():
                errors.append(f'{rel}: {href} has no exported file')
            elif target_url.fragment and target in pages:
                if unquote(target_url.fragment) not in pages[target].ids:
                    errors.append(f'{rel}: {href} has no matching ID')
    return errors, count


def self_test():
    """Exercise valid, missing, encoded, external and traversal links in a disposable export."""
    with TemporaryDirectory() as folder:
        root = Path(folder)
        (root / 'guide').mkdir()
        (root / 'guide/index.html').write_text('<h1 id="café">Guide</h1><a href="../">Home</a>')
        (root / 'file.zip').write_bytes(b'fixture')
        home = '<link rel="canonical" href="https://example.test/">'
        good = '<a href="guide/?q=1#caf%C3%A9">Guide</a><a href="/file.zip">ZIP</a>'
        external = '<a href="https://other.test/missing">Other</a><a href="mailto:a@example.test">Mail</a>'
        (root / 'index.html').write_text(home + good + external)
        assert check(root) == ([], 3), check(root)
        (root / 'index.html').write_text(home + '<a href="/missing/">Missing</a><a href="/guide/#absent">Bad ID</a><a href="/%2e%2e/outside">Escape</a>')
        errors, count = check(root)
        assert count == 4 and len(errors) == 3, (errors, count)
        assert any('no exported file' in error for error in errors), errors
        assert any('no matching ID' in error for error in errors), errors
        assert any('escapes the export' in error for error in errors), errors
        (root / 'index.html').unlink()
        assert check(root)[0], 'Missing homepage must fail'
    print('pass  static-link checker self-test')


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-test']:
        self_test()
    else:
        failures, checked = check(Path(sys.argv[1]))
        for failure in failures:
            print(f'FAIL  {failure}', file=sys.stderr)
        if failures:
            sys.exit(1)
        print(f'pass  {checked} internal links and fragments resolve in the export')
