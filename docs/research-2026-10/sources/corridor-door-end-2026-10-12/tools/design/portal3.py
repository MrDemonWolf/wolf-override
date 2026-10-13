"""Fix round 2 (v3) construction design of the corridor's door end. It is the v2 model (portal2.py:
the cast cross-wall across the walkway, its face turned 17 degrees, the rolling door in it) with the
round-2 review's changes:

  must-fix 2  the cross-wall reaches the camera: the near pier's end face carries on as the wall's
              cut section straight down past the bottom of the view (PIER CUT, front layer, with
              its steel arris angles), and right of it the plant room's own dry slab runs down to the
              bottom of the frame (NEAR SLAB, far plate) with saw-cut joints, so the corridor's wet
              floor ends at the wall. The end face's foot shadow and foot damp are gone (the wall
              no longer ends there); a contact shadow runs down both sides of the cut instead.
  must-fix 3  MANUAL BYPASS is a wall-mounted override: an anchored backplate on the corridor back
              wall at the cross-wall's corner, a worm gearbox with the handwheel's hub at 1.05 m
              (world y 398, the wheel sprite moves up 5 px), and an enclosed chain guard running
              straight up the wall in two clamp brackets into the door operator at 3.1 m. The floor
              stand, its diagonal shaft and its floor shadow are gone.
  small 4     the yellow floor line at the door's travel is 120 mm wide (it vanished at 60 mm).
  small 5     the push-button station's stop button is grey: the view's reds are the live beacons.
  must-fix 5  the far column gets a pour joint at the head line (h 3.05 m), where the cross-wall's
              lower part (behind the actors, mid plate) meets its upper part (front layer), so the
              layer split follows a real construction joint.

Canvases: CVD, the cleanup canvas, 4 px per world px over world x 676..984, y 150..625 (the v2
canvas CV was x 680..845, y 150..480; it sits at +16, +0 px in CVD). CVP, the paint canvas: the
1024 x 1024 edit target, world x 640..974, y 286..620 (3.066 px per world px).
Writes design/portal3/.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import common
from common import Canvas, to_srgb_u8, from_srgb_u8, save_mask, write_json, depth_scale, VPX, HORIZON, PX_PER_M
import portal2 as p2
import far_patch as fp

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "portal3")
CVD = Canvas("portal3", x0=676.0, y0=150.0, ppw=4.0, w=1232, h=1900)
CVP = Canvas("paint3", x0=640.0, y0=286.0, ppw=1024.0 / 334.0, w=1024, h=1024)
CV2_OFFSET = (16, 0)  # v2 canvas CV inside CVD, px

# the v2 model's per-pixel rays follow the design canvas
p2.CV = CVD
p2.RAY_A, p2.RAY_B = p2.rays(CVD)

HUB = (695.0, 398.0)  # handwheel hub: 1.05 m at the walk line (440 - 1.05 * 40)
BYPASS_LAMPS = (p2.F_CORR, p2.F_DOOR, p2.F_BOUNCE)  # the plant-room lamps are behind the wall
BAND_BOTTOM = 625.0
SPLIT_H = 3.05  # the cross-wall above this height goes to the front layer
REMOVED_V2 = ("stand_base", "stand_base_top", "stand_anchor0", "stand_anchor1", "stand_column", "stand_gearbox",
              "stand_gearbox_top", "drive_guard", "drive_ujoint0", "drive_ujoint1", "stand_arrow_plate", "floor_line")
# wall-layer parts that are above the head line: they go to the front layer (above the actors)
UPPER_WALL = ("face_upper", "pour_joint0", "frame_head", "jb_backplate", "jb_box", "jb_side", "jb_lock", "jb_plate",
              "conduit_up0", "conduit_up1", "conduit_up2", "penetration_plate", "door_light_feed", "operator_feed",
              "feed_strap", "door_light_bracket", "door_light_body", "door_light_lens")
NEW_PARTS = ("bp_backplate", "bp_anchor0", "bp_anchor1", "bp_anchor2", "bp_anchor3", "bp_gearbox_side", "bp_gearbox",
             "bp_gearbox_top", "bp_boss", "bp_wallplate0", "bp_wallplate1", "bp_guard", "bp_guard_edge", "bp_sprocket_cover",
             "bp_guard_flange", "bp_clamp0", "bp_clamp1", "floor_line_wide", "far_col_joint", "far_col_patch",
             "pier_cut", "arris_cut_left", "arris_cut_right")


class BandPlane:
    """The pier's end plane carried below the floor (the cut section): x from the end plane, light
    from the end face's foot, falling off toward the camera."""


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def bypass_parts() -> list:
    P = []
    Part = p2.Part
    fpw = p2.front_plane(2.35)
    P.append(Part("wall", "bp_backplate", [rect(685.0, 384.5, 708.2, 411.5)], p2.HOUSING, fpw,
                  "10 mm steel backplate 0.58 x 0.68 m, four M16 wedge anchors into the wall", "carries the bypass gearbox on the corridor wall"))
    for i, (ax, ay) in enumerate(((687.3, 386.8), (705.9, 386.8), (687.3, 409.2), (705.9, 409.2))):
        P.append(Part("wall", f"bp_anchor{i}", [("ellipse", ax, ay, 0.85, 0.85)], p2.STEEL_WORN, p2.front_plane(2.33), "M16 anchor nut", "holds the plate to the wall"))
    for i, y in enumerate((334.0, 362.0)):
        P.append(Part("wall", f"bp_wallplate{i}", [rect(700.0, y - 2.1, 708.4, y + 2.1)], p2.HOUSING, p2.front_plane(2.36),
                      "bracket wall plate 0.2 x 0.1 m, two anchors", "stand-off bracket for the chain guard"))
    P.append(Part("wall", "bp_gearbox_side", [rect(687.6, 390.2, 689.7, 406.6)], (0.11, 0.115, 0.13), p2.front_plane(2.2),
                  "gearbox side", "the gearbox's side toward the corridor"))
    P.append(Part("wall", "bp_gearbox", [rect(689.6, 390.2, 708.0, 406.6)], p2.GUNSHIP, p2.front_plane(2.0),
                  "worm gearbox 0.46 x 0.41 x 0.4 m (36118)", "many easy turns of the wheel into a few strong ones on the chain"))
    P.append(Part("wall", "bp_gearbox_top", [rect(689.2, 388.9, 708.0, 390.3)], p2.STEEL, p2.top_plane(1.06),
                  "bolted gearbox cover", "the gearbox's top, seen from the corridor's eye height"))
    P.append(Part("wall", "bp_sprocket_cover", [rect(701.4, 385.6, 708.8, 390.4)], p2.GUNSHIP, p2.front_plane(1.95),
                  "sprocket cover", "covers the output sprocket where the chain leaves the gearbox"))
    P.append(Part("wall", "bp_boss", [("ellipse", HUB[0], HUB[1], 3.6, 3.6)], p2.HOUSING, p2.front_plane(1.8),
                  "input bearing housing", "carries the handwheel's shaft"))
    P.append(Part("wall", "bp_guard", [rect(702.6, 306.6, 708.4, 386.0)], p2.GUNSHIP, p2.front_plane(1.95),
                  "enclosed chain guard 0.15 m, straight up the wall", "carries the bypass chain to the operator's manual input"))
    P.append(Part("wall", "bp_guard_edge", [rect(702.6, 306.6, 703.5, 386.0)], p2.STEEL_WORN, p2.front_plane(1.94),
                  "folded edge", "the guard's folded edge, toward the corridor light"))
    P.append(Part("wall", "bp_guard_flange", [rect(701.8, 305.0, 709.2, 307.4)], p2.HOUSING, p2.front_plane(1.9),
                  "guard top flange", "bolts the guard to the operator's underside"))
    for i, y in enumerate((334.0, 362.0)):
        P.append(Part("wall", f"bp_clamp{i}", [rect(701.6, y - 1.1, 709.4, y + 1.1)], p2.HOUSING, p2.front_plane(1.9),
                      "U-clamp", "holds the guard to its stand-off bracket"))
    return P


