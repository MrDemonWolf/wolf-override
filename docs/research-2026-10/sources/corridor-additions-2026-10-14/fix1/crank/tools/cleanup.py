"""Crank pose cleanup (add7 fix round 1, item f). Codex's repaint (codex/paint-crank8/out/crank8-painted.png,
kept untouched with its C2PA chunk; a resampled copy is used) is taken ONLY inside the repair zones
(arms, where the arms left the body, the hip seam). Everywhere else each frame is the rig, which is
the in-game sprite's own pixels; the legs below the hip seam are the sprite's pixels exactly.

Steps per frame: resample the panel to the 384 frame; register it to the rig on the protected pixels
(integer shift search); key the magenta field to alpha (and drop the cyan guide line, inpainting it
where it crossed a glove); match Codex's colour to the rig's inside the zone (per-channel mean and
spread); composite with a 2 px feather; restore the legs exactly; measure the gloves on the rim.
Writes crank/frames/frame-A.png, frame-B.png (384x384), crank/frames/report.json.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rig as R  # noqa: E402
import codex_inputs as CI  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
J = CI.J
OUT = os.path.join(ROOT, "frames")
LUM = np.array([0.2126, 0.7152, 0.0722])


def key_magenta(rgb):
    """rgb in 0..1 over magenta: (alpha, foreground)."""
    k = (np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1])
    a = np.clip(1.0 - (k - 0.08) / 0.75, 0, 1)
    bg = np.array([1.0, 0.0, 1.0])
    fg = np.where(a[..., None] > 0.05, (rgb - (1 - a[..., None]) * bg) / np.maximum(a[..., None], 0.05), 0)
    return a, np.clip(fg, 0, 1)


def main():
    os.makedirs(OUT, exist_ok=True)
    panels = json.load(open(os.path.join(J, "panels.json")))["panels"]
    im = Image.open(os.path.join(J, "out", "crank8-painted.png")).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
    big = np.asarray(im).astype(float) / 255.0
    src = np.asarray(Image.open(R.SRC).convert("RGBA")).astype(float) / 255.0
    srcp = np.zeros((384, 384, 4))
    srcp[:, R.PAD:R.PAD + 256] = src
    rigj = json.load(open(os.path.join(ROOT, "rig", "rig.json")))
    rep = {"frames": {}}
    for key in ("A", "B"):
        rigf = np.asarray(Image.open(os.path.join(ROOT, "rig", f"frame-{key}.png")).convert("RGBA")).astype(float) / 255.0
        Z = CI.zones(key, (src[..., 3] * 255).astype(np.uint8))
        ax, ay = panels[key]["at"]
        side = panels[key]["px"]
        best = None
        prot = (rigf[..., 3] > 0.9) & ~ndimage.binary_dilation(Z, iterations=4)
        for dy in range(-6, 7):
            for dx in range(-6, 7):
                pnl = big[ay + dy:ay + dy + side, ax + dx:ax + dx + side]
                small = np.asarray(Image.fromarray((pnl * 255).round().astype(np.uint8)).resize((384, 384), Image.Resampling.LANCZOS)).astype(float) / 255.0
                err = np.abs((small * LUM).sum(-1) - (rigf[..., :3] * LUM).sum(-1))[prot].mean()
                if best is None or err < best[0]:
                    best = (err, dx, dy, small)
        err, dx, dy, small = best
        a, fg = key_magenta(small)
        # the cyan guide: background, inpainted where it crossed a glove
        cyan = (small[..., 1] > 0.55) & (small[..., 2] > 0.55) & (small[..., 0] < 0.45)
        cyan = ndimage.binary_dilation(cyan, iterations=1)
        body = (a > 0.5) & ~cyan
        filled = ndimage.binary_fill_holes(body)
        hole = filled & ~body
        if hole.any():
            idx = ndimage.distance_transform_edt(~body, return_distances=False, return_indices=True)
            fg[hole] = fg[idx[0][hole], idx[1][hole]]
            a[hole] = 1.0
        a[cyan & ~filled] = 0.0
        # colour match inside the zone (rig vs Codex, both opaque)
        both = Z & (a > 0.9) & (rigf[..., 3] > 0.9)
        gain, off = np.ones(3), np.zeros(3)
        for c in range(3):
            ms, ss_ = fg[both, c].mean(), fg[both, c].std()
            mr, sr = rigf[both, c, ].mean(), rigf[both, c].std()
            gain[c] = np.clip(sr / max(ss_, 1e-4), 0.8, 1.25)
            off[c] = mr - gain[c] * ms
        fgm = np.clip(fg * gain + off, 0, 1)
        # magenta despill: no pixel keeps more of both red and blue than its green allows
        ex = np.clip(np.minimum(fgm[..., 0], fgm[..., 2]) - fgm[..., 1], 0, None) * 1.3
        fgm[..., 0] -= ex
        fgm[..., 2] -= ex
        w = ndimage.gaussian_filter(Z.astype(float), 1.0)
        w = np.where(Z, np.maximum(w, 0.5), w)
        w = np.clip((w - 0.0) / 1.0, 0, 1)
        outa = rigf[..., 3] * (1 - w) + a * w
        outc = (rigf[..., :3] * rigf[..., 3:4] * (1 - w[..., None]) + fgm * a[..., None] * w[..., None]) / np.maximum(outa[..., None], 1e-4)
        # the legs below the hip seam, outside the zone: the sprite's own pixels, exactly
        rows = np.arange(384)[:, None]
        outa = np.where(outa < 0.04, 0.0, outa)
        # thin leftovers of the cut (a 2-3 px sliver of the trouser outline carried off with the far
        # hand) are removed by an opening outside the body and the glove: nothing under 5 px across
        # survives there; the glove core and everything the sprite itself covers are left alone
        T = rigj["frames"][key]["far_target"]
        yy, xx = np.mgrid[0:384, 0:384]
        keep = (np.hypot(xx - T[0], yy - T[1]) <= 13) | ndimage.binary_dilation(srcp[..., 3] > 0.5, iterations=1)
        Rg = (yy >= 165) & (yy <= 225) & (xx >= 215) & (xx <= 285) & ~keep
        solid = outa > 0.5
        opened = ndimage.binary_opening(solid, structure=np.ones((5, 5)))
        sliver = Rg & solid & ~ndimage.binary_dilation(opened, iterations=1)
        outa[sliver] = 0.0
        rep.setdefault("sliver_px", {})[key] = int(sliver.sum())
        # the legs below the hip seam, outside the zone: the sprite's own pixels, exactly (last)
        legs = (rows >= 184) & ~ndimage.binary_dilation(Z, iterations=2)
        outc[legs] = srcp[legs, :3]
        outa[legs] = srcp[legs, 3]
        out = np.dstack([np.clip(outc, 0, 1), np.clip(outa, 0, 1)])
        Image.fromarray((out * 255).round().astype(np.uint8), "RGBA").save(os.path.join(OUT, f"frame-{key}.png"))
        # gloves on the rim: dark neutral opaque pixels near each target
        hub = (rigj["hub"][0] + R.PAD, rigj["hub"][1])
        res = {"registration_shift_1024px": [dx, dy], "registration_err": round(float(err), 4), "colour_gain": np.round(gain, 3).tolist(), "colour_offset": np.round(off, 3).tolist()}
        for g in ("far", "near"):
            T = rigj["frames"][key][f"{g}_target"]
            yy, xx = np.mgrid[0:384, 0:384]
            lum = (out[..., :3] * LUM).sum(-1)
            sat = out[..., :3].max(-1) - out[..., :3].min(-1)
            m = (out[..., 3] > 0.8) & (lum < 0.25) & (sat < 0.12) & (np.hypot(xx - T[0], yy - T[1]) <= 16)
            ys, xs = np.nonzero(m)
            cen = (xs.mean() + 0.5, ys.mean() + 0.5) if xs.size else (np.nan, np.nan)
            res[f"{g}_glove"] = {"target": [round(v, 2) for v in T], "centroid": [round(float(v), 2) for v in cen],
                                 "off_rim_world_px": round(abs(float(np.hypot(cen[0] - hub[0], cen[1] - hub[1])) - rigj["rim"]) * R.SCALE, 2),
                                 "from_target_world_px": round(float(np.hypot(cen[0] - T[0], cen[1] - T[1])) * R.SCALE, 2), "px": int(xs.size)}
        legs_src = (rows >= 184) & (srcp[..., 3] > 0) & ~ndimage.binary_dilation(Z, iterations=2)
        res["legs_identical_px"] = int((np.abs(np.round(out * 255) - np.round(srcp * 255)).max(-1)[legs_src] == 0).sum())
        res["legs_px"] = int(legs_src.sum())
        rep["frames"][key] = res
    json.dump(rep, open(os.path.join(OUT, "report.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
