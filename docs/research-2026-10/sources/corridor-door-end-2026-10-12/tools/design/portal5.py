"""Fix round 4 (v5) construction design of the corridor's door end: the v4 model (portal4.py) with
the round-4 review's must-fix 1.

  must 1   the near guide's return. The guide (three 50 mm angles, 120 mm on the jamb, standing
           130 mm off the face) has a side return at its camera-side edge (a = A_N - 0.12) that runs
           from the guide's front (t = -0.13) back to the jamb's channel frame (t = -0.02). v4 drew
           the guide's front and the jamb but not that return, so a 6.9 design px (1.7 world px) slit
           was left between them (design x 456.5..463.4) and the actors behind the column showed
           through it. The return is drawn now, before the jamb in painter's order, so it fills
           exactly the slit and the jamb keeps its painted face: from the guide's left edge to the
           chamfer the column is solid steel and concrete over the guide's full height.
Everything else is portal4's, unchanged. Writes design/portal5/ (front layer render, part masks,
contact shadows, spec.json).
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from common import save_mask, to_srgb_u8, write_json  # noqa: E402
import portal4 as p4  # noqa: E402
import portal2 as p2  # noqa: E402

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "portal5")
CVD = p4.CVD


def front_parts_v5() -> list:
    P = p4.front_parts_v4()
    names = [p.name for p in P]
    side = p2.Part("front", "guide_near_side",
                   [p2.quad_side(p2.A_N - p2.GUIDE_W, p2.GUIDE_T, -0.02, 0.0, p2.H_OPEN)], p2.HOUSING,
                   p2.side_plane(p2.A_N - p2.GUIDE_W),
                   "guide return 110 mm deep (the angles' flange back to the jamb's channel frame)",
                   "closes the guide's camera-side edge back to the jamb: no gap between the guide and the column")
    P.insert(names.index("frame_near_jamb"), side)
    return P


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    parts = front_parts_v5()
    lay = p2.render(parts, CVD)["front"]
    tl = p4.T_END / 2
    lcx, lcy = p2.scr(p2.pt(p4.A_END4 - 0.12, p4.LAMP_H, tl))
    glass = p2.mask_of([("ellipse", lcx, lcy, 2.05, 2.55)], CVD)
    guard = np.clip(sum(lay["masks"][f"lamp_guard{i}"] for i in range(3)), 0, 1)
    glass_hole = np.clip(glass - guard, 0, 1)
    lay["a"] = lay["a"] * (1 - glass_hole)
    lay["masks"]["GLASS_HOLE"] = glass_hole
    sh = p4.contact_shadows_front(CVD) * (1 - np.clip(lay["a"], 0, 1))
    lay["masks"]["contact_shadow"] = sh
    rgba = np.dstack([to_srgb_u8(lay["lin"]), (np.clip(lay["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "design-front.png"))
    for n, m in lay["masks"].items():
        save_mask(m, os.path.join(OUT, "masks", f"front--{n}.png"))
    save_mask(lay["a"], os.path.join(OUT, "masks", "front--ALPHA.png"))
    # the slit check in the design: every design column from the guide's left edge to the chamfer's
    # right edge is opaque over the guide's height (rows at h 0.05..3.0 m)
    gx0 = p2.scr(p2.pt(p2.A_N + 0.02, 1.0, p2.GUIDE_T))[0]
    cx1 = p2.scr(p2.pt(p2.A_N, 1.0, p2.T_WALL))[0]
    x0, x1 = int(np.ceil((gx0 - CVD.x0) * CVD.ppw)) + 1, int(np.floor((cx1 - CVD.x0) * CVD.ppw)) - 1
    ytop = int(np.ceil((p2.scr(p2.pt(p2.A_N, 3.0, 0.0))[1] - CVD.y0) * CVD.ppw))
    ybot = int(np.floor((p2.scr(p2.pt(p2.A_N, 0.05, 0.0))[1] - CVD.y0) * CVD.ppw))
    band = lay["a"][ytop:ybot, x0:x1]
    old = np.asarray(Image.open(os.path.join(ROOT, "portal4", "masks", "front--ALPHA.png")).convert("L")).astype(np.float64)[ytop:ybot, x0:x1] / 255.0
    sm = lay["masks"]["guide_near_side"]
    vis = sm.copy()
    later = False
    for p in parts:
        if p.name == "guide_near_side":
            later = True
            continue
        if later:
            vis = vis * (1 - lay["masks"][p.name])
    ys, xs = np.nonzero(vis > 0.5)
    spec = json.load(open(os.path.join(ROOT, "portal4", "spec.json")))
    spec["parts"] = [{"name": p.name, "dims": p.dims, "job": p.job} for p in parts]
    spec["guide_return"] = {
        "a": round(p2.A_N - p2.GUIDE_W, 4), "t": [p2.GUIDE_T, -0.02], "h": [0.0, p2.H_OPEN],
        "visible_design_px_x": [int(xs.min()), int(xs.max())] if len(xs) else None,
        "slit_check_design_cols": [x0, x1], "slit_check_design_rows": [ytop, ybot],
        "min_alpha_v4": round(float(old.min()), 3), "min_alpha_v5": round(float(band.min()), 3),
        "transparent_px_v4": int((old < 0.999).sum()), "transparent_px_v5": int((band < 0.999).sum()),
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print(json.dumps(spec["guide_return"], indent=1))


if __name__ == "__main__":
    main()
