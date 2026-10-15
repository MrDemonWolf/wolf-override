"""Fix round 3 (review r3 S3, human r3): the thrown blast leaf, after the grade (jgrade2.py) and before the
install. Scratch only; deterministic (NumPy, SciPy, Pillow). Reads and rewrites layers/graded/blown/lying.png.

Review r3: "the thrown leaf reads as a clean slab or pallet: flat, crisp edges, no visible bow, crushed
corner, scrape or soot at play zoom. ASTM F2927 Category IV (SDI 133) is a door torn off and thrown as
flying debris. Show the bow in its silhouette (at least 3 world px), crush the landing corner, scrape the
leading edge and add soot near the latch." Human r3: "its left corner lies across the cross-wall's foot".

1. The dish. jdesign.py dished the leaf 90 mm (LY_BOW), too little to read. The overpressure that tore the
   leaf out pushed its middle away from the charge, so it lies approach face up, dished: it rests on its
   middle and on the chunk under its right end (as before: the right end's underside stays at 0.147 m),
   and its left end now stands 0.174 m off the deck (was 0.047). The height change at every point of the
   leaf comes from jdesign's own geometry (_ly_bottom with LY_BOW 0.16, LY_LIFT -0.027 against 0.09, 0.10):
   a vertical move in the room projects to a vertical move on screen, so each painted pixel moves up by
   that change x the camera's px per metre at its depth; the deck under the lifted end shows its contact
   shadow. The silhouette sags about 7 world px against the chord between its ends.
2. Clear of the wall's foot: the leaf, its contact shadow and the chunk under its right end lie SHIFT_X
   world px further along the lane (thrown 0.4 m further), so its left end is clear of the cross-wall's
   stub. The front rubble stays where it fell.
3. The landing corner, on the chunk (it was thrown toward the right and came down on it first): the
   corner crushed in a ragged 0.10-0.14 m chamfer, the torn skin's edge bright, the crumpled skin and the
   concrete fill behind it dark.
4. Scrapes: it slid to the right on the deck, so the near edge's lower half and the up face's leading
   (right) end carry bare-steel scrapes along the slide.
5. Soot: the approach face (now up) near the latch edge (the far side), heaviest by the bolts, falling off
   toward the hinge edge.
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.spatial import cKDTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jdesign as JD  # noqa: E402
import jmodel as M  # noqa: E402

BOW_NEW, LIFT_NEW = 0.16, -0.027
SHIFT_X = 16.0      # world px (its edge and soft shadow 16-17 px clear of the stub's lit edge at every row, measured on render.sh j04; r2 overlapped it)
PAD_RIGHT = 20.0    # world px added to the canvas on the right
PPW = M.CV.ppw
L = os.path.join(M.WORK, "layers", "graded", "blown")
DM = os.path.join(M.WORK, "design", "masks")
LEAF_PARTS = ("leaf_up_face", "leaf_hinge_edge", "leaf_end", "leaf_seam", "leaf_spindle_cap", "bent_bolt", "hinge_")


def mask(prefixes):
    u = None
    for f in sorted(os.listdir(DM)):
        if f.startswith("lying--") and any(f[7:-4].startswith(p) for p in prefixes):
            m = np.asarray(Image.open(os.path.join(DM, f))) > 127
            u = m if u is None else (u | m)
    return u


def bottom(u, v, bow, lift):
    x = 2.0 * u / JD.LY_LEN - 1.0
    return lift * (u / JD.LY_LEN) + JD.LY_LIFT_V * (v / JD.LY_WID) - bow * (1.0 - x * x)


def z0(bow, lift):
    us = np.linspace(0, JD.LY_LEN, 400)
    return -min(min(bottom(us, 0.0, bow, lift)), min(bottom(us, JD.LY_WID, bow, lift)))


def to_canvas(p):
    x, y = JD.scr(p)
    return (x - M.CV.x0) * PPW, (y - M.CV.y0) * PPW


def samples():
    """(u, v, up) samples over the leaf's visible faces, with their canvas positions (old geometry)."""
    pts, uvw = [], []
    for u in np.linspace(0, JD.LY_LEN, 260):
        for v in np.linspace(0, JD.LY_WID, 120):
            uvw.append((u, v, JD.LY_TH))
        for up in np.linspace(0, JD.LY_TH, 24):
            uvw.append((u, 0.0, up))
            uvw.append((u, -0.06, up))
    for v in np.linspace(0, JD.LY_WID, 120):
        for up in np.linspace(0, JD.LY_TH, 24):
            uvw.append((0.0, v, up))
            uvw.append((JD.LY_LEN, v, up))
    for (u, v, up) in uvw:
        pts.append(to_canvas(JD.ly_point(u, v, up)))
    return np.array(pts), np.array(uvw)


