"""Fix round 2 (review r2, N3): one light logic per door end. Scratch only; deterministic.

Round 1's grade (grade.py) set each cross-wall row by row to 0.70x the room's back wall, but it
measured in sRGB values (0.70 there is about 0.45 in linear light) and against wide back-wall spans that
are mostly dark recesses between lit pipes, so the walls came out 4-6x darker than the approved corridor
wall, and the steel leaves (graded by an eased gain) glowed 3-4x above them.

Here, as the reviewer measures:
  - luminance is LINEAR (Rec. 709 weights on linearised sRGB);
  - the reference is the room's back wall in a box just on the room side of the corner where the
    cross-wall meets it (REFS: the same boxes as measure3.py), per world row, from the round-1 render.sh
    frames (the room plates there are unchanged this round);
  - the wall is measured in the columns just on the cross-wall side of that corner, so the design's own
    fall-off along the face (from the fittings it was lit by) is kept: one gain per row;
  - every row of the face is set to RATIO x the back wall at that height (0.45-0.75 asked; 0.60), never
    below FLOOR_FRAC x the back wall's median over its lower rows, so a face high up in a dark recess
    stays a visible concrete surface, and a face that sees a lit fitting at the corner is lit with it;
  - gains are applied in linear light; a pool already brighter than its row (under a fitting) keeps part
    of its light; lenses keep their value;
  - the painted steel (leaves) is set to LEAF_FRAC x the concrete beside it at the door's rows (painted
    Gunship Gray 36118 is darker than grey cast concrete under the same light);
  - the paint's own fine structure is lifted at a scale that survives the 0.5x atlas (DETAIL_SIGMA_W
    world px), so the cast face keeps at least half the room's texture. Nothing is added: no noise.
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
FRAMES = os.path.join(HERE, "..", "measure", "r1-after-1280")
RATIO = 0.60
PASSAGE_RATIO = 0.90
FLOOR_FRAC = 0.50
LEAF_FRAC = 0.85
DETAIL_SIGMA_W = 1.2
DETAIL_AMOUNT = 2.0
W709 = np.array([0.2126, 0.7152, 0.0722])

# door end: (frame slug, back-wall world x range (room side of the corner), wall world x range (face side))
REFS = {
    "records-exit": ("r04-copy-point", (685.0, 712.0), (812.0, 850.0)),
    "records-entry": ("r01-arrival", (250.0, 290.0), (95.0, 150.0)),
    "junction-entry": ("r11-entry-shut", (150.0, 300.0), (60.0, 118.0)),  # no plain wall right of this corner: the room's machinery and the wall between, x 150-300
    "junction-blast": ("j01-sealed", (395.0, 416.0), (424.0, 446.0)),
    "junction-exit": ("j08-exit-bolt", (835.0, 866.0), (876.0, 905.0)),
}


def to_lin(u8):
    a = np.asarray(u8)[..., :3].astype(np.float64) / 255.0
    return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)


def to_srgb8(lin):
    lin = np.clip(lin, 0.0, 1.0)
    s = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * np.power(lin, 1 / 2.4) - 0.055)
    return np.clip(s * 255.0 + 0.5, 0, 255).astype(np.uint8)


def lum(rgb_u8):
    """Linear luminance (as the reviewer measures)."""
    return (to_lin(rgb_u8) * W709).sum(-1)


def shot(slug):
    d = json.load(open(os.path.join(FRAMES, "_run.json")))
    for s in d["shots"]:
        if s["slug"] == slug:
            return s, d["size"]
    raise KeyError(slug)


def room_profile(slug, xr, y0=140.0, y1=445.0, sigma=15.0):  # light on a wall varies smoothly with height
    s, size = shot(slug)
    sc, tx, ty = s["canvas"][0], s["canvas"][4], s["canvas"][5]
    k = size[0] / 960.0
    img = lum(Image.open(os.path.join(FRAMES, f"{slug}-clean.png")).convert("RGB"))
    ys = np.arange(y0, y1, 1.0)
    out = np.full(len(ys), np.nan)
    sx0, sx1 = int(round((xr[0] * sc + tx) * k)), int(round((xr[1] * sc + tx) * k))
    sx0, sx1 = max(sx0, 0), min(sx1, img.shape[1])
    for i, y in enumerate(ys):
        sy = int(round((y * sc + ty) * k))
        if 0 <= sy < img.shape[0] and sx1 > sx0:
            out[i] = np.median(img[sy, sx0:sx1])
    good = ~np.isnan(out)
    out = np.interp(ys, ys[good], out[good])
    return ys, ndimage.gaussian_filter1d(out, sigma, mode="nearest")


# the junction exit's back wall carries a ceiling fitting's hard-edged pool right at the corner: its
# profile is kept sharp (the face that sees that fitting is lit with the same fall-off)
SIGMA = {"junction-exit": 4.0}


def profile(name):
    slug, bx, _ = REFS[name]
    return room_profile(slug, bx, sigma=SIGMA.get(name, 15.0))


def wall_x(name):
    return REFS[name][2]


def row_gains(rgba, mask, world_y0, ppw, prof, ratio=RATIO, sigma_px=None, lo=0.15, hi=15.0, y_hold=422.0, world_x0=None, xr=None):
    """Per-row LINEAR gain bringing the median linear luminance of mask's pixels in each row (only those
    in world columns xr, when given and the row has them) to ratio x the room profile at that height."""
    ys_w, ref = prof
    band = (ys_w >= 300.0) & (ys_w <= 430.0)
    ref_floor = FLOOR_FRAC * float(np.median(ref[band])) if band.any() else 0.0
    L = lum(rgba)
    h, w = L.shape
    colsel = np.ones(w, bool)
    if xr is not None and world_x0 is not None:
        xw = world_x0 + (np.arange(w) + 0.5) / ppw
        colsel = (xw >= xr[0]) & (xw <= xr[1])
    g = np.full(h, np.nan)
    for r in range(h):
        sel = mask[r] > 0.5
        near = sel & colsel
        use = near if near.sum() >= 6 else sel
        if use.sum() >= 6:
            cur = np.median(L[r][use])
            yw = world_y0 + (r + 0.5) / ppw
            tgt = ratio * max(float(np.interp(yw, ys_w, ref)), ref_floor)
            g[r] = tgt / max(cur, 1e-5)
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
    """Multiplies an RGBA image row by row by the LINEAR gains gw = (ys, g); emissive pixels (keep) are
    left as they are; with meds, a pixel well above its row's median (a lit pool, a lit edge) takes only
    part of a darkening, or part of a lift."""
    ys, g = gw
    rows = world_y0 + (np.arange(rgba.shape[0]) + 0.5) / ppw
    gr = np.interp(rows, ys, g)
    f = np.broadcast_to(gr[:, None], rgba.shape[:2]).copy()
    if meds is not None:
        med = np.interp(rows, meds[0], meds[1])
        ratio = lum(rgba) / np.maximum(med[:, None], 1e-5)
        w = np.clip((ratio - 1.5) / 3.0, 0.0, 0.6)
        f = np.power(f, 1.0 - w)
    if keep is not None:
        f = np.where(keep > 0.5, 1.0, f)
    lin = to_lin(rgba) * f[..., None]
    out = np.asarray(rgba).copy()
    out[..., :3] = to_srgb8(lin)
    return out


def scale_lin(rgba, gain, keep=None):
    lin = to_lin(rgba) * gain
    out = np.asarray(rgba).copy()
    new = to_srgb8(lin)
    if keep is not None:
        new = np.where(keep[..., None] > 0.5, out[..., :3], new)
    out[..., :3] = new
    return out


def median_gain(gw, y0, y1):
    ys, g = gw
    sel = (ys >= y0) & (ys <= y1)
    return float(np.exp(np.median(np.log(g[sel])))) if sel.any() else 1.0


def masked_median(rgba, mask):
    L = lum(rgba)
    m = (mask > 0.5) & (np.asarray(rgba)[..., 3] > 250)
    return float(np.median(L[m])) if m.sum() > 8 else float("nan")


def leaf_gain(leaf_med, wall_med, frac=LEAF_FRAC):
    """The linear gain that puts painted steel at frac x the concrete beside it (never a lift above 1.5)."""
    if not (leaf_med > 0 and wall_med > 0):
        return 1.0
    return float(np.clip(frac * wall_med / leaf_med, 0.1, 8.0))


def boost_detail(rgba, mask, sigma=None, amount=DETAIL_AMOUNT, ppw=2.0):
    """Lifts the paint's own structure on the concrete (unsharp mask in log luminance at DETAIL_SIGMA_W
    world px, which survives the 2 px-per-world-px atlas), applied as a per-pixel gain so colour holds.
    Nothing is added: the structure is the painted grain itself."""
    s = sigma if sigma is not None else DETAIL_SIGMA_W * ppw
    a = np.asarray(rgba)
    m = (mask > 0.5) & (a[..., 3] > 250)
    if m.sum() < 16:
        return a.copy()
    lin = to_lin(a)
    L = np.maximum((lin * W709).sum(-1), 1e-5)
    lg = np.log(L)
    mf = m.astype(np.float64)
    bl = ndimage.gaussian_filter(lg * mf, s) / np.maximum(ndimage.gaussian_filter(mf, s), 1e-6)
    d = np.clip(lg - bl, -1.2, 1.2)
    gain = np.exp(np.where(m, amount * d, 0.0))
    out = a.copy()
    out[..., :3] = to_srgb8(lin * gain[..., None])
    return out


# ---------------------------------------------------------------------------------------------- feedback
# Fix round 2: the grade is closed on the render. After a render.sh pass, feedback.py measures, per world
# row, the cross-wall at the corner against the back wall (the boxes above) and stores the factor
# RATIO x back / wall that the next grade multiplies into that row's gain (cumulative over passes), so the
# face lands on RATIO at the corner whatever the atlas resampling, the room plate's parallax or the
# actors' contact shadows do between the layer and the screen.
FEEDBACK = os.path.join(HERE, "..", "measure", "feedback.json")


def feedback(name):
    try:
        fb = json.load(open(FEEDBACK)).get(name)
    except (OSError, ValueError):
        fb = None
    if not fb:
        return None
    return np.array(fb["ys"], float), np.array(fb["factor"], float)


def with_feedback(name, gw):
    fb = feedback(name)
    if fb is None:
        return gw
    ys, g = gw
    return ys, g * np.interp(ys, fb[0], fb[1])


# ------------------------------------------------------------------------------------- fittings, leaves
# render feedback on the painted steel (measured leaf / wall, measure4.py) where the design-side rule lands
# off in the render (a leaf painted much darker or lighter than its design value)
LEAF_FB = {"junction-blast": 1.4, "junction-exit": 1.6}


def fitting_pool(rgba, world_y0, ppw, gw, fit_mask, lens_mask, body_mask, radius_w=16.0, meds=None):
    """Fix round 2 (human: "a stray white dash with no fitting"): a batten seen through a doorway or over a
    door: its grey body and clips are not darkened (they are what shows the fitting: lit by its own
    spill), its lens takes half the darkening (the square root of the gain), and the wall round it keeps
    part of its light in a soft pool (the darkening's exponent eased by up to half within radius_w world
    px of the lens), so it reads as a lamp on the wall that lights it."""
    ys, g = gw
    rows = world_y0 + (np.arange(rgba.shape[0]) + 0.5) / ppw
    gr = np.interp(rows, ys, g)
    f = np.broadcast_to(gr[:, None], rgba.shape[:2]).copy()
    if lens_mask is not None and lens_mask.max() > 0:
        d = ndimage.distance_transform_edt(lens_mask < 0.5) / ppw
        w = 0.5 * np.exp(-(d / radius_w) ** 2)
        f = np.where(f < 1.0, np.power(f, 1.0 - w), f)
        f = np.where(lens_mask > 0.5, np.sqrt(gr)[:, None] * np.ones_like(f), f)
    if body_mask is not None:
        f = np.where(body_mask > 0.5, 1.0, f)
    lin = to_lin(rgba) * f[..., None]
    out = np.asarray(rgba).copy()
    out[..., :3] = to_srgb8(lin)
    return out


def despeckle(rgba, mask, keep=0.35):
    """Calms an even salt-and-pepper speckle (checklist item 9) on a painted face: each pixel goes to its
    3 x 3 median plus keep x its difference from it, so isolated flecks go and scuffs, grime and edges
    (several pixels across) stay."""
    a = np.asarray(rgba).astype(np.float64)
    out = a.copy()
    m = mask > 0.5
    for c in range(3):
        med = ndimage.median_filter(a[..., c], size=3)
        out[..., c] = np.where(m, med + keep * (a[..., c] - med), a[..., c])
    return np.clip(out + 0.5, 0, 255).astype(np.uint8)
