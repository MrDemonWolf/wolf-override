"""Fix round 2 (N3): closes the wall grade on a render.sh pass (see grade2.FEEDBACK). Scratch only.
usage: feedback.py FRAMES_DIR   (updates measure/feedback.json cumulatively)"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grade2 as G  # noqa: E402
import measure3 as M3  # noqa: E402


def main():
    frames = sys.argv[1]
    run = json.load(open(os.path.join(frames, "_run.json")))
    shots = {s["slug"]: s for s in run["shots"]}
    try:
        fb = json.load(open(G.FEEDBACK))
    except (OSError, ValueError):
        fb = {}
    for end, (slug, bx, wx) in G.REFS.items():
        s = shots[slug]
        L = M3.lin_lum(os.path.join(frames, f"{slug}-clean.png"))
        sc, tx, ty = s["canvas"][0], s["canvas"][4], s["canvas"][5]
        k = run["size"][0] / 960.0
        ys = np.arange(150.0, 431.0, 1.0)
        f = np.full(len(ys), np.nan)
        for i, y in enumerate(ys):
            sy = int(round((y * sc + ty) * k))
            if not 0 <= sy < L.shape[0]:
                continue
            def med(xr):
                a, b = [int(round((x * sc + tx) * k)) for x in xr]
                a, b = max(a, 0), min(b, L.shape[1])
                return float(np.median(L[sy, a:b])) if b - a >= 3 else np.nan
            bm, wm = med(bx), med(wx)
            if bm > 0 and wm > 0:
                f[i] = G.RATIO * bm / wm
        good = ~np.isnan(f)
        if good.sum() < 10:
            continue
        f = np.interp(ys, ys[good], f[good])
        sig = 4.0 if end == "junction-exit" else 10.0
        # clamped: where the back box is the ceiling's dark void, the floor rule (grade2.FLOOR_FRAC) holds the face up
        f = np.exp(ndimage.gaussian_filter1d(np.log(np.clip(f, 0.5, 2.5)), sig, mode="nearest"))
        prev = fb.get(end)
        if prev:
            f = f * np.interp(ys, prev["ys"], prev["factor"])
        f = np.clip(f, 0.5, 2.5)  # cumulative bound: the floor rule holds over passes too
        fb[end] = {"ys": ys.tolist(), "factor": [round(float(v), 4) for v in f], "from": frames}
        print(end, "factor at 160/250/340/420:", [round(float(np.interp(y, ys, f)), 2) for y in (160, 250, 340, 420)])
    json.dump(fb, open(G.FEEDBACK, "w"))


if __name__ == "__main__":
    main()
