#!/usr/bin/env python3
"""Write the UI token file's theme lines into the game theme, and check and apply tuned values.

Source: apps/game/ui/ui.tokens.json (the one home of UI colour, type, density, motion and timing; brief 2.7).
Target: apps/game/assets/fonts/game_theme.tres (committed; scripts/check-game.sh fails when it drifts).

Usage:
    python3 scripts/export_ui_tokens.py                    # rewrite the theme lines the tokens bind
    python3 scripts/export_ui_tokens.py --check            # exit 1 when the theme or the token file drifted
    python3 scripts/export_ui_tokens.py --check-css FILE   # exit 1 when FILE (mockups/shared/wo.css) holds a value
    python3 scripts/export_ui_tokens.py --apply TUNE       # apply the Tune panel's patch, then rewrite the theme

Theme rules (deterministic, standard library only):
- A token's $extensions["com.mrdemonwolf.wolfoverride"]["theme"] lists the theme slots it fills. A slot is
  "<sub_resource id>.<property>" for a StyleBox line ("Button_normal.bg_color") or the bare key of a
  [resource] line ("Button/colors/font_color", "default_font_size").
- Only those lines are rewritten; every other byte of the theme stays as it is. A colour is written
  Color(r, g, b, a) with each number as '%.7g', the text Godot itself writes (the token file stores
  components as '%.7g' % (k / 255), so the first run gives back the hand-made theme byte for byte).
- Every Color() line of the theme must be bound, so no theme colour has a second home; each slot must
  exist and be bound once. Gradients (PackedColorArray) are box art, not tokens, and stay in the theme.

--check fails (exit 1) when regenerating would change the theme, when the token file is not in the form
--apply writes (json.dumps, 2-space indent, trailing newline), or when a token's value breaks its own
limits (see value_problems).

--check-css enforces brief 7.1's rule for the mockups' shared stylesheet, which holds components only and
reads every value from the tokens through var(--wo-...): it fails on a colour literal (hex, a colour
function such as rgb() or hsl(), or a named colour other than transparent and currentColor), a duration,
cubic-bezier( or a font size written as a number anywhere in the file, and on any length other than 0
and 1px inside a rule whose selector names a .wo-* class. Mockup chrome (.mk-*) may use plain lengths.
scripts/check-copies.py compares code lines, so it cannot see a token value copied into CSS; this can.

--apply takes the Tune panel's "Copy JSON diff" (brief 7.2): a JSON list of {"file": ..., "patch": [...]}
where each patch is an RFC 6902 JSON Patch for one of the two files the panel tunes,
apps/game/ui/ui.tokens.json (a token's "$value") or apps/game/i18n/languages.json (a language row's
"row_characters"). Only "test" and "replace" on existing paths are accepted. A value outside the token's
hard_min or hard_max, a change to a computed token, a colour that is not one of the token's options, or a
failed test refuses the whole patch and writes nothing (RFC 6902 section 5); a value outside min and max
(the slider's range) only warns. The token file is written back with key order and $extensions kept;
languages.json keeps its one-row-per-language layout (only the changed number is edited in place). Then
the theme is regenerated, and the old -> new list is printed for the commit message and changelog.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
# The files a Tune patch may name, as the panel writes them (repository-relative, forward slashes).
TOKENS_FILE = "apps/game/ui/ui.tokens.json"
LANGUAGES_FILE = "apps/game/i18n/languages.json"
TOKENS = ROOT / TOKENS_FILE
LANGUAGES = ROOT / LANGUAGES_FILE
THEME = ROOT / "apps" / "game" / "assets" / "fonts" / "game_theme.tres"
# The token file's extension key (the bundle id; DTCG asks for reverse-domain keys).
NAMESPACE = "com.mrdemonwolf.wolfoverride"
# The DTCG 2025.10 types the token file uses (brief 2.7).
TYPES = ("color", "dimension", "duration", "number", "cubicBezier", "fontFamily", "fontWeight")
# The unit each measured type is written in (the root $description says the same).
UNITS = {"dimension": ("px",), "duration": ("ms", "s")}
# The language-row fields the Tune panel may change (brief 7.2: lang.<code>.<field>; reading_cps is
# shown read-only there).
LANGUAGE_FIELDS = ("row_characters",)
# Values another file also checks: changing one in the tokens alone makes that check fail, so --apply says
# where to look. Keys are token dot paths, or "languages.<field>" for a language-row field.
_KNOCKDOWN_TOTAL = "apps/game/tests/impact_test.gd checks RETRY_READY_SECONDS + fade out + fade in = 1.5 s (the Cold Still knockdown timing)"
GUARDED = {
    "languages.row_characters": "apps/game/scripts/dialogue_boxes.gd MAX_ROW_CHARACTERS also holds English's row "
    "limit until B31 reads it from this table; check both",
    "timing.fade.out": _KNOCKDOWN_TOTAL,
    "timing.fade.in": _KNOCKDOWN_TOTAL,
}

ALIAS = re.compile(r"^\{([^{}]+)\}$")
# A theme section header: "[sub_resource type="StyleBoxFlat" id="Button_normal"]".
SUB_RESOURCE = re.compile(r'^\[sub_resource type="\w+" id="(\w+)"\]$')
# A theme property line: "bg_color = Color(...)", "Button/colors/font_color = Color(...)".
PROPERTY = re.compile(r"^([A-Za-z0-9_/]+) = (.*)$")


class TokenError(Exception):
    """A token file, theme or patch the script cannot use; the message says which token or line."""


class Tokens:
    """The token file as a tree (key order kept) plus a flat index of its tokens by dot path.

    Contract: ``data`` is the parsed file; ``entries`` maps every token's dot path ("dialogue.backing") to
    its own object (the one holding "$value"), in file order. Groups are objects without "$value"; keys
    starting with "$" ($description, $type, $extensions) are data, not children.
    """

    def __init__(self, data: dict[str, Any]) -> None:
        self.data = data
        self.entries: dict[str, dict[str, Any]] = {}
        self._walk(data, "")

    def _walk(self, node: dict[str, Any], prefix: str) -> None:
        for key, child in node.items():
            if key.startswith("$"):
                continue
            path = prefix + key
            if not isinstance(child, dict):
                raise TokenError("%s: a group or token must be an object" % path)
            if "$value" in child:
                self.entries[path] = child
            else:
                self._walk(child, path + ".")

    def extension(self, path: str) -> dict[str, Any]:
        """The token's own extension data (status, source, limits, options, theme), {} when it has none."""
        return self.entries[path].get("$extensions", {}).get(NAMESPACE, {})

    def resolve(self, path: str, via: str | None = None) -> tuple[str, Any]:
        """Follows ``path``'s aliases ({group.token}) to a literal: returns (the dot path holding it, the
        value). ``via`` names a token whose new value is the alias to ``path``, so a chain that comes back to
        it is a loop too. Raises TokenError for a missing token or an alias loop."""
        seen: list[str] = [via] if via else []
        while True:
            if path in seen:
                raise TokenError("alias loop: %s" % " -> ".join(seen + [path]))
            seen.append(path)
            if path not in self.entries:
                raise TokenError("no token %s%s" % (path, " (from %s)" % seen[0] if len(seen) > 1 else ""))
            value = self.entries[path]["$value"]
            match = ALIAS.match(value) if isinstance(value, str) else None
            if not match:
                return path, value
            path = match.group(1)


