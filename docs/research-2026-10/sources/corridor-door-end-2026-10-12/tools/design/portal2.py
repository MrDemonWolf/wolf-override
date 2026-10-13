"""Fix round 1 (v2) construction design of the corridor seal: a hardened portal ACROSS the walkway
(Nathanial's approved round-4 composition: a heavy portal across the corridor, the shutter's face
seen at a slight angle), built as a 3D model and projected through the far plate's own camera.

Why a model: the reviewer found that a door in a back-wall pier does not block the way. Here the
cast cross-wall stands across the corridor. Its approach face is turned 17 degrees off square, so
its horizontal lines meet the plate's horizon (y 158.5) at x 21 instead of the floor's vanishing
point (x 483.9): a second vanishing point on the same horizon, exactly as a photograph of a turned
wall shows it. The rolling door is set in that face. Its bottom edge crosses the walk line (y 440)
at x 752, the existing collision face, so no gameplay number changes.

Coordinates: metres, (X along the corridor = world x / 40 at walkway depth, H up, D behind the
walkway; D < 0 is nearer the camera). common.project() maps them to the clamp-world screen.

Layers (one 4 px per world px canvas, world x 680..845, y 150..480, 660 x 1320 px):
  wall     the cross-wall behind the walk line (far column face, upper face, far reveal, steel
           threshold, floor line), its fixtures and hardware, the bypass floor stand and its drive
           guard, and floor contact shadows. Doorway alpha 0. Goes into the mid plate (z -3).
  curtain  the rolling curtain, closed (moves; SealLeaf draws it as a mesh, z 0).
  frame    the door's own frame behind the walk line: far guide, hood, operator (z 0, over the
           curtain). The door asset is only the door: guides, hood, curtain, bar, lamps.
  front    everything in front of the walk line: the near pier (approach face and end face with
           steel arris angles), the near guide, the camera on its arm, the lamp socket (its glass is a
           hole: the live lens draws under the guard bars), the push-button station (z 3).
  wheel    the bypass handwheel (rotates), its own canvas centred on its hub.
  lens     the status lamp's glass, a shaded neutral globe the game tints (shut: unlit).
Writes design/portal2/.
"""
from __future__ import annotations

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
import common
from common import Canvas, project, to_srgb_u8, save_mask, write_json, VPX, HORIZON, FLOOR_Y, D0, PX_PER_M, depth_scale

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "portal2")
FONT = os.path.abspath(os.path.join(ROOT, "..", "game-main", "apps", "game", "assets", "fonts", "Roboto-Variable.ttf"))
CV = Canvas("portal2", x0=680.0, y0=150.0, ppw=4.0, w=660, h=1320)
SS = 4

# ----------------------------------------------------------------------------- the model
VP2_X = 21.0  # second vanishing point (the turned face's horizontals), on the plate's horizon
K = (VPX - VP2_X) / D0  # world px of x lost per metre of depth along the face
U = np.array([-K / PX_PER_M, 0.0, 1.0])
U /= np.linalg.norm(U)  # along the face, toward the back wall
EY = np.array([0.0, 1.0, 0.0])
N = np.array([U[2], 0.0, -U[0]])  # into the wall (the beyond side); -N faces the approach
O = np.array([752.0 / PX_PER_M, 0.0, 0.0])  # where the face meets the walk line (x 752, y 440)

A_F = 1.4 / U[2]  # far jamb (1.4 m behind the walk line)
A_N = -2.0 / U[2]  # near jamb (2.0 m in front of it)
A_BACK = 2.4 / U[2]  # where the face meets the corridor's back wall
A_END = A_N - 0.65  # end of the near pier
T_WALL = 0.66  # wall thickness (cast concrete), steel-lined at the reveal
H_OPEN = 3.05  # opening height (the collision body is 132 px = 3.3 m)
H_TOP = 7.8
HOOD_H0, HOOD_H1, HOOD_T = 3.05, 3.50, -0.50  # hood: 0.45 m tall, 0.5 m projection
CURT_T = -0.07  # curtain plane, in front of the face, inside the guides
GUIDE_W, GUIDE_T = 0.12, -0.13
TRAVEL = H_OPEN - 0.115  # the bottom bar stays tucked under the hood once open
BAR_H = 0.115
PITCH = 0.0667


def pt(a: float, h: float, t: float = 0.0) -> np.ndarray:
    return O + a * U + h * EY + t * N


def scr(P: np.ndarray) -> tuple[float, float]:
    return project(P[0] * PX_PER_M, P[1], P[2])


def poly(points3) -> list:
    return [scr(np.asarray(p, float)) for p in points3]


def quad_face(a0, a1, h0, h1, t=0.0):
    return poly([pt(a0, h0, t), pt(a1, h0, t), pt(a1, h1, t), pt(a0, h1, t)])


def quad_side(a, t0, t1, h0, h1):
    return poly([pt(a, h0, t0), pt(a, h0, t1), pt(a, h1, t1), pt(a, h1, t0)])


def quad_top(a0, a1, t0, t1, h):
    return poly([pt(a0, h, t0), pt(a1, h, t0), pt(a1, h, t1), pt(a0, h, t1)])


# ----------------------------------------------------------------------------- per-pixel geometry

def rays(canvas: Canvas):
    X, Y = canvas.grid()
    A = np.array([VPX / PX_PER_M, (FLOOR_Y - HORIZON) / PX_PER_M, -D0])
    B = np.stack([(X - VPX) / PX_PER_M, (HORIZON - Y) / PX_PER_M, np.full_like(X, D0)], -1)
    return A, B


RAY_A, RAY_B = rays(CV)


class Plane:
    """A planar surface: origin, two in-plane axes and its outward normal (toward the viewer)."""

    def __init__(self, origin, e1, e2, normal):
        self.o = np.asarray(origin, float)
        self.e1 = np.asarray(e1, float)
        self.e2 = np.asarray(e2, float)
        self.n = np.asarray(normal, float) / np.linalg.norm(normal)

    def points(self):
        nb = (RAY_B * self.n).sum(-1)
        tt = ((self.o - RAY_A) * self.n).sum() / np.where(np.abs(nb) < 1e-9, 1e-9, nb)
        P = RAY_A + RAY_B * tt[..., None]
        rel = P - self.o
        return P, (rel * self.e1).sum(-1), (rel * self.e2).sum(-1)


def face_plane(t=0.0):
    return Plane(pt(0, 0, t), U, EY, -N)


def side_plane(a):  # a jamb / end surface at constant a, facing the camera (-U)
    return Plane(pt(a, 0, 0), N, EY, -U)


def top_plane(h):
    return Plane(np.array([0, h, 0.0]), U, N, EY)


def front_plane(D):  # a screen-parallel plane at depth D (things on the walkway)
    return Plane(np.array([0, 0, D]), np.array([1.0, 0, 0]), EY, np.array([0, 0, -1.0]))


