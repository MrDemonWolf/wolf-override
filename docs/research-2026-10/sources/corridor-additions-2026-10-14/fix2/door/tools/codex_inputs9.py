"""Builds the round-9 Codex edit target and its paint map (codex/paint-cut9b/refs/; paint-cut9 holds the superseded 0.42 m try), deterministic.

1024 x 1024, flat #24262A field, one panel: CVD canvas x 336..1232, y 1100..1580 (world x 760..984,
y 425..545, 4 px per world px; 896 x 480) at (64, 272). Context = round 8's in-game frame s1 at
1280x720 (render.sh), resampled onto the CVD grid; over it, the new cut section flat-lit
(design/design-cut.png). Paint map: white = the cut section's parts.
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
F2 = os.path.abspath(os.path.join(ROOT, ".."))
D = os.path.join(ROOT, "design")
J = os.path.join(F2, "codex", "paint-cut9b")  # paint-cut9 was the 0.42 m try, superseded (its design: door/work-042/design)
CAP = os.path.join(F2, "..", "shots", "raw8", "add", "A-720", "s1-door-end-rest-clean.png")
CAM = (604.4, 360.0)
SZ = 1024
BG = (36, 38, 42)
PANEL = {"cvd": [336, 1100, 1232, 1580], "at": [64, 272]}


def main():
    os.makedirs(os.path.join(J, "refs"), exist_ok=True)
    cap = np.asarray(Image.open(CAP).convert("RGB")).astype(float)
    x0, y0, x1, y1 = PANEL["cvd"]
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(float)
    wx, wy = 676 + (xx + 0.5) / 4, 150 + (yy + 0.5) / 4
    sx = ((wx - CAM[0]) * 1.35 + 480) * 4 / 3 - 0.5
    sy = ((wy - CAM[1]) * 1.35 + 270) * 4 / 3 - 0.5
    ctx = np.stack([ndimage.map_coordinates(cap[..., c], [sy, sx], order=1, mode="nearest") for c in range(3)], -1)
    des = np.asarray(Image.open(os.path.join(D, "design-cut.png")).convert("RGBA")).astype(float)[y0:y1, x0:x1]
    a = des[..., 3:4] / 255.0
    pan = ctx * (1 - a) + des[..., :3] * a
    target = np.zeros((SZ, SZ, 3)) + np.array(BG)
    amap = np.zeros((SZ, SZ))
    ax, ay = PANEL["at"]
    target[ay:ay + pan.shape[0], ax:ax + pan.shape[1]] = pan
    amap[ay:ay + pan.shape[0], ax:ax + pan.shape[1]] = (a[..., 0] > 0.3).astype(float)
    Image.fromarray(np.clip(target, 0, 255).round().astype(np.uint8), "RGB").save(os.path.join(J, "refs", "1-edit-target-cut-wall.png"))
    Image.fromarray((amap * 255).astype(np.uint8), "L").convert("RGB").save(os.path.join(J, "refs", "2-areas-to-paint.png"))
    json.dump({"size": SZ, "panel": PANEL, "bg": BG, "context": os.path.relpath(CAP, F2)}, open(os.path.join(J, "panels.json"), "w"), indent=1)
    print(json.dumps(PANEL))


if __name__ == "__main__":
    main()
