"""Fix round 5 (v6) deterministic cleanup. No new image-tool paint: every new pixel carries paint
already in the slice (REAL-LOOK section 4, step 3). Inputs: layers/v5/* (round 4's layers) and
design/portal6 (the lamp conduit's elbow, run, strap and corner into the camera's wall plate).

Front layer (must 1, the lamp conduit's top end):
  * the old conduit above the new elbow (v5 ran it straight up to 4.40 m and capped it in mid-air) is
    painted out: the end face's own painted concrete from 12 px to the right on the same rows (clear
    of every part), its broad light matched to the face's light there (12 px low-pass), feathered;
  * the elbow, the run across the end face, and the piece round the arris into the camera's wall
    plate are painted with the vertical conduit's own painted steel: its measured cross-profile
    (wall shadow line, lit edge, highlight, body, far edge, cast shadow), laid across the run with the
    lit side up (the corridor fittings are above it; the wall pack below faces down) and blended
    round the elbow from the vertical's profile to the run's; the conduit's cast shadow falls on the
    concrete below the run;
  * the saddle strap: the conduit's highlight steel (STEEL_WORN), lit top, darker lower half,
    a one-pixel shadow line under it.
Wall layer (should 3, the pale strip under the camera housing):
  * the wall layer still carried a ghost of the camera's silhouette from an earlier design: a pale
    fill with a dark outline at design x 368..470, y 466..514, offset from the camera now drawn
    in front of it, so its lower edge showed under the housing (lit from below, with no source) and a
    pale patch showed above the arm. It is painted out with the wall's own concrete from 52 px
    above (clean wall), its broad light matched to the wall's light there, feathered.
Far plate (should 2, the tank's right shoulder):
  * high-bay B hangs over the tank's right half, about 2 m behind it and 0.35 m above its crown. Its
    light grazes the shell's limb from behind: a faint rim along the shell's right silhouette, 1-2 px
    wide, strongest under the head and fading down the shell (e-fold 110 px) and in from the edge
    (e-fold 0.9 px, at most 4 px), in B's cool white, added in linear light. Nothing else in the plate changes.
Writes layers/v6/ and layers/report6.json.
"""
from __future__ import annotations

import json
import os
import shutil
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from imgkit import lum, to_lin, to_srgb  # noqa: E402
from cleanup2 import mask, rgba, save_rgba, visible_masks, spill_check  # noqa: E402

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "design"))  # the design tools (tools/design/)
import portal6 as p6  # noqa: E402
import portal2 as p2  # noqa: E402

D5 = os.path.join(R, "design", "portal5")
D6 = os.path.join(R, "design", "portal6")
V5 = os.path.join(R, "layers", "v5")
OUT = os.path.join(R, "layers", "v6")
M2 = os.path.join(R, "design", "far-patch2", "masks")
FX0 = 1112
CVD = p6.CVD

# the vertical conduit's measured cross-profile (layers/v5/portal-front.png, mean over its rows; design
# px from its centre at x 519.5, + toward the right/outer side), sRGB
V_PROF_X = np.array([-3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5])
# the run's profile, + upward (the lit side up), built from the same samples: top edge, highlight,
# body, far edge, then the cast shadow line on the wall below
H_PROF_X = np.array([3.5, 2.5, 1.5, 0.5, -0.5, -1.5, -2.5, -3.5, -4.5])


def affine_side(a: float):
    """Design px <-> (t, h) on the side plane at a (an affine fit, exact enough over 1 m)."""
    def px(t, h):
        x, y = p2.scr(p2.pt(a, h, t))
        return np.array([(x - CVD.x0) * CVD.ppw, (y - CVD.y0) * CVD.ppw])
    o = px(0.0, 4.0)
    et = px(1.0, 4.0) - o
    eh = px(0.0, 5.0) - o
    M = np.array([et, eh]).T
    Mi = np.linalg.inv(M)
    return o, Mi, M


