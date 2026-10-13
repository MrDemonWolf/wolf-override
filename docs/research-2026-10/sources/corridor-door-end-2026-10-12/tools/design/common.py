"""Shared geometry, camera and light for the corridor door-end design (scratch only).

World units are game world px at the corridor's right camera clamp (camera x 604.444, zoom 1.35):
the floor at the walkway is y 440 and 1 m = 40 px at walkway depth. The far plate is drawn with a
0.9 parallax; at the clamp it sits 12.444 px right of where the room places it, so a far-plate
source pixel is sx = 2 * (X - 12.444), sy = 2 * (Y - 78.5).

Camera (measured from the far plate's floor joints): vanishing point at clamp-world (483.9, 158.5),
the walkway at depth D0 = 38 m from the eye, eye height 7.04 m. A point d metres behind the walkway
scales by s = D0 / (D0 + d) about the vanishing point.
"""
from __future__ import annotations

import json
import math
from dataclasses import dataclass, field

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

PX_PER_M = 40.0
FLOOR_Y = 440.0
VPX = 483.9
HORIZON = 158.5
D0 = 38.0
FAR_SHIFT = 12.444  # far-plate parallax offset at the camera's right clamp
SS = 4  # supersampling for masks


def depth_scale(d: float) -> float:
    return D0 / (D0 + d)


def project(x_walk: float, h_m: float, d_m: float) -> tuple[float, float]:
    """x_walk: the point's x as it would appear at walkway depth (world px); h_m height above the
    floor in metres; d_m metres behind the walkway (negative = nearer the camera)."""
    s = depth_scale(d_m)
    X = VPX + (x_walk - VPX) * s
    Y = HORIZON + (FLOOR_Y - HORIZON) * s - h_m * PX_PER_M * s
    return X, Y


def floor_y(d_m: float) -> float:
    return project(VPX, 0.0, d_m)[1]


def depth_at_floor_y(Y: float) -> float:
    s = (Y - HORIZON) / (FLOOR_Y - HORIZON)
    return D0 / s - D0


def x_walk_from_screen(X: float, d_m: float) -> float:
    s = depth_scale(d_m)
    return VPX + (X - VPX) / s


@dataclass
class Canvas:
    """Maps world (clamp) coordinates to canvas pixels: px = (X - x0) * ppw."""
    name: str
    x0: float
    y0: float
    ppw: float
    w: int
    h: int

    def px(self, X: float, Y: float) -> tuple[float, float]:
        return ((X - self.x0) * self.ppw, (Y - self.y0) * self.ppw)

    def world(self, px: float, py: float) -> tuple[float, float]:
        return (self.x0 + px / self.ppw, self.y0 + py / self.ppw)

    def grid(self) -> tuple[np.ndarray, np.ndarray]:
        ys, xs = np.mgrid[0:self.h, 0:self.w].astype(np.float64)
        return self.x0 + (xs + 0.5) / self.ppw, self.y0 + (ys + 0.5) / self.ppw


@dataclass
class Part:
    name: str
    polys: list  # list of polygons, each a list of (X, Y) world points; or ("ellipse", cx, cy, rx, ry)
    albedo: tuple
    surface: dict  # {"kind": "front"|"floor"|"side"|"top"|"cyl"|"emit"|"keep", ...}
    lit_by: tuple = ()
    job: str = ""
    dims: str = ""
    note: str = ""
    z: int = 0
    emit: tuple = (0.0, 0.0, 0.0)
    texture: str = ""  # optional procedural detail: "slats", "grating", "seams"
    params: dict = field(default_factory=dict)


def draw_mask(canvas: Canvas, polys: list, soft: bool = True) -> np.ndarray:
    """Returns a float mask 0..1 at canvas resolution (anti-aliased by supersampling)."""
    big = Image.new("L", (canvas.w * SS, canvas.h * SS), 0)
    dr = ImageDraw.Draw(big)
    for poly in polys:
        if isinstance(poly, tuple) and poly and poly[0] == "ellipse":
            _, cx, cy, rx, ry = poly
            a = canvas.px(cx - rx, cy - ry)
            b = canvas.px(cx + rx, cy + ry)
            dr.ellipse([a[0] * SS, a[1] * SS, b[0] * SS, b[1] * SS], fill=255)
        elif isinstance(poly, tuple) and poly and poly[0] == "ring":
            _, cx, cy, r_out, r_in = poly
            a = canvas.px(cx - r_out, cy - r_out)
            b = canvas.px(cx + r_out, cy + r_out)
            dr.ellipse([a[0] * SS, a[1] * SS, b[0] * SS, b[1] * SS], fill=255)
            a = canvas.px(cx - r_in, cy - r_in)
            b = canvas.px(cx + r_in, cy + r_in)
            dr.ellipse([a[0] * SS, a[1] * SS, b[0] * SS, b[1] * SS], fill=0)
        elif isinstance(poly, tuple) and poly and poly[0] == "line":
            _, pts, width = poly
            q = [tuple(v * SS for v in canvas.px(*p)) for p in pts]
            dr.line(q, fill=255, width=max(1, int(round(width * canvas.ppw * SS))))
        else:
            q = [tuple(v * SS for v in canvas.px(*p)) for p in poly]
            dr.polygon(q, fill=255)
    if soft:
        small = big.resize((canvas.w, canvas.h), Image.Resampling.BOX)
    else:
        small = big.resize((canvas.w, canvas.h), Image.Resampling.NEAREST)
    return np.asarray(small, dtype=np.float64) / 255.0


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


