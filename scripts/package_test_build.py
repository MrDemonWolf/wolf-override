#!/usr/bin/env python3
"""Check a Godot debug export and package it as one test-build zip with its licence notices.

Usage:
    python3 scripts/package_test_build.py macos   EXPORT.zip OUTPUT.zip NOTICES_DIR COMMIT
    python3 scripts/package_test_build.py windows EXPORT.exe OUTPUT.zip NOTICES_DIR COMMIT

Checks (any failure exits non-zero):
- the game pack holds the in-game changelog and the font licences, and none of the tests, tool or
  review drivers, art masters, trial assets, Markdown notes or the asset register;
- the game pack holds the language table and one catalog per offered language (localization PR L13);
- macOS: the app's executable keeps its executable bit and Godot's ad-hoc signature is present, and
  Contents/Resources holds exactly one <locale>.lproj folder per offered language, English included,
  which is what macOS and the Mac App Store read as the app's language list (PR L13);
- Windows: the pack is embedded in the .exe and the debug console wrapper sits beside it.

The notices (the game's GPL licence, Godot's, and the fonts') go in a licenses/ folder beside the
game, never inside the signed .app.
Standard library only.
"""

from __future__ import annotations

import re
import shutil
import struct
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

# Godot's macOS export names the app, its executable and its pack after application/config/name
# passed through OS::get_safe_dir_name (platform/macos/export/export_plugin.cpp, 4.7.2-stable), which
# keeps spaces and turns "/" into "-": "WOLF OVERRIDE" since 2026-10-17 (it was "WOLF--OVERRIDE").
EXE = "WOLF OVERRIDE"
APP = f"{EXE}.app"
REQUIRED_IN_PACK = ["assets/changelog.txt", "assets/fonts/Roboto-OFL.txt", "assets/fonts/Montserrat-OFL.txt"]
FORBIDDEN_IN_PACK = re.compile(
    r"^(tests|tools|review|capture|trial|assets/trial|art-source)/|\.md$|^assets/manifest\.json$"
)
# The site's one page on downloading and opening a test build (moved out of the testing page in October 2026).
TEST_BUILDS_URL = "https://wolfoverride.mrdemonwolf.dev/docs/test-builds/"
CREDITS_URL = "https://wolfoverride.mrdemonwolf.dev/docs/credits/"
LEGAL_URL = "https://wolfoverride.mrdemonwolf.dev/docs/legal/"
SOURCE_URL = "https://github.com/MrDemonWolf/wolf-override/tree/{commit}"
GAME_LICENSE = Path(__file__).resolve().parent.parent / "LICENSE"

# The one per-language table, read through the i18n tool so this script keeps no second reader or list
# (scripts/i18n/i18n_tool.py, LANGUAGES). python3 -I leaves the script's own folder off sys.path, so the
# tool's folder is added by hand, and no bytecode is written next to it (export-game.sh runs this without -B).
sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent / "i18n"))
from i18n_tool import LANGUAGES  # noqa: E402

# The table's own path inside the game pack (apps/game/i18n/languages.json): I18n reads it at start.
LANGUAGE_TABLE_IN_PACK = "i18n/languages.json"


def offered_languages() -> list[str]:
    """The languages the game offers: every languages.json code whose "enabled" is true, English included.

    tests/i18n_test.gd keeps this list equal to project.godot's registered catalogs, and Godot's macOS
    export writes one <locale>.lproj folder per registered catalog's locale plus en.lproj
    (platform/macos/export/export_plugin.cpp, 4.7.2-stable; measured on the 670b8ed test build), so the
    offered list is also the app's expected folder list.
    """
    return sorted(code for code, row in LANGUAGES.items() if row.get("enabled"))


def catalogs_in_pack() -> list[str]:
    """Pack paths of the offered languages' catalogs, i18n/<code>.po; English, the source, has none."""
    return [f"i18n/{code}.po" for code in offered_languages() if not LANGUAGES[code].get("source")]


def fail(message: str) -> None:
    print(f"package_test_build: {message}", file=sys.stderr)
    sys.exit(1)


def pack_paths(data: bytes) -> list[str]:
    """File paths in a Godot 4 pack, standalone or embedded at the end of an executable."""
    start = 0
    if data[:4] != b"GDPC":
        if data[-4:] != b"GDPC":
            fail("no Godot pack found")
        (size,) = struct.unpack_from("<Q", data, len(data) - 12)
        start = len(data) - 12 - size
    magic, version, _major, _minor, _patch, flags, _file_base, directory = struct.unpack_from("<4sIIIIIQQ", data, start)
    if magic != b"GDPC" or version not in (3, 4):
        fail(f"unsupported pack format {version}")
    if flags & 1:
        fail("the pack directory is encrypted; these checks need it readable")
    position = start + directory
    (count,) = struct.unpack_from("<I", data, position)
    position += 4
    paths = []
    for _ in range(count):
        (length,) = struct.unpack_from("<I", data, position)
        position += 4
        paths.append(data[position : position + length].rstrip(b"\0").decode("utf-8"))
        position += length + 8 + 8 + 16 + 4
    return paths


def check_pack(data: bytes, label: str) -> int:
    paths = [path.removeprefix("res://") for path in pack_paths(data)]
    missing = [path for path in REQUIRED_IN_PACK if path not in paths]
    if missing:
        fail(f"{label} pack is missing {', '.join(missing)} (check the preset's include filter)")
    languages = [path for path in [LANGUAGE_TABLE_IN_PACK, *catalogs_in_pack()] if path not in paths]
    if languages:
        fail(f"{label} pack is missing language files {', '.join(languages)} (check the preset's filters)")
    unwanted = sorted(path for path in paths if FORBIDDEN_IN_PACK.search(path))
    if unwanted:
        fail(f"{label} pack holds files the game does not use at run time: {', '.join(unwanted)}")
    return len(paths)


