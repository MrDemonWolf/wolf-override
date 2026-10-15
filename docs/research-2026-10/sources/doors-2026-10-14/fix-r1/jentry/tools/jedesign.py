"""Junction entry door (doors-r1, fix round 1, M5): construction design. Scratch only; no image tool
touches this step.

The engineer comes into the Service Junction from the service line passage (the passage the Records
exit opens on), so the junction's left end is the same kind of door end as the Records doors, in the
junction's own camera (jemodel.py: vanishing point (511, 162)): a 300 mm cast cross-wall turned 17
degrees across the walkway, its approach face crossing the walk line at XE = 30, with a 3'0" x 7'0"
hollow-metal steel door (SDI 129 hinge spacing, ICD/ICS 705-style automatic non-hold closer on the
junction side) that swings INTO the junction on its hinges at the far jamb. It stands open behind the
arriving pair and its closer brings it shut. The passage beyond (concrete, the service line's two
pipes and its cable ladder running on toward Records, one vapour-tight fitting) is painted behind the
doorway. It replaces the camera-facing round pressure hatch (junction-hatch.png).

XE = 30 because WOLF's authored waiting spot by the entrance (JunctionRoom.WOLF_CLEAR_X 100, his
tail at x 33) must stay clear of the wall's near column (its right edge at 1 m about x 16) and of the
part of the shut leaf in front of the walk line. The engineer's collision face is the leaf at x 30.

Reuses rdesign.py's parts (wall, column, stub, leaf faces) with jemodel as the model; the junction's
own lamps, wear seeds, pour joint and passage are set here. Writes design/{entry,leaf}/.
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jemodel as M  # noqa: E402
sys.modules["rmodel"] = M
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "records", "tools"))
import rdesign as RD  # noqa: E402
from rmodel import Part, Lamp, DoorEnd, Canvas, Plane, EY  # noqa: E402

XE = 30.0
FAR_SHIFT_LEFT = -12.444  # the far plate's parallax at the camera's left clamp (camera x 355.556)
PASSAGE_D = 1.6
RD.PIPE_RUNS = ()  # no pipe runs of the room pass this wall
RD.POUR_H = {1: 3.6, -1: 3.3}  # its own lift


def lamps():
    door = DoorEnd(-1, XE)
    f_door = Lamp("entry door light: vapour-tight LED 0.6 m on the cross-wall face over the door", door.pt(0.0, 2.80, -0.10), (0.86, 0.95, 1.0), 0.95, 1.4, 2.0)
    f_room = Lamp("junction ceiling lamp 0 (far plate, painted)", M.from_screen(133.4 + FAR_SHIFT_LEFT, 223.7, 4.2), (0.62, 0.9, 1.0), 1.1, 3.4, 1.5)
    f_pass = Lamp("service line passage light: vapour-tight LED on the passage back wall", M.from_screen(-14.0, 300.0, PASSAGE_D - 0.12), (0.80, 0.92, 1.0), 0.75, 1.5, 1.5)
    bounce = Lamp("wet deck bounce (fill)", np.array([door.O[0] + 2.0, 0.1, -3.0]), (0.55, 0.75, 0.85), 0.10, 4.0)
    return door, [f_door, f_room, f_pass, bounce]


def beyond_parts(door):
    """The service line passage behind the wall, as seen at the left clamp: its back wall PASSAGE_D
    behind the walk line, the dry slab, the service line's pipes and cable ladder running on toward
    Records, one fitting. Only what lies past the cross-wall's room face is drawn (no parallax gap)."""
    P = []
    Dp = PASSAGE_D

    def beyond_wall(Pp):
        t = ((Pp - door.O) * door.N).sum(-1)
        return np.clip((t - 0.02) / 0.04, 0, 1)

    x0, x1 = -70.0, 80.0

    def rect_d(xa, xb, h0, h1, dd):
        a = M.project(xa, h0, dd)
        b = M.project(xb, h1, dd)
        return [(a[0], a[1]), (b[0], a[1]), (b[0], b[1]), (a[0], b[1])]

    def xw(X, dd):
        return M.VPX + (X - M.VPX) / M.depth_scale(dd)
    bw = M.front_plane(Dp)
    P.append(Part("beyond", "back_wall", [rect_d(xw(x0, Dp), xw(x1, Dp), 0.0, 8.5, Dp)], M.CONCRETE, bw, "the passage's back wall, cast concrete", "the far side of the service line passage",
                  mod=lambda P_, la, lb: (1.0 + 0.07 * RD._noise2(la, lb, 1.1, 0.9, 101)) * (1.0 - 0.3 * np.clip(1.0 - lb / 0.16, 0, 1))))
    fl = Plane(np.array([0, 0.0, 0]), np.array([1.0, 0, 0]), np.array([0, 0, 1.0]), EY)
    fa = M.project(xw(x0, -3.0), 0.0, -3.0)
    fb = M.project(xw(x1, -3.0), 0.0, -3.0)
    fc = M.project(xw(x1, Dp), 0.0, Dp)
    fd = M.project(xw(x0, Dp), 0.0, Dp)
    P.append(Part("beyond", "floor", [[fd, fc, (fc[0], fb[1] + 40.0), (fd[0], fa[1] + 40.0)]], (0.17, 0.175, 0.185), fl, "the same slab, dry", "the passage floor"))
    P.append(Part("beyond", "pour_joint", [rect_d(xw(x0, Dp), xw(x1, Dp), 3.3 - 0.012, 3.3 + 0.012, Dp - 0.002)], M.CONCRETE_DK, M.front_plane(Dp - 0.002), "pour line", "construction joint", texture="seam"))
    for i, (h, r, dd) in enumerate(((2.20, 0.075, Dp - 0.25), (2.48, 0.055, Dp - 0.22))):
        P.append(Part("beyond", f"pipe{i}", [rect_d(xw(x0, dd), xw(x1, dd), h - r, h + r, dd)], (0.20, 0.215, 0.24), M.front_plane(dd),
                      ("150 mm" if i == 0 else "100 mm") + " steel pipe, painted", "the service line (chilled water supply and return), on toward Records"))
    P.append(Part("beyond", "tray_rail", [rect_d(xw(x0, Dp - 0.40), xw(x1, Dp - 0.40), 2.95, 3.05, Dp - 0.40)], M.STEEL, M.front_plane(Dp - 0.40),
                  "cable ladder side rail 100 mm, 400 mm wide tray", "carries the data and power cables along the passage"))
    for k, X in enumerate((-50.0, 10.0, 70.0)):
        xa = xw(X, Dp - 0.02)
        P.append(Part("beyond", f"strut{k}", [rect_d(xa - 1.0, xa + 1.0, 2.05, 3.10, Dp - 0.02)], M.HOUSING, M.front_plane(Dp - 0.02), "41 mm strut bracket, anchored", "holds the pipes and the tray"))
    lx, ly = -14.0, 300.0
    lw = 0.60 * M.PX_PER_M * M.depth_scale(Dp - 0.12) / 2
    P.append(Part("beyond", "light_body", [[(lx - lw, ly - 1.6), (lx + lw, ly - 1.6), (lx + lw, ly + 1.2), (lx - lw, ly + 1.2)]], M.HOUSING, M.front_plane(Dp - 0.12), "vapour-tight LED fitting 0.6 m", "lights the passage"))
    P.append(Part("beyond", "light_diffuser", [[(lx - lw + 0.6, ly + 1.2), (lx + lw - 0.6, ly + 1.2), (lx + lw - 0.6, ly + 2.0), (lx - lw + 0.6, ly + 2.0)]], (1, 1, 1), None, "opal diffuser, lit", "the fitting's lens", emit=(0.80, 0.90, 0.96)))
    P.append(Part("beyond", "light_conduit", [[(lx - lw + 1.1, 100.0), (lx - lw + 1.9, 100.0), (lx - lw + 1.9, ly - 1.6), (lx - lw + 1.1, ly - 1.6)]], M.STEEL, M.front_plane(Dp - 0.04), "20 mm conduit", "feeds the fitting"))
    for p in P:
        if p.emit is None:
            p.clipfn = beyond_wall
    return P


