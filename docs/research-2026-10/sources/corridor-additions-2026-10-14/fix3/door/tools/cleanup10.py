"""Round 10 cleanup (add7 fix round 3): the cut wall as a clean section poche in the front layer.

Copied from fix2/door/tools/cleanup9.py, changed where marked R10. Round 9 painted the section as a
built knee wall (Codex detail, steel angles, anchors, ties, joints, a damp foot). Round 10 (Nathanial,
"Show it as a clean cutaway") fills cut10's two parts with ONE flat poche colour: a section fill is
flat by definition, and at its value (about sRGB 15) any material grain under 8 % is below one 8-bit
level, so no paint is used and there is no Codex session this round. The composite is cleanup9's:
round 8's front layer, the old curb's shadow zone cleared, the new (softer) footprint shadow, the
poche over everything, and the section/column junction grouted solid with the column's own pixels.
Writes add7/fix3/door/layers/portal-front.png and report10.json.
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
import cut10  # noqa: E402
from cut10 import p2, p4, A_E, T  # noqa: E402
import cut9  # noqa: E402
from common import to_srgb_u8, from_srgb_u8  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
F3 = os.path.abspath(os.path.join(ROOT, ".."))
D = os.path.join(ROOT, "design")
R8 = os.path.join(F3, "..", "fix1", "door", "layers", "portal-front.png")
M6_ALPHA = os.path.join(F3, "..", "..", "design", "portal6", "masks", "front--ALPHA.png")
OUT = os.path.join(ROOT, "layers")
LUM = np.array([0.2126, 0.7152, 0.0722])


def mask(n):
    return np.asarray(Image.open(os.path.join(D, "masks", f"front--{n}.png")).convert("L")).astype(float) / 255.0


def lum_srgb(lin):
    return (to_srgb_u8(lin).astype(float) * LUM).sum(-1)


def main():
    os.makedirs(OUT, exist_ok=True)
    Hc, Wc = 1900, 1232
    rep = {"parts": {}}
    # R10: one flat poche over the cut (face and cut plane), no paint
    m = np.maximum(mask("cut_face"), mask("cut_top"))
    lin = np.zeros((Hc, Wc, 3)) + np.array(cut10.POCHE)
    alpha = m
    inside = m > 0.5
    rep["parts"]["poche"] = {"px_cvd": int(inside.sum()), "srgb": [int(v) for v in to_srgb_u8(np.array([cut10.POCHE]))[0]],
                             "mean_luma_layer": round(float(lum_srgb(lin[inside]).mean()), 2)}
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
    sh_c = cut10.contact_shadow(p2.CV)  # R10: softer
    sh_p = np.where((a_ <= A_E + 0.02) & (t_ > T), 0.35 * np.exp(-np.clip(t_ - T, 0, 50) / 0.12), 0.0)  # past the plant-room foot, as round 9
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
    rep["codex"] = None  # R10: no paint; a flat section fill
    json.dump(rep, open(os.path.join(OUT, "report10.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
