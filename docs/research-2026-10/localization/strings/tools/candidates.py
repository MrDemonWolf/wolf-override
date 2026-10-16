"""Narrow extract_literals.py's output to literals that could be text a player reads.

Purpose: second pass of the i18n string inventory. It drops literals that are plainly data
(resource paths, colours, node and property names, snake_case ids, format-only glue) so the
human review in classify.py only has to look at plausible player text.

Contract:
    python3 -I candidates.py <literals.json> <out.json>
    Keeps entries from game code and scenes only (tests are counted separately by
    test_asserts.py); writes the kept entries unchanged, plus "debug": true for anything under
    scripts/debug/ or in main.gd's debug-hook section (those are out of scope, listed only).

Gotchas:
  - The filter is deliberately loose (it keeps single ALL-CAPS words such as "USE" or "PAUSE"
    because buttons use them); classify.py drops the remaining false positives by name.
  - MAIN_DEBUG_FROM is the first line of main.gd's "Debug tools hooks" section at origin/main
    1cf8d73; if main.gd moves, re-read it there.
"""
from __future__ import annotations

import json
import re
import sys

MAIN_DEBUG_FROM = 5108
DATA = [
    re.compile(r"^(res|user|https?)://"),
    re.compile(r"^#[0-9a-fA-F]{3,8}$"),
    re.compile(r"^[a-z0-9_:./%-]*$"),  # ids, property paths, snake_case keys
    re.compile(r"^[A-Z][a-z0-9]+(?:[A-Z][a-z0-9]*)+%?d?$"),  # CamelCase node names
    re.compile(r"^[^A-Za-z]*$"),  # no letters at all: glue such as "\n", " / ", "%d%%"
    re.compile(r"^(%s[|:\\n ]*)+$"),
]


def keep(entry: dict) -> bool:
    """Whether [entry] might be player text (see module doc for what is dropped)."""
    if entry["prefix"] in ("&", "^"):
        return False
    text = entry["text"]
    return not any(p.search(text) for p in DATA)


def main(src: str, out: str) -> None:
    rows = json.load(open(src, encoding="utf-8"))
    kept = []
    for e in rows:
        if e["path"].startswith("tests/") or not keep(e):
            continue
        e = dict(e)
        e["debug"] = e["path"].startswith("scripts/debug/") or (e["path"] == "scripts/main.gd" and e["line"] >= MAIN_DEBUG_FROM)
        kept.append(e)
    json.dump(kept, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"{len(kept)} candidates ({sum(e['debug'] for e in kept)} debug) -> {out}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
