"""Junction exit door: the construction design (scratch only). Ray-casts the measured parts in
geom.py with the room's camera and its two visible light sources, and writes for each state (shut,
open) a flat-shaded value render, one mask per part, the layer masks and spec.json.

Usage: python design.py OUT_DIR
"""
from __future__ import annotations

import json
import math
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import geom as g  # noqa: E402

PPW = 4.0                    # design px per world px
X0, X1 = 826.0, 1032.0       # world rect of the wall pieces (fix round 2: from 826, so the bolt panel's riser at x 834 is in it)
Y0, Y1 = 140.0, 584.0        # fix round 1: down through the deck's fascia (the stub's cut)
AMBIENT = np.array([0.068, 0.076, 0.090])
I1 = np.array([1.00, 1.02, 1.06]) * 30.0      # the junction's cold LED fitting
I2 = np.array([1.00, 1.03, 1.08]) * 2.6       # the passage bulkhead fitting (fix round 2: the passage reads as a lit space)
I3 = np.array([1.00, 1.02, 1.05]) * 2.4       # the wall pack over the door (forward-down lobe; fix round 2: it is lit, S7)
TARGET_WALL_SRGB = 50.0
# The fittings are area lights (a 1.2 m LED batten; a 0.5 m wall pack): sampled along their length so
# shadows from small fixtures go soft with distance, as they do.
# fix round 1 (S3): sampled densely enough that a small box's shadow is the soft smudge a 1.2 m batten
# gives, not five stacked hard copies of a point light's wedge.
L1_SAMPLES = [np.array([dx, 0.0, dz]) for dx in np.linspace(-0.6, 0.6, 13) for dz in (-0.15, 0.0, 0.15)]
L3_SAMPLES = [g.U * ds + g.V * dn for ds in np.linspace(-0.22, 0.22, 9) for dn in (-0.06, 0.06)]                         # median of the lit concrete faces (the room's wall values)
EXPOSURE = 1.0


def grid(x0, x1, y0, y1, ppw):
    w, h = int(round((x1 - x0) * ppw)), int(round((y1 - y0) * ppw))
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)
    return x0 + (xs + 0.5) / ppw, y0 + (ys + 0.5) / ppw


KEYS: list = []


def cast(parts, X, Y):
    KEYS[:] = [i for i, p in enumerate(parts) if p.layer == "key"]
    P0, B = g.rays(X, Y)
    best = np.full(X.shape, np.inf)
    idx = np.full(X.shape, -1, int)
    pos = np.zeros(X.shape + (3,))
    uv = np.zeros(X.shape + (2,))
    for i, pt in enumerate(parts):
        if isinstance(pt, g.Rect):
            z, p, ua, vb = g.hit_rect(pt, P0, B)
        else:
            z, p = g.hit_sphere(pt, P0, B)
            ua = vb = np.zeros_like(z)
        # the deck (key) loses ties with parts lying on it (the sill, the passage floor)
        m = (z < best - 1e-3) if pt.layer == "key" else (z < best + (1e-3 if (idx >= 0).any() and False else 0) )
        if pt.layer != "key":
            keyhit = np.isin(idx, KEYS) & (z <= best + 2e-3)
            m |= keyhit & np.isfinite(z)
        best[m] = z[m]
        idx[m] = i
        pos[m] = p[m]
        uv[m, 0] = ua[m]
        uv[m, 1] = vb[m]
    return idx, best, pos, uv


def _noise3(P, scale, seed):
    rng = np.random.default_rng(seed)
    out = np.zeros(len(P))
    for k in range(6):
        f = rng.uniform(0.6, 1.6, 3) / scale
        ph = rng.uniform(0, 2 * np.pi, 3)
        out += np.sin(P[:, 0] * f[0] * 2 * np.pi + ph[0]) * np.sin(P[:, 1] * f[1] * 2 * np.pi + ph[1]) * np.cos(P[:, 2] * f[2] * 2 * np.pi + ph[2]) / (k + 1)
    return out / 1.5


