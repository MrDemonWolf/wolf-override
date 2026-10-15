"""Service Junction blast door: camera, 3D model frame, light and the flat renderer (scratch only).

Same method as the corridor door end (docs/research-2026-10/sources/corridor-door-end-2026-10-12,
tools/design/common.py and portal2.py), registered to THIS room's plates:

  Camera, measured from the junction mid plate's deck seams (source rows 796 and 880, seams at
  source x 777.5 -> 742.5, 1047.5 -> 1050, 1137.5 -> 1155): floor vanishing point at world
  (511, 162). The walkway depth D0 = 38 m is the corridor's (the same painter's camera; the
  junction's deck front edge then sits 6.2 m in front of the walk line, y 494). 1 m = 40 world px at
  the walk line; the floor is y 440.

  Model: metres, P = (x / 40 at walkway depth, height, d metres behind the walk line; d < 0 is
  nearer the camera). A cast-concrete cross-wall stands ACROSS the walkway, its approach face turned
  17 degrees toward the camera (the corridor's angle), so its horizontals run to VP2 = (46.3, 162).
  Its approach face crosses the walk line at x 472 (the valve, x 369.4..470.6, stands just in front of
  it; the collision face stays at M0State.JUNCTION_DOOR_LEFT_X = 452, inside the valve's footprint).
  a runs along the face toward the back wall, t across the wall into the lane (0 = approach face).
"""
from __future__ import annotations

import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw

