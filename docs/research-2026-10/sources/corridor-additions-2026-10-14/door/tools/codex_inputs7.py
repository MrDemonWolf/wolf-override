"""Builds the round-7 Codex edit target and its paint map (codex/paint-door7/refs/), deterministic.

1024 x 1024, flat #24262A field:
  panel A  world x 700..800, y 225..445 at 4 px per world px (400 x 880) at (10, 72): the door end,
           open, from the flat design layers (design/flat7): round 6's painted layers with the new
           parts drawn flat (blast frame plates and bolts, sign plate WITHOUT its letters, the
           pocket's seals, the parked leaf edge, the floor rail).
  panel B  the blast leaf's front face, a flat elevation 3.95 x 3.20 m at 130 px per m (514 x 416)
           at (440, 72).
  panel C  the leaf's leading edge, 0.24 x 3.20 m at 130 px per m (31 x 416) at (972, 72).
Paint map: white = the new parts (panel A) and all of panels B and C.
Writes panels.json with every panel's geometry for cleanup7.py.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hood_blank  # noqa: E402

sys.path.insert(0, os.path.dirname(__file__))
from stack import p2  # noqa: E402
import portal7 as d7  # noqa: E402
import compose7  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "..", "design")
J = os.path.join(HERE, "..", "codex", "paint-door7")
SZ = 1024
BG = (36, 38, 42)
PA = {"world": [700.0, 225.0, 800.0, 445.0], "ppw": 4.0, "at": [10, 72]}
PB = {"ppm": 130.0, "at": [440, 72], "size_m": [d7.LEAF_L, d7.LEAF_H]}
PC = {"ppm": 130.0, "at": [972, 72], "size_m": [d7.T_LB - d7.T_LF, d7.LEAF_H]}
NEW_WALL = ("bf_jamb_plate", "bf_head_plate", "bf_jamb_seam0", "bf_jamb_seam1", "bf_head_seam0", "bf_head_seam1", "bf_bolts",
            "sign_plate", "sign_bolts", "slot_seal_front", "slot_seal_back", "leaf_edge_parked", "rail_recess", "rail_head")
NEW_FRONT = ("bf_near_head", "bf_near_bolts")


def mask(name):
    return np.asarray(Image.open(os.path.join(D, "masks", name)).convert("L")).astype(float) / 255.0


def main():
    os.makedirs(os.path.join(J, "refs"), exist_ok=True)
    F = os.path.join(D, "flat7")
    # the flat sign plate without its letters: rebuild portal-wall without the text for the target
    base = Image.open(os.path.join(d7.R6, "layers", "v6", "portal-wall.png")).convert("RGBA")
    base.alpha_composite(Image.open(os.path.join(D, "design-add-wall-notext.png")).convert("RGBA"))
    wall = np.asarray(base).astype(float)
    tmp = os.path.join(J, "tmp-flat")
    os.makedirs(tmp, exist_ok=True)
    for f in os.listdir(F):
        src = os.path.join(F, f)
        if f == "portal-wall.png":
            Image.fromarray(wall.astype(np.uint8), "RGBA").save(os.path.join(tmp, f))
        else:
            Image.open(src).save(os.path.join(tmp, f))
    comp = compose7.compose(tmp, 1.0, show_leaf=False)
    X0, Y0 = compose7.X0, compose7.Y0
    x0, y0, x1, y1 = PA["world"]
    a = comp[int((y0 - Y0) * 4):int((y1 - Y0) * 4), int((x0 - X0) * 4):int((x1 - X0) * 4), :3]
    # Filed 2026-10-14: the hood's typeset DOOR 4B-07 is blanked in the edit target (hood_blank.py), so
    # the image tool never sees lettering it could copy into a plate (review r5). The targets this
    # session actually used, with the lettering, are kept in codex/<job>/refs/.
    a, _ = hood_blank.blank_hood_text(a, x0, y0, 4.0)
    # the sign plate as weathered white paint in this dim light (about luma 70), its bolts darker
    sp = mask("wall--sign_plate.png") * (1 - mask("wall--sign_bolts.png"))
    spc = sp[int((y0 - 150) * 4):int((y1 - 150) * 4), int((x0 - 676) * 4):int((x1 - 676) * 4)][..., None]
    a = a * (1 - spc) + np.array([66, 69, 72]) / 255.0 * spc
    target = np.zeros((SZ, SZ, 3)) + np.array(BG) / 255.0
    amap = np.zeros((SZ, SZ))
    ax, ay = PA["at"]
    target[ay:ay + a.shape[0], ax:ax + a.shape[1]] = a
    # panel A's paint map: the new parts' masks on CVD, cropped
    m = np.zeros((1900, 1232))
    for n in NEW_WALL:
        m = np.maximum(m, mask(f"wall--{n}.png"))
    for n in NEW_FRONT:
        m = np.maximum(m, mask(f"front--{n}.png"))
    # the front layer's hood clearance: the near head plate shows only where the hood is not in front
    fr = np.zeros((1900, 1232))
    frm = np.asarray(Image.open(os.path.join(F, "portal-frame.png")).convert("RGBA")).astype(float)[..., 3] / 255.0
    fr[:frm.shape[0], 16:16 + frm.shape[1]] = frm
    m = m * (1 - np.clip(fr * 1.5, 0, 1) * np.maximum(mask("front--bf_near_head.png"), mask("front--bf_near_bolts.png")))
    mc = m[int((y0 - 150) * 4):int((y1 - 150) * 4), int((x0 - 676) * 4):int((x1 - 676) * 4)]
    mc = (mc > 0.3).astype(float)
    amap[ay:ay + mc.shape[0], ax:ax + mc.shape[1]] = mc
    # panels B and C: the leaf elevations, resampled to 130 px per m
    for P, nm in ((PB, "leaf-front"), (PC, "leaf-edge")):
        im = Image.open(os.path.join(D, f"design-{nm}-albedo.png")).convert("RGB")
        w, h = int(round(P["size_m"][0] * P["ppm"])), int(round(P["size_m"][1] * P["ppm"]))
        im = np.asarray(im.resize((w, h), Image.Resampling.LANCZOS)).astype(float) / 255.0
        bx, by = P["at"]
        target[by:by + h, bx:bx + w] = im
        amap[by:by + h, bx:bx + w] = 1.0
        P["px"] = [w, h]
    PA["px"] = [a.shape[1], a.shape[0]]
    Image.fromarray((np.clip(target, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(J, "refs", "1-edit-target-door-end.png"))
    Image.fromarray((amap * 255).astype(np.uint8), "L").convert("RGB").save(os.path.join(J, "refs", "2-areas-to-paint.png"))
    json.dump({"size": SZ, "A": PA, "B": PB, "C": PC, "bg": BG}, open(os.path.join(J, "panels.json"), "w"), indent=1)
    print(json.dumps({"A": PA, "B": PB, "C": PC}))


if __name__ == "__main__":
    main()