def read_tokens(path: Path) -> tuple[str, Tokens]:
    """Returns the token file's text and its parsed Tokens. Raises TokenError when it is not JSON."""
    text = path.read_text(encoding="utf-8")
    try:
        return text, Tokens(json.loads(text))
    except json.JSONDecodeError as error:
        raise TokenError("%s is not JSON: %s" % (path, error)) from error


def dump_tokens(data: dict[str, Any]) -> str:
    """The token file's one written form: json.dumps with a 2-space indent and a trailing newline. The file
    is kept in this form (--check), so --apply rewrites it with no diff beyond the changed values."""
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def scalar(token_type: str, value: Any) -> float | None:
    """The number a value is measured in for limits: a dimension's px, a duration's ms (an "s" duration is
    turned into ms) or a number itself; None for any other type."""
    if token_type in UNITS:
        return value["value"] * (1000 if value.get("unit") == "s" else 1)
    if token_type == "number":
        return value
    return None


def value_problems(tokens: Tokens, path: str, value: Any) -> list[str]:
    """Why ``value`` cannot be token ``path``'s $value; [] when it can.

    Checks the shape for the token's $type (an alias must resolve to a token of the same type), a colour
    role's alias to a base colour, hard_min and hard_max (inclusive), an enum index and a fontFamily or
    fontWeight among its options. The slider range (min, max) is not a limit; --apply warns about it."""
    entry = tokens.entries[path]
    token_type = entry.get("$type")
    ext = tokens.extension(path)
    if token_type not in TYPES:
        return ["unknown $type %r" % token_type]
    if ext.get("status") not in ("sourced", "computed", "today", "proposal"):
        return ["unknown status %r" % ext.get("status")]
    alias = ALIAS.match(value) if isinstance(value, str) else None
    if alias:
        try:
            target, value = tokens.resolve(alias.group(1), via=path)
        except TokenError as error:
            return [str(error)]
        if tokens.entries[target].get("$type") != token_type:
            return ["alias {%s} is a %s, not a %s" % (alias.group(1), tokens.entries[target].get("$type"), token_type)]
        if token_type == "color" and path.startswith("color.role.") and not alias.group(1).startswith("color.base."):
            return ["a colour role must alias a base colour ({color.base.<name>})"]
    elif token_type == "color" and path.startswith("color.role."):
        return ["a colour role must alias a base colour ({color.base.<name>})"]
    problems: list[str] = []
    if token_type == "color":
        components = value.get("components") if isinstance(value, dict) else None
        alpha = value.get("alpha", 1) if isinstance(value, dict) else None
        if not (isinstance(components, list) and len(components) == 3 and all(_is_number(c) and 0 <= c <= 1 for c in components + [alpha])):
            problems.append("a colour needs three components and an alpha, each from 0 to 1")
        elif value.get("colorSpace") != "srgb":
            problems.append("a colour's colorSpace must be srgb (Godot's Color)")
        elif "hex" in value and value["hex"] != "#" + "".join("%02x" % round(c * 255) for c in components):
            # The game reads components and never hex (UiTokens.color); a hex that disagrees would show
            # another colour wherever a reader shows the hex.
            problems.append("hex %s does not match the components %s" % (value["hex"], components))
    elif token_type in UNITS:
        if not (isinstance(value, dict) and value.get("unit") in UNITS[token_type] and _is_number(value.get("value"))):
            problems.append("a %s is {\"value\": number, \"unit\": %s}" % (token_type, " or ".join(UNITS[token_type])))
    elif token_type == "number":
        if not _is_number(value):
            problems.append("a number token needs a number")
    elif token_type == "cubicBezier":
        if not (isinstance(value, list) and len(value) == 4 and all(_is_number(v) for v in value) and 0 <= value[0] <= 1 and 0 <= value[2] <= 1):
            problems.append("a cubicBezier is [x1, y1, x2, y2] with x1 and x2 from 0 to 1")
    if problems:
        return problems
    options = ext.get("options")
    measured = scalar(token_type, value)
    if options is not None and token_type == "number":
        if not (isinstance(value, int) and 0 <= value < len(options)):
            problems.append("%r is not an index into %s" % (value, options))
    elif options is not None and token_type in ("fontFamily", "fontWeight") and value not in options:
        problems.append("%r is not one of %s" % (value, options))
    elif measured is not None:
        if "hard_min" in ext and measured < ext["hard_min"]:
            problems.append("%s is below hard_min %s" % (_number(measured), ext["hard_min"]))
        if "hard_max" in ext and measured > ext["hard_max"]:
            problems.append("%s is above hard_max %s" % (_number(measured), ext["hard_max"]))
    return problems


