"""Count the game tests that pin English player text, per test file.

Purpose: tells the i18n plan how many checks would break, or need a locale pinned, once the
game's text goes through translation (WOLF//OVERRIDE, step research-strings).

Contract:
    python3 -I test_asserts.py <project_dir> <literals.json> <inventory.json> <out.json>
    <literals.json> is extract_literals.py output; <inventory.json> is classify.py output (only
    its in-scope, shown entries are used: debug-tool text and the changelog, which no test reads,
    are left out). Writes, per tests/*.gd file:
      english_literals   - test string literals that are (part of) a player string, >= 3 chars
                           and not a bare id; each occurrence counted
      english_lines      - distinct source lines holding at least one such literal
      constant_refs      - references to the game's text constants (e.g. MainScript.TRUST_LINE_1,
                           JunctionRoom.VENT_REASON); these pass in English and keep passing only if
                           the test compares against the same translated text the screen shows
      expect_lines       - lines that call _expect( (or Suite.expect) and hold either of the above
    and the totals.

Gotchas:
  - "Is part of a player string" is a substring test, so a test literal such as "door" matches;
    literals of fewer than 3 characters and lowercase ids are ignored to keep that noise out.
  - The _expect message argument is a test description, not an assertion on game text; it is only
    counted when the description happens to quote a player string (rare, and still language-bound).
  - Constant names are read from `const NAME: String` / `Array[String]` declarations in the game
    scripts, so a renamed constant is picked up without editing this file.
"""
from __future__ import annotations

import json
import os
import re
import sys

ID = re.compile(r"^[a-z0-9_./:%-]*$")
## Proper names shown as written in every language; a test matching one is not pinning English.
NAMES = {"WOLF", "WOLFDEN", "ROWAN", "WOLF//OVERRIDE"}


def text_constants(project: str) -> set[str]:
    """Names of String / Array[String] constants declared in the game's scripts."""
    names = set()
    decl = re.compile(r"^const ([A-Z][A-Z0-9_]*)\s*(?::\s*(?:String|Array\[String\]))?\s*=\s*[\"\[{]", re.M)
    for root, _dirs, files in os.walk(os.path.join(project, "scripts")):
        for name in files:
            if name.endswith(".gd"):
                src = open(os.path.join(root, name), encoding="utf-8").read()
                names.update(decl.findall(src))
    return names


def main(project: str, literals_path: str, inventory_path: str, out_path: str) -> None:
    literals = json.load(open(literals_path, encoding="utf-8"))
    inventory = [e for e in json.load(open(inventory_path, encoding="utf-8")) if e["in_scope"] and e["shown"] and e["class"] != "changelog"]
    corpus = "\u0000".join(e["text"] for e in inventory)
    consts = text_constants(project)
    const_ref = re.compile(r"\b(?:MainScript|Main|JunctionRoom|RecordsRoom|M0State|State|GameSettings|BypassHandle)\.(" + "|".join(sorted(consts)) + r")\b")
    per_file: dict[str, dict] = {}
    english_lines: dict[str, set] = {}
    for e in literals:
        if not e["path"].startswith("tests/") or e["prefix"]:
            continue
        t = e["text"]
        if len(t.strip()) < 3 or ID.match(t) or not re.search(r"[A-Za-z]", t):
            continue
        # One-word literals count only as ALL-CAPS UI words (FUSE LIT, CRANK, DIRECTOR); a lone
        # Titlecase word is a node or bus name in the tests ("Wolf", "Music"), and names that are
        # never translated (WOLF, WOLFDEN, the engineer's names) are not English to translate.
        one_word = not re.search(r"\s", t.strip())
        if one_word and (t != t.upper() or t.strip() in NAMES):
            continue
        if t in corpus:
            f = per_file.setdefault(e["path"], {"english_literals": 0})
            f["english_literals"] += 1
            english_lines.setdefault(e["path"], set()).add(e["line"])
    totals = {"english_literals": 0, "english_lines": 0, "constant_refs": 0, "expect_lines": 0}
    for name in sorted(os.listdir(os.path.join(project, "tests"))):
        if not name.endswith(".gd"):
            continue
        rel = f"tests/{name}"
        rows = open(os.path.join(project, rel), encoding="utf-8").read().split("\n")
        f = per_file.setdefault(rel, {"english_literals": 0})
        lines = english_lines.get(rel, set())
        refs = 0
        ref_lines = set()
        for i, row in enumerate(rows, 1):
            code = row.split("#", 1)[0] if '"' not in row else row
            n = len(const_ref.findall(code))
            if n:
                refs += n
                ref_lines.add(i)
        expect = {i for i in (lines | ref_lines) if re.search(r"\b_?expect\(|Suite\.expect", rows[i - 1])}
        f.update({"english_lines": len(lines), "constant_refs": refs, "expect_lines": len(expect)})
        for k in totals:
            totals[k] += f[k]
    per_file = {k: v for k, v in sorted(per_file.items()) if any(v.values())}
    json.dump({"files": per_file, "totals": totals}, open(out_path, "w", encoding="utf-8"), indent=1)
    print(json.dumps(totals))


if __name__ == "__main__":
    main(*sys.argv[1:5])