def front(report: dict) -> None:
    rgb, a = rgba(os.path.join(V5, "portal-front.png"))
    H, W = a.shape
    parts = p6.front_parts_v6()
    names = [p.name for p in parts]
    m6 = {n: mask(os.path.join(D6, "masks", f"front--{n}.png")) for n in names}
    vis = visible_masks(names, m6)
    old = mask(os.path.join(D5, "masks", "front--lamp_conduit_up.png"))
    newc = np.clip(sum(m6[n] for n in ("lamp_conduit_up", "lamp_conduit_elbow", "lamp_conduit_run", "lamp_conduit_corner", "lamp_conduit_strap")), 0, 1)
    # the vertical's profile, measured (rows well inside its v5 run)
    ys, xs = np.nonzero(old > 0.5)
    rows = slice(ys.min() + 10, ys.max() - 10)
    xc = 519.5
    prof_v = np.stack([rgb[rows, int(xc + d), :].mean(0) for d in V_PROF_X])
    s = {d: prof_v[i] for i, d in enumerate(V_PROF_X)}
    wall_ref = rgb[rows, 511:514, :].mean((0, 1))  # the bare end face beside it
    # top to bottom: bare wall, the lit top edge, highlight, body, lower body, dark lower edge, then the
    # cast shadow line on the wall and its soft fall back to the wall
    prof_h = np.stack([wall_ref, (s[0.5] + wall_ref) / 2, s[0.5], s[1.5], s[-0.5], s[-1.5], s[-2.5], s[4.5], (s[5.5] + wall_ref) / 2])
    # 1) paint out the old conduit above the elbow's start (and its shadow lines)
    o, Mi, M = affine_side(p6.A_C)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
    rel = np.stack([xx - o[0], yy - o[1]], -1)
    th = rel @ Mi.T
    T, Hh = th[..., 0], th[..., 1] + 4.0  # the fit's origin is at h 4.0 m
    top_new = p6.HC - p6.R_EL
    zone = ndimage.binary_dilation(old > 0.02, iterations=1)
    zone = ndimage.binary_dilation(zone, structure=np.ones((1, 9))) & (Hh > top_new - 0.004) & (yy >= ys.min() - 4)
    zone &= vis["pier_end"] > 0.5
    src = np.roll(rgb, -12, 1)
    lin, lsrc = to_lin(rgb), to_lin(src)
    face = (vis["pier_end"] > 0.9) & ~ndimage.binary_dilation(old > 0.02, structure=np.ones((3, 11)))
    def lp(v, m, sg=12.0):
        return ndimage.gaussian_filter(v * m, sg) / np.maximum(ndimage.gaussian_filter(m.astype(float), sg), 1e-6)
    fm = face.astype(float)
    Lf = lp(lum(lin), fm)
    Ls = np.roll(Lf, -12, 1)
    fill = to_srgb(lsrc * (Lf / np.maximum(Ls, 1e-6))[..., None])
    zf = ndimage.gaussian_filter(zone.astype(float), 0.7) * (vis["pier_end"] > 0.5)
    zf = np.maximum(zf, zone.astype(float))
    rgb = rgb * (1 - zf[..., None]) + fill * zf[..., None]
    report["front_erased_px"] = int(zone.sum())
    # 2) paint the new conduit: d (design px, + outer / up) and the blend weight w (0 vertical, 1 run)
    pxm = np.linalg.norm(M[:, 1]) / 1.0  # design px per metre along h
    ptm = np.linalg.norm(M[:, 0])  # along t
    ct, ch = p6.TL - p6.R_EL, p6.HC - p6.R_EL
    rho = np.hypot(T - ct, Hh - ch)
    ang = np.arctan2(Hh - ch, T - ct)
    d_arc = (rho - p6.R_EL) * 0.5 * (pxm + ptm)
    w_arc = np.clip(ang / (np.pi / 2), 0, 1)
    d_run = (Hh - p6.HC) * pxm
    in_arc = (T >= ct - 0.003) & (Hh >= ch - 0.003)
    d = np.where(in_arc, d_arc, d_run)
    w = np.where(in_arc, w_arc, 1.0)

    def interp(prof, xs_, dd):
        order = np.argsort(xs_)
        return np.stack([np.interp(dd, xs_[order], prof[order, c]) for c in range(3)], -1)

    # the vertical's profile is indexed +right = +outer; the run's +up = +outer
    col_v = interp(prof_v, V_PROF_X, d)
    col_h = interp(prof_h, H_PROF_X, d)
    col = col_v * (1 - w[..., None]) + col_h * w[..., None]
    paint = np.clip(sum(vis[n] for n in ("lamp_conduit_elbow", "lamp_conduit_run", "lamp_conduit_corner")), 0, 1)
    # the vertical's own new top (its last 3 px under the elbow) keeps its painted pixels
    # cast shadow on the concrete below the run and outside the elbow's inner side
    sh_band = (d < -1.0) & (d > -5.0) & ((Hh <= p6.HC) | in_arc) & (T >= p6.T_C - 0.01) & (T <= p6.TL + 0.03) & (Hh > ch - 0.1)
    sh_band &= (paint < 0.05) & (newc < 0.05) & (vis["pier_end"] > 0.5) & ~((T > p6.TL - 0.02) & ~in_arc)
    shade = interp(prof_h, H_PROF_X, np.clip(d, -4.5, -2.5)) / np.maximum(wall_ref, 1)[None, None, :]
    shade = np.where(sh_band[..., None], np.clip(shade, 0.55, 1.0), 1.0)
    rgb = rgb * shade
    # where the elbow is still near-vertical, the vertical's own shadow line on its outer side carries
    # on round it, fading as the elbow turns (the run's top side has none: its light is above it)
    ob = in_arc & (d > 2.0) & (d < 4.5) & (paint < 0.05) & (newc < 0.05) & (vis["pier_end"] > 0.5)
    ratio = interp(prof_v, V_PROF_X, np.clip(d + 1.5, 3.5, 5.5)) / np.maximum(wall_ref, 1)[None, None, :]
    ow = np.where(ob, (1 - w) ** 1.5, 0.0)[..., None]
    rgb = rgb * (1 - ow + ow * np.clip(ratio, 0.55, 1.0))
    rgb = rgb * (1 - paint[..., None]) + col * paint[..., None]
    # 3) the strap
    st = vis["lamp_conduit_strap"]
    sy = np.nonzero(st > 0.5)[0]
    top_half = yy < (sy.min() + sy.max()) / 2.0
    hi = s[0.5] * 1.12
    strap_col = np.where(top_half[..., None], hi, s[-0.5] * 0.95)
    rgb = rgb * (1 - st[..., None]) + strap_col * st[..., None]
    under = (np.roll(st > 0.5, 1, 0) & (st < 0.5)) & (vis["pier_end"] > 0.5)
    rgb = np.where(under[..., None], rgb * 0.7, rgb)
    a = np.maximum(a, np.clip(paint + st, 0, 1))
    save_rgba(rgb, a, os.path.join(OUT, "portal-front.png"))
    report["front"] = {
        "vertical_profile_srgb": {str(k): [round(float(v), 1) for v in s[k]] for k in V_PROF_X},
        "new_conduit_px": int((paint > 0.5).sum()), "strap_px": int((st > 0.5).sum()), "shadow_px": int(sh_band.sum()), "outer_shadow_px": int(ob.sum()),
        "run_mean_luma": round(float(lum(rgb[vis["lamp_conduit_run"] > 0.9]).mean()), 1),
        "vertical_mean_luma": round(float(lum(rgb[vis["lamp_conduit_up"] > 0.9]).mean()), 1),
        "old_conduit_left_above_elbow_px": int(((old > 0.5) & (Hh > top_new + 0.01) & (newc < 0.05) & (np.abs(lum(rgb) - lum(fill)) > 6)).sum()),
        "spill": spill_check(rgb, a),
    }


