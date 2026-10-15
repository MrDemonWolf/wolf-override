"""Round 9 (add7 fix round 2) construction design: the cross-wall carried to the camera as a CUT
CONCRETE SECTION, so DOOR 4B-07 is the only way into the plant room.

Both round-8 reviews (real MUST 1, human MUST): right of the near column the corridor's wet floor ran
on in front of a 0.15 m curb (round 4's 'stub') into the plant room one step up, so a first-time
player reads 'step up and walk round the door'. Fix (the real review's preferred one): the same wall,
on the same line, from the column's foot to the bottom-right edge of the view, cut down to
H_CUT = 0.36 m (the cutaway convention: the wall is there, the camera's section plane takes it down
so the plant room stays readable). The review asked for about 0.6-0.7 m, below the safe point's
plinth; measured against the engineer standing at the safe point, the section's PLANT-ROOM arris
(the far edge of its 0.66 m top, which starts at the column's chamfer) crosses their boots above
about 0.38 m (at 0.60 m it hides up to 5 world px of both boots; a first try at 0.42 m still took the
bottom 1-2 screen px of the rear heel in a render.sh capture), so 0.36 m is the cut that leaves them
whole with a margin:

  cut_face          the wall's corridor face, cast concrete, 0..0.36 m, along the stub's own line
                    (VP2, slope 0.385) from the column's foot (a = A_END4) to the view's edge
  cut_face_damp     its bottom 0.10 m, darker: the wet corridor floor wicks into the concrete
  cut_ties          plugged formwork tie holes (25 mm) at 0.18 m, every 0.60 m (a cast wall's tie grid)
  cut_joint*        formed control joints (20 mm) at 3.0 m and 6.0 m from the column, face and top
  cut_top           the section's top: the wall's full 0.66 m, cast concrete, seen from above
  cut_angle_top/face  65 mm galvanised steel edge angle on the corridor arris, anchored every 0.6 m
  cut_angle_far     50 mm angle on the plant-room arris
  cut_anchor*       M12 anchor heads on the face leg, every 0.60 m
  contact shadow    a footprint shadow on the corridor floor along the face's foot, stronger and
                    wider than the curb's (0.70, 0.14 m falloff, gone by 0.55 m: a taller wall occludes more light)

Heights checked against the engineer at the safe point (x 817-843, soles at y 440): the top line is
at y >= 440.0 there, so no boot is cut, and below the safe point's plinth everywhere (it reaches
y 459.6 under the station's centre). Everything else in the front layer is round 8's.
Writes add7/fix2/door/design/: design-cut.png (flat lit construction, CVD canvas), masks/, spec.json.
"""
from __future__ import annotations

import json
import os
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

R7T = "scratchpad/real-slice/add7/door/tools"
sys.path.insert(0, R7T)
from stack import common, p2, p3, p4  # noqa: E402
from common import save_mask, to_srgb_u8, write_json  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "design"))
CVD = p3.CVD
A_E = p4.A_END4
T = p2.T_WALL
H_CUT = 0.36
TIE_H, TIE_PITCH, TIE_R_M = 0.18, 0.60, 0.0125
JOINTS = (3.0, 6.0)          # metres from the column, toward the camera
ANCHOR_PITCH = 0.60
SAFE_ENGINEER_X = (817.8, 843.0)   # measured in render.sh s7 frames: boot pixels from screen x 1022
SOLE_Y = 438.6   # measured: the rear sole's last row is screen y 501 (render.sh s7, 1280x720)


def a_far() -> float:
    a = p4.stub_far_a()
    return a - 0.6   # a little past the canvas edge so no end ever shows