def concrete_wear(P):
    """Designed wear on the cast concrete (fix round 1, M1): board-form mottle (+-6 %), a damp band at
    the foot where the deck's water wicks up (irregular top, 0.12-0.24 m), and seepage just under the
    3.6 m pour joint (a cold joint leaks). Nothing else: no random drips."""
    h = P[:, 1]
    f = 1.0 + 0.06 * _noise3(P, np.array([1.2, 0.9, 1.2]), 51)
    top = 0.18 + 0.06 * _noise3(P * np.array([1, 0, 1]), np.array([0.5, 1.0, 0.5]), 52)
    f *= 1.0 - 0.36 * np.clip(1.0 - h / top, 0, 1) ** 0.7 * (h > -0.05)
    f *= 1.0 - 0.12 * np.exp(-(((h - (g.POUR_JOINT_H - 0.08)) / 0.08) ** 2))
    return f


def cast_marks(P, seed=5):
    """Fix round 2: form-panel joints (1.2 x 2.4 m plywood) and grouted 25 mm tie-cone holes 0.6 m on
    centre (ACI 347), on the cross-wall's approach face, from its (s, h)."""
    s_al = ((P - g.C) * g.U).sum(-1)
    h = P[:, 1]
    v = np.ones(len(P))
    da, dh = np.mod(s_al, 1.2), np.mod(h, 2.4)
    joint = (np.minimum(da, 1.2 - da) < 0.005) | (np.minimum(dh, 2.4 - dh) < 0.005)
    fin = ((da > 0.005) & (da < 0.016)) | ((dh > 0.005) & (dh < 0.016))
    v = np.where(joint, 0.86, np.where(fin, 1.04, v))
    ta, th = np.mod(s_al - 0.3, 0.6), np.mod(h - 0.3, 0.6)
    r = np.sqrt(np.minimum(ta, 0.6 - ta) ** 2 + np.minimum(th, 0.6 - th) ** 2)
    cell = (np.floor((s_al - 0.3) / 0.6 + 0.5) * 131 + np.floor((h - 0.3) / 0.6 + 0.5) * 17 + seed) % 7
    core = np.where(cell < 2, 0.80, 0.58)
    return np.where(r < 0.0125, v * core, np.where(r < 0.024, v * 1.07, v))


def detail(pt, P, uv):
    """Albedo multiplier for designed detail: pour joint, leaf seams and frame band, edge stripes."""
    m = np.ones(len(P))
    nm = pt.name
    if nm in ("back_face", "lintel_face", "front_face", "below_sill", "col_end", "stub_face", "stub_top", "stub_cut"):
        m = m * concrete_wear(P)
    if nm in ("back_face", "lintel_face", "front_face"):
        m = m * cast_marks(P)
        m[np.abs(P[:, 1] - g.POUR_JOINT_H) < 0.012] = 0.55
    if nm == "sill":
        # the leaf's bottom track: a slot in the threshold plate under the leaf (uv: s along a, n along b)
        n_al = uv[:, 1] * g.T
        m[(n_al > g.LEAF_N0 + 0.02) & (n_al < g.LEAF_N1 - 0.02)] = 0.08
    if nm == "leaf_face":
        s_al = uv[:, 0] * g.LEAF_W
        h = uv[:, 1] * (g.LEAF_H - 0.004)
        band = 0.06
        edge = (np.abs(s_al - band) < 0.008) | (np.abs(s_al - (g.LEAF_W - band)) < 0.008) | (np.abs(h - band) < 0.008) | (np.abs(h - (g.LEAF_H - band)) < 0.008)
        seams = (np.abs(h - 0.82) < 0.006) | (np.abs(h - 1.64) < 0.006)
        m[edge] = 0.62
        m[seams & (s_al > band) & (s_al < g.LEAF_W - band)] = 0.72
    if nm == "leaf_edge":
        n_al = uv[:, 0] * (g.LEAF_N1 - g.LEAF_N0)
        h = uv[:, 1] * g.LEAF_H
        stripe = np.floor((h + n_al) / 0.06).astype(int) % 2 == 1
        m[stripe] = np.array(g.BLACK).mean() / np.array(g.YELLOW).mean()
        seal = np.abs(n_al - 0.06) < 0.012
        m[seal] = 0.04
    return m


