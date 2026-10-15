"""Junction entry door: deterministic cleanup of the Codex paint (doors-r1, fix round 1). The records
track's cleanup (records/tools/cleanup.py) in the junction's model: every part takes the design's
colour and light times the paint's local material detail (clamped), alpha is the design's exactly,
contact shadows from the design's footprints. Writes layers/entry/clean-{wall,front,beyond}.png and
layers/leaf/clean-{room,out-exit,edge}.png at the design's scale; layers/report.json."""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jedesign as JE  # noqa: E402,F401  (installs jemodel as rmodel)
import jemodel as M  # noqa: E402
import cleanup as RC  # noqa: E402  (records/tools/cleanup.py)

JOB = "r2-junction-entry"  # fix round 2: painted open (no leaf in the doorway)


def painted_on_canvas(img, lay, cv):
    X0, Y0, Wd, Hd = lay["world_x0"], lay["world_y0"], lay["world_w"], lay["world_h"]
    sx, sy = img.size[0] / Wd, img.size[1] / Hd
    left, top = (cv["x0"] - X0) * sx, (cv["y0"] - Y0) * sy
    box = (left, top, left + cv["w"] / cv["ppw"] * sx, top + cv["h"] / cv["ppw"] * sy)
    crop = img.transform((cv["w"], cv["h"]), Image.Transform.EXTENT, box, Image.Resampling.BICUBIC)
    return M.from_srgb_u8(np.asarray(crop))


def beyond_visible(mask_dir, cv):
    """Where the open painting shows the passage: its alpha minus the wall, column, stub and the junction's
    (edited) mid plate, eroded 2 px (fix round 2, N1)."""
    from scipy import ndimage
    from jemid import edit_mid
    by = RC.load_mask(os.path.join(mask_dir, "beyond--ALPHA.png")) > 0.5
    occ = (RC.load_mask(os.path.join(mask_dir, "wall--ALPHA.png")) > 0.02) | (RC.load_mask(os.path.join(mask_dir, "front--ALPHA.png")) > 0.02)
    mid, _ = edit_mid()
    ma = np.asarray(mid)[..., 3]
    H, W = by.shape
    XX, YY = np.meshgrid(cv["x0"] + (np.arange(W) + 0.5) / cv["ppw"], cv["y0"] + (np.arange(H) + 0.5) / cv["ppw"])
    mx = (XX * 2).astype(int)
    my = ((YY - 52.0) * 2).astype(int)
    inside = (mx >= 0) & (mx < ma.shape[1]) & (my >= 0) & (my < ma.shape[0])
    mo = np.zeros_like(by)
    mo[inside] = ma[my[inside], mx[inside]] > 8
    occ |= mo
    return (by & ~ndimage.binary_dilation(occ, iterations=2)).astype(np.float64)


def main():
    J = os.path.join(M.TRACK, "..", "codex", JOB)
    lay = json.load(open(os.path.join(J, "layout.json")))
    spec = json.load(open(os.path.join(M.DESIGN, "entry", "spec.json")))
    cv = spec["canvas"]
    painted = painted_on_canvas(Image.open(os.path.join(J, "out", "r2-junction-entry-painted.png")).convert("RGB"), lay, cv)
    mask_dir = os.path.join(M.DESIGN, "entry", "masks")
    vis = beyond_visible(mask_dir, cv)
    out = os.path.join(M.TRACK, "layers", "entry")
    os.makedirs(out, exist_ok=True)
    rep = {}
    cast = (0.92, 1.0, 1.08)
    for layer in ("wall", "front", "beyond"):
        names = [p["name"] for p in spec["parts"] if p["layer"] == layer] + (["GLASS_HOLE"] if layer == "front" else [])
        rgba, checks = RC.clean_layer(os.path.join(M.DESIGN, "entry", f"design-{layer}.png"), mask_dir, layer, names, painted, 1.0, cast,
                                      vis=vis if layer == "beyond" else None)
        if layer == "front":
            glass = RC.load_mask(os.path.join(mask_dir, "front--GLASS_HOLE.png"))
            rgba[..., 3] = np.where(glass > 0.5, 0, rgba[..., 3])
            checks["glass_hole_alpha_px"] = int(((glass > 0.5) & (rgba[..., 3] > 0)).sum())
        Image.fromarray(rgba, "RGBA").save(os.path.join(out, f"clean-{layer}.png"))
        rep[layer] = checks
    # the leaf sheet (the tool returned it at 1254 for 1024: mapped by the ratio)
    im = Image.open(os.path.join(J, "out", "r2-junction-entry-leaf-painted.png")).convert("RGB")
    k = im.size[0] / 1024.0
    lo = os.path.join(M.TRACK, "layers", "leaf")
    os.makedirs(lo, exist_ok=True)
    leaf_spec = json.load(open(os.path.join(M.DESIGN, "leaf", "spec.json")))
    for name in ("room", "out-exit", "edge"):
        it = lay["items"][name]
        w, h = it["size"]
        x, y = it["xy"]
        crop = im.transform((w, h), Image.Transform.EXTENT, (x * k, y * k, (x + w * it["scale"]) * k, (y + h * it["scale"]) * k), Image.Resampling.BICUBIC)
        p_lin = M.from_srgb_u8(np.asarray(crop))
        d_lin = M.from_srgb_u8(np.asarray(Image.open(os.path.join(M.DESIGN, "leaf", f"design-{name}.png")).convert("RGB")))
        names = [p["name"] for p in leaf_spec["faces"][name]["parts"]]
        if name == "edge":
            own = np.zeros(d_lin.shape[:2], int)
        else:
            own = RC.owners(names, os.path.join(M.DESIGN, "leaf", "masks"), name)
            own = np.where(own < 0, 0, own)
        det = RC.detail_map(p_lin, own, len(names), sigma=RC.LEAF_SIGMA)
        Image.fromarray(M.to_srgb_u8(d_lin * det[..., None])).save(os.path.join(lo, f"clean-{name}.png"))
    M.write_json(os.path.join(M.TRACK, "layers", "report.json"), rep)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