def _is_number(value: Any) -> bool:
    """Whether a parsed JSON value is a number (JSON true and false parse to bool, which Python counts as int)."""
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _number(value: float) -> str:
    """A number for messages: "16", not "16.0"; fractions as Python writes them."""
    return str(int(value)) if float(value).is_integer() else repr(value)


def describe(token_type: str, value: Any, options: list[Any] | None = None) -> str:
    """A value as the old -> new list shows it: "16 px", "250 ms", "{color.base.cyan-8de5f5}", "1 (next-screen)"."""
    if isinstance(value, str) or value is None:
        return json.dumps(value) if value is None else value
    if token_type in UNITS:
        return "%s %s" % (_number(value["value"]), value["unit"])
    if token_type == "number" and options is not None and isinstance(value, int) and 0 <= value < len(options):
        return "%d (%s)" % (value, options[value])
    return json.dumps(value)


# --------------------------------------------------------------------------------------------- theme


def theme_slots(lines: list[str]) -> dict[str, list[int]]:
    """Every property line of the theme by slot name ("Button_normal.bg_color", "default_font_size"), with
    the index of each line that writes it (a slot written twice has two)."""
    slots: dict[str, list[int]] = {}
    section: str | None = None  # a sub_resource id, "" in [resource], None elsewhere (headers, ext_resource)
    for index, line in enumerate(lines):
        if line.startswith("["):
            match = SUB_RESOURCE.match(line)
            section = match.group(1) if match else ("" if line == "[resource]" else None)
            continue
        match = PROPERTY.match(line)
        if match and section is not None:
            slots.setdefault("%s.%s" % (section, match.group(1)) if section else match.group(1), []).append(index)
    return slots


