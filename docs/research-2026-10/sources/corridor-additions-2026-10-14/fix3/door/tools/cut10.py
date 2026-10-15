"""Round 10 (add7 fix round 3) construction design: the safe-point room's camera-side wall as a CLEAN
ARCHITECTURAL CUTAWAY (Nathanial, 2026-10-14: "Show it as a clean cutaway", the way This War of Mine
and Fallout Shelter cut buildings open).

Round 9 (fix2/door/tools/cut9.py) carried the cross-wall from the near column's foot to the view's
edge, cut at 0.36 m, and finished it as a BUILT knee wall: galvanised edge angles on both arrises, M12
anchor heads, plugged form-tie holes, formed control joints and a damp foot. Both round-9 reviews read
that as a wall a player could step over. Round 10 keeps cut9's geometry exactly (same line, same
0.36 m cut, same 0.66 m thickness, same ends, so the engineer and the SAFE POINT machine stay whole)
and draws it as a section: one solid dark poche over the whole cut (corridor face and cut plane
together), bounded by clean straight edges, with no steel angles, anchors, tie holes, joints or damp
band. The only other thing kept is a real footprint shadow on the corridor floor at its foot, softer
than round 9's so the poche's foot edge stays crisp against the wet floor.

  cut_face   the cut wall's corridor face, 0..0.36 m          } one poche fill (cleanup10)
  cut_top    the cut plane, the wall's full 0.66 m thickness  }

Writes add7/fix3/door/design/: design-cut.png (the poche, flat), masks/, spec.json.
"""
from __future__ import annotations

import json
import os
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

F2T = "scratchpad/real-slice/add7/fix2/door/tools"
sys.path.insert(0, F2T)
import cut9  # noqa: E402  (read only: geometry, constants and its checks)
from cut9 import p2, p4, A_E, T, H_CUT, a_far  # noqa: E402
from common import save_mask, to_srgb_u8, write_json  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "design"))
CVD = cut9.CVD
POCHE = (0.0046, 0.0055, 0.0068)   # linear; about sRGB (12, 13, 15): a cool near-black, the scene's darkest neutral


def parts() -> list:
    Part, quad_face, quad_top = p2.Part, p2.quad_face, p2.quad_top
    af = a_far()
    return [
        Part("front", "cut_face", [quad_face(af, A_E, 0.0, H_CUT)], POCHE, p2.face_plane(0.0),
             "the cut wall's corridor face, 0..0.36 m, from the column's foot to the view's edge",
             "section poche: closes the plant room on the camera side (cutaway convention)"),
        Part("front", "cut_top", [quad_top(af, A_E, 0.0, T, H_CUT)], POCHE, p2.top_plane(H_CUT),
             "the cut plane, the wall's full 0.66 m", "section poche: the cut itself"),
    ]


def contact_shadow(canvas) -> np.ndarray:
    """A footprint shadow on the corridor floor at the cut wall's foot: 0.45 at the foot, 0.10 m
    falloff, gone by 0.40 m (round 9: 0.70, 0.14 m, 0.55 m), so the poche's foot stays a clean edge."""
    a, t, _ = p4.floor_coords(canvas)
    left = (a <= A_E + 0.02) & (t < 0)
    d = np.clip(-t, 0, 50)
    return np.where(left, 0.45 * np.exp(-d / 0.10) * np.clip((0.40 - d) / 0.15, 0, 1), 0.0)


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    P = parts()
    lay = p2.render(P, CVD)["front"]
    a = np.clip(lay["a"], 0, 1)
    lin = np.zeros(a.shape + (3,)) + np.array(POCHE)
    rgba = np.dstack([to_srgb_u8(lin), (a * 255 + 0.5).astype(np.uint8)])
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "design-cut.png"))
    for n, m in lay["masks"].items():
        save_mask(m, os.path.join(OUT, "masks", f"front--{n}.png"))
    save_mask(a, os.path.join(OUT, "masks", "front--CUT_ALPHA.png"))
    save_mask(contact_shadow(CVD) * (1 - a), os.path.join(OUT, "masks", "front--cut_contact_shadow.png"))
    spec = json.load(open(os.path.join(F2T, "..", "design", "spec.json")))
    out = {
        "height_m": H_CUT, "thickness_m": T, "a_from_to": [round(A_E, 4), round(a_far(), 4)],
        "geometry": "cut9's, unchanged (fix2/door/design/spec.json)",
        "engineer_clear": spec.get("engineer_clear"),
        "silhouette_top_y_over_safe_point_engineer_x818_843": spec.get("silhouette_top_y_over_safe_point_engineer_x818_843"),
        "poche_linear": POCHE, "poche_srgb": [int(v) for v in to_srgb_u8(np.array([POCHE]))[0]],
        "removed": ["cut_face_damp", "cut_ties", "cut_joint_face0/1", "cut_joint_top0/1", "cut_angle_top", "cut_angle_face", "cut_angle_far", "cut_anchors"],
        "parts": [{"name": p.name, "dims": p.dims, "job": p.job} for p in P],
    }
    write_json(os.path.join(OUT, "spec.json"), out)
    print(json.dumps({k: v for k, v in out.items() if k != "parts"}, indent=1))


if __name__ == "__main__":
    main()
