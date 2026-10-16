"""Builds the round-8 Codex edit target and its paint map (codex/paint-door8/refs/), deterministic.

1024 x 1024, flat #24262A field:
  panel A  world x 700..800, y 225..445 at 4 px per world px (400 x 880) at (10, 72): the door end,
           open, round 8's base layers (round 7 minus its redrawn parts) with the new parts flat:
           the steel liner (head band, jamb strip, joints, arrises, anchor heads), the wider parked
           leaf edge with its receivers, and the wiper seals.
  panel B  the leaf's front face, flat elevation 3.95 x 3.20 m at 130 px per m (514 x 416) at (440, 72).
  panel C  the leaf's leading edge, 0.36 x 3.20 m at 130 px per m (47 x 416) at (966, 72).
Paint map: white = the new parts (panel A) and all of panels B and C.
"""
from __future__ import annotations

import json
import os
import shutil
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hood_blank  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portal8 as d8  # noqa: E402  (also points round 7's modules at round 8's leaf)
import compose7  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
D = os.path.join(ROOT, "design")
J = os.path.join(ROOT, "..", "codex", "paint-door8")
V6 = os.path.join(d8.d7.R6, "layers", "v6")
SZ = 1024
BG = (36, 38, 42)
PA = {"world": [700.0, 225.0, 800.0, 445.0], "ppw": 4.0, "at": [10, 72]}
PB = {"ppm": 130.0, "at": [440, 72], "size_m": [d8.LEAF_L, d8.LEAF_H]}
PC = {"ppm": 130.0, "at": [966, 72], "size_m": [d8.T_LB - d8.T_LF, d8.LEAF_H]}
SKIP = ("sign_plate", "sign_bolts", "rail_recess", "rail_head", "TEXT-sign", "lamp_conduit_strap2")


def masks_of(layer):
    out = np.zeros((1900, 1232))
    for f in sorted(os.listdir(os.path.join(D, "masks"))):
        if f.startswith(f"{layer}--") and not any(f == f"{layer}--{s}.png" for s in SKIP) and "ALPHA" not in f:
            out = np.maximum(out, np.asarray(Image.open(os.path.join(D, "masks", f)).convert("L")).astype(float) / 255.0)
    return out


def main():
    os.makedirs(os.path.join(J, "refs"), exist_ok=True)
    tmp = os.path.join(ROOT, "work", "tmp-flat")
    os.makedirs(tmp, exist_ok=True)
    for f in ("portal-curtain.png", "portal-curtain-open.png", "portal-frame.png", "bypass-wheel.png", "lens.png"):
        shutil.copy(os.path.join(V6, f), os.path.join(tmp, f))
    for f in ("corridor-far.png", "corridor-mid.png"):
        shutil.copy(os.path.join(V6, "game", f), os.path.join(tmp, f))
    newm = {}
    for layer in ("wall", "front"):
        base = np.asarray(Image.open(os.path.join(ROOT, "layers", f"base-{layer}.png")).convert("RGBA")).astype(float)
        add = np.asarray(Image.open(os.path.join(D, f"design-add-{layer}.png")).convert("RGBA")).astype(float)
        m = masks_of(layer)
        newm[layer] = m
        a = (add[..., 3:4] / 255.0) * m[..., None]
        out = base.copy()
        out[..., :3] = base[..., :3] * (1 - a) + add[..., :3] * a
        out[..., 3:4] = np.maximum(base[..., 3:4], a * 255)
        if layer == "wall":
            # the sign's letters are typeset later: the painter sees a blank plate
            from scipy import ndimage
            txt = ndimage.binary_dilation(np.asarray(Image.open(os.path.join(D, "masks", "wall--TEXT-sign.png")).convert("L")) > 20, iterations=3)
            plate = (np.asarray(Image.open(os.path.join(D, "masks", "wall--sign_plate.png")).convert("L")) > 250) & ~txt
            spm = np.asarray(Image.open(os.path.join(D, "masks", "wall--sign_plate.png")).convert("L")) > 100
            bolts = ndimage.binary_dilation(np.asarray(Image.open(os.path.join(D, "masks", "wall--sign_bolts.png")).convert("L")) > 60, iterations=2)
            out[spm & ~bolts, :3] = np.median(out[plate & ~bolts, :3], 0)
        Image.fromarray(out.round().astype(np.uint8), "RGBA").save(os.path.join(tmp, f"portal-{layer}.png"))
    comp = compose7.compose(tmp, 1.0, show_leaf=False)
    X0, Y0 = compose7.X0, compose7.Y0
    x0, y0, x1, y1 = PA["world"]
    a = comp[int((y0 - Y0) * 4):int((y1 - Y0) * 4), int((x0 - X0) * 4):int((x1 - X0) * 4), :3]
    # Filed 2026-10-14: the hood's typeset DOOR 4B-07 is blanked in the edit target (hood_blank.py), so
    # the image tool never sees lettering it could copy into a plate (review r5). The targets this
    # session actually used, with the lettering, are kept in codex/<job>/refs/.
    a, _ = hood_blank.blank_hood_text(a, x0, y0, 4.0)
    target = np.zeros((SZ, SZ, 3)) + np.array(BG) / 255.0
    amap = np.zeros((SZ, SZ))
    ax, ay = PA["at"]
    target[ay:ay + a.shape[0], ax:ax + a.shape[1]] = a
    m = np.maximum(newm["wall"], newm["front"])
    # the hood and guides stand in front: paint only where the new parts show in the composite
    fr = np.zeros((1900, 1232))
    frm = np.asarray(Image.open(os.path.join(tmp, "portal-frame.png")).convert("RGBA")).astype(float)[..., 3] / 255.0
    fr[:frm.shape[0], 16:16 + frm.shape[1]] = frm
    m = m * (1 - np.clip(fr * 1.5, 0, 1))
    mc = m[int((y0 - 150) * 4):int((y1 - 150) * 4), int((x0 - 676) * 4):int((x1 - 676) * 4)]
    amap[ay:ay + mc.shape[0], ax:ax + mc.shape[1]] = (mc > 0.3).astype(float)
    for P, nm in ((PB, "leaf-front"), (PC, "leaf-edge")):
        im = Image.open(os.path.join(D, f"design-{nm}-albedo.png")).convert("RGB")
        # show the elevation brighter than the game will (a readable value plan for the painter)
        w, h = int(round(P["size_m"][0] * P["ppm"])), int(round(P["size_m"][1] * P["ppm"]))
        im = np.asarray(im.resize((w, h), Image.Resampling.LANCZOS)).astype(float) / 255.0
        im = np.clip(im * 1.9, 0, 1)
        bx, by = P["at"]
        target[by:by + h, bx:bx + w] = im
        amap[by:by + h, bx:bx + w] = 1.0
        P["px"] = [w, h]
        P["display_gain"] = 1.9
    PA["px"] = [a.shape[1], a.shape[0]]
    Image.fromarray((np.clip(target, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(J, "refs", "1-edit-target-door-end.png"))
    Image.fromarray((amap * 255).astype(np.uint8), "L").convert("RGB").save(os.path.join(J, "refs", "2-areas-to-paint.png"))
    json.dump({"size": SZ, "A": PA, "B": PB, "C": PC, "bg": BG}, open(os.path.join(J, "panels.json"), "w"), indent=1)
    print(json.dumps({"A": PA, "B": PB, "C": PC}))


if __name__ == "__main__":
    main()