def theme_value(token_type: str, value: Any, old: str) -> str:
    """The right-hand side of a bound theme line. A colour is Color(r, g, b, a), each '%.7g'. A dimension or
    number keeps the form of the line it replaces: "16.0" stays a float, "16" must stay a whole number."""
    if token_type == "color":
        return "Color(%s)" % ", ".join("%.7g" % c for c in value["components"] + [value.get("alpha", 1)])
    number = scalar(token_type, value) if token_type in ("dimension", "number") else None
    if number is None:
        raise TokenError("a %s cannot fill a theme slot" % token_type)
    if "." in old:
        return repr(float(number))
    if not float(number).is_integer():
        raise TokenError("%s is not a whole number, and the theme line %r holds one" % (number, old))
    return str(int(number))


def render_theme(tokens: Tokens, theme_text: str) -> str:
    """``theme_text`` with every bound line rewritten from the tokens and nothing else changed.

    Raises TokenError when a binding names a slot the theme does not have, a slot is written twice or bound
    by two tokens, a binding's alias does not resolve, or a Color() line is bound by no token."""
    lines = theme_text.split("\n")
    slots = theme_slots(lines)
    bound: dict[int, str] = {}
    for path in tokens.entries:
        for slot in tokens.extension(path).get("theme", []):
            where = slots.get(slot, [])
            if len(where) != 1:
                raise TokenError("%s: theme slot %s is %s game_theme.tres" % (path, slot, "not in" if not where else "written twice in"))
            if where[0] in bound:
                raise TokenError("%s: theme slot %s is bound by both %s and %s" % (path, slot, bound[where[0]], path))
            bound[where[0]] = path
            _, value = tokens.resolve(path)
            key, old = PROPERTY.match(lines[where[0]]).groups()
            try:
                lines[where[0]] = "%s = %s" % (key, theme_value(tokens.entries[path]["$type"], value, old))
            except TokenError as error:
                raise TokenError("%s (theme slot %s): %s" % (path, slot, error)) from error
    loose = [index + 1 for index, line in enumerate(lines) if " = Color(" in line and index not in bound]
    if loose:
        raise TokenError("game_theme.tres lines %s write a Color() no token binds: give each a color.role.* token" % loose)
    return "\n".join(lines)


def file_problems(tokens: Tokens, text: str) -> list[str]:
    """Why the token file as a whole is not sound: its form, then each token's value (value_problems)."""
    problems: list[str] = []
    if text != dump_tokens(tokens.data):
        problems.append("ui.tokens.json is not in json.dumps(indent=2) form: --apply would reformat it")
    for path, entry in tokens.entries.items():
        problems.extend("%s: %s" % (path, problem) for problem in value_problems(tokens, path, entry["$value"]))
    return problems


# --------------------------------------------------------------------------------------------- --check-css


