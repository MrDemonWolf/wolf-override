"""Grounding for the two approved Look 2 stations at the door end: the coolant relay and the safe
point keep their designs pixel for pixel; each gains a plinth with anchors and a brush-strip cable
entry (cables come up from the floor), and a contact shadow drawn from its footprint. Writes
design/stations/.

Sprites are 4 source px per world px (the Look 2 density). Each output canvas puts the floor contact
line at row FLOOR_ROW; the game draws it at y 440.
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from common import save_mask, write_json

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "stations")
L2 = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "look2-hq", "props"))  # the approved Look 2 props, in this repository

STATIONS = {
    # name: (L2 file, plinth height px (4/world px), centre world x, plinth body x range in L2 px, note)
    "relay": ("corridor-coolant-relay.png", 32, 605.0, (14, 301), "200 mm plinth under a 2.2 m cabinet"),
    "safe-point": ("corridor-safe-point.png", 16, 876.0, (10, 286), "100 mm plinth under the safe point console"),
}
PAD_X = 16
SHADOW_ROWS = 16


def build(name: str, spec) -> dict:
    fname, plinth_h, centre_x, (px0, px1), note = spec
    src = Image.open(os.path.join(L2, fname)).convert("RGBA")
    a = np.asarray(src)
    alpha = a[..., 3]
    rows = np.nonzero(alpha.max(1) > 128)[0]
    bottom = int(rows.max())  # last opaque row of the L2 art (its feet)
    W = src.width + 2 * PAD_X
    floor_row = bottom + 1 + plinth_h
    H = floor_row + SHADOW_ROWS
    canvas = np.zeros((H, W, 4), dtype=np.float64)
    # plinth: a plain steel box under the whole base, its top under the feet
    x0, x1 = px0 + PAD_X, px1 + PAD_X + 1
    y0, y1 = bottom + 1, floor_row
    masks = {}
    yy, xx = np.mgrid[0:H, 0:W]
    plinth = (xx >= x0) & (xx < x1) & (yy >= y0) & (yy < y1)
    masks["plinth"] = plinth.astype(float)
    # flat value plan for the plinth: lit top lip, mid face, darker foot
    face = np.zeros((H, W, 3))
    t = (yy - y0) / max(plinth_h, 1)
    base_col = np.array([40, 42, 48], float)  # 36081-grey steel plinth
    face[...] = base_col
    face[(yy >= y0) & (yy < y0 + 3)] = [84, 88, 96]  # top lip catches the overhead light
    face = face * (1.0 - 0.25 * np.clip(t, 0, 1))[..., None]
    # brush-strip cable entry slot in the middle of the face
    bs_x0 = x0 + int((x1 - x0) * 0.32)
    bs_x1 = x0 + int((x1 - x0) * 0.68)
    bs_y0 = y0 + max(4, plinth_h // 3)
    bs_y1 = y1 - max(3, plinth_h // 5)
    brush = (xx >= bs_x0) & (xx < bs_x1) & (yy >= bs_y0) & (yy < bs_y1)
    face[brush] = [14, 17, 19]
    masks["brush_strip"] = brush.astype(float)
    # anchor bolts: one near each end of the plinth face
    bolts = np.zeros((H, W), bool)
    for bx in (x0 + 10, x1 - 11):
        by = (y0 + y1) // 2 + 1
        bolts |= (xx - bx) ** 2 + (yy - by) ** 2 <= 9
    face[bolts] = [96, 108, 114]
    masks["anchors"] = bolts.astype(float)
    canvas[plinth, :3] = face[plinth]
    canvas[plinth, 3] = 255
    # the approved art, unchanged, on top
    l2 = np.zeros((H, W, 4))
    l2[0:src.height, PAD_X:PAD_X + src.width] = a
    la = l2[..., 3:4] / 255.0
    canvas[..., :3] = canvas[..., :3] * (1 - la) + l2[..., :3] * la
    canvas[..., 3] = np.maximum(canvas[..., 3], l2[..., 3])
    masks["look2"] = (l2[..., 3] / 255.0)
    # contact shadow on the floor: darkest at the contact line, soft 4 world px (16 px) out
    sh = np.zeros((H, W))
    below = yy >= floor_row
    edge = np.clip(np.minimum(xx - (x0 - 8), (x1 + 8) - xx) / 10.0, 0, 1)
    sh[below] = (0.72 * np.exp(-(yy[below] - floor_row) / 4.0) * edge[below])
    # a little occlusion on the floor right at the plinth's ends
    shadow_rgb = np.array([2, 5, 8], float)
    sa = sh * 255
    out_a = canvas[..., 3] + sa * (1 - canvas[..., 3] / 255.0)
    w_sh = np.where(out_a > 0, sa * (1 - canvas[..., 3] / 255.0) / np.maximum(out_a, 1e-6), 0)
    canvas[..., :3] = canvas[..., :3] * (1 - w_sh[..., None]) + shadow_rgb * w_sh[..., None]
    canvas[..., 3] = out_a
    masks["contact_shadow"] = sh
    img = Image.fromarray(np.clip(canvas + 0.5, 0, 255).astype(np.uint8), "RGBA")
    img.save(os.path.join(OUT, f"design-{name}.png"))
    for k, m in masks.items():
        save_mask(m, os.path.join(OUT, "masks", f"{name}--{k}.png"))
    opaque_cols = np.nonzero(canvas[..., 3].max(0) > 128)[0]
    return {
        "file": f"design-{name}.png", "size": [W, H], "floor_row": floor_row, "l2_file": fname, "l2_offset": [PAD_X, 0],
        "plinth_px": [x0, y0, x1, y1], "plinth_world_m": plinth_h / 4 / 40, "brush_strip_px": [bs_x0, bs_y0, bs_x1, bs_y1],
        "centre_world_x": centre_x, "sprite_centre_px_x": (px0 + px1) / 2 + PAD_X,
        "note": note,
    }


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    info = {name: build(name, spec) for name, spec in STATIONS.items()}
    write_json(os.path.join(OUT, "spec.json"), info)
    print(info)


if __name__ == "__main__":
    main()
