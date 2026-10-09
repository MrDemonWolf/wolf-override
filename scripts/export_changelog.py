#!/usr/bin/env python3
"""Export the public changelog as plain text for the in-game CHANGELOG screen.

Source: apps/docs/content/docs/changelog.mdx (the single source of truth).
Target: apps/game/assets/changelog.txt (committed; scripts/check-game.sh fails when it drifts).

Usage:
    python3 scripts/export_changelog.py            # rewrite the committed file
    python3 scripts/export_changelog.py --output P # write the export to P instead

Rules (deterministic, standard library only):
- The MDX front matter and everything before the first "## " heading are dropped, so the
  text starts with the newest dated heading.
- "## Heading" becomes "== Heading ==", "### Heading" and deeper become "-- Heading --".
- Bullets keep a "- " prefix; wrapped bullet lines are joined.
- Markdown links keep their text, **bold** and `code` lose their markers.
- Blank lines separate headings and paragraphs; consecutive bullets stay together.
- MDX import lines and JSX tags are not prose and are skipped.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "apps" / "docs" / "content" / "docs" / "changelog.mdx"
TARGET = ROOT / "apps" / "game" / "assets" / "changelog.txt"

LINK = re.compile(r"\[([^\]]+)\]\([^)]*\)")
BOLD = re.compile(r"\*\*(.+?)\*\*")
CODE = re.compile(r"`([^`]*)`")


def inline(text: str) -> str:
    """Strip inline markdown and collapse whitespace."""
    text = LINK.sub(r"\1", text)
    text = BOLD.sub(r"\1", text)
    text = CODE.sub(r"\1", text)
    return " ".join(text.split())


def strip_front_matter(lines: list[str]) -> list[str]:
    if not lines or lines[0].strip() != "---":
        return lines
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return lines[index + 1 :]
    raise SystemExit("export_changelog: unterminated front matter in %s" % SOURCE)


def blocks(lines: list[str]) -> list[tuple[str, str]]:
    """Group the markdown into (kind, text) blocks: heading, subheading, bullet or paragraph."""
    result: list[tuple[str, str]] = []
    current: list[str] = []
    kind = ""
    started = False

    def flush() -> None:
        nonlocal current, kind
        if current:
            result.append((kind, inline(" ".join(current))))
        current = []
        kind = ""

    for raw in lines:
        stripped = raw.strip()
        if stripped.startswith("## "):
            started = True
            flush()
            result.append(("heading", inline(stripped[3:])))
            continue
        if not started:
            continue
        if stripped.startswith("#"):
            flush()
            result.append(("subheading", inline(stripped.lstrip("#").strip())))
        elif stripped.startswith(("- ", "* ")):
            flush()
            kind = "bullet"
            current = [stripped[2:]]
        elif stripped == "":
            flush()
        elif stripped.startswith("import ") or stripped.startswith("<") or stripped.startswith("{"):
            flush()
        elif kind in ("bullet", "paragraph"):
            current.append(stripped)
        else:
            kind = "paragraph"
            current = [stripped]
    flush()
    return result


def render(items: list[tuple[str, str]]) -> str:
    out: list[str] = []
    previous = ""
    for kind, text in items:
        if kind == "heading":
            line = "== %s ==" % text
        elif kind == "subheading":
            line = "-- %s --" % text
        elif kind == "bullet":
            line = "- %s" % text
        else:
            line = text
        needs_gap = bool(out) and not (kind == "bullet" and previous == "bullet") and previous not in ("heading", "subheading")
        if needs_gap:
            out.append("")
        out.append(line)
        previous = kind
    return "\n".join(out).rstrip("\n") + "\n"


def convert(source_text: str) -> str:
    return render(blocks(strip_front_matter(source_text.splitlines())))


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--source", type=Path, default=SOURCE, help="changelog.mdx to read (default: the public docs changelog)")
    parser.add_argument("--output", type=Path, default=TARGET, help="plain-text file to write (default: apps/game/assets/changelog.txt)")
    args = parser.parse_args(argv)
    text = convert(args.source.read_text(encoding="utf-8"))
    if not text.startswith("== "):
        print("export_changelog: no '## ' heading found in %s" % args.source, file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
