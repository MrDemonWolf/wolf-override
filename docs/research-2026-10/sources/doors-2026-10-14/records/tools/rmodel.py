"""Records Access doors (doors-r1, records track): the measured model shared by every design tool.

Scratch only. The camera is the one the corridor door end measured (corridor-door-end-2026-10-12,
tools/design/common.py): every room uses the same game camera (floor y 440 at the walkway, 1 m = 40
world px there), vanishing point (483.9, 158.5), walkway 38 m from the eye, eye height 7.04 m. The
Records far plate's own floor joints are AI-painted and inconsistent (one runs to x about 438), so
the game camera rules; the back wall's floor line (y 411.5) puts the Records back wall 4.3 m behind
the walkway.

Coordinates: metres. X along the room (world x / 40 at walkway depth), H up, D behind the walkway
(D < 0 is nearer the camera). project() maps them to world px at scroll 1.0 (the mid plate's frame).

A door end is a cross-wall standing across the walkway, its approach face turned 17 degrees toward
the camera (the corridor's design language: its horizontals run to VP2 on the horizon at x 21 for a
wall closing the room's right end, and at x 946.8 for one closing its left end). side = +1 for the
right end (the exit to the service line), -1 for the left end (the way in from the corridor).
"""
from __future__ import annotations

import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw

PX_PER_M = 40.0
FLOOR_Y = 440.0
VPX = 483.9
HORIZON = 158.5
D0 = 38.0
SS = 4
VP2_OFFSET = VPX - 21.0  # the corridor's VP2 for a 17-degree turn

TOOLS = os.path.dirname(os.path.abspath(__file__))
TRACK = os.path.dirname(TOOLS)
DESIGN = os.path.join(TRACK, "design")


def depth_scale(d):
    return D0 / (D0 + d)


def project(x_walk_px, h_m, d_m):
    s = depth_scale(d_m)
    return VPX + (x_walk_px - VPX) * s, HORIZON + (FLOOR_Y - HORIZON) * s - h_m * PX_PER_M * s


def scr(P):
    return project(P[0] * PX_PER_M, P[1], P[2])


def floor_y(d):
    return project(VPX, 0.0, d)[1]


def from_screen(X, Y, d):
    s = depth_scale(d)
    xw = VPX + (X - VPX) / s
    h = (HORIZON + (FLOOR_Y - HORIZON) * s - Y) / (PX_PER_M * s)
    return np.array([xw / PX_PER_M, h, d])


class Canvas:
    """World px -> canvas px: ((X - x0) * ppw, (Y - y0) * ppw)."""

    def __init__(self, name, x0, y0, ppw, w, h):
        self.name, self.x0, self.y0, self.ppw, self.w, self.h = name, x0, y0, ppw, w, h

    def px(self, X, Y):
        return ((X - self.x0) * self.ppw, (Y - self.y0) * self.ppw)

    def grid(self):
        ys, xs = np.mgrid[0:self.h, 0:self.w].astype(np.float64)
        return self.x0 + (xs + 0.5) / self.ppw, self.y0 + (ys + 0.5) / self.ppw

    def rays(self):
        X, Y = self.grid()
        A = np.array([VPX / PX_PER_M, (FLOOR_Y - HORIZON) / PX_PER_M, -D0])
        B = np.stack([(X - VPX) / PX_PER_M, (HORIZON - Y) / PX_PER_M, np.full_like(X, D0)], -1)
        return A, B


EY = np.array([0.0, 1.0, 0.0])


class Plane:
    def __init__(self, origin, e1, e2, normal):
        self.o = np.asarray(origin, float)
        self.e1 = np.asarray(e1, float)
        self.e2 = np.asarray(e2, float)
        self.n = np.asarray(normal, float) / np.linalg.norm(normal)

    def points(self, canvas):
        A, B = canvas.rays()
        nb = (B * self.n).sum(-1)
        tt = ((self.o - A) * self.n).sum() / np.where(np.abs(nb) < 1e-9, 1e-9, nb)
        P = A + B * tt[..., None]
        rel = P - self.o
        return P, (rel * self.e1).sum(-1), (rel * self.e2).sum(-1)


def front_plane(d):
    return Plane(np.array([0, 0, d]), np.array([1.0, 0, 0]), EY, np.array([0, 0, -1.0]))


def mask_of(polys, canvas):
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
        else:
            q = [tuple(v * SS for v in canvas.px(*xy)) for xy in p]
            dr.polygon(q, fill=255)
    return np.asarray(big.resize((canvas.w, canvas.h), Image.Resampling.BOX), dtype=np.float64) / 255.0