# CSS Color 4's named colours and system colours (https://www.w3.org/TR/css-color-4/#named-colors and
# #css-system-colors), lower-cased. transparent and currentColor are keywords that add no colour.
CSS_COLOUR_NAMES = frozenset(
    """aliceblue antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown
    burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan
    darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid
    darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet
    deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro
    ghostwhite gold goldenrod gray green greenyellow grey honeydew hotpink indianred indigo ivory khaki
    lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow
    lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue lightslategray
    lightslategrey lightsteelblue lightyellow lime limegreen linen magenta maroon mediumaquamarine
    mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise
    mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite navy oldlace olive olivedrab
    orange orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru
    pink plum powderblue purple rebeccapurple red rosybrown royalblue saddlebrown salmon sandybrown
    seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen steelblue tan
    teal thistle tomato turquoise violet wheat white whitesmoke yellow yellowgreen
    accentcolor accentcolortext activetext buttonborder buttonface buttontext canvas canvastext field
    fieldtext graytext highlight highlighttext linktext mark marktext selecteditem selecteditemtext
    visitedtext""".split()
)
# CSS length units (CSS Values 4: font-relative, viewport, container and absolute). A percentage is not a
# length, and the rule names lengths only.
CSS_LENGTH_UNITS = (
    "px|em|rem|ex|rex|ch|rch|cap|rcap|ic|ric|lh|rlh|vw|vh|vi|vb|vmin|vmax|svw|svh|svi|svb|svmin|svmax|lvw|lvh"
    "|lvi|lvb|lvmin|lvmax|dvw|dvh|dvi|dvb|dvmin|dvmax|cqw|cqh|cqi|cqb|cqmin|cqmax|cm|mm|q|in|pt|pc"
)
# A number with a unit, standing alone (not inside a name such as --wo-gap-2 or a hex colour).
_NUMBER = r"(?<![\w.#-])[+-]?(?:\d+\.?\d*|\.\d+)"
CSS_HEX = re.compile(r"#[0-9a-fA-F]{3,8}(?![\w-])")
CSS_COLOUR_FUNCTION = re.compile(r"(?<![\w-])(?:rgba?|hsla?|hwb|lab|lch|oklab|oklch|color)\(", re.IGNORECASE)
CSS_IDENT = re.compile(r"(?<![\w-])-{0,2}[A-Za-z_][\w-]*")
CSS_DURATION = re.compile(_NUMBER + r"(?:ms|s)(?![\w-])", re.IGNORECASE)
CSS_LENGTH = re.compile(_NUMBER + r"(?:" + CSS_LENGTH_UNITS + r")(?![\w-])", re.IGNORECASE)
CSS_DIGIT = re.compile(r"\d")


def _blank(text: str, pattern: str, flags: int = 0) -> str:
    """``text`` with every match of ``pattern`` turned into spaces (newlines kept), so positions and line
    numbers stay those of the file while comments, strings and url() paths are not read as values."""
    return re.sub(pattern, lambda m: re.sub(r"[^\n]", " ", m.group(0)), text, flags=flags)


def css_problems(css: str) -> list[tuple[int, str]]:
    """Every token value written into ``css`` as (line, problem); [] when it reads every value from var().

    How it reads the file: comments, strings and url(...) are blanked, then the text is cut at "{", ";" and
    "}". A chunk ending in "{" is a rule's prelude (a selector or an at-rule) and opens a block; a chunk
    ending in ";" or "}" with a ":" is a declaration in the innermost block. Declarations are checked
    everywhere for colours, durations, cubic-bezier( and numeric font sizes, and for lengths when any
    enclosing selector names a .wo-* class."""
    text = _blank(css, r"/\*.*?\*/", re.DOTALL)
    text = _blank(text, r"\"(?:\\.|[^\"\\\n])*\"|'(?:\\.|[^'\\\n])*'")
    text = _blank(text, r"(?<![\w-])url\([^)]*\)", re.IGNORECASE)
    problems: list[tuple[int, str]] = []
    stack: list[str] = []
    start = 0
    for match in re.finditer(r"[{};]", text):
        chunk_start, mark = start, match.group(0)
        chunk = text[chunk_start : match.start()]
        start = match.end()
        if mark == "{":
            stack.append(chunk.strip())
            continue
        if ":" in chunk and not chunk.strip().startswith("@"):
            in_component = any(_is_component(prelude) for prelude in stack)
            for where, what in _declaration_problems(chunk, in_component):
                problems.append((text.count("\n", 0, chunk_start + where) + 1, what))
        if mark == "}" and stack:
            stack.pop()
    return problems


def _is_component(prelude: str) -> bool:
    """Whether a block's prelude belongs to game UI: a selector naming a .wo-* class, or a @keyframes
    wo-* animation (which a .wo-* rule plays). Other at-rules (@media) only hold rules."""
    if prelude.startswith("@"):
        return re.match(r"@(?:-webkit-)?keyframes\s+wo-", prelude) is not None
    return ".wo-" in prelude


