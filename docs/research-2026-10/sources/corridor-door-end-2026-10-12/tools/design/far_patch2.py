"""Fix round 1 (v2) of the far-plate patch: the v1 design (far_patch.py) with
  - the corridor luminaire moved to mid-bay (clamp x 652), dimmer and tighter, so its pool falls to
    the old wall's value (luma 20-25) by the seam column (review item 4);
  - the lockdown beacon's mount moved left of the fitting (the beacon itself is the game's live one;
    main.tscn's second warning lamp moves from far x 0.659 to 0.62 to match);
  - the machinery room's floor carried forward to the cross-wall's far foot line, so the floor seen
    through and past the portal is the plant room's own dry concrete under its own lights, not the
    corridor's wet floor (review item 1);
  - parts listed back to front, so cleanup can composite and value-match them in depth order
    (review item 7: no part may write into a nearer one).
Writes design/far-patch2/.
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import common
import far_patch as fp
from common import Fixture, Part, rect, write_json, save_mask, to_srgb_u8
import portal2 as p2

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "far-patch2")

LED_X, LED_Y = p2.LED_SCREEN
fp.F_CORR = Fixture("corridor vapour-tight luminaire (1.28 m, chain-hung 0.5 m off the wall), mid-bay", (LED_X, LED_Y), 1.9, (0.72, 0.93, 1.0), 0.8, 0.45, 1.0)
fp.CORR = (fp.F_CORR,)
# a touch less ambient in the corridor bay than v1, so the wall by the seam column sits at the old
# wall's value (the plate left of the column has no lamp near it)
common.AMBIENT = np.array([0.015, 0.028, 0.037])
BEACON_FAR_FRACTION_X = 0.62  # main.tscn CorridorDepth.warning_lamps[1].x (was 0.659)
BEACON_X = BEACON_FAR_FRACTION_X * 960.0 + common.FAR_SHIFT


def parts() -> list[Part]:
    ps = [p for p in fp.parts() if not p.name.startswith("beacon_")]
    # the machinery floor in front of the plant room's back half, up to the cross-wall's far foot line
    far_foot = [p2.scr(p2.pt(a, 0.0, p2.T_WALL)) for a in (p2.A_BACK, p2.A_END)]
    (x0, y0), (x1, y1) = far_foot
    near = [(x0 - 6.0, y0 - 0.5), (985.0, y0 - 0.5), (985.0, y1 + 7.0), (x1, y1 + 7.0), (x1, y1)]
    mach_floor_near = Part("mach_floor_near", [near], (0.16, 0.21, 0.23), {"kind": "floor"}, fp.MACH,
                           dims="the plant room's slab between the cross-wall and its back half", note="dry sealed concrete under the plant room's own lights")
    # insert it right after the machinery floor (so the room's equipment draws over it)
    idx = next(i for i, p in enumerate(ps) if p.name == "mach_floor") + 1
    ps.insert(idx, mach_floor_near)
    bx = BEACON_X
    ps.append(Part("beacon_conduit", [rect(bx - 0.6, 174.5, bx + 0.6, 216.0)], (0.38, 0.44, 0.47), {"kind": "front", "d": fp.D_CORR - 0.05}, fp.CORR,
                   dims="20 mm conduit to the ceiling tray", note="feeds the lockdown beacon"))
    ps.append(Part("beacon_backbox", [rect(bx - 4.0, 213.0, bx + 4.0, 216.5)], (0.26, 0.32, 0.35), {"kind": "front", "d": fp.D_CORR - 0.05}, fp.CORR,
                   dims="back box 0.2 m", note="the beacon's stub bracket bolts here"))
    return ps


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    ps = parts()
    fp.OUT = OUT
    lin, masks = fp.render(ps)
    img = to_srgb_u8(lin)
    Image.fromarray(img, "RGB").save(os.path.join(OUT, "design.png"))
    for name, m in masks.items():
        save_mask(m, os.path.join(OUT, "masks", f"{name}.png"))
    order = [p.name for p in ps]
    spec = {
        "canvas": {"source_rect_in_corridor_far": [fp.SRC_X0, 0, fp.CANVAS.w, fp.CANVAS.h], "px_per_world": fp.CANVAS.ppw,
                   "world_origin_at_clamp": [fp.CANVAS.x0, fp.CANVAS.y0], "keep_original_rows": fp.KEEP_ROWS},
        "draw_order_back_to_front": order,
        "fixtures": [{"name": f.name, "screen": f.screen, "depth_m": f.d, "color": f.color, "intensity": f.intensity, "reach_m": f.reach} for f in (fp.F_CORR, fp.F_MA, fp.F_MB)],
        "beacon": {"far_fraction_x": BEACON_FAR_FRACTION_X, "clamp_world_x": round(BEACON_X, 2)},
        "parts": [{"name": p.name, "albedo": p.albedo, "surface": p.surface, "dims": p.dims, "job": p.note} for p in ps],
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    far = Image.fromarray(fp.base_far(), "RGB")
    far.paste(Image.fromarray(img, "RGB"), (fp.SRC_X0, 0))
    far.save(os.path.join(OUT, "far-plate-with-design.png"))
    # value check at the seam: the new wall just right of the column against the old wall left of it
    L = img[..., 0] * 0.2126 + img[..., 1] * 0.7152 + img[..., 2] * 0.0722
    def col(xw, y0w, y1w):
        sx = int(round((xw - fp.CANVAS.x0) * 2))
        return float(np.median(L[int((y0w - 78.5) * 2):int((y1w - 78.5) * 2), sx]))
    print("new wall luma at x 590/600/620/652/690 (y 195-245):", [round(col(x, 195, 245), 1) for x in (590, 600, 620, 652, 690)])
    print("new wall luma at x 590/600/620/652/690 (y 250-400):", [round(col(x, 250, 400), 1) for x in (590, 600, 620, 652, 690)])


if __name__ == "__main__":
    main()