# ----------------------------------------------------------------------------- light

class Lamp:
    def __init__(self, name, pos, color, intensity, reach, down=0.0, note=""):
        self.name, self.pos, self.color, self.intensity, self.reach, self.down, self.note = name, np.asarray(pos, float), np.asarray(color, float), intensity, reach, down, note

    def screen(self):
        return scr(self.pos)


def from_screen(X, Y, d):
    s = depth_scale(d)
    xw = VPX + (X - VPX) / s
    h = (HORIZON + (FLOOR_Y - HORIZON) * s - Y) / (PX_PER_M * s)
    return np.array([xw / PX_PER_M, h, d])


AMBIENT = np.array([0.020, 0.032, 0.042])
WRAP = 0.06
# the corridor's door-end luminaire, moved to mid-bay (far patch v2): chain-hung, 1.9 m off the walk line
LED_SCREEN = (652.0, 190.5)
F_CORR = Lamp("corridor vapour-tight LED, chain-hung mid-bay (far patch v2)", from_screen(LED_SCREEN[0], LED_SCREEN[1], 1.9), (0.72, 0.93, 1.0), 0.50, 2.2, 2.0)
# the door light: a vapour-tight fitting on a short bracket over the hood, lighting the floor in front
F_DOOR = Lamp("door vapour-tight LED on a bracket over the hood", pt(-0.05, 4.05, -0.34), (0.86, 0.95, 1.0), 0.42, 0.8, 2.5)
# plant-room high-bays (far patch): light the reveal from the far side
F_MA = Lamp("machinery high-bay A", from_screen(790.0, 203.3, 4.0), (0.93, 0.96, 1.0), 1.4, 1.8, 2.0)
F_MB = Lamp("machinery high-bay B", from_screen(905.0, 201.2, 6.0), (0.93, 0.96, 1.0), 1.4, 1.8, 2.0)
# floor bounce: the wet corridor floor in front throws a little cold light back up onto faces that
# look at the camera (a fill, not a fixture; kept very low)
F_BOUNCE = Lamp("floor bounce (wet floor in front, under the corridor light)", np.array([17.5, 0.1, -3.5]), (0.55, 0.75, 0.85), 0.15, 4.0, 0.0)
LAMPS = (F_CORR, F_DOOR, F_MA, F_MB, F_BOUNCE)


def shade(P, Nrm, lamps=LAMPS, occlude=None):
    out = np.broadcast_to(AMBIENT, P.shape).copy()
    for lp in lamps:
        L = lp.pos - P
        dist = np.linalg.norm(L, axis=-1, keepdims=True)
        Ln = L / np.maximum(dist, 1e-6)
        ndl = np.clip((Ln * Nrm).sum(-1, keepdims=True), 0, 1)
        ndl = np.where(ndl > 0, WRAP + (1 - WRAP) * ndl, 0.0)
        fall = 1.0 / (1.0 + (dist / lp.reach) ** 2)
        if lp.down > 0:
            # a downlight: most of its output goes down, a little sideways and up (smooth, no cut-off line)
            below = np.clip((Ln[..., 1:2] + 0.35) / 1.35, 0, 1)
            fall = fall * (0.04 + 0.96 * below ** lp.down)
        k = 1.0
        if occlude is not None:
            k = occlude(lp, P)[..., None]
        out = out + lp.intensity * ndl * fall * lp.color * k
    return out


def hood_shadow_band(h):
    """The hood's shadow on the curtain from the corridor luminaire (up and to the left): the
    curtain is in full light below SH0 and in the hood's shadow above SH1 (computed below)."""
    return 1.0 - (1.0 - HOOD_SHADOW_FLOOR) * np.clip((h - SH0) / (SH1 - SH0), 0, 1) ** 1.3


def _hood_shadow_line():
    """Height on the curtain under which the corridor luminaire still sees past the hood's front
    lower edge (its two ends give the penumbra)."""
    hs = []
    for a in np.linspace(A_N, A_F, 5):
        P = pt(a, 1.0, CURT_T)
        for end in (-0.64, 0.64):
            Lp = F_CORR.pos + np.array([end, 0, 0])
            v = Lp - P
            out = -(v @ N)  # metres toward the approach side
            rise = v[1]
            edge = HOOD_T - CURT_T  # the hood projects this far past the curtain (negative)
            # the ray clears the hood edge if, by the time it is |edge| out, it is still below 3.05
            hs.append(H_OPEN - rise * (-edge) / max(out, 1e-6))
    return min(hs), max(hs)


SH0, SH1 = _hood_shadow_line()
HOOD_SHADOW_FLOOR = 0.42


# ----------------------------------------------------------------------------- materials (linear albedo)
CONCRETE = (0.205, 0.21, 0.225)  # 36231-like structural grey, matte cast
CONCRETE_DK = (0.10, 0.105, 0.115)
STEEL = (0.36, 0.37, 0.39)  # bare / galvanised steel
STEEL_WORN = (0.55, 0.56, 0.58)
GUNSHIP = (0.18, 0.195, 0.235)  # 36118 Gunship Gray paint (doors, hood, guides)
HOUSING = (0.15, 0.155, 0.175)  # 36081
DARK = (0.05, 0.055, 0.06)
YELLOW = (0.70, 0.42, 0.02)  # 33538, the door's caught-between marking only
BLACK = (0.03, 0.03, 0.035)
RED = (0.35, 0.035, 0.04)  # 31136, the emergency stop only
RUBBER = (0.025, 0.025, 0.028)


class Part:
    def __init__(self, layer, name, polys, albedo, plane=None, dims="", job="", texture=None, lit=True, shadow=None, emit=None, clip=None):
        self.layer, self.name, self.polys, self.albedo, self.plane = layer, name, polys, np.asarray(albedo, float), plane
        self.dims, self.job, self.texture, self.lit, self.shadow, self.emit, self.clip = dims, job, texture, lit, shadow, emit, clip


def mask_of(polys, canvas=CV) -> np.ndarray:
    big = Image.new("L", (canvas.w * SS, canvas.h * SS), 0)
    dr = ImageDraw.Draw(big)
    for p in polys:
        if isinstance(p, tuple) and p and p[0] == "ellipse":
            _, cx, cy, rx, ry = p
            a = canvas.px(cx - rx, cy - ry)
            b = canvas.px(cx + rx, cy + ry)
            dr.ellipse([a[0] * SS, a[1] * SS, b[0] * SS, b[1] * SS], fill=255)
        elif isinstance(p, tuple) and p and p[0] == "ring":
            _, cx, cy, ro, ri = p
            for r, f in ((ro, 255), (ri, 0)):
                a = canvas.px(cx - r, cy - r)
                b = canvas.px(cx + r, cy + r)
                dr.ellipse([a[0] * SS, a[1] * SS, b[0] * SS, b[1] * SS], fill=f)
        elif isinstance(p, tuple) and p and p[0] == "line":
            _, pts, width = p
            q = [tuple(v * SS for v in canvas.px(*xy)) for xy in pts]
            dr.line(q, fill=255, width=max(1, int(round(width * canvas.ppw * SS))))
        else:
            q = [tuple(v * SS for v in canvas.px(*xy)) for xy in p]
            dr.polygon(q, fill=255)
    return np.asarray(big.resize((canvas.w, canvas.h), Image.Resampling.BOX), dtype=np.float64) / 255.0


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


