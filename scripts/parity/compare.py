#!/usr/bin/env python3
"""Compares two parity capture folders (scripts/parity/run.sh capture) still by still.

Every run folder (<route>/<variant>/<size>) must have the same stills in the same order, the same
text.log (narration, hints, objective, cards and buttons by frame) and the same audio.log (SfxBank
calls by frame). Each pair of stills is compared with ImageMagick: `magick compare -metric AE
-fuzz 0`, counting differing pixels. Byte-identical PNGs count as AE 0 without calling magick.
Rectangles listed under a still's "masks" in shots.json (for particles that cannot be seeded; the
driver seeds all of them today, so the list is empty) are painted out of both images first.

Thresholds (critique C3 of the lighter-game plan, which replaces the plan's 0.1% / 0.25% at fuzz 3%):
every still, in every variant, effects on or off, must have AE 0 at fuzz 0.

Usage: python3 -I scripts/parity/compare.py <baseline dir> <candidate dir> [--diffs <dir>] [--jobs N]
Exit status 0 only when everything is identical. A summary is printed per run folder.
"""
import argparse
import concurrent.futures
import filecmp
import json
import pathlib
import subprocess
import sys
import tempfile

AE_LIMIT = 0


def runs(base: pathlib.Path) -> list[pathlib.Path]:
    return sorted(p.parent.relative_to(base) for p in base.glob("*/*/*/shots.json"))


def masked(path: pathlib.Path, masks: list, tmp: pathlib.Path) -> pathlib.Path:
    if not masks:
        return path
    out = tmp / (path.parent.name + "-" + path.name)
    draw = [a for m in masks for a in ("-draw", "rectangle %d,%d %d,%d" % (m[0], m[1], m[0] + m[2] - 1, m[1] + m[3] - 1))]
    subprocess.run(["magick", str(path), "-fill", "black", *draw, str(out)], check=True)
    return out


def ae(a: pathlib.Path, b: pathlib.Path, masks: list, diff_out: pathlib.Path | None, tmp: pathlib.Path) -> int:
    if not masks and filecmp.cmp(a, b, shallow=False):
        return 0
    a2, b2 = masked(a, masks, tmp), masked(b, masks, tmp)
    target = str(diff_out) if diff_out else "null:"
    if diff_out:
        diff_out.parent.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(["magick", "compare", "-metric", "AE", "-fuzz", "0", str(a2), str(b2), target], capture_output=True, text=True)
    text = (r.stderr or r.stdout).strip().split()[0] if (r.stderr or r.stdout).strip() else ""
    try:
        return int(float(text))
    except ValueError:
        # Different image sizes and other errors: count every pixel as different.
        return 1 << 30


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("baseline", type=pathlib.Path)
    ap.add_argument("candidate", type=pathlib.Path)
    ap.add_argument("--diffs", type=pathlib.Path, default=None, help="write magick difference images here")
    ap.add_argument("--jobs", type=int, default=6)
    args = ap.parse_args()
    base_runs, cand_runs = runs(args.baseline), runs(args.candidate)
    ok = True
    if base_runs != cand_runs:
        print("run folders differ: only in baseline %s; only in candidate %s" % (sorted(set(base_runs) - set(cand_runs)), sorted(set(cand_runs) - set(base_runs))))
        ok = False
    total_shots = 0
    with tempfile.TemporaryDirectory() as tmpdir, concurrent.futures.ThreadPoolExecutor(args.jobs) as pool:
        tmp = pathlib.Path(tmpdir)
        for rel in [r for r in base_runs if r in cand_runs]:
            a_dir, b_dir = args.baseline / rel, args.candidate / rel
            a_meta = json.loads((a_dir / "shots.json").read_text())
            b_meta = json.loads((b_dir / "shots.json").read_text())
            problems = []
            for meta, label in ((a_meta, "baseline"), (b_meta, "candidate")):
                if meta.get("failed"):
                    problems.append("%s run failed: %s" % (label, meta.get("notes")))
            a_files = [s["file"] for s in a_meta["shots"]]
            b_files = [s["file"] for s in b_meta["shots"]]
            if a_files != b_files:
                problems.append("still lists differ (%d vs %d)" % (len(a_files), len(b_files)))
            for log in ("text.log", "audio.log"):
                if not filecmp.cmp(a_dir / log, b_dir / log, shallow=False):
                    problems.append("%s differs" % log)
            frames = (a_meta.get("frames"), b_meta.get("frames"))
            if frames[0] != frames[1]:
                problems.append("frame counts differ %s" % (frames,))
            jobs = {}
            for a_shot, b_shot in zip(a_meta["shots"], b_meta["shots"]):
                if a_shot["file"] != b_shot["file"]:
                    continue
                masks = a_shot.get("masks", []) + b_shot.get("masks", [])
                diff_out = (args.diffs / rel / a_shot["file"]) if args.diffs else None
                jobs[a_shot["file"]] = pool.submit(ae, a_dir / a_shot["file"], b_dir / b_shot["file"], masks, diff_out, tmp)
            bad = {f: j.result() for f, j in jobs.items() if j.result() > AE_LIMIT}
            total_shots += len(jobs)
            worst = max(bad.values()) if bad else 0
            if bad:
                problems.append("%d stills over AE %d (worst %d px): %s" % (len(bad), AE_LIMIT, worst, ", ".join("%s=%d" % kv for kv in sorted(bad.items())[:8])))
            status = "IDENTICAL" if not problems else "DIFFERENT"
            ok = ok and not problems
            print("%-9s %-28s %3d stills, text and audio logs %s%s" % (status, str(rel), len(jobs), "same" if not any("log" in p for p in problems) else "DIFFER", ("; " + "; ".join(problems)) if problems else ""))
    print("%s: %d run folders, %d stills compared" % ("ALL IDENTICAL" if ok else "DIFFERENCES FOUND", len(base_runs), total_shots))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
