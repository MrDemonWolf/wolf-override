"""Deterministic cleanup of the Codex paint-overs (scratch only). The Codex originals are never
modified: each is read, registered to its edit target, sampled back onto the design canvas
(4 px per world px), and kept ONLY inside the construction's own masks. Then per part:
  - alpha is the design's exact alpha (silhouettes snap back; the doorway and the lamp glass stay 0);
  - large calm faces are calmed (broad light kept, fine texture reduced);
  - each part's mean value is held to the design's light plan (+-15 %), and its colour moved toward
    the design's (which carries the light's colour) and the room's cool palette;
  - edge pixels are decontaminated (no room colour fringes);
  - the designed contact shadows are composited.
Writes layers/<set>/<layer>.png at 4 px per world px plus a checks report.

usage: cleanup.py sealed|blown
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
import imgkit as K  # noqa: E402
import jmodel as M  # noqa: E402
from codex_inputs import TH, TW, TX0, TY0  # noqa: E402

TS = TW / (664.0 - 400.0)  # target px per world px (3.8788)
CODEX = os.path.join(M.WORK, "..", "codex")
DESIGN = os.path.join(M.WORK, "design")

# Faces that must stay calm (large plain surfaces) and how much fine texture they keep.
CALM = {"face_far_column": (5.0, 0.55), "face_upper": (5.0, 0.55), "col_end": (3.0, 0.6), "col_face_strip": (3.0, 0.6),
        "stub_face": (3.0, 0.6), "stub_top": (3.0, 0.6), "bay_back": (5.0, 0.5), "leaf_face": (4.0, 0.55),
        "reveal_far": (3.0, 0.6), "leaf_up_face": (4.0, 0.6), "threshold_full": (2.0, 0.7)}
# Parts painted only by the design (light sources): kept as drawn.
KEEP_DESIGN = {"light_lens", "bay_light_lens"}
# Soft designed films composited over the paint from the design (never painted by the image tool).
SOFT = {"soot", "dust_film"}


def load_design(layer):
    im = np.asarray(Image.open(os.path.join(DESIGN, f"design-{layer}.png")).convert("RGBA")).astype(np.float64)
    return im[..., :3], im[..., 3] / 255.0


def part_masks(layer):
    out = {}
    pre = f"{layer}--"
    for f in sorted(os.listdir(os.path.join(DESIGN, "masks"))):
        if f.startswith(pre) and f.endswith(".png"):
            n = f[len(pre):-4]
            out[n] = np.asarray(Image.open(os.path.join(DESIGN, "masks", f))).astype(np.float64) / 255.0
    return out


def sample_painted(painted_target: np.ndarray) -> np.ndarray:
    """The registered paint-over (target frame) sampled onto the design canvas."""
    X, Y = M.CV.grid()
    tx = (X - TX0) * TS - 0.5
    ty = (Y - TY0) * TS - 0.5
    return np.stack([ndimage.map_coordinates(painted_target[..., c], [ty, tx], order=1, mode="nearest") for c in range(3)], -1)


def registered(job, out_name, target_name):
    d = os.path.join(CODEX, job)
    p = K.load_rgb(os.path.join(d, "out", out_name))
    t = K.load_rgb(os.path.join(d, "refs", target_name))
    p = K.resize(p, (TW, TH))
    reg, info = K.register(p, t)
    return reg, info


def props_alpha():
    """Where main's props (breaker, valve, release cabinet) cover the design canvas: the paint-over
    there shows the props themselves, which must never be baked into a layer behind them."""
    import preview as P
    img = Image.new("RGBA", (960 * P.S, 640 * P.S), (0, 0, 0, 0))
    P.props_under(img)
    a = np.asarray(img.getchannel("A")).astype(np.float64) / 255.0
    x0, y0 = int(M.CV.x0 * P.S), int(M.CV.y0 * P.S)
    a = a[y0:y0 + M.CV.h, x0:x0 + M.CV.w]
    return ndimage.binary_dilation(a > 0.02, iterations=3)


def fill_hidden(rgb, alpha, hidden):
    """Replaces hidden pixels with the nearest visible painted pixel of the same layer, then smooths
    only the filled area, so no copy of a prop is baked in and no edge ghost remains."""
    src = (alpha > 0.5) & ~hidden
    if not src.any() or not hidden.any():
        return rgb
    _, (iy, ix) = ndimage.distance_transform_edt(~src, return_indices=True)
    filled = rgb[iy, ix]
    sm = np.stack([ndimage.gaussian_filter(filled[..., c], 6.0) for c in range(3)], -1)
    h = hidden[..., None].astype(float)
    return rgb * (1 - h) + sm * h


def clean_layer(layer, painted_canvas, report, room_chroma=None, hidden=None):
    drgb, da = load_design(layer)
    masks = part_masks(layer)
    rgb = painted_canvas.copy()
    if hidden is not None:
        rgb = fill_hidden(rgb, da, hidden)
    valid = np.ones(da.shape, bool)
    for name, m in masks.items():
        if name in ("ALPHA", "HOLE", "GLASS_HOLE", "contact_shadow") or name in SOFT:
            continue
        if name in KEEP_DESIGN:
            rgb = rgb * (1 - m[..., None]) + drgb * m[..., None]
            continue
        if name in CALM:
            s, keep = CALM[name]
            rgb = K.calm(rgb, m, s, keep)
        rgb, k = K.match_part(rgb, drgb, m, tol=0.15, valid=valid)
        rgb = K.match_chroma(rgb, drgb, m, strength=0.55, valid=valid)
        report.setdefault(layer, {})[name] = round(k, 3)
    # the room's cool cast (the plates' mid tones are strongly blue-green): a gentle shift
    if room_chroma is not None:
        lin = K.to_lin(rgb)
        lum = K.lum(lin)[..., None]
        tint = lin * (1 - 0.18) + lum * room_chroma * 0.18
        rgb = K.to_srgb(tint)
    # soft films: their designed colour over whatever is under them (alone, the film's own colour)
    hard = np.zeros(da.shape)
    for n2, m2 in masks.items():
        if n2 not in SOFT and n2 not in ("ALPHA", "HOLE", "GLASS_HOLE", "contact_shadow"):
            hard = np.maximum(hard, m2)
    for name in SOFT:
        if name in masks:
            m = masks[name]
            others = hard
            sel = m > 0.004
            if sel.any():
                c = np.median(drgb[sel & (others < 0.05)], axis=0) if (sel & (others < 0.05)).any() else drgb[sel].mean(0)
                over = (others > 0.5)[..., None]
                film = rgb * (1 - m[..., None]) + c * m[..., None]
                rgb = np.where(sel[..., None], np.where(over, film, c), rgb)
    # contact shadows: the designed shadow colour where only the shadow covers
    a = da.copy()
    if "contact_shadow" in masks:
        sh = masks["contact_shadow"]
        body = np.clip(a - sh, 0, 1)
        w = np.clip(sh / np.maximum(a, 1e-6), 0, 1) * (body < 0.5)
        rgb = rgb * (1 - w[..., None]) + drgb * w[..., None]
    keep = np.zeros(a.shape, bool)
    for name in SOFT:
        if name in masks:
            keep |= (masks[name] > 0.004) & (hard < 0.5)
    pre = rgb.copy()
    rgb = K.decontaminate(rgb, a, band=2)
    rgb[keep] = pre[keep]
    rgb[a <= 0] = 0
    return rgb, a


def room_cast():
    """Mean chromaticity (linear, normalised to unit luminance) of the room's walls near the door."""
    import preview as P
    img = np.asarray(P.room().convert("RGB")).astype(np.float64)
    r = img[300 * P.S:430 * P.S, 300 * P.S:640 * P.S].reshape(-1, 3)
    lin = K.to_lin(r).mean(0)
    return lin / (lin * np.array([0.2126, 0.7152, 0.0722])).sum()


