#!/usr/bin/env python3
"""Check a Godot debug export and package it as one test-build zip with its licence notices.

Usage:
    python3 scripts/package_test_build.py macos   EXPORT.zip OUTPUT.zip NOTICES_DIR COMMIT
    python3 scripts/package_test_build.py windows EXPORT.exe OUTPUT.zip NOTICES_DIR COMMIT

Checks (any failure exits non-zero):
- the game pack holds the in-game changelog and the font licences, and none of the tests, tool or
  review drivers, art masters, trial assets, Markdown notes or the asset register;
- macOS: the app's executable keeps its executable bit and Godot's ad-hoc signature is present;
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

APP = "WOLF--OVERRIDE.app"
REQUIRED_IN_PACK = ["assets/changelog.txt", "assets/fonts/Roboto-OFL.txt", "assets/fonts/Montserrat-OFL.txt"]
FORBIDDEN_IN_PACK = re.compile(
    r"^(tests|tools|review|capture|trial|assets/trial|art-source)/|\.md$|^assets/manifest\.json$"
)
TESTING_URL = "https://wolfoverride.mrdemonwolf.dev/docs/development/testing/#test-builds"
CREDITS_URL = "https://wolfoverride.mrdemonwolf.dev/docs/credits/"
LEGAL_URL = "https://wolfoverride.mrdemonwolf.dev/docs/legal/"
SOURCE_URL = "https://github.com/MrDemonWolf/wolf-override/tree/{commit}"
GAME_LICENSE = Path(__file__).resolve().parent.parent / "LICENSE"


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
    unwanted = sorted(path for path in paths if FORBIDDEN_IN_PACK.search(path))
    if unwanted:
        fail(f"{label} pack holds files the game does not use at run time: {', '.join(unwanted)}")
    return len(paths)


def readme(platform: str, commit: str) -> str:
    built = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    target = "macOS (one app for Apple silicon and Intel Macs)" if platform == "macos" else "Windows (64-bit)"
    return f"""WOLF//OVERRIDE test build
Platform: {target}
Commit: {commit}
Built: {built}

This is an automatic DEBUG test build of the source game, made for testing while the game is in
development. It is not a release. The debug tools are on. It is not signed with a developer
certificate, so the system warns the first time you open it.

How to open it and what to report: {TESTING_URL}

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


def package_macos(export: Path, output: Path, notices: Path, commit: str) -> None:
    with zipfile.ZipFile(export) as archive:
        entries = {info.filename: info for info in archive.infolist()}
        binary = entries.get(f"{APP}/Contents/MacOS/WOLF--OVERRIDE")
        if binary is None or not (binary.external_attr >> 16) & 0o111:
            fail("the macOS app's executable is missing or lost its executable bit")
        if f"{APP}/Contents/_CodeSignature/CodeResources" not in entries:
            fail("the macOS app has no signature (Godot's built-in ad-hoc signing did not run)")
        files = check_pack(archive.read(f"{APP}/Contents/Resources/WOLF--OVERRIDE.pck"), "macOS")
    shutil.copyfile(export, output)
    # Appending leaves Godot's entries, their permission bits and the app's signature untouched.
    with zipfile.ZipFile(output, "a", compression=zipfile.ZIP_DEFLATED) as archive:
        add_notices(archive, notices, "macos", commit)
    print(f"macOS: {files} files in the pack; app signed ad hoc; wrote {output.name}")


def package_windows(export: Path, output: Path, notices: Path, commit: str) -> None:
    console = export.with_name(f"{export.stem}.console.exe")
    if not console.is_file():
        fail(f"missing the debug console wrapper {console.name}")
    files = check_pack(export.read_bytes(), "Windows")
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.write(export, export.name)
        archive.write(console, console.name)
        add_notices(archive, notices, "windows", commit)
    print(f"Windows: {files} files in the embedded pack; wrote {output.name}")


def main() -> None:
    if len(sys.argv) != 6 or sys.argv[1] not in ("macos", "windows"):
        fail("usage: package_test_build.py macos|windows EXPORT OUTPUT NOTICES_DIR COMMIT")
    platform, export, output, notices, commit = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]), sys.argv[5]
    if not export.is_file():
        fail(f"missing export {export}")
    (package_macos if platform == "macos" else package_windows)(export, output, notices, commit)


if __name__ == "__main__":
    main()