# ----------------------------------------------------------------------------- parts

def wall_parts() -> list[Part]:
    P: list[Part] = []
    fp = face_plane(0.0)
    # far reveal: the far jamb of the opening, steel-lined (hardened opening), seen through the hole
    P.append(Part("wall", "reveal_far", [quad_side(A_F, 0.0, T_WALL, 0.0, H_OPEN)], STEEL, side_plane(A_F),
                  "jamb reveal, 0.66 m cast wall lined with 6 mm steel plate", "the wall's thickness, steel-lined at the opening", texture="liner"))
    P.append(Part("wall", "threshold", [quad_top(A_N, A_F, 0.0, T_WALL, 0.0)], (0.27, 0.275, 0.29), top_plane(0.0),
                  "steel threshold plate 3.55 x 0.66 m", "metal threshold of the shielded opening; the curtain lands on its front edge", texture="threshold"))
    P.append(Part("wall", "face_upper", [quad_face(A_N, A_BACK, H_OPEN, H_TOP)], CONCRETE, fp,
                  "cast reinforced-concrete cross-wall over the opening, 0.66 m thick", "the hardened wall the door is set into", texture="concrete"))
    P.append(Part("wall", "face_far_column", [quad_face(A_F, A_BACK, 0.0, H_OPEN)], CONCRETE, fp,
                  "far column of the cross-wall, 1.05 m from the jamb to the corridor wall", "carries the door's drive-end guide", texture="concrete"))
    for i, h in enumerate((5.25,)):
        P.append(Part("wall", f"pour_joint{i}", [quad_face(A_N, A_BACK, h - 0.012, h + 0.012)], CONCRETE_DK, fp,
                      "pour line between concrete lifts", "construction joint"))
    # heavy steel frame round the opening on the face (head and far jamb; the near jamb strip is in front)
    P.append(Part("wall", "frame_far_jamb", [quad_face(A_F, A_F + 0.16, 0.0, H_OPEN + 0.16, -0.02)], GUNSHIP, face_plane(-0.02),
                  "steel channel frame 160 mm round the opening", "armours the opening's edge; the guide bolts to it"))
    P.append(Part("wall", "frame_head", [quad_face(A_N - 0.16, A_F + 0.16, H_OPEN, H_OPEN + 0.16, -0.02)], GUNSHIP, face_plane(-0.02),
                  "steel channel head 160 mm", "armours the head (hidden under the hood)"))
    P.append(Part("wall", "reveal_angle_far", [quad_side(A_F, 0.0, 0.07, 0.0, H_OPEN)], STEEL_WORN, side_plane(A_F),
                  "steel arris angle at the reveal", "protects the jamb edge"))
    P.append(Part("wall", "back_arris", [quad_face(A_BACK - 0.06, A_BACK, 0.0, H_TOP, -0.005)], CONCRETE_DK, face_plane(-0.005),
                  "internal corner with the corridor wall", "where the cross-wall meets the corridor's back wall"))
    # yellow floor line at the edge of the door's travel, in front of the curtain (one yellow element)
    P.append(Part("wall", "floor_line", [quad_top(A_N + 0.05, A_F - 0.05, -0.30, -0.24, 0.0)], YELLOW, top_plane(0.0),
                  "60 mm yellow line along the door line", "marks the door's travel; scuffed where feet cross", texture="line_wear"))
    # junction box, conduit group and the welded penetration plate, on the upper face
    jb_a0, jb_a1, jb_h0, jb_h1 = 1.30, 1.62, 4.55, 4.95
    fpp = face_plane(-0.03)
    P.append(Part("wall", "jb_backplate", [quad_face(jb_a0 - 0.04, jb_a1 + 0.04, jb_h0 - 0.05, jb_h1 + 0.05, -0.01)], HOUSING, face_plane(-0.01),
                  "backplate", "carries the box"))
    P.append(Part("wall", "jb_box", [quad_face(jb_a0, jb_a1, jb_h0, jb_h1, -0.16)], GUNSHIP, face_plane(-0.16),
                  "lockable junction box 0.32 x 0.40 x 0.15 m", "terminates the camera, operator and door-light feeds"))
    P.append(Part("wall", "jb_side", [poly([pt(jb_a0, jb_h0, -0.16), pt(jb_a0, jb_h0, -0.01), pt(jb_a0, jb_h1, -0.01), pt(jb_a0, jb_h1, -0.16)])], HOUSING,
                  Plane(pt(jb_a0, 0, 0), N, EY, -U), "box side", "the box's near side"))
    P.append(Part("wall", "jb_lock", [quad_face(jb_a1 - 0.07, jb_a1 - 0.04, 4.72, 4.78, -0.17)], STEEL, face_plane(-0.17), "padlock hasp", "lockable, tamper-protected"))
    P.append(Part("wall", "jb_plate", [quad_face(jb_a0 + 0.05, jb_a1 - 0.08, 4.86, 4.91, -0.17)], STEEL, face_plane(-0.17), "blank equipment plate", "too small to letter: blank"))
    for i, a in enumerate((1.36, 1.46, 1.56)):
        P.append(Part("wall", f"conduit_up{i}", [quad_face(a - 0.012, a + 0.012, jb_h1 + 0.05, 5.55, -0.03)], STEEL, fpp, "20 mm rigid conduit", "from the box into the penetration plate"))
    P.append(Part("wall", "penetration_plate", [quad_face(1.22, 1.70, 5.55, 5.80, -0.006)], STEEL, face_plane(-0.006),
                  "6 mm welded penetration plate, 150 mm past the conduits", "where the conduit group passes the shielded wall"))
    P.append(Part("wall", "door_light_feed", [quad_face(-0.05, jb_a0, 4.62, 4.645, -0.03), quad_face(-0.07, -0.03, 4.12, 4.645, -0.03)], STEEL, fpp,
                  "20 mm rigid conduit", "feeds the door light"))
    P.append(Part("wall", "operator_feed", [quad_face(A_F + 0.16, A_F + 0.19, 3.62, jb_h0, -0.03), quad_face(A_F + 0.16, jb_a0, jb_h0 + 0.10, jb_h0 + 0.125, -0.03)], STEEL, fpp,
                  "20 mm rigid conduit", "operator power from the box"))
    P.append(Part("wall", "feed_strap", [quad_face(A_F + 0.13, A_F + 0.22, 4.10, 4.15, -0.04)], DARK, face_plane(-0.04), "one-hole strap within 0.9 m of the box", "holds the conduit"))
    # the door light: vapour-tight fitting on a short bracket over the hood (it lights the floor)
    P.append(Part("wall", "door_light_bracket", [quad_face(-0.08, -0.02, 3.98, 4.12, -0.02), quad_face(-0.08, -0.02, 3.98, 4.04, -0.30)], HOUSING, face_plane(-0.1),
                  "bracket 0.3 m", "holds the fitting off the wall"))
    P.append(Part("wall", "door_light_body", [quad_face(-0.62, 0.58, 3.98, 4.10, -0.36)], (0.42, 0.45, 0.47), face_plane(-0.36),
                  "vapour-tight LED 1.2 x 0.12 m", "lights the door's floor and threshold"))
    P.append(Part("wall", "door_light_lens", [quad_face(-0.60, 0.56, 3.955, 3.985, -0.37)], (1, 1, 1), face_plane(-0.37),
                  "diffuser", "light source", lit=False, emit=(0.86, 0.95, 1.0)))
    return P


