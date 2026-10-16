"""Pull every string literal out of a Godot 4 project's GDScript and scene files.

Purpose: the first pass of the i18n string inventory (WOLF//OVERRIDE, step research-strings).
It lists candidates only; deciding which ones a player sees is a human review step
(see classify.py next to this file, which carries those decisions).

Contract:
    python3 -I extract_literals.py <project_dir> <out.json>
    Writes a JSON array of {path, line, kind, prefix, text, context} where
      path    - path relative to <project_dir>
      line    - 1-based line the literal starts on
      kind    - "gd" for a GDScript literal, "tscn" for a scene property value
      prefix  - "&" (StringName), "^" (NodePath), "r" (raw) or "" (plain String)
      text    - the literal's value with GDScript escapes (\\n, \\t, \\", \\\\) decoded
      context - the stripped source line (gd) or "<node path>.<property>" (tscn)

Gotchas:
  - This is a small hand-written tokenizer, not Godot's parser. It understands "...", '...',
    triple-quoted strings, the &/^/r prefixes and # comments (a # inside a string is not a
    comment). Doc comments (##) are comments and are skipped, which is what we want: they are
    developer text, not player text.
  - Scene files: only the properties players can read are taken (text, tooltip_text,
    placeholder_text, title, and OptionButton/PopupMenu item text). Multi-line scene values are
    joined. Godot writes scene strings with the same escapes as GDScript.
  - Literals are reported once per occurrence; the same English in two places is two entries,
    which is what an inventory of call sites needs.
"""
from __future__ import annotations

import json
import os
import re
import sys

# Scene properties whose value is shown to a player. Anything else (names, paths, groups) is data.
SCENE_TEXT_PROPS = re.compile(
    r'^(text|tooltip_text|placeholder_text|title|popup/item_\d+/text|item_\d+/text)\s*=\s*"'
)
ESCAPES = {"n": "\n", "t": "\t", '"': '"', "'": "'", "\\": "\\", "r": "\r"}


def _decode(raw: str) -> str:
    """Decode the GDScript escapes the game uses; unknown escapes are kept as written."""
    out, i = [], 0
    while i < len(raw):
        ch = raw[i]
        if ch == "\\" and i + 1 < len(raw):
            nxt = raw[i + 1]
            out.append(ESCAPES.get(nxt, "\\" + nxt))
            i += 2
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def scan_gd(source: str):
    """Yield (line, prefix, text, context_line) for each literal in one GDScript source."""
    lines = source.split("\n")
    i, n, line = 0, len(source), 1
    while i < n:
        ch = source[i]
        if ch == "\n":
            line += 1
            i += 1
            continue
        if ch == "#":  # comment to end of line
            while i < n and source[i] != "\n":
                i += 1
            continue
        if ch in "\"'":
            prefix = ""
            if i > 0 and source[i - 1] in "&^r" and (i < 2 or not (source[i - 2].isalnum() or source[i - 2] == "_")):
                prefix = source[i - 1]
            quote = source[i] * 3 if source.startswith(source[i] * 3, i) else source[i]
            start_line = line
            j = i + len(quote)
            buf = []
            while j < n and not source.startswith(quote, j):
                if source[j] == "\\" and prefix != "r":
                    buf.append(source[j : j + 2])
                    j += 2
                    continue
                if source[j] == "\n":
                    line += 1
                buf.append(source[j])
                j += 1
            raw = "".join(buf)
            text = raw if prefix == "r" else _decode(raw)
            yield start_line, prefix, text, lines[start_line - 1].strip()
            i = j + len(quote)
            continue
        i += 1


def scan_tscn(source: str):
    """Yield (line, '', text, node.prop) for each player-readable property in a scene file."""
    node = ""
    rows = source.split("\n")
    k = 0
    while k < len(rows):
        row = rows[k]
        m_node = re.match(r'^\[node name="([^"]+)"(?:[^\]]*parent="([^"]*)")?', row)
        if m_node:
            parent = m_node.group(2)
            node = m_node.group(1) if parent in (None, ".") else f"{parent}/{m_node.group(1)}"
        m = SCENE_TEXT_PROPS.match(row)
        if m:
            start = k
            value = row[m.end():]
            # A value runs to the first unescaped closing quote, possibly on a later row.
            while not re.search(r'(?<!\\)(?:\\\\)*"\s*$', value):
                k += 1
                value += "\n" + rows[k]
            yield start + 1, "", _decode(value.rstrip()[:-1]), f"{node}.{m.group(1)}"
        k += 1


def main(project: str, out_path: str) -> None:
    found = []
    for root, dirs, files in os.walk(project):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for name in sorted(files):
            full = os.path.join(root, name)
            rel = os.path.relpath(full, project)
            if name.endswith(".gd"):
                scanner, kind = scan_gd, "gd"
            elif name.endswith(".tscn"):
                scanner, kind = scan_tscn, "tscn"
            else:
                continue
            with open(full, encoding="utf-8") as fh:
                src = fh.read()
            for ln, prefix, text, ctx in scanner(src):
                found.append({"path": rel, "line": ln, "kind": kind, "prefix": prefix, "text": text, "context": ctx})
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(found, fh, ensure_ascii=False, indent=1)
    print(f"{len(found)} literals -> {out_path}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