def parts() -> list:
    Part, quad_face, quad_top, pt, scr = p2.Part, p2.quad_face, p2.quad_top, p2.pt, p2.scr
    af = a_far()
    P = []
    P.append(Part("front", "cut_face", [quad_face(af, A_E, 0.0, H_CUT)], p2.CONCRETE, p2.face_plane(0.0),
                  "the cross-wall's corridor face, cut at 0.36 m, from the column's foot to the view's edge",
                  "closes the plant room on the camera side: DOOR 4B-07 is the only way in (cutaway)", texture="concrete"))
    P.append(Part("front", "cut_face_damp", [quad_face(af, A_E, 0.0, 0.10, -0.0005)], tuple(np.array(p2.CONCRETE) * 0.80), p2.face_plane(-0.0005),
                  "bottom 0.10 m of the face", "damp where the wet corridor floor wicks into the concrete"))
    ties = []
    a = A_E - TIE_PITCH / 2
    while a > af:
        c = scr(pt(a, TIE_H, -0.001))
        ties.append(("ellipse", c[0], c[1], TIE_R_M * 40.0 * 0.9, TIE_R_M * 40.0))
        a -= TIE_PITCH
    P.append(Part("front", "cut_ties", ties, tuple(np.array(p2.CONCRETE) * 0.72), p2.face_plane(-0.001),
                  "25 mm plugged formwork tie holes at 0.18 m, 0.60 m pitch", "a cast-in-place wall's tie grid"))
    for i, d in enumerate(JOINTS):
        aj = A_E - d
        P.append(Part("front", f"cut_joint_face{i}", [quad_face(aj - 0.010, aj + 0.010, 0.0, H_CUT - 0.065, -0.001)], p2.CONCRETE_DK, p2.face_plane(-0.001),
                      "20 mm formed control joint", "lets the wall shrink without cracking"))
        P.append(Part("front", f"cut_joint_top{i}", [quad_top(aj - 0.010, aj + 0.010, 0.065, T - 0.05, H_CUT + 0.001)], p2.CONCRETE_DK, p2.top_plane(H_CUT + 0.001),
                      "the joint across the top", "as above"))
    P.append(Part("front", "cut_top", [quad_top(af, A_E, 0.0, T, H_CUT)], p2.CONCRETE, p2.top_plane(H_CUT),
                  "the section's top, the wall's full 0.66 m", "the cut, seen from above", texture="concrete"))
    P.append(Part("front", "cut_angle_top", [quad_top(af, A_E, 0.0, 0.065, H_CUT + 0.003)], p2.STEEL_WORN, p2.top_plane(H_CUT + 0.003),
                  "65 mm galvanised steel edge angle, top leg", "armours the corridor arris (carts, hands)"))
    P.append(Part("front", "cut_angle_face", [quad_face(af, A_E, H_CUT - 0.065, H_CUT, -0.004)], p2.STEEL, p2.face_plane(-0.004),
                  "65 mm edge angle, face leg", "armours the corridor arris"))
    P.append(Part("front", "cut_angle_far", [quad_top(af, A_E, T - 0.05, T, H_CUT + 0.003)], p2.STEEL_WORN, p2.top_plane(H_CUT + 0.003),
                  "50 mm steel edge angle, plant-room arris", "armours the plant-room arris"))
    anchors = []
    a = A_E - 0.30
    while a > af:
        c = scr(pt(a, H_CUT - 0.032, -0.006))
        anchors.append(("ellipse", c[0], c[1], 0.42, 0.42))
        a -= ANCHOR_PITCH
    P.append(Part("front", "cut_anchors", anchors, p2.DARK, p2.face_plane(-0.006),
                  "M12 anchor heads in the face leg, 0.60 m pitch", "fix the angle to the concrete"))
    return P


def contact_shadow(canvas) -> np.ndarray:
    a, t, _ = p4.floor_coords(canvas)
    near = a <= A_E + 0.02
    left = near & (t < 0)
    d = np.clip(-t, 0, 50)
    # 0.70 at the foot, 0.14 m falloff, faded out between 0.35 and 0.55 m (the curb's reached 0.5 m)
    return np.where(left, 0.70 * np.exp(-d / 0.14) * np.clip((0.55 - d) / 0.20, 0, 1), 0.0)


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    P = parts()
    lay = p2.render(P, CVD)["front"]
    sh = contact_shadow(CVD) * (1 - np.clip(lay["a"], 0, 1))
    rgba = np.dstack([to_srgb_u8(lay["lin"]), (np.clip(lay["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "design-cut.png"))
    for n, m in lay["masks"].items():
        save_mask(m, os.path.join(OUT, "masks", f"front--{n}.png"))
    save_mask(lay["a"], os.path.join(OUT, "masks", "front--CUT_ALPHA.png"))
    save_mask(sh, os.path.join(OUT, "masks", "front--cut_contact_shadow.png"))
    # checks: the top line against the engineer's soles at the safe point and the station's plinth
    scr, pt = p2.scr, p2.pt
    top = np.array([scr(pt(a, H_CUT, 0.0)) for a in np.linspace(A_E, a_far(), 400)])
    far = np.array([scr(pt(a, H_CUT, T)) for a in np.linspace(A_E, a_far(), 400)])

    def top_y_at(x, line=top):
        # left of a line's first point (the plant-room arris starts at the column's chamfer, x 820.9)
        # the junction is grouted level with it (cleanup9), so the line is carried on flat
        return float(np.interp(x, line[:, 0], line[:, 1]))
    # the section's silhouette top at x is the higher (smaller y) of its two arrises
    eng = [round(min(top_y_at(x), top_y_at(x, far)), 2) for x in np.linspace(*SAFE_ENGINEER_X, 6)]
    foot = [scr(pt(a, 0.0, 0.0)) for a in (A_E, a_far())]
    spec = {
        "height_m": H_CUT, "thickness_m": T, "a_from_to": [round(A_E, 4), round(a_far(), 4)],
        "foot_line_screen": [list(map(lambda v: round(v, 2), q)) for q in foot],
        "silhouette_top_y_over_safe_point_engineer_x818_843": eng, "engineer_sole_y": SOLE_Y,
        "engineer_clear": bool(min(eng) >= SOLE_Y + 0.5),
        "silhouette_top_y_at_station_x841_911": [round(min(top_y_at(x), top_y_at(x, far)), 2) for x in (841.0, 876.0, 911.0)],
        "parts": [{"name": p.name, "dims": p.dims, "job": p.job} for p in P],
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print(json.dumps({k: v for k, v in spec.items() if k != "parts"}, indent=1))


if __name__ == "__main__":
    main()
