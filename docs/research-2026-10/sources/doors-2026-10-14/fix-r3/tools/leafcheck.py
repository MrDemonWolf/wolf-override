"""Fix round 3 (review r3, R3-2): each open swing leaf against the far-jamb reveal it hangs on. Scratch only.

An open leaf (90 degrees) and its far-jamb reveal face the same way, and the door light over the head
lights both at nearly the same angle, so at the head next to the hinge the painted steel leaf should read
about as the painted steel reveal does (target 0.7-1.0), falling toward the free edge; where the door light
does not reach (the free edge, low down) it should sit at or below the concrete beside the door.

The leaf's pixels are where the frame and its leaf-hidden twin differ. Zones, in screen px:
  head-hinge  leaf pixels within HINGE_PX of the leaf's hinge-side edge, in its top 4-22 % of rows;
  reveal      the 3-10 px just beyond that edge (the reveal), the same rows, from the leaf-hidden frame;
  free-low    leaf pixels within HINGE_PX of its free edge, in its bottom 4-22 % of rows;
  wall-low    the cross-wall beside the door at those rows (measure3.ENDS columns).
Also the fine texture of the leaf (std of a 3 px high-pass in linear light over its median; review r3's
leafflat.py metric), target >= 0.12.

usage: leafcheck.py FRAMES_DIR [OUT_JSON]  -> prints a table; exit 1 if any open leaf misses a target."""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import measure3 as M3  # noqa: E402
import measure4 as M4  # noqa: E402

HINGE_PX = 6
# frame, leaf-hidden twin, world x window, the side the hinge is on (+1 right, -1 left)
LEAVES = {
    "records-entry": ("r01-arrival", "r01-noleaf", (40.0, 170.0), -1),
    "records-exit": ("r07-exit-open", "r07-noleaf", (780.0, 910.0), 1),
    "junction-entry": ("r09-after-leaving", "r09-noleaf", (0.0, 70.0), -1),
}
# The leaves as the game models them (SwingLeaf; RecordsRoom / JunctionRoom constants): hinge foot (m),
# the wall's U and N, the room's camera. The leaf's outline at 90 degrees is projected exactly; inside it,
# pixels the actors cover (the same in both frames) are left out.
MODEL = {
    "records-entry": ((1.89549, 0.0, 0.43655), (0.291329, 0.0, 0.956623), (-0.956623, 0.0, 0.291329), 483.9, 158.5),
    "records-exit": ((21.85451, 0.0, 0.43655), (-0.291329, 0.0, 0.956623), (0.956623, 0.0, 0.291329), 483.9, 158.5),
    "junction-entry": ((0.89597, 0.0, 0.43639), (0.292372, 0.0, 0.956305), (-0.956305, 0.0, 0.292372), 511.0, 162.0),
}
LEAF_W, LEAF_H, LEAF_T, LEAF_BOTTOM = 0.914, 2.134, 0.044, 0.010


def leaf_outline(end, shot, size, shape):
    from PIL import ImageDraw
    h, u, n, vpx, hor = (np.array(v) if isinstance(v, tuple) else v for v in MODEL[end])
    th = np.pi / 2
    d = -u * np.cos(th) - n * np.sin(th)
    nr = -n * np.cos(th) + u * np.sin(th)
    base = h if nr[2] < 0 else h - nr * LEAF_T

    def proj(p):
        s = 38.0 / (38.0 + p[2])
        wx, wy = vpx + (p[0] * 40.0 - vpx) * s, hor + (440.0 - hor) * s - p[1] * 40.0 * s
        sc, tx, ty = shot["canvas"][0], shot["canvas"][4], shot["canvas"][5]
        kk = size[0] / 960.0
        return ((wx * sc + tx) * kk, (wy * sc + ty) * kk)
    up = np.array([0.0, 1.0, 0.0])
    pts = [proj(base + up * LEAF_BOTTOM), proj(base + d * LEAF_W + up * LEAF_BOTTOM), proj(base + d * LEAF_W + up * (LEAF_BOTTOM + LEAF_H)), proj(base + up * (LEAF_BOTTOM + LEAF_H))]
    im = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(im).polygon(pts, fill=255)
    return np.asarray(im) > 0
