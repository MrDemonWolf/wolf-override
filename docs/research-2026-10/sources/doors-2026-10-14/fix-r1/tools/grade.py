"""Fix round 1 (M1): grades the door ends' concrete into their rooms' value plan (scratch only).

The approved corridor door end's cross-wall sits at 0.72x its room's back-wall luminance; the round-1
walls sat at 1.9-3.8x and read as pasted grey-box. Here every door end's concrete is set, row by row,
to RATIO x the room's own back wall at the same height (luminance as the reviewer measures it: Rec.709
weights on sRGB values), measured in the round-1 render.sh frames of the room (whose plates this round
does not change there). The room's own fall-off toward the ceiling comes with it. One gain per row,
smoothed, is applied to every piece of that door end (wall, leaf, column, stub, damage), so the
painted light keeps its relations (the pools under the fittings stay brighter than the wall round
them); emissive lenses keep their value. A passage seen through a doorway is set to PASSAGE_RATIO.
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
FRAMES = os.path.join(HERE, "..", "..", "integrate", "captures", "after-1280")
RATIO = 0.70
PASSAGE_RATIO = 0.95
FLOOR_FRAC = 0.55
W709 = np.array([0.2126, 0.7152, 0.0722])


def lum(rgb_u8):
    return (np.asarray(rgb_u8)[..., :3].astype(np.float64) / 255.0 * W709).sum(-1)


def shot(slug):
    d = json.load(open(os.path.join(FRAMES, "_run.json")))
    for s in d["shots"]:
        if s["slug"] == slug:
            return s
    raise KeyError(slug)


def room_profile(slug, x_ranges, y0=150.0, y1=445.0, sigma=10.0):
    """Median luminance of the room's back wall per world row (1 px rows from y0), over x_ranges
    (world), from that shot's render.sh frame."""
    s = shot(slug)
    sc, tx, ty = s["canvas"][0], s["canvas"][4], s["canvas"][5]
    k = 1280.0 / 960.0
    img = lum(Image.open(os.path.join(FRAMES, f"{slug}-clean.png")).convert("RGB"))
    ys = np.arange(y0, y1, 1.0)
    out = np.zeros(len(ys))
    for i, y in enumerate(ys):
        sy = int(round((y * sc + ty) * k))
        vals = []
        for (xa, xb) in x_ranges:
            sx0, sx1 = int(round((xa * sc + tx) * k)), int(round((xb * sc + tx) * k))
            sx0, sx1 = max(sx0, 0), min(sx1, 1280)
            if 0 <= sy < 720 and sx1 > sx0:
                vals.append(img[sy, sx0:sx1])
        out[i] = np.median(np.concatenate(vals)) if vals else np.nan
    good = ~np.isnan(out)
    out = np.interp(ys, ys[good], out[good])
    return ys, ndimage.gaussian_filter1d(out, sigma, mode="nearest")


def row_gains(rgba, mask, world_y0, ppw, prof, ratio=RATIO, sigma_px=None, lo=0.08, hi=1.0, y_hold=422.0):
    """Per-row gain (one per image row) that brings the median luminance of mask's pixels in each row
    to ratio x the room profile at that row's world y. Rows without mask pixels take the nearest
    row's gain."""
    ys_w, ref = prof
    # The room's upper wall is mostly dark gaps between lit pipes: its median there says less about how
    # light the room reads than its lower wall does. The target never falls below FLOOR_FRAC of the
    # room's median over its lower wall (rows 300-430), so a cast face high up stays a visible, darker
    # surface and does not go to a black void.
    band = (ys_w >= 300.0) & (ys_w <= 430.0)
    ref_floor = FLOOR_FRAC * float(np.median(ref[band])) if band.any() else 0.0
    L = lum(rgba)
    h = L.shape[0]
    g = np.full(h, np.nan)
    for r in range(h):
        sel = mask[r] > 0.5
        if sel.sum() >= 6:
            cur = np.median(L[r][sel])
            yw = world_y0 + (r + 0.5) / ppw
            tgt = ratio * max(float(np.interp(yw, ys_w, ref)), ref_floor)
            g[r] = tgt / max(cur, 1e-4)
    # the room's reference near the floor is its wet floor's sheen, not wall: rows below y_hold keep the
    # gain the wall has just above it
    rows_w = world_y0 + (np.arange(h) + 0.5) / ppw
    g[rows_w > y_hold] = np.nan
    good = ~np.isnan(g)
    if not good.any():
        return np.ones(h)
    idx = np.arange(h)
    g = np.interp(idx, idx[good], g[good])
    g = ndimage.gaussian_filter1d(np.log(np.clip(g, lo, hi)), sigma_px or 6.0 * ppw, mode="nearest")
    return np.exp(g)