def stand_parts() -> list[Part]:
    """MANUAL BYPASS: a cast floor stand (pedestal) at walkway depth, anchored to the slab, with a
    worm gearbox at its head. Its handwheel (own sprite) is at hand height under the crank pose's
    hand. Its output drives the door operator through an enclosed line shaft with universal joints."""
    P: list[Part] = []
    fp = front_plane(0.15)
    cx = WHEEL_C[0]
    P.append(Part("wall", "stand_base", [rect(cx - 9.0, 437.2, cx + 9.0, 440.0)], HOUSING, front_plane(0.0), "base flange 0.45 x 0.45 m, four M16 anchors", "anchors the stand to the slab"))
    P.append(Part("wall", "stand_base_top", [rect(cx - 8.4, 436.2, cx + 8.4, 437.3)], STEEL, top_plane(0.07), "flange top", "the cast flange's top edge"))
    for i, ax in enumerate((cx - 6.6, cx + 6.6)):
        P.append(Part("wall", f"stand_anchor{i}", [("ellipse", ax, 436.8, 1.05, 0.6)], STEEL_WORN, front_plane(0.0), "M16 anchor nut", "holds the flange down"))
    P.append(Part("wall", "stand_column", [[(cx - 3.2, 436.3), (cx + 3.2, 436.3), (cx + 2.5, WHEEL_C[1] + 5.0), (cx - 2.5, WHEEL_C[1] + 5.0)]], HOUSING, fp,
                  "cast pedestal 0.16 m tapering to 0.12 m", "carries the gearbox at hand height", texture="cyl_v"))
    P.append(Part("wall", "stand_gearbox", [rect(cx - 5.2, WHEEL_C[1] - 6.0, cx + 5.2, WHEEL_C[1] + 6.0)], GUNSHIP, front_plane(0.12),
                  "worm gearbox 0.26 x 0.30 m", "many easy turns of the wheel into a few strong ones"))
    P.append(Part("wall", "stand_gearbox_top", [rect(cx - 5.0, WHEEL_C[1] - 7.0, cx + 5.0, WHEEL_C[1] - 6.0)], STEEL, top_plane(0.98), "gearbox cover", "bolted cover"))
    # enclosed line shaft from the gearbox's output (top right) up to the operator's manual input
    g = (cx + 3.0, WHEEL_C[1] - 7.0)
    o = scr(pt(A_F + 0.30, 3.20, -0.24))
    ang = math.atan2(o[1] - g[1], o[0] - g[0])
    nx_, ny_ = -math.sin(ang), math.cos(ang)
    w = 1.25
    P.append(Part("wall", "drive_guard", [[(g[0] + nx_ * w, g[1] + ny_ * w), (o[0] + nx_ * w, o[1] + ny_ * w), (o[0] - nx_ * w, o[1] - ny_ * w), (g[0] - nx_ * w, g[1] - ny_ * w)]],
                  GUNSHIP, front_plane(0.8), "enclosed line shaft, 60 mm guard tube, universal joint at each end", "carries the bypass drive to the door operator"))
    for i, t in enumerate((0.0, 1.0)):
        jx, jy = g[0] + (o[0] - g[0]) * t, g[1] + (o[1] - g[1]) * t
        P.append(Part("wall", f"drive_ujoint{i}", [("ellipse", jx, jy, 2.0, 2.0)], HOUSING, front_plane(0.8), "universal-joint housing", "lets the shaft run at an angle"))
    P.append(Part("wall", "stand_arrow_plate", [rect(cx - 4.0, WHEEL_C[1] + 7.5, cx + 4.0, WHEEL_C[1] + 9.5)], STEEL, front_plane(0.1),
                  "direction plate (embossed arrow, no lettering)", "which way opens"))
    return P


def frame_parts() -> list[Part]:
    """The door's own frame behind the walk line: the far guide, the hood (its front, top and near
    end cap), the drive-end operator."""
    P: list[Part] = []
    P.append(Part("frame", "guide_far", [quad_face(A_F - 0.02, A_F + GUIDE_W, 0.0, H_OPEN, GUIDE_T)], GUNSHIP, face_plane(GUIDE_T),
                  "guide: three 50 mm angles, 120 mm on the wall", "the curtain's drive-end edge runs in it", texture="guide"))
    P.append(Part("frame", "guide_far_side", [quad_side(A_F + GUIDE_W, GUIDE_T, 0.0, 0.0, H_OPEN)], HOUSING, side_plane(A_F + GUIDE_W),
                  "guide flange", "the angle's return to the wall"))
    a0, a1 = A_N - 0.22, A_F + 0.22
    P.append(Part("frame", "hood_front", [quad_face(a0, a1, HOOD_H0, HOOD_H1, HOOD_T)], GUNSHIP, face_plane(HOOD_T),
                  "24 ga steel hood 0.45 m tall, 0.5 m projection, 3.99 m long", "covers the coil; carries the stencilled door number", texture="hood"))
    P.append(Part("frame", "hood_top", [quad_top(a0, a1, HOOD_T, 0.0, HOOD_H1)], HOUSING, top_plane(HOOD_H1),
                  "hood top", "the hood's lid, seen from the corridor's eye height"))
    P.append(Part("frame", "hood_end_near", [quad_side(a0, HOOD_T, 0.0, HOOD_H0, HOOD_H1)], HOUSING, side_plane(a0),
                  "idle-end cap", "closes the hood's near end"))
    P.append(Part("frame", "hood_lip", [quad_face(a0, a1, HOOD_H0 - 0.012, HOOD_H0 + 0.02, HOOD_T)], DARK, face_plane(HOOD_T),
                  "hood lower lip", "folded edge"))
    # operator on the drive-end bracket, over the far column
    P.append(Part("frame", "operator_bracket", [quad_face(A_F + 0.20, A_F + 0.26, 3.00, 3.62, -0.08)], GUNSHIP, face_plane(-0.08),
                  "end bracket plate", "carries the barrel and the operator"))
    P.append(Part("frame", "operator_body", [quad_face(A_F + 0.24, A_F + 0.62, 3.14, 3.56, -0.40)], HOUSING, face_plane(-0.40),
                  "door operator 0.38 x 0.42 m at 3.1 m (>= 2.44 m)", "electric operator with a manual-drive input"))
    P.append(Part("frame", "operator_side", [quad_side(A_F + 0.24, -0.40, -0.08, 3.14, 3.56)], (0.11, 0.115, 0.13), side_plane(A_F + 0.24),
                  "operator side", "the operator's near side"))
    P.append(Part("frame", "operator_motor", [quad_face(A_F + 0.30, A_F + 0.56, 3.20, 3.42, -0.46)], DARK, face_plane(-0.46), "motor can", "motor"))
    P.append(Part("frame", "operator_input", [("ellipse",) + tuple(scr(pt(A_F + 0.30, 3.20, -0.24))) + (1.6, 1.6)], STEEL, face_plane(-0.24),
                  "manual-drive input", "the bypass line shaft drives this"))
    return P