def wall_parts_v3() -> list:
    P = [p for p in p2.wall_parts() if p.name not in REMOVED_V2]
    P.append(p2.Part("wall", "floor_line_wide", [p2.quad_top(p2.A_N + 0.05, p2.A_F - 0.05, -0.36, -0.24, 0.0)], p2.YELLOW, p2.top_plane(0.0),
                     "120 mm yellow line along the door line", "marks the door's travel; scuffed where feet cross", texture="line_wear"))
    P.append(p2.Part("wall", "far_col_joint", [p2.quad_face(p2.A_F + 0.16, p2.A_BACK, 3.035, 3.06, -0.002)], p2.CONCRETE_DK, p2.face_plane(-0.002),
                     "pour joint at the head line", "construction joint between the wall's lifts"))
    return P


def front_parts_v3() -> list:
    P = []
    for p in p2.front_parts():
        if p.name == "pb_button2":
            p.albedo = np.asarray((0.09, 0.09, 0.095))
            p.job = "stop (grey cap: the view's reds are the live lockdown beacons)"
        P.append(p)
    # the cut section below the end face
    e0 = p2.scr(p2.pt(p2.A_END, 0.0, 0.0))
    e1 = p2.scr(p2.pt(p2.A_END, 0.0, p2.T_WALL))
    a0 = p2.scr(p2.pt(p2.A_END, 0.0, 0.065))
    a1 = p2.scr(p2.pt(p2.A_END, 0.0, p2.T_WALL - 0.065))
    P.append(p2.Part("front", "pier_cut", [[e0, e1, (e1[0], BAND_BOTTOM), (e0[0], BAND_BOTTOM)]], p2.CONCRETE, None,
                     "the cross-wall's cut section, 0.66 m, from the pier's foot to the camera", "the wall continues to the corridor's near side: nothing passes it but the doorway"))
    P.append(p2.Part("front", "arris_cut_left", [[e0, a0, (a0[0], BAND_BOTTOM), (e0[0], BAND_BOTTOM)]], p2.STEEL, None,
                     "65 mm steel arris angle, continued", "armours the wall's corner"))
    P.append(p2.Part("front", "arris_cut_right", [[a1, e1, (e1[0], BAND_BOTTOM), (a1[0], BAND_BOTTOM)]], p2.STEEL, None,
                     "65 mm steel arris angle, continued", "armours the wall's corner"))
    return P


