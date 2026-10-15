"""Relief valve on the coolant relay's side pipe: exact construction (deterministic, no image tool).

All coordinates are in the relay art's own pixels (corridor-coolant-relay.png, 368x408, drawn at
0.25 scale, so 4 art px = 1 world px; the game's scale is about 42 world px per metre, so
1 art px is about 6 mm). The art's top-left sits at world (561.625, 338.0).

What it is (real practice, see NOTES.md): a spring-loaded safety relief valve standing upright
(spindle vertical) on a weld boss on the crown of the side pipe's upper elbow, so its inlet is as
short as possible with no elbows; a hex inlet nut; a cast bronze body with a side outlet to the
right; the spring bonnet, cap and test lever on top; then a short open tailpipe: a nipple with a
union, a 90-degree elbow, and a short drop that ends open, pointing DOWN to the floor, beside the
pipe and away from the engineer (who stands to the right, facing the wheel). A short tailpipe needs
no separate support (Kunkle IOM). The valve is ~240 mm tall, a 1-1/4" valve on an ~8" line.

Outputs (design/):
  parts.npz            per-part coverage masks at art resolution (float 0..1), plus 'all'
  construction.png     the relay with the flat-shaded construction composited (art resolution)
  construction-8x.png  crop x 260..368, y 40..140, 8x nearest, for review
  spec.json            the measurements and the outlet point in art, world and node coordinates
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GAME = "scratchpad/real-slice/game-slice/apps/game"
RELAY = os.path.join(GAME, "assets/props/corridor-coolant-relay.png")
OUT = os.path.join(ROOT, "design")
SS = 8  # supersamples per art px (each axis)
ART_ORIGIN_WORLD = (607.625 - 46.0, 389.0 - 51.0)
BYPASS_NODE_WORLD = (700.0, 398.0)

CX = 302.0  # valve spindle centreline
# Discharge pipe: OD 6.5 art px (~40 mm, 1-1/4" NPS is 42 mm)
D_OD = 6.5
D_Y = 71.75  # nipple centreline
BEND_R = 6.0  # centreline radius of the 90-degree elbow (long radius ~1.5 D)
BEND_X0 = 346.0  # where the nipple meets the elbow
TAIL_X = BEND_X0 + BEND_R  # 352: tail centreline
TAIL_END_Y = 92.0  # open end


def grid(w: int, h: int):
    ys = (np.arange(h * SS) + 0.5) / SS
    xs = (np.arange(w * SS) + 0.5) / SS
    return np.meshgrid(xs, ys)


def crown_y(relay_alpha: np.ndarray) -> np.ndarray:
    """Top edge of the side pipe per art column (first alpha >= 128), as a float array."""
    top = np.full(relay_alpha.shape[1], 9999.0)
    for x in range(relay_alpha.shape[1]):
        col = np.where(relay_alpha[:, x] >= 128)[0]
        if len(col):
            top[x] = col.min()
    return top


def rect(X, Y, x0, y0, x1, y1):
    return (X >= x0) & (X < x1) & (Y >= y0) & (Y < y1)


def rounded_rect(X, Y, x0, y0, x1, y1, r):
    m = rect(X, Y, x0, y0, x1, y1)
    for cx, cy in ((x0 + r, y0 + r), (x1 - r, y0 + r)):
        corner = ((X < x0 + r) if cx == x0 + r else (X >= x1 - r)) & (Y < y0 + r)
        m &= ~(corner & ((X - cx) ** 2 + (Y - cy) ** 2 > r * r))
    return m


def trapezoid(X, Y, xt0, xt1, yt, xb0, xb1, yb):
    t = np.clip((Y - yt) / (yb - yt), 0, 1)
    return (Y >= yt) & (Y < yb) & (X >= xt0 + (xb0 - xt0) * t) & (X < xt1 + (xb1 - xt1) * t)


def segment(X, Y, p0, p1, half_w):
    p0 = np.array(p0); p1 = np.array(p1)
    d = p1 - p0
    L2 = float(d @ d)
    t = np.clip(((X - p0[0]) * d[0] + (Y - p0[1]) * d[1]) / L2, 0, 1)
    px = p0[0] + t * d[0]; py = p0[1] + t * d[1]
    return (X - px) ** 2 + (Y - py) ** 2 <= half_w ** 2


def build():
    relay = np.array(Image.open(RELAY).convert("RGBA"))
    H, W = relay.shape[:2]
    X, Y = grid(W, H)
    top = crown_y(relay[..., 3])
    top_ss = np.interp(X[0], np.arange(W) + 0.5, top)  # per supersample column
    crown = np.broadcast_to(top_ss, X.shape)

    parts = {}
    # 1 weld boss (sockolet) on the elbow crown, with its fillet weld; it runs 1.5 px into the pipe
    boss = trapezoid(X, Y, CX - 5.0, CX + 5.0, 85.0, CX - 7.0, CX + 7.0, 93.5) & (Y < crown + 1.5)
    parts["boss"] = boss
    parts["weld"] = boss & (Y >= crown - 1.25)
    # 2 hex inlet nut (three faces seen)
    parts["hex"] = rect(X, Y, CX - 6.5, 78.5, CX + 6.5, 85.0)
    # 3 cast body with the side outlet boss
    parts["body"] = rounded_rect(X, Y, CX - 5.0, 65.5, CX + 5.0, 78.5, 2.5)
    parts["outlet"] = rect(X, Y, CX + 4.5, 67.5, CX + 11.0, 76.0)
    parts["outlet_hex"] = rect(X, Y, CX + 10.0, 67.0, CX + 12.5, 76.5)
    # 4 spring bonnet (slight taper), 5 cap, 6 test lever with its pivot
    parts["bonnet"] = trapezoid(X, Y, CX - 3.0, CX + 3.0, 56.5, CX - 3.75, CX + 3.75, 65.5)
    parts["cap"] = rounded_rect(X, Y, CX - 2.5, 52.5, CX + 2.5, 56.75, 1.25)
    parts["lever"] = segment(X, Y, (CX + 1.5, 54.0), (CX - 9.5, 57.5), 0.8) | (((X - (CX - 9.5)) ** 2 + (Y - 57.5) ** 2) <= 1.3 ** 2)
    parts["pivot"] = ((X - (CX + 1.0)) ** 2 + (Y - 54.5) ** 2) <= 1.0
    # 7 discharge nipple with a union; 8 long-radius elbow; 9 short drop, open at the bottom
    r = D_OD / 2
    parts["nipple"] = rect(X, Y, CX + 12.5, D_Y - r, BEND_X0, D_Y + r)
    parts["union"] = rect(X, Y, 322.5, D_Y - r - 1.0, 327.5, D_Y + r + 1.0)
    bc = (BEND_X0, D_Y + BEND_R)
    rr = np.sqrt((X - bc[0]) ** 2 + (Y - bc[1]) ** 2)
    parts["elbow"] = (X >= bc[0]) & (Y <= bc[1]) & (rr >= BEND_R - r) & (rr <= BEND_R + r)
    parts["tail"] = rect(X, Y, TAIL_X - r, bc[1], TAIL_X + r, TAIL_END_Y)
    parts["tail_lip"] = rect(X, Y, TAIL_X - r - 0.5, TAIL_END_Y - 1.5, TAIL_X + r + 0.5, TAIL_END_Y)

    order = ["weld", "boss", "hex", "body", "outlet", "outlet_hex", "bonnet", "cap", "lever", "pivot",
             "nipple", "union", "elbow", "tail", "tail_lip"]
    allm = np.zeros_like(boss)
    for k in order:
        allm |= parts[k]

    def down(m):
        return m.reshape(H, SS, W, SS).mean(axis=(1, 3))

    cov = {k: down(parts[k]) for k in order}
    cov["all"] = down(allm)

    # Flat value plan: overhead corridor light, a touch from the right (as on the relay's pipe).
    STEEL = np.array([50, 60, 70.0]); BRONZE = np.array([92, 78, 58.0])
    material = {"weld": STEEL * 0.8, "boss": STEEL, "hex": STEEL * 1.05, "body": BRONZE, "outlet": BRONZE,
                "outlet_hex": STEEL * 1.05, "bonnet": BRONZE * 1.02, "cap": BRONZE * 0.95,
                "lever": STEEL * 1.1, "pivot": STEEL * 0.8, "nipple": STEEL, "union": STEEL * 1.08,
                "elbow": STEEL, "tail": STEEL, "tail_lip": STEEL * 0.85}
    # Cylinder shading: vertical parts across x (lit right of centre), horizontal parts across y
    # (lit on top), the elbow across its radius.
    rgb = np.zeros(X.shape + (3,))
    for k in order:
        m = parts[k]
        base = material[k]
        if k in ("nipple", "union"):
            v = (Y - D_Y) / (r + 1.0)  # -1 top .. 1 bottom
            shade = 1.25 - 0.55 * (v + 1) / 2 - 0.25 * np.clip(v - 0.4, 0, 1)
            shade += 0.6 * np.exp(-((v + 0.45) / 0.22) ** 2)
        elif k == "elbow":
            v = (rr - BEND_R) / r  # -1 inner .. 1 outer
            ang = np.arctan2(bc[1] - Y, X - bc[0])  # 0 at the right, pi/2 at the top
            shade = 0.95 + 0.25 * np.sin(ang) - 0.25 * np.abs(v) + 0.55 * np.exp(-((v - 0.35) / 0.25) ** 2) * np.sin(ang)
        else:
            if k in ("tail", "tail_lip"):
                c, half = TAIL_X, r
            elif k in ("outlet", "outlet_hex"):
                c, half = CX + 8.0, 4.5
            else:
                c, half = CX, 6.5
            u = np.clip((X - c) / half, -1, 1)
            shade = 0.85 + 0.25 * u - 0.35 * u ** 2 + 0.55 * np.exp(-((u - 0.3) / 0.25) ** 2)
            if k in ("bonnet", "cap", "body", "boss", "hex"):
                # light from above: tops a little brighter, the body darker toward its hex
                shade *= 1.0 + 0.12 * np.clip((60.0 - Y) / 10.0, -1, 1)
        if k == "hex":
            # hex flats: the left face in shade, the centre face lit, the right face catching the lamp
            face = np.where(X < CX - 3.25, 0.62, np.where(X > CX + 3.25, 1.08, 0.95))
            shade = face * (1.0 + 0.0 * shade)
        if k == "tail_lip":
            shade = shade * 0.9
        col = np.clip(base[None, None, :] * shade[..., None], 0, 255)
        rgb[m] = col[m]
    # one-pixel dark outline like the Look 2 line work, from the silhouette (art resolution)
    a_art = cov["all"]
    rgb_art = rgb.reshape(H, SS, W, SS, 3).sum(axis=(1, 3)) / np.maximum(allm.reshape(H, SS, W, SS).sum(axis=(1, 3)), 1)[..., None]
    solid = a_art >= 0.5
    edge = solid & ~(np.roll(solid, 1, 0) & np.roll(solid, -1, 0) & np.roll(solid, 1, 1) & np.roll(solid, -1, 1))
    # the outline is skipped where the part meets the pipe it sits on (the weld runs into it)
    pipe = relay[..., 3] >= 128
    edge &= ~(np.roll(pipe, -1, 0) | pipe)
    OUTLINE = np.array([8, 11, 15.0])
    rgb_art[edge] = rgb_art[edge] * 0.35 + OUTLINE * 0.65

    os.makedirs(OUT, exist_ok=True)
    # the construction at 8x (one sample per supersample) for the paint step: crop window
    # x 260..368, y 40..140 in art px
    cy0, cy1, cx0, cx1 = 40 * SS, 140 * SS, 260 * SS, 368 * SS
    hi_rgb = rgb[cy0:cy1, cx0:cx1]
    hi_m = allm[cy0:cy1, cx0:cx1]
    # the outline at 8x: samples within 1 art px of the silhouette edge, outside the pipe contact
    from scipy import ndimage  # noqa: E402  (only needed here)
    inner = ndimage.binary_erosion(hi_m, iterations=SS)
    pipe_hi = np.kron(pipe[40:140, 260:368], np.ones((SS, SS), bool))
    pipe_hi_up = np.roll(pipe_hi, -SS, 0) | pipe_hi
    ring = hi_m & ~inner & ~pipe_hi_up
    hi_rgb = hi_rgb.copy()
    hi_rgb[ring] = hi_rgb[ring] * 0.35 + OUTLINE * 0.65
    np.savez_compressed(os.path.join(OUT, "hires.npz"), rgb=hi_rgb.astype(np.float32), mask=hi_m)
    np.savez_compressed(os.path.join(OUT, "parts.npz"), **{k: v.astype(np.float32) for k, v in cov.items()})
    # composite over the relay: straight-alpha 'over'
    sa = a_art; da = relay[..., 3] / 255.0
    oa = sa + da * (1 - sa)
    oc = (rgb_art * sa[..., None] + relay[..., :3] * (da * (1 - sa))[..., None]) / np.maximum(oa, 1e-6)[..., None]
    comp = np.dstack([oc, oa * 255.0])
    comp = np.clip(np.round(comp), 0, 255).astype(np.uint8)
    Image.fromarray(comp, "RGBA").save(os.path.join(OUT, "construction.png"))
    Image.fromarray(np.clip(np.round(np.dstack([rgb_art, a_art * 255])), 0, 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "fitting-flat.png"))
    crop = Image.fromarray(comp, "RGBA").crop((260, 40, 368, 140))
    bg = Image.new("RGBA", crop.size, (36, 38, 42, 255)); bg.alpha_composite(crop)
    bg.resize((crop.width * 8, crop.height * 8), Image.NEAREST).save(os.path.join(OUT, "construction-8x.png"))

    ox, oy = TAIL_X, TAIL_END_Y
    wx = ART_ORIGIN_WORLD[0] + ox / 4.0; wy = ART_ORIGIN_WORLD[1] + oy / 4.0
    ys, xs = np.where(a_art > 0)
    spec = {
        "units": "relay art px (4 per world px); world px (~42 per metre)",
        "relay_art_origin_world": ART_ORIGIN_WORLD,
        "fitting_bbox_art": [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1],
        "fitting_bbox_world": [ART_ORIGIN_WORLD[0] + xs.min() / 4, ART_ORIGIN_WORLD[1] + ys.min() / 4,
                               ART_ORIGIN_WORLD[0] + (xs.max() + 1) / 4, ART_ORIGIN_WORLD[1] + (ys.max() + 1) / 4],
        "valve_spindle_x_art": CX,
        "valve_height_art": [52.5, 93.5],
        "discharge_od_art": D_OD,
        "outlet_art": [ox, oy],
        "outlet_world": [wx, wy],
        "outlet_from_bypass_node": [wx - BYPASS_NODE_WORLD[0], wy - BYPASS_NODE_WORLD[1]],
        "jet_direction": [0.0, 1.0],
        "art_px_changed": int((a_art > 0).sum()),
    }
    with open(os.path.join(OUT, "spec.json"), "w") as f:
        json.dump(spec, f, indent=1)
    print(json.dumps(spec, indent=1))


if __name__ == "__main__":
    build()