def curtain_parts() -> list[Part]:
    P: list[Part] = []
    cp = face_plane(CURT_T)
    a0, a1 = A_N - 0.07, A_F + 0.07
    P.append(Part("curtain", "curtain_face", [quad_face(a0, a1, BAR_H, H_OPEN + 0.02, CURT_T)], GUNSHIP, cp,
                  "interlocking steel slats, 66.7 mm pitch (2.67 px at the walk line)", "the door leaf", texture="slats"))
    P.append(Part("curtain", "bottom_bar", [quad_face(a0, a1, 0.012, BAR_H, CURT_T - 0.01)], BLACK, face_plane(CURT_T - 0.01),
                  "bottom bar, two steel angles back to back, 115 mm", "stiffens the curtain's leading edge; black between the stripes"))
    P.append(Part("curtain", "bar_stripes", [quad_face(a0, a1, 0.012, BAR_H, CURT_T - 0.011)], YELLOW, face_plane(CURT_T - 0.011),
                  "45 degree yellow/black bands, 0.1 m", "caught-between hazard on the closing edge", texture="stripes"))
    P.append(Part("curtain", "astragal", [quad_face(a0, a1, 0.0, 0.014, CURT_T - 0.01)], RUBBER, face_plane(CURT_T - 0.01),
                  "rubber bulb astragal", "seals to the threshold"))
    return P


def front_parts() -> list[Part]:
    P: list[Part] = []
    fp = face_plane(0.0)
    P.append(Part("front", "pier_face", [quad_face(A_END, A_N, 0.0, H_TOP)], CONCRETE, fp,
                  "near pier of the cross-wall, 0.65 m along the face", "carries the idle-end guide", texture="concrete"))
    P.append(Part("front", "pier_end", [quad_side(A_END, 0.0, T_WALL, 0.0, H_TOP)], CONCRETE, side_plane(A_END),
                  "pier end face, the 0.66 m wall thickness", "the cross-wall's end toward the corridor's open side", texture="concrete"))
    P.append(Part("front", "arris_end_left", [quad_side(A_END, 0.0, 0.065, 0.0, H_TOP)], STEEL, side_plane(A_END),
                  "65 mm steel arris angle", "armours the corner (carts, blast)"))
    P.append(Part("front", "arris_end_right", [quad_side(A_END, T_WALL - 0.065, T_WALL, 0.0, H_TOP)], STEEL, side_plane(A_END),
                  "65 mm steel arris angle", "armours the corner"))
    P.append(Part("front", "arris_face", [quad_face(A_END, A_END + 0.065, 0.0, H_TOP, -0.004)], STEEL, face_plane(-0.004),
                  "steel arris angle, face leg", "armours the corner"))
    P.append(Part("front", "frame_near_jamb", [quad_face(A_N - 0.16, A_N, 0.0, H_OPEN + 0.16, -0.02)], GUNSHIP, face_plane(-0.02),
                  "steel channel frame 160 mm", "armours the jamb; the guide bolts to it"))
    P.append(Part("front", "guide_near", [quad_face(A_N - GUIDE_W, A_N + 0.02, 0.0, H_OPEN, GUIDE_T)], GUNSHIP, face_plane(GUIDE_T),
                  "guide: three 50 mm angles", "the curtain's idle-end edge runs in it", texture="guide"))
    # status lamp on the pier end (cast base, globe in a wire guard; the globe is a hole, the live
    # lens draws under the guard bars)
    tl = T_WALL / 2
    sp = side_plane(A_END)
    lc = scr(pt(A_END, LAMP_H, tl - 0.0))
    P.append(Part("front", "lamp_base", [quad_side(A_END - 0.10, tl - 0.09, tl + 0.09, LAMP_H - 0.17, LAMP_H - 0.10)], HOUSING, side_plane(A_END - 0.10),
                  "cast lamp body on a conduit box", "carries the globe"))
    P.append(Part("front", "lamp_conduit", [quad_side(A_END - 0.03, tl - 0.012, tl + 0.012, LAMP_H - 0.10, LAMP_H + 0.02)], STEEL, side_plane(A_END - 0.03),
                  "20 mm conduit", "feeds the lamp"))
    P.append(Part("front", "lamp_conduit_up", [quad_side(A_END - 0.03, tl - 0.012, tl + 0.012, LAMP_H + 0.12, 4.40)], STEEL, side_plane(A_END - 0.03),
                  "20 mm conduit up the pier", "from the camera's box"))
    P.append(Part("front", "lamp_cap", [quad_side(A_END - 0.10, tl - 0.07, tl + 0.07, LAMP_H + 0.085, LAMP_H + 0.12)], HOUSING, side_plane(A_END - 0.10),
                  "guard cap", "tops the wire guard"))
    for i, dt in enumerate((-0.055, 0.0, 0.055)):
        P.append(Part("front", f"lamp_guard{i}", [quad_side(A_END - 0.13, tl + dt - 0.007, tl + dt + 0.007, LAMP_H - 0.10, LAMP_H + 0.09)], STEEL, side_plane(A_END - 0.13),
                      "wire guard bar", "protects the globe"))
    # push-button station: lockable steel enclosure on a backplate, on the pier end at 1.6 m
    P.append(Part("front", "pb_backplate", [quad_side(A_END - 0.01, tl - 0.15, tl + 0.15, 1.42, 1.80)], HOUSING, side_plane(A_END - 0.01), "backplate", "carries the station"))
    P.append(Part("front", "pb_box", [quad_side(A_END - 0.10, tl - 0.12, tl + 0.12, 1.45, 1.77)], GUNSHIP, side_plane(A_END - 0.10),
                  "OPEN/CLOSE/STOP station at 1.6 m in a lockable cover", "push-button station"))
    P.append(Part("front", "pb_hinge", [quad_side(A_END - 0.11, tl - 0.12, tl - 0.10, 1.47, 1.75)], DARK, side_plane(A_END - 0.11), "cover hinge", "hinged cover"))
    P.append(Part("front", "pb_lock", [quad_side(A_END - 0.11, tl + 0.085, tl + 0.105, 1.60, 1.64)], STEEL, side_plane(A_END - 0.11), "cam lock", "keeps the cover shut"))
    for i, (h, col) in enumerate(((1.71, DARK), (1.62, DARK), (1.52, RED))):
        c = scr(pt(A_END - 0.12, h, tl))
        P.append(Part("front", f"pb_button{i}", [("ellipse", c[0], c[1], 1.05, 1.05)], col, side_plane(A_END - 0.12),
                      "22 mm button", ("open", "close", "emergency stop (the view's one painted red)")[i]))
    P.append(Part("front", "pb_conduit", [quad_side(A_END - 0.03, tl - 0.012, tl + 0.012, 1.80, LAMP_H - 0.17)], STEEL, side_plane(A_END - 0.03),
                  "20 mm conduit", "from the lamp box to the station"))
    # fixed surveillance camera on a wall arm on the pier's approach face, watching the approach
    cam_a, cam_h = A_END + 0.28, 4.35
    P.append(Part("front", "cam_plate", [quad_face(cam_a - 0.07, cam_a + 0.07, cam_h - 0.16, cam_h + 0.16, -0.01)], HOUSING, face_plane(-0.01),
                  "wall plate 0.14 x 0.32 m, two anchors", "fixes the arm"))
    P.append(Part("front", "cam_arm", [poly([pt(cam_a, cam_h + 0.03, -0.02), pt(cam_a, cam_h + 0.03, -0.42), pt(cam_a, cam_h - 0.03, -0.42), pt(cam_a, cam_h - 0.03, -0.02)])], HOUSING,
                  Plane(pt(cam_a, 0, 0), N, EY, -U), "tubular arm 0.4 m", "holds the housing off the wall"))
    hx, hy = scr(pt(cam_a, cam_h, -0.44))
    P.append(Part("front", "cam_housing", [[(hx - 13.5, hy - 2.6), (hx + 1.5, hy - 3.4), (hx + 1.8, hy + 2.4), (hx - 13.0, hy + 3.6)]], GUNSHIP, front_plane(-2.7),
                  "fixed camera in a vandal-resistant housing 0.36 x 0.14 m", "watches the approach; static art, no glow"))
    P.append(Part("front", "cam_sunshield", [[(hx - 14.6, hy - 4.2), (hx + 2.0, hy - 5.0), (hx + 2.2, hy - 3.3), (hx - 14.2, hy - 2.5)]], HOUSING, front_plane(-2.7),
                  "sunshield", "the housing's top cover"))
    P.append(Part("front", "cam_window", [[(hx - 13.6, hy - 2.0), (hx - 12.2, hy - 2.2), (hx - 11.8, hy + 3.0), (hx - 13.1, hy + 3.2)]], DARK, front_plane(-2.7),
                  "front window", "dark lens window"))
    P.append(Part("front", "cam_conduit", [quad_face(cam_a - 0.012, cam_a + 0.012, 4.40, cam_h - 0.16, -0.02), quad_face(A_END + 0.02, cam_a, 4.40, 4.425, -0.02)], STEEL, face_plane(-0.02),
                  "20 mm conduit", "camera feed round the corner and down to the lamp box"))
    return P