# ----------------------------------------------------------------------------- materials (linear)
CONCRETE = (0.205, 0.21, 0.225)  # 36231-like structural grey, matte cast (as the corridor)
CONCRETE_DK = (0.10, 0.105, 0.115)
STEEL = (0.36, 0.37, 0.39)  # bare / galvanised steel
STEEL_WORN = (0.55, 0.56, 0.58)
GUNSHIP = (0.18, 0.195, 0.235)  # 36118 Gunship Gray: doors, frames
HOUSING = (0.15, 0.155, 0.175)  # 36081: housings, conduit boxes
DARK = (0.05, 0.055, 0.06)
RUBBER = (0.025, 0.025, 0.028)
CONTAINER_GRAY = (0.33, 0.335, 0.35)  # GSA container "Gray" (lighter than the doors)
FITTING_LENS = (0.62, 0.66, 0.68)


# ----------------------------------------------------------------------------- light
class Lamp:
    def __init__(self, name, pos, color, intensity, reach, down=0.0):
        self.name, self.pos, self.color = name, np.asarray(pos, float), np.asarray(color, float)
        self.intensity, self.reach, self.down = intensity, reach, down


AMBIENT = np.array([0.020, 0.032, 0.042])
WRAP = 0.06


def shade(P, Nrm, lamps, ambient=AMBIENT):
    out = np.broadcast_to(ambient, P.shape).copy()
    for lp in lamps:
        L = lp.pos - P
        dist = np.linalg.norm(L, axis=-1, keepdims=True)
        Ln = L / np.maximum(dist, 1e-6)
        ndl = np.clip((Ln * Nrm).sum(-1, keepdims=True), 0, 1)
        ndl = np.where(ndl > 0, WRAP + (1 - WRAP) * ndl, 0.0)
        fall = 1.0 / (1.0 + (dist / lp.reach) ** 2)
        if lp.down > 0:
            below = np.clip((Ln[..., 1:2] + 0.35) / 1.35, 0, 1)
            fall = fall * (0.04 + 0.96 * below ** lp.down)
        out = out + lp.intensity * ndl * fall * lp.color
    return out


def to_srgb_u8(lin):
    lin = np.clip(lin, 0, 1)
    return (np.where(lin <= 0.0031308, lin * 12.92, 1.055 * np.power(lin, 1 / 2.4) - 0.055) * 255 + 0.5).astype(np.uint8)


def from_srgb_u8(u8):
    c = u8.astype(np.float64) / 255.0
    return np.where(c <= 0.04045, c / 12.92, np.power((c + 0.055) / 1.055, 2.4))


def save_mask(arr, path):
    Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(path)


def write_json(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=1)


class Part:
    def __init__(self, layer, name, polys, albedo, plane=None, dims="", job="", texture=None, emit=None, clip=None, lamps=None, clipfn=None):
        self.layer, self.name, self.polys, self.albedo, self.plane = layer, name, polys, np.asarray(albedo, float), plane
        self.dims, self.job, self.texture, self.emit, self.clip, self.lamps = dims, job, texture, emit, clip, lamps
        self.clipfn = clipfn  # per-pixel 0..1 from the part's 3D points (e.g. only what lies beyond a wall)


def render(parts, canvas, lamps):
    H, W = canvas.h, canvas.w
    out = {}
    for p in parts:
        m = mask_of(p.polys, canvas)
        if p.clip is not None:
            m = m * p.clip
        if p.emit is not None:
            col = np.broadcast_to(np.array(p.emit), (H, W, 3))
        else:
            pl = p.plane if p.plane is not None else front_plane(0.0)
            Pp, la, lb = pl.points(canvas)
            if p.clipfn is not None:
                m = m * p.clipfn(Pp)
            col = p.albedo * shade(Pp, pl.n, p.lamps if p.lamps is not None else lamps)
            if p.texture == "seam":  # a recessed joint: darker
                col = col * 0.55
        lay = out.setdefault(p.layer, {"lin": np.zeros((H, W, 3)), "a": np.zeros((H, W)), "masks": {}})
        lay["lin"] = lay["lin"] * (1 - m[..., None]) + col * m[..., None]
        lay["a"] = m + lay["a"] * (1 - m)
        lay["masks"][p.name] = m
    return out


