"""Fix round 4 (review r4, M1): a software copy of SwingLeaf (swing_leaf.gd), to fit the swing leaves' light
before closing it on render.sh frames. Scratch only.

It builds the leaf's mesh exactly as append_mesh() does (the face the camera sees, the latch edge; ROWS rows by
two columns), lights each vertex as shade() does, and rasterises the triangles affinely in screen space as the
2D canvas does: UV and vertex colour interpolated per triangle, the atlas sampled bilinearly, the vertex colour
multiplying the texel in sRGB. Output: linear luminance (Rec. 709) at the frame's size, and the face mask.

Two face choices: "parallel" (rounds 1-3: n_room.z < 0, a view straight along +d) and "camera" (round 4: the
face whose normal points back toward the room's real pinhole camera at (vpx / 40, *, -38) m).

Light: [position (m), colour * intensity, reach (m), down exponent, wrap, fill]. Round 3 multiplied every
light and the ambient by one exposure. Round 4: `exposure` sets the key lights (the door light and the ceiling
lamp) and `fill` sets the ambient and every light marked fill (the floor bounce), so a face the door light
misses keeps the room's fill (review r4 M1 cause 2)."""
from __future__ import annotations

import copy
import os

import numpy as np
from PIL import Image

D0, PX_PER_M, FLOOR_Y = 38.0, 40.0, 440.0
LEAF_W, LEAF_H, LEAF_T, LEAF_BOTTOM = 0.914, 2.134, 0.044, 0.010
ROWS = np.array([0.0, 0.2, 0.45, 0.7, 0.88, 1.0])
AMBIENT = np.array([0.020, 0.032, 0.042])
PAINT = np.array([0.18, 0.195, 0.235])
WRAP = 0.06
W709 = np.array([0.2126, 0.7152, 0.0722])
GAME = "doors-r1/game-doors/apps/game"
ATLAS = {"records": os.path.join(GAME, "assets/props/records-doors-atlas.png"),
         "jentry": os.path.join(GAME, "assets/props/junction-entry-atlas.png")}

# Round 3's shipped constants (records_room.gd, junction_room.gd), as the base the fit starts from.
LEAVES = {
    "records-exit": dict(atlas="records", hinge=(21.85451, 0.0, 0.43655), u=(-0.291329, 0.0, 0.956623), n=(0.956623, 0.0, 0.291329),
                         vpx=483.9, hor=158.5, room=(552, 2, 73, 171), out=(627, 2, 73, 171), edge=(777, 2, 5, 171), side=+1,
                         exposure=0.082, fill=None,
                         lights=[[(21.9043, 2.8, -0.0291), (47.44, 52.41, 55.17), 0.5, 2.0, 0.0, False],
                                 [(15.0056, 5.5765, 4.3), (0.648, 0.837, 0.9), 3.2, 1.5, WRAP, False],
                                 [(20.0, 0.1, -3.0), (0.165, 0.225, 0.255), 5.0, 0.0, WRAP, True]]),
    "records-entry": dict(atlas="records", hinge=(1.89549, 0.0, 0.43655), u=(0.291329, 0.0, 0.956623), n=(-0.956623, 0.0, 0.291329),
                          vpx=483.9, hor=158.5, room=(552, 2, 73, 171), out=(702, 2, 73, 171), edge=(777, 2, 5, 171), side=-1,
                          exposure=0.225, fill=None,
                          lights=[[(1.8457, 2.8, -0.0291), (11.94, 13.19, 13.88), 0.5, 2.0, 0.0, False],
                                  [(3.6013, 5.5765, 4.3), (0.648, 0.837, 0.9), 3.2, 1.5, WRAP, False],
                                  [(3.75, 0.1, -3.0), (0.165, 0.225, 0.255), 5.0, 0.0, WRAP, True]]),
    "junction-entry": dict(atlas="jentry", hinge=(0.89597, 0.0, 0.43639), u=(0.292372, 0.0, 0.956305), n=(-0.956305, 0.0, 0.292372),
                           vpx=511.0, hor=162.0, room=(374, 2, 73, 171), out=(449, 2, 73, 171), edge=(524, 2, 5, 171), side=-1,
                           exposure=0.147, fill=None,
                           lights=[[(0.8456, 2.8, -0.0292), (45.57, 50.33, 52.99), 0.5, 2.0, 0.0, False],
                                   [(1.9461, 5.237, 4.2), (0.682, 0.99, 1.1), 3.4, 1.5, WRAP, False],
                                   [(2.75, 0.1, -3.0), (0.055, 0.075, 0.085), 4.0, 0.0, WRAP, True]]),
}
_TEX: dict = {}


def leaf(name: str) -> dict:
    return copy.deepcopy(LEAVES[name])


def srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)


def lin(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.04045, c / 12.92, np.power((c + 0.055) / 1.055, 2.4))


def light_at(cfg: dict, p, nrm) -> np.ndarray:
    """PAINT x light x exposure, linear (shade() before its sRGB ratio)."""
    fill = cfg["exposure"] if cfg.get("fill") is None else cfg["fill"]
    out = AMBIENT * fill
    for pos, col, reach, down, wrap, is_fill in cfg["lights"]:
        to = np.array(pos) - p
        dist = np.linalg.norm(to)
        dr = to / max(dist, 1e-6)
        ndl = float(np.clip(dr @ nrm, 0.0, 1.0))
        if ndl <= 0.0:
            continue
        ndl = wrap + (1.0 - wrap) * ndl
        fall = 1.0 / (1.0 + (dist / reach) ** 2)
        if down > 0.0:
            below = float(np.clip((dr[1] + 0.35) / 1.35, 0.0, 1.0))
            fall *= 0.04 + 0.96 * below ** down
        out = out + np.array(col) * ndl * fall * (fill if is_fill else cfg["exposure"])
    return PAINT * out


