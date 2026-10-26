#!/usr/bin/env python3
"""Compares two parity capture folders (scripts/parity/run.sh capture) still by still.

Every run folder (<route>/<variant>/<size>) must have the same stills in the same order, the same
text.log (narration, hints, objective, cards and buttons by frame) and the same audio.log (SfxBank
calls by frame). Byte-identical PNGs count as 0 changed pixels without calling ImageMagick. Any other
pair is counted exactly: ImageMagick takes the per-channel difference of the colour channels and of
the alpha channels, keeps the largest per pixel, thresholds it at 0 and counts the pixels left (so a
1/255 change in one channel of one pixel counts as 1). `magick compare -metric AE` is not used for
the count: ImageMagick 7.1.2 prints a weighted, fractional AE (one pixel changed by 1/255 reads
0.0013), which is not a pixel count. Rectangles listed under a still's "masks" in shots.json (for
particles that cannot be seeded; the driver seeds all of them today, so the list is empty) are
painted out of both images first.

Thresholds (critique C3 of the lighter-game plan, which replaces the plan's 0.1% / 0.25% at fuzz 3%):
every still, in every variant, effects on or off, must have 0 changed pixels at fuzz 0.

Texture memory (RENDER_TEXTURE_MEM_USED, recorded per still by the driver in the render container)
is reported when it differs, as information: an IDENTICAL step may lower it.

Usage: python3 -I scripts/parity/compare.py <baseline dir> <candidate dir> [--diffs <dir>] [--jobs N] [--subset]
       python3 -I scripts/parity/compare.py --self-test
Exit status 0 only when everything is identical (or the self-test passes).
"""
import argparse
import concurrent.futures
import filecmp
import json
import os
import pathlib
import subprocess
import sys
import tempfile

PIXEL_LIMIT = 0
# Returned when two stills cannot be compared (different sizes, unreadable files).
INCOMPARABLE = 1 << 30


def runs(base: pathlib.Path) -> list[pathlib.Path]:
    return sorted(p.parent.relative_to(base) for p in base.glob("*/*/*/shots.json"))


def masked(path: pathlib.Path, masks: list, tmp: pathlib.Path) -> pathlib.Path:
    """path with every mask rectangle [x, y, w, h] (px) painted black, as a new PNG in tmp; path itself
    when there are no masks.

    Each call gets its own file from mkstemp. A name built from the still (its folder and file name)
    is the same for the baseline and the candidate, which share both, so the candidate's copy
    overwrote the baseline's and the candidate was compared with itself; the comparison threads also
    share tmp (Codex review finding M4)."""
    if not masks:
        return path
    handle, name = tempfile.mkstemp(suffix=".png", dir=tmp)
    os.close(handle)
    out = pathlib.Path(name)
    draw = [a for m in masks for a in ("-draw", "rectangle %d,%d %d,%d" % (m[0], m[1], m[0] + m[2] - 1, m[1] + m[3] - 1))]
    subprocess.run(["magick", str(path), "-fill", "black", *draw, str(out)], check=True)
    return out


def dimensions(path: pathlib.Path) -> str:
    r = subprocess.run(["magick", "identify", "-format", "%wx%h", str(path)], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


def changed_pixels(a: pathlib.Path, b: pathlib.Path, masks: list, diff_out: pathlib.Path | None, tmp: pathlib.Path) -> int:
    """The exact number of pixels whose colour or alpha differs at all between a and b."""
    if not masks and filecmp.cmp(a, b, shallow=False):
        return 0
    a2, b2 = masked(a, masks, tmp), masked(b, masks, tmp)
    size = dimensions(a2)
    if not size or size != dimensions(b2):
        return INCOMPARABLE
    r = subprocess.run([
        "magick",
        "(", str(a2), str(b2), "-alpha", "off", "-compose", "Difference", "-composite", "-separate", ")",
        "(", str(a2), str(b2), "-alpha", "extract", "-compose", "Difference", "-composite", ")",
        "-evaluate-sequence", "max", "-threshold", "0", "-format", "%[fx:round(mean*w*h)]", "info:",
    ], capture_output=True, text=True)
    try:
        count = int(r.stdout.strip())
    except ValueError:
        return INCOMPARABLE
    if diff_out and count:
        # A picture of where they differ, for a person to look at; the count above is the gate.
        diff_out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["magick", "compare", "-fuzz", "0", str(a2), str(b2), str(diff_out)], capture_output=True)
    return count


