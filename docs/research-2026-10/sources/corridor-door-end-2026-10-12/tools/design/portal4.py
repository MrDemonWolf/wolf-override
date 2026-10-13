"""Fix round 3 (v4) construction design of the corridor's door end: the v3 model (portal3.py) with
the round-3 review's changes. Everything is in the plate's own camera (common.py, portal2.py).

  must 1   the near column is slim. The cross-wall now ends 0.16 m past the near jamb (A_END4 =
           A_N - 0.16: the approach face is only the jamb's 160 mm steel channel frame). Its end face
           toward the camera is 0.50 m of the wall's 0.66 m; the last 0.16 m is a 45-degree steel-plated
           chamfer on the plant-room corner. On screen the column (guide, frame, end face, chamfer)
           spans clamp-world x 787..817.5, so the engineer at the safe point (x 831, body from about
           x 820) stands clear of it. The status lamp, the push-button station and the camera stay on
           it at the same heights (lamp and station centred on the 0.5 m end face; the camera on the
           approach face). Nothing draws a silhouette over it.
  must 2a  the wall's line toward the camera follows the wall, not a screen vertical. The cross-wall
           is turned 17 degrees, so its horizontals meet the horizon at x 21 (VP2, as the door, hood,
           bar and marks do). Past the column it is cut down to a 0.15 m concrete stub (the section of
           the wall below the cutaway, read as a bund curb) whose top, approach-side face and lit
           steel edge angle run along the wall's own line to VP2 and leave the view at the room's right
           edge (about y 520). The corridor's wet floor is on its approach side, the plant room's dry
           slab on the other (far plate, cleanup4_far.py). Contact shadows run along both feet.
  bypass   the handwheel's hub moves to (694, 400), 1.0 m: the crank pose's glove lands on the rim at
           8 o'clock. The gearbox's input boss moves with it (cleanup4.py moves its paint).
Writes design/portal4/ (front layer render, part masks, contact shadows, spec.json).
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import common  # noqa: E402
from common import save_mask, to_srgb_u8, write_json  # noqa: E402
import portal3 as p3  # noqa: E402  (sets p2.CV = CVD and its rays)
import portal2 as p2  # noqa: E402

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "portal4")
CVD = p3.CVD
A_END4 = p2.A_N - 0.16
T_END = 0.50  # end face, of the wall's 0.66 m; the rest is the chamfer
STUB_H = 0.15
HUB4 = (694.0, 400.0)
LAMP_H = p2.LAMP_H
VP2 = (p2.VP2_X, common.HORIZON)


def chamfer_plane() -> "p2.Plane":
    p0 = p2.pt(A_END4, 0.0, T_END)
    p1 = p2.pt(p2.A_N, 0.0, p2.T_WALL)
    d = (p1 - p0) / np.linalg.norm(p1 - p0)
    n = np.cross(d, p2.EY)
    if n[2] > 0:
        n = -n
    return p2.Plane(p0, d, p2.EY, n)


def stub_far_a() -> float:
    """How far toward the camera the stub runs (in a) so it leaves the canvas at its right edge."""
    a = A_END4
    while p2.scr(p2.pt(a, 0.0, 0.0))[0] < CVD.x0 + CVD.w / CVD.ppw + 8.0:
        a -= 0.05
    return a


def front_parts_v4() -> list:
    Part, quad_face, quad_side, quad_top, poly, pt, scr = p2.Part, p2.quad_face, p2.quad_side, p2.quad_top, p2.poly, p2.pt, p2.scr
    P = []
    fp = p2.face_plane(0.0)
    A_E, A_N, H_TOP, T = A_END4, p2.A_N, p2.H_TOP, p2.T_WALL
    tl = T_END / 2
    P.append(Part("front", "pier_face", [quad_face(A_E, A_N, 0.0, H_TOP)], p2.CONCRETE, fp,
                  "the cross-wall's end beside the near jamb: 0.16 m along the face (the jamb's channel frame up to 3.21 m, concrete above)", "carries the idle-end guide", texture="concrete"))
    P.append(Part("front", "pier_end", [quad_side(A_E, 0.0, T_END, 0.0, H_TOP)], p2.CONCRETE, p2.side_plane(A_E),
                  "end face toward the camera, 0.50 m", "the wall's end; carries the status lamp and the push-button station", texture="concrete"))
    P.append(Part("front", "chamfer", [poly([pt(A_E, 0.0, T_END), pt(A_N, 0.0, T), pt(A_N, H_TOP, T), pt(A_E, H_TOP, T_END)])], p2.STEEL, chamfer_plane(),
                  "45-degree chamfer 0.16 x 0.16 m, faced with 10 mm steel plate", "armours the wall end's plant-room corner (no spalling edge)"))
    P.append(Part("front", "arris_end_left", [quad_side(A_E, 0.0, 0.065, 0.0, H_TOP)], p2.STEEL, p2.side_plane(A_E),
                  "65 mm steel arris angle", "armours the corner (carts, blast)"))
    P.append(Part("front", "arris_end_right", [quad_side(A_E, T_END - 0.05, T_END, 0.0, H_TOP)], p2.STEEL, p2.side_plane(A_E),
                  "50 mm steel angle where the end face meets the chamfer plate", "edges the chamfer plate"))
    P.append(Part("front", "arris_face", [quad_face(A_E, A_E + 0.065, 0.0, H_TOP, -0.004)], p2.STEEL, p2.face_plane(-0.004),
                  "steel arris angle, face leg", "armours the corner"))
    P.append(Part("front", "frame_near_jamb", [quad_face(A_N - 0.16, A_N, 0.0, p2.H_OPEN + 0.16, -0.02)], p2.GUNSHIP, p2.face_plane(-0.02),
                  "steel channel frame 160 mm", "armours the jamb; the guide bolts to it"))
    P.append(Part("front", "guide_near", [quad_face(A_N - p2.GUIDE_W, A_N + 0.02, 0.0, p2.H_OPEN, p2.GUIDE_T)], p2.GUNSHIP, p2.face_plane(p2.GUIDE_T),
                  "guide: three 50 mm angles", "the curtain's idle-end edge runs in it", texture="guide"))
    P.append(Part("front", "lamp_base", [quad_side(A_E - 0.10, tl - 0.09, tl + 0.09, LAMP_H - 0.17, LAMP_H - 0.10)], p2.HOUSING, p2.side_plane(A_E - 0.10),
                  "cast lamp body on a conduit box", "carries the globe"))
    P.append(Part("front", "lamp_conduit", [quad_side(A_E - 0.03, tl - 0.012, tl + 0.012, LAMP_H - 0.10, LAMP_H + 0.02)], p2.STEEL, p2.side_plane(A_E - 0.03),
                  "20 mm conduit", "feeds the lamp"))
    P.append(Part("front", "lamp_conduit_up", [quad_side(A_E - 0.03, tl - 0.012, tl + 0.012, LAMP_H + 0.12, 4.40)], p2.STEEL, p2.side_plane(A_E - 0.03),
                  "20 mm conduit up the end", "from the camera's box"))
    P.append(Part("front", "lamp_cap", [quad_side(A_E - 0.10, tl - 0.07, tl + 0.07, LAMP_H + 0.085, LAMP_H + 0.12)], p2.HOUSING, p2.side_plane(A_E - 0.10),
                  "guard cap", "tops the wire guard"))
    for i, dt in enumerate((-0.055, 0.0, 0.055)):
        P.append(Part("front", f"lamp_guard{i}", [quad_side(A_E - 0.13, tl + dt - 0.007, tl + dt + 0.007, LAMP_H - 0.10, LAMP_H + 0.09)], p2.STEEL, p2.side_plane(A_E - 0.13),
                      "wire guard bar", "protects the globe"))
    P.append(Part("front", "pb_backplate", [quad_side(A_E - 0.01, tl - 0.15, tl + 0.15, 1.42, 1.80)], p2.HOUSING, p2.side_plane(A_E - 0.01), "backplate", "carries the station"))
    P.append(Part("front", "pb_box", [quad_side(A_E - 0.10, tl - 0.12, tl + 0.12, 1.45, 1.77)], p2.GUNSHIP, p2.side_plane(A_E - 0.10),
                  "OPEN/CLOSE/STOP station at 1.6 m in a lockable cover", "push-button station"))
    P.append(Part("front", "pb_hinge", [quad_side(A_E - 0.11, tl - 0.12, tl - 0.10, 1.47, 1.75)], p2.DARK, p2.side_plane(A_E - 0.11), "cover hinge", "hinged cover"))
    P.append(Part("front", "pb_lock", [quad_side(A_E - 0.11, tl + 0.085, tl + 0.105, 1.60, 1.64)], p2.STEEL, p2.side_plane(A_E - 0.11), "cam lock", "keeps the cover shut"))
    for i, (h, col) in enumerate(((1.71, p2.DARK), (1.62, p2.DARK), (1.52, (0.09, 0.09, 0.095)))):
        c = scr(pt(A_E - 0.12, h, tl))
        P.append(Part("front", f"pb_button{i}", [("ellipse", c[0], c[1], 1.05, 1.05)], col, p2.side_plane(A_E - 0.12),
                      "22 mm button", ("open", "close", "stop (grey cap: the view's reds are the live lockdown beacons)")[i]))
    P.append(Part("front", "pb_conduit", [quad_side(A_E - 0.03, tl - 0.012, tl + 0.012, 1.80, LAMP_H - 0.17)], p2.STEEL, p2.side_plane(A_E - 0.03),
                  "20 mm conduit", "from the lamp box to the station"))
    cam_a, cam_h = A_E + 0.08, 4.35
    P.append(Part("front", "cam_plate", [quad_face(cam_a - 0.07, cam_a + 0.07, cam_h - 0.16, cam_h + 0.16, -0.01)], p2.HOUSING, p2.face_plane(-0.01),
                  "wall plate 0.14 x 0.32 m, two anchors", "fixes the arm"))
    P.append(Part("front", "cam_arm", [poly([pt(cam_a, cam_h + 0.03, -0.02), pt(cam_a, cam_h + 0.03, -0.42), pt(cam_a, cam_h - 0.03, -0.42), pt(cam_a, cam_h - 0.03, -0.02)])], p2.HOUSING,
                  p2.Plane(pt(cam_a, 0, 0), p2.N, p2.EY, -p2.U), "tubular arm 0.4 m", "holds the housing off the wall"))
    hx, hy = scr(pt(cam_a, cam_h, -0.44))
    P.append(Part("front", "cam_housing", [[(hx - 13.5, hy - 2.6), (hx + 1.5, hy - 3.4), (hx + 1.8, hy + 2.4), (hx - 13.0, hy + 3.6)]], p2.GUNSHIP, p2.front_plane(-2.7),
                  "fixed camera in a vandal-resistant housing 0.36 x 0.14 m", "watches the approach; static art, no glow"))
    P.append(Part("front", "cam_sunshield", [[(hx - 14.6, hy - 4.2), (hx + 2.0, hy - 5.0), (hx + 2.2, hy - 3.3), (hx - 14.2, hy - 2.5)]], p2.HOUSING, p2.front_plane(-2.7),
                  "sunshield", "the housing's top cover"))
    P.append(Part("front", "cam_window", [[(hx - 13.6, hy - 2.0), (hx - 12.2, hy - 2.2), (hx - 11.8, hy + 3.0), (hx - 13.1, hy + 3.2)]], p2.DARK, p2.front_plane(-2.7),
                  "front window", "dark lens window"))
    P.append(Part("front", "cam_conduit", [quad_face(cam_a - 0.012, cam_a + 0.012, 4.40, cam_h - 0.16, -0.02), quad_face(A_E + 0.02, cam_a, 4.40, 4.425, -0.02)], p2.STEEL, p2.face_plane(-0.02),
                  "20 mm conduit", "camera feed down to the lamp box"))
    # the stub: the wall cut down to 0.15 m past its end, toward the camera along the wall's own line
    a_far = stub_far_a()
    P.append(Part("front", "stub_face", [quad_face(a_far, A_E, 0.0, STUB_H)], p2.CONCRETE, p2.face_plane(0.0),
                  "the cross-wall's 0.15 m stub, approach-side face", "the wall's line carried to the camera (cutaway): a bund curb between the corridor and the plant room", texture="concrete"))
    P.append(Part("front", "stub_top", [quad_top(a_far, A_E, 0.0, T, STUB_H)], p2.CONCRETE, p2.top_plane(STUB_H),
                  "stub top, the wall's 0.66 m thickness", "the cut section, seen from above", texture="concrete"))
    P.append(Part("front", "stub_angle_top", [quad_top(a_far, A_E, 0.0, 0.065, STUB_H + 0.003)], p2.STEEL_WORN, p2.top_plane(STUB_H + 0.003),
                  "65 mm steel edge angle, top leg", "armours the curb's corridor edge (carts)"))
    P.append(Part("front", "stub_angle_face", [quad_face(a_far, A_E, STUB_H - 0.065, STUB_H, -0.004)], p2.STEEL, p2.face_plane(-0.004),
                  "65 mm steel edge angle, face leg", "armours the curb's corridor edge"))
    P.append(Part("front", "stub_angle_far", [quad_top(a_far, A_E, T - 0.05, T, STUB_H + 0.003)], p2.STEEL_WORN, p2.top_plane(STUB_H + 0.003),
                  "50 mm steel edge angle, top leg, plant-room side", "armours the curb's plant-room edge (pallet trucks)"))
    return P


def floor_coords(canvas, h=0.0):
    """Per pixel: the floor point at height h, as (a, t) in the wall's frame (a along U from O,
    t along N), and the depth."""
    A, B = p2.rays(canvas)
    tt = (h - A[1]) / np.where(np.abs(B[..., 1]) < 1e-9, -1e-9, B[..., 1])
    P = A + B * tt[..., None]
    rel = P - p2.O
    return (rel * p2.U).sum(-1), (rel * p2.N).sum(-1), P


def contact_shadows_front(canvas) -> np.ndarray:
    """Footprint contact shadows on the floor round the stub and the column's foot (alpha on
    near-black), darkest at the contact line: along the stub's corridor-side foot (t < 0), along its
    plant-side foot (t > 0.66, its face hidden from the camera), and on the corridor floor in front of
    the column's approach face."""
    a, t, _ = floor_coords(canvas)
    sh = np.zeros(a.shape)
    near = a <= A_END4 + 0.02
    left = near & (t < 0)
    sh = np.maximum(sh, np.where(left, 0.62 * np.exp(-np.clip(-t, 0, 50) / 0.10), 0))
    right = near & (t > p2.T_WALL)
    sh = np.maximum(sh, np.where(right, 0.55 * np.exp(-np.clip(t - p2.T_WALL, 0, 50) / 0.12), 0))
    # in front of the column's approach face (the frame's foot), corridor side
    face = (a >= A_END4) & (a <= p2.A_N) & (t < 0)
    sh = np.maximum(sh, np.where(face, 0.58 * np.exp(-np.clip(-t, 0, 50) / 0.14), 0))
    return sh


