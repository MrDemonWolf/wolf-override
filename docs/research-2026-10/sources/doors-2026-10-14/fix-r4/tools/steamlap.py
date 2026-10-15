"""Fix round 4 (review r4, S1): the junction mid plate's static steam by the header elbow ended in a ruler-straight
vertical line at the entry cross-wall's back corner (world x 124.1): the wall, drawn over the plate, hid every
pixel of the cloud past the corner. Steam in the room lies in front of the cross-wall's face, which the camera
sees, so near the corner it laps onto that face and thins out on it. Scratch only; deterministic.

  1. The cloud's density in the mid plate just room-side of the corner is estimated with the dark-channel
     prior (He, Sun and Tang, "Single Image Haze Removal Using Dark Channel Prior", CVPR 2009): steam lifts
     the darkest channel of the dark metal behind it, a = OMEGA * min over a 7 x 7 patch of min_c(I_c / A_c),
     with A the cloud's own colour (the mean of its densest pixels there), less the bare metal's own dark
     channel (measured where the plate has no steam, under the elbow further right).
  2. On the cross-wall's face (the atlas's wall region), within LAP world px of the corner, the cloud is
     composited in its own colour with the density mirrored about the corner (its own wisps, nothing new) and
     a smooth fall-off to nothing at LAP px (DENSITY_GAIN: see below): the lap is about 12 screen px at 1280 x 720.
Nothing else in the atlas changes. usage: steamlap.py ATLAS_IN MID_PLATE ATLAS_OUT [PREVIEW_DIR]"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

CORNER_X = 124.1           # world px: the cross-wall's back corner (jemid info corner_x)
WALL_REGION = (92, 2, 280, 607)
WALL_AT = (7.0, 140.0)     # world top-left, 0.5 world px per atlas px
MID_Y0 = 52.0              # the mid plate: 2 px per world px, y from 52
LAP = 7.0                  # world px
# The plate's steam reads denser than its dark-channel estimate where it lies over lit pipe metal; on the dark
# face it needs this much more cover to meet the cloud's brightness at the corner (closed on render.sh r09:
# round-4 first pass 0.026 against the cloud's 0.076 linear at the corner, a step that still read as a line).
DENSITY_GAIN = 1.7
MAX_ALPHA = 0.9
OMEGA = 0.95
ROWS = (200.0, 330.0)      # world y: the band the cloud reaches at the corner (review: screen y 140-240)
BARE = (330, 420)          # plate x columns with no steam, the same rows (the header and riser further right)


def lum(c):
    return c @ np.array([0.2126, 0.7152, 0.0722])


def density(mid):
    rgb = mid[..., :3] / 255.0
    op = mid[..., 3] > 250
    y0, y1 = int((ROWS[0] - MID_Y0) * 2), int((ROWS[1] - MID_Y0) * 2)
    x0 = int(CORNER_X * 2) + 1
    band = (slice(y0, y1), slice(x0, x0 + 60))
    # the cloud's colour: the brightest-dark-channel pixels next to the corner
    raw = np.where(op, rgb.min(-1), 9.0)
    dark0 = ndimage.minimum_filter(raw, size=7)
    d = np.where(op, dark0, 0.0)[band]
    top = d >= np.percentile(d[op[band]], 97)
    A = rgb[band][top].mean(0)
    norm = np.where(op, (rgb / A).min(-1), 9.0)
    dark = np.where(op, ndimage.minimum_filter(norm, size=7), 0.0)
    bare = np.median(dark[y0:y1, BARE[0]:BARE[1]][op[y0:y1, BARE[0]:BARE[1]]])
    a = np.clip(OMEGA * (dark - bare) / max(1.0 - bare, 1e-6), 0.0, 1.0)
    a = ndimage.gaussian_filter(a, 1.0)
    return a, A, float(bare)


def main():
    atlas_in, mid_path, atlas_out = sys.argv[1:4]
    prev = sys.argv[4] if len(sys.argv) > 4 else None
    atlas = np.asarray(Image.open(atlas_in).convert("RGBA")).astype(np.float64)
    mid = np.asarray(Image.open(mid_path).convert("RGBA")).astype(np.float64)
    a, A, bare = density(mid)
    rx, ry, rw, rh = WALL_REGION
    ys, xs = np.mgrid[ry:ry + rh, rx:rx + rw]
    wx = WALL_AT[0] + (xs - rx + 0.5) * 0.5
    wy = WALL_AT[1] + (ys - ry + 0.5) * 0.5
    dist = CORNER_X - wx
    on = (dist > 0) & (dist < LAP) & (wy >= ROWS[0] - 10) & (wy <= ROWS[1] + 10) & (atlas[ry:ry + rh, rx:rx + rw, 3] > 250)
    # the mirrored density: the plate's pixel as far room-side of the corner as this one is wall-side
    mx = (CORNER_X + dist) * 2.0 - 0.5
    my = (wy - MID_Y0) * 2.0 - 0.5
    am = ndimage.map_coordinates(a, [my[on], mx[on]], order=1, mode="nearest")
    t = np.clip(dist[on] / LAP, 0, 1)
    fall = (1.0 - t) ** 2 * (1.0 + 2.0 * t)      # smoothstep down to 0 at LAP
    alpha = np.clip(am * DENSITY_GAIN, 0.0, MAX_ALPHA) * fall
    sub = atlas[ry:ry + rh, rx:rx + rw]
    rgb = sub[..., :3][on]
    sub[..., :3][on] = rgb * (1.0 - alpha[:, None]) + (A * 255.0) * alpha[:, None]
    atlas[ry:ry + rh, rx:rx + rw] = sub
    Image.fromarray(np.clip(atlas + 0.5, 0, 255).astype(np.uint8), "RGBA").save(atlas_out, optimize=True)
    info = {"cloud_rgb": [round(float(v) * 255, 1) for v in A], "bare_dark": round(bare, 4), "lap_world_px": LAP, "px_changed": int((alpha > 0.004).sum()),
            "alpha_max": round(float(alpha.max()), 3), "alpha_at_corner_max": round(float(am.max()), 3)}
    print(json.dumps(info))
    if prev:
        os.makedirs(prev, exist_ok=True)
        y0, y1 = int((ROWS[0] - MID_Y0) * 2), int((ROWS[1] - MID_Y0) * 2)
        Image.fromarray((np.clip(a[y0:y1, int(CORNER_X * 2) - 4:int(CORNER_X * 2) + 120], 0, 1) * 255).astype(np.uint8)).resize((248, 2 * (y1 - y0)), Image.NEAREST).save(os.path.join(prev, "steam-density.png"))
        json.dump(info, open(os.path.join(prev, "steamlap.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