def band_light(canvas: Canvas) -> np.ndarray:
    """Linear light on the cut section: the end face's light at its foot, per column, falling toward
    the camera (away from the door light) to about 40 %."""
    X, Y = canvas.grid()
    xs = np.linspace(p2.scr(p2.pt(p2.A_END, 0, 0))[0], p2.scr(p2.pt(p2.A_END, 0, p2.T_WALL))[0], 33)
    Ls = []
    for x in xs:
        t = np.interp(x, [xs[0], xs[-1]], [0.0, p2.T_WALL])
        P = p2.pt(p2.A_END, 0.02, t)[None, None, :]
        Ls.append(p2.shade(P, (-p2.U)[None, None, :])[0, 0])
    Ls = np.array(Ls)
    Lx = np.stack([np.interp(X, xs, Ls[:, c]) for c in range(3)], -1)
    foot = np.interp(X, [xs[0], xs[-1]], [460.86, 459.23])
    g = 0.42 + 0.58 * np.exp(-np.clip(Y - foot, 0, None) / 40.0)
    return Lx * g[..., None]


def render_parts(parts, canvas):
    """p2.render, with the cut-section parts (plane None) lit by band_light."""
    H, W = canvas.h, canvas.w
    out = {}
    plain = [p for p in parts if p.plane is not None or p.emit is not None]
    lay = p2.render(plain, canvas)
    BL = band_light(canvas)
    for p in parts:
        if p.plane is None and p.emit is None:
            m = p2.mask_of(p.polys, canvas)
            col = p.albedo * BL
            L = lay.setdefault(p.layer, {"lin": np.zeros((H, W, 3)), "a": np.zeros((H, W)), "masks": {}})
            L["lin"] = L["lin"] * (1 - m[..., None]) + col * m[..., None]
            L["a"] = m + L["a"] * (1 - m)
            L["masks"][p.name] = m
    # keep the render order of `parts` in each layer's mask dict
    for name, L in lay.items():
        order = [p.name for p in parts if p.layer == name]
        L["masks"] = {n: L["masks"][n] for n in order if n in L["masks"]}
    return lay


