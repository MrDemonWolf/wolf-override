"""Fix round 3: the shut swing leaves against the cross-wall beside them, on the render (the r2 N3 rule,
leaf at or below its wall, for the shut state; the open state follows R3-2's leaf-vs-reveal, leafcheck.py).
The leaf is the model's outline at 0 degrees (leafcheck.MODEL), eroded 2 px; the wall is measure4's box at
the door's rows. usage: shutleaf.py FRAMES_DIR [OUT_JSON]"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import leafcheck as LC, measure3 as M3, measure4 as M4
SHUT = {"records-entry": "r03-arrival-closed", "records-exit": "r04-copy-point", "junction-entry": "r11-entry-shut"}
def outline(end, shot, size, shape):
    h, u, n, vpx, hor = (np.array(v) if isinstance(v, tuple) else v for v in LC.MODEL[end])
    d = -u
    up = np.array([0.0, 1.0, 0.0])
    def proj(p):
        s = 38.0 / (38.0 + p[2]); wx, wy = vpx + (p[0] * 40.0 - vpx) * s, hor + (440.0 - hor) * s - p[1] * 40.0 * s
        sc, tx, ty = shot["canvas"][0], shot["canvas"][4], shot["canvas"][5]; kk = size[0] / 960.0
        return ((wx * sc + tx) * kk, (wy * sc + ty) * kk)
    b = h; W, H, B = LC.LEAF_W, LC.LEAF_H, LC.LEAF_BOTTOM
    pts = [proj(b + up * B), proj(b + d * W + up * B), proj(b + d * W + up * (B + H)), proj(b + up * (B + H))]
    im = Image.new("L", (shape[1], shape[0]), 0); ImageDraw.Draw(im).polygon(pts, fill=255)
    return np.asarray(im) > 0
fr = sys.argv[1]; run = json.load(open(os.path.join(fr, "_run.json"))); shots = {s["slug"]: s for s in run["shots"]}
out = {}
for end, slug in SHUT.items():
    p = os.path.join(fr, slug + "-clean.png"); L = M3.lin_lum(p)
    m = ndimage.binary_erosion(outline(end, shots[slug], run["size"], L.shape), iterations=2)
    ys = np.nonzero(m.any(1))[0]
    x0, _, x1, _ = M4.screen_box(shots[slug], run["size"], M3.ENDS[end][2], (330.0, 430.0), L.shape)
    lm, wm = float(np.median(L[m])), float(np.median(L[ys.min():ys.max() + 1, x0:x1]))
    out[end] = {"frame": slug, "leaf": round(lm, 4), "wall": round(wm, 4), "ratio": round(lm / wm, 2)}
    print(end, out[end])
if len(sys.argv) > 2: json.dump(out, open(sys.argv[2], "w"), indent=1)
