"""Round 11: builds the Codex edit target and its paint map for the blast frame's jamb plates
(add7/fix4/codex/paint-jamb11/refs/), deterministic.

1024 x 1024, flat #24262A field; panel A = world x 700..830, y 270..462 at 5 px per world px
(650 x 960) at (187, 32): the door end shut, composed as the game layers its atlas pieces, with the
round-11 design (jamb11.py) in the wall and column pieces. Paint map: white = the two jamb plates
where they are visible (not under the guides, the hood or the column's hardware), black elsewhere.
Writes panels.json for cleanup11.py."""
from __future__ import annotations

import json
import os
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hood_blank  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import compose11 as c  # noqa: E402

D = os.path.join(HERE, "..", "design")
J = os.path.abspath(os.path.join(HERE, "..", "..", "codex", "paint-jamb11"))
SZ = 1024
BG = (36, 38, 42)
PA = {"world": [700.0, 270.0, 830.0, 462.0], "ppw": 5.0, "at": [187, 32]}


def rgba(p):
    return np.asarray(Image.open(p).convert("RGBA")).astype(float) / 255.0


def gray(p):
    return np.asarray(Image.open(p).convert("L")).astype(float) / 255.0


def main():
    os.makedirs(os.path.join(J, "refs"), exist_ok=True)
    atlas = rgba(c.ATLAS10) if hasattr(c, "ATLAS10") else rgba(os.path.join(c.R, "add7", "fix3", "door", "game", "corridor-seal-atlas.png"))
    w = rgba(os.path.join(D, "design-wall.png"))
    k = rgba(os.path.join(D, "design-column.png"))
    x0, y0, x1, y1 = PA["world"]
    comp = c.compose(atlas, x0, y0, x1, y1, PA["ppw"], wall=w, column=k)
    # Filed 2026-10-14: the hood's typeset DOOR 4B-07 is blanked in the edit target (hood_blank.py), so
    # the image tool never sees lettering it could copy into a plate (review r5). The targets this
    # session actually used, with the lettering, are kept in codex/<job>/refs/.
    comp, _ = hood_blank.blank_hood_text(comp, x0, y0, PA["ppw"])
    # visibility of the new parts: the same composition with the masks as white pieces, everything
    # else black (keeping its alpha), so only what the game would show of each plate stays white
    blk = atlas.copy()
    blk[..., :3] = 0.0
    fm = np.clip(gray(os.path.join(D, "masks", "wall--far_plate.png")), 0, 1)
    nm = gray(os.path.join(D, "masks", "column--near_plate.png")) * (1 - gray(os.path.join(D, "masks", "column--KEEP_hardware.png")))
    wpiece = np.dstack([np.ones(fm.shape + (3,)) * fm[..., None], np.maximum(fm, c.piece(atlas, "wall")[..., 3])])
    kpiece = np.dstack([np.ones(nm.shape + (3,)) * nm[..., None], c.piece(atlas, "column")[..., 3]])
    vis = c.compose(blk, x0, y0, x1, y1, PA["ppw"], wall=wpiece, column=kpiece, bg=(0, 0, 0))[..., 0]
    vis = (vis > 0.5).astype(float)
    target = np.zeros((SZ, SZ, 3)) + np.array(BG) / 255.0
    amap = np.zeros((SZ, SZ))
    ax, ay = PA["at"]
    target[ay:ay + comp.shape[0], ax:ax + comp.shape[1]] = comp
    amap[ay:ay + vis.shape[0], ax:ax + vis.shape[1]] = vis
    PA["px"] = [comp.shape[1], comp.shape[0]]
    Image.fromarray((np.clip(target, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(J, "refs", "1-edit-target-door-jambs.png"))
    Image.fromarray((amap * 255).astype(np.uint8), "L").convert("RGB").save(os.path.join(J, "refs", "2-areas-to-paint.png"))
    json.dump({"size": SZ, "A": PA, "bg": BG}, open(os.path.join(J, "panels.json"), "w"), indent=1)
    print(json.dumps(PA), int(vis.sum()))


if __name__ == "__main__":
    main()
