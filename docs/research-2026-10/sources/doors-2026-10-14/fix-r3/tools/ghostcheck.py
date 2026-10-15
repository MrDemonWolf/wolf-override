"""Fix round 2 (review r2, N1): the cleanup check that fails a layer behind a doorway when its fine
edges line up with the door's own shapes (a painted copy of the shut leaf: its outline, lever, rose, kick
plate, lock) inside the opening. Scratch only.

For each door end: the shut leaf's outside face (the design art, warped into its shut place in the design
canvas exactly as the paint step and the game place it) gives the leaf's feature edges (gradient of its
design luminance plus its outline), dilated 2 px; the opening is the leaf's footprint. In the layer behind
the doorway, |high-pass| (luminance minus a 1.5 px blur) is correlated with that edge mask over the
opening. A ghost door correlates strongly; a passage painted as itself does not.
FAIL above CORR_MAX, and also when the high-pass energy on the leaf's edges is more than RATIO_MAX times
its energy elsewhere in the opening.

usage: ghostcheck.py  (checks round 1's and this round's layers; writes checks/ghostcheck.json)"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
F2 = os.path.dirname(HERE)
S = os.path.dirname(F2)
CORR_MAX = 0.10
RATIO_MAX = 1.5


def lum(img):
    a = np.asarray(img.convert("RGB")).astype(np.float64) / 255.0
    return (a * np.array([0.2126, 0.7152, 0.0722])).sum(-1)


def leaf_features(track_tools, track_design, side, x_cross, cv, face, model_mod=None, door_fn=None):
    sys.path.insert(0, track_tools)
    import compose as C  # noqa
    import rmodel as M  # noqa
    door = door_fn() if door_fn else M.DoorEnd(side, x_cross)
    img = Image.new("RGBA", (cv["w"], cv["h"]), (0, 0, 0, 0))
    # the leaf at 0 degrees: compose.place_leaf warps the face art with its design light
    C.place_leaf(img, cv["x0"], cv["y0"], door, 0.0, os.path.join(track_design, "leaf"), face)
    a = np.asarray(img)[..., 3] / 255.0
    L = lum(img)
    gx = ndimage.sobel(L, 1)
    gy = ndimage.sobel(L, 0)
    g = np.hypot(gx, gy) * (a > 0.99)
    edges = (g > np.percentile(g[a > 0.99], 90)) | (a > 0.05) & (a < 0.95)
    edges = ndimage.binary_dilation(edges, iterations=2)
    opening = ndimage.binary_erosion(a > 0.5, iterations=3)
    return edges, opening


def score(layer_png, edges, opening):
    im = Image.open(layer_png).convert("RGBA")
    L = lum(im)
    al = np.asarray(im)[..., 3] / 255.0
    hp = np.abs(L - ndimage.gaussian_filter(L, 1.5))
    sel = opening & (al > 0.5)
    if sel.sum() < 50:
        return {"px": int(sel.sum()), "result": "n/a"}
    e = edges[sel].astype(float)
    h = hp[sel]
    corr = float(np.corrcoef(e, h)[0, 1]) if h.std() > 0 and e.std() > 0 else 0.0
    ratio = float(h[e > 0.5].mean() / max(h[e < 0.5].mean(), 1e-6)) if (e > 0.5).any() and (e < 0.5).any() else 0.0
    ok = corr <= CORR_MAX and ratio <= RATIO_MAX
    return {"px": int(sel.sum()), "corr_hp_vs_leaf_edges": round(corr, 4), "edge_energy_ratio": round(ratio, 3), "result": "pass" if ok else "FAIL"}


def main():
    out = {}
    # Records exit / entry (round 1 layers, round 2 layers)
    rt = os.path.join(F2, "records", "tools")
    for piece, side, xc, face in (("exit", 1, 880.0, "out-exit"), ("entry", -1, 70.0, "out-entry")):
        spec = json.load(open(os.path.join(F2, "records", "design", piece, "spec.json")))
        edges, opening = leaf_features(rt, os.path.join(F2, "records", "design"), side, xc, spec["canvas"], face)
        for tag, path in (("round1", os.path.join(S, "fix-r1", "records", "layers", "graded", piece, "clean-beyond.png")),
                          ("round2", os.path.join(F2, "records", "layers", "graded", piece, "clean-beyond.png")),
                          ("round2-ungraded", os.path.join(F2, "records", "layers", piece, "clean-beyond.png"))):
            if os.path.exists(path):
                out[f"records-{piece}/{tag}"] = score(path, edges, opening)
    sys.path.pop(0)
    for k in [m for m in sys.modules if m in ("compose", "rmodel", "rdesign")]:
        del sys.modules[k]
    # junction entry
    jt = os.path.join(F2, "jentry", "tools")
    sys.path.insert(0, jt)
    sys.path.insert(0, os.path.join(F2, "records", "tools"))
    import jedesign as JE  # noqa: installs jemodel as rmodel
    import compose as C  # noqa
    spec = json.load(open(os.path.join(F2, "jentry", "design", "entry", "spec.json")))
    cv = spec["canvas"]
    door, _ = JE.lamps()
    img = Image.new("RGBA", (cv["w"], cv["h"]), (0, 0, 0, 0))
    C.place_leaf(img, cv["x0"], cv["y0"], door, 0.0, os.path.join(F2, "jentry", "design", "leaf"), "out-exit")
    a = np.asarray(img)[..., 3] / 255.0
    L = lum(img)
    g = np.hypot(ndimage.sobel(L, 1), ndimage.sobel(L, 0)) * (a > 0.99)
    edges = ndimage.binary_dilation((g > np.percentile(g[a > 0.99], 90)) | ((a > 0.05) & (a < 0.95)), iterations=2)
    opening = ndimage.binary_erosion(a > 0.5, iterations=3)
    for tag, path in (("round1", os.path.join(S, "fix-r1", "jentry", "layers", "graded", "entry", "clean-beyond.png")),
                      ("round2", os.path.join(F2, "jentry", "layers", "graded", "entry", "clean-beyond.png")),
                      ("round2-ungraded", os.path.join(F2, "jentry", "layers", "entry", "clean-beyond.png"))):
        if os.path.exists(path):
            out[f"junction-entry/{tag}"] = score(path, edges, opening)
    os.makedirs(os.path.join(F2, "checks"), exist_ok=True)
    json.dump({"rule": f"FAIL when corr(|high-pass|, shut-leaf edges) > {CORR_MAX} or edge energy ratio > {RATIO_MAX} inside the opening", "results": out},
              open(os.path.join(F2, "checks", "ghostcheck.json"), "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