def shade(cfg, p, nrm):
    return srgb(light_at(cfg, p, nrm)) / srgb(PAINT)


def project(cfg, p):
    s = D0 / (D0 + p[2])
    return np.array([cfg["vpx"] + (p[0] * PX_PER_M - cfg["vpx"]) * s, cfg["hor"] + (FLOOR_Y - cfg["hor"]) * s - p[1] * PX_PER_M * s])


def faces(cfg, opened: float, choice: str = "camera"):
    """The visible face's (base, across, region, normal, which) and the edge's, as append_mesh builds them."""
    h, u, n = (np.array(cfg[k], float) for k in ("hinge", "u", "n"))
    th = opened * np.pi * 0.5
    dirv = -u * np.cos(th) - n * np.sin(th)
    nroom = -n * np.cos(th) + u * np.sin(th)
    if choice == "parallel":
        room = nroom[2] < 0.0
    else:
        cam = np.array([cfg["vpx"] / PX_PER_M, 0.0, -D0])
        centre = h + dirv * (LEAF_W * 0.5)
        room = float(nroom @ (centre - cam)) < 0.0
    base = h if room else h - nroom * LEAF_T
    nrm = nroom if room else -nroom
    region = cfg["room"] if room else cfg["out"]
    return [(base, dirv * LEAF_W, region, nrm, "room" if room else "out"), (h + dirv * LEAF_W, -nroom * LEAF_T, cfg["edge"], dirv, "edge")]


def mesh(cfg, opened, choice="camera"):
    """Triangles: list of (3x2 world px, 3x2 atlas px, 3x3 vertex colour, tag)."""
    tris = []
    for base, across, region, nrm, tag in faces(cfg, opened, choice):
        rx, ry, rw, rh = region
        V = {}
        for c in (0, 1):
            for i, r in enumerate(ROWS):
                p = base + across * c + np.array([0.0, LEAF_BOTTOM + r * LEAF_H, 0.0])
                V[(c, i)] = (project(cfg, p), np.array([rx + c * rw, ry + (1.0 - r) * rh]), shade(cfg, p, nrm))
        for i in range(len(ROWS) - 1):
            a, b, a1, b1 = V[(0, i)], V[(1, i)], V[(0, i + 1)], V[(1, i + 1)]
            for t in ((a, b, a1), (a1, b, b1)):
                tris.append((np.array([v[0] for v in t]), np.array([v[1] for v in t]), np.array([v[2] for v in t]), tag))
    return tris


def texture(key):
    if key not in _TEX:
        _TEX[key] = np.asarray(Image.open(ATLAS[key]).convert("RGBA")).astype(np.float64) / 255.0
    return _TEX[key]


def sample(tex, uv):
    x = np.clip(uv[:, 0] - 0.5, 0, tex.shape[1] - 1.001)
    y = np.clip(uv[:, 1] - 0.5, 0, tex.shape[0] - 1.001)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = (x - x0)[:, None], (y - y0)[:, None]
    t = tex
    return (t[y0, x0] * (1 - fx) * (1 - fy) + t[y0, x0 + 1] * fx * (1 - fy) + t[y0 + 1, x0] * (1 - fx) * fy + t[y0 + 1, x0 + 1] * fx * fy)


def render(cfg, opened, canvas, size=(1280, 720), choice="camera"):
    """Linear luminance image of the leaf alone (NaN where it does not draw) and a tag image."""
    sc, tx, ty = canvas[0], canvas[4], canvas[5]
    k = size[0] / 960.0
    tex = texture(cfg["atlas"])
    lum = np.full((size[1], size[0]), np.nan)
    tag = np.zeros((size[1], size[0]), dtype="<U4")
    for P, UV, C, tg in mesh(cfg, opened, choice):
        S = np.stack([(P[:, 0] * sc + tx) * k, (P[:, 1] * sc + ty) * k], 1)
        x0, y0 = np.floor(S.min(0)).astype(int)
        x1, y1 = np.ceil(S.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, size[0] - 1), min(y1, size[1] - 1)
        if x1 < x0 or y1 < y0:
            continue
        ys, xs = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        px = np.stack([xs.ravel() + 0.5, ys.ravel() + 0.5], 1)
        (ax, ay), (bx, by), (cx, cy) = S
        det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(det) < 1e-9:
            continue
        l0 = ((by - cy) * (px[:, 0] - cx) + (cx - bx) * (px[:, 1] - cy)) / det
        l1 = ((cy - ay) * (px[:, 0] - cx) + (ax - cx) * (px[:, 1] - cy)) / det
        l2 = 1 - l0 - l1
        inside = (l0 >= -1e-6) & (l1 >= -1e-6) & (l2 >= -1e-6)
        if not inside.any():
            continue
        L = np.stack([l0, l1, l2], 1)[inside]
        uv = L @ UV
        col = L @ C
        texel = sample(tex, uv)
        rgb = texel[:, :3] * col
        a = texel[:, 3]
        val = (lin(rgb) * W709).sum(1)
        X, Y = px[inside, 0].astype(int), px[inside, 1].astype(int)
        keep = a > 0.5
        lum[Y[keep], X[keep]] = val[keep]
        tag[Y[keep], X[keep]] = tg
    return lum, tag