# ----------------------------------------------------------------------------- light

@dataclass
class Fixture:
    name: str
    screen: tuple  # (X, Y) of the lamp centre on screen at the clamp
    d: float  # metres behind the walkway
    color: tuple
    intensity: float
    reach: float  # metres
    down: float = 0.0  # >0: a downlight, its output weighted by (cos of the angle below horizontal)^down

    def pos3(self):
        s = depth_scale(self.d)
        xw = VPX + (self.screen[0] - VPX) / s
        h = (HORIZON + (FLOOR_Y - HORIZON) * s - self.screen[1]) / (PX_PER_M * s)
        return np.array([xw / PX_PER_M, h, -self.d])


AMBIENT = np.array([0.085, 0.125, 0.15])
WRAP = 0.06


def surface_points(canvas: Canvas, surf: dict):
    """3D points (metres: x, h, z=-d) and normals for every canvas pixel of a surface."""
    X, Y = canvas.grid()
    kind = surf["kind"]
    if kind in ("front", "emit", "keep"):
        d = surf.get("d", 0.0)
        s = depth_scale(d)
        xw = VPX + (X - VPX) / s
        h = (HORIZON + (FLOOR_Y - HORIZON) * s - Y) / (PX_PER_M * s)
        P = np.stack([xw / PX_PER_M, h, np.full_like(X, -d)], -1)
        N = np.zeros_like(P)
        N[..., 2] = 1.0
        return P, N
    if kind == "floor" or kind == "top":
        hh = surf.get("h", 0.0)
        # On a horizontal plane at height hh: Y = HORIZON + (FLOOR_Y-HORIZON-hh*40)*s
        k = FLOOR_Y - HORIZON - hh * PX_PER_M
        s = np.clip((Y - HORIZON) / k, 0.05, 5.0)
        d = D0 / s - D0
        xw = VPX + (X - VPX) / s
        P = np.stack([xw / PX_PER_M, np.full_like(X, hh), -d], -1)
        N = np.zeros_like(P)
        N[..., 1] = 1.0
        return P, N
    if kind == "side":
        xw0 = surf["xw"]  # the plane x (as at walkway depth, world px)
        s = np.clip((X - VPX) / (xw0 - VPX), 0.05, 5.0)
        d = D0 / s - D0
        h = (HORIZON + (FLOOR_Y - HORIZON) * s - Y) / (PX_PER_M * s)
        P = np.stack([np.full_like(X, xw0 / PX_PER_M), h, -d], -1)
        N = np.zeros_like(P)
        N[..., 0] = surf.get("nx", -1.0)
        return P, N
    if kind == "cyl":
        cx, r, d = surf.get("cx", 0.0), surf["r"], surf.get("d", 0.0)
        s = depth_scale(d)
        xw = VPX + (X - VPX) / s
        h = (HORIZON + (FLOOR_Y - HORIZON) * s - Y) / (PX_PER_M * s)
        t = np.clip((X - cx) / max(r, 1e-6), -1, 1)
        if surf.get("axis", "v") == "h":
            # horizontal cylinder (pipe along x): normal varies with Y
            cy = surf["cy"]
            t = np.clip((Y - cy) / max(r, 1e-6), -1, 1)
            N = np.stack([np.zeros_like(t), -t, np.sqrt(1 - t * t)], -1)
        else:
            N = np.stack([t, np.zeros_like(t), np.sqrt(1 - t * t)], -1)
        P = np.stack([xw / PX_PER_M, h, np.full_like(X, -d)], -1)
        return P, N
    raise ValueError(kind)


def light(canvas: Canvas, surf: dict, fixtures: list) -> np.ndarray:
    P, N = surface_points(canvas, surf)
    out = np.broadcast_to(AMBIENT, P.shape).copy()
    out *= surf.get("ao", 1.0)
    for f in fixtures:
        F = f.pos3()
        L = F - P
        dist = np.linalg.norm(L, axis=-1, keepdims=True)
        Ln = L / np.maximum(dist, 1e-6)
        ndl = np.clip((N * Ln).sum(-1, keepdims=True), 0, 1)
        # soft wrap so grazing faces are not black
        ndl = WRAP + (1 - WRAP) * ndl
        fall = 1.0 / (1.0 + (dist / f.reach) ** 2)
        if f.down > 0:
            below = np.clip(Ln[..., 1:2], 0, 1)  # the lamp is above the point
            fall = fall * (0.08 + 0.92 * below ** f.down)
        out += f.intensity * ndl * fall * np.array(f.color)
    return out


def to_srgb_u8(lin: np.ndarray) -> np.ndarray:
    lin = np.clip(lin, 0, 1)
    return (np.where(lin <= 0.0031308, lin * 12.92, 1.055 * np.power(lin, 1 / 2.4) - 0.055) * 255 + 0.5).astype(np.uint8)


def from_srgb_u8(u8: np.ndarray) -> np.ndarray:
    c = u8.astype(np.float64) / 255.0
    return np.where(c <= 0.04045, c / 12.92, np.power((c + 0.055) / 1.055, 2.4))


def save_mask(arr: np.ndarray, path: str) -> None:
    Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(path)


def write_json(path: str, data) -> None:
    with open(path, "w") as f:
        json.dump(data, f, indent=1)
