#!/usr/bin/env python3
"""Prints the code-size figures and the surface that tests and the debug tools use on Main.

Run it on a commit before and after a refactor step and diff the two outputs: a name that drops out
of "main defines" while a test or debug tool still uses it is a broken contract.
Usage: python3 -I scripts/parity/surface.py [repo root]   (prints Markdown on stdout)
"""
import collections
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parents[2])
game = root / "apps" / "game"
main_path = game / "scripts" / "main.gd"
main_src = main_path.read_text()
main_lines = main_src.split("\n")


def lines_of(path: pathlib.Path) -> int:
    return len(path.read_text().splitlines())


def functions(lines: list[str]) -> list[tuple[str, int, int]]:
    """Top-level functions with their first and last line (trailing blanks and the next function's
    doc comments are not counted)."""
    starts = [(i + 1, m.group(1)) for i, l in enumerate(lines) if (m := re.match(r"(?:static )?func (\w+)", l))]
    out = []
    for k, (ln, name) in enumerate(starts):
        end = starts[k + 1][0] - 1 if k + 1 < len(starts) else len(lines)
        while end > ln and (lines[end - 1].strip() == "" or lines[end - 1].lstrip().startswith("##")):
            end -= 1
        out.append((name, ln, end))
    return out


def defined_names(src: str) -> dict[str, set[str]]:
    return {
        "func": set(re.findall(r"^(?:static )?func (\w+)", src, re.M)),
        "var": set(re.findall(r"^(?:@\w+(?:\([^)]*\))? )*var (\w+)", src, re.M)),
        "const": set(re.findall(r"^const (\w+)", src, re.M)),
    }


def code_of(path: pathlib.Path) -> str:
    """The file without its comment lines, so a name in a comment does not count as a use."""
    return "\n".join(l for l in path.read_text().split("\n") if not l.lstrip().startswith("#"))


def counted(pattern: str, files: list[pathlib.Path]) -> collections.Counter:
    c: collections.Counter = collections.Counter()
    for f in files:
        c.update(re.findall(pattern, code_of(f)))
    return c


def fmt(c: collections.Counter) -> str:
    return ", ".join(f"`{k}` ({v})" for k, v in sorted(c.items(), key=lambda kv: (-kv[1], kv[0]))) or "none"


tests = sorted((game / "tests").glob("*_test.gd"))
debug = sorted((game / "scripts" / "debug").glob("*.gd"))
scripts = sorted((game / "scripts").glob("*.gd"))
defs = defined_names(main_src)
all_main = defs["func"] | defs["var"] | defs["const"]

print("## Code size")
print()
print("| File | Lines |")
print("|---|---:|")
total = 0
for f in scripts:
    n = lines_of(f)
    total += n
    print(f"| `scripts/{f.name}` | {n} |")
print(f"| **`scripts/*.gd` total** | **{total}** |")
dn = sum(lines_of(f) for f in debug)
print(f"| `scripts/debug/*.gd` ({len(debug)} files) | {dn} |")
tn = sum(lines_of(f) for f in tests)
print(f"| `tests/*_test.gd` ({len(tests)} files) | {tn} |")
for scene in sorted((game / "scenes").glob("*.tscn")):
    print(f"| `scenes/{scene.name}` | {lines_of(scene)} |")
print()
fns = functions(main_lines)
print(f"main.gd: {len(main_lines) - (1 if main_src.endswith(chr(10)) else 0)} lines, {len(fns)} top-level functions, "
      f"{len(defs['const'])} const, {len(defs['var'])} var (including @onready and @export), "
      f"`status_line =` assigned {len(re.findall(r'status_line = ', main_src))} times, "
      f"`state.chapter_id` read {len(re.findall(r'state\.chapter_id', main_src))} times.")
print()

print("## Tests: what they use on Main")
print()
calls = counted(r'\bgame\.call\(&?"(\w+)"', tests)
gets = counted(r'\bgame\.get\(&?"(\w+)"\)', tests)
sets = counted(r'\bgame\.set\(&?"(\w+)"', tests)
consts = counted(r'(?:constant_map\(\)|main_constants|\bconstants)\["([A-Z_0-9]+)"\]', tests)
consts.update(counted(r'\b(?:Main|MainScript)\.([A-Z][A-Z_0-9]+)\b', tests))
print(f"Methods called with `game.call` ({len(calls)}): {fmt(calls)}")
print()
print(f"Properties read with `game.get` ({len(gets)}): {fmt(gets)}")
print()
print(f"Properties set with `game.set` ({len(sets)}): {fmt(sets)}")
print()
print(f"Main constants read ({len(consts)}): {fmt(consts)}")
print()
paths = counted(r'\bgame\.get_node(?:_or_null)?\("([^"]+)"\)', tests)
print(f"Node paths under Main ({len(paths)} unique, `game.get_node`): " + ", ".join(f"`{p}`" for p in sorted(paths)))
print()
private = sorted(n for n in calls if n.startswith("_"))
print(f"Private methods (leading underscore) tests call ({len(private)}): " + ", ".join(f"`{n}`" for n in private))
print()
# The critique of the plan (section A4) named these 15; every one must stay readable on Main.
critique_15 = ["BYPASS_CRANK_X", "BYPASS_WHEEL", "CORRIDOR_DOOR_LEFT_X", "CORRIDOR_STATIONS", "INTRO_LINES",
               "JUNCTION_STATIONS", "RECORDS_STATIONS", "RELAY_X", "STATION_OVERLAP", "WOLF_BYPASS_CLEAR_X",
               "WOLF_MIRROR_X", "GAMEPLAY_ZOOM", "GAMEPLAY_CAMERA_Y_TOUCH", "VALVE_CRANK_X", "BOLT_WHINE_SECONDS"]
print("The critique's 15 constants: " + ", ".join(f"`{n}` ({'read by tests' if n in consts else 'not read in test code now'}, {'defined' if n in defs['const'] else 'MISSING'})" for n in critique_15))
print()
missing = sorted((set(calls) | set(gets) | set(sets) | set(consts)) - all_main)
print("Used by tests but not defined at the top level of main.gd (inherited or a bug): " + (", ".join(f"`{m}`" for m in missing) or "none"))
print()

print("## Debug tools: what they use on Main")
print()
dcalls = counted(r'\bgame\.(\w+)\b', debug)
dconsts = counted(r'\bMain\.([A-Z][A-Z_0-9]+)\b', debug)
dmembers = collections.Counter({k: v for k, v in dcalls.items() if k in all_main})
print(f"Members of Main used through `game.` in scripts/debug ({len(dmembers)}): {fmt(dmembers)}")
print()
print(f"Main constants read in scripts/debug ({len(dconsts)}): {fmt(dconsts)}")
print()
print("The public debug surface on Main: " + ", ".join(f"`{n}`" for n in sorted(n for n in defs["func"] if n.startswith("debug_"))))
print()

print("## main.gd functions (first and last line)")
print()
print("| Function | Lines | Length |")
print("|---|---|---:|")
for name, a, b in fns:
    print(f"| `{name}` | {a}-{b} | {b - a + 1} |")
