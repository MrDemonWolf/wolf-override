"""Round 9 cleanup (add7 fix round 2): the cut concrete section into the front layer.

Codex's paint (codex/paint-cut9b/out/cut9b-painted.png, kept untouched with its C2PA chunk; a
resampled 1024 copy is used, measured shift 0, 0) becomes material detail only: per part, the
high-pass of its luma inside the design mask, clamped. Every value is the part's albedo times the
design light (p2.shade, as every round since 3) times one constant per part that holds the part's
mean to its target, so the section stays at or below the column's value (review: 'keep its value
at or below the column's'). Chroma is the design's (cool concrete, galvanised steel).

Composite: round 8's front layer (fix1/door/layers/portal-front.png), the section over it (it covers
the old 0.15 m curb whole), and in the curb's old shadow zone the new footprint contact shadow on the
corridor side (0.70, 0.14 m) and a faint one past the plant-room foot. Outside that zone every pixel
is round 8's.
Writes add7/fix2/door/layers/portal-front.png and report9.json.
"""
from __future__ import annotations

import json
import os
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cut9  # noqa: E402
from cut9 import p2, p4, A_E, T  # noqa: E402
from common import to_srgb_u8, from_srgb_u8  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
F2 = os.path.abspath(os.path.join(ROOT, ".."))
D = os.path.join(ROOT, "design")
J = os.path.join(F2, "codex", "paint-cut9b")  # paint-cut9 was the 0.42 m try, superseded (its design: door/work-042/design)
R8 = os.path.join(F2, "..", "fix1", "door", "layers", "portal-front.png")
M6_ALPHA = os.path.join(F2, "..", "..", "design", "portal6", "masks", "front--ALPHA.png")
OUT = os.path.join(ROOT, "layers")
LUM = np.array([0.2126, 0.7152, 0.0722])
SHIFT = (0, 0)

# per part: target mean sRGB luma in the layer (in game about 0.8x: the grade), detail sigma, clamp
TARGETS = {
    "cut_face": (27.5, 5.0, (0.86, 1.14)),
    "cut_face_damp": (22.5, 4.0, (0.88, 1.12)),
    "cut_ties": (21.0, None, None),
    "cut_joint_face0": (15.0, None, None), "cut_joint_face1": (15.0, None, None),
    "cut_joint_top0": (18.0, None, None), "cut_joint_top1": (18.0, None, None),
    "cut_top": (35.0, 5.0, (0.88, 1.12)),
    "cut_angle_top": (47.0, 2.0, (0.82, 1.22)),
    "cut_angle_face": (41.0, 2.0, (0.84, 1.18)),
    "cut_angle_far": (44.0, 2.0, (0.84, 1.18)),
    "cut_anchors": (12.0, None, None),
}


def mask(n):
    return np.asarray(Image.open(os.path.join(D, "masks", f"front--{n}.png")).convert("L")).astype(float) / 255.0


def lum_srgb(lin):
    return (to_srgb_u8(lin).astype(float) * LUM).sum(-1)