def wall_contact_shadow(canvas) -> np.ndarray:
    """The wall layer's floor contact shadow along the far column's approach-side foot (the near
    pier's part is now the column's own, in the front layer)."""
    a, t, _ = floor_coords(canvas)
    a0, a1 = p2.A_F + 0.16, p2.A_BACK
    inside = (a >= a0) & (a <= a1) & (t <= 0)
    edge = np.clip(np.minimum(a - a0, a1 - a) / 0.15, 0, 1)
    return np.where(inside, 0.58 * np.exp(-np.clip(-t, 0, 50) / 0.16) * edge, 0)


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    parts = front_parts_v4()
    lay = p2.render(parts, CVD)["front"]
    # the lamp's glass is a hole (the live lens draws under the guard bars)
    tl = T_END / 2
    lcx, lcy = p2.scr(p2.pt(A_END4 - 0.12, LAMP_H, tl))
    glass = p2.mask_of([("ellipse", lcx, lcy, 2.05, 2.55)], CVD)
    guard = np.clip(sum(lay["masks"][f"lamp_guard{i}"] for i in range(3)), 0, 1)
    glass_hole = np.clip(glass - guard, 0, 1)
    lay["a"] = lay["a"] * (1 - glass_hole)
    lay["masks"]["GLASS_HOLE"] = glass_hole
    sh = contact_shadows_front(CVD) * (1 - np.clip(lay["a"], 0, 1))
    lay["masks"]["contact_shadow"] = sh
    rgba = np.dstack([to_srgb_u8(lay["lin"]), (np.clip(lay["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "design-front.png"))
    for n, m in lay["masks"].items():
        save_mask(m, os.path.join(OUT, "masks", f"front--{n}.png"))
    save_mask(lay["a"], os.path.join(OUT, "masks", "front--ALPHA.png"))
    save_mask(wall_contact_shadow(CVD), os.path.join(OUT, "masks", "wall--contact_shadow.png"))
    # the column's extent on screen and the stub's line
    col_x = [p2.scr(p2.pt(A_END4, 1.0, 0.0))[0], p2.scr(p2.pt(p2.A_N, 1.0, p2.T_WALL))[0], p2.scr(p2.pt(A_END4, 1.0, T_END))[0]]
    guide_x = p2.scr(p2.pt(p2.A_N - p2.GUIDE_W, 1.0, p2.GUIDE_T))[0]
    a_far = stub_far_a()
    line = [p2.scr(p2.pt(a, 0.0, 0.0)) for a in (A_END4, a_far)]
    slope = (line[1][1] - line[0][1]) / (line[1][0] - line[0][0])
    lamp = p2.scr(p2.pt(A_END4 - 0.12, LAMP_H, tl))
    spec = {
        "column": {"a_end": round(A_END4, 4), "approach_face_m": 0.16, "end_face_m": T_END, "chamfer_m": [0.16, 0.16],
                   "screen_x_at_1m": {"guide_left": round(guide_x, 2), "end_face_left": round(col_x[0], 2), "end_face_right": round(col_x[2], 2), "chamfer_right": round(col_x[1], 2)},
                   "foot": [list(map(lambda v: round(v, 2), p2.scr(p2.pt(A_END4, 0.0, 0.0)))), list(map(lambda v: round(v, 2), p2.scr(p2.pt(A_END4, 0.0, T_END))))]},
        "stub": {"height_m": STUB_H, "thickness_m": p2.T_WALL, "corridor_edge_screen": [list(map(lambda v: round(v, 2), q)) for q in line],
                 "screen_slope": round(slope, 4), "vanishing_point": [round(VP2[0], 2), round(VP2[1], 2)],
                 "slope_check": "a line on the floor along the wall's direction runs to VP2: (y - 158.5) / (x - 21) = %.4f at the column foot" % ((line[0][1] - VP2[1]) / (line[0][0] - VP2[0]))},
        "lamp_screen": [round(lamp[0], 3), round(lamp[1], 3)],
        "bypass_hub": HUB4, "bypass_hub_height_m": round((440.0 - HUB4[1]) / 40.0, 3),
        "parts": [{"name": p.name, "dims": p.dims, "job": p.job} for p in parts],
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print(json.dumps({k: spec[k] for k in ("column", "stub", "lamp_screen", "bypass_hub")}, indent=1))


if __name__ == "__main__":
    main()
