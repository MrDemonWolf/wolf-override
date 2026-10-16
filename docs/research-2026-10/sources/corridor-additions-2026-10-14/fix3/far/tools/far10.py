"""Round 10 (add7 fix round 3; copied from fix2/far/tools/far9.py, changed only where marked R10).

R10, real review r3 MUST 1: far9 kept the gain ratio at 1 over a RECTANGLE round the fitting
(SOURCE_BOX), so the wall inside it kept round 8's light while the wall round it was relit: a
hard-edged dark frame round the source. Now ratio 1 is kept only on the fitting's own pixels (body,
diffuser, end caps, hanger rods, canopies, from fix1/luminaire/design/spec.json), feathered over
about 2.5 plate px, and above the diffuser (plate y 229) the pool's gain fades smoothly upward to
nothing by y 199 (a batten's opaque body throws little light up the wall), the same at every x.
Everything else (the floor streak, the stray-streak inpaint) is far9's, unchanged.

Round 9's docstring follows.
Round 9 (add7 fix round 2): the far plate's light under the door end's luminaire, and the stray
floor streak by the safe point. Deterministic relighting of round 8's plate (no new paint).

Real review MUST 2: round 8 shortened the luminaire and moved it left (plate x 1213..1261, centre
1237) to clear PAUSE, but its painted wall pool (centroid plate x ~1286) and its wet-floor reflection
streak (peak ~1279) stayed under the old 1.2 m bar, about 0.55 m to the fitting's right. Real review
MUST 1 (part): the corridor floor in front of the safe point's wall carries a reflection streak (plate
x ~1786; 1280x720 screen x ~1181 at the door-end camera) of a lamp that is behind the wall.
(Plate to screen at the door-end camera: 0.9 screen px per plate px, fitting centre 1237 -> 687.)

Method (linear light, per pixel, no pixel is moved or repainted):
  * each light is modelled as a smooth gain over the plate's own unlit level,
        G(x, y) = 1 + A(y) * exp(-(x - xc)^2 / (2 s^2)),
    with xc and s fitted once on the region's summed column profile and A(y) fitted per 6-row
    band (least squares against a linear background), smoothed down the rows;
  * the pool and the streak are MOVED by multiplying by G(x + d, y) / G(x, y) (d = how far left),
    so the same concrete and the same wet patches carry the light at its new place;
  * the stray streak is REMOVED by dividing by its G.
The luminaire's own pixels (body, diffuser, rods, canopies) keep ratio 1: they are the source.
Writes add7/fix2/far/layer/corridor-far.png, report.json, and before/after crops.
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
SRC = "scratchpad/real-slice/add7/fix2/work/r8-game/assets/rooms/corridor-far.png"  # round 8 as installed (= fix1/luminaire/layer)
OUT = os.path.join(ROOT, "layer")  # R10: fix3/far/layer
LUM = np.array([0.2126, 0.7152, 0.0722])
FITTING_X = (1213, 1261)          # round 8's fitting (luminaire/tools/design.py)
FITTING_CX = 1237.0
# R10: the fitting's own pixels (fix1/luminaire/design/spec.json), not a box round them
FIT_BODY_Y, FIT_DIFF_Y, FIT_HANGERS, FIT_CANOPY_Y = (219, 224), (224, 227), (1217, 1256), (192, 194)
TAPER_Y = (199.0, 229.0)          # R10: the pool's gain fades from full at y 229 to none at y 199
FEATHER = 1.2                      # R10: gaussian sigma (plate px) of the fitting mask's edge
WALL = (1150, 1435, 196, 687)     # x0, x1, y0, y1: the bulkhead wall under the fitting
WALL_FIT_ROWS = (229, 316)        # rows clear of the pipes, where the pool is cleanest
FLOOR = (1150, 1440, 688, 1080)
STRAY = (1700, 1880, 740, 1080)
WALL_EXTRA = 9.0                   # plate px, see the wall pool below
A_MAX = 8.0                        # a light at most 9x the unlit level under it
FADE = 12                          # px: each region's ratio fades to 1 at its edges


def to_lin(u8):
    c = u8 / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(lin):
    lin = np.clip(lin, 0, 1)
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055) * 255.0


def profile(Y, x0, x1, y0, y1):
    return ndimage.uniform_filter1d(Y[y0:y1, x0:x1].mean(0), 7)


def fit_center(p, xs, xc_range, s_range):
    best = None
    for xc in xc_range:
        for s in s_range:
            g = np.exp(-(xs - xc) ** 2 / (2 * s * s))
            A = np.stack([np.ones_like(xs), xs - xs.mean(), g], 1)
            coef, res, *_ = np.linalg.lstsq(A, p, rcond=None)
            r = ((A @ coef - p) ** 2).sum()
            if best is None or r < best[0]:
                best = (r, float(xc), float(s), coef)
    return best


def gain_field(Y, box, xc, s, band=6, skip_rows=None, smooth=4.0):
    x0, x1, y0, y1 = box
    xs = np.arange(x0, x1, dtype=float)
    g = np.exp(-(xs - xc) ** 2 / (2 * s * s))
    A_rows = np.zeros(y1 - y0)
    ok = np.zeros(y1 - y0, bool)
    for b0 in range(y0, y1, band):
        b1 = min(b0 + band, y1)
        if skip_rows is not None and any(lo <= b0 < hi for lo, hi in skip_rows):
            continue
        p = profile(Y, x0, x1, b0, b1)
        M = np.stack([np.ones_like(xs), xs - xs.mean(), g], 1)
        coef, *_ = np.linalg.lstsq(M, p, rcond=None)
        # the unlit level under the light's centre (the linear background there), never below the
        # band's own darkest decile, so a dark band cannot blow the ratio up
        base = max(coef[0] + coef[1] * (xc - xs.mean()), np.percentile(p, 10), 1e-4)
        A_rows[b0 - y0:b1 - y0] = min(max(coef[2], 0.0) / base, A_MAX)
        ok[b0 - y0:b1 - y0] = True
    idx = np.arange(y1 - y0)
    A_rows = np.interp(idx, idx[ok], A_rows[ok])
    A_rows = ndimage.gaussian_filter1d(A_rows, smooth)
    return A_rows


def edge_fade(shape, fade):
    h, w = shape
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.minimum.reduce([xx, w - 1 - xx, yy, h - 1 - yy]).astype(float)
    return np.clip(d / fade, 0, 1)


def ratio_move(A_rows, box, xc, s, d):
    x0, x1, y0, y1 = box
    xs = np.arange(x0, x1, dtype=float)
    g_old = np.exp(-(xs - xc) ** 2 / (2 * s * s))
    g_new = np.exp(-(xs - (xc - d)) ** 2 / (2 * s * s))
    return (1 + A_rows[:, None] * g_new[None, :]) / (1 + A_rows[:, None] * g_old[None, :])


def ratio_remove(A_rows, box, xc, s):
    x0, x1, y0, y1 = box
    xs = np.arange(x0, x1, dtype=float)
    g = np.exp(-(xs - xc) ** 2 / (2 * s * s))
    return 1.0 / (1 + A_rows[:, None] * g[None, :])


def peaks(Y, box, rows):
    x0, x1, _, _ = box
    p = profile(Y, x0, x1, *rows)
    xs = np.arange(x0, x1)
    w = np.clip(p - np.percentile(p, 20), 0, None)
    return {"peak_x": int(xs[ndimage.uniform_filter1d(p, 9).argmax()]), "centroid_x": round(float((xs * w).sum() / max(w.sum(), 1e-9)), 1)}


def main():
    os.makedirs(OUT, exist_ok=True)
    u8 = np.asarray(Image.open(SRC).convert("RGB")).astype(float)
    lin = to_lin(u8)
    Y = (lin * LUM).sum(-1)
    R = np.ones(Y.shape)
    rep = {"before": {}, "after": {}, "fits": {}}
    # --- the wall pool
    xs = np.arange(WALL[0], WALL[1], dtype=float)
    p = profile(Y, WALL[0], WALL[1], *WALL_FIT_ROWS)
    _, xc_w, s_w, _ = fit_center(p, xs, np.arange(1250, 1320, 1.0), np.arange(20, 70, 2.0))
    # the fitted centre sits left of the pool's visible peak (the pool is skewed right by the wall's
    # end at x 1435): measured in game (render.sh, s1/s5 at 720p) the moved peak landed 8 screen px
    # (9 plate px) right of the fitting, so the move is 9 px more than the fit's centre offset
    d_w = xc_w - FITTING_CX + WALL_EXTRA
    A_w = gain_field(Y, WALL, xc_w, s_w, skip_rows=[(316, 376)])
    # R10: above the diffuser the bands are fitted across the fitting itself, so their A is not the
    # wall's: hold the diffuser row's A there, and taper the pool's effect upward (below)
    yrow = np.arange(WALL[2], WALL[3], dtype=float)
    A_w = np.where(yrow < TAPER_Y[1], A_w[int(TAPER_Y[1]) - WALL[2]], A_w)
    r_w = ratio_move(A_w, WALL, xc_w, s_w, d_w)
    t = np.clip((yrow - TAPER_Y[0]) / (TAPER_Y[1] - TAPER_Y[0]), 0, 1)
    taper = (0.5 - 0.5 * np.cos(np.pi * t))[:, None]
    r_w = 1 + (r_w - 1) * taper
    # R10: the source and its hangers stay as they are: ratio 1 on the fitting's own pixels only,
    # feathered, so no frame of unrelit wall is left round it
    X, Yg = np.meshgrid(np.arange(WALL[0], WALL[1]), yrow)
    fit = (X >= FITTING_X[0]) & (X < FITTING_X[1]) & (Yg >= FIT_BODY_Y[0]) & (Yg < FIT_DIFF_Y[1])
    for hx in FIT_HANGERS:
        fit |= (X >= hx) & (X < hx + 2) & (Yg >= FIT_CANOPY_Y[1]) & (Yg < FIT_BODY_Y[0])
        fit |= (X >= hx - 2) & (X < hx + 4) & (Yg >= FIT_CANOPY_Y[0]) & (Yg < FIT_CANOPY_Y[1])
    keep = np.clip(ndimage.gaussian_filter(ndimage.binary_dilation(fit, iterations=1).astype(float), FEATHER) * 1.6, 0, 1)
    keep = np.maximum(keep, fit.astype(float))
    r_w = 1 + (r_w - 1) * (1 - keep)
    rep["fits"]["fitting_mask_px"] = int(fit.sum())
    fw = edge_fade(r_w.shape, FADE)
    fw[:, :] = np.minimum(fw, 1.0)
    R[WALL[2]:WALL[3], WALL[0]:WALL[1]] *= 1 + (r_w - 1) * fw
    rep["fits"]["wall_pool"] = {"xc": xc_w, "sigma": s_w, "moved_px": round(d_w, 1), "A_max": round(float(A_w.max()), 3)}
    new = lin * R[..., None]   # the wall pool, moved
    # --- the floor streaks are reflections: light ADDED to the wet floor, in the lamp's own cool
    # white (not the floor's blue). Each is taken as its luma excess per pixel, E = Y (1 - 1/G),
    # carried as a neutral-cool light; the moved streak's excess is subtracted where it was and
    # added back d px to the left (its own patchy pattern moves with it); the stray one is
    # subtracted. Nothing is ever taken below 30 % of the pixel.
    TINT = np.array([0.92, 1.0, 1.04]) / (np.array([0.92, 1.0, 1.04]) * LUM).sum()
    xs = np.arange(FLOOR[0], FLOOR[1], dtype=float)
    p = profile(Y, FLOOR[0], FLOOR[1], 720, 900)
    _, xc_f, s_f, _ = fit_center(p, xs, np.arange(1250, 1310, 1.0), np.arange(8, 40, 1.0))
    d_f = int(round(xc_f - FITTING_CX))
    A_f = gain_field(Y, FLOOR, xc_f, s_f, band=6, smooth=3.0)
    x0, x1, y0, y1 = FLOOR
    g = np.exp(-(xs - xc_f) ** 2 / (2 * s_f * s_f))
    G = 1 + A_f[:, None] * g[None, :]
    E = Y[y0:y1, x0:x1] * (1 - 1 / G) * edge_fade(G.shape, FADE)
    E_new = np.zeros_like(E)
    E_new[:, :E.shape[1] - d_f] = E[:, d_f:]
    reg = new[y0:y1, x0:x1]
    reg = np.maximum(reg - E[..., None] * TINT, reg * 0.30) + E_new[..., None] * TINT
    new[y0:y1, x0:x1] = reg
    rep["fits"]["floor_streak"] = {"xc": xc_f, "sigma": s_f, "moved_px": d_f, "A_max": round(float(A_f.max()), 3), "model": "additive reflection, cool white"}
    # --- the stray streak by the safe point: inpainted. Its columns' low-frequency light is
    # interpolated across from the floor either side of it (3.5 sigma out), and the floor's own
    # high-pass texture is kept, scaled to that level, so the wet patches carry on unlit.
    xs = np.arange(STRAY[0], STRAY[1], dtype=float)
    p = profile(Y, STRAY[0], STRAY[1], 800, 1000)
    _, xc_s, s_s, _ = fit_center(p, xs, np.arange(1765, 1810, 1.0), np.arange(6, 36, 1.0))
    half = int(round(3.5 * s_s))
    x0, x1, y0, y1 = int(xc_s) - half, int(xc_s) + half + 1, STRAY[2], STRAY[3]
    blur = np.stack([ndimage.gaussian_filter(new[..., c], 3.0) for c in range(3)], -1)
    left, right = blur[y0:y1, x0 - 3:x0].mean(1), blur[y0:y1, x1:x1 + 3].mean(1)
    f = ((np.arange(x0, x1) - x0 + 0.5) / (x1 - x0))[None, :, None]
    base = left[:, None, :] * (1 - f) + right[:, None, :] * f
    hp = new[y0:y1, x0:x1] - blur[y0:y1, x0:x1]
    k = ((base * LUM).sum(-1) / np.maximum((blur[y0:y1, x0:x1] * LUM).sum(-1), 1e-5))[..., None]
    filled = np.maximum(base + hp * np.clip(k, 0.2, 1.0), 0)
    # feather: full fill inside 2.5 sigma of the centre, back to the plate at 3.5 sigma
    w = np.clip((3.5 * s_s - np.abs(np.arange(x0, x1) + 0.5 - xc_s)) / s_s, 0, 1)[None, :, None]
    wy = np.clip((np.arange(y0, y1) - y0) / 6.0, 0, 1)[:, None, None]
    new[y0:y1, x0:x1] = new[y0:y1, x0:x1] * (1 - w * wy) + filled * w * wy
    rep["fits"]["stray_streak"] = {"xc": xc_s, "sigma": s_s, "inpainted_x": [x0, x1], "rows": [y0, y1], "model": "low-frequency interpolated across, floor high-pass kept"}
    out = np.clip(np.round(to_srgb(new)), 0, 255).astype(np.uint8)
    # pixels outside the three regions are round 8's exactly
    touched = np.zeros(Y.shape, bool)
    for b in (WALL, FLOOR, STRAY):
        touched[b[2]:b[3], b[0]:b[1]] = True
    out[~touched] = u8[~touched].astype(np.uint8)
    Image.fromarray(out, "RGB").save(os.path.join(OUT, "corridor-far.png"))
    Y2 = (to_lin(out.astype(float)) * LUM).sum(-1)
    for tag, Yy in (("before", Y), ("after", Y2)):
        rep[tag]["wall_pool_rows_232_300"] = peaks(Yy, WALL, (232, 300))
        rep[tag]["floor_streak_rows_720_900"] = peaks(Yy, FLOOR, (720, 900))
        sp = profile(Yy, STRAY[0], STRAY[1], 800, 1000)
        rep[tag]["stray_zone_rows_800_1000_max_over_median"] = round(float(sp.max() / np.median(sp)), 3)
    rep["fitting_centre_x"] = FITTING_CX
    rep["changed_px"] = int((np.abs(out.astype(int) - u8.astype(int)).max(-1) > 0).sum())
    json.dump(rep, open(os.path.join(OUT, "report.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))
    for nm, img in (("before", u8.astype(np.uint8)), ("after", out)):
        c = Image.fromarray(img).crop((1120, 180, 1560, 1080))
        c = Image.fromarray(np.clip(np.asarray(c).astype(float) * 2.2, 0, 255).astype(np.uint8))
        c.save(os.path.join(OUT, f"crop-{nm}-x2.2.png"))


if __name__ == "__main__":
    main()