def _declaration_problems(declaration: str, in_component: bool) -> list[tuple[int, str]]:
    """The problems in one "property: value" declaration (as cut from the file, leading space included) as
    (offset in it, problem). Lengths are checked only when ``in_component`` (inside a .wo-* rule)."""
    prop, _, value = declaration.partition(":")
    base = len(prop) + 1
    name = prop.strip().lower()
    found: list[tuple[int, str]] = []
    for match in CSS_HEX.finditer(value):
        found.append((base + match.start(), "colour literal %s" % match.group(0)))
    for match in CSS_COLOUR_FUNCTION.finditer(value):
        found.append((base + match.start(), "colour literal %s...)" % match.group(0)))
    for match in CSS_IDENT.finditer(value):
        if match.group(0).lower() in CSS_COLOUR_NAMES:
            found.append((base + match.start(), "named colour %s" % match.group(0)))
    for match in CSS_DURATION.finditer(value):
        found.append((base + match.start(), "duration %s" % match.group(0)))
    if "cubic-bezier(" in value.lower():
        found.append((base + value.lower().index("cubic-bezier("), "cubic-bezier( written out"))
    if name in ("font-size", "font") and CSS_DIGIT.search(re.sub(r"--[\w-]+", "", value)):
        found.append((base, "%s with a number: %s" % (name, " ".join(value.split()))))
    if in_component:
        for match in CSS_LENGTH.finditer(value):
            number = float(re.match(r"[+-]?(?:\d+\.?\d*|\.\d+)", match.group(0)).group(0))
            if number != 0 and match.group(0).lstrip("+-").lower() != "1px":
                found.append((base + match.start(), "length %s in a .wo-* rule" % match.group(0)))
    return found


# --------------------------------------------------------------------------------------------- --apply


def pointer(path: str) -> list[str]:
    """An RFC 6901 JSON Pointer as its reference tokens ("~1" is "/", "~0" is "~"). Raises TokenError for a
    pointer that does not start with "/"."""
    if not path.startswith("/"):
        raise TokenError("%r is not a JSON Pointer" % path)
    return [part.replace("~1", "/").replace("~0", "~") for part in path[1:].split("/")]


