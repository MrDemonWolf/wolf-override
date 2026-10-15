"""Filed this folder's layout on October 14-15, 2026, before the October 15 consolidation (one copy of each
tool; see ../README.md, "Tool map"): the put() mapping below is evidence of what was filed where, and is
not rewritten. Several of the paths it writes (the fix rounds' copies, integration/, fix-r*/doors-section.md,
junction-entry/NOTES-fix-r*.md) no longer exist; the tool map cites each by commit.

Copy the doors' design records from the scratch folder into the repository (no captures, no caches,
no copies of copyrighted standards), rewriting scratch and home paths to relative ones.
usage: file_records.py SCRATCH_DOORS_R1 LAND_DOORS DEST
"""
import os
import re
import shutil
import sys

src, land, dest = sys.argv[1:4]
SCRATCH = os.path.dirname(src.rstrip("/"))
HOME = os.path.expanduser("~")
TEXT = {".py", ".md", ".json", ".sh", ".gd", ".txt", ".tmpl"}


def clean_text(s: str) -> str:
    s = s.replace(src.rstrip("/") + "/", "doors-r1/")
    s = s.replace(SCRATCH + "/land-doors/", "land-doors/")
    s = s.replace(SCRATCH + "/", "scratch/")
    s = s.replace(SCRATCH, "scratch")
    s = s.replace(HOME + "/Developer/mrdemonwolf/wolf-override/", "")
    s = s.replace(HOME, "~")
    s = re.sub(r"/private/tmp/claude-\d+/[^\s\"']*", "scratch", s)
    return s


def put(rel_src: str, rel_dest: str, base: str = src) -> None:
    p = os.path.join(base, rel_src)
    if not os.path.isfile(p):
        print("missing", p)
        return
    q = os.path.join(dest, rel_dest)
    os.makedirs(os.path.dirname(q), exist_ok=True)
    if os.path.splitext(p)[1] in TEXT:
        with open(p, encoding="utf-8", errors="strict") as f:
            text = f.read()
        with open(q, "w", encoding="utf-8") as f:
            f.write(clean_text(text))
    else:
        shutil.copyfile(p, q)


def tree(rel_src: str, rel_dest: str, exts=TEXT, base: str = src) -> None:
    root = os.path.join(base, rel_src)
    for d, dirs, files in os.walk(root):
        dirs[:] = [x for x in dirs if x not in ("__pycache__",)]
        for f in files:
            if os.path.splitext(f)[1] in exts:
                r = os.path.relpath(os.path.join(d, f), root)
                put(os.path.join(rel_src, r), os.path.join(rel_dest, r), base)


# The running record, the reviews and provenance.
put("shots/DOORS.md", "DOORS.md")
put("provenance.txt", "provenance.txt")
for who in ("real", "human"):
    for n in range(1, 6):
        put(f"shots/REVIEW-{who}-r{n}.md", f"reviews/REVIEW-{who}-r{n}.md")
put("shots/perf.json", "reviews/perf-package.json")
# The tracks: notes, design specs, placement and tools (round 1 as built).
put("records/NOTES.md", "records/NOTES.md")
tree("records/design", "records/design", {".json"})
put("records/out/placement.json", "records/placement.json")
tree("records/tools", "records/tools")
put("junction/NOTES.md", "junction/NOTES.md")
put("junction/design/spec.json", "junction/design/spec.json")
put("junction/layers/final/placement.json", "junction/placement.json")
tree("junction/tools", "junction/tools")
put("hatch/NOTES.md", "junction-exit/NOTES.md")
put("hatch/placement.json", "junction-exit/placement.json")
put("hatch/design/v6/spec.json", "junction-exit/design/v6/spec.json")
tree("hatch/tools", "junction-exit/tools")
put("hatch/templates/junction_room.gd.tmpl", "junction-exit/templates/junction_room.gd.tmpl")
for n in (1, 2, 3):
    put(f"fix-r{n}/jentry/NOTES.md", f"junction-entry/NOTES-fix-r{n}.md")
tree("fix-r3/jentry/tools", "junction-entry/tools")
tree("fix-r3/jentry/design", "junction-entry/design", {".json"})
# Each fix round's own tools, notes and capture driver (as the round packaged them).
for n in (1, 2, 3, 4):
    tree(f"shots/fix-r{n}-tools", f"fix-r{n}")
    put(f"fix-r{n}/doors-section.md", f"fix-r{n}/doors-section.md")
# Fix round 1 re-built the entry door and the exit door with their own tools (cited by the register).
tree("fix-r1/jentry/tools", "fix-r1/jentry/tools")
tree("fix-r1/hatch/tools", "fix-r1/hatch/tools")
tree("fix-r3/tools", "fix-r3/tools")
tree("fix-r4/tools", "fix-r4/tools")
tree("shots/integration-tools", "integration")
# The Codex jobs: prompts and session notes for every job; the raw outputs behind the shipped atlases
# (fix round 2's paints; rounds 3 and 4 ran no Codex session), byte for byte with their C2PA.
for job in sorted(os.listdir(os.path.join(src, "codex"))):
    jd = os.path.join("codex", job)
    for f in ("prompt.txt", "session.txt", "started.txt", "finished.txt"):
        put(os.path.join(jd, f), os.path.join(jd, f))
    put(os.path.join(jd, "out", "notes.txt"), os.path.join(jd, "out", "notes.txt"))
    if job.startswith("r2-"):
        out = os.path.join(src, jd, "out")
        for f in sorted(os.listdir(out)):
            if f.endswith(".png"):
                put(os.path.join(jd, "out", f), os.path.join(jd, "out", f))
# The landing (this work).
tree("tools", "landing/tools", base=land)
tree("driver", "landing/driver", base=land)
tree("driver2", "landing/driver2", base=land)
for f in ("render.sh", "suite.sh", "sheet.py", "file_records.py", "perf.py", "compare.py"):
    put(f, os.path.join("landing", f), base=land)
print("filed into", dest)