def shade(parts, idx, pos, uv=None):
    out = np.zeros(idx.shape + (3,))
    occ = [p for p in parts if isinstance(p, g.Rect) and p.emissive == 0]
    for i, pt in enumerate(parts):
        m = idx == i
        if not m.any() or pt.layer == "key":
            continue
        P = pos[m]
        if isinstance(pt, g.Sphere):
            n = P - pt.c
            n /= np.linalg.norm(n, axis=-1, keepdims=True)
        else:
            n = np.broadcast_to(pt.n, P.shape)
        alb = np.array(pt.albedo)[None, :] * detail(pt, P, uv[m] if uv is not None else np.zeros((len(P), 2)))[:, None]
        col = np.broadcast_to(AMBIENT, P.shape).copy()
        for L0, I, soft, lobe, samples in ((g.L1, I1, 4.0, False, L1_SAMPLES), (g.L2, I2, 0.12, False, [np.zeros(3)]), (g.L3, I3, 0.35, True, L3_SAMPLES)):
            acc = np.zeros(len(P))
            for off in samples:
                L = L0 + off
                d = L - P
                dist2 = (d * d).sum(-1)
                l = d / np.sqrt(dist2)[:, None]
                lam = np.clip((n * l).sum(-1), 0, 1)
                if lobe:
                    # forward-throw (fix round 2): the light leaves the front glass down and out toward
                    # the approach (-V); the wall right under it gets the spill, the leaf, threshold and
                    # deck in front get the beam; nothing goes up
                    fwd = (l * g.V[None, :]).sum(-1)
                    lam = lam * np.clip(l[:, 1], 0, 1) ** 0.8 * (0.35 + 0.65 * np.clip(fwd, 0, 1))
                vis = ~g.occluded(P + n * 0.004, L, occ, skip=pt.name)
                acc += lam * vis / (dist2 + soft)
            col += I[None, :] * (acc / len(samples))[:, None]
        c = alb * col + pt.emissive * np.array([1.4, 1.45, 1.5])[None, :]
        out[m] = c
    return out


def to_srgb(lin):
    lin = np.clip(lin * EXPOSURE, 0, 1)
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055) * 255


def render_state(lead_s, out, tag, with_leaf=True):
    parts = g.parts(lead_s, with_leaf)
    X, Y = grid(X0, X1, Y0, Y1, PPW)
    idx, z, pos, uv = cast(parts, X, Y)
    rgb = shade(parts, idx, pos, uv)
    global EXPOSURE
    if tag == "open":
        sel = np.isin(idx, [i for i, p in enumerate(parts) if p.name in ("back_face", "lintel_face", "front_face")])
        lum = (rgb[sel] * np.array([0.2126, 0.7152, 0.0722])).sum(-1)
        med = np.median(lum)
        t = TARGET_WALL_SRGB / 255.0
        t_lin = ((t + 0.055) / 1.055) ** 2.4
        EXPOSURE = t_lin / med
        print("exposure", EXPOSURE)
        open(f"{out}/exposure.txt", "w").write(repr(float(EXPOSURE)))
    srgb = to_srgb(rgb)
    names = [p.name for p in parts]
    layers = {p.name: p.layer for p in parts}
    key = np.array([p.layer == "key" for p in parts] + [True])
    mine = (idx >= 0) & ~key[idx]
    img = np.zeros(X.shape + (4,), np.uint8)
    img[..., :3] = np.clip(srgb + 0.5, 0, 255).astype(np.uint8)
    img[..., 3] = mine * 255
    Image.fromarray(img, "RGBA").save(f"{out}/design-{tag}.png")
    np.save(f"{out}/idx-{tag}.npy", idx)
    np.save(f"{out}/z-{tag}.npy", z)
    np.save(f"{out}/uv-{tag}.npy", uv.astype(np.float32))
    np.save(f"{out}/rgb-{tag}.npy", srgb.astype(np.float32))
    return parts, names, layers, idx