def texture_mb(meta: dict) -> tuple[float, float]:
    """Peak and last RENDER_TEXTURE_MEM_USED (MB) over a run's stills; -1 when not recorded."""
    values = [float(s["texture_mem_mb"]) for s in meta.get("shots", []) if "texture_mem_mb" in s]
    return (max(values), values[-1]) if values else (-1.0, -1.0)


def compare(baseline: pathlib.Path, candidate: pathlib.Path, diffs: pathlib.Path | None, jobs: int, subset: bool = False) -> int:
    base_runs, cand_runs = runs(baseline), runs(candidate)
    if subset:
        base_runs = [r for r in base_runs if r in cand_runs]
    ok = bool(base_runs)
    if not base_runs:
        print("no run folders (<route>/<variant>/<size>/shots.json) in %s" % baseline)
    if base_runs != cand_runs:
        print("run folders differ: only in baseline %s; only in candidate %s" % (sorted(set(base_runs) - set(cand_runs)), sorted(set(cand_runs) - set(base_runs))))
        ok = False
    total_shots = 0
    with tempfile.TemporaryDirectory() as tmpdir, concurrent.futures.ThreadPoolExecutor(jobs) as pool:
        tmp = pathlib.Path(tmpdir)
        for rel in [r for r in base_runs if r in cand_runs]:
            a_dir, b_dir = baseline / rel, candidate / rel
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
                if not (a_dir / log).exists() or not (b_dir / log).exists() or not filecmp.cmp(a_dir / log, b_dir / log, shallow=False):
                    problems.append("%s differs" % log)
            frames = (a_meta.get("frames"), b_meta.get("frames"))
            if frames[0] != frames[1]:
                problems.append("frame counts differ %s" % (frames,))
            futures = {}
            for a_shot, b_shot in zip(a_meta["shots"], b_meta["shots"]):
                if a_shot["file"] != b_shot["file"]:
                    continue
                masks = a_shot.get("masks", []) + b_shot.get("masks", [])
                diff_out = (diffs / rel / a_shot["file"]) if diffs else None
                futures[a_shot["file"]] = pool.submit(changed_pixels, a_dir / a_shot["file"], b_dir / b_shot["file"], masks, diff_out, tmp)
            counts = {f: j.result() for f, j in futures.items()}
            bad = {f: n for f, n in counts.items() if n > PIXEL_LIMIT}
            total_shots += len(futures)
            if bad:
                problems.append("%d stills with changed pixels (worst %d px): %s" % (len(bad), max(bad.values()), ", ".join("%s=%d" % kv for kv in sorted(bad.items())[:8])))
            info = ""
            a_tex, b_tex = texture_mb(a_meta), texture_mb(b_meta)
            if a_tex != b_tex:
                info = "; texture memory peak/last %.1f/%.1f MB -> %.1f/%.1f MB" % (a_tex + b_tex)
            status = "IDENTICAL" if not problems else "DIFFERENT"
            ok = ok and not problems
            logs_same = not any("log" in p for p in problems)
            print("%-9s %-28s %3d stills, text and audio logs %s%s%s" % (status, str(rel), len(futures), "same" if logs_same else "DIFFER", ("; " + "; ".join(problems)) if problems else "", info))
    print("%s: %d run folders, %d stills compared" % ("ALL IDENTICAL" if ok else "DIFFERENCES FOUND", len(base_runs), total_shots))
    return 0 if ok else 1