def readme(platform: str, commit: str) -> str:
    built = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    target = "macOS (one app for Apple silicon and Intel Macs)" if platform == "macos" else "Windows (64-bit)"
    return f"""WOLF OVERRIDE test build
Platform: {target}
Commit: {commit}
Built: {built}

This is an automatic DEBUG test build of the source game, made for testing while the game is in
development. It is not a release. The debug tools are on. It is not signed with a developer
certificate, so the system warns the first time you open it.

How to open it and what to report: {TEST_BUILDS_URL}

Original concept, core story and creative vision: Nathanial Henniges.
Credits, references and asset sources: {CREDITS_URL}

The game's code is free software under the GNU General Public License, version 3 or later
(WOLF-OVERRIDE-LICENSE.txt in this folder). Its source for this exact build:
{SOURCE_URL.format(commit=commit)}

The art and other media have separate rights from the code. The GPL does not grant a licence to
reuse them; their sources and status are listed on the legal page: {LEGAL_URL}

This folder holds the licence notices for software and fonts inside the build:
- WOLF-OVERRIDE-LICENSE.txt: the game's code (GNU GPL version 3 or later)
- GODOT_LICENSE.txt: Godot Engine (MIT licence), https://godotengine.org/license
- GODOT_COPYRIGHT.txt: the third-party components inside Godot Engine
- Roboto-OFL.txt and Montserrat-OFL.txt: the game's typefaces (SIL Open Font License 1.1)
"""


def add_notices(archive: zipfile.ZipFile, notices: Path, platform: str, commit: str) -> None:
    for name in ["GODOT_LICENSE.txt", "GODOT_COPYRIGHT.txt", "Roboto-OFL.txt", "Montserrat-OFL.txt"]:
        source = notices / name
        if not source.is_file():
            fail(f"missing notice {source}")
        archive.write(source, f"licenses/{name}")
    if not GAME_LICENSE.is_file():
        fail(f"missing the game's licence {GAME_LICENSE}")
    archive.write(GAME_LICENSE, "licenses/WOLF-OVERRIDE-LICENSE.txt")
    info = zipfile.ZipInfo("licenses/README.txt", datetime.now(timezone.utc).timetuple()[:6])
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    archive.writestr(info, readme(platform, commit))


def check_lproj(entries: dict[str, zipfile.ZipInfo]) -> list[str]:
    """The app's .lproj folder names, checked against the offered languages; returns the locales found.

    A missing folder hides a language from macOS's per-app language setting and the App Store's list; an
    extra one advertises a language the game does not offer. Each folder must hold InfoPlist.strings,
    the file Godot writes into it.
    """
    prefix = f"{APP}/Contents/Resources/"
    found = sorted({name[len(prefix) :].split("/")[0].removesuffix(".lproj") for name in entries
                    if name.startswith(prefix) and name[len(prefix) :].split("/")[0].endswith(".lproj")})
    expected = offered_languages()
    if found != expected:
        fail(f"the macOS app's .lproj folders are {found}, but the offered languages are {expected}")
    empty = [code for code in found if f"{prefix}{code}.lproj/InfoPlist.strings" not in entries]
    if empty:
        fail(f"the macOS app's .lproj folders lack InfoPlist.strings: {', '.join(empty)}")
    return found


def package_macos(export: Path, output: Path, notices: Path, commit: str) -> None:
    with zipfile.ZipFile(export) as archive:
        entries = {info.filename: info for info in archive.infolist()}
        binary = entries.get(f"{APP}/Contents/MacOS/{EXE}")
        if binary is None or not (binary.external_attr >> 16) & 0o111:
            fail("the macOS app's executable is missing or lost its executable bit")
        if f"{APP}/Contents/_CodeSignature/CodeResources" not in entries:
            fail("the macOS app has no signature (Godot's built-in ad-hoc signing did not run)")
        files = check_pack(archive.read(f"{APP}/Contents/Resources/{EXE}.pck"), "macOS")
        locales = check_lproj(entries)
    shutil.copyfile(export, output)
    # Appending leaves Godot's entries, their permission bits and the app's signature untouched.
    with zipfile.ZipFile(output, "a", compression=zipfile.ZIP_DEFLATED) as archive:
        add_notices(archive, notices, "macos", commit)
    print(f"macOS: {files} files in the pack; app signed ad hoc; .lproj for {', '.join(locales)}; wrote {output.name}")


def package_windows(export: Path, output: Path, notices: Path, commit: str) -> None:
    console = export.with_name(f"{export.stem}.console.exe")
    if not console.is_file():
        fail(f"missing the debug console wrapper {console.name}")
    files = check_pack(export.read_bytes(), "Windows")
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.write(export, export.name)
        archive.write(console, console.name)
        add_notices(archive, notices, "windows", commit)
    print(f"Windows: {files} files in the embedded pack, {len(catalogs_in_pack())} catalogs; wrote {output.name}")


def main() -> None:
    if len(sys.argv) != 6 or sys.argv[1] not in ("macos", "windows"):
        fail("usage: package_test_build.py macos|windows EXPORT OUTPUT NOTICES_DIR COMMIT")
    platform, export, output, notices, commit = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]), sys.argv[5]
    if not export.is_file():
        fail(f"missing export {export}")
    (package_macos if platform == "macos" else package_windows)(export, output, notices, commit)


if __name__ == "__main__":
    main()