LAMP_H = 2.65
WHEEL_C = (695.0, 403.0)
WHEEL_R = 10.5  # 0.525 m handwheel


def wheel_parts(canvas: Canvas) -> list[Part]:
    cx, cy = WHEEL_C
    r = WHEEL_R
    P: list[Part] = []
    fp = front_plane(-0.12)
    P.append(Part("wheel", "wheel_rim", [("ring", cx, cy, r, r - 1.9)], STEEL_WORN, fp, "0.525 m cast steel handwheel rim", "bare steel, polished where hands grip it", texture="rim"))
    spokes = []
    for k in range(5):
        a = -math.pi / 2 + k * 2 * math.pi / 5
        ca, sa = math.cos(a), math.sin(a)
        px, py = -sa * 0.8, ca * 0.8
        p0 = (cx + ca * 2.2, cy + sa * 2.2)
        p1 = (cx + ca * (r - 1.4), cy + sa * (r - 1.4))
        spokes.append([(p0[0] + px, p0[1] + py), (p1[0] + px, p1[1] + py), (p1[0] - px, p1[1] - py), (p0[0] - px, p0[1] - py)])
    P.append(Part("wheel", "wheel_spokes", spokes, GUNSHIP, fp, "five spokes", "painted spokes"))
    P.append(Part("wheel", "wheel_hub", [("ellipse", cx, cy, 2.7, 2.7)], HOUSING, front_plane(-0.14), "hub on the input shaft", "hub"))
    a = -math.pi / 2 + math.pi / 5
    kx, ky = cx + math.cos(a) * (r - 0.95), cy + math.sin(a) * (r - 0.95)
    P.append(Part("wheel", "wheel_knob", [("ellipse", kx, ky, 1.35, 1.35)], DARK, front_plane(-0.2), "spinner knob", "for many fast turns"))
    return P


# ----------------------------------------------------------------------------- textures (procedural value structure only; Codex paints the material)

def texture_mod(part: Part, la, lb, X, Y) -> np.ndarray:
    t = part.texture
    if t == "slats":
        h = lb
        f = ((h - BAR_H) / PITCH) % 1.0
        prof = 1.12 - 0.40 * f
        return np.where(f > 0.86, 0.38, prof)
    if t == "stripes":
        s = ((la * 1.0 + lb * 1.0) / 0.10) % 2.0
        return np.where(s < 1.0, 1.0, 0.045)  # yellow / black (black via the low factor on yellow)
    if t == "guide":
        return np.where(((la - la.min()) % 0.06) < 0.012, 0.7, 1.0) if False else 1.0
    if t == "liner":
        return 1.0
    return 1.0


# ----------------------------------------------------------------------------- render

