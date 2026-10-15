"""Fix round 1: each door end's cross-wall against its own room's back wall AT THE SAME HEIGHT, in
render.sh 1280x720 -clean frames (luminance as review-real-r1/measure_walls.py: Rec.709 weights on sRGB
0..1; fine texture: std of L minus a 2 px Gaussian blur). Boxes are WORLD coordinates (x0, y0, x1, y1),
mapped through each shot's canvas transform (_run.json), on plain concrete away from fixtures, signs and
light pools, and plain back wall of the room on the same rows.
usage: measure_r2.py CAPTURE_DIR [CAPTURE_DIR_BEFORE]"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

W = np.array([0.2126, 0.7152, 0.0722])
ROWS = [
    ("Records exit, upper", "r04-copy-point", (802, 205, 838, 300), (262, 205, 458, 300)),
    ("Records exit, mid", "r04-copy-point", (812, 300, 840, 336), (262, 300, 458, 336)),
    ("Records entry, upper", "r03-arrival-closed", (88, 205, 140, 300), (262, 205, 458, 300)),
    ("Records entry, mid", "r03-arrival-closed", (100, 300, 140, 336), (262, 300, 458, 336)),
    ("Junction blast, upper", "j06-lane-sentry", (424, 175, 446, 290), (640, 175, 790, 290)),
    ("Junction blast, mid", "j06-lane-sentry", (424, 300, 446, 330), (640, 300, 790, 330)),
    ("Junction exit, upper", "j11-hatch-open", (872, 175, 915, 300), (640, 175, 790, 300)),
    ("Junction exit, upper, vs the back wall beside it under the same lamp", "j11-hatch-open", (872, 175, 915, 300), (800, 175, 860, 300)),
    ("Junction exit, mid", "j11-hatch-open", (872, 330, 900, 400), (640, 330, 790, 400)),
    ("Junction entry, upper", "r11-entry-shut", (62, 190, 110, 300), (232, 190, 400, 300)),
    ("Junction entry, mid", "r11-entry-shut", (62, 300, 110, 330), (232, 300, 400, 330)),
]


def load(cap, slug):
    run = json.load(open(os.path.join(cap, "_run.json")))
    shot = next(s for s in run["shots"] if s["slug"] == slug)
    a = np.asarray(Image.open(os.path.join(cap, f"{slug}-clean.png")).convert("RGB")).astype(float) / 255.0
    return (a * W).sum(-1), shot["canvas"]


def box(L, canvas, b):
    sc, tx, ty = canvas[0], canvas[4], canvas[5]
    k = 1280.0 / 960.0
    x0, y0, x1, y1 = [int(round(v)) for v in ((b[0] * sc + tx) * k, (b[1] * sc + ty) * k, (b[2] * sc + tx) * k, (b[3] * sc + ty) * k)]
    x0, x1 = max(x0, 0), min(x1, L.shape[1])
    y0, y1 = max(y0, 0), min(y1, L.shape[0])
    r = L[y0:y1, x0:x1]
    if r.size == 0:
        return float("nan"), float("nan")
    return float(np.median(r)), float((r - gaussian_filter(r, 2)).std())


def main():
    cap = sys.argv[1]
    print("| Piece (same rows) | frame | cross-wall L | room wall L | ratio | wall texture | room texture | ratio |")
    print("|---|---|---|---|---|---|---|---|")
    for name, slug, wb, rb in ROWS:
        try:
            L, cv = load(cap, slug)
        except (StopIteration, FileNotFoundError):
            continue
        wl, wt = box(L, cv, wb)
        rl, rt = box(L, cv, rb)
        print(f"| {name} | {slug} | {wl:.3f} | {rl:.3f} | {wl / rl:.2f} | {wt:.4f} | {rt:.4f} | {wt / rt:.2f} |")


if __name__ == "__main__":
    main()
