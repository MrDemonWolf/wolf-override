"""Fix round 3 (review r3, S1): the blast door's threshold plate against the deck beside it, on the render.
The plate's pixels are its design mask (junction/design/masks/wall--threshold.png, canvas world x0 400, y0 136,
4 px per world px) carried to the screen with the shot's canvas transform; the deck is the frame's pixels in the
same rows within 40 px either side of the plate, outside it and its nose. Linear luminance. Target: the plate's
median within the deck's median +-15 %. usage: threshcheck.py FRAMES_DIR [OUT_JSON]"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import measure3 as M3  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
DM = os.path.join(HERE, "..", "junction", "design", "masks")


def to_screen(mask, shot, size, shape):
    sc, tx, ty = shot["canvas"][0], shot["canvas"][4], shot["canvas"][5]
    k = size[0] / 960.0
    H, W = shape
    ys, xs = np.mgrid[0:H, 0:W].astype(np.float64)
    wx = ((xs + 0.5) / k - tx) / sc
    wy = ((ys + 0.5) / k - ty) / sc
    px = (wx - 400.0) * 4.0
    py = (wy - 136.0) * 4.0
    return ndimage.map_coordinates(mask.astype(np.float64), [py, px], order=1, mode="constant", cval=0.0) > 0.5


def main():
    fr = sys.argv[1]
    run = json.load(open(os.path.join(fr, "_run.json")))
    shots = {s["slug"]: s for s in run["shots"]}
    out = {}
    for slug in ("j01-sealed", "j02-fuse"):
        L = M3.lin_lum(os.path.join(fr, f"{slug}-clean.png"))
        plate = np.asarray(Image.open(os.path.join(DM, "wall--threshold.png"))) > 127
        nose = np.asarray(Image.open(os.path.join(DM, "wall--threshold_nose.png"))) > 127
        sp = ndimage.binary_erosion(to_screen(plate, shots[slug], run["size"], L.shape), iterations=1)
        sn = to_screen(nose, shots[slug], run["size"], L.shape)
        ys, xs = np.nonzero(sp)
        rows = slice(ys.min(), ys.max() + 1)
        band = np.zeros_like(sp)
        band[rows, max(xs.min() - 40, 0):xs.min() - 3] = True
        band[rows, xs.max() + 4:xs.max() + 41] = True
        band &= ~ndimage.binary_dilation(sp | sn, iterations=3)
        p, d = float(np.median(L[sp])), float(np.median(L[band]))
        out[slug] = {"plate_rows": [int(ys.min()), int(ys.max())], "plate": p, "deck": d, "ratio": p / max(d, 1e-6), "nose_px": int(sn.sum()),
                     "pass": bool(abs(p / max(d, 1e-6) - 1.0) <= 0.15)}
        print(f"{slug}: rows {ys.min()}-{ys.max()} plate {p:.4f} deck {d:.4f} ratio {p / max(d, 1e-6):.2f} ({'pass' if out[slug]['pass'] else 'FAIL'})")
    if len(sys.argv) > 2:
        json.dump(out, open(sys.argv[2], "w"), indent=1)


if __name__ == "__main__":
    main()
