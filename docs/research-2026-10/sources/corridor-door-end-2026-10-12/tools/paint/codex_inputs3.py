"""Fix round 2 (v3): the edit target for Codex's paint job paint-v3.

The target is the door end as it stands after round 1 (the painted v2 far plate, mid plate, curtain,
frame, wheel and front, no stations, no runtime effects), with the v3 design's NEW parts drawn flat
from the construction render: the wall-mounted bypass (backplate, gearbox, chain guard, brackets),
the far column's concrete where the v2 drive shaft crossed it and its new pour joint, the 120 mm
yellow floor line, the cut section running down from the near pier's foot with its steel angles,
and the plant room's dry slab at the bottom right. The v2 floor stand, its shaft and its shadow are
gone. Codex paints only those flat areas; cleanup takes only their pixels.

Canvas CVP (design/tools/portal3.py): world x 640..974, y 286..620, 1024 x 1024.
Writes codex/paint-v3/refs/ and paint/inputs3.json.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "design"))  # the design tools (tools/design/)
from common import Canvas  # noqa: E402

D3 = os.path.join(R, "design", "portal3")
V2 = os.path.join(R, "layers", "v2")
GM = os.path.join(R, "game-main", "apps", "game", "assets")
OUT = os.path.join(R, "codex", "paint-v3", "refs")
CVP = Canvas("paint3", x0=640.0, y0=286.0, ppw=1024.0 / 334.0, w=1024, h=1024)
CVD = (676.0, 150.0, 4.0)
CV2 = (680.0, 150.0, 4.0)
NEW_WALL = ("bp_backplate", "bp_anchor0", "bp_anchor1", "bp_anchor2", "bp_anchor3", "bp_gearbox_side", "bp_gearbox",
            "bp_gearbox_top", "bp_boss", "bp_wallplate0", "bp_wallplate1", "bp_guard", "bp_guard_edge", "bp_sprocket_cover",
            "bp_guard_flange", "bp_clamp0", "bp_clamp1", "floor_line_wide", "far_col_joint", "far_col_patch")
NEW_FRONT = ("pier_cut", "arris_cut_left", "arris_cut_right")


def load(path):
    return np.asarray(Image.open(path).convert("RGBA")).astype(np.float64) / 255.0


def mask(path):
    return np.asarray(Image.open(path).convert("L")).astype(np.float64) / 255.0


def sample(img, x0, y0, ppw, canvas=CVP):
    """Bilinear sample of an image whose pixel (0, 0) top-left is world (x0, y0) at ppw px per
    world px, at the canvas's pixel centres. Outside the image: transparent."""
    X, Y = canvas.grid()
    px = (X - x0) * ppw - 0.5
    py = (Y - y0) * ppw - 0.5
    chans = img.shape[2] if img.ndim == 3 else 1
    a = img if img.ndim == 3 else img[..., None]
    out = np.stack([ndimage.map_coordinates(a[..., c], [py, px], order=1, mode="constant", cval=0.0) for c in range(chans)], -1)
    return out if img.ndim == 3 else out[..., 0]


def over(dst, src):
    sa = src[..., 3:4]
    da = dst[..., 3:4]
    oa = sa + da * (1 - sa)
    rgb = (src[..., :3] * sa + dst[..., :3] * da * (1 - sa)) / np.maximum(oa, 1e-9)
    return np.dstack([rgb, oa])


def premul_sample(img, x0, y0, ppw):
    """Samples RGBA with premultiplied colour so transparent pixels do not bleed black."""
    pm = img.copy()
    pm[..., :3] *= pm[..., 3:4]
    s = sample(pm, x0, y0, ppw)
    s[..., :3] /= np.maximum(s[..., 3:4], 1e-6)
    return np.clip(s, 0, 1)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    far = np.asarray(Image.open(os.path.join(R, "layers", "v3", "corridor-far-base.png")).convert("RGB")).astype(np.float64) / 255.0
    far = np.dstack([far, np.ones(far.shape[:2])])
    comp = sample(far, 12.444, 78.5, 2.0)
    comp[..., 3] = 1.0
    slab = load(os.path.join(D3, "design-slab-cvd.png"))
    comp = over(comp, premul_sample(slab, *CVD))
    mid = load(os.path.join(GM, "rooms", "corridor-mid.png"))
    mid[200:, 1400:, 3] = 0.0  # as round 1: the old pipe column and pump are gone
    comp = over(comp, premul_sample(mid, 0.0, 51.5, 2.0))
    # the wall layer: v2 paint for the old parts, the v3 design for the new ones, v3's alpha
    w2 = load(os.path.join(V2, "portal-wall.png"))
    w3 = load(os.path.join(D3, "design-wall.png"))
    newm = np.zeros(w3.shape[:2])
    for n in NEW_WALL:
        newm = np.maximum(newm, mask(os.path.join(D3, "masks", f"wall--{n}.png")))
    w2c = np.zeros_like(w3)
    w2c[:w2.shape[0], 16:16 + w2.shape[1]] = w2
    use_design = (newm > 0.02) | (w2c[..., 3] < 0.02)
    wall = w3.copy()
    wall[..., :3] = np.where(use_design[..., None], w3[..., :3], w2c[..., :3])
    comp = over(comp, premul_sample(wall, *CVD))
    for n in ("portal-curtain", "portal-frame"):
        comp = over(comp, premul_sample(load(os.path.join(V2, f"{n}.png")), *CV2))
    wheel = load(os.path.join(V2, "bypass-wheel.png"))
    comp = over(comp, premul_sample(wheel, 695.0 - 11.0, 398.0 - 11.0, 4.0))
    # the front: v2 paint (its hood region cleared, as in game) with the v3 cut section drawn flat
    f2 = load(os.path.join(V2, "portal-front.png"))
    fr2 = load(os.path.join(V2, "portal-frame.png"))
    f2[..., 3] *= 1.0 - np.clip(fr2[..., 3] * 1.5, 0, 1)
    f3 = load(os.path.join(D3, "design-front.png"))
    newf = np.zeros(f3.shape[:2])
    for n in NEW_FRONT:
        newf = np.maximum(newf, mask(os.path.join(D3, "masks", f"front--{n}.png")))
    f2c = np.zeros_like(f3)
    f2c[:f2.shape[0], 16:16 + f2.shape[1]] = f2
    front = f2c.copy()
    sel = newf > 0.02
    front[sel, :3] = f3[sel, :3]
    front[..., 3] = np.maximum(f2c[..., 3], newf)
    comp = over(comp, premul_sample(front, *CVD))
    rgb = (np.clip(comp[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8)
    Image.fromarray(rgb, "RGB").save(os.path.join(OUT, "1-edit-target-door-end.png"))
    # where the flat parts are, on the paint canvas (for the checks and for cleanup)
    paint_area = np.maximum(sample(newm, *CVD), sample(newf, *CVD))
    paint_area = np.maximum(paint_area, sample(slab[..., 3], *CVD))
    Image.fromarray((np.clip(paint_area, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(os.path.join(R, "paint", "paint-v3-area.png"))
    json.dump({"paint-v3": {"target": "1-edit-target-door-end.png", "canvas": vars(CVP), "new_wall_parts": NEW_WALL, "new_front_parts": NEW_FRONT,
                            "slab": "design/portal3/design-slab-cvd.png", "area_mask": "paint/paint-v3-area.png"}},
              open(os.path.join(R, "paint", "inputs3.json"), "w"), indent=1)
    print("edit target written", rgb.shape, "paint area px", int((paint_area > 0.5).sum()))


if __name__ == "__main__":
    main()
