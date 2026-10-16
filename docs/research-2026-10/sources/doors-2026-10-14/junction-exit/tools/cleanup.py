"""Junction exit door: deterministic cleanup of the two Codex paint-overs into the game's layers
(scratch only). Codex painted material and light only; this re-imposes the design's masks (every
silhouette comes from the ray-cast parts in geom.py, never from the paint), calms the large concrete
faces, clamps each part's value to the design's value plan, grades everything into the junction's
cold palette, and writes:

  layers/<layer>.png   at 2 source px per world px (the game's room scale): beyond, back, lens, front,
                       each on the design canvas (world x0..x1, y0..y1), premultiplied-resampled;
  layers/leaf.png      the sliding leaf (shut, lit in place) at 2 px per world px;
  layers/review-*.png  composites for review (shut, open) on a dark ground.

Usage: python cleanup.py HATCH_DIR
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import geom as g  # noqa: E402
import design as d  # noqa: E402
import imgkit as k  # noqa: E402

H = sys.argv[1]
D = f"{H}/design/v8"  # fix round 2
C = f"{H}/design/v8/compose"
CODEX = os.path.abspath(f"{H}/../codex")
OUT = f"{H}/layers"
os.makedirs(OUT, exist_ok=True)

# The junction's cold light, as a linear-RGB gain at constant luminance: about half the chroma of the
# room's own lit back wall (far plate mean 26, 48, 58), so the concrete reads as grey concrete under
# the same cold LEDs, not as a teal wall.
ASSETS = os.path.abspath(f"{H}/../main-hatch/apps/game/assets")
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools"))
import grade2 as G  # noqa: E402  (fix round 2: one light logic, linear, at the corner)
CONCRETE_MEDIAN = 36.0
SHOULDER = 46.0
GAIN = [1.0]
FLOOR_MASK = [None]
FLOOR_INFO: dict = {}
# fix round 3: the floor between the wall's foot and the walk line is the room's deck moved this far
DECK_DX = 1.5          # m along the room (left), so the source stays on the mid plate (x < 958)
DECK_DZ_MARGIN = 0.6   # m in front of the walk line beyond the deepest floor point (off the deck's lit lip)
TINT = np.array([0.80, 1.00, 1.12])
TINT = TINT / (TINT * np.array([0.2126, 0.7152, 0.0722])).sum()
CONCRETE = {"back_face", "lintel_face", "front_face", "below_sill", "col_end", "stub_face", "stub_top", "stub_cut"}
STEEL_FLAT = {"far_jamb_trim", "near_jamb_trim", "head_trim", "reveal_front", "reveal_near", "col_arris_face", "col_arris_l", "col_arris_r", "stub_angle"}
CALM = {"pass_wall": (5.0, 0.5), "pass_floor": (5.0, 0.5)}


def tint(rgb: np.ndarray, m: np.ndarray, amount: float = 1.0) -> np.ndarray:
    lin = k.to_lin(rgb)
    out = k.to_srgb(lin * (1 + amount * (TINT - 1)))
    return np.where(m[..., None], out, rgb)


def part_names(parts) -> list[str]:
    return [p.name for p in parts]


def wall() -> dict:
    reg = json.load(open(f"{C}/registration.json"))
    w, h = reg["design_size"]
    tw = 1024 - reg["pad_right"]
    target = k.load_rgb(f"{C}/1-edit-target-exit-door.png")
    painted = k.load_rgb(f"{CODEX}/r2-junction-exit/out/r2-junction-exit-painted.png")
    warped, tr = k.register(painted, target, scales=np.linspace(0.985, 1.015, 7), shift=4)
    print("wall registration", tr)
    p = k.resize(warped[:, :tw], (w, h))
    tgt = k.resize(target[:, :tw], (w, h))
    fid = k.fidelity(p, tgt, np.ones((h, w)))
    print("wall fidelity", fid)

    parts = g.parts(g.LEAD_OPEN, True)
    names = part_names(parts)
    layer_of = {pt.name: pt.layer for pt in parts}
    idx = np.load(f"{D}/idx-open.npy")
    uv = np.load(f"{D}/uv-open.npy")
    drgb = np.load(f"{D}/rgb-open.npy").astype(np.float64)
    parts_n = g.parts(g.LEAD_OPEN, False)
    names_n = part_names(parts_n)
    idx_n = np.load(f"{D}/idx-noleaf.npy")
    uv_n = np.load(f"{D}/uv-noleaf.npy")
    drgb_n = np.load(f"{D}/rgb-noleaf.npy").astype(np.float64)

    # Colour starts as the paint; where the paint touched the key (outline band), the nearest interior
    # paint stands in, so no magenta fringe survives.
    mine = (idx >= 0) & np.array([layer_of[n] != "key" for n in names] + [False])[idx]
    valid = k.magenta_alpha(p) > 0.99
    # The paint's own key edge drifts by up to a pixel or two from the design's silhouette after
    # registration and resampling: every pixel within 3 px of the silhouette takes the colour of the
    # nearest pixel further in, and nothing outside the silhouette is ever kept.
    valid &= ndimage.binary_erosion(mine, iterations=3)
    # The paint feathers the key into the piece over several pixels: near the silhouette, any pixel
    # with a magenta cast (red and blue over green) is not paint either. (The yellow stripes and the
    # riser are far from the key edge.)
    near_edge = mine & ~ndimage.binary_erosion(mine, iterations=14)
    cast = (p[..., 0] + p[..., 2]) * 0.5 - p[..., 1]
    valid &= ~(near_edge & (cast > 6.0))
    rgb = k.decontaminate(p, (mine & valid).astype(float), band=0)
    _, (iy, ix) = ndimage.distance_transform_edt(~(mine & valid), return_indices=True)
    rgb = np.where((mine & ~valid)[..., None], p[iy, ix], rgb)
    # Outside the silhouette too (so the blurs below never pull the key in).
    rgb = np.where((~mine)[..., None], p[iy, ix], rgb)

    # Per part: calm the big faces, clamp the value to the design's plan.
    gains = {}
    # The cross-wall's concrete is one cast face, split only by where it draws (behind or in front of
    # the walk line): calmed and value-matched as one surface, so no seam shows at the splits.
    conc = np.isin(idx, [i for i, nm in enumerate(names) if nm in CONCRETE])
    rgb = k.calm(rgb, conc.astype(float), 7.0, 0.9)  # fix round 1: keep the paint's grain and grime
    rgb, gains["concrete"] = k.match_part(rgb, drgb, conc.astype(float), tol=0.10, valid=valid)
    rgb = k.match_chroma(rgb, drgb, conc.astype(float), strength=0.7, valid=valid)
    for i, nm in enumerate(names):
        m = idx == i
        if not m.any() or layer_of[nm] == "key":
            continue
        base = nm.split(":")[0]
        mf = m.astype(float)
        if base in CONCRETE:
            continue
        elif base in CALM:
            s, keep = CALM[base]
            rgb = k.calm(rgb, mf, s, keep)
            tol = 0.12
        elif base in STEEL_FLAT:
            rgb = k.calm(rgb, mf, 2.0, 0.7)
            tol = 0.12
        else:
            tol = 0.15
        if m.sum() < 60:
            # Small hardware: the paint has too few pixels to hold its own value; the design's shading
            # with the paint's fine texture.
            lo = np.stack([ndimage.gaussian_filter(rgb[..., c], 1.0) for c in range(3)], -1)
            rgb = np.where(m[..., None], drgb + 0.5 * (rgb - lo), rgb)
            continue
        rgb, gk = k.match_part(rgb, drgb, mf, tol=tol, valid=valid)
        gains[nm] = gk
        rgb = k.match_chroma(rgb, drgb, mf, strength=0.7, valid=valid)

    # The riser under the bolt panel (compose.py): its paint as it is, value-matched to its design.
    riser = (np.asarray(Image.open(f"{C}/mask-riser.png")) > 0) | (np.asarray(Image.open(f"{C}/mask-riser-flange.png")) > 0)
    full = np.asarray(Image.open(f"{C}/design-open-full.png")).astype(np.float64)[..., :3]
    rgb = np.where(riser[..., None], np.where(valid[..., None], p, full), rgb)

    # The status lamp's globe: a clear glass globe the game tints live (modulate), so it is drawn as
    # bright neutral glass, brightest at its centre, with the guard bars' shadow kept from the paint.
    gl = names.index("lamp_globe")
    gm = idx == gl
    if gm.any():
        yy, xx = np.nonzero(gm)
        cy, cx = yy.mean(), xx.mean()
        r = np.hypot(yy - cy, xx - cx) / max(np.hypot(yy - cy, xx - cx).max(), 1)
        lum_p = k.lum(p[gm])
        shadow = np.clip(lum_p / max(np.percentile(lum_p, 90), 1), 0.55, 1.0)
        v = (245 - 85 * r ** 1.6) * shadow
        rgb[gm] = v[:, None] * np.array([1.0, 1.0, 1.0])

    # The junction's floor between the walk line and the wall's foot (behind the walk line, on the
    # room's side of the wall): the room's painting has no floor there (its walkway meets its back wall
    # at the walk line), so the wall would stand on nothing. It is the deck's own dark tone, falling
    # off into a contact shadow along the wall's foot, with the faintest luminance grain.
    X, Y = d.grid(d.X0, d.X1, d.Y0, d.Y1, d.PPW)
    with np.errstate(divide="ignore", invalid="ignore"):
        zf = g.D0 * (g.FLOOR - Y) / (Y - g.HOR)
    P0, B = g.rays(X, Y)
    pf = P0 + zf[..., None] * B
    nf = ((pf - g.C) * g.V).sum(-1)
    zbest = np.load(f"{D}/z-open.npy")
    floor = mine & (Y < g.FLOOR) & (zf > 0) & (zf < zbest - 1e-3) & (nf < 0.0)
    floor &= ~np.isin(idx, [i for i, nm in enumerate(names) if layer_of[nm] in ("front", "lens")])
    shade = 0.45 + 0.55 * np.clip(-nf / 0.9, 0, 1) ** 0.7
    # Fix round 3 (review r3, human pass: "a flat, smooth, lighter grey patch ... reads as a placeholder
    # plane next to the wet deck"): the floor here is the room's own deck, not one flat tone. Each floor
    # point takes the mid plate's deck at the same point moved DECK_DZ nearer the camera and DECK_DX along
    # the room (a 3D translation in the room's camera, as hinstall.deck_piece and jentry's jemid.py do),
    # so its plate seams, wet sheen and grime run on to the room's vanishing point; then the wall's
    # contact shadow along its foot. It is kept out of the wall's row gains (grade_room: keep), which
    # had lifted it to a light grey.
    mid = np.asarray(Image.open(ASSETS + "/rooms/junction-mid.png").convert("RGB")).astype(np.float64)
    zmax = float(zf[floor].max())
    dz = zmax + DECK_DZ_MARGIN
    src = pf[floor] - np.array([DECK_DX, 0.0, dz])
    xs_, ys_ = g.project(src)
    assert xs_.max() < 958.0 and ys_.min() > 440.5 and ys_.max() < 590.0, (xs_.min(), xs_.max(), ys_.min(), ys_.max())
    sx, sy = xs_ * 2.0 - 0.5, (ys_ - 52.0) * 2.0 - 0.5
    deck_rgb = np.stack([ndimage.map_coordinates(mid[..., c], [sy, sx], order=1, mode="nearest") for c in range(3)], -1)
    floor_rgb = rgb.copy()
    floor_rgb[floor] = k.to_srgb(k.to_lin(deck_rgb) * shade[floor][:, None])
    rgb = np.where(floor[..., None], floor_rgb, rgb)
    FLOOR_MASK[0] = floor
    FLOOR_INFO.update({"deck_shift_m": [DECK_DX, round(dz, 3)], "floor_depth_max_m": round(zmax, 3), "source_world_x": [round(float(xs_.min()), 1), round(float(xs_.max()), 1)], "source_world_y": [round(float(ys_.min()), 1), round(float(ys_.max()), 1)]})

    # Grade into the room's cold light (not the lamp glass, not the riser, not the yellow edge).
    keep_colour = gm | riser
    for nm in ("leaf_edge",):
        if nm in names:
            keep_colour |= idx == names.index(nm)
    rgb = tint(rgb, mine & ~keep_colour & ~floor)

    # Exposure: the facility's concrete reads as it does at the corridor's approved door end (its wall
    # in the game: median about 34 sRGB, 22..49), so the cross-wall sits in the room's dark instead of
    # standing out as a pale slab. One linear gain for everything lit by the room's light (the passage
    # and the leaf too, so their light keeps its relation to the wall), then a soft shoulder on the
    # concrete near the junction's fitting. The fittings' lenses and the lamp's glass keep their value.
    conc = np.isin(idx, [i for i, nm in enumerate(names) if nm in CONCRETE]) & ~floor
    emissive = np.isin(idx, [i for i, nm in enumerate(names) if nm in ("wallpack_lens", "pass_fitting", "lamp_globe")])
    lin = k.to_lin(rgb)
    med = np.median(k.lum(lin[conc]))
    gain = float(k.to_lin(np.array(CONCRETE_MEDIAN)) / med)
    GAIN[0] = gain
    lit = mine & ~emissive & ~floor & ~riser
    lin = np.where(lit[..., None], lin * gain, lin)
    out = k.to_srgb(lin)
    L = k.lum(out)
    knee = SHOULDER
    Ls = np.where(L > knee, knee + (L - knee) * 0.7, L)
    ratio = np.where(L > 1e-3, Ls / np.maximum(L, 1e-3), 1.0)
    out = np.where((conc & (L > knee))[..., None], out * ratio[..., None], out)
    # The junction's ceiling fitting is a cold LED a metre off the wall's top corner: what it lights
    # on the concrete takes its colour, more the brighter it is (the room's own wall under it is cyan).
    L2_ = k.lum(out)
    wash = np.clip((L2_ - 30.0) / 40.0, 0, 1) * conc
    cold = np.array([0.78, 1.0, 1.24])
    cold = cold / (cold * np.array([0.2126, 0.7152, 0.0722])).sum()
    out = np.where(conc[..., None], k.to_srgb(k.to_lin(out) * (1 + wash[..., None] * (cold - 1))), out)
    rgb = np.where(mine[..., None], out, rgb)
    print("exposure gain", round(gain, 4), "concrete median before", round(float(k.to_srgb(np.array(med))), 1))

    # Fix round 3 (review r3 S2): the pipe runs and their escutcheons, from the model, at final values.
    rgb, fixed = pipe_runs(rgb, idx, names, X, Y)
    fixed |= floor

    # Layers (open state). The sill behind the leaf's line (n > LEAF_N0) goes to 'beyond', under the
    # leaf, so the shut leaf stands in front of it.
    layers = {}
    for L in ("beyond", "back", "lens", "front"):
        layers[L] = np.zeros((h, w), bool)
    for i, nm in enumerate(names):
        L = layer_of[nm]
        if L in layers:
            layers[L] |= idx == i
    layers["back"] |= floor
    sill = idx == names.index("sill")
    sill_rear = sill & (uv[..., 1] * g.T > g.LEAF_N0 - 0.005)
    layers["back"] &= ~sill_rear
    layers["beyond"] |= sill_rear
    layers["back"] |= riser & ~mine

    # 'beyond' must also hold what the leaf hides in the open state (the pocket mouth behind its
    # edge): there the no-leaf cast shows, value-graded like its part.
    leaf_idx = [i for i, nm in enumerate(names) if nm.startswith("leaf")]
    hidden = np.isin(idx, leaf_idx)
    lay_n = {pt.name: pt.layer for pt in parts_n}
    beyond_n = np.array([lay_n[n] == "beyond" for n in names_n] + [False])[idx_n]
    sill_n = idx_n == names_n.index("sill")
    beyond_n |= sill_n & (uv_n[..., 1] * g.T > g.LEAF_N0 - 0.005)
    fill = hidden & beyond_n
    fill_rgb = k.to_srgb(k.to_lin(tint(drgb_n, np.ones((h, w), bool))) * GAIN[0])
    # Calm, dark: the pocket is unlit steel and the passage floor its own value.
    rgb = np.where(fill[..., None], fill_rgb, rgb)
    layers["beyond"] |= fill
    # Same pixel, same surface in both casts: the beyond layer under the leaf continues seamlessly.

    # Each layer runs on under every layer drawn over it (beyond < back < lens < front), so where two
    # layers meet, their resampled edges overlap instead of both fading out over the ground.
    over = {"beyond": ("back", "lens", "front"), "back": ("lens", "front"), "lens": ("front",)}
    under = {}
    for L, ups in over.items():
        cover = np.zeros((h, w), bool)
        for U in ups:
            cover |= layers[U]
        under[L] = layers[L] | (ndimage.binary_dilation(layers[L], iterations=3) & cover)
    layers.update(under)
    np.save(f"{OUT}/wall-rgb.npy", rgb.astype(np.float32))
    for L, m in layers.items():
        np.save(f"{OUT}/mask-{L}.npy", m)
    return {"rgb": rgb, "layers": layers, "registration": tr, "fidelity": fid, "gains": gains, "size": (w, h),
            "idx": idx, "names": names, "conc": conc, "emissive": emissive, "fixed": fixed}


# Fix round 3 (review r3, S2: "four stacked black knobs"): the room's four back-wall pipes reach this
# wall's back corner 0.3 m off the back wall and pass into the face. Round 2 drew the short run between
# the corner and the face as a flat dark band in the face plane and the escutcheon as a square plate, and
# the paint merged the two into one round 8.5 x 10 px knob per pipe. Here each pipe is a cylinder along
# the room (axis at h, z = Z_BACK - 0.30) from the corner to where it enters the face, valued from the
# room's own pipes beside it (render.sh j08, just left of the corner: a thin cyan highlight on its top
# over a dark body), and the escutcheon is a 50 mm-wide steel ring in the face plane round the pipe,
# 10 mm proud; seen on a face turned 17 degrees it projects to a narrow upright ellipse (the model gives
# about 0.52 of its height) with the pipe running into it. Old collar and band pixels that neither
# covers are the face's concrete, taken from the same row 12 world px further along the face.
PIPE_BODY = np.array([22.0, 50.0, 64.0])
PIPE_HL = (np.array([96.0, 168.0, 207.0]), np.array([132.0, 210.0, 238.0]), np.array([117.0, 188.0, 227.0]), np.array([100.0, 170.0, 205.0]))
RING_BASE = np.array([36.0, 42.0, 48.0])
RING_LIT = np.array([78.0, 92.0, 104.0])
RING_DARK = np.array([14.0, 17.0, 20.0])
ESC_W, ESC_PROUD = 0.05, 0.010
PIPE_INFO: list = []


def pipe_runs(rgb: np.ndarray, idx: np.ndarray, names: list, X: np.ndarray, Y: np.ndarray):
    P0, B = g.rays(X, Y)
    old = np.isin(idx, [i for i, nm in enumerate(names) if nm.startswith(("pipe_collar", "pipe_stub"))])
    out = rgb.copy()
    fixed = np.zeros(idx.shape, bool)
    s_corner = g.s_at_z(g.Z_BACK, 0.0)
    x_corner = float(g.project(g.W(s_corner, 0.0, 3.0))[0])
    zc = g.Z_BACK - 0.30
    s_in = g.s_at_z(zc, 0.0)
    BV = (B * g.V).sum(-1)
    for i, (hp, rp) in enumerate(g.PIPE_RUNS_EXIT):
        rc = rp + ESC_W
        # the escutcheon: the plane n = -ESC_PROUD
        with np.errstate(divide="ignore", invalid="ignore"):
            t_r = (-ESC_PROUD + np.dot(g.C, g.V) - (P0 * g.V).sum(-1)) / BV
        pr = P0 + t_r[..., None] * B
        s_r = ((pr - g.C) * g.U).sum(-1)
        h_r = pr[..., 1]
        rr = np.hypot((s_r - s_in), (h_r - hp))
        ring = (rr <= rc) & np.isfinite(t_r)
        # the pipe: (y - hp)^2 + (z - zc)^2 = rp^2 on the ray (z = t)
        dy = P0[..., 1] - hp
        a = B[..., 1] ** 2 + 1.0
        b = 2.0 * (B[..., 1] * dy - zc)
        c = dy ** 2 + zc ** 2 - rp ** 2
        disc = b * b - 4 * a * c
        with np.errstate(invalid="ignore"):
            t_p = (-b - np.sqrt(disc)) / (2 * a)
        pp = P0 + np.where(disc >= 0, t_p, 0.0)[..., None] * B
        n_p = ((pp - g.C) * g.V).sum(-1)
        pipe = (disc >= 0) & (n_p <= -ESC_PROUD) & (X >= x_corner)
        pipe_front = pipe & (~ring | (t_p <= t_r))
        ring_vis = ring & ~pipe_front
        # inside the ring's hole the pipe runs on into the wall: its body, in the ring's shade
        hole = ring_vis & (rr < rp)
        # pipe shading: normal in the y-z plane; the camera, 7 m up, sees its top
        ny = np.clip((pp[..., 1] - hp) / rp, -1, 1)
        hl = np.clip((ny - 0.55) / 0.35, 0, 1) ** 1.5
        body = PIPE_BODY[None, None, :] * (0.7 + 0.4 * np.clip(ny, 0, 1))[..., None]
        pcol = body + hl[..., None] * (PIPE_HL[i][None, None, :] - body)
        # ring shading: lit along its upper rim (the ceiling fitting), dark along its lower rim and in
        # the shadow the pipe casts on it just below the pipe
        ang = np.arctan2(h_r - hp, s_r - s_in)
        rim = (rr > rc - 0.022)
        lit = rim & (np.sin(ang) > 0.35)
        dark = (rim & (np.sin(ang) < -0.45)) | ((h_r < hp - rp) & (h_r > hp - rp - 0.03) & (s_r < s_in + rp))
        rcol = np.where(lit[..., None], RING_LIT, np.where(dark[..., None], RING_DARK, RING_BASE))
        rcol = np.where(hole[..., None], PIPE_BODY * 0.55, rcol)
        out = np.where(pipe_front[..., None], pcol, out)
        out = np.where(ring_vis[..., None], rcol, out)
        fixed |= pipe_front | ring_vis
        ys_, xs_ = np.nonzero(ring_vis)
        if len(xs_):
            w_ = (xs_.max() - xs_.min() + 1) / d.PPW
            h_ = (ys_.max() - ys_.min() + 1) / d.PPW
            PIPE_INFO.append({"pipe": i, "ring_world_w": round(float(w_), 2), "ring_world_h": round(float(h_), 2), "w_over_h": round(float(w_ / h_), 2),
                              "pipe_px": int(pipe_front.sum()), "ring_px": int(ring_vis.sum())})
    # what the old band and square collar covered and the new parts do not: the face's own concrete
    # (and the paint's knob halo, up to 2 world px outside the old masks on the face)
    face = idx == names.index("back_face")
    vac = ((old | (ndimage.binary_dilation(old, iterations=int(2 * d.PPW)) & face)) & ~fixed)
    ys_, xs_ = np.nonzero(vac)
    face = face & ~ndimage.binary_dilation(old, iterations=int(2 * d.PPW))
    shift = int(round(12 * d.PPW))
    for y_, x_ in zip(ys_, xs_):
        xx = x_ + shift
        while xx < idx.shape[1] - 1 and not face[y_, xx]:
            xx += 1
        out[y_, x_] = out[y_, min(xx, idx.shape[1] - 1)]
    return out, fixed


def leaf() -> dict:
    reg = json.load(open(f"{C}/registration-leaf.json"))
    target = k.load_rgb(f"{C}/1-edit-target-leaf.png")
    painted = k.load_rgb(f"{CODEX}/r2-junction-exit/out/r2-junction-exit-leaf-painted.png")
    painted = k.resize(painted, (1024, 1024))
    warped, tr = k.register(painted, target, scales=np.linspace(0.97, 1.03, 13), shift=6)
    print("leaf registration", tr)
    lw, lh = reg["leaf_size"]
    ox, oy = reg["offset"]
    p = warped[oy:oy + lh, ox:ox + lw]
    des = np.asarray(Image.open(f"{D}/leaf-design-8.png")).astype(np.float64)
    drgb, da = des[..., :3], des[..., 3] / 255.0
    valid = k.magenta_alpha(p) > 0.99
    # Fix round 3 (review r3, R3-1: a violet fringe on the leaf's left and bottom edges): the paint's key
    # edge drifts a few 8x pixels inside the design's silhouette after registration, and its dark,
    # key-tinted pixels (e.g. 66, 42, 100) pass magenta_alpha. As in wall(): nothing within 6 px (0.75
    # world px) of the silhouette is kept, and near it no pixel with a magenta cast (red and blue over
    # green) counts as paint; all of them take the colour of the nearest kept pixel further in.
    inside = da > 0.5
    valid &= ndimage.binary_erosion(inside, iterations=6)
    near_edge = inside & ~ndimage.binary_erosion(inside, iterations=24)
    cast = (p[..., 0] + p[..., 2]) * 0.5 - p[..., 1]
    valid &= ~(near_edge & (cast > 6.0))
    rgb = k.decontaminate(p, inside & valid, band=0)
    _, (iy, ix) = ndimage.distance_transform_edt(~(inside & valid), return_indices=True)
    rgb = np.where((~(inside & valid))[..., None], rgb[iy, ix], rgb)
    for nm, keep in (("leaf_face", 0.65), ("leaf_top", 0.5), ("leaf_edge", 0.9)):
        m = np.asarray(Image.open(f"{D}/leaf-mask-{nm}-8.png")) > 0
        if nm == "leaf_face":
            rgb = k.calm(rgb, m.astype(float), 6.0, keep)
        rgb, _ = k.match_part(rgb, drgb, m.astype(float), tol=0.12, valid=valid)
        rgb = k.match_chroma(rgb, drgb, m.astype(float), strength=0.7, valid=valid)
    edge = np.asarray(Image.open(f"{D}/leaf-mask-leaf_edge-8.png")) > 0
    rgb = tint(rgb, (da > 0.5) & ~edge)
    # The wall's exposure, eased for the leaf: it stands right under the wall pack and is painted
    # steel, and at the wall's full gain its face went near black, reading as a hole, not a door.
    rgb = np.where((da > 0)[..., None], k.to_srgb(k.to_lin(rgb) * GAIN[0] ** 0.5), rgb)
    fid = k.fidelity(rgb, drgb, da)
    print("leaf fidelity", fid)
    # 8 -> 2 px per world px, premultiplied
    a4 = k.resize(da, (lw // 4, lh // 4))
    c4 = k.resize(rgb * da[..., None], (lw // 4, lh // 4))
    a4 = np.clip(a4, 0, 1)
    c4 = np.where(a4[..., None] > 1e-3, c4 / np.maximum(a4[..., None], 1e-3), 0)
    k.save_rgba(c4, a4, f"{OUT}/leaf.png")
    # anchor: the leading edge's bottom corner, in leaf.png pixels (leaf.py grid: world 930, 328)
    x, y = g.project(g.W(g.LEAD_SHUT, g.LEAF_N0, 0.0))
    anchor = [round((float(x) - 930.0) * 2.0, 2), round((float(y) - 328.0) * 2.0, 2)]
    return {"registration": tr, "fidelity": fid, "size": [lw // 4, lh // 4], "anchor": anchor, "rgb8": rgb, "a8": da}


def to_game_scale(rgb: np.ndarray, m: np.ndarray, size: tuple) -> tuple[np.ndarray, np.ndarray]:
    w, h = size
    a = m.astype(np.float64)
    a2 = np.clip(k.resize(a, (w // 2, h // 2)), 0, 1)
    c2 = k.resize(rgb * a[..., None], (w // 2, h // 2))
    c2 = np.where(a2[..., None] > 1e-3, c2 / np.maximum(a2[..., None], 1e-3), 0)
    a2[a2 < 0.02] = 0
    return c2, a2


def grade_room(W: dict, L: dict) -> dict:
    """Fix round 1 (M1): the concrete row by row at 0.70x the junction's back wall at the same height
    (grade.py); the passage beyond at PASSAGE_RATIO; lenses kept; the leaf by the eased median gain."""
    prof = G.profile("junction-exit")
    rgb, idx, names = W["rgb"], W["idx"], W["names"]
    u8 = np.clip(rgb, 0, 255).astype(np.uint8)
    rgba = np.dstack([u8, np.full(u8.shape[:2], 255, np.uint8)])
    # 0.62x here, not 0.70x: the exit wall's upper face stands right under the junction's right ceiling
    # fitting, whose painted pool lifts it; at 0.70x it still read brighter than the back wall beside it.
    # fix round 2 (N3): RATIO x the back wall at the corner, measured at the corner (the face there sees
    # the junction's right ceiling fitting, so it is lit with it); linear light
    g = G.row_gains(rgba, W["conc"].astype(float), d.Y0, d.PPW, prof, world_x0=d.X0, xr=G.wall_x("junction-exit"))
    gw = G.gains_to_world(g, d.Y0, d.PPW)
    gw = G.with_feedback("junction-exit", gw)  # fix round 2: closed on the last render.sh pass (feedback.py)
    passage = np.isin(idx, [i for i, nm in enumerate(names) if nm in ("pass_wall", "pass_floor")])
    gb = G.gains_to_world(G.row_gains(rgba, passage.astype(float), d.Y0, d.PPW, prof, ratio=G.PASSAGE_RATIO), d.Y0, d.PPW)
    # fix round 3: the deck at the wall's foot and the pipe runs and escutcheons (drawn from the model at
    # their final values) take no wall gain
    keep = (W["emissive"] | W["fixed"]).astype(float)
    meds = G.row_medians(rgba, W["conc"].astype(float), d.Y0, d.PPW)
    pmeds = G.row_medians(rgba, passage.astype(float), d.Y0, d.PPW)
    a = G.apply_world_gains(rgba, d.Y0, d.PPW, gw, np.maximum(keep, passage), meds)
    b = G.apply_world_gains(rgba, d.Y0, d.PPW, gb, keep, pmeds)
    out = np.where(passage[..., None], b, a)
    out = G.boost_detail(out, (W["conc"] | passage).astype(float), ppw=d.PPW)
    W["rgb"] = out[..., :3].astype(np.float64)
    # fix round 2 (N3): the leaf (painted steel) at LEAF_FRAC x the graded concrete beside the door
    rows = d.Y0 + (np.arange(out.shape[0]) + 0.5) / d.PPW
    xs = d.X0 + (np.arange(out.shape[1]) + 0.5) / d.PPW
    band = ((rows >= 342.0) & (rows <= 440.0))[:, None] & ((xs >= 940.0) & (xs <= 1000.0))[None, :]
    wall_med = G.masked_median(out, W["conc"].astype(float) * band)
    la = L["a8"].astype(np.float64)
    la = la / 255.0 if la.max() > 1.0 else la
    leaf_rgba = np.dstack([np.clip(L["rgb8"], 0, 255).astype(np.uint8), (la * 255).astype(np.uint8)])
    leaf_med = G.masked_median(leaf_rgba, (la > 0.99).astype(float))
    lg = G.leaf_gain(leaf_med, wall_med) * G.LEAF_FB.get("junction-exit", 1.0)
    return {"leaf_gain": round(lg, 3), "wall_med_door_rows": round(wall_med, 5), "leaf_med_before": round(leaf_med, 5), "wall_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gw[0][::40], gw[1][::40])}}


def main() -> None:
    W = wall()
    L = leaf()
    GR = grade_room(W, L)
    leaf_png = Image.open(f"{OUT}/leaf.png")
    Image.fromarray(G.scale_lin(np.asarray(leaf_png.convert("RGBA")), GR["leaf_gain"]), "RGBA").save(f"{OUT}/leaf.png")  # fix round 2: linear
    w, h = W["size"]
    out = {}
    for name, m in W["layers"].items():
        c2, a2 = to_game_scale(W["rgb"], m, (w, h))
        k.save_rgba(c2, a2, f"{OUT}/{name}.png")
        out[name] = (c2, a2)
    json.dump({"wall_registration": W["registration"], "wall_fidelity": W["fidelity"], "part_gains": W["gains"],
               "leaf_registration": L["registration"], "leaf_fidelity": L["fidelity"], "leaf_size": L["size"], "leaf_anchor": L["anchor"],
               "canvas_world": [d.X0, d.Y0, d.X1, d.Y1], "layer_px_per_world_px": 2, "room_grade": GR,
               "fix_round_3": {"floor": FLOOR_INFO, "pipe_runs": PIPE_INFO}},
              open(f"{OUT}/cleanup.json", "w"), indent=1)
    # review composites (game scale): dark ground, beyond, leaf (shut/open), back, lens, front
    leaf_img = Image.open(f"{OUT}/leaf.png")
    for state in ("shut", "open"):
        bg = Image.new("RGBA", (w // 2, h // 2), (14, 22, 27, 255))
        for name in ("beyond",):
            bg.alpha_composite(Image.open(f"{OUT}/{name}.png"))
        s = g.LEAD_SHUT if state == "shut" else g.LEAD_OPEN
        x, y = g.project(g.W(s, g.LEAF_N0, 0.0))
        zf = (38.0 + (g.LEAD_SHUT * g.U[2] + g.LEAF_N0 * g.V[2])) / (38.0 + (s * g.U[2] + g.LEAF_N0 * g.V[2]))
        lf = leaf_img.resize((max(1, round(leaf_img.width * zf)), max(1, round(leaf_img.height * zf))), Image.Resampling.LANCZOS)
        ax, ay = L["anchor"][0] * zf, L["anchor"][1] * zf
        px, py = (float(x) - d.X0) * 2 - ax, (float(y) - d.Y0) * 2 - ay
        layer = Image.new("RGBA", bg.size, (0, 0, 0, 0))
        layer.paste(lf, (round(px), round(py)))
        bg.alpha_composite(layer)
        for name in ("back", "lens", "front"):
            bg.alpha_composite(Image.open(f"{OUT}/{name}.png"))
        bg.save(f"{OUT}/review-{state}.png")
    print("cleanup done")


if __name__ == "__main__":
    main()
