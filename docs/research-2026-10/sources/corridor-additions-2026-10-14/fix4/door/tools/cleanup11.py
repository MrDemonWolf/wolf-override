"""Round 11 (add7 fix round 4) cleanup and install: Codex's paint of the two jamb plates
(codex/paint-jamb11/out/jamb11-painted.png, kept untouched with its C2PA chunk; a resampled copy is
used) becomes material detail only. Each plate is re-imposed from its design mask (jamb11.py) at its
albedo times the light the round-10 art already carries there (light-far.npy, light-near.npy), times
Codex's relative detail (its luminance over its own blur, clamped to +-12 %); the joints, the bolts
(washer, head, a lit rim on the side toward the visible fitting, a 1 px cast shadow away from it) and
the plates' edge shadows are drawn deterministically. Only the atlas's wall and column regions
change, and only inside the new masks (checked); every other pixel of the atlas is round 10's.

Writes add7/fix4/door/game/corridor-seal-atlas.png (and atlas-regions.json, copied unchanged) and
add7/fix4/door/layers/report11.json."""
from __future__ import annotations

import json
import os
import shutil
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import jamb11 as j  # noqa: E402
from jamb11 import p2, CW, CC, to_srgb_u8, from_srgb_u8, LUM  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
D = os.path.join(ROOT, "design")
JOB = os.path.abspath(os.path.join(ROOT, "..", "codex", "paint-jamb11"))
OUT = os.path.join(ROOT, "game")
LAY = os.path.join(ROOT, "layers")


def mask(name):
    return np.asarray(Image.open(os.path.join(D, "masks", name)).convert("L")).astype(float) / 255.0


def codex_panel():
    """Codex's output resampled to the 1024 edit-target grid (scale only; alignment checked in the
    report against the target's edges), panel A cut out (5 px per world px), and the paint map."""
    panels = json.load(open(os.path.join(JOB, "panels.json")))
    im = Image.open(os.path.join(JOB, "out", "jamb11-painted.png")).convert("RGB")
    native = im.size
    im = np.asarray(im.resize((1024, 1024), Image.Resampling.LANCZOS)).astype(float)
    amap = np.asarray(Image.open(os.path.join(JOB, "refs", "2-areas-to-paint.png")).convert("L")).astype(float) / 255.0
    tgt = np.asarray(Image.open(os.path.join(JOB, "refs", "1-edit-target-door-jambs.png")).convert("RGB")).astype(float)
    PA = panels["A"]
    ax, ay = PA["at"]
    pw, ph = PA["px"]
    pan = from_srgb_u8(im[ay:ay + ph, ax:ax + pw].round())
    vis = amap[ay:ay + ph, ax:ax + pw]
    # alignment: outside the paint map Codex should have kept the target; mean abs difference there
    keep = amap < 0.5
    err = float(np.abs(im - tgt).mean(-1)[keep].mean())
    return pan, vis, PA, native, err


def to_region(pan, vis, PA, canvas):
    """Samples the panel (world at PA['ppw']) onto a region canvas (2 px per world px), with a small
    pre-blur for the 2.5x reduction."""
    X, Y = canvas.grid()
    x0, y0 = PA["world"][0], PA["world"][1]
    u = (X - x0) * PA["ppw"] - 0.5
    v = (Y - y0) * PA["ppw"] - 0.5
    out = np.stack([ndimage.map_coordinates(ndimage.gaussian_filter(pan[..., c], 1.0), [v, u], order=1, mode="nearest") for c in range(3)], -1)
    vm = ndimage.map_coordinates(vis, [v, u], order=1, mode="constant", cval=0.0)
    inside = (u >= 0) & (v >= 0) & (u < pan.shape[1] - 1) & (v < pan.shape[0] - 1)
    return out, vm * inside


def detail(lin_img, m, sigma, lo=0.88, hi=1.12):
    y = np.maximum((lin_img * LUM).sum(-1), 1e-5)
    w = (m > 0.5).astype(float)
    base = ndimage.gaussian_filter(y * w, sigma) / np.maximum(ndimage.gaussian_filter(w, sigma), 1e-6)
    d = np.where(w > 0, y / np.maximum(base, 1e-6), 1.0)
    return np.clip(d, lo, hi)


def shift(m, dy, dx):
    return ndimage.shift(m, (dy, dx), order=1, mode="constant", cval=0.0)


