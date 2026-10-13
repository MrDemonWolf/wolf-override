"""Fix round 5 (v6) construction design of the corridor's door end: the v5 model (portal5.py) with
the round-5 review's must-fix 1.

  must 1   the status lamp's conduit gets a real top end, as the spec says ("from the camera's box").
           The 20 mm rigid conduit up the column's end face (lamp_conduit_up, a = A_END4 - 0.03, its
           centre at t = 0.25 m) now stops at h = HC - R_ELBOW, where a standard 90-degree conduit
           elbow (centre-line radius 100 mm) turns it toward the corner; a horizontal run at HC = 4.4125 m
           (the camera conduit's own height, 4.40..4.425 m) crosses the end face to the arris, held by
           one saddle strap at t = 0.09 m, wraps the corner 20 mm proud of the jamb's 160 mm approach
           face and enters the side of the camera's wall plate (its edge at a = A_END4 + 0.01), where
           the camera conduit (portal4 cam_conduit) already runs into the plate. Every end is on a box
           or a plate: lamp box below, camera wall plate above.
Everything else is portal5's, unchanged. Writes design/portal6/ (front layer render, part masks,
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
import portal5 as p5  # noqa: E402
import portal4 as p4  # noqa: E402
import portal2 as p2  # noqa: E402

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "portal6")
CVD = p4.CVD
A_E = p4.A_END4
TL = p4.T_END / 2  # the vertical conduit's centre on the end face
A_C = A_E - 0.03  # the conduit's plane, 30 mm proud of the end face
T_C = -0.02  # its plane on the approach face, 20 mm proud
HC = 4.4125  # horizontal run centre (the camera conduit's 4.40..4.425 m)
R_EL = 0.10  # elbow centre-line radius
HW = 0.012  # half the conduit's 24 mm outside diameter
CAM_A = A_E + 0.08
PLATE_EDGE_A = CAM_A - 0.07


def arc_poly(n: int = 24) -> list:
    """The elbow's outline in the end face's plane: centre (t, h) = (TL - R, HC - R), outer and inner
    radius R +- HW, from the vertical (angle 0) to the horizontal (angle 90 degrees)."""
    ct, ch = TL - R_EL, HC - R_EL
    th = np.linspace(0.0, np.pi / 2, n)
    outer = [p2.pt(A_C, ch + (R_EL + HW) * np.sin(a), ct + (R_EL + HW) * np.cos(a)) for a in th]
    inner = [p2.pt(A_C, ch + (R_EL - HW) * np.sin(a), ct + (R_EL - HW) * np.cos(a)) for a in th[::-1]]
    return p2.poly(outer + inner)


def front_parts_v6() -> list:
    P = p5.front_parts_v5()
    names = [p.name for p in P]
    i = names.index("lamp_conduit_up")
    sp = p2.side_plane(A_C)
    P[i] = p2.Part("front", "lamp_conduit_up", [p2.quad_side(A_C, TL - HW, TL + HW, p4.LAMP_H + 0.12, HC - R_EL)], p2.STEEL, sp,
                   "20 mm conduit up the end face, to the elbow", "feeds the lamp box from the camera's plate")
    new = [
        p2.Part("front", "lamp_conduit_elbow", [arc_poly()], p2.STEEL, sp,
                "20 mm 90-degree conduit elbow, 100 mm radius", "turns the run from the end face toward the camera's plate"),
        p2.Part("front", "lamp_conduit_run", [p2.quad_side(A_C, T_C - HW, TL - R_EL, HC - HW, HC + HW)], p2.STEEL, sp,
                "20 mm conduit across the end face at 4.41 m", "carries the lamp and station feed to the corner"),
        p2.Part("front", "lamp_conduit_corner", [p2.quad_face(A_C - HW, PLATE_EDGE_A + 0.005, HC - HW, HC + HW, T_C)], p2.STEEL, p2.face_plane(T_C),
                "20 mm conduit round the arris, 20 mm proud of the 160 mm approach face", "enters the side of the camera's wall plate"),
        p2.Part("front", "lamp_conduit_strap", [p2.quad_side(A_C - 0.006, 0.078, 0.102, HC - 0.022, HC + 0.022)], p2.STEEL_WORN, p2.side_plane(A_C - 0.006),
                "one-hole saddle strap 24 mm, anchored to the concrete", "holds the run to the end face"),
    ]
    j = names.index("lamp_conduit_up") + 1
    return P[:j] + new + P[j:]


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    parts = front_parts_v6()
    lay = p2.render(parts, CVD)["front"]
    lcx, lcy = p2.scr(p2.pt(A_E - 0.12, p4.LAMP_H, TL))
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
    # the conduit's chain, end to end, must touch: lamp box -> vertical -> elbow -> run -> corner -> plate
    M = lay["masks"]
    from scipy import ndimage

    def touch(a, b):
        return int(((ndimage.binary_dilation(M[a] > 0.3, iterations=2)) & (M[b] > 0.3)).sum())  # 2 design px: the lamp cap stands 70 mm proud of the conduit's plane

    chain = [("lamp_cap", "lamp_conduit_up"), ("lamp_conduit_up", "lamp_conduit_elbow"), ("lamp_conduit_elbow", "lamp_conduit_run"),
             ("lamp_conduit_run", "lamp_conduit_corner"), ("lamp_conduit_corner", "cam_plate")]
    joins = {f"{a}->{b}": touch(a, b) for a, b in chain}
    up_top = p2.scr(p2.pt(A_C, HC - R_EL, TL))
    plate_edge = p2.scr(p2.pt(PLATE_EDGE_A, HC, -0.01))
    spec = json.load(open(os.path.join(ROOT, "portal5", "spec.json")))
    spec["parts"] = [{"name": p.name, "dims": p.dims, "job": p.job} for p in parts]
    spec["lamp_conduit_top"] = {
        "plane_a": round(A_C, 4), "vertical_t": TL, "vertical_h": [round(p4.LAMP_H + 0.12, 3), round(HC - R_EL, 4)],
        "elbow_radius_m": R_EL, "run_h": HC, "run_t": [T_C, round(TL - R_EL, 3)], "strap_t": [0.078, 0.102],
        "corner_a": [round(A_C - HW, 4), round(PLATE_EDGE_A + 0.005, 4)], "camera_plate_edge_a": round(PLATE_EDGE_A, 4),
        "screen_vertical_top": [round(up_top[0], 2), round(up_top[1], 2)], "screen_plate_entry": [round(plate_edge[0], 2), round(plate_edge[1], 2)],
        "joins_design_px": joins, "all_joined": all(v > 0 for v in joins.values()),
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print(json.dumps(spec["lamp_conduit_top"], indent=1))


if __name__ == "__main__":
    main()