def main():
    job = sys.argv[1] if len(sys.argv) > 1 else "sealed"
    out = os.path.join(M.WORK, "layers", job)
    os.makedirs(out, exist_ok=True)
    report = {"job": job, "registration": {}, "value_gain": {}, "checks": {}}
    cast = room_cast()
    hidden = props_alpha()
    if job == "sealed":
        reg, info = registered("junction-paint-sealed", "junction-door-shut-painted.png", "1-edit-target-junction-door-shut.png")
        report["registration"]["sealed"] = info
        canvas = sample_painted(reg)
        jobs = [("wall", canvas), ("leaf", canvas), ("front", canvas), ("alcove", canvas)]
    else:
        reg, info = registered("junction-paint-blown", "junction-door-blown-painted.png", "1-edit-target-junction-door-blown.png")
        report["registration"]["blown"] = info
        reg2, info2 = registered("junction-paint-blown", "junction-door-breaking-painted.png", "3-edit-target-junction-door-breaking.png")
        report["registration"]["breaking"] = info2
        c1, c2 = sample_painted(reg), sample_painted(reg2)
        jobs = [("hole", c1), ("damage", c1), ("lying", c1), ("leafbreak", c2), ("cracks", c2)]
    for layer, canvas in jobs:
        rgb, a = clean_layer(layer, canvas, report["value_gain"], cast, hidden if layer in ("wall", "alcove", "hole", "damage", "leaf", "leafbreak", "cracks") else None)
        K.save_rgba(rgb, a, os.path.join(out, f"{layer}.png"))
        _, da = load_design(layer)
        masks = part_masks(layer)
        chk = {"silhouette_iou": round(K.iou(a, da), 4), "alpha_outside_design": int(((a > 0) & (da <= 0)).sum())}
        for hn in ("HOLE", "GLASS_HOLE"):
            if hn in masks:
                chk[f"{hn.lower()}_interior_px_with_alpha"] = int(((masks[hn] > 0.99) & (a > 0.004)).sum())
        report["checks"][layer] = chk
    with open(os.path.join(out, "cleanup-report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print(json.dumps(report["checks"], indent=1), report["registration"])


if __name__ == "__main__":
    main()
