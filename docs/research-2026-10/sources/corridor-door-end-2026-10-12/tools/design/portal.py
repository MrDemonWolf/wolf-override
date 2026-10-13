"""Construction design of the corridor seal: the bulkhead portal with its rolling steel service
door, the MANUAL BYPASS gearbox and handwheel, and the door's controls. Writes design/portal/.

Layers (all 4 source px per world px, world box x 646..851, y 140..447.5 = 820 x 1230 px):
  frame   behind the actors and the curtain: wall face, left return, reveal, threshold, operator,
          controls, lamp socket, wall pack, bypass backplate and gearbox, chain guard, floor line,
          contact shadow; alpha 0 in the doorway (the hole).
  curtain the rolling curtain, slats + bottom bar + astragal (moves; drawn over the frame).
  front   guides, hood and end brackets (drawn over the curtain and the actors).
  wheel   the bypass handwheel (rotates), its own small canvas centred on (700, 398).
  lens    the door status lamp's glass (tinted live by the game), centred on the socket.
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import common
from common import (Canvas, Fixture, Part, draw_mask, rect, light, depth_scale, floor_y, to_srgb_u8,
                    save_mask, write_json, PX_PER_M, VPX)

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "portal")
CANVAS = Canvas("portal", x0=646.0, y0=140.0, ppw=4.0, w=820, h=1230)
WHEEL_CANVAS = Canvas("wheel", x0=690.0, y0=388.0, ppw=4.0, w=80, h=80)
LENS_CANVAS = Canvas("lens", x0=733.0, y0=324.0, ppw=4.0, w=32, h=40)

from far_patch import F_CORR  # the corridor luminaire lights the bulkhead's left return
common.AMBIENT = np.array([0.020, 0.034, 0.044])
F_DOOR = Fixture("door wall pack over the hood (0.4 m, 3.7 m up, 0.3 m off the face)", (780.0, 292.5), -0.3, (0.80, 0.94, 1.0), 2.2, 1.0, 1.4)
LIGHTS = (F_CORR, F_DOOR)

# key geometry (world px at the clamp)
PIER_L = 680.0
PIER_R = 838.0
OPEN_L = 752.0  # curtain face / collision face
OPEN_R = 808.0
HEAD = 318.0  # 3.05 m opening
WALL_D = 0.5  # bulkhead thickness, m
BACK_R = VPX + (OPEN_R - VPX) * depth_scale(WALL_D)  # 803.7
BACK_FLOOR = floor_y(WALL_D)  # 436.3
WHEEL_C = (700.0, 398.0)
WHEEL_R = 9.0  # 0.45 m wheel
LAMP_C = (737.0, 329.5)

# Military palette (REAL-LOOK section 8; FED-STD-595 chips as approximate linear albedo, kept inside
# the corridor's value plan): cast concrete structure, 36118 Gunship Gray doors/hoods/guides, 36081
# housings, bare steel at worn edges, 33538 yellow only for the door's caught-between marking, 31136
# red only for the emergency stop.
CONCRETE = (0.25, 0.255, 0.27)
CONCRETE_JOINT = (0.12, 0.125, 0.135)
STEEL = (0.34, 0.35, 0.37)
GUNSHIP = (0.20, 0.215, 0.255)
HOUSING = (0.16, 0.165, 0.185)
DARK = (0.06, 0.065, 0.07)
YELLOW = (0.70, 0.42, 0.02)
BLACK = (0.03, 0.03, 0.035)
RED = (0.35, 0.035, 0.04)


def frame_parts() -> list[Part]:
    P: list[Part] = []
    s_c = depth_scale(2.4)
    ret_back = VPX + (PIER_L - VPX) * s_c
    P.append(Part("return_left", [[(ret_back, 141.1), (PIER_L, 140.0), (PIER_L, 440.0), (ret_back, floor_y(2.4))]],
                  CONCRETE, {"kind": "side", "xw": PIER_L, "nx": -1.0}, LIGHTS,
                  dims="bulkhead side face, 2.4 m deep to the corridor wall", note="cast-concrete bulkhead's corridor-side return"))
    wall = [rect(PIER_L, 140.0, PIER_R, 440.0)]
    P.append(Part("wall_face", wall, CONCRETE, {"kind": "front", "d": 0.0}, LIGHTS,
                  dims="cast reinforced-concrete bulkhead, 0.5 m thick, 3.95 m wide here, floor to roof", note="the hardened wall the door is set into"))
    for i, yy in enumerate((236.0, 296.0)):
        P.append(Part(f"wall_joint{i}", [rect(PIER_L, yy - 0.4, PIER_R, yy + 0.4)], CONCRETE_JOINT, {"kind": "front", "d": 0.0}, LIGHTS,
                      dims="pour line between concrete lifts", note="construction joint"))
    P.append(Part("corner_guard_left", [rect(PIER_L, 360.0, PIER_L + 2.0, 440.0)], STEEL, {"kind": "front", "d": -0.01}, LIGHTS,
                  dims="50 mm steel corner angle to 2 m", note="protects the arris from carts"))
    P.append(Part("corner_guard_right", [rect(PIER_R - 2.0, 360.0, PIER_R, 440.0)], STEEL, {"kind": "front", "d": -0.01}, LIGHTS,
                  dims="50 mm steel corner angle to 2 m", note="protects the arris"))
    P.append(Part("reveal_right", [[(BACK_R, HEAD), (OPEN_R, HEAD), (OPEN_R, 440.0), (BACK_R, BACK_FLOOR)]], CONCRETE,
                  {"kind": "side", "xw": OPEN_R, "nx": -1.0}, LIGHTS, dims="jamb reveal, 0.5 m wall thickness", note="inside face of the opening"))
    P.append(Part("reveal_angle", [[(OPEN_R - 1.4, HEAD), (OPEN_R, HEAD), (OPEN_R, 440.0), (OPEN_R - 1.4, 440.0 - 0.1)]], STEEL,
                  {"kind": "side", "xw": OPEN_R, "nx": -1.0}, LIGHTS, dims="steel edge angle 60 mm along the reveal", note="steel-lined reveal edge (hardened opening)"))
    P.append(Part("threshold", [[(OPEN_L, BACK_FLOOR), (BACK_R, BACK_FLOOR), (OPEN_R, 440.0), (OPEN_L, 440.0)]], STEEL,
                  {"kind": "floor"}, LIGHTS, dims="steel threshold plate 0.5 m", note="metal threshold of a shielded door; worn bright where the curtain lands and feet cross"))
    # door operator on the drive-end bracket
    P.append(Part("operator_bracket", [rect(739.5, 299.0, 744.0, 323.0)], GUNSHIP, {"kind": "front", "d": -0.05}, LIGHTS,
                  dims="end bracket plate", note="carries the barrel and the operator"))
    P.append(Part("operator_body", [rect(727.0, 300.0, 739.5, 311.0)], HOUSING, {"kind": "front", "d": -0.15}, LIGHTS,
                  dims="door operator 0.34 x 0.28 m at 3.2 m (>= 2.44 m)", note="electric operator on the drive end"))
    P.append(Part("operator_motor", [rect(729.0, 303.0, 735.0, 309.0)], DARK, {"kind": "cyl", "axis": "h", "cy": 306.0, "r": 3.0, "d": -0.25, "cx": 732.0}, LIGHTS,
                  dims="motor can", note="motor"))
    P.append(Part("operator_sprocket", [("ellipse", 733.5, 312.5, 2.0, 2.0)], DARK, {"kind": "front", "d": -0.2}, LIGHTS,
                  dims="manual-drive sprocket", note="the bypass chain drives this"))
    # chain guard from the bypass gearbox output up to the operator's manual-drive sprocket
    gx, gy = 700.0, 385.0
    ox, oy = 733.5, 313.0
    ang = math.atan2(oy - gy, ox - gx)
    nx_, ny_ = -math.sin(ang), math.cos(ang)
    w = 1.6
    P.append(Part("chain_guard", [[(gx + nx_ * w, gy + ny_ * w), (ox + nx_ * w, oy + ny_ * w), (ox - nx_ * w, oy - ny_ * w), (gx - nx_ * w, gy - ny_ * w)]],
                  GUNSHIP, {"kind": "front", "d": -0.1}, LIGHTS, dims="enclosed chain guard 80 mm", note="manual bypass drive to the door"))
    for i, t in enumerate((0.3, 0.72)):
        bx = gx + (ox - gx) * t
        by = gy + (oy - gy) * t
        P.append(Part(f"chain_guard_clip{i}", [rect(bx - 2.2, by - 0.8, bx + 2.2, by + 0.8)], HOUSING, {"kind": "front", "d": -0.05}, LIGHTS,
                      dims="wall clip", note="holds the guard to the wall"))
    # bypass backplate and gearbox (the wheel is its own sprite)
    P.append(Part("bypass_backplate", [rect(691.0, 387.0, 709.0, 409.0)], HOUSING, {"kind": "front", "d": -0.02}, LIGHTS,
                  dims="backplate 0.45 x 0.55 m, four anchors", note="fixes the gearbox to the bulkhead"))
    for i, (ax, ay) in enumerate(((693.0, 389.0), (707.0, 389.0), (693.0, 407.0), (707.0, 407.0))):
        P.append(Part(f"bypass_anchor{i}", [("ellipse", ax, ay, 0.7, 0.7)], STEEL, {"kind": "front", "d": -0.03}, LIGHTS,
                      dims="M12 anchor", note="wall anchor"))
    P.append(Part("bypass_gearbox", [rect(696.0, 384.0, 704.0, 405.0)], GUNSHIP, {"kind": "front", "d": -0.15}, LIGHTS,
                  dims="worm gearbox, output sprocket on top", note="many easy turns to a few strong ones"))
    P.append(Part("bypass_arrow_plate", [rect(689.5, 410.5, 710.5, 414.0)], STEEL, {"kind": "front", "d": -0.02}, LIGHTS,
                  dims="direction plate (no lettering)", note="an embossed open/close arrow, no text"))
    # push-button station: a lockable steel enclosure on a backplate, fed by conduit from the operator
    P.append(Part("ctrl_conduit", [rect(736.4, 311.0, 737.4, 365.0)], STEEL, {"kind": "front", "d": -0.04}, LIGHTS,
                  dims="20 mm rigid conduit from the operator", note="feeds the lamp and the buttons"))
    P.append(Part("pushbutton_backplate", [rect(731.5, 365.0, 741.5, 378.5)], HOUSING, {"kind": "front", "d": -0.03}, LIGHTS,
                  dims="backplate 0.25 x 0.34 m", note="carries the enclosure"))
    P.append(Part("pushbutton_box", [rect(732.5, 366.0, 740.5, 377.5)], GUNSHIP, {"kind": "front", "d": -0.08}, LIGHTS,
                  dims="OPEN/CLOSE/STOP station at 1.6 m (>= 1.52 m) in a lockable cover", note="push-button station"))
    P.append(Part("pushbutton_hinge", [rect(732.5, 367.0, 733.2, 376.5)], DARK, {"kind": "front", "d": -0.09}, LIGHTS,
                  dims="cover hinge (left)", note="the cover swings open to the left"))
    P.append(Part("pushbutton_lock", [rect(739.4, 371.0, 740.2, 372.4)], STEEL, {"kind": "front", "d": -0.1}, LIGHTS,
                  dims="cam lock (right)", note="keeps the cover locked"))
    for i, (by, col) in enumerate(((369.0, DARK), (372.0, DARK), (375.0, RED))):
        P.append(Part(f"pushbutton{i}", [("ellipse", 736.5, by, 1.1, 1.1)], col, {"kind": "front", "d": -0.1}, LIGHTS,
                      dims="22 mm button", note=("open", "close", "emergency stop (red, the view's one red)")[i]))
    # guarded status lamp (unlit socket; the game tints a live lens over it)
    P.append(Part("lamp_base", [rect(733.8, 333.0, 740.2, 336.0)], HOUSING, {"kind": "front", "d": -0.06}, LIGHTS,
                  dims="cast base", note="lamp body on the conduit"))
    P.append(Part("lamp_globe", [("ellipse", LAMP_C[0], LAMP_C[1], 2.6, 3.6)], DARK, {"kind": "front", "d": -0.1}, LIGHTS,
                  dims="globe 0.18 m tall in a guard (unlit socket)", note="the game tints a live lens over this"))
    for i, xx in enumerate((735.0, 737.0, 739.0)):
        P.append(Part(f"lamp_guard{i}", [rect(xx - 0.3, 326.0, xx + 0.3, 333.0)], STEEL, {"kind": "front", "d": -0.12}, LIGHTS,
                      dims="wire guard", note="guard bar"))
    # the wall pack that lights the door, fed from the operator
    P.append(Part("wallpack_conduit", [rect(741.0, 292.0, 772.0, 293.0)], STEEL, {"kind": "front", "d": -0.04}, LIGHTS,
                  dims="20 mm rigid conduit", note="feeds the wall pack"))
    P.append(Part("wallpack_body", [rect(772.0, 287.0, 788.0, 292.0)], HOUSING, {"kind": "front", "d": -0.25}, LIGHTS,
                  dims="vapour-tight LED wall pack 0.4 m", note="lights the door face and the threshold"))
    P.append(Part("wallpack_lens", [rect(773.0, 292.0, 787.0, 293.6)], (1, 1, 1), {"kind": "emit", "d": -0.3}, (),
                  emit=(0.86, 0.96, 1.0), dims="lens", note="light source"))
    # fixed surveillance camera on a wall arm on the bulkhead's return, aimed back down the approach
    P.append(Part("camera_mount", [[(676.0, 279.0), (679.4, 279.0), (679.4, 291.0), (676.0, 291.2)]], HOUSING,
                  {"kind": "side", "xw": PIER_L, "nx": -1.0}, LIGHTS, dims="wall plate 0.1 x 0.3 m, two anchors", note="fixes the camera arm to the return"))
    P.append(Part("camera_arm", [rect(670.0, 283.6, 677.0, 285.4)], HOUSING, {"kind": "front", "d": 0.2}, LIGHTS,
                  dims="tubular wall arm 0.18 m", note="holds the housing off the wall"))
    P.append(Part("camera_housing", [[(658.0, 285.5), (671.5, 284.0), (672.5, 289.6), (659.0, 291.6)]], GUNSHIP,
                  {"kind": "front", "d": 0.2}, LIGHTS, dims="fixed camera in a vandal-resistant housing, 0.36 x 0.14 m", note="watches the approach; static art, no live glow"))
    P.append(Part("camera_sunshield", [[(656.5, 283.6), (672.5, 281.8), (672.8, 283.6), (657.0, 285.4)]], HOUSING,
                  {"kind": "front", "d": 0.2}, LIGHTS, dims="sunshield", note="top cover of the housing"))
    P.append(Part("camera_window", [[(657.6, 286.2), (659.0, 286.0), (659.8, 291.0), (658.6, 291.3)]], DARK,
                  {"kind": "front", "d": 0.2}, LIGHTS, dims="front window", note="the lens window, dark (no glow)"))
    # junction box, conduit group and the welded penetration plate (one plate for the whole group)
    P.append(Part("camera_conduit", [rect(679.4, 285.0, 683.0, 286.0)], STEEL, {"kind": "front", "d": -0.03}, LIGHTS,
                  dims="20 mm rigid conduit", note="camera cable to the junction box"))
    P.append(Part("jb_backplate", [rect(682.5, 283.0, 695.5, 299.5)], HOUSING, {"kind": "front", "d": -0.02}, LIGHTS,
                  dims="backplate", note="carries the box"))
    P.append(Part("jb_box", [rect(683.5, 284.0, 694.5, 298.5)], GUNSHIP, {"kind": "front", "d": -0.08}, LIGHTS,
                  dims="lockable junction box 0.28 x 0.36 m (blank equipment plate)", note="terminates the camera and operator feeds"))
    P.append(Part("jb_hinge", [rect(683.5, 285.0, 684.2, 297.5)], DARK, {"kind": "front", "d": -0.09}, LIGHTS,
                  dims="cover hinge (left)", note="hinged cover"))
    P.append(Part("jb_lock", [rect(693.3, 290.5, 694.1, 292.0)], STEEL, {"kind": "front", "d": -0.1}, LIGHTS,
                  dims="padlock hasp (right)", note="lockable, tamper-protected"))
    P.append(Part("jb_plate", [rect(686.0, 286.0, 692.0, 288.0)], STEEL, {"kind": "front", "d": -0.09}, LIGHTS,
                  dims="blank equipment plate", note="too small to letter: a blank plate, never fake text"))
    P.append(Part("operator_feed", [rect(694.5, 300.3, 727.0, 301.3), rect(694.5, 296.0, 696.0, 301.3)], STEEL, {"kind": "front", "d": -0.04}, LIGHTS,
                  dims="20 mm rigid conduit", note="operator power from the junction box"))
    P.append(Part("feed_strap", [rect(709.5, 299.6, 711.0, 302.0)], DARK, {"kind": "front", "d": -0.05}, LIGHTS,
                  dims="one-hole strap within 0.9 m of the box", note="holds the conduit to the wall"))
    P.append(Part("group_conduits", [rect(686.0, 298.5, 687.0, 305.0), rect(689.0, 298.5, 690.0, 305.0), rect(692.0, 298.5, 693.0, 305.0)], STEEL,
                  {"kind": "front", "d": -0.04}, LIGHTS, dims="three 20 mm rigid conduits", note="the conduit group into the wall"))
    P.append(Part("penetration_plate", [rect(683.0, 305.0, 696.0, 311.0)], STEEL, {"kind": "front", "d": -0.01}, LIGHTS,
                  dims="6 mm welded penetration plate, 150 mm past the conduits", note="where the group passes the shielded wall"))
    # floor marking and the contact shadow are drawn separately (see shadows())
    P.append(Part("floor_line", [rect(746.0, 440.0, 814.0, 442.0)], YELLOW, {"kind": "floor"}, LIGHTS,
                  dims="50 mm yellow line at the edge of the door's travel", note="marks the door line; scuffed where feet cross"))
    return P


def front_parts() -> list[Part]:
    P: list[Part] = []
    P.append(Part("guide_left", [rect(747.5, 316.0, OPEN_L, 440.0)], GUNSHIP, {"kind": "front", "d": -0.05}, LIGHTS,
                  dims="guide, three 50 mm angles, 4.5 px face", note="the curtain runs in it"))
    P.append(Part("guide_right", [rect(OPEN_R, 316.0, 812.5, 440.0)], GUNSHIP, {"kind": "front", "d": -0.05}, LIGHTS,
                  dims="guide", note="the curtain runs in it"))
    P.append(Part("hood", [rect(744.0, 304.0, 816.0, 319.0)], GUNSHIP, {"kind": "front", "d": -0.43}, LIGHTS,
                  dims="steel hood 0.38 m tall, 0.43 m deep", note="covers the 0.3 m coil; carries the stencilled door number"))
    P.append(Part("hood_lip", [rect(744.0, 318.0, 816.0, 319.5)], DARK, {"kind": "front", "d": -0.43}, LIGHTS,
                  dims="hood lower lip", note="shadow line under the hood"))
    P.append(Part("end_bracket_right", [rect(816.0, 301.0, 819.5, 322.0)], HOUSING, {"kind": "front", "d": -0.05}, LIGHTS,
                  dims="idle-end bracket plate", note="carries the barrel"))
    return P


BAR_TOP = 435.0  # the bottom bar: two back-to-back steel angles, 115 mm, hazard-striped front face


def curtain_parts() -> list[Part]:
    P: list[Part] = []
    x0, x1 = 749.5, 810.5
    top = 314.0
    pitch = 2.65
    P.append(Part("curtain_face", [rect(x0, top, x1, BAR_TOP)], GUNSHIP, {"kind": "front", "d": 0.02}, LIGHTS,
                  dims="interlocking steel slats, 2.65 px (66.7 mm) pitch", note="the door leaf", texture="slats", params={"pitch": pitch, "top": top, "bottom": BAR_TOP}))
    P.append(Part("bottom_bar", [rect(x0, BAR_TOP, x1, 439.6)], BLACK, {"kind": "front", "d": -0.02}, LIGHTS,
                  dims="bottom bar, two angles back to back, 115 mm", note="stiffens the curtain's lower edge; black between the stripes"))
    stripes = []
    band = 2.5
    hgt = 439.6 - BAR_TOP
    for k in range(-3, 30):
        xs = x0 + k * band * 2
        stripes.append([(xs, 439.6), (xs + band, 439.6), (xs + band + hgt, BAR_TOP), (xs + hgt, BAR_TOP)])
    P.append(Part("bar_stripes", stripes, YELLOW, {"kind": "front", "d": -0.02}, LIGHTS,
                  dims="45 degree yellow/black bands 2.5 px (0.1 m)", note="caught-between hazard on the closing edge (OSHA yellow)",
                  params={"clip": [x0, BAR_TOP, x1, 439.6]}))
    P.append(Part("astragal", [rect(x0, 439.6, x1, 440.6)], BLACK, {"kind": "front", "d": -0.02}, LIGHTS,
                  dims="rubber bulb astragal", note="seals to the threshold"))
    return P


def wheel_parts() -> list[Part]:
    cx, cy = WHEEL_C
    r = WHEEL_R
    P: list[Part] = []
    P.append(Part("wheel_rim", [("ring", cx, cy, r, r - 1.7)], STEEL, {"kind": "front", "d": -0.3}, LIGHTS,
                  dims="0.45 m cast steel handwheel rim", note="bare steel, polished where hands grip it"))
    spokes = []
    for k in range(5):
        a = -math.pi / 2 + k * 2 * math.pi / 5
        ca, sa = math.cos(a), math.sin(a)
        px, py = -sa * 0.7, ca * 0.7
        p0 = (cx + ca * 2.0, cy + sa * 2.0)
        p1 = (cx + ca * (r - 1.2), cy + sa * (r - 1.2))
        spokes.append([(p0[0] + px, p0[1] + py), (p1[0] + px, p1[1] + py), (p1[0] - px, p1[1] - py), (p0[0] - px, p0[1] - py)])
    P.append(Part("wheel_spokes", spokes, GUNSHIP, {"kind": "front", "d": -0.3}, LIGHTS, dims="five spokes", note="painted spokes"))
    P.append(Part("wheel_hub", [("ellipse", cx, cy, 2.4, 2.4)], HOUSING, {"kind": "front", "d": -0.32}, LIGHTS, dims="hub on the input shaft", note="hub"))
    a = -math.pi / 2 + math.pi / 5
    kx, ky = cx + math.cos(a) * (r - 0.8), cy + math.sin(a) * (r - 0.8)
    P.append(Part("wheel_knob", [("ellipse", kx, ky, 1.3, 1.3)], DARK, {"kind": "front", "d": -0.36}, LIGHTS, dims="spinner knob", note="for many fast turns"))
    return P


def render_layer(canvas: Canvas, plist: list[Part], base: np.ndarray | None = None):
    H, W = canvas.h, canvas.w
    lin = np.zeros((H, W, 3)) if base is None else base.copy()
    alpha = np.zeros((H, W))
    masks = {}
    X, Y = canvas.grid()
    for p in plist:
        m = draw_mask(canvas, p.polys)
        if "clip" in p.params:
            c = p.params["clip"]
            m = m * ((X >= c[0]) & (X <= c[2]) & (Y >= c[1]) & (Y <= c[3]))
        masks[p.name] = m
        if p.surface["kind"] == "emit":
            col = np.broadcast_to(np.array(p.emit), (H, W, 3))
        else:
            col = np.array(p.albedo) * light(canvas, p.surface, list(p.lit_by))
        if p.texture == "slats":
            pitch = p.params["pitch"]
            t = ((Y - p.params["top"]) / pitch) % 1.0
            # convex slat: lighter upper half (top-lit), dark interlock groove at the joint
            prof = 1.15 - 0.45 * t
            prof = np.where(t > 0.86, 0.35, prof)
            col = col * prof[..., None]
        lin = lin * (1 - m[..., None]) + col * m[..., None]
        alpha = np.maximum(alpha, m)
    return lin, alpha, masks


def shadows(canvas: Canvas) -> tuple[np.ndarray, np.ndarray]:
    """The bulkhead's contact shadow on the floor: darkest at the contact line, gone 4 px out."""
    X, Y = canvas.grid()
    a = np.zeros((canvas.h, canvas.w))
    on_floor = (Y >= 440.0) & (Y <= 445.0)
    for x0, x1 in ((PIER_L - 2.0, 747.5), (812.5, PIER_R + 2.0)):
        inside = (X >= x0) & (X <= x1)
        edge = np.clip(np.minimum(X - x0, x1 - X) / 2.0, 0, 1)
        a = np.maximum(a, np.where(on_floor & inside, 0.62 * np.exp(-(Y - 440.0) / 1.4) * edge, 0))
    return np.zeros((canvas.h, canvas.w, 3)), a


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    fr, fa, fm = render_layer(CANVAS, frame_parts())
    # cut the doorway
    hole = draw_mask(CANVAS, [rect(OPEN_L, HEAD, BACK_R, BACK_FLOOR)])
    fa = fa * (1 - hole)
    fm["hole"] = hole
    sc, sa = shadows(CANVAS)
    fr = fr * fa[..., None] + sc * (1 - fa[..., None])
    fa = np.maximum(fa, sa)
    fm["contact_shadow"] = sa
    cr, ca, cm = render_layer(CANVAS, curtain_parts())
    ft, fta, ftm = render_layer(CANVAS, front_parts())
    wr, wa, wm = render_layer(WHEEL_CANVAS, wheel_parts())
    for name, (lin, a) in {"frame": (fr, fa), "curtain": (cr, ca), "front": (ft, fta)}.items():
        rgba = np.dstack([to_srgb_u8(lin), (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)])
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, f"design-{name}.png"))
    rgba = np.dstack([to_srgb_u8(wr), (np.clip(wa, 0, 1) * 255 + 0.5).astype(np.uint8)])
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "design-wheel.png"))
    for d, prefix in ((fm, "frame"), (cm, "curtain"), (ftm, "front"), (wm, "wheel")):
        for name, m in d.items():
            save_mask(m, os.path.join(OUT, "masks", f"{prefix}--{name}.png"))
    save_mask(fa, os.path.join(OUT, "masks", "frame--ALPHA.png"))
    save_mask(ca, os.path.join(OUT, "masks", "curtain--ALPHA.png"))
    save_mask(fta, os.path.join(OUT, "masks", "front--ALPHA.png"))
    save_mask(wa, os.path.join(OUT, "masks", "wheel--ALPHA.png"))
    # composites: closed and open, wheel in place, over a flat dark field
    def comp(states):
        out = Image.new("RGBA", (CANVAS.w, CANVAS.h), (14, 20, 24, 255))
        for name in states:
            out.alpha_composite(Image.open(os.path.join(OUT, f"design-{name}.png")))
        wheel = Image.open(os.path.join(OUT, "design-wheel.png"))
        out.alpha_composite(wheel, (int((WHEEL_CANVAS.x0 - CANVAS.x0) * 4), int((WHEEL_CANVAS.y0 - CANVAS.y0) * 4)))
        return out
    comp(["frame", "curtain", "front"]).save(os.path.join(OUT, "design-closed.png"))
    comp(["frame", "front"]).save(os.path.join(OUT, "design-open.png"))
    spec = {
        "canvas": {"world_box": [CANVAS.x0, CANVAS.y0, CANVAS.x0 + CANVAS.w / 4, CANVAS.y0 + CANVAS.h / 4], "px_per_world": 4},
        "wheel_canvas": {"world_box": [WHEEL_CANVAS.x0, WHEEL_CANVAS.y0, WHEEL_CANVAS.x0 + 20, WHEEL_CANVAS.y0 + 20], "centre": WHEEL_C, "radius": WHEEL_R},
        "geometry": {"pier_left": PIER_L, "pier_right": PIER_R, "opening": [OPEN_L, HEAD, OPEN_R, 440.0], "hole": [OPEN_L, HEAD, BACK_R, BACK_FLOOR],
                     "wall_thickness_m": WALL_D, "lamp_centre": LAMP_C},
        "fixtures": [{"name": f.name, "screen": f.screen, "depth_m": f.d} for f in LIGHTS],
        "layers": {
            "frame": [{"name": p.name, "dims": p.dims, "job": p.note} for p in frame_parts()],
            "curtain": [{"name": p.name, "dims": p.dims, "job": p.note} for p in curtain_parts()],
            "front": [{"name": p.name, "dims": p.dims, "job": p.note} for p in front_parts()],
            "wheel": [{"name": p.name, "dims": p.dims, "job": p.note} for p in wheel_parts()],
        },
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print("portal design written")


if __name__ == "__main__":
    main()