def gains_to_world(gains, world_y0, ppw):
    ys = world_y0 + (np.arange(len(gains)) + 0.5) / ppw
    return ys, gains


def row_medians(rgba, mask, world_y0, ppw):
    """The median luminance of mask's pixels per row, as (world ys, medians), smoothed; for
    apply_world_gains' pool keeping."""
    L = lum(rgba)
    med = np.full(rgba.shape[0], np.nan)
    for r in range(rgba.shape[0]):
        sel = mask[r] > 0.5
        if sel.sum() >= 6:
            med[r] = np.median(L[r][sel])
    good = ~np.isnan(med)
    idx = np.arange(len(med))
    med = ndimage.gaussian_filter1d(np.interp(idx, idx[good], med[good]), 8.0, mode="nearest") if good.any() else np.full(len(med), 1.0)
    return world_y0 + (idx + 0.5) / ppw, med


def apply_world_gains(rgba, world_y0, ppw, gw, keep=None, meds=None):
    """Multiplies an RGBA image (world origin y0, ppw) row by row by the gains gw = (ys, g) (interpolated
    at its rows, held at the ends); pixels in keep (emissive parts) are left as they are. With meds (the
    concrete's row medians the gains were measured on, row_medians), the painted light keeps its
    relations: a pixel well above its row's median (a pool under a fitting, a lit edge) takes only part
    of the darkening."""
    ys, g = gw
    rows = world_y0 + (np.arange(rgba.shape[0]) + 0.5) / ppw
    gr = np.interp(rows, ys, g)
    out = rgba.astype(np.float64).copy()
    f = np.broadcast_to(gr[:, None], rgba.shape[:2]).copy()
    if meds is not None:
        med = np.interp(rows, meds[0], meds[1])
        ratio = lum(rgba) / np.maximum(med[:, None], 1e-4)
        w = np.clip((ratio - 1.25) / 1.5, 0.0, 0.6)
        f = np.power(f, 1.0 - w)
    f = f[..., None]
    if keep is not None:
        f = np.where(keep[..., None] > 0.5, 1.0, f)
    out[..., :3] = np.clip(out[..., :3] * f, 0, 255)
    return out.astype(np.uint8)


def median_gain(gw, y0, y1):
    ys, g = gw
    sel = (ys >= y0) & (ys <= y1)
    return float(np.exp(np.median(np.log(g[sel])))) if sel.any() else 1.0


# the rooms' back-wall reference spans (world x) and the frames they are read from
REFS = {
    "records-exit": ("r04-copy-point", [(255.0, 460.0)]),
    "records-entry": ("r01-arrival", [(255.0, 460.0)]),
    "junction-blast": ("j06-lane-sentry", [(640.0, 790.0)]),
    "junction-exit": ("j11-hatch-open", [(640.0, 790.0)]),
    "junction-entry": ("r09-after-leaving", [(232.0, 400.0)]),
}


def profile(name):
    slug, xr = REFS[name]
    return room_profile(slug, xr)


def boost_detail(rgba, mask, sigma=3.0, amount=1.0):
    """Lifts the paint's own fine structure on the concrete (unsharp mask: the image plus amount x its
    difference from a sigma-px blur), so the cast face carries the room's level of fine grain after the
    darkening, from the painted grain itself (nothing is added: no noise)."""
    out = rgba.astype(np.float64).copy()
    m = (mask > 0.5) & (rgba[..., 3] > 250)
    for c in range(3):
        ch = out[..., c]
        bl = ndimage.gaussian_filter(ch, sigma)
        ch = np.where(m, ch + amount * (ch - bl), ch)
        out[..., c] = ch
    return np.clip(out, 0, 255).astype(np.uint8)