def main():
    im = np.asarray(Image.open(os.path.join(L, "lying.png")).convert("RGBA")).astype(np.float64)
    H, W = im.shape[:2]
    pad = int(PAD_RIGHT * PPW)
    leafm = ndimage.binary_dilation(mask(LEAF_PARTS), iterations=2) & (im[..., 3] > 0)
    shadm = ndimage.binary_dilation(mask(("leaf_shadow",)), iterations=2) & (im[..., 3] > 0) & ~leafm
    chunkm = ndimage.binary_dilation(mask(("prop_chunk",)), iterations=1) & (im[..., 3] > 0) & ~leafm
    rest = im.copy()
    rest[leafm | shadm | chunkm] = 0
    big = lambda: np.zeros((H, W + pad, 4))
    out = big()
    out[:, :W] = rest
    sx = int(round(SHIFT_X * PPW))

    # (u, v) per leaf pixel, from the old geometry
    pts, uvw = samples()
    tree = cKDTree(pts)
    ys, xs = np.nonzero(leafm)
    _, idx = tree.query(np.stack([xs + 0.5, ys + 0.5], -1))
    U, V, UP = uvw[idx, 0], uvw[idx, 1], uvw[idx, 2]
    z_old, z_new = z0(JD.LY_BOW, JD.LY_LIFT), z0(BOW_NEW, LIFT_NEW)
    dh = (bottom(U, np.clip(V, 0, JD.LY_WID), BOW_NEW, LIFT_NEW) + z_new) - (bottom(U, np.clip(V, 0, JD.LY_WID), JD.LY_BOW, JD.LY_LIFT) + z_old)
    # px per metre at each point's depth
    c, dl, dv = JD._ly_axes()
    depth = (c + (U[:, None] - JD.LY_LEN / 2) * dl + (V[:, None] - JD.LY_WID / 2) * dv)[:, 2]
    ppm = M.PXM * 38.0 / (38.0 + depth)
    dy = -dh * ppm * PPW  # canvas px (up is negative)
    dyf = np.zeros((H, W))
    dyf[ys, xs] = dy
    # a smooth field over the leaf (and a little beyond, for the inverse lookup)
    near = ndimage.distance_transform_edt(~leafm, return_indices=True)[1]
    dyfull = dyf[near[0], near[1]]

    # inverse warp of the leaf into its new place: dst (X, Y) <- src (X - sx, Y + dy(src))
    leaf = np.zeros_like(im)
    leaf[leafm] = im[leafm]
    pm = leaf.copy()
    pm[..., :3] *= pm[..., 3:4] / 255.0
    Yd, Xd = np.mgrid[0:H, 0:W + pad].astype(np.float64)
    Xs = Xd - sx
    inside = (Xs >= 0) & (Xs < W - 1)
    Xc = np.clip(Xs, 0, W - 1)
    Ys = Yd.copy()
    for _ in range(4):
        Ys = Yd - ndimage.map_coordinates(dyfull, [np.clip(Ys, 0, H - 1), Xc], order=1, mode="nearest")
    warped = np.stack([ndimage.map_coordinates(pm[..., k], [Ys, Xc], order=1, mode="constant", cval=0.0) for k in range(4)], -1)
    warped[~inside] = 0
    a = warped[..., 3:4] / 255.0
    warped[..., :3] = np.where(a > 1e-4, warped[..., :3] / np.maximum(a, 1e-4), 0)
    # the leaf's parameters at their new places (for the damage below)
    uvm = np.full((H, W + pad, 3), np.nan)
    for k, arr in enumerate((U, V, UP)):
        f = np.full((H, W), np.nan)
        f[ys, xs] = arr
        uvm[..., k] = ndimage.map_coordinates(np.nan_to_num(f, nan=-9.0), [Ys, Xc], order=0, mode="constant", cval=-9.0)
    uvm[warped[..., 3] < 1.0] = np.nan

    # 3. the landing corner (u = LEN, v = 0), crushed: a ragged chamfer
    rng = np.random.default_rng(31)
    Uu, Vv, Pp = uvm[..., 0], uvm[..., 1], uvm[..., 2]
    on = np.isfinite(Uu)
    d_corner = (JD.LY_LEN - Uu) + np.maximum(Vv, 0) + 0.35 * (JD.LY_TH - Pp)
    # smooth (the (u, v) per pixel comes from discrete samples): fill, blur, re-mask
    fill_idx = ndimage.distance_transform_edt(~on, return_indices=True)[1]
    d_corner = ndimage.gaussian_filter(np.nan_to_num(d_corner, nan=9.0)[fill_idx[0], fill_idx[1]], 2.5)
    d_corner = np.where(on, d_corner, 9.0)
    nz = ndimage.gaussian_filter(rng.normal(0, 1, (H, W + pad)), 5.0)
    rag = 0.12 + 0.018 * nz / max(np.abs(nz).max(), 1e-6)
    gone = on & (d_corner < rag - 0.03)
    gone = ndimage.binary_closing(ndimage.binary_opening(gone, iterations=2), iterations=2) & on
    edge_band = on & ~gone & ndimage.binary_dilation(gone, iterations=3)
    torn = edge_band & ~ndimage.binary_dilation(gone, iterations=1) | (on & ~gone & ndimage.binary_dilation(gone, iterations=1))
    torn &= ~ndimage.binary_dilation(gone, iterations=2) | ndimage.binary_dilation(gone, iterations=1)
    crumple = on & ~gone & ~torn & (d_corner < rag + 0.10)
    warped[gone, 3] = 0
    lin = lambda u8: np.where(u8 / 255.0 <= 0.04045, u8 / 255.0 / 12.92, ((u8 / 255.0 + 0.055) / 1.055) ** 2.4)
    srgb = lambda l: np.where(l <= 0.0031308, l * 12.92, 1.055 * np.clip(l, 0, 1) ** (1 / 2.4) - 0.055) * 255.0
    wl = lin(warped[..., :3])
    wl[torn] = np.clip(wl[torn] * 2.2 + 0.008, 0, 1)
    fall = np.clip((d_corner - rag) / 0.10, 0, 1)
    wl[crumple] = wl[crumple] * (0.5 + 0.5 * fall[crumple])[:, None]
    # 4. scrapes along the slide: the near (hinge) edge's lower half, and the up face's right end; each a
    # continuous anti-aliased line through the leaf's new shape (old point + the dish's lift + the shift)
    def new_canvas(u, v, up):
        x, y = to_canvas(JD.ly_point(u, v, up))
        vv = min(max(v, 0.0), JD.LY_WID)
        d_h = (bottom(u, vv, BOW_NEW, LIFT_NEW) + z_new) - (bottom(u, vv, JD.LY_BOW, JD.LY_LIFT) + z_old)
        dep = (c + (u - JD.LY_LEN / 2) * dl + (vv - JD.LY_WID / 2) * dv)[2]
        return x + sx, y - d_h * M.PXM * 38.0 / (38.0 + dep) * PPW
    acc = np.zeros((H, W + pad))
    strokes = [(0.0, rng.uniform(0.03, 0.13), rng.uniform(1.2, 2.0), rng.uniform(2.25, JD.LY_LEN - 0.12)) for _ in range(5)]
    strokes += [(rng.uniform(0.15, 1.6), JD.LY_TH, rng.uniform(1.7, 2.3), JD.LY_LEN - 0.15) for _ in range(5)]
    for (v0, up0, u0, u1) in strokes:
        for u in np.linspace(u0, u1, int((u1 - u0) * 400)):
            x, y = new_canvas(u, v0, up0)
            xi, yi = int(x), int(y)
            if 0 <= xi < W + pad - 1 and 0 <= yi < H - 1:
                fx, fy = x - xi, y - yi
                acc[yi, xi] += (1 - fx) * (1 - fy); acc[yi, xi + 1] += fx * (1 - fy)
                acc[yi + 1, xi] += (1 - fx) * fy; acc[yi + 1, xi + 1] += fx * fy
    # not over the hardware (hinge plates, knuckles, pins, bolts, spindle caps): scrapes are in the skin's paint
    hw_src = ndimage.binary_dilation(mask(("hinge_", "bent_bolt", "leaf_spindle_cap")), iterations=3).astype(np.float64)
    hw = ndimage.map_coordinates(hw_src, [Ys, Xc], order=0, mode="constant", cval=0.0) > 0.5
    lines_w = np.clip(ndimage.gaussian_filter(acc, 0.6) * 1.2, 0, 1) * (warped[..., 3] > 200) * ~gone * ~hw
    lines = lines_w > 0.05
    wl = wl * (1 + 0.9 * lines_w[..., None]) + 0.006 * lines_w[..., None]
    # 5. soot on the approach face by the latch edge
    face_up = on & (np.abs(Pp - JD.LY_TH) < 1e-3)
    soot = np.clip((Vv - (JD.LY_WID - 0.75)) / 0.75, 0, 1) ** 1.3
    soot *= 0.75 + 0.25 * np.clip(ndimage.gaussian_filter(rng.normal(0, 1, (H, W + pad)), 6.0) / 0.03, -1, 1)
    wl[face_up] = wl[face_up] * (1.0 - 0.75 * soot[face_up])[:, None]
    warped[..., :3] = srgb(wl)
    warped[gone, :3] = 0

    # the shadow and the chunk moved with it, then the rest, then the leaf over them
    moved = big()
    for m in (shadm, chunkm):
        lay = np.zeros((H, W + pad, 4))
        yy, xx = np.nonzero(m)
        ok = xx + sx < W + pad
        lay[yy[ok], xx[ok] + sx] = im[yy[ok], xx[ok]]
        if m is shadm:
            # the deck in the leaf's shade: soft-edged, not a black card, where the lifted end shows it
            lay[..., 3] = np.minimum(ndimage.gaussian_filter(lay[..., 3], 1.5 * PPW), 0.85 * 255.0)
        moved = over(lay, moved)
    base = over(out, moved)
    final = over(warped, base)
    Image.fromarray(np.clip(final + 0.5, 0, 255).astype(np.uint8), "RGBA").save(os.path.join(L, "lying.png"))
    lift_left = (bottom(0.0, 0.0, BOW_NEW, LIFT_NEW) + z_new)
    print({"left_end_underside_m": round(float(lift_left), 3), "right_end_underside_m": round(float(bottom(JD.LY_LEN, 0, BOW_NEW, LIFT_NEW) + z_new), 3),
           "max_dy_world_px": round(float(-dy.min() / PPW), 2), "shift_world_px": SHIFT_X, "crushed_px": int(gone.sum()), "torn_px": int(torn.sum()),
           "scrape_px": int(lines.sum()), "soot_px": int((face_up & (soot > 0.05)).sum())})


def over(top, bottom_):
    """'top' over 'bottom_' (straight-alpha RGBA in 0..255)."""
    at = top[..., 3:4] / 255.0
    ab = bottom_[..., 3:4] / 255.0
    ao = at + ab * (1 - at)
    rgb = np.where(ao > 1e-6, (top[..., :3] * at + bottom_[..., :3] * ab * (1 - at)) / np.maximum(ao, 1e-6), 0)
    return np.concatenate([rgb, ao * 255.0], -1)


if __name__ == "__main__":
    main()