def main(out):
    import os
    os.makedirs(out + "/masks", exist_ok=True)
    parts_o, names_o, layers_o, idx_o = render_state(g.LEAD_OPEN, out, "open")
    parts_s, names_s, layers_s, idx_s = render_state(g.LEAD_SHUT, out, "shut")
    # per-part masks (open state; the leaf's from the shut state)
    for i, nm in enumerate(names_o):
        m = idx_o == i
        if m.any():
            Image.fromarray((m * 255).astype(np.uint8)).save(f"{out}/masks/{nm.replace(':', '--')}.png")
    for i, nm in enumerate(names_s):
        if nm.startswith("leaf"):
            m = idx_s == i
            if m.any():
                Image.fromarray((m * 255).astype(np.uint8)).save(f"{out}/masks/shut--{nm}.png")
    # spec: screen numbers of the key points
    def P(s, n, h):
        x, y = g.project(g.W(s, n, h))
        return [round(float(x), 2), round(float(y), 2)]
    spec = {
        "camera": {"vp": [g.VPX, g.HOR], "walk_line_depth_m": g.D0, "px_per_m": g.PPM, "eye_height_m": round(float(g.EYE[1]), 4)},
        "wall": {"angle_deg": 17, "thickness_m": g.T, "approach_face_crosses_walk_line_x": g.X_CROSS, "back_wall_depth_m": g.Z_BACK,
                 "meets_back_wall_screen": P(g.s_at_z(g.Z_BACK), 0, 0)},
        "opening": {"clear_width_m": g.S_FAR - g.S_NEAR, "clear_height_m": g.H_OPEN,
                    "far_jamb_floor": P(g.S_FAR, 0, 0), "far_jamb_head": P(g.S_FAR, 0, g.H_OPEN),
                    "near_jamb_floor": P(g.S_NEAR, 0, 0), "near_jamb_head": P(g.S_NEAR, 0, g.H_OPEN),
                    "pocket_mouth_floor": P(g.S_FAR, (g.SLOT_N0 + g.SLOT_N1) / 2, 0),
                    "departure_far_floor": P(g.S_FAR, g.T, 0)},
        "leaf": {"width_m": g.LEAF_W, "height_m": g.LEAF_H, "thickness_m": g.LEAF_N1 - g.LEAF_N0,
                 "lead_shut_s": g.LEAD_SHUT, "lead_open_s": g.LEAD_OPEN, "travel_m": g.LEAD_OPEN - g.LEAD_SHUT,
                 "lead_shut_bottom": P(g.LEAD_SHUT, g.LEAF_N0, 0.004), "lead_shut_top": P(g.LEAD_SHUT, g.LEAF_N0, g.LEAF_H),
                 "lead_open_bottom": P(g.LEAD_OPEN, g.LEAF_N0, 0.004), "lead_open_top": P(g.LEAD_OPEN, g.LEAF_N0, g.LEAF_H)},
        "lamp_globe_centre": [round(float(v), 2) for v in g.project(g.W(1.98, -0.17, g.H_OPEN + g.TRIM + 0.18))],
        "lights": {"L1_junction_fitting_m": [round(float(v), 3) for v in g.L1], "L2_passage_fitting_m": [round(float(v), 3) for v in g.L2]},
        "canvas": {"x0": X0, "y0": Y0, "x1": X1, "y1": Y1, "px_per_world_px": PPW},
        "parts": sorted(set(n.split(":")[0] for n in names_o)),
        "layers": {n: layers_o[n] for n in names_o},
    }
    json.dump(spec, open(f"{out}/spec.json", "w"), indent=1)
    print(json.dumps({k: spec[k] for k in ("wall", "opening", "leaf", "lamp_globe_centre")}, indent=1))


if __name__ == "__main__":
    main(sys.argv[1])
