#!/usr/bin/env python3
"""Export the public changelog as plain text for the in-game CHANGELOG screen.

Source: apps/docs/content/docs/changelog.mdx (the single source of truth).
Target: apps/game/assets/changelog.txt (committed; scripts/check-game.sh fails when it drifts).

Usage:
    python3 scripts/export_changelog.py            # rewrite the committed file
    python3 scripts/export_changelog.py --output P # write the export to P instead

Rules (deterministic, standard library only):
- The MDX front matter and everything before the first "## " heading are dropped, so the
  text starts with "Next version (in development)" or the newest version heading.
- "## Heading" becomes "== Heading ==", "### Heading" and deeper become "-- Heading --".
- Bullets keep a "- " prefix; wrapped bullet lines are joined.
- Markdown links keep their text, **bold** and `code` lose their markers.
- Blank lines separate headings and paragraphs; consecutive bullets stay together.
- MDX import lines and JSX tags are not prose and are skipped.
- Everything inside a <Details> (or HTML <details>) block is skipped: the website keeps the long
  notes there and the game shows only the short lines above them (the in-game screen links to
  the website).

Version guard (fails the export, and so scripts/check-game.sh, with exit code 1):
- Cut versions are headings "## 0.N.0 - Month D, YYYY", newest first, each lower than the one
  above it. The newest must equal application/config/version in apps/game/project.godot, the
  single source of the game's version, so a cut cannot forget to bump the game or the reverse.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "apps" / "docs" / "content" / "docs" / "changelog.mdx"
TARGET = ROOT / "apps" / "game" / "assets" / "changelog.txt"
PROJECT = ROOT / "apps" / "game" / "project.godot"

LINK = re.compile(r"\[([^\]]+)\]\([^)]*\)")
BOLD = re.compile(r"\*\*(.+?)\*\*")
CODE = re.compile(r"`([^`]*)`")
# A cut version heading as the exporter writes it: "== 0.15.0 - October 16, 2026 ==".
VERSION_HEADING = re.compile(r"^(\d+)\.(\d+)\.(\d+) - [A-Z][a-z]+ \d{1,2}, \d{4}$")
# project.godot's [application] key; Godot writes it as config/version="0.15.0".
PROJECT_VERSION = re.compile(r'^config/version="([^"]*)"$')


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
    # How many <details> blocks the current line sits in; their bodies are website-only.
    details = 0

    def flush() -> None:
        nonlocal current, kind
        if current:
            result.append((kind, inline(" ".join(current))))
        current = []
        kind = ""

    for raw in lines:
        stripped = raw.strip()
        # The website writes <Details> (its MDX component); plain HTML <details> counts the same.
        if stripped.lower().startswith("<details"):
            flush()
            details += 1
            continue
        if stripped.lower().startswith("</details>"):
            details = max(0, details - 1)
            continue
        if details:
            continue
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


def project_version(project: Path) -> str:
    """Return application/config/version from a project.godot file ("" when it is not set)."""
    section = ""
    for line in project.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            section = stripped[1:-1]
        elif section == "application":
            match = PROJECT_VERSION.match(stripped)
            if match:
                return match.group(1)
    return ""


def version_errors(text: str, version: str) -> list[str]:
    """Check the exported text's version headings against the game's version.

    Inputs: the exported text (headings as "== ... ==") and project.godot's version string.
    Output: a list of problems, empty when the newest cut version equals the game's version and
    every cut version is lower than the one above it.
    """
    cut: list[tuple[tuple[int, int, int], str]] = []
    for line in text.splitlines():
        if line.startswith("== ") and line.endswith(" =="):
            match = VERSION_HEADING.match(line[3:-3])
            if match:
                number = tuple(int(part) for part in match.groups())
                cut.append((number, "%d.%d.%d" % number))
    if not cut:
        return ["no version heading such as '## 0.1.0 - September 26, 2026' found"]
    errors: list[str] = []
    if cut[0][1] != version:
        errors.append("newest changelog version is %s but apps/game/project.godot config/version is %r" % (cut[0][1], version))
    for (newer, newer_text), (older, older_text) in zip(cut, cut[1:]):
        if newer <= older:
            errors.append("version %s is listed above %s but is not newer" % (newer_text, older_text))
    return errors


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--source", type=Path, default=SOURCE, help="changelog.mdx to read (default: the public docs changelog)")
    parser.add_argument("--output", type=Path, default=TARGET, help="plain-text file to write (default: apps/game/assets/changelog.txt)")
    parser.add_argument("--project", type=Path, default=PROJECT, help="project.godot holding the game's version (default: apps/game/project.godot)")
    args = parser.parse_args(argv)
    text = convert(args.source.read_text(encoding="utf-8"))
    if not text.startswith("== "):
        print("export_changelog: no '## ' heading found in %s" % args.source, file=sys.stderr)
        return 1
    errors = version_errors(text, project_version(args.project))
    if errors:
        for error in errors:
            print("export_changelog: %s" % error, file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