def contact_shadows_v3(canvas: Canvas) -> tuple[np.ndarray, np.ndarray]:
    """(floor shadows behind the actors, shadows down both sides of the cut section in front).
    Floor: along the cross-wall's foot on the approach side (far column and near pier), as v2;
    no end-face foot shadow (the wall carries on) and no floor-stand shadow."""
    X, Y = canvas.grid()
    sh = np.zeros((canvas.h, canvas.w))
    Pp, la, lb = p2.top_plane(0.0).points() if canvas is CVD else _plane_coords(p2.top_plane(0.0), canvas)
    out_m = -lb
    for a0, a1 in ((p2.A_F + 0.16, p2.A_BACK), (p2.A_END, p2.A_N - 0.16)):
        inside = (la >= a0) & (la <= a1) & (out_m >= 0)
        edge = np.clip(np.minimum(la - a0, a1 - la) / 0.15, 0, 1)
        sh = np.maximum(sh, np.where(inside, 0.58 * np.exp(-np.clip(out_m, 0, 50) / 0.16) * edge, 0))
    e0x = p2.scr(p2.pt(p2.A_END, 0.0, 0.0))[0]
    e1x = p2.scr(p2.pt(p2.A_END, 0.0, p2.T_WALL))[0]
    top = np.clip((Y - 457.0) / 5.0, 0, 1)
    left = np.where(X <= e0x, 0.52 * np.exp(-np.clip(e0x - X, 0, 50) / 2.8), 0) * top
    right = np.where(X >= e1x, 0.58 * np.exp(-np.clip(X - e1x, 0, 50) / 2.8), 0) * np.clip((Y - 452.0) / 5.0, 0, 1)
    cut = np.maximum(left, right) * (Y <= BAND_BOTTOM)
    return sh, cut


def _plane_coords(plane, canvas):
    A, B = p2.rays(canvas)
    nb = (B * plane.n).sum(-1)
    tt = ((plane.o - A) * plane.n).sum() / np.where(np.abs(nb) < 1e-9, 1e-9, nb)
    P = A + B * tt[..., None]
    rel = P - plane.o
    return P, (rel * plane.e1).sum(-1), (rel * plane.e2).sum(-1)


# ----------------------------------------------------------------------------- the near slab (far plate)

SLAB_X0 = 826.0  # clamp-world x: under the cut section, so the far plate's parallax never shows the join
SLAB_Y0 = 448.0
SLAB_JOIN_Y = (448.0, 456.0)  # blends into the v2 plant floor behind the safe point


def slab_polys():
    return [rect(SLAB_X0, SLAB_Y0, 990.0, 625.0)]


def slab_joints():
    """Saw-cut control joints in the plant room's slab: two transverse cuts at 3 m and 7.5 m in front
    of the walk line, one longitudinal cut on the 900 grid line, all at the plate's vanishing point."""
    ys = [common.floor_y(-3.0), common.floor_y(-7.5)]
    lines = [rect(SLAB_X0, y - 0.35, 990.0, y + 0.35) for y in ys]
    pts = []
    for yy in np.linspace(SLAB_Y0, 625.0, 60):
        s = (yy - HORIZON) / (common.FLOOR_Y - HORIZON)
        pts.append((VPX + (900.0 - VPX) * s, yy))
    left = [(x - 0.35, y) for x, y in pts]
    right = [(x + 0.35, y) for x, y in pts[::-1]]
    lines.append(left + right)
    return lines, [round(y, 1) for y in ys]