# --- CONFIG ---------------------------------------------------------------------------------------
# WORK is this track's folder (design/, layers/, codex/ ... live under it). Point
# WOLF_JUNCTION_DOOR_WORK at your own copy to run the tools again.
WORK = os.environ.get("WOLF_JUNCTION_DOOR_WORK", os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
MAIN = os.path.join(WORK, "..", "main-junction", "apps", "game")
# --------------------------------------------------------------------------------------------------

PXM = 40.0
FLOOR_Y = 440.0
VPX = 511.0
HORIZON = 162.0
D0 = 38.0
THETA = math.radians(17.0)
K = math.tan(THETA) * PXM  # world px of x per metre of depth along the face
VP2_X = VPX - K * D0

U = np.array([-math.sin(THETA), 0.0, math.cos(THETA)])  # along the face, toward the back wall
EY = np.array([0.0, 1.0, 0.0])
N = np.array([math.cos(THETA), 0.0, math.sin(THETA)])  # through the wall, into the lane
O = np.array([472.0 / PXM, 0.0, 0.0])  # where the approach face meets the walk line

# ---- dimensions (metres) --------------------------------------------------------------------------
T_WALL = 0.40  # cast reinforced-concrete partition
D_FAR = 0.55  # depth of the far (latch) jamb behind the walk line
W_OPEN = 2.30  # clear opening along the face
H_OPEN = 2.60  # clear opening height
FR = 0.18  # steel channel frame: its approach-face flange width
A_F = D_FAR / math.cos(THETA)  # far (latch) jamb
A_N = A_F - W_OPEN  # near (hinge) jamb, 1.66 m in front of the walk line
A_E = A_N - FR - 0.02  # the wall's end (the near column's end face)
D_BACK = 5.30  # the back wall (its corner with the cross-wall at screen x ~420, behind the valve)
A_BACK = D_BACK / math.cos(THETA)
H_TOP = 8.2  # well above the top of any framing (y < 136)
LEAF_T0, LEAF_T1 = 0.03, 0.33  # the leaf sits behind the approach-side stop: 0.30 m thick
STUB_H = 0.15
DECK_FRONT_D = -6.2  # the deck's front edge (y 494)
LAMP_H = 2.30  # status lamp globe centre, on the column's end face


def pt(a: float, h: float, t: float = 0.0) -> np.ndarray:
    return O + a * U + h * EY + t * N


def project(P) -> tuple[float, float]:
    s = D0 / (D0 + P[2])
    return (VPX + (P[0] * PXM - VPX) * s, HORIZON + (FLOOR_Y - HORIZON) * s - P[1] * PXM * s)


def scr(P) -> tuple[float, float]:
    return project(np.asarray(P, float))


def from_screen(X: float, Y: float, d: float) -> np.ndarray:
    s = D0 / (D0 + d)
    xw = VPX + (X - VPX) / s
    h = (HORIZON + (FLOOR_Y - HORIZON) * s - Y) / (PXM * s)
    return np.array([xw / PXM, h, d])


def poly(points3) -> list:
    return [scr(p) for p in points3]


def quad_face(a0, a1, h0, h1, t=0.0):
    return poly([pt(a0, h0, t), pt(a1, h0, t), pt(a1, h1, t), pt(a0, h1, t)])


def quad_side(a, t0, t1, h0, h1):
    return poly([pt(a, h0, t0), pt(a, h0, t1), pt(a, h1, t1), pt(a, h1, t0)])


def quad_top(a0, a1, t0, t1, h):
    return poly([pt(a0, h, t0), pt(a1, h, t0), pt(a1, h, t1), pt(a0, h, t1)])


# ---- canvas ---------------------------------------------------------------------------------------
class Canvas:
    def __init__(self, x0, y0, x1, y1, ppw):
        self.x0, self.y0, self.ppw = x0, y0, ppw
        self.w = int(round((x1 - x0) * ppw))
        self.h = int(round((y1 - y0) * ppw))

    def px(self, X, Y):
        return ((X - self.x0) * self.ppw, (Y - self.y0) * self.ppw)

    def grid(self, box=None):
        x0, y0, x1, y1 = box if box else (0, 0, self.w, self.h)
        ys, xs = np.mgrid[y0:y1, x0:x1].astype(np.float64)
        return self.x0 + (xs + 0.5) / self.ppw, self.y0 + (ys + 0.5) / self.ppw


# The design canvas: everything this piece draws, at 4 px per world px.
CV = Canvas(400.0, 136.0, 664.0, 504.0, 4.0)
SS = 4


def _bbox(polys, canvas, pad=2):
    xs, ys = [], []
    for p in polys:
        if isinstance(p, tuple) and p and p[0] in ("ellipse", "ring"):
            cx, cy = p[1], p[2]
            rx, ry = (p[3], p[4]) if p[0] == "ellipse" else (p[3], p[3])
            a = canvas.px(cx - rx, cy - ry)
            b = canvas.px(cx + rx, cy + ry)
            xs += [a[0], b[0]]
            ys += [a[1], b[1]]
        elif isinstance(p, tuple) and p and p[0] == "line":
            for q in p[1]:
                c = canvas.px(*q)
                xs.append(c[0])
                ys.append(c[1])
        else:
            for q in p:
                c = canvas.px(*q)
                xs.append(c[0])
                ys.append(c[1])
    x0 = max(0, int(math.floor(min(xs))) - pad)
    y0 = max(0, int(math.floor(min(ys))) - pad)
    x1 = min(canvas.w, int(math.ceil(max(xs))) + pad)
    y1 = min(canvas.h, int(math.ceil(max(ys))) + pad)
    return x0, y0, max(x0 + 1, x1), max(y0 + 1, y1)


def mask_of(polys, canvas=CV) -> np.ndarray:
    """Anti-aliased coverage (0..1) of the polygons over the whole canvas; drawn only inside their
    bounding box."""
    out = np.zeros((canvas.h, canvas.w))
    if not polys:
        return out
    x0, y0, x1, y1 = _bbox(polys, canvas)
    big = Image.new("L", ((x1 - x0) * SS, (y1 - y0) * SS), 0)
    dr = ImageDraw.Draw(big)

    def q(X, Y):
        c = canvas.px(X, Y)
        return ((c[0] - x0) * SS, (c[1] - y0) * SS)

    for p in polys:
        if isinstance(p, tuple) and p and p[0] == "ellipse":
            _, cx, cy, rx, ry = p
            a, b = q(cx - rx, cy - ry), q(cx + rx, cy + ry)
            dr.ellipse([a[0], a[1], b[0], b[1]], fill=255)
        elif isinstance(p, tuple) and p and p[0] == "ring":
            _, cx, cy, ro, ri = p
            for r, f in ((ro, 255), (ri, 0)):
                a, b = q(cx - r, cy - r), q(cx + r, cy + r)
                dr.ellipse([a[0], a[1], b[0], b[1]], fill=f)
        elif isinstance(p, tuple) and p and p[0] == "line":
            _, pts, width = p
            dr.line([q(*xy) for xy in pts], fill=255, width=max(1, int(round(width * canvas.ppw * SS))))
        else:
            dr.polygon([q(*xy) for xy in p], fill=255)
    small = np.asarray(big.resize((x1 - x0, y1 - y0), Image.Resampling.BOX), dtype=np.float64) / 255.0
    out[y0:y1, x0:x1] = small
    return out


# ---- planes and light -----------------------------------------------------------------------------
def rays(canvas=CV):
    X, Y = canvas.grid()
    A = np.array([VPX / PXM, (FLOOR_Y - HORIZON) / PXM, -D0])
    B = np.stack([(X - VPX) / PXM, (HORIZON - Y) / PXM, np.full_like(X, D0)], -1)
    return A, B


RAY_A, RAY_B = rays(CV)


class Plane:
    def __init__(self, origin, e1, e2, normal):
        self.o = np.asarray(origin, float)
        self.e1 = np.asarray(e1, float)
        self.e2 = np.asarray(e2, float)
        n = np.asarray(normal, float)
        self.n = n / np.linalg.norm(n)

    def points(self, A=RAY_A, B=RAY_B):
        nb = (B * self.n).sum(-1)
        tt = ((self.o - A) * self.n).sum() / np.where(np.abs(nb) < 1e-9, 1e-9, nb)
        P = A + B * tt[..., None]
        rel = P - self.o
        return P, (rel * self.e1).sum(-1), (rel * self.e2).sum(-1)


def face_plane(t=0.0):  # the approach face (and planes parallel to it), facing the approach side
    return Plane(pt(0, 0, t), U, EY, -N)


def side_plane(a):  # a surface at constant a facing the camera (-U): the column's end, the far reveal
    return Plane(pt(a, 0, 0), N, EY, -U)


def top_plane(h):
    return Plane(np.array([0, h, 0.0]), U, N, EY)


def front_plane(d):  # screen-parallel at depth d
    return Plane(np.array([0, 0, d]), np.array([1.0, 0, 0]), EY, np.array([0, 0, -1.0]))


def general_plane(p0, p1, p2):
    """Through three points; normal oriented toward the camera."""
    p0, p1, p2 = (np.asarray(p, float) for p in (p0, p1, p2))
    e1 = (p1 - p0) / np.linalg.norm(p1 - p0)
    n = np.cross(p1 - p0, p2 - p0)
    eye = np.array([VPX / PXM, (FLOOR_Y - HORIZON) / PXM, -D0])
    if (n * (eye - p0)).sum() < 0:
        n = -n
    n = n / np.linalg.norm(n)
    e2 = np.cross(n, e1)
    return Plane(p0, e1, e2, n)


class Lamp:
    def __init__(self, name, pos, color, intensity, reach, down=0.0, note=""):
        self.name, self.pos, self.color = name, np.asarray(pos, float), np.asarray(color, float)
        self.intensity, self.reach, self.down, self.note = intensity, reach, down, note

    def screen(self):
        return scr(self.pos)


# Far plate lamps (RoomDepth lamps as fractions of the far plate at x 0, y 79 + 540 high), at the
# back wall: they light the approach side (lamp 0, left), the lane behind the cross-wall (lamp 1,
# now hidden from the camera by the wall's upper face) and the lane's far end (lamp 2).
def _far_lamp(fx, fy, d=D_BACK):
    return from_screen(fx * 960.0, 79.0 + fy * 540.0, d)


A_MID = (A_F + A_N) / 2
F_DOOR = Lamp("door light: vapour-tight LED 1.2 m on a bracket over the door head", pt(A_MID, 3.22, -0.34), (0.86, 0.95, 1.0), 2.6, 1.25, 2.5,
              "lights the leaf, the frame, the threshold and the valve's top; falls off down the leaf")
F_L0 = Lamp("far-plate lamp 0 (approach side)", _far_lamp(0.139, 0.268), (0.62, 0.9, 1.0), 1.4, 4.5, 2.0)
F_L1 = Lamp("far-plate lamp 1 (lane side, behind the cross-wall)", _far_lamp(0.493, 0.268), (0.62, 0.9, 1.0), 3.5, 4.0, 2.0)
F_L2 = Lamp("far-plate lamp 2 (lane, far end)", _far_lamp(0.857, 0.268), (0.62, 0.9, 1.0), 3.0, 4.5, 2.0)
F_ALC = Lamp("alcove fitting: vapour-tight LED 0.6 m under the bay's header", from_screen(585.5, 318.0, 1.9), (0.86, 0.95, 1.0), 1.2, 0.9, 2.5)
F_BOUNCE = Lamp("wet deck bounce (fill)", np.array([12.5, 0.1, -3.0]), (0.55, 0.75, 0.85), 0.35, 4.0, 0.0)
LAMPS = (F_DOOR, F_L0, F_L1, F_L2, F_ALC, F_BOUNCE)

AMBIENT = np.array([0.06, 0.095, 0.12])
WRAP = 0.06


def shade(P, Nrm, lamps=LAMPS):
    out = np.broadcast_to(AMBIENT, P.shape).copy()
    for lp in lamps:
        L = lp.pos - P
        dist = np.linalg.norm(L, axis=-1, keepdims=True)
        Ln = L / np.maximum(dist, 1e-6)
        ndl = np.clip((Ln * Nrm).sum(-1, keepdims=True), 0, 1)
        ndl = np.where(ndl > 0, WRAP + (1 - WRAP) * ndl, 0.0)
        fall = 1.0 / (1.0 + (dist / lp.reach) ** 2)
        if lp.down > 0:
            below = np.clip((Ln[..., 1:2] + 0.35) / 1.35, 0, 1)  # the lamp is above the point
            fall = fall * (0.04 + 0.96 * below ** lp.down)
        out = out + lp.intensity * ndl * fall * lp.color
    return out


# ---- materials (linear albedo) ----------------------------------------------------------------------
CONCRETE = (0.205, 0.21, 0.225)  # 36231-like structural grey, matte cast
CONCRETE_CUT = (0.15, 0.152, 0.16)  # broken concrete (spall faces, rubble)
CONCRETE_DK = (0.10, 0.105, 0.115)
STEEL = (0.36, 0.37, 0.39)
STEEL_WORN = (0.55, 0.56, 0.58)
GUNSHIP = (0.18, 0.195, 0.235)  # 36118 doors, frames
HOUSING = (0.15, 0.155, 0.175)  # 36081 housings, conduit boxes
DARK = (0.05, 0.055, 0.06)
REBAR = (0.09, 0.075, 0.065)
SOOT = (0.03, 0.03, 0.032)
PIPE = (0.20, 0.21, 0.22)  # painted pipe (the charge line), matches the valve's dark steel


class Part:
    def __init__(self, layer, name, polys, albedo, plane=None, dims="", job="", lit=True, emit=None, mod=None, clip=None):
        self.layer, self.name, self.polys, self.albedo, self.plane = layer, name, polys, np.asarray(albedo, float), plane
        self.dims, self.job, self.lit, self.emit, self.mod, self.clip = dims, job, lit, emit, mod, clip


def render(parts, canvas=CV):
    """Flat-shaded construction render: per layer linear colour, alpha and one mask per part, in
    painter's order (later parts over earlier)."""
    out = {}
    A, B = rays(canvas)
    for p in parts:
        m = mask_of(p.polys, canvas)
        if p.clip is not None:
            m = m * p.clip
        lay = out.setdefault(p.layer, {"lin": np.zeros((canvas.h, canvas.w, 3)), "a": np.zeros((canvas.h, canvas.w)), "masks": {}})
        ys, xs = np.nonzero(m > 0)
        if len(ys):
            y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
            mm = m[y0:y1, x0:x1]
            if p.emit is not None:
                col = np.broadcast_to(np.array(p.emit, float), mm.shape + (3,))
            else:
                pl = p.plane if p.plane is not None else front_plane(0.0)
                Pp, la, lb = pl.points(A, B[y0:y1, x0:x1])
                col = p.albedo * shade(Pp, pl.n)
                if p.mod is not None:
                    f = p.mod(Pp, la, lb)
                    col = col * (f[..., None] if isinstance(f, np.ndarray) else f)
            sl = lay["lin"][y0:y1, x0:x1]
            lay["lin"][y0:y1, x0:x1] = sl * (1 - mm[..., None]) + col * mm[..., None]
            lay["a"][y0:y1, x0:x1] = mm + lay["a"][y0:y1, x0:x1] * (1 - mm)
        if p.name in lay["masks"]:
            lay["masks"][p.name] = np.clip(lay["masks"][p.name] + m, 0, 1)
        else:
            lay["masks"][p.name] = m
    return out


def to_srgb_u8(lin):
    lin = np.clip(lin, 0, 1)
    return (np.where(lin <= 0.0031308, lin * 12.92, 1.055 * np.power(lin, 1 / 2.4) - 0.055) * 255 + 0.5).astype(np.uint8)


def save_rgba(lin, a, path):
    Image.fromarray(np.dstack([to_srgb_u8(lin), (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)]), "RGBA").save(path)


def save_mask(m, path):
    Image.fromarray((np.clip(m, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(path)


def write_json(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=1)