def bolts(lin, plate_m, wash_m, head_m, L, light_dx, rep_key, rep):
    """Draws the bolts: washer, head, a lit rim on the side toward the light (light_dx: -1 = light
    from the left, +1 = from the right; always from above) and a 1 px cast shadow away from it."""
    WASH = np.array(p2.STEEL) * 0.95
    HEADC = np.array(p2.STEEL_WORN) * 0.80
    allb = np.clip(wash_m + head_m, 0, 1)
    cast = np.clip(shift(allb, 1.0, -light_dx) - allb, 0, 1) * plate_m
    lin = lin * (1 - cast[..., None] * 0.55) + (lin * 0.35) * cast[..., None] * 0.55
    lin = lin * (1 - wash_m[..., None]) + (WASH * L) * wash_m[..., None]
    # the washer's edge away from the light reads darker (its 6 mm thickness in shade)
    wdark = np.clip(wash_m - shift(wash_m, -1.0, light_dx), 0, 1) * (1 - head_m)
    lin = lin * (1 - wdark[..., None] * 0.5) + (WASH * L * 0.55) * wdark[..., None] * 0.5
    lin = lin * (1 - head_m[..., None]) + (HEADC * L) * head_m[..., None]
    rim = np.clip(head_m - shift(head_m, 1.0, -light_dx), 0, 1)
    lin = lin * (1 - rim[..., None] * 0.7) + (np.array(p2.STEEL_WORN) * L * 1.35) * rim[..., None] * 0.7
    rep[rep_key] = {"washer_px": int((wash_m > 0.5).sum()), "head_px": int((head_m > 0.5).sum()), "cast_shadow_px": int((cast > 0.3).sum())}
    return lin


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(LAY, exist_ok=True)
    rep = {}
    atlas10 = np.asarray(Image.open(j.ATLAS10).convert("RGBA"))
    atlas = atlas10.copy()
    pan, vis, PA, native, err = codex_panel()
    rep["codex"] = {"native_size": list(native), "mean_abs_diff_outside_paint_map_srgb": round(err, 2)}
    Lf = np.load(os.path.join(D, "light-far.npy"))
    Ln = np.load(os.path.join(D, "light-near.npy"))

    # ---------------------------------------------------------------- far jamb (wall region)
    wx, wy, ww, wh = j.W["region"]
    wall = atlas10[wy:wy + wh, wx:wx + ww].astype(float) / 255.0
    lin = from_srgb_u8((wall[..., :3] * 255).round())
    cw, vw = to_region(pan, vis, PA, CW)
    fp = mask("wall--far_plate.png")
    dt = detail(cw, fp * (vw > 0.5), 2.0)
    GUN = np.array(p2.GUNSHIP) * 0.92
    new = GUN * Lf * dt[..., None]
    lin = lin * (1 - fp[..., None]) + new * fp[..., None]
    # its far edge's shadow on the concrete (light from the door light, above and to the right)
    esh = p2.mask_of([p2.quad_face(j.FAR_A1, j.FAR_A1 + 0.05, 0.0, j.d7.H_OPEN, 0.0), p2.quad_face(j.FAR_A1, j.FAR_A1 + 0.05, j.d7.H_OPEN, j.BF_TOP, 0.0)], CW) * (1 - fp)
    esh *= (wall[..., 3] > 0.99)
    lin = lin * (1 - esh[..., None] * 0.45) + lin * 0.4 * esh[..., None] * 0.45
    sm = np.clip(mask("wall--far_seams.png") * fp, 0, 1) * 0.9
    lin = lin * (1 - sm[..., None]) + (GUN * Lf * 0.35) * sm[..., None]
    lin = bolts(lin, fp, mask("wall--far_washers.png"), mask("wall--far_heads.png"), Lf, +1, "far_bolts", rep)
    newm_w = np.clip(fp + esh + ndimage.binary_dilation(mask("wall--far_washers.png") > 0.01, iterations=2) * fp, 0, 1)
    wall_out = wall.copy()
    wall_out[..., :3] = to_srgb_u8(lin) / 255.0
    atlas[wy:wy + wh, wx:wx + ww] = (np.clip(wall_out, 0, 1) * 255 + 0.5).astype(np.uint8)
    rep["far_plate"] = {"px": int((fp > 0.5).sum()), "codex_visible_px": int(((fp > 0.5) & (vw > 0.5)).sum()),
                        "detail_range": [round(float(dt[fp > 0.5].min()), 3), round(float(dt[fp > 0.5].max()), 3)],
                        "mean_luma": round(float((to_srgb_u8(lin).astype(float) * LUM).sum(-1)[fp > 0.99].mean()), 1)}

    # ---------------------------------------------------------------- near jamb (column region)
    cx, cy, cw_, ch = j.C["region"]
    col = atlas10[cy:cy + ch, cx:cx + cw_].astype(float) / 255.0
    clin = from_srgb_u8((col[..., :3] * 255).round())
    cc, vc = to_region(pan, vis, PA, CC)
    hw = mask("column--KEEP_hardware.png") > 0.5
    op = col[..., 3] > 0.99
    npl = mask("column--near_plate.png") * (~hw) * op
    dt = detail(cc, npl * (vc > 0.5), 2.0)
    GALV = np.array(p2.STEEL) * 0.80
    clin = clin * (1 - npl[..., None]) + (GALV * Ln * dt[..., None]) * npl[..., None]
    # worn arris (t 0..20 mm) and the plate's lit top edge
    arr = p2.mask_of([p2.quad_side(j.NEAR_A, 0.0, 0.022, j.NEAR_H0, j.BF_TOP)], CC) * npl
    clin = clin * (1 - arr[..., None] * 0.6) + (np.array(p2.STEEL_WORN) * Ln) * arr[..., None] * 0.6
    top = p2.mask_of([p2.quad_side(j.NEAR_A, 0.0, j.NEAR_T1, j.BF_TOP - 0.02, j.BF_TOP)], CC) * npl
    clin = clin * (1 - top[..., None] * 0.6) + (np.array(p2.STEEL_WORN) * Ln) * top[..., None] * 0.6
    nsh = mask("column--near_edge_shadow.png") * (1 - mask("column--near_plate.png")) * (~hw) * op
    clin = clin * (1 - nsh[..., None] * 0.55) + clin * 0.45 * nsh[..., None] * 0.55
    sm = np.clip(mask("column--near_seams.png") * npl, 0, 1) * 0.9
    clin = clin * (1 - sm[..., None]) + (GALV * Ln * 0.35) * sm[..., None]
    nw = mask("column--near_washers.png") * (~hw) * op
    nh = mask("column--near_heads.png") * (~hw) * op
    clin = bolts(clin, npl, nw, nh, Ln, -1, "near_bolts", rep)
    col_out = col.copy()
    col_out[..., :3] = to_srgb_u8(clin) / 255.0
    atlas[cy:cy + ch, cx:cx + cw_] = (np.clip(col_out, 0, 1) * 255 + 0.5).astype(np.uint8)
    rep["near_plate"] = {"px": int((npl > 0.5).sum()), "codex_visible_px": int(((npl > 0.5) & (vc > 0.5)).sum()),
                         "detail_range": [round(float(dt[npl > 0.5].min()), 3), round(float(dt[npl > 0.5].max()), 3)],
                         "mean_luma": round(float((to_srgb_u8(clin).astype(float) * LUM).sum(-1)[npl > 0.99].mean()), 1),
                         "end_face_concrete_luma_beside": j.json.load(open(os.path.join(D, "spec.json")))["light"]["near_end_face_concrete_mean_luma"]}
    # alpha never changes; nothing outside the two regions' new masks changes
    diff = np.abs(atlas.astype(int) - atlas10.astype(int)).max(-1)
    allowed = np.zeros(diff.shape, bool)
    allowed[wy:wy + wh, wx:wx + ww] = ndimage.binary_dilation(newm_w > 0.001, iterations=2)
    newm_c = np.clip(npl + nsh + nw + nh + mask("column--near_plate.png") * op * (~hw), 0, 1)
    allowed[cy:cy + ch, cx:cx + cw_] = ndimage.binary_dilation(newm_c > 0.001, iterations=2)
    rep["changed_px"] = int((diff > 0).sum())
    rep["changed_outside_new_masks_px"] = int(((diff > 0) & ~allowed).sum())
    rep["alpha_changed_px"] = int((atlas[..., 3] != atlas10[..., 3]).sum())
    Image.fromarray(atlas, "RGBA").save(os.path.join(OUT, "corridor-seal-atlas.png"))
    shutil.copy(os.path.join(j.R, "add7", "fix3", "door", "game", "atlas-regions.json"), os.path.join(OUT, "atlas-regions.json"))
    json.dump(rep, open(os.path.join(LAY, "report11.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