def slab_value(canvas: Canvas) -> np.ndarray:
    """Linear colour of the plant room's dry slab in front of the walk line: lit by the plant room's
    two high-bays (far_patch fixtures, physically), exposed so the slab meets the regraded plant floor
    (about luma 40 behind the safe point) and falls to about luma 18 at the bottom of the view; the
    pool is brightest toward high-bay B."""
    Lm = common.light(canvas, {"kind": "floor"}, [fp.F_MA, fp.F_MB])
    lum = (Lm * np.array([0.2126, 0.7152, 0.0722])).sum(-1)
    X, Y = canvas.grid()
    ref = (Y > SLAB_Y0) & (Y < SLAB_Y0 + 4) & (X > 860) & (X < 920)
    k = 1.0
    if ref.any():
        k = common.from_srgb_u8(np.array([40.0]))[0] / max(lum[ref].mean() * 0.20, 1e-6)
    alb = np.array([0.16, 0.20, 0.22])
    lin = Lm * alb * k
    floor_v = common.from_srgb_u8(np.array([17.0]))[0]
    lin = np.maximum(lin, floor_v * np.array([0.85, 1.0, 1.1]))
    return lin


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    wall = wall_parts_v3() + bypass_parts()
    parts = wall + p2.frame_parts() + p2.curtain_parts() + front_parts_v3()
    layers = render_parts(parts, CVD)
    # the far column under the v2 drive shaft: its concrete, repainted (the shaft is gone)
    v2m = os.path.join(ROOT, "portal2", "masks")
    shaft = np.zeros((CVD.h, CVD.w))
    for n in ("drive_guard", "drive_ujoint0", "drive_ujoint1"):
        m = np.asarray(Image.open(os.path.join(v2m, f"wall--{n}.png")).convert("L")).astype(float) / 255.0
        shaft[:m.shape[0], CV2_OFFSET[0]:CV2_OFFSET[0] + m.shape[1]] = np.maximum(shaft[:m.shape[0], CV2_OFFSET[0]:CV2_OFFSET[0] + m.shape[1]], m)
    shaft = np.clip(ndilate(shaft, 3), 0, 1)
    col = layers["wall"]["masks"]["face_far_column"]
    nearer = np.zeros_like(col)
    names = list(layers["wall"]["masks"])
    for n in names[names.index("face_far_column") + 1:]:
        nearer = np.maximum(nearer, layers["wall"]["masks"][n])
    patch = shaft * col * (1 - nearer)
    layers["wall"]["masks"]["far_col_patch"] = patch
    # the doorway hole in the wall layer (as v2)
    hole_face = p2.mask_of([p2.quad_face(p2.A_N, p2.A_F, 0.0, p2.H_OPEN)], CVD)
    wm = layers["wall"]["masks"]
    keep = np.clip(wm["reveal_far"] + wm["reveal_angle_far"] + wm["threshold"] + wm["floor_line_wide"], 0, 1)
    hole = np.clip(hole_face - keep, 0, 1)
    layers["wall"]["a"] = layers["wall"]["a"] * (1 - hole)
    wm["HOLE"] = hole
    sh, cut = contact_shadows_v3(CVD)
    sh = sh * (1 - hole)
    wa = layers["wall"]["a"]
    out_a = wa + sh * (1 - wa)
    w_sh = np.where(out_a > 0, sh * (1 - wa) / np.maximum(out_a, 1e-6), 0)
    layers["wall"]["lin"] = layers["wall"]["lin"] * (1 - w_sh[..., None]) + np.array([0.0008, 0.0015, 0.0025]) * w_sh[..., None]
    layers["wall"]["a"] = out_a
    wm["contact_shadow"] = sh
    layers["front"]["masks"]["cut_shadow"] = cut
    # the lamp's glass hole (as v2)
    tl = p2.T_WALL / 2
    lcx, lcy = p2.scr(p2.pt(p2.A_END - 0.12, p2.LAMP_H, tl))
    glass = p2.mask_of([("ellipse", lcx, lcy, 2.05, 2.55)], CVD)
    guard = np.clip(sum(layers["front"]["masks"][f"lamp_guard{i}"] for i in range(3)), 0, 1)
    glass_hole = np.clip(glass - guard, 0, 1)
    layers["front"]["a"] = layers["front"]["a"] * (1 - glass_hole)
    layers["front"]["masks"]["GLASS_HOLE"] = glass_hole
    # typeset marks (as v2), in each surface's own plane
    sec, info_s = p2.text_layer("SECTOR 4B", 0.30, p2.face_plane(0.0), (p2.A_N + p2.A_BACK) / 2 - 0.15, 5.95)
    sec = sec * layers["wall"]["masks"]["face_upper"]
    door, info_d = p2.text_layer("DOOR 4B-07", 0.30, p2.face_plane(p2.HOOD_T - 0.002), (p2.A_N + p2.A_F) / 2, p2.HOOD_H0 + 0.075)
    door = door * layers["frame"]["masks"]["hood_front"]
    save_mask(sec, os.path.join(OUT, "masks", "TEXT-wall.png"))
    save_mask(door, os.path.join(OUT, "masks", "TEXT-frame.png"))
    # the split of the wall layer: above the head line (front) and below (mid)
    _, la, lb = p2.face_plane(0.0).points()
    upper = np.zeros((CVD.h, CVD.w))
    for n in UPPER_WALL:
        upper = np.maximum(upper, wm[n])
    upper = np.maximum(upper, wm["back_arris"] * (lb >= SPLIT_H))
    save_mask(upper, os.path.join(OUT, "masks", "SPLIT-wall-upper.png"))
    for name, lay in layers.items():
        rgba = np.dstack([to_srgb_u8(lay["lin"]), (np.clip(lay["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, f"design-{name}.png"))
        for mname, m in lay["masks"].items():
            save_mask(m, os.path.join(OUT, "masks", f"{name}--{mname}.png"))
        save_mask(lay["a"], os.path.join(OUT, "masks", f"{name}--ALPHA.png"))
    # the near slab, on CVD (for cleanup) and on the far plate's own canvas (2 px)
    joints, joint_ys = slab_joints()
    for cv, tag in ((CVD, "cvd"),):
        sm = p2.mask_of(slab_polys(), cv)
        jm = p2.mask_of(joints, cv) * sm
        lin = slab_value(cv)
        lin = lin * (1 - 0.55 * jm[..., None])
        Image.fromarray(np.dstack([to_srgb_u8(lin), (sm * 255 + 0.5).astype(np.uint8)]), "RGBA").save(os.path.join(OUT, f"design-slab-{tag}.png"))
        save_mask(sm, os.path.join(OUT, "masks", f"slab--{tag}.png"))
        save_mask(jm, os.path.join(OUT, "masks", f"slab-joints--{tag}.png"))
    spec = {
        "canvases": {"CVD": vars(CVD), "CVP": vars(CVP), "v2_canvas_in_CVD_px": CV2_OFFSET},
        "bypass": {"hub_world": HUB, "hub_height_m": round((440.0 - HUB[1]) / PX_PER_M, 3), "wheel_radius_world": p2.WHEEL_R,
                   "drive": "enclosed chain guard straight up the wall (x 702.6..708.4) from the gearbox to the operator's underside at y 307 (3.3 m)",
                   "lit_by": [l.name for l in BYPASS_LAMPS]},
        "pier_cut": {"x": [round(p2.scr(p2.pt(p2.A_END, 0, 0))[0], 2), round(p2.scr(p2.pt(p2.A_END, 0, p2.T_WALL))[0], 2)], "from_y": [460.86, 459.23], "to_y": BAND_BOTTOM,
                     "light": "the end face's light at its foot per column, falling to 42 % toward the camera (40 px e-fold)"},
        "slab": {"x0": SLAB_X0, "y0": SLAB_Y0, "joints_transverse_y": joint_ys, "joint_longitudinal": "grid line x 900 at the walk line, to the vanishing point",
                 "light": "plant-room high-bays A and B (far_patch fixtures), exposed to luma 40 behind the safe point, floor luma 17"},
        "split": {"head_line_h_m": SPLIT_H, "upper_wall_parts_to_front": list(UPPER_WALL)},
        "removed_from_v2": list(REMOVED_V2),
        "new_parts": list(NEW_PARTS),
        "marks": [info_s, info_d],
        "parts": {lay: [{"name": p.name, "dims": p.dims, "job": p.job} for p in parts if p.layer == lay] for lay in ("wall", "frame", "curtain", "front")},
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print(json.dumps({k: spec[k] for k in ("bypass", "pier_cut", "slab")}, indent=1))


def ndilate(m, it):
    from scipy import ndimage
    return ndimage.binary_dilation(m > 0.05, iterations=it).astype(float) * 1.0


if __name__ == "__main__":
    main()
