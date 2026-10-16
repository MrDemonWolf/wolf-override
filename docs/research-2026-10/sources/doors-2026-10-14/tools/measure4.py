"""Fix round 2 (review r2, N3): one light logic, measured. Scratch only.

1. Walls at the corner (measure3.py's boxes: the cross-wall face just on its side of the corner against the
   room's back wall just on the room side, same world rows), linear luminance; texture = std of a 3 px
   high-pass. Target: ratio 0.45-0.75, texture ratio >= 0.5.
2. The reviewer's own boxes at the junction exit (j08, 1280 px screen: back wall x 940-985 against the
   cross-wall face x 995-1040, rows 100-140, 180-220, 260-300, 340-380).
3. Leaves against their walls: the leaf's pixels are where the frame and its leaf-hidden twin differ
   (the driver's *-noleaf frames); its median against the cross-wall's median at the door's rows (world
   y 330-430) in the same frame. Target: painted steel at or below the concrete (<= 1.0).
4. Plain-wall medians for scale against the approved corridor wall (0.018, review r2).
usage: measure4.py FRAMES_DIR LABEL   writes FRAMES_DIR/../light-LABEL.{json,md}"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import measure3 as M3  # noqa: E402

# frame, its leaf-hidden twin, and the world window round the door the leaf can be in (so an actor's idle
# motion or a flickering light between the two frames never counts as leaf)
LEAVES = {
    "records-entry": ("r01-arrival", "r01-noleaf", (40.0, 170.0)),
    "records-exit": ("r07-exit-open", "r07-noleaf", (780.0, 910.0)),
    "junction-entry": ("r09-after-leaving", "r09-noleaf", (0.0, 70.0)),
    "junction-blast": ("j01-sealed", "j01-noleaf", (440.0, 500.0)),
    "junction-exit": ("j08-exit-bolt", "j08-noleaf", (920.0, 1000.0)),
}
REVIEW_J08 = {"back": (940, 985), "wall": (995, 1040), "rows": [(100, 140), (180, 220), (260, 300), (340, 380)]}


def screen_box(s, size, xr, yr, shape):
    sc, tx, ty = s["canvas"][0], s["canvas"][4], s["canvas"][5]
    k = size[0] / 960.0
    x0, x1 = [int(round((x * sc + tx) * k)) for x in xr]
    y0, y1 = [int(round((y * sc + ty) * k)) for y in yr]
    return max(x0, 0), max(y0, 0), min(x1, shape[1]), min(y1, shape[0])


def main():
    frames, label = sys.argv[1], sys.argv[2]
    out = {"walls": M3.measure(frames), "review_j08": [], "leaves": {}}
    lines = ["### Walls at the corner (linear; target ratio 0.45-0.75, texture ratio >= 0.5)", "",
             "| Door end | Rows (world y) | Back wall | Cross-wall | Ratio | Texture wall / back | Texture ratio | Wall texture / its median (approved corridor wall: 0.22) |", "|---|---|---|---|---|---|---|---|"]
    for end, r in out["walls"].items():
        for row in r["rows"]:
            lines.append(f"| {end} ({r['frame']}) | {row['rows'][0]:.0f}-{row['rows'][1]:.0f} | {row['back']['median']:.4f} | {row['wall']['median']:.4f} | **{row['ratio']:.2f}** | {row['wall']['texture']:.4f} / {row['back']['texture']:.4f} | {row['texture_ratio']:.2f} | {row['wall']['texture'] / max(row['wall']['median'], 1e-6):.2f} |")
    p = os.path.join(frames, "j08-exit-bolt-clean.png")
    if os.path.exists(p):
        L = M3.lin_lum(p)
        hp = L - ndimage.uniform_filter(L, 3)
        lines += ["", "### The reviewer's junction-exit boxes (j08, screen px)", "", "| Rows | Back wall x 940-985 | Cross-wall x 995-1040 | Ratio |", "|---|---|---|---|"]
        for (y0, y1) in REVIEW_J08["rows"]:
            b = float(np.median(L[y0:y1, 940:985]))
            w = float(np.median(L[y0:y1, 995:1040]))
            out["review_j08"].append({"rows": [y0, y1], "back": b, "wall": w, "ratio": w / max(b, 1e-6)})
            lines.append(f"| {y0}-{y1} | {b:.4f} | {w:.4f} | **{w / max(b, 1e-6):.2f}** |")
    lines += ["", "### Leaves against their walls (linear; target <= 1.0)", "", "| Door end | Frame | Leaf median | Wall median (door rows) | Leaf / wall |", "|---|---|---|---|---|"]
    run = json.load(open(os.path.join(frames, "_run.json")))
    shots = {s["slug"]: s for s in run["shots"]}
    for end, (a, b, win) in LEAVES.items():
        pa, pb = os.path.join(frames, f"{a}-clean.png"), os.path.join(frames, f"{b}-clean.png")
        if not (os.path.exists(pa) and os.path.exists(pb)):
            continue
        A = np.asarray(Image.open(pa).convert("RGB")).astype(int)
        B = np.asarray(Image.open(pb).convert("RGB")).astype(int)
        m = np.abs(A - B).sum(-1) > 18
        m = ndimage.binary_erosion(ndimage.binary_opening(m, iterations=1), iterations=1)
        wx0, wy0, wx1, wy1 = screen_box(shots[a], run["size"], win, (300.0, 445.0), m.shape)
        keep = np.zeros_like(m)
        keep[wy0:wy1, wx0:wx1] = True
        m &= keep
        L = M3.lin_lum(pa)
        if m.sum() < 30:
            continue
        leaf = float(np.median(L[m]))
        s = shots[a]
        wx = M3.ENDS[end][2]
        x0, y0, x1, y1 = screen_box(s, run["size"], wx, (330.0, 430.0), L.shape)
        wall = float(np.median(L[y0:y1, x0:x1])) if x1 > x0 and y1 > y0 else float("nan")
        out["leaves"][end] = {"frame": a, "leaf_px": int(m.sum()), "leaf": leaf, "wall": wall, "ratio": leaf / max(wall, 1e-6)}
        lines.append(f"| {end} | {a} | {leaf:.4f} | {wall:.4f} | **{leaf / max(wall, 1e-6):.2f}** |")
    base = os.path.dirname(frames.rstrip("/"))
    json.dump(out, open(os.path.join(base, f"light-{label}.json"), "w"), indent=1)
    open(os.path.join(base, f"light-{label}.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