def render(parts: list[Part], canvas: Canvas = CV, layer_order=None):
    H, W = canvas.h, canvas.w
    out = {}
    X, Y = canvas.grid()
    for p in parts:
        m = mask_of(p.polys, canvas)
        if p.clip is not None:
            m = m * p.clip
        if p.emit is not None:
            col = np.broadcast_to(np.array(p.emit), (H, W, 3))
        else:
            pl = p.plane if p.plane is not None else front_plane(0.0)
            if canvas is CV:
                Pp, la, lb = pl.points()
            else:
                A, B = rays(canvas)
                nb = (B * pl.n).sum(-1)
                tt = ((pl.o - A) * pl.n).sum() / np.where(np.abs(nb) < 1e-9, 1e-9, nb)
                Pp = A + B * tt[..., None]
                rel = Pp - pl.o
                la, lb = (rel * pl.e1).sum(-1), (rel * pl.e2).sum(-1)
            if p.layer == "curtain":
                # the moving curtain carries no light that depends on its height: its light is a
                # function of the column only, at a reference height; the hood's fixed shadow band
                # is applied by the game per screen row (SealLeaf), and baked here for the shut state
                Pref = Pp.copy()
                Pref[..., 1] = 1.0
                L = shade(Pref, pl.n)
                L = L * hood_shadow_band(lb)[..., None]
            else:
                L = shade(Pp, pl.n)
            col = p.albedo * L
            tm = texture_mod(p, la, lb, X, Y)
            col = col * (tm[..., None] if isinstance(tm, np.ndarray) else tm)
        lay = out.setdefault(p.layer, {"lin": np.zeros((H, W, 3)), "a": np.zeros((H, W)), "masks": {}})
        lay["lin"] = lay["lin"] * (1 - m[..., None]) + col * m[..., None]
        lay["a"] = m + lay["a"] * (1 - m)
        lay["masks"][p.name] = m
    return out


def contact_shadows(canvas: Canvas = CV) -> np.ndarray:
    """Floor contact shadows (alpha on near-black), darkest at the contact line: the cross-wall's foot
    on the approach side (far column and near pier) and under the bypass stand's flange."""
    X, Y = canvas.grid()
    sh = np.zeros((canvas.h, canvas.w))
    # along the face's foot line on the floor (approach side): distance from the line in metres
    fpl = top_plane(0.0)
    Pp, la, lb = fpl.points()
    # lb is the coordinate along N (into the wall); the approach side is lb < 0
    out_m = -lb
    for a0, a1 in ((A_F + 0.16, A_BACK), (A_END, A_N - 0.16)):
        inside = (la >= a0) & (la <= a1) & (out_m >= 0)
        edge = np.clip(np.minimum(la - a0, a1 - la) / 0.15, 0, 1)
        sh = np.maximum(sh, np.where(inside, 0.58 * np.exp(-np.clip(out_m, 0, 50) / 0.16) * edge, 0))
    # the near pier's end face foot (toward the camera): distance along -U from the end face
    d_end = (A_END - la)
    inside = (lb >= 0) & (lb <= T_WALL) & (d_end >= 0)
    sh = np.maximum(sh, np.where(inside, 0.55 * np.exp(-np.clip(d_end, 0, 50) / 0.18), 0))
    # the bypass stand's flange (walkway depth), a footprint shadow 6 px deep in front of it
    cx = WHEEL_C[0]
    dy = Y - 440.0
    inside = (dy >= 0) & (X >= cx - 11) & (X <= cx + 11)
    edge = np.clip(np.minimum(X - (cx - 11), (cx + 11) - X) / 2.5, 0, 1)
    sh = np.maximum(sh, np.where(inside, 0.6 * np.exp(-np.clip(dy, 0, 500) / 2.6) * edge, 0))
    return sh


def text_layer(word: str, cap_m: float, plane: Plane, a_center: float, h_base: float, condensed=False):
    """Typesets [word] in the game's Roboto (weight 700) with stencil bridges in the plane's own
    coordinates (metres), then maps it onto the canvas through the projection: a stencil painted on a
    turned face, seen from the corridor. Returns a coverage mask."""
    res = 400.0  # px per metre in plane space
    cap_px = cap_m * res
    f = ImageFont.truetype(FONT, max(4, int(round(cap_px / 0.711))))
    f.set_variation_by_axes([700, 75 if condensed else 100])
    pad = int(cap_px)
    w = int(f.getlength(word) * 1.3) + 2 * pad
    hgt = int(cap_px * 2.2) + 2 * pad
    img = Image.new("L", (w, hgt), 0)
    d = ImageDraw.Draw(img)
    x = pad
    for ch in word:
        d.text((x, pad), ch, font=f, fill=255)
        x += f.getlength(ch) + 0.06 * cap_px
    a = np.asarray(img, dtype=np.float64) / 255.0
    rows = np.nonzero(a.max(1) > 0.5)[0]
    cols = np.nonzero(a.max(0) > 0.5)[0]
    a = a[rows.min():rows.max() + 1, cols.min():cols.max() + 1]
    sys.path.insert(0, os.path.dirname(__file__))
    from text_layer import bridges
    a = bridges(a, cap_px)
    hh, ww = a.shape
    Pp, la, lb = plane.points()
    # the face's in-plane axis U runs toward the back wall, which is leftward on screen: the text
    # reads from high a to low a
    u = ((a_center + ww / res / 2) - la) * res
    v = (h_base + hh / res - lb) * res
    cov = ndimage.map_coordinates(a, [v, u], order=1, mode="constant", cval=0.0)
    return np.clip(cov, 0, 1), {"text": word, "cap_world_px": round(cap_m * PX_PER_M, 2), "plane_length_m": round(ww / res, 3)}