def wall(report: dict) -> None:
    rgb, a = rgba(os.path.join(V5, "portal-wall.png"))
    H, W = a.shape
    x0, x1, y0, y1 = 366, 472, 464, 516
    zone = np.zeros((H, W), bool)
    zone[y0:y1, x0:x1] = True
    zone &= a > 0.999
    lin = to_lin(rgb)
    L = lum(lin)
    clean = (a > 0.999) & ~ndimage.binary_dilation(zone, iterations=3)
    def lp(v, m, sg=10.0):
        return ndimage.gaussian_filter(v * m, sg) / np.maximum(ndimage.gaussian_filter(m.astype(float), sg), 1e-6)
    Lb = lp(L, clean.astype(float))
    DY = 52
    src = np.roll(lin, DY, 0)
    Ls = np.roll(Lb, DY, 0)
    fill = to_srgb(src * (Lb / np.maximum(Ls, 1e-6))[..., None])
    z = ndimage.gaussian_filter(zone.astype(float), 1.5)
    z = np.maximum(z, ndimage.binary_erosion(zone, iterations=2).astype(float)) * (a > 0.999)
    before = rgb.copy()
    rgb = rgb * (1 - z[..., None]) + fill * z[..., None]
    save_rgba(rgb, a, os.path.join(OUT, "portal-wall.png"))
    Lr = lum(rgb)
    hp = Lr - ndimage.gaussian_filter(Lr, 4)
    ring = ndimage.binary_dilation(zone, iterations=14) & ~ndimage.binary_dilation(zone, iterations=3) & (a > 0.999)
    edges = np.hypot(ndimage.sobel(lum(before), 0), ndimage.sobel(lum(before), 1))
    edges2 = np.hypot(ndimage.sobel(Lr, 0), ndimage.sobel(Lr, 1))
    report["wall_ghost"] = {"zone_design_px": [x0, y0, x1, y1], "source_offset_px": [0, -DY],
                            "mean_luma_zone_before": round(float(lum(before[zone]).mean()), 1), "mean_luma_zone_after": round(float(Lr[zone].mean()), 1),
                            "mean_luma_ring": round(float(Lr[ring].mean()), 1),
                            "hp_sd_zone_after": round(float(hp[zone].std()), 2), "hp_sd_ring": round(float(hp[ring].std()), 2),
                            "edge_p99_zone_before": round(float(np.percentile(edges[zone], 99)), 1), "edge_p99_zone_after": round(float(np.percentile(edges2[zone], 99)), 1),
                            "edge_p99_ring": round(float(np.percentile(edges2[ring], 99)), 1)}


