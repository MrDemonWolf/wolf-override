"""Crank pose rig (add7 fix round 1, item f), deterministic: the two crank frames are built FROM THE
SPRITE THE GAME DRAWS (assets/rowan-side-right-provisional.png, 256x384, drawn at 0.188), so the
proportions, trousers, face, hair and light are that drawing's own pixels.

Geometry (sprite px; the game draws the sprite centred at the engineer's position + (0, -5)):
  hub of the MANUAL BYPASS wheel   (234.4, 165.4)   world (694, 400) with the engineer at x 674
  rim radius (tube centre line)    49.9             world 9.375 px
Cut into rigid parts by hand-measured polygons: legs (kept exactly), torso+head (leaned toward the
wheel about the belt), the near arm (image left: the engineer's right arm, nearer the camera in this
3/4 view) and the far arm (image right), each arm as an upper arm and a forearm+glove, solved with
two-bone IK so each glove centroid lands on its rim point:
  A (regrip)  lean 6 deg;  far glove at  8 o'clock (240 deg),  near glove at 10 o'clock (300 deg)
  B (push)    lean 9 deg;  both turned one tick (45 deg) with the rim: 285 and 345 deg
Writes crank/rig/: frame-A.png, frame-B.png (384x384, the sprite at x + 64), masks per part and a
guide (rig + the rim drawn as a cyan line) for the painter, and rig.json.
"""
from __future__ import annotations

import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "rig"))
SRC = "scratchpad/real-slice/game-add/apps/game/assets/rowan-side-right-provisional.png"
PAD = 64
SCALE = 0.188
HUB = (128.0 + 20.0 / SCALE, 192.0 + (400.0 - 405.0) / SCALE)   # (234.38, 165.40)
RIM = 9.375 / SCALE                                               # 49.87
PIVOT = (140.0, 168.0)   # belt centre: the torso leans about it
HIP_ROW = 160            # the legs layer keeps the original from this row down (the torso covers the seam)

# hand-measured polygons on the 256x384 sprite (see rig-upper-5x.png)
NEAR_ARM = [(56, 92), (66, 80), (80, 70), (96, 66), (104, 74), (105, 96), (103, 120), (101, 142), (99, 160), (93, 176), (93, 224), (84, 227), (66, 225), (62, 200), (60, 176), (56, 160), (52, 140)]
NEAR_ELBOW_CUT = 142     # rows above: upper arm; below: forearm + glove
NEAR_SHOULDER = (88.0, 82.0)
NEAR_ELBOW = (80.0, 142.0)
FAR_ARM = [(166, 96), (176, 96), (184, 110), (188, 130), (190, 160), (190, 178), (197, 196), (198, 222), (190, 231), (179, 231), (176, 214), (175, 196), (173, 184), (169, 176), (166, 150), (166, 130)]
FAR_ELBOW_CUT = 148
FAR_SHOULDER = (172.0, 100.0)
FAR_ELBOW = (182.0, 148.0)

FRAMES = {"A": {"lean": 6.0, "far": 240.0, "near": 300.0}, "B": {"lean": 9.0, "far": 285.0, "near": 345.0}}


def poly_mask(poly, shape):
    im = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(im).polygon(poly, fill=255)
    return np.asarray(im) > 0


def rim_point(clock_deg):
    c = math.radians(clock_deg)
    return (HUB[0] + RIM * math.sin(c), HUB[1] - RIM * math.cos(c))


def rot(p, c, deg):
    """Rotate p about c by deg clockwise on screen (y down)."""
    t = math.radians(deg)
    dx, dy = p[0] - c[0], p[1] - c[1]
    return (c[0] + dx * math.cos(t) - dy * math.sin(t), c[1] + dx * math.sin(t) + dy * math.cos(t))