def self_test() -> int:
    """Checks the pixel count on known changes, and that one changed pixel fails a whole comparison."""
    failures = []
    with tempfile.TemporaryDirectory() as tmpdir:
        t = pathlib.Path(tmpdir)

        def make(name: str, *ops: str) -> pathlib.Path:
            path = t / name
            subprocess.run(["magick", *ops, "PNG32:" + str(path)], check=True)
            return path

        base = make("base.png", "-size", "96x54", "gradient:#204060-#80a0c0")
        # The red channel of pixel (5,5) one step (1/255) up, nothing else.
        one = make("one.png", str(base), "-channel", "R", "-fx", "i==5&&j==5?u+1/255:u", "+channel")
        cases = [
            ("re-encoded, same pixels", make("same.png", str(base), "-define", "png:compression-level=1"), 0),
            ("one channel of one pixel up by 1/255", one, 1),
            ("ten pixels set to white", make("ten.png", str(base), "-fill", "white", "-draw", "rectangle 0,0 4,1"), 10),
            ("alpha of one pixel halved", make("alpha.png", str(base), "-alpha", "set", "-channel", "A", "-fx", "i==7&&j==7?0.5:u", "+channel"), 1),
        ]
        for label, path, want in cases:
            got = changed_pixels(base, path, [], None, t)
            if got != want:
                failures.append("%s: counted %d, want %d" % (label, got, want))
        smaller = make("small.png", "-size", "48x27", "xc:black")
        if changed_pixels(base, smaller, [], None, t) != INCOMPARABLE:
            failures.append("different sizes were not reported as incomparable")
        def write_run(side: str, still: pathlib.Path, masks: list) -> pathlib.Path:
            """A one-run capture folder <side>/R0/kb-fx/96x54 whose first still is `still` with `masks`."""
            run = t / side / "R0" / "kb-fx" / "96x54"
            run.mkdir(parents=True)
            (run / "001-x.png").write_bytes(still.read_bytes())
            (run / "002-y.png").write_bytes(base.read_bytes())
            (run / "text.log").write_text("1\tx\ty\n")
            (run / "audio.log").write_text("\n")
            (run / "shots.json").write_text(json.dumps({"frames": 2, "failed": False, "shots": [{"file": "001-x.png", "masks": masks}, {"file": "002-y.png", "masks": []}]}))
            return t / side

        # A whole comparison: one changed pixel in one still must fail it.
        plain, changed = write_run("a", base, []), write_run("b", one, [])
        if compare(plain, changed, None, 2) != 1:
            failures.append("a run with one changed pixel compared as identical")
        if compare(plain, plain, None, 2) != 0:
            failures.append("a run compared against itself was not identical")
        # Masked stills: the same still names on both sides, so a shared temporary file would compare
        # the candidate with itself. A mask away from the changed pixel (5,5) must still fail the run;
        # one over it must pass.
        if compare(plain, write_run("c", one, [[0, 0, 2, 2]]), None, 2) != 1:
            failures.append("a masked run with one changed pixel outside the mask compared as identical")
        if compare(plain, write_run("d", one, [[5, 5, 1, 1]]), None, 2) != 0:
            failures.append("a run whose only changed pixel is masked was not identical")
    for f in failures:
        print("SELF-TEST FAIL: " + f)
    print("self-test %s" % ("failed" if failures else "passed: 1/255 in one channel of one pixel = 1, ten pixels = 10, alpha only = 1, re-encoded = 0, size mismatch fails, one changed pixel fails a run, masked or not, and a masked change passes"))
    return 1 if failures else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("baseline", type=pathlib.Path, nargs="?")
    ap.add_argument("candidate", type=pathlib.Path, nargs="?")
    ap.add_argument("--diffs", type=pathlib.Path, default=None, help="write magick difference images here")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--subset", action="store_true", help="compare only the run folders the candidate has (spot runs)")
    ap.add_argument("--self-test", action="store_true", help="check the pixel count on known changes")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    if args.baseline is None or args.candidate is None:
        ap.error("baseline and candidate folders are required")
    return compare(args.baseline, args.candidate, args.diffs, args.jobs, args.subset)


if __name__ == "__main__":
    sys.exit(main())