def far(report: dict) -> None:
    img = np.asarray(Image.open(os.path.join(V5, "corridor-far.png")).convert("RGB")).astype(np.float64)
    H, W = img.shape[:2]
    def full(n):
        m = np.asarray(Image.open(os.path.join(M2, n + ".png")).convert("L")).astype(np.float64) / 255.0
        return np.pad(m, ((0, H - m.shape[0]), (FX0, W - FX0 - m.shape[1])))
    shell = full("tank_shell")
    front_of = np.zeros((H, W))
    for n in ("tank_seam0", "tank_seam1"):
        front_of = np.maximum(front_of, full(n))
    sm = (shell > 0.5) & (full("tank_head") < 0.5)  # the visible shell (the dished head is in front of its top)
    # distance in from the shell's right silhouette, per row
    ys, xs = np.nonzero(sm)
    right = np.full(H, -1)
    for y in np.unique(ys):
        right[y] = xs[ys == y].max()
    yy, xx = np.mgrid[0:H, 0:W]
    din = right[yy] - xx
    head_y = int(np.nonzero(full("tank_head") > 0.5)[0].max())
    # only rows where the silhouette is the shell's own (under the head, not a sliver beside it)
    fr = np.full(H, -1)
    fys, fxs = np.nonzero(shell > 0.5)
    for y in np.unique(fys):
        fr[y] = fxs[fys == y].max()
    own_edge = (right >= 0) & (right >= fr - 1)
    ok = sm & (din >= 0) & (din <= 3) & own_edge[yy]
    rim = np.where(ok, np.exp(-np.clip(din, 0, 3) / 0.9), 0.0)
    rim *= np.exp(-np.clip(yy - head_y, 0, None) / 110.0)
    lin = to_lin(img)
    b_col = np.array([0.93, 0.96, 1.0])
    k = 0.014  # linear light added at the top of the rim (sRGB about 15 -> 38 on the shell)
    lin2 = lin + (rim * k)[..., None] * b_col[None, None, :]
    out = to_srgb(lin2)
    Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "corridor-far.png"))
    Lo, Ln = lum(img), lum(out)
    band = sm & (din <= 1)
    report["tank_rim"] = {"head_bottom_y": head_y, "rim_px_changed": int((np.abs(Ln - Lo) > 0.5).sum()),
                          "right_edge_luma_before_after": {str(y): [round(float(Lo[y, right[y]]), 1), round(float(Ln[y, right[y]]), 1)] for y in (head_y + 5, 380, 450, 520, 600)},
                          "changed_bbox": [int(xx[np.abs(Ln - Lo) > 0.5].min()), int(yy[np.abs(Ln - Lo) > 0.5].min()), int(xx[np.abs(Ln - Lo) > 0.5].max()), int(yy[np.abs(Ln - Lo) > 0.5].max())],
                          "lit_left_third_luma_unchanged": bool(np.array_equal(np.clip(out + 0.5, 0, 255).astype(np.uint8)[:, :1780], img.astype(np.uint8)[:, :1780])),
                          "band_mean_luma_after": round(float(Ln[band].mean()), 1)}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    report: dict = {}
    front(report)
    wall(report)
    far(report)
    for n in ("portal-frame.png", "portal-curtain.png", "portal-curtain-open.png", "lens.png", "bypass-wheel.png"):
        shutil.copy(os.path.join(V5, n), os.path.join(OUT, n))
    json.dump(report, open(os.path.join(R, "layers", "report6.json"), "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