def affine_paste(dst, src, mask, M):
    """Paste src (RGBA float, masked) into dst through the 2x3 affine M (dst = M @ src). Bicubic,
    premultiplied, then composited over dst."""
    H, W = dst.shape[:2]
    A = np.array([[M[0][0], M[0][1]], [M[1][0], M[1][1]]])
    b = np.array([M[0][2], M[1][2]])
    Ai = np.linalg.inv(A)
    inv = np.concatenate([Ai, (-Ai @ b)[:, None]], 1)
    s = src.copy()
    s[..., 3] *= mask
    pm = s.copy()
    pm[..., :3] *= pm[..., 3:4]
    im = Image.fromarray((np.clip(pm, 0, 1) * 255).round().astype(np.uint8), "RGBA")
    t = im.transform((W, H), Image.Transform.AFFINE, data=tuple(inv.ravel()), resample=Image.Resampling.BICUBIC)
    t = np.asarray(t).astype(float) / 255.0
    a = t[..., 3:4]
    rgb = np.where(a > 1e-4, t[..., :3] / np.maximum(a, 1e-4), 0)
    dst[..., :3] = rgb * a + dst[..., :3] * (1 - a)
    dst[..., 3:4] = a + dst[..., 3:4] * (1 - a)
    return t[..., 3]


def rigid(deg, c_from, c_to):
    """Affine: rotate by deg (clockwise) about c_from, then move c_from to c_to."""
    t = math.radians(deg)
    ca, sa = math.cos(t), math.sin(t)
    return [[ca, -sa, c_to[0] - (ca * c_from[0] - sa * c_from[1])], [sa, ca, c_to[1] - (sa * c_from[0] + ca * c_from[1])]]


def angle(v):
    return math.degrees(math.atan2(v[1], v[0]))


def ik(S, T, a, b, bend):
    """Elbow for upper length a, lower b, shoulder S, target T; bend = +1/-1 picks the side."""
    dx, dy = T[0] - S[0], T[1] - S[1]
    d = min(math.hypot(dx, dy), a + b - 1e-3)
    base = math.atan2(dy, dx)
    cosA = (a * a + d * d - b * b) / (2 * a * d)
    A_ = math.acos(max(-1, min(1, cosA)))
    ang = base + bend * A_
    return (S[0] + a * math.cos(ang), S[1] + a * math.sin(ang))


def glove_centroid(img, region):
    x0, y0, x1, y1 = region
    a = img[y0:y1, x0:x1]
    lum = (a[..., :3] * np.array([0.2126, 0.7152, 0.0722])).sum(-1)
    sat = a[..., :3].max(-1) - a[..., :3].min(-1)
    m = (a[..., 3] > 0.8) & (lum < 0.22) & (sat < 0.12)
    ys, xs = np.nonzero(m)
    return (x0 + xs.mean() + 0.5, y0 + ys.mean() + 0.5)