def same(a: Any, b: Any) -> bool:
    """RFC 6902 section 4.6 equality: numbers by value (42 and 42.0 match), objects by members, arrays in
    order; true and 1 do not match."""
    if isinstance(a, bool) or isinstance(b, bool):
        return type(a) is type(b) and a == b
    if _is_number(a) and _is_number(b):
        return a == b
    if isinstance(a, dict) and isinstance(b, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return type(a) is type(b) and a == b


def token_op(tokens: Tokens, op: dict[str, Any], warnings: list[str], changes: list[str]) -> None:
    """Applies one test or replace to the token file in ``tokens`` (in memory). Refusals raise TokenError;
    slider-range and locked-status notes go to ``warnings``; a replace adds its old -> new line to
    ``changes``."""
    parts = pointer(op["path"])
    path = ".".join(parts[:-1])
    if parts[-1] != "$value" or any(part.startswith("$") for part in parts[:-1]) or path not in tokens.entries:
        raise TokenError("%s is not a token's $value (only existing $value paths can be tested or replaced)" % op["path"])
    entry = tokens.entries[path]
    if op["op"] == "test":
        if not same(entry["$value"], op["value"]):
            raise TokenError("test failed: %s is %s, not %s (the file changed since tuning started)" % (path, json.dumps(entry["$value"]), json.dumps(op["value"])))
        return
    ext = tokens.extension(path)
    new = op["value"]
    if ext.get("status") == "computed":
        raise TokenError("%s is computed from cited numbers (read-only); change its inputs instead" % path)
    if entry["$type"] == "color" and new not in ext.get("options", []):
        raise TokenError("%s: colours are never free to tune (N2); %s is not one of its options %s" % (path, json.dumps(new), ext.get("options", [])))
    problems = value_problems(tokens, path, new)
    if problems:
        raise TokenError("%s: %s" % (path, "; ".join(problems)))
    # An alias takes its target's value, which its own limits were just checked against; no slider applies.
    measured = None if isinstance(new, str) else scalar(entry["$type"], new)
    if measured is not None and "min" in ext and "max" in ext and not ext["min"] <= measured <= ext["max"]:
        warnings.append("%s: %s is outside the slider's %s to %s" % (path, _number(measured), ext["min"], ext["max"]))
    if ext.get("status") in ("sourced", "today"):
        warnings.append("%s was %s (locked in the Tune panel); check the change was meant" % (path, ext.get("status")))
    if path in GUARDED:
        warnings.append("%s: %s" % (path, GUARDED[path]))
    changes.append("%s: %s -> %s" % (path, describe(entry["$type"], entry["$value"], ext.get("options")), describe(entry["$type"], new, ext.get("options"))))
    entry["$value"] = new


def language_op(data: dict[str, Any], op: dict[str, Any], warnings: list[str], changes: list[str]) -> tuple[str, str, Any] | None:
    """Applies one test or replace to languages.json's parsed ``data`` (in memory). Returns (code, field, new
    value) for a replace, None for a test; refusals raise TokenError."""
    parts = pointer(op["path"])
    rows = data.get("languages", {})
    if len(parts) != 3 or parts[0] != "languages" or parts[1] not in rows or parts[2] not in LANGUAGE_FIELDS or parts[2] not in rows[parts[1]]:
        raise TokenError("%s is not a language row's %s" % (op["path"], " or ".join(LANGUAGE_FIELDS)))
    _, code, field = parts
    old = rows[code][field]
    if op["op"] == "test":
        if not same(old, op["value"]):
            raise TokenError("test failed: languages.%s.%s is %s, not %s (the file changed since tuning started)" % (code, field, json.dumps(old), json.dumps(op["value"])))
        return None
    new = op["value"]
    if new is not None and not (isinstance(new, int) and not isinstance(new, bool) and new > 0):
        raise TokenError("languages.%s.%s must be a whole number above 0, or null to run rows to the column" % (code, field))
    if "languages.%s" % field in GUARDED:
        warnings.append("languages.%s.%s: %s" % (code, field, GUARDED["languages.%s" % field]))
    changes.append("languages.%s.%s: %s -> %s" % (code, field, json.dumps(old), json.dumps(new)))
    rows[code][field] = new
    return code, field, new


def edit_language_row(text: str, code: str, field: str, new: Any) -> str:
    """languages.json's ``text`` with ``field`` of the ``code`` row set to ``new``, editing only that number:
    the file keeps one row per language, a layout json.dumps would not keep."""
    row = re.compile(r'^\s*"%s": \{.*$' % re.escape(code))
    value = re.compile(r'("%s": )(null|-?\d+(?:\.\d+)?)(?=[,}])' % re.escape(field))
    lines = text.split("\n")
    hits = [index for index, line in enumerate(lines) if row.match(line) and len(value.findall(line)) == 1]
    if len(hits) != 1:
        raise TokenError("languages.json has no single one-line %s row with one %s to edit" % (code, field))
    lines[hits[0]] = value.sub(lambda m: m.group(1) + json.dumps(new), lines[hits[0]])
    return "\n".join(lines)


def apply_patch(tune_path: Path, tokens_path: Path, languages_path: Path, theme_path: Path) -> int:
    """--apply: applies the Tune panel's patches all or nothing, then writes the token file, languages.json
    and the regenerated theme. Prints warnings to stderr and the old -> new list to stdout. Returns the exit
    status (0 applied, 1 refused with nothing written)."""
    try:
        bundle = json.loads(tune_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print("export_ui_tokens: cannot read %s: %s" % (tune_path, error), file=sys.stderr)
        return 1
    warnings: list[str] = []
    changes: list[str] = []
    try:
        tokens_text, tokens = read_tokens(tokens_path)
        languages_text = languages_path.read_text(encoding="utf-8")
        languages = json.loads(languages_text)
        if not isinstance(bundle, list) or not all(isinstance(item, dict) and isinstance(item.get("patch"), list) for item in bundle):
            raise TokenError("%s is not a list of {\"file\": ..., \"patch\": [...]} (brief 7.2)" % tune_path)
        problems = file_problems(tokens, tokens_text)
        if problems:
            raise TokenError("the token file must pass --check before a patch: %s" % "; ".join(problems))
        edits: list[tuple[str, str, Any]] = []
        for item in bundle:
            if item.get("file") not in (TOKENS_FILE, LANGUAGES_FILE):
                raise TokenError("%r is not a file the Tune panel tunes (%s or %s)" % (item.get("file"), TOKENS_FILE, LANGUAGES_FILE))
            for op in item["patch"]:
                if not isinstance(op, dict) or op.get("op") not in ("test", "replace") or "value" not in op or not isinstance(op.get("path"), str):
                    raise TokenError("only {\"op\": \"test\" or \"replace\", \"path\", \"value\"} operations are accepted, not %s" % json.dumps(op))
                if item["file"] == TOKENS_FILE:
                    token_op(tokens, op, warnings, changes)
                else:
                    edit = language_op(languages, op, warnings, changes)
                    if edit:
                        edits.append(edit)
        problems = file_problems(tokens, dump_tokens(tokens.data))
        if problems:
            raise TokenError("; ".join(problems))
        new_tokens = dump_tokens(tokens.data)
        new_languages = languages_text
        for code, field, new in edits:
            new_languages = edit_language_row(new_languages, code, field, new)
        if json.loads(new_languages) != languages:
            raise TokenError("editing languages.json in place did not give the patched table")
        new_theme = render_theme(tokens, theme_path.read_text(encoding="utf-8"))
    except (TokenError, KeyError, TypeError, json.JSONDecodeError) as error:
        print("export_ui_tokens: patch refused, nothing written: %s" % error, file=sys.stderr)
        return 1
    for warning in warnings:
        print("export_ui_tokens: warning: %s" % warning, file=sys.stderr)
    for path, text in ((tokens_path, new_tokens), (languages_path, new_languages), (theme_path, new_theme)):
        write(path, text)
    print("\n".join(changes) if changes else "export_ui_tokens: the patch only tested values; nothing changed")
    return 0


def write(path: Path, text: str) -> None:
    """Writes ``text`` to ``path`` with "\\n" line ends through a temporary file and a rename, so a failed
    write never leaves half a file. Does nothing when the file already holds ``text``."""
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(text, encoding="utf-8", newline="\n")
    os.replace(temporary, path)


def main(argv: list[str]) -> int:
    """Runs one mode (see the module notes) and returns the exit status: 0 done, 1 out of date or refused."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="exit 1 when game_theme.tres or ui.tokens.json is out of date or unsound")
    mode.add_argument("--check-css", type=Path, metavar="FILE", help="exit 1 when FILE (mockups/shared/wo.css) writes a token value")
    mode.add_argument("--apply", type=Path, metavar="TUNE", help="apply the Tune panel's JSON Patch file, then regenerate the theme")
    parser.add_argument("--tokens", type=Path, default=TOKENS, help="token file (default: apps/game/ui/ui.tokens.json)")
    parser.add_argument("--theme", type=Path, default=THEME, help="theme to write or check (default: apps/game/assets/fonts/game_theme.tres)")
    parser.add_argument("--languages", type=Path, default=LANGUAGES, help="language table --apply may change (default: apps/game/i18n/languages.json)")
    args = parser.parse_args(argv)
    if args.check_css:
        try:
            css = args.check_css.read_text(encoding="utf-8")
        except OSError as error:
            print("export_ui_tokens: cannot read %s: %s" % (args.check_css, error), file=sys.stderr)
            return 1
        problems = css_problems(css)
        for line, problem in problems:
            print("%s:%d: %s (wo.css takes every value from var(--wo-...); brief 7.1)" % (args.check_css, line, problem), file=sys.stderr)
        return 1 if problems else 0
    if args.apply:
        return apply_patch(args.apply, args.tokens, args.languages, args.theme)
    try:
        text, tokens = read_tokens(args.tokens)
        problems = file_problems(tokens, text)
        if problems:
            raise TokenError("; ".join(problems))
        theme = args.theme.read_text(encoding="utf-8")
        rendered = render_theme(tokens, theme)
    except TokenError as error:
        print("export_ui_tokens: %s" % error, file=sys.stderr)
        return 1
    if args.check:
        if rendered != theme:
            print("game_theme.tres is out of date: run python3 scripts/export_ui_tokens.py and commit the result", file=sys.stderr)
            return 1
        return 0
    write(args.theme, rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
