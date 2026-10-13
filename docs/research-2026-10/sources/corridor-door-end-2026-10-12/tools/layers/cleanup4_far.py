"""Fix round 3 (v4): the far plate (deterministic; no new image-tool paint). From layers/v3/corridor-far.png.

  must 2a  the floor follows the wall's line. The cross-wall's stub (front layer, world-locked) runs
           from the column's foot along the wall to VP2 (x 21 on the horizon). On its approach side the
           corridor's wet floor carries on to the bottom right of the view; on its far side the plant
           room's dry slab. In the plate the two meet at t = 0.55 m across the wall, under the stub, so
           the far plate's parallax (up to 16 px at the edge of the view, the stub is 25-32 px wide)
           never shows the join. The wet floor there is main's own plate (its lamp-2 streak removed in
           round 1: design/far-patch/far-base-streak-removed.png), matched to the v3 wet floor beside
           it, with a soft reflection of plant high-bay B, the one bright light in view above it.
           The plant slab keeps round 2's painted slab; where the cut band used to hide it, the slab
           is carried left from the slab beside it (rows unchanged, so its joints stay at the
           vanishing point).
  must 2b  the tank's head is redrawn in the plate's camera: the eye is 1.8 m above the tank top
           and 42 m away, so the rim is nearly edge-on (2.2 source px of top surface at the centre)
           and the 0.27 m dished head shows as a low profile (19.5 source px) above it. The head keeps
           its painted texture (its v3 rows, rescaled) and is lit from high-bay B, 0.35 m above the
           crown and 2 m behind it: brightest on the upper curve, falling toward the rim. The old
           head's lower half becomes shell (the shell's own columns), and the wall behind the old
           head's top is filled from the wall each side.
  should   the plant floor's pool beside the column is pulled down so it never reads brighter than
           the actors (in-game target 40-45).
Nothing left of source x 1132 changes. Writes layers/v4/corridor-far.png and layers/v4/far-report.json.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from imgkit import lum, to_lin, to_srgb  # noqa: E402

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "design"))  # the design tools (tools/design/)
import common  # noqa: E402
import portal4 as p4  # noqa: E402

OUT = os.path.join(R, "layers", "v4")
M2 = os.path.join(R, "design", "far-patch2", "masks")
X0 = 1112
FX, FY = 12.444, 78.5
T_JOIN = 0.55


def m2(n):
    return np.asarray(Image.open(os.path.join(M2, n + ".png")).convert("L")).astype(np.float64) / 255.0


def main() -> None:
    report: dict = {}
    v3 = np.asarray(Image.open(os.path.join(R, "layers", "v3", "corridor-far.png")).convert("RGB")).astype(np.float64)
    base = np.asarray(Image.open(os.path.join(R, "design", "far-patch", "far-base-streak-removed.png")).convert("RGB")).astype(np.float64)
    orig = np.asarray(Image.open(os.path.join(R, "game-main", "apps", "game", "assets", "rooms", "corridor-far.png")).convert("RGB")).astype(np.float64)
    H, W = v3.shape[:2]
    out = v3.copy()
    canvas = common.Canvas("far", x0=FX, y0=FY, ppw=2.0, w=W, h=H)
    Xw, Yw = canvas.grid()
    a, t, _ = p4.floor_coords(canvas)
    floor = Yw > 444.0
    roi = floor & (Xw >= 790.0)
    # ---- the wet corridor floor on the stub's approach side
    wet = roi & (t < T_JOIN) & (Yw >= 452.0)
    blin = to_lin(base)
    # brightness match to the v3 wet floor beside it (v3 kept main's floor left of x 826)
    band = wet & (Xw >= 800) & (Xw < 824)
    k = lum(to_lin(v3[band])).mean() / max(lum(blin[band]).mean(), 1e-6)
    wet_src = blin * k
    # a soft reflection of high-bay B (clamp x 905) in the wet floor, from the old plate's own painted
    # lamp streak (the excess of main's plate over the streak-removed base under its old lamp)
    rows = slice(690, 1080)
    ex = np.clip(to_lin(orig[rows, 1536:1744]) - to_lin(base[rows, 1536:1744]), 0, None)
    exl = lum(ndimage.gaussian_filter(ex, (3.0, 3.0, 0)))
    sx = (905.0 - FX) * 2
    wscale, kB = 0.5, 0.07
    xs = np.arange(int(sx - 104 * wscale), int(sx + 104 * wscale))
    src_x = 1640 + (xs - sx) / wscale - 1536
    yy = np.repeat(np.arange(exl.shape[0])[:, None], len(xs), 1)
    streak = ndimage.map_coordinates(exl, [yy, np.repeat(src_x[None, :], exl.shape[0], 0)], order=1, mode="constant")
    refl = np.zeros((H, W))
    refl[rows, xs[0]:xs[-1] + 1] = streak
    tint = np.array([0.93, 0.97, 1.0])
    wet_src = wet_src + kB * refl[..., None] * tint
    # blend in from the v3 floor over x 812..830 (source of both is main's floor, so no seam)
    ramp = np.clip((Xw - 812.0) / 18.0, 0, 1)
    wet_lin = to_lin(v3) * (1 - ramp[..., None]) + wet_src * ramp[..., None]
    out = np.where(wet[..., None], to_srgb(wet_lin), out)
    report["wet_floor"] = {"source": "design/far-patch/far-base-streak-removed.png (main's plate, its lamp-2 streak removed)", "match_gain": round(float(k), 3),
                           "high_bay_B_reflection": {"clamp_x": 905.0, "strength": kB, "width_scale": wscale}, "join_t_m": T_JOIN}
    # ---- the plant slab on the far side: carry round 2's slab left where the cut band hid it
    plant = roi & (t >= T_JOIN) & (Yw >= 448.0) & (Xw < 828.0)
    shift = 64  # source px (32 world px) to the right, the same rows
    carried = np.zeros_like(v3)
    carried[:, :-shift] = v3[:, shift:]
    out = np.where(plant[..., None], carried, out)
    report["plant_slab_carried_px"] = int(plant.sum())
    # the slab toward the camera falls away from the plant room's lights; it is lifted so the corner
    # by the stub never reads as a hole (review round 3: it was luma 13-14 on screen)
    slab = roi & (t >= T_JOIN) & (Yw >= 456.0)
    lift = 1.0 + 0.8 * np.clip((Yw - 462.0) / 50.0, 0, 1)
    out = np.where(slab[..., None], to_srgb(to_lin(out) * lift[..., None]), out)
    report["slab_lift_toward_camera"] = "linear gain 1.0 at y 462 rising to 1.8 by y 512"
    # ---- the pool on the plant floor beside the column, under high-bay A: never brighter than the
    # actors. Its highlights are compressed above luma 38 (slope 0.15), so its shape and texture stay
    # and its peak falls from about 85 to about 45.
    pm = np.zeros((H, W))
    pm[0:808, X0:1920] = np.clip(m2("mach_floor") + m2("mach_floor_near"), 0, 1)
    pool = (pm > 0.5) & (Yw > 391.0) & (Yw < 447.0) & (Xw > 806.0) & (Xw < 900.0)
    Lp = lum(out)
    before = float(ndimage.uniform_filter(Lp, 9)[pool].max())
    want = np.where(Lp > 38.0, 38.0 + (Lp - 38.0) * 0.15, Lp)
    g = to_lin(np.repeat(want[..., None], 3, -1))[..., 0] / np.maximum(to_lin(np.repeat(Lp[..., None], 3, -1))[..., 0], 1e-6)
    g = np.where(pool, g, 1.0)
    g = ndimage.gaussian_filter(g, 1.0)
    out = to_srgb(to_lin(out) * g[..., None])
    after = float(ndimage.uniform_filter(lum(out), 9)[pool].max())
    report["pool_beside_column"] = {"region": "plant floor, clamp x 806..900, y 391..447", "knee_luma": 38.0, "slope_above": 0.15,
                                    "plate_luma_max_9px_before": round(before, 1), "after": round(after, 1)}
    # ---- the tank's head (patch canvas: source x 1112.., y 0..808)
    P = out[0:808, X0:1920].copy()
    head = m2("tank_head") > 0.5
    shell = m2("tank_shell") > 0.5
    hy, hx = np.nonzero(head)
    cx, r = (hx.min() + hx.max()) / 2.0, (hx.max() - hx.min() + 1) / 2.0
    y_rim = (hy.min() + hy.max()) / 2.0  # the v3 ellipse centre: the shell's top (5.2 m)
    tm = 2 * common.PX_PER_M * common.depth_scale(4.0)  # source px per metre at the tank (4 m back)
    rise = 0.27 * tm
    eye_h, dist = 7.04, common.D0 + 4.0
    lip = 0.7 * (eye_h - 5.2) / dist * tm
    yy, xx = np.mgrid[0:808, 0:808].astype(np.float64)
    u = (xx + 0.5 - cx) / r
    inside_u = np.abs(u) <= 1.0
    w_top = np.sqrt(np.clip(1 - u ** 2, 0, 1))
    dome_top = y_rim - rise * w_top
    rim_low = y_rim + lip * w_top
    new_head = inside_u & (yy + 0.5 >= dome_top) & (yy + 0.5 <= rim_low)
    new_shell = inside_u & (yy + 0.5 > rim_low) & (yy <= hy.max() + 1)
    old_only = head & ~new_head & ~new_shell
    src = P.copy()
    # shell rows: each column's own shell paint mirrored about the first row below the old head, so
    # the shell runs up to the rim without a step
    s0 = int(hy.max()) + 2
    for x in np.nonzero(new_shell.any(0))[0]:
        ys = np.nonzero(new_shell[:, x])[0]
        srcy = np.clip(s0 + (s0 - ys), 0, 807)
        P[ys, x] = src[srcy, x]
    shell_top_luma = float(lum(src[s0:s0 + 6][shell[s0:s0 + 6]]).mean())
    # head: the v3 head's paint texture (each pixel over its row's mean), its rows squeezed into the
    # new profile, lit from B behind and above the crown
    Lh = lum(src)
    core = ndimage.binary_erosion(head, iterations=4)
    row_mean = np.array([Lh[y][core[y]].mean() if core[y].any() else 1.0 for y in range(808)])
    tex = np.clip(Lh / np.maximum(row_mean[:, None], 1e-3), 0.8, 1.25)
    tex = np.where(core, tex, 1.0)
    wn = np.clip((y_rim - (yy + 0.5)) / rise, 0, 1)  # 0 at the rim line, 1 at the crown
    # surface normal of the head (an ellipsoid cap, front half) and the light from B
    zf = -np.sqrt(np.clip(1 - u ** 2 - wn ** 2, 0, 1))
    n = np.stack([u / r, wn / rise, zf / r], -1)
    n /= np.maximum(np.linalg.norm(n, axis=-1, keepdims=True), 1e-9)
    Ldir = np.array([0.15, 0.35, 2.0])  # to B: a little right, 0.35 m up, 2 m behind
    Ldir /= np.linalg.norm(Ldir)
    ndl = np.clip((n * Ldir).sum(-1), 0, 1)
    up = np.clip(n[..., 1], 0, 1)
    lit = np.clip((0.6 * ndl + 0.7 * up) / 0.8, 0, 1) ** 1.3
    # sRGB luma: from a little over the shell's own value where the knuckle meets the shell, rising to
    # about 80 on the crest under B (about 60-65 on screen after the grade)
    target = shell_top_luma + 8.0 + (80.0 - shell_top_luma - 8.0) * lit
    # the knuckle's front edge (the weld seam to the shell) catches the overhead light: a thin line
    seam = np.exp(-(((yy + 0.5) - (rim_low - 0.8)) / 0.9) ** 2)
    target = target + 14.0 * seam
    srcy = np.clip((hy.min() + 4 + (yy - dome_top) / np.maximum(rim_low - dome_top, 1) * ((hy.max() - hy.min()) * 0.5 - 4)).astype(int), 0, 807)
    want = np.clip(target * tex[srcy, np.clip(xx.astype(int), 0, 807)], 0, 88)
    colour = src[head].mean(0)
    chroma = to_lin(colour[None, :])[0] / max(lum(to_lin(colour[None, :]))[0], 1e-6)
    hl = to_lin(np.repeat(want[..., None], 3, -1))[..., 0]
    head_rgb = to_srgb(hl[..., None] * chroma)
    P = np.where(new_head[..., None], head_rgb, P)
    # the wall behind the old head's top: filled from the wall each side, row by row, with the
    # wall's texture 9 px above
    for y in np.nonzero(old_only.any(1))[0]:
        cols = np.nonzero(old_only[y])[0]
        a0, b0 = max(cols.min() - 2, 0), min(cols.max() + 2, 807)
        for c in cols:
            tt = (c - a0) / max(b0 - a0, 1)
            base_v = src[y, a0] * (1 - tt) + src[y, b0] * tt
            above = src[max(y - 9, 0), c] if not (head[max(y - 9, 0), c]) else base_v
            P[y, c] = base_v + 0.5 * (above - (src[max(y - 9, 0), a0] * (1 - tt) + src[max(y - 9, 0), b0] * tt))
    out[0:808, X0:1920] = P
    report["tank_head"] = {"rim_y_src": round(float(y_rim), 1), "radius_src_px": r, "rise_m": 0.27, "rise_src_px": round(float(rise), 1),
                           "top_surface_half_height_src_px": round(float(lip), 2), "old_half_height_src_px": round(float((hy.max() - hy.min()) / 2), 1),
                           "luma_crest": round(float(lum(P[new_head & (wn > 0.8)]).mean()), 1), "luma_near_rim": round(float(lum(P[new_head & (wn < 0.2)]).mean()), 1), "shell_top_luma": round(shell_top_luma, 1)}
    unchanged = bool(np.array_equal(np.round(out[:, :1132]), np.round(v3[:, :1132])))
    report["left_of_source_1132_unchanged"] = unchanged
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "corridor-far.png"))
    json.dump(report, open(os.path.join(OUT, "far-report.json"), "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
