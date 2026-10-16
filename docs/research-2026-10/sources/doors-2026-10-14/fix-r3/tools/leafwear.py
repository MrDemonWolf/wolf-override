"""Fix round 3 (review r3, R3-2: "the faces are flat ... target at least 0.12 relative texture, with grime at
the bottom rail and wear around the lever"): designed wear on a swing leaf's painted steel faces, laid
where use and water put it on a real hollow-metal door, as an albedo multiplier on the cleaned paint (the
paint's own grain stays; nothing new is drawn but wear), then the paint's grain lifted so it survives
at play size. Deterministic (one seed per face). Scratch only.

Face coordinates: the face art is 73 x 171 px at 80 px per metre (0.914 x 2.134 m), u from the hinge edge
(x 0) to the latch edge (x 72), v up (image row 170 is the floor). Where the wear goes, and why:
  - hands: people push and pull a door within a palm's reach of the lever, 0.85-1.35 m up and 0.06-0.32 m
    in from the latch edge; skin oil and grime darken the paint there (a soft smudge, x 0.72), and at the stile right beside the lever the paint is rubbed through to grey primer (a narrow
    lighter streak, x 1.15), as on any well-used painted steel door;
  - the bottom rail: floor water, mop splash and grit leave a grime band up to about 0.10 m with an
    uneven top (x 0.68), on top of the kick plate where there is one;
  - feet: black heel and toe marks where people shove the door with a foot, 0.06-0.30 m up, short and
    nearly level, darker than the paint (x 0.50), fewer near the hinge;
  - scratches: a few thin, nearly level light lines where carts and tool bags scraped the paint at
    0.35-0.95 m (x 1.2);
  - the edges: dirt held in the 1 px meeting of the face and its edges (x 0.88).
The grain lift is grade2.boost_detail at 1.0 and 2.0 face px (the face draws at about 0.85x at 1280 x 720,
with trilinear mipmaps, so a 1 px grain alone does not survive)."""
from __future__ import annotations

import os
import sys

import numpy as np
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grade2 as G  # noqa: E402

PPM = 80.0


def _smooth_noise(shape, sigma, seed):
    n = ndimage.gaussian_filter(np.random.default_rng(seed).normal(0, 1, shape), sigma)
    return n / max(np.abs(n).max(), 1e-6)