TARGET = (0.7, 1.0)
TEX_MIN = 0.12


def zones(m, side):
    ys, xs = np.nonzero(m)
    y0, y1 = ys.min(), ys.max()
    H = y1 - y0 + 1
    head = np.zeros_like(m)
    low = np.zeros_like(m)
    rev = np.zeros_like(m)
    for y in range(y0 + int(0.04 * H), y0 + int(0.22 * H) + 1):
        row = np.nonzero(m[y])[0]
        if len(row) < 2 * HINGE_PX:
            continue
        if side > 0:
            e = row.max()
            head[y, e - HINGE_PX + 1:e + 1] = True
            rev[y, e + 3:e + 11] = True
        else:
            e = row.min()
            head[y, e:e + HINGE_PX] = True
            rev[y, max(e - 10, 0):max(e - 2, 0)] = True
    for y in range(y1 - int(0.22 * H), y1 - int(0.04 * H) + 1):
        row = np.nonzero(m[y])[0]
        if len(row) < 2 * HINGE_PX:
            continue
        if side > 0:
            f = row.min()
            low[y, f:f + HINGE_PX] = True
        else:
            f = row.max()
            low[y, f - HINGE_PX + 1:f + 1] = True
    return head & m, rev & ~m, low & m, (y0, y1)


def main():
    frames = sys.argv[1]
    run = json.load(open(os.path.join(frames, "_run.json")))
    shots = {s["slug"]: s for s in run["shots"]}
    out = {}
    ok = True
    lines = ["| Door | Frame | Head by hinge | Reveal | Leaf / reveal | Free edge low | Wall at those rows | Free low / wall | Leaf texture |", "|---|---|---|---|---|---|---|---|---|"]
    for end, (a, b, win, side) in LEAVES.items():
        pa, pb = os.path.join(frames, f"{a}-clean.png"), os.path.join(frames, f"{b}-clean.png")
        A = np.asarray(Image.open(pa).convert("RGB")).astype(int)
        B = np.asarray(Image.open(pb).convert("RGB")).astype(int)
        outline = ndimage.binary_erosion(leaf_outline(end, shots[a], run["size"], A.shape[:2]), iterations=1)
        same = np.abs(A - B).sum(-1) <= 2
        m = outline & ~ndimage.binary_dilation(same & ndimage.binary_opening(same, iterations=2), iterations=1)
        La = M3.lin_lum(pa)
        Lb = M3.lin_lum(pb)
        head, rev, low, (y0, y1) = zones(m, side)
        lh, lr, ll = float(np.median(La[head])), float(np.median(Lb[rev])), float(np.median(La[low]))
        s = shots[a]
        wx = M3.ENDS[end][2]
        # the wall at the free-low rows
        ly = np.nonzero(low.any(1))[0]
        x0, _, x1, _ = M4.screen_box(s, run["size"], wx, (330.0, 430.0), La.shape)
        wl = float(np.median(La[ly.min():ly.max() + 1, x0:x1]))
        inner = ndimage.binary_erosion(m, iterations=2)
        hp = La - ndimage.uniform_filter(La, 3)
        tex = float(np.std(hp[inner]) / max(np.median(La[inner]), 1e-6))
        r_hr, r_lw = lh / max(lr, 1e-6), ll / max(wl, 1e-6)
        good = TARGET[0] <= r_hr <= TARGET[1] + 0.05 and r_lw <= 1.0 and tex >= TEX_MIN
        ok &= good
        out[end] = {"frame": a, "leaf_rows_screen": [int(y0), int(y1)], "head_hinge": lh, "reveal": lr, "leaf_over_reveal": r_hr,
                    "free_low": ll, "wall_low": wl, "free_low_over_wall": r_lw, "texture": tex, "pass": bool(good)}
        lines.append(f"| {end} | {a} | {lh:.4f} | {lr:.4f} | **{r_hr:.2f}** | {ll:.4f} | {wl:.4f} | **{r_lw:.2f}** | **{tex:.3f}** |")
    print("\n".join(lines))
    if len(sys.argv) > 2:
        json.dump(out, open(sys.argv[2], "w"), indent=1)
        open(sys.argv[2].replace(".json", ".md"), "w").write("\n".join(lines) + "\n")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