def lens_texture() -> Image.Image:
    """The status lamp's glass: a shaded neutral globe (a light cap highlight, a darker rim), white
    so the game tints it; 32 x 40 px for an 8 x 10 world px globe."""
    w, h = 32, 40
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    cx, cy, rx, ry = 15.5, 19.5, 11.5, 15.5
    d = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
    a = np.clip((1.0 - d) * 6.0, 0, 1)
    body = 0.78 + 0.22 * (1 - d ** 2)
    hl = np.exp(-(((xx - (cx - 4)) / 3.0) ** 2 + ((yy - (cy - 7)) / 4.5) ** 2)) * 0.35
    rim = np.clip((d - 0.75) / 0.25, 0, 1) * 0.35
    v = np.clip(body + hl - rim, 0, 1)
    rgba = np.dstack([v, v, v, a])
    return Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA")


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    parts = wall_parts() + stand_parts() + frame_parts() + curtain_parts() + front_parts()
    layers = render(parts)
    # the doorway: alpha 0 in the wall layer (the face's opening; the reveal and threshold stay)
    hole_face = mask_of([quad_face(A_N, A_F, 0.0, H_OPEN)])
    reveal = layers["wall"]["masks"]["reveal_far"]
    thr = layers["wall"]["masks"]["threshold"]
    keep = np.clip(reveal + layers["wall"]["masks"]["reveal_angle_far"] + thr + layers["wall"]["masks"]["floor_line"], 0, 1)
    hole = np.clip(hole_face - keep, 0, 1)
    # the drive guard and stand are in front of the opening region? (no: x < 726) - keep only wall parts
    layers["wall"]["a"] = layers["wall"]["a"] * (1 - hole)
    layers["wall"]["masks"]["HOLE"] = hole
    # contact shadows on the floor, under everything else in the wall layer
    sh = contact_shadows()
    wa = layers["wall"]["a"]
    lin = layers["wall"]["lin"]
    sh = sh * (1 - hole)
    out_a = wa + sh * (1 - wa)
    w_sh = np.where(out_a > 0, sh * (1 - wa) / np.maximum(out_a, 1e-6), 0)
    lin = lin * (1 - w_sh[..., None]) + np.array([0.0008, 0.0015, 0.0025]) * w_sh[..., None]
    layers["wall"]["lin"], layers["wall"]["a"] = lin, out_a
    layers["wall"]["masks"]["contact_shadow"] = sh
    # the lamp's glass is a hole in the front layer (the live lens draws under the guard bars)
    tl = T_WALL / 2
    lcx, lcy = scr(pt(A_END - 0.12, LAMP_H, tl))
    glass = mask_of([("ellipse", lcx, lcy, 2.05, 2.55)])
    guard = np.clip(sum(layers["front"]["masks"][f"lamp_guard{i}"] for i in range(3)), 0, 1)
    glass_hole = np.clip(glass - guard, 0, 1)
    layers["front"]["a"] = layers["front"]["a"] * (1 - glass_hole)
    layers["front"]["masks"]["GLASS_HOLE"] = glass_hole
    # typeset stencils (37875 lusterless white), in each surface's own plane
    marks = []
    sec, info = text_layer("SECTOR 4B", 0.30, face_plane(0.0), (A_N + A_BACK) / 2 - 0.15, 5.95)
    sec = sec * layers["wall"]["masks"]["face_upper"]
    info.update({"layer": "wall", "where": "cross-wall upper face, high", "status": "proposed, awaiting Nathanial"})
    marks.append(info)
    door, info = text_layer("DOOR 4B-07", 0.30, face_plane(HOOD_T - 0.002), (A_N + A_F) / 2, HOOD_H0 + 0.075)
    door = door * layers["frame"]["masks"]["hood_front"]
    info.update({"layer": "frame", "where": "hood front (fixed; does not scroll with the slats)", "status": "proposed, awaiting Nathanial"})
    marks.append(info)
    save_mask(sec, os.path.join(OUT, "masks", "TEXT-wall.png"))
    save_mask(door, os.path.join(OUT, "masks", "TEXT-frame.png"))
    # the wheel on its own canvas
    WC = Canvas("wheel", x0=WHEEL_C[0] - 11.0, y0=WHEEL_C[1] - 11.0, ppw=4.0, w=88, h=88)
    wl = render(wheel_parts(WC), WC)["wheel"]
    wheel_on_cv = render(wheel_parts(CV))["wheel"]
    for name, lay in list(layers.items()) + [("wheel", wl)]:
        rgba = np.dstack([to_srgb_u8(lay["lin"]), (np.clip(lay["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, f"design-{name}.png"))
        for mname, m in lay["masks"].items():
            save_mask(m, os.path.join(OUT, "masks", f"{name}--{mname}.png"))
        save_mask(lay["a"], os.path.join(OUT, "masks", f"{name}--ALPHA.png"))
    rgba = np.dstack([to_srgb_u8(wheel_on_cv["lin"]), (np.clip(wheel_on_cv["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "design-wheel-on-canvas.png"))
    lens_texture().save(os.path.join(OUT, "lens.png"))
    # composites (closed / open) over a neutral dark field, for review and for the edit targets
    def comp(names, bg=(36, 38, 42)):
        o = Image.new("RGBA", (CV.w, CV.h), bg + (255,))
        for n in names:
            o.alpha_composite(Image.open(os.path.join(OUT, f"design-{n}.png")))
        return o
    comp(["wall", "curtain", "frame", "wheel-on-canvas", "front"]).save(os.path.join(OUT, "design-closed.png"))
    comp(["wall", "frame", "wheel-on-canvas", "front"]).save(os.path.join(OUT, "design-open.png"))
    # the SealLeaf mesh table: curtain columns (screen x, floor y, px per metre) in world px
    cols = []
    for a in np.linspace(A_N - 0.07, A_F + 0.07, 9):
        x0, y0 = scr(pt(a, 0.0, CURT_T))
        x1, y1 = scr(pt(a, 1.0, CURT_T))
        cols.append([round(x0, 3), round(y0, 3), round(y0 - y1, 4)])
    spec = {
        "model": {"vp2": [VP2_X, HORIZON], "u": U.round(5).tolist(), "n_into_wall": N.round(5).tolist(), "origin_walkline": [752.0, 440.0],
                  "a_far_jamb": A_F, "a_near_jamb": A_N, "a_back": A_BACK, "a_pier_end": A_END, "wall_thickness_m": T_WALL,
                  "opening_m": [round((A_F - A_N), 3), H_OPEN], "hood": [HOOD_H0, HOOD_H1, HOOD_T], "curtain_t": CURT_T, "travel_m": TRAVEL,
                  "hood_shadow_band_m": [round(SH0, 3), round(SH1, 3), HOOD_SHADOW_FLOOR]},
        "screen": {"far_jamb_foot": scr(pt(A_F, 0)), "near_jamb_foot": scr(pt(A_N, 0)), "walk_crossing": scr(pt(0, 0)), "pier_end_foot": [scr(pt(A_END, 0)), scr(pt(A_END, 0, T_WALL))],
                   "far_column_back_foot": scr(pt(A_BACK, 0)), "opening_top": [scr(pt(A_F, H_OPEN)), scr(pt(A_N, H_OPEN))],
                   "hood_lower_edge": [scr(pt(A_N - 0.22, HOOD_H0, HOOD_T)), scr(pt(A_F + 0.22, HOOD_H0, HOOD_T))],
                   "lamp_centre": [round(lcx, 3), round(lcy, 3)], "wheel_centre": WHEEL_C, "wheel_radius": WHEEL_R,
                   "door_light": F_DOOR.screen(), "corridor_led": LED_SCREEN},
        "curtain_columns": cols,
        "canvas": {"world_box": [CV.x0, CV.y0, CV.x0 + CV.w / CV.ppw, CV.y0 + CV.h / CV.ppw], "px_per_world": CV.ppw},
        "wheel_canvas": {"world_box": [WC.x0, WC.y0, WC.x0 + WC.w / 4, WC.y0 + WC.h / 4]},
        "lamps": [{"name": l.name, "pos_m": l.pos.round(3).tolist(), "screen": [round(v, 1) for v in l.screen()]} for l in LAMPS],
        "marks": marks,
        "parts": {lay: [{"name": p.name, "dims": p.dims, "job": p.job} for p in parts + wheel_parts(CV) if p.layer == lay] for lay in ("wall", "frame", "curtain", "front", "wheel")},
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print(json.dumps({k: spec[k] for k in ("model", "screen")}, indent=1))


if __name__ == "__main__":
    main()