def main():
    door, lps = lamps()
    RD.lamps_for = lambda side: (door, lps, lps[0], lps[2])
    RD.OUT = M.DESIGN
    cv = Canvas("jentry", -60.0, 140.0, 4.0, 4 * 230, 4 * 330)
    out = os.path.join(M.DESIGN, "entry")
    os.makedirs(os.path.join(out, "masks"), exist_ok=True)
    walls = RD.wall_parts(door, lps)
    fronts, a_far = RD.front_parts(door, -60.0)
    beyond = beyond_parts(door)
    layers = M.render(walls + fronts + beyond, cv, lps)
    wl, fr, by = layers["wall"], layers["front"], layers["beyond"]
    wall_sh = RD.wall_contact_shadow(door, cv) * (1 - np.clip(wl["a"], 0, 1))
    front_sh = RD.front_contact_shadow(door, cv) * (1 - np.clip(fr["a"], 0, 1))
    lx, ly = RD.lamp_screen(door)
    glass = M.mask_of([("ellipse", lx, ly, 1.9, 2.4)], cv)
    guard = np.clip(sum(fr["masks"][f"lamp_guard{i}"] for i in range(3)), 0, 1)
    glass_hole = np.clip(glass - guard, 0, 1)
    fr["a"] = fr["a"] * (1 - glass_hole)
    fr["masks"]["GLASS_HOLE"] = glass_hole
    from PIL import Image
    for name, lay, sh in (("wall", wl, wall_sh), ("front", fr, front_sh), ("beyond", by, None)):
        a = np.clip(lay["a"], 0, 1)
        rgb = M.to_srgb_u8(lay["lin"])
        if sh is not None:
            a_total = a + sh * (1 - a)
            rgb = (rgb.astype(np.float64) * (a / np.maximum(a_total, 1e-6))[..., None] + 6.0 * (sh * (1 - a) / np.maximum(a_total, 1e-6))[..., None]).astype(np.uint8)
            a = a_total
            M.save_mask(sh, os.path.join(out, "masks", f"{name}--contact_shadow.png"))
        Image.fromarray(np.dstack([rgb, (a * 255 + 0.5).astype(np.uint8)]), "RGBA").save(os.path.join(out, f"design-{name}.png"))
        M.save_mask(np.clip(lay["a"], 0, 1), os.path.join(out, "masks", f"{name}--ALPHA.png"))
        for n, m in lay["masks"].items():
            M.save_mask(m, os.path.join(out, "masks", f"{name}--{n}.png"))
    spec = {
        "canvas": {"x0": cv.x0, "y0": cv.y0, "ppw": cv.ppw, "w": cv.w, "h": cv.h},
        "camera": {"vp": [M.VPX, M.HORIZON], "d0_m": M.D0},
        "door": {"side": -1, "x_cross": door.xc, "wall_m": door.T_WALL, "leaf_m": [door.LEAF_W, door.LEAF_H, door.LEAF_T],
                 "hinge_foot_m": [round(float(v), 5) for v in door.hinge], "axis_u": [round(float(v), 6) for v in door.U], "axis_n": [round(float(v), 6) for v in door.N],
                 "near_jamb_foot": [round(v, 2) for v in door.s(door.A_N, 0.0)], "far_jamb_foot": [round(v, 2) for v in door.s(door.A_F, 0.0)],
                 "column_end_face_at_1m": [round(door.s(door.A_END, 1.0, 0.0)[0], 2), round(door.s(door.A_END, 1.0, door.T_WALL)[0], 2)],
                 "back_end_foot": [round(v, 2) for v in door.s(door.A_BACK, 0.0)], "stub_far_a": round(a_far, 3), "status_lamp_screen": [round(lx, 3), round(ly, 3)]},
        "lamps": [{"name": l.name, "pos_m": [round(float(v), 3) for v in l.pos], "screen": [round(v, 2) for v in M.scr(l.pos)], "colour_x_intensity": [round(c * l.intensity, 4) for c in l.color], "reach_m": l.reach, "down": l.down} for l in lps],
        "parts": [{"layer": p.layer, "name": p.name, "dims": p.dims, "job": p.job} for p in walls + fronts + beyond],
    }
    M.write_json(os.path.join(out, "spec.json"), spec)
    RD.leaf_faces()
    print(spec["door"])


if __name__ == "__main__":
    main()