def main():
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    src = np.asarray(Image.open(SRC).convert("RGBA")).astype(float) / 255.0
    H, W = src.shape[:2]
    near = poly_mask(NEAR_ARM, (H, W)) & (src[..., 3] > 0)
    far = poly_mask(FAR_ARM, (H, W)) & (src[..., 3] > 0)
    rows = np.arange(H)[:, None]
    near_up, near_lo = near & (rows < NEAR_ELBOW_CUT), near & (rows >= NEAR_ELBOW_CUT)
    far_up, far_lo = far & (rows < FAR_ELBOW_CUT), far & (rows >= FAR_ELBOW_CUT)
    body = (src[..., 3] > 0) & ~near & ~far
    legs = body & (rows >= HIP_ROW)
    torso = body & (rows < 178)
    # the gloves' own centroids in the sprite (dark neutral opaque pixels in each hand box)
    g_near = glove_centroid(src, (60, 184, 102, 234))
    g_far = glove_centroid(src, (168, 184, 202, 234))
    rep = {"hub": HUB, "rim": RIM, "glove_near_src": g_near, "glove_far_src": g_far, "frames": {}}
    for key, f in FRAMES.items():
        canvas = np.zeros((H, W + 2 * PAD, 4))
        P = (PIVOT[0] + PAD, PIVOT[1])
        sh = lambda p: (p[0] + PAD, p[1])  # noqa: E731
        hub = sh(HUB)
        part_alpha = {}
        # the far arm behind the torso, then legs, torso, then the near arm in front
        # far arm: shoulder leans with the torso; two-bone IK to its rim point
        S_far = rot(sh(FAR_SHOULDER), P, f["lean"])
        T_far = sh(rim_point(f["far"]))
        a_far = math.dist(FAR_SHOULDER, FAR_ELBOW)
        b_far = math.dist(FAR_ELBOW, g_far)
        E_far = ik(S_far, T_far, a_far, b_far, 1)
        up_deg = angle((E_far[0] - S_far[0], E_far[1] - S_far[1])) - angle((FAR_ELBOW[0] - FAR_SHOULDER[0], FAR_ELBOW[1] - FAR_SHOULDER[1]))
        lo_deg = angle((T_far[0] - E_far[0], T_far[1] - E_far[1])) - angle((g_far[0] - FAR_ELBOW[0], g_far[1] - FAR_ELBOW[1]))
        srcp = np.zeros_like(canvas)
        srcp[:, PAD:PAD + W] = src
        pad = lambda m: np.pad(m, ((0, 0), (PAD, PAD))).astype(float)  # noqa: E731
        part_alpha["far_upper"] = affine_paste(canvas, srcp, pad(far_up), rigid(up_deg, sh(FAR_SHOULDER), S_far))
        part_alpha["far_lower"] = affine_paste(canvas, srcp, pad(far_lo), rigid(lo_deg, sh(FAR_ELBOW), E_far))
        part_alpha["legs"] = affine_paste(canvas, srcp, pad(legs), rigid(0.0, (0, 0), (0, 0)))
        part_alpha["torso"] = affine_paste(canvas, srcp, pad(torso), rigid(f["lean"], P, P))
        S_near = rot(sh(NEAR_SHOULDER), P, f["lean"])
        T_near = sh(rim_point(f["near"]))
        a_n = math.dist(NEAR_SHOULDER, NEAR_ELBOW)
        b_n = math.dist(NEAR_ELBOW, g_near)
        E_near = ik(S_near, T_near, a_n, b_n, 1)
        up_n = angle((E_near[0] - S_near[0], E_near[1] - S_near[1])) - angle((NEAR_ELBOW[0] - NEAR_SHOULDER[0], NEAR_ELBOW[1] - NEAR_SHOULDER[1]))
        lo_n = angle((T_near[0] - E_near[0], T_near[1] - E_near[1])) - angle((g_near[0] - NEAR_ELBOW[0], g_near[1] - NEAR_ELBOW[1]))
        part_alpha["near_upper"] = affine_paste(canvas, srcp, pad(near_up), rigid(up_n, sh(NEAR_SHOULDER), S_near))
        part_alpha["near_lower"] = affine_paste(canvas, srcp, pad(near_lo), rigid(lo_n, sh(NEAR_ELBOW), E_near))
        Image.fromarray((np.clip(canvas, 0, 1) * 255).round().astype(np.uint8), "RGBA").save(os.path.join(OUT, f"frame-{key}.png"))
        for n, a in part_alpha.items():
            Image.fromarray((np.clip(a, 0, 1) * 255).round().astype(np.uint8), "L").save(os.path.join(OUT, "masks", f"{key}-{n}.png"))
        # joints the painter must repair: shoulders, elbows, the hip seam, where the hands left the legs
        rep["frames"][key] = {"lean": f["lean"], "far_target": T_far, "near_target": T_near, "far_shoulder": S_far, "far_elbow": E_far, "near_shoulder": S_near,
                              "near_elbow": E_near, "far_upper_deg": round(up_deg, 2), "far_lower_deg": round(lo_deg, 2), "near_upper_deg": round(up_n, 2), "near_lower_deg": round(lo_n, 2)}
    json.dump(rep, open(os.path.join(OUT, "rig.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1, default=lambda v: [round(x, 2) for x in v]))


if __name__ == "__main__":
    main()
