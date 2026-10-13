"""Fix round 2 (v3), the far plate before the plant room's near slab is added (deterministic; the
painted pixels are round 1's paint-far2b, cleaned by cleanup2.py into layers/v2/corridor-far.png).

  small 2   the plant room seen past the cross-wall is darkened to the actors' values (wall about
            luma 38, floor 36 on the plate) with a defined pool under its visible high-bay B (the
            room's low-frequency light is raised to a power, so the pool keeps its place and the
            corners fall away), and carried toward the corridor's cold hue (HSV S about 0.38, from
            0.12-0.19), per pixel, so the paint's texture and variation stay.
  small 3   the tank's dished head is lit from high-bay B straight above it: its top is the
            brightest part of the tank, falling off over the crown.
  must 4    the lockdown beacon's painted mount (conduit and back box) moves back under main's
            beacon (far x 0.659, clamp-world x 645.1); the old place is filled from the wall each side.
  must 5    fine grain (+-2.5 levels, 0.6 px) on the calm faces (the plant wall and the corridor
            bay wall), so S3TC/ETC2 blocks do not band.
Nothing left of source x 1132 (the opening's framing) changes. Writes layers/v3/corridor-far-base.png
and layers/v3/far-report.json.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from imgkit import lum, to_lin, to_srgb

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
M = os.path.join(R, "design", "far-patch2", "masks")
OUT = os.path.join(R, "layers", "v3")
X0 = 1112  # the patch's source x
FAR_SHIFT = 12.444
MACH_PREFIX = ("mach_", "catwalk_", "highbay_", "pump_", "tank_")
TARGET_RGB = np.array([28.3, 40.1, 45.6])  # luma 38, S 0.38, the corridor's hue
GAMMA = 1.6


def mask(n):
    return np.asarray(Image.open(os.path.join(M, n + ".png")).convert("L")).astype(np.float64) / 255.0


def mgauss(v, m, s):
    return ndimage.gaussian_filter(v * m, s) / np.maximum(ndimage.gaussian_filter(m, s), 1e-6)


def hsv_s(c):
    return float((c.max() - c.min()) / max(c.max(), 1e-6))


def stats(img, sel):
    c = img[sel].mean(0)
    return {"mean_rgb": [round(float(v), 1) for v in c], "luma": round(float(lum(img[sel]).mean()), 1), "S": round(hsv_s(c), 3)}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    spec = json.load(open(os.path.join(R, "design", "far-patch2", "spec.json")))
    order = spec["draw_order_back_to_front"]
    full = np.asarray(Image.open(os.path.join(R, "layers", "v2", "corridor-far.png")).convert("RGB")).astype(np.float64)
    P = full[0:808, X0:1920].copy()
    masks = {n: mask(n) for n in order if os.path.exists(os.path.join(M, n + ".png"))}
    # visible masks, nearest last
    vis = {}
    nearer = np.zeros((808, 808))
    for n in reversed(order):
        if n in masks:
            vis[n] = np.clip(masks[n] - nearer, 0, 1)
            nearer = np.clip(nearer + masks[n], 0, 1)
    mach = np.zeros((808, 808))
    for n, v in vis.items():
        if n.startswith(MACH_PREFIX) and not n.endswith("_lens"):
            mach = np.maximum(mach, v)
    lenses = np.clip(vis["highbay_A_lens"] + vis["highbay_B_lens"], 0, 1)
    report = {"before": {"mach_wall": stats(P, vis["mach_wall"] > 0.5), "mach_floor": stats(P, (vis["mach_floor"] + vis["mach_floor_near"]) > 0.5),
                         "tank_shell": stats(P, vis["tank_shell"] > 0.5), "tank_head": stats(P, vis["tank_head"] > 0.5)}}
    # ---- small 2: values and hue of the plant room
    lin = to_lin(P)
    Y = lum(lin)
    m = (mach > 0.5).astype(float)
    low = mgauss(Y, m, 10.0)
    wall_sel = vis["mach_wall"] > 0.5
    # T = k * low^GAMMA, with k so that the plant wall's mean sRGB luma lands on the target
    target_y = to_lin(np.array([TARGET_RGB]))[0]
    target_luma_lin = float(lum(target_y[None, :])[0])
    shaped = np.power(np.maximum(low, 1e-6), GAMMA)
    k = 1.0
    for _ in range(30):
        Yn = Y * (k * shaped / np.maximum(low, 1e-6))
        cur = float(lum(to_srgb(np.repeat(Yn[wall_sel][:, None], 3, 1))).mean())
        k *= (38.0 / max(cur, 1e-3)) ** 1.6
    gain = np.where(m > 0, k * shaped / np.maximum(low, 1e-6), 1.0)
    gain = gain * (1 - lenses) + lenses
    # ---- small 3: the tank head lit from high-bay B straight above it
    yy, xx = np.mgrid[0:808, 0:808].astype(np.float64)
    head = vis["tank_head"]
    hy, hx = np.nonzero(head > 0.5)
    top_y, cx = hy.min(), (hx.min() + hx.max()) / 2.0
    # the dished head's top surface (seen from above the horizon line's height... below it: the
    # plate's eye is above the tank top) faces high-bay B: lit across, brightest under the lamp, with
    # no glint brighter than the actors
    hh = max(hy.max() - top_y, 1)
    crown = np.exp(-(((xx - (cx + 6.0)) / 34.0) ** 2) - (((yy - (top_y + 0.45 * hh)) / (0.6 * hh)) ** 2))
    shell_top = np.exp(-(((yy - (hy.max() + 2.0)) / 14.0) ** 2)) * vis["tank_shell"]
    dome_gain = 1.0 + 0.3 * shell_top * np.exp(-(((xx - (cx + 6.0)) / 30.0) ** 2))
    gain = gain * dome_gain
    # hue: each pixel's chromaticity moved by the region's shift toward the target hue
    chrom = lin / np.maximum(Y[..., None], 1e-6)
    cm = (chrom * m[..., None]).sum((0, 1)) / max(m.sum(), 1.0)
    ct = target_y / target_luma_lin
    new_chrom = np.clip(chrom + (ct - cm)[None, None, :] * m[..., None], 0, None)
    Yn = Y * gain
    newlin = new_chrom * Yn[..., None]
    w = (m * (1 - lenses))[..., None]
    lin = lin * (1 - w) + newlin * w
    P2 = to_srgb(lin)
    # the dished head, seen from above, faces high-bay B straight over it: relight it row by row to a
    # target in sRGB luma (the far rim's glint capped at 90, the crown under the lamp about 55, the near
    # curve falling to 32), keeping the paint's texture as each pixel's ratio to its row's mean
    Lh = lum(P2)
    rows = np.arange(808)
    t = np.clip((rows - top_y) / max(hy.max() - top_y, 1), 0, 1)
    target = np.interp(t, [0.0, 0.08, 0.2, 0.45, 1.0], [70.0, 90.0, 62.0, 52.0, 32.0])
    row_mean = np.array([Lh[y][head[y] > 0.5].mean() if (head[y] > 0.5).any() else 1.0 for y in rows])
    ratio = np.clip(Lh / np.maximum(row_mean[:, None], 1e-3), 0.6, 1.5)
    want = np.clip(target[:, None] * ratio, 0, 95)
    gh = to_lin(np.repeat(want[..., None], 3, 2))[..., 0] / np.maximum(to_lin(np.repeat(Lh[..., None], 3, 2))[..., 0], 1e-6)
    lin2 = to_lin(P2) * np.clip(gh, 0, 20)[..., None]
    hw = (head > 0.5)[..., None] * (1 - lenses[..., None])
    P2 = P2 * (1 - hw) + to_srgb(lin2) * hw
    # ---- must 4: the beacon's painted mount back under main's beacon (far x 0.659)
    old_x = 0.62 * 960.0 + FAR_SHIFT
    new_x = 0.659 * 960.0 + FAR_SHIFT
    dx = int(round((new_x - old_x) * 2.0))
    mount = np.clip(masks["beacon_conduit"] + masks["beacon_backbox"], 0, 1)
    mount_d = ndimage.binary_dilation(mount > 0.05, iterations=1)
    before_fill = P2.copy()
    # fill the old place from the wall each side, row by row (linear across the gap, with the texture
    # of the wall 6 px to the right)
    for y in np.nonzero(mount_d.any(1))[0]:
        cols = np.nonzero(mount_d[y])[0]
        a, b = cols.min() - 1, cols.max() + 1
        for c in cols:
            t = (c - a) / max(b - a, 1)
            base = before_fill[y, a] * (1 - t) + before_fill[y, b] * t
            tex = before_fill[y, min(c + 7, 807)] - (before_fill[y, min(a + 7, 807)] * (1 - t) + before_fill[y, min(b + 7, 807)] * t)
            P2[y, c] = base + 0.6 * tex
    # the fitting in front: its chains, housing and lens (the conduit passes behind it)
    fitting = np.clip(masks["lum_chains"] + masks["lum_housing"] + masks["lum_lens"], 0, 1)
    moved = np.zeros_like(mount)
    moved[:, dx:] = mount[:, :-dx]
    moved *= (1 - fitting)
    src = np.zeros_like(P2)
    src[:, dx:] = before_fill[:, :-dx]
    # the moved mount takes the local light: scale it by the wall's light there over its old light
    wl = mgauss(lum(to_lin(before_fill)), (vis["corr_wall"] > 0.5).astype(float), 6.0)
    ratio = np.ones((808, 808))
    ratio[:, dx:] = wl[:, dx:] / np.maximum(wl[:, :-dx], 1e-5)
    srcl = to_srgb(to_lin(src) * np.clip(ratio, 0.5, 3.0)[..., None])
    P2 = P2 * (1 - moved[..., None]) + srcl * moved[..., None]
    # ---- must 5: fine grain on the calm faces
    rng = np.random.default_rng(20261012)
    calm = np.clip(vis["mach_wall"] + vis["corr_wall"] + vis["corr_dado"], 0, 1) * (1 - fitting) * (1 - moved)
    calm[:, :22] = 0.0  # nothing left of source x 1134 changes
    g = ndimage.gaussian_filter(rng.standard_normal((808, 808)), 0.6)
    g = g / g.std() * 2.5
    P2 = P2 + (g * calm)[..., None]
    P2 = np.clip(P2, 0, 255)
    # nothing left of the opening's framing changes
    P2[:, :20] = P[:, :20]
    out = full.copy()
    out[0:808, X0:1920] = P2
    Image.fromarray((out + 0.5).astype(np.uint8), "RGB").save(os.path.join(OUT, "corridor-far-base.png"))
    report["after"] = {"mach_wall": stats(P2, vis["mach_wall"] > 0.5), "mach_floor": stats(P2, (vis["mach_floor"] + vis["mach_floor_near"]) > 0.5),
                       "tank_shell": stats(P2, vis["tank_shell"] > 0.5), "tank_head": stats(P2, vis["tank_head"] > 0.5)}
    hsel = head > 0.5
    top_band = hsel & (yy < top_y + 10)
    report["after"]["tank_head_top_luma"] = round(float(lum(P2[top_band]).mean()), 1)
    report["after"]["tank_head_p99_luma"] = round(float(np.percentile(lum(P2[hsel]), 99)), 1)
    report["after"]["tank_shell_body_luma"] = round(float(lum(P2[(vis["tank_shell"] > 0.5) & (yy > hy.max() + 30)]).mean()), 1)
    report["regrade"] = {"gamma": GAMMA, "k": round(float(k), 4), "target_rgb": TARGET_RGB.tolist()}
    report["beacon_mount"] = {"from_clamp_x": round(old_x, 2), "to_clamp_x": round(new_x, 2), "shift_px": dx}
    report["grain"] = {"levels_sd": 2.5, "blur_px": 0.6, "faces": ["mach_wall", "corr_wall", "corr_dado"]}
    unchanged = bool(np.array_equal(out[:, :X0 + 20], full[:, :X0 + 20]))
    report["left_of_source_1132_unchanged"] = unchanged
    json.dump(report, open(os.path.join(OUT, "far-report.json"), "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
