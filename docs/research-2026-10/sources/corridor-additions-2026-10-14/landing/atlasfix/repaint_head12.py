"""Corridor additions, landing fix (2026-10-14): repaints the image tool's hidden copy of DOOR 4B-07
in corridor-seal-atlas.png's wall region (review r5, should-fix 1). The faint lettering sits in the
blast frame's head plate behind the always-opaque hood (atlas x 728-840, y 296-338).

Inside that box, only on the head plate's own flat paint (its design mask less every joint, bolt,
arris, seal and the parked leaf's edge, less round 11's far jamb plate) and only where the hood is
fully opaque within 2 world px all round (so no in-game frame can change), each plate panel's
paint is rebuilt as the plate's own clean paint: the plate's light from a masked smooth of its own
paint (sigma 8 px, the lettering's strokes weighted down), times luma-only grain matched to the
plate's clean grain outside the box (seeded, so the result is reproducible). The edge of the repaint is feathered over 2 px. Alpha and
every other pixel are unchanged. No image tool is used.

Usage: ADD7=<add7 folder> python repaint_head12.py <atlas in> <atlas out> <report.json>"""
import json
import os
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image
from scipy import ndimage

import masks

LUM = np.array([0.2126, 0.7152, 0.0722])
MARGIN_WORLD = 2.0
SEED = 20261014
SMOOTH = 8.0


def hood_opaque(alpha_frame):
    """Wall texels whose world neighbourhood (+-MARGIN_WORLD) is fully covered by the hood (the frame
    piece, region (2, 2, 387, 564) at world (700.5, 289.5), 4 px per world px)."""
    ys, xs = np.mgrid[0:1024, 0:1024]
    wx = 684 + (xs - 672 + 0.5) * 0.5
    wy = 150 + (ys - 2 + 0.5) * 0.5
    ok_all = np.ones((1024, 1024), bool)
    for dx in np.linspace(-MARGIN_WORLD, MARGIN_WORLD, 9):
        for dy in np.linspace(-MARGIN_WORLD, MARGIN_WORLD, 9):
            fx = np.floor((wx + dx - 700.5) * 4).astype(int)
            fy = np.floor((wy + dy - 289.5) * 4).astype(int)
            inside = (fx >= 0) & (fy >= 0) & (fx < 387) & (fy < 564)
            a = np.zeros((1024, 1024))
            a[inside] = alpha_frame[fy[inside], fx[inside]]
            ok_all &= a >= 255
    return ok_all


def main(src, dst, report_path):
    img = np.array(Image.open(src).convert("RGBA"))
    rgb = img[..., :3].astype(float)
    plate = masks.plate_mask()
    box = np.zeros(plate.shape, bool)
    box[masks.BOX] = True
    covered = hood_opaque(img[2:2 + 564, 2:2 + 387, 3].astype(float))
    change = plate & box & covered
    rng = np.random.default_rng(SEED)
    out = rgb.copy()
    report = {"changed_px": 0}
    lum = (rgb * LUM).sum(-1)
    # The plate's clean grain: luma detail finer than 1.5 px on the plate's flat paint outside the box,
    # 2 px clear of its features (a robust spread, so edges and bolts do not count).
    fine = lum - ndimage.gaussian_filter(lum, 1.5)
    clean_ref = ndimage.binary_erosion(plate, iterations=2) & ~box
    clean_ref[:, :700] = False
    clean_ref[:, 880:] = False
    rel = (fine / np.maximum(lum, 1.0))[clean_ref]
    grain_std = float(1.4826 * np.median(np.abs(rel - np.median(rel))))
    # The plate's light without the lettering: a masked smooth of the plate's own paint (sigma 8 px),
    # the lettering's strokes (brighter than the smooth by more than 2.5 grain) weighted down and
    # smoothed again, so the light stays the plate's own and only the letters go.
    weight = plate.astype(float)
    base = None
    for _pass in range(3):
        num = np.stack([ndimage.gaussian_filter(rgb[..., c] * weight, SMOOTH) for c in range(3)], -1)
        den = ndimage.gaussian_filter(weight, SMOOTH)[..., None]
        base = num / np.maximum(den, 1e-6)
        base_lum = (base * LUM).sum(-1)
        strokes = np.abs(lum - base_lum) > 2.5 * grain_std * np.maximum(base_lum, 1.0)
        weight = plate * np.where(strokes & box, 0.05, 1.0)
    noise = ndimage.gaussian_filter(rng.standard_normal(plate.shape), 0.6)
    noise *= grain_std / max(noise[change].std(), 1e-6)
    new = base * (1.0 + noise)[..., None]
    feather = np.clip(ndimage.distance_transform_edt(change) / 2.0, 0.0, 1.0)[..., None]
    out = np.where(change[..., None], rgb * (1.0 - feather) + new * feather, rgb)
    report["grain_std_rel"] = round(grain_std, 4)
    report["smooth_sigma_px"] = SMOOTH
    result = img.copy()
    result[..., :3] = np.clip(np.round(out), 0, 255).astype(np.uint8)
    changed = np.any(result != img, -1)
    assert not np.any(result[..., 3] != img[..., 3]), "alpha changed"
    assert not np.any(changed & ~change), "a pixel changed outside the repaint mask"
    report["changed_px"] = int(changed.sum())
    report["repaint_mask_px"] = int(change.sum())
    report["plate_px_in_box"] = int((plate & box).sum())
    report["plate_px_in_box_not_under_opaque_hood"] = int((plate & box & ~covered).sum())
    Image.fromarray(result).save(dst, optimize=False, compress_level=9)
    json.dump(report, open(report_path, "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main(*sys.argv[1:4])