def wear_map(shape, face, lever_xy, seed):
    h, w = shape
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)
    v = (h - 1 - ys) / PPM          # metres up
    u_latch = (w - 1 - xs) / PPM    # metres in from the latch edge
    f = np.ones(shape)
    # hands: a soft smudge round the lever, more toward the latch edge
    lx, ly = lever_xy
    lever_v = (h - 1 - ly) / PPM
    d = np.sqrt(((u_latch - 0.16) / 0.17) ** 2 + ((v - (lever_v + 0.08)) / 0.27) ** 2)
    smudge = np.clip(1.0 - d, 0, 1) ** 1.3 * (0.75 + 0.25 * _smooth_noise(shape, 2.5, seed))
    f *= 1.0 - 0.28 * smudge
    # paint rubbed through at the stile beside the lever
    stile = (u_latch < 0.035) & (np.abs(v - lever_v) < 0.16)
    f = np.where(stile, f * (1.0 + 0.15 * np.clip(1 - np.abs(v - lever_v) / 0.16, 0, 1)), f)
    # the bottom rail's grime band, uneven top
    top = 0.10 + 0.03 * _smooth_noise((1, w), 4.0, seed + 1)[0][None, :]
    f *= 1.0 - 0.32 * np.clip((top - v) / 0.05, 0, 1)
    # heel and toe marks: short, nearly level strokes low on the face
    rng = np.random.default_rng(seed + 2)
    for _ in range(7):
        cu = rng.uniform(0.18, 0.86) * w
        cv = rng.uniform(0.06, 0.30)
        if cu < 0.3 * w and rng.random() < 0.5:
            continue
        ln = rng.uniform(0.04, 0.10) * PPM
        ang = rng.uniform(-0.25, 0.25)
        t = np.linspace(-0.5, 0.5, 24)
        px = cu + t * ln * np.cos(ang)
        py = (h - 1) - (cv * PPM) + t * ln * np.sin(ang)
        mark = np.zeros(shape)
        for x_, y_ in zip(px, py):
            xi, yi = int(round(x_)), int(round(y_))
            if 0 <= xi < w and 0 <= yi < h:
                mark[yi, xi] = 1.0
        mark = ndimage.gaussian_filter(mark, 0.6)
        mark = mark / max(mark.max(), 1e-6)
        f *= 1.0 - 0.50 * mark * rng.uniform(0.6, 1.0)
    # light scrapes through the paint where carts and tool bags rub: thin, nearly level, at cart height
    for _ in range(6):
        cu = rng.uniform(0.15, 0.85) * w
        cv = rng.uniform(0.35, 0.95)
        ln = rng.uniform(0.04, 0.10) * PPM
        ang = rng.uniform(-0.2, 0.2)
        t = np.linspace(-0.5, 0.5, 20)
        px = cu + t * ln * np.cos(ang)
        py = (h - 1) - (cv * PPM) + t * ln * np.sin(ang)
        mark = np.zeros(shape)
        for x_, y_ in zip(px, py):
            xi, yi = int(round(x_)), int(round(y_))
            if 0 <= xi < w and 0 <= yi < h:
                mark[yi, xi] = 1.0
        f *= 1.0 + 0.20 * mark * rng.uniform(0.6, 1.0)
    # dirt in the edges
    edge = np.zeros(shape, bool)
    edge[:, 0] = edge[:, -1] = True
    edge[0, :] = edge[-1, :] = True
    f = np.where(edge, f * 0.88, f)
    return f


def apply(rgba, face, lever_mask, seed, plate=None, lift=None, grain=(None, None)):
    """rgba: uint8 face art. lever_mask: the face's lever mask (its centre places the hand wear)."""
    a = np.asarray(rgba).astype(np.float64)
    ys, xs = np.nonzero(lever_mask > 0.5)
    lever = (xs.mean(), ys.mean()) if len(xs) else (a.shape[1] - 10.0, a.shape[0] * 0.5)
    f = wear_map(a.shape[:2], face, lever, seed)
    # hardware (lever, rose, cylinder, lock) keeps its own value: only the painted steel and the kick plate
    if plate is not None:
        f = np.where(plate > 0.5, f, 1.0)
    lin = G.to_lin(a.astype(np.uint8)) * f[..., None]
    out = a.copy()
    out[..., :3] = G.to_srgb8(lin)
    # the grain lift on the painted skin only (lift); the kick plate keeps its own texture
    pm = lift if lift is not None else (plate if plate is not None else np.ones(a.shape[:2]))
    fine = GRAIN_FINE_AMOUNT if grain[0] is None else grain[0]
    coarse = GRAIN_COARSE_AMOUNT if grain[1] is None else grain[1]
    out = G.boost_detail(out.astype(np.uint8), pm, sigma=1.0, amount=fine, ppw=2.0)
    # fix round 3, second pass: the face draws at about 0.85x with trilinear mipmaps, which takes most of a
    # 1 px grain away; the paint's own structure at 2 face px (its mottle, scuffs and grime) is lifted too
    out = G.boost_detail(out.astype(np.uint8), pm, sigma=GRAIN_COARSE_SIGMA, amount=coarse, ppw=2.0)
    return out


GRAIN_FINE_AMOUNT, GRAIN_COARSE_SIGMA, GRAIN_COARSE_AMOUNT = 1.5, 2.0, 1.0
# fix round 3, final pass: the junction entry's open leaf read 0.089 relative texture on render.sh a3 (target
# 0.12; Records' leaves 0.128 and 0.251 with the amounts above): it stands deeper in its camera and draws
# smaller, so its grain is lifted more (rgrade2.py passes this for the jentry track)
JENTRY_GRAIN = (2.2, 1.9)