def main():
    os.makedirs(OUT, exist_ok=True)
    panels = json.load(open(os.path.join(J, "panels.json")))
    x0, y0, x1, y1 = panels["panel"]["cvd"]
    ax, ay = panels["panel"]["at"]
    cx = Image.open(os.path.join(J, "out", "cut9b-painted.png")).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
    C = from_srgb_u8(np.asarray(cx).astype(float))
    C = np.roll(np.roll(C, SHIFT[1], 0), SHIFT[0], 1)
    Hc, Wc = 1900, 1232
    cl = np.zeros((Hc, Wc))
    cl[y0:y1, x0:x1] = (C[ay:ay + (y1 - y0), ax:ax + (x1 - x0)] * LUM).sum(-1)
    des = np.asarray(Image.open(os.path.join(D, "design-cut.png")).convert("RGBA"))
    dlin = from_srgb_u8(des[..., :3].astype(float))
    parts = cut9.parts()
    rep = {"parts": {}}
    lin = np.zeros((Hc, Wc, 3))
    alpha = np.zeros((Hc, Wc))
    _, _, face_h = p2.face_plane(0.0).points()
    for p in parts:
        m = mask(p.name)
        if p.name == "cut_face_damp":
            # the damp band covers the face's own soft foot edge too (no lighter face pixel peeks
            # out under it)
            m = np.maximum(m, mask("cut_face") * np.clip((0.10 - face_h) / 0.01, 0, 1))
        sel = m > 0.001
        if not sel.any():
            continue
        target, sigma, clamp = TARGETS[p.name]
        col = dlin.copy()
        if sigma is not None:
            w = (m > 0.5).astype(float)
            y = np.maximum(cl, 1e-5)
            base = ndimage.gaussian_filter(y * w, sigma) / np.maximum(ndimage.gaussian_filter(w, sigma), 1e-6)
            det = np.clip(np.where(w > 0, y / np.maximum(base, 1e-6), 1.0), *clamp)
            col = col * det[..., None]
        # the part's design colour under its design light: fill the part's own soft edge from inside
        inside = m > 0.5
        if inside.any():
            idx = ndimage.distance_transform_edt(~inside, return_distances=False, return_indices=True)
            col = col[idx[0], idx[1]]
        # one constant per part to its target mean (sRGB luma of the fully covered pixels)
        k = 1.0
        for _ in range(4):
            cur = lum_srgb(np.clip(col[inside] * k, 0, 1)).mean()
            k *= (from_srgb_u8(np.array([target])) / from_srgb_u8(np.array([cur])))[0]
        col = col * k
        lin = lin * (1 - m[..., None]) + col * m[..., None]
        alpha = m + alpha * (1 - m)
        rep["parts"][p.name] = {"target_luma": target, "k": round(float(k), 4), "mean_luma": round(float(lum_srgb(np.clip(col[inside], 0, 1)).mean()), 2),
                                "detail": None if sigma is None else {"sigma_px": sigma, "clamp": clamp}}
    # the old front layer, with the curb's shadow zone cleared and the new shadows in it
    old = np.asarray(Image.open(R8).convert("RGBA")).astype(float)
    olin = from_srgb_u8(old[..., :3])
    oa = old[..., 3] / 255.0
    a_, t_, _ = p4.floor_coords(p2.CV)
    zone = (a_ <= A_E + 0.02) & ((t_ < 0) | (t_ > T))
    # never touch the column, the camera or anything round 8 drew outside the old curb's shadows:
    # in the zone, only pixels outside every designed front part (round 6's front ALPHA, plus round
    # 8's near head band and strap) are the old shadows, and only those are replaced
    parts6 = np.asarray(Image.open(M6_ALPHA).convert("L")).astype(float) / 255.0
    old_shadow = zone & (parts6 < 0.004) & (oa < 0.999)
    sh_c = cut9.contact_shadow(p2.CV)
    sh_p = np.where((a_ <= A_E + 0.02) & (t_ > T), 0.35 * np.exp(-np.clip(t_ - T, 0, 50) / 0.12), 0.0)
    sh = np.maximum(sh_c, sh_p)   # under the section too, so its soft edge never lifts a seam
    dark = from_srgb_u8(np.array([2.0, 4.0, 6.0]))
    base_lin = np.where(old_shadow[..., None], dark, olin)
    base_a = np.where(old_shadow, 0.0, oa)
    # new shadow under the old layer's other content (shadow first, then whatever round 8 had)
    sa = np.where(zone, sh, 0.0)
    comb_a = base_a + sa * (1 - base_a)
    comb_lin = (base_lin * base_a[..., None] + dark * (sa * (1 - base_a))[..., None]) / np.maximum(comb_a, 1e-6)[..., None]
    # the section over everything
    fa = alpha + comb_a * (1 - alpha)
    flin = (lin * alpha[..., None] + comb_lin * (comb_a * (1 - alpha))[..., None]) / np.maximum(fa, 1e-6)[..., None]
    # the junction of the section's plant-room arris with the column's chamfer (world x 812..825,
    # y 436..447): where the section's top meets the chamfered corner of the column a notch up to
    # 2.5 world px wide shows the plant room through (the chamfer cuts the corner the section's top
    # runs into). It is grouted solid, as a real wall/pier junction would be: a pixel there with
    # opaque section/column pixels within 12 px (3 world px) on both sides of its row takes the
    # nearer opaque neighbour's colour, alpha 1.
    jy0, jy1 = int((436 - 150) * 4), int((447 - 150) * 4)
    jx0, jx1 = int((812 - 676) * 4), int((825 - 676) * 4)
    notch = 0
    for y in range(jy0, jy1):
        for x in range(jx0, jx1):
            if fa[y, x] >= 0.997:
                continue
            lo = [d for d in range(1, 13) if fa[y, x - d] >= 0.997]
            hi = [d for d in range(1, 13) if fa[y, x + d] >= 0.997]
            if lo and hi:
                src = x - lo[0] if lo[0] <= hi[0] else x + hi[0]
                flin[y, x] = flin[y, src]
                fa[y, x] = 1.0
                notch += 1
    rep["junction_notch_px_closed"] = notch
    rgba = np.dstack([to_srgb_u8(flin), (np.clip(fa, 0, 1) * 255 + 0.5).astype(np.uint8)])
    rgba[fa <= 0.0] = 0
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "portal-front.png"))
    changed = np.abs(rgba.astype(int) - old.astype(int)).max(-1) > 0
    ys, xs = np.nonzero(changed)
    rep["changed_px"] = int(changed.sum())
    rep["changed_bbox_cvd"] = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]
    rep["changed_bbox_world"] = [676 + xs.min() / 4, 150 + ys.min() / 4, 676 + (xs.max() + 1) / 4, 150 + (ys.max() + 1) / 4]
    rep["old_shadow_px_replaced"] = int(old_shadow.sum())
    rep["codex"] = {"file": "codex/paint-cut9b/out/cut9b-painted.png", "used_as": "luma high-pass detail per part, clamped", "shift": SHIFT}
    json.dump(rep, open(os.path.join(OUT, "report9.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