# ----------------------------------------------------------------------------- a door end
class DoorEnd:
    """A cast-concrete cross-wall across the walkway, its approach face turned 17 degrees, with a
    1-3/4 in steel secure-area door (ICD 705 TS v1.4 ch. 3E) swinging into the Records room.

    a: metres along the approach face from the walk line, positive toward the room's back wall.
    t: metres into the wall from the approach face (the far side of the wall is t = T_WALL).
    """

    T_WALL = 0.30  # 300 mm cast reinforced concrete
    LEAF_W = 0.914  # 3'0" leaf
    LEAF_H = 2.134  # 7'0" leaf
    LEAF_T = 0.044  # 1-3/4 in
    OPEN_W = 0.920  # frame opening: leaf + 3 mm clearance each side (1/8 in, ANSI/SDI A250.8)
    H_OPEN = 2.140
    FRAME_FACE = 0.051  # 2 in hollow-metal frame face
    HEADER_H = 0.120  # head with the concealed low-energy operator (ANSI/BHMA A156.19)
    A_N = -0.46  # near (latch) jamb, toward the camera
    A_F = 0.46  # far (hinge) jamb, behind the walk line
    A_END = A_N - 0.16  # the wall ends 0.16 m past the near jamb (the corridor's column rule)
    A_BACK = 4.30 / math.cos(math.radians(16.94))  # where the face meets the room's back wall (4.3 m)
    H_TOP = 7.8
    STUB_H = 0.15
    # SDI 129-24, 7'-0" opening, 4-1/2 in hinges: top hinge 9 in below the head, two spaces of 33 in
    HINGES = ((2.134 - 0.229 - 0.114, 2.134 - 0.229), (2.134 - 0.229 - 0.838 - 0.114, 2.134 - 0.229 - 0.838), (2.134 - 0.229 - 1.676 - 0.114, 2.134 - 0.229 - 1.676))
    LEVER_H = 1.062  # SDI 129-24 strike centreline 41-13/16 in
    LAMP_H = 2.45

    def __init__(self, side, x_cross):
        self.side = side
        self.xc = x_cross
        k = VP2_OFFSET / D0 / PX_PER_M
        u = np.array([-side * k, 0.0, 1.0])
        self.U = u / np.linalg.norm(u)
        self.N = np.array([side * self.U[2], 0.0, -side * self.U[0]])
        self.O = np.array([x_cross / PX_PER_M, 0.0, 0.0])
        self.hinge = self.pt(self.A_F, 0.0, -0.012)

    def pt(self, a, h, t=0.0):
        return self.O + a * self.U + h * EY + t * self.N

    def s(self, a, h, t=0.0):
        return scr(self.pt(a, h, t))

    def poly(self, pts):
        return [scr(np.asarray(p, float)) for p in pts]

    def quad_face(self, a0, a1, h0, h1, t=0.0):
        return self.poly([self.pt(a0, h0, t), self.pt(a1, h0, t), self.pt(a1, h1, t), self.pt(a0, h1, t)])

    def quad_side(self, a, t0, t1, h0, h1):
        return self.poly([self.pt(a, h0, t0), self.pt(a, h0, t1), self.pt(a, h1, t1), self.pt(a, h1, t0)])

    def quad_top(self, a0, a1, t0, t1, h):
        return self.poly([self.pt(a0, h, t0), self.pt(a1, h, t0), self.pt(a1, h, t1), self.pt(a0, h, t1)])

    def face_plane(self, t=0.0):
        return Plane(self.pt(0, 0, t), self.U, EY, -self.N)

    def side_plane(self, a):
        return Plane(self.pt(a, 0, 0), self.N, EY, -self.U)

    def top_plane(self, h):
        return Plane(np.array([0, h, 0.0]), self.U, self.N, EY)

    # the leaf: hinged on the far jamb, swinging into the room (toward -N)
    def leaf_dir(self, theta):
        return -self.U * math.cos(theta) - self.N * math.sin(theta)

    def leaf_normal_room(self, theta):
        """Normal of the leaf's room-side face (faces the room when shut)."""
        return -self.N * math.cos(theta) + self.U * math.sin(theta)

    def leaf_corners(self, theta, face="room"):
        """The leaf face's four corners (hinge-bottom, free-bottom, free-top, hinge-top) in 3D."""
        d = self.leaf_dir(theta)
        n_room = self.leaf_normal_room(theta)
        base = self.hinge.copy()
        if face == "out":
            base = base - n_room * self.LEAF_T
        h0, h1 = 0.010, 0.010 + self.LEAF_H
        return [base + EY * h0, base + d * self.LEAF_W + EY * h0, base + d * self.LEAF_W + EY * h1, base + EY * h1]

    def stub_far_a(self, x_limit):
        a = self.A_END
        while (self.side > 0 and self.s(a, 0.0, 0.0)[0] < x_limit) or (self.side < 0 and self.s(a, 0.0, 0.0)[0] > x_limit):
            a -= 0.05
        return a
