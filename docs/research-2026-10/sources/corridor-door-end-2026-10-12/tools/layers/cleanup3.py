"""Fix round 2 (v3) deterministic cleanup of Codex paint-v3 (REAL-LOOK section 4, step 3).

paint-v3 painted only the v3 design's NEW parts on a composite of the round-1 door end (see
paint/tools/codex_inputs3.py): the wall-mounted bypass (backplate, gearbox, chain guard, clamps), the
120 mm floor line, the far column's patch and pour joint, the cross-wall's cut section with its steel
angles, and the plant room's dry slab. This script:

  1. registers the paint to its edit target and checks edge fidelity inside the paint area;
  2. builds the v3 wall and front layers on the design canvas CVD (4 px per world px): round-1
     (layers/v2) paint for the parts that did not change, the new paint for the new parts, the v3
     design's alpha exactly (doorway alpha 0), each new part's value and colour held to the design
     on its visible pixels only (depth order), the designed contact and cut shadows, a designed soft
     shadow of the bypass on the wall, caused wear on the floor line, the stop button grey, fine
     grain (+-2.5 levels) on the large calm faces so S3TC / ETC2 / BPTC blocks do not band;
  3. adds the painted slab (value-held to the design) to the far plate base (cleanup3_far.py);
  4. checks: alpha equals the design, hole alpha 0, no violet spill within 8 px of an edge, no part
     pass writes outside its visible mask, fidelity thresholds.
The Codex original in codex/paint-v3/out/ is never modified. Writes layers/v3/ and layers/report3.json.
"""
from __future__ import annotations

import json
import os
import shutil
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from imgkit import load_rgb, resize, register, fidelity, lum, to_lin, to_srgb, decontaminate  # noqa: E402
from cleanup2 import mask, rgba, save_rgba, mgauss, relight, hold_mean, hold_chroma, visible_masks, spill_check, despill  # noqa: E402

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
D3 = os.path.join(R, "design", "portal3")
M3 = os.path.join(D3, "masks")
V2 = os.path.join(R, "layers", "v2")
OUT = os.path.join(R, "layers", "v3")
JOB = os.path.join(R, "codex", "paint-v3")
THRESH = {"edge_ncc_in_asset": 0.45, "strong_edge_recall": 0.80}
CVD = (676.0, 150.0, 4.0, 1232, 1900)
CVP = (640.0, 286.0, 1024.0 / 334.0, 1024, 1024)
OFF2 = 16  # the v2 canvas sits at +16 px in CVD
NEW_WALL = ("bp_backplate", "bp_anchor0", "bp_anchor1", "bp_anchor2", "bp_anchor3", "bp_gearbox_side", "bp_gearbox",
            "bp_gearbox_top", "bp_boss", "bp_wallplate0", "bp_wallplate1", "bp_guard", "bp_guard_edge", "bp_sprocket_cover",
            "bp_guard_flange", "bp_clamp0", "bp_clamp1", "floor_line_wide", "far_col_joint")
NEW_FRONT = ("pier_cut", "arris_cut_left", "arris_cut_right")
BYPASS = [n for n in NEW_WALL if n.startswith("bp_")]
GRAIN_WALL = ("face_upper", "face_far_column")
GRAIN_FRONT = ("pier_face", "pier_end", "pier_cut")


def cvd_grid():
    x0, y0, ppw, w, h = CVD
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    return x0 + (xx + 0.5) / ppw, y0 + (yy + 0.5) / ppw


def paint_on_cvd(painted: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """The registered paint (CVP canvas) sampled at CVD's pixel centres, and where CVP covers CVD."""
    X, Y = cvd_grid()
    x0, y0, ppw, w, h = CVP
    px = (X - x0) * ppw - 0.5
    py = (Y - y0) * ppw - 0.5
    out = np.stack([ndimage.map_coordinates(painted[..., c], [py, px], order=1, mode="nearest") for c in range(3)], -1)
    inside = (px >= 0) & (px <= w - 1) & (py >= 0) & (py <= h - 1)
    return out, inside


def on_cvd(img: np.ndarray, off: int = OFF2) -> np.ndarray:
    _, _, _, w, h = CVD
    out = np.zeros((h, w) + img.shape[2:])
    out[:img.shape[0], off:off + img.shape[1]] = img
    return out


def grain(shape, seed, sigma=0.6, sd=2.5):
    g = ndimage.gaussian_filter(np.random.default_rng(seed).standard_normal(shape), sigma)
    return g / g.std() * sd


def soft_shadow(alpha, dx_world, dy_world, blur_world, strength):
    ppw = CVD[2]
    sh = ndimage.shift(alpha, (dy_world * ppw, dx_world * ppw), order=1, mode="constant")
    sh = ndimage.gaussian_filter(sh, blur_world * ppw)
    return np.clip(sh * strength, 0, 1)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    report: dict = {"thresholds": THRESH}
    spec = json.load(open(os.path.join(D3, "spec.json")))
    order = {lay: [p["name"] for p in spec["parts"][lay]] for lay in ("wall", "frame", "curtain", "front")}
    # ---- 1. registration and fidelity
    target = load_rgb(os.path.join(JOB, "refs", "1-edit-target-door-end.png"))
    raw = load_rgb(os.path.join(JOB, "out", "door-end-v3-painted.png"))
    painted = resize(raw, (1024, 1024))
    reg, tr = register(painted, target, scales=np.linspace(0.98, 1.02, 5), shift=6)
    area = mask(os.path.join(R, "paint", "paint-v3-area.png"))
    f = fidelity(reg, target, area)
    f["registration"] = tr
    f["source_px"] = list(raw.shape[1::-1])
    f["pass"] = all(f[k] >= v for k, v in THRESH.items())
    outside = (ndimage.binary_erosion(area < 0.5, iterations=6))
    f["outside_area_mean_abs_change"] = round(float(np.abs(reg[outside] - target[outside]).mean()), 2)
    report["paint-v3"] = f
    pc, inside = paint_on_cvd(reg)
    # ---- 2a. wall layer
    w2 = rgba(os.path.join(V2, "portal-wall.png"))
    w2rgb, w2a = on_cvd(w2[0]), on_cvd(w2[1])
    drgb, da = rgba(os.path.join(D3, "design-wall.png"))
    lm = {n: mask(os.path.join(M3, f"wall--{n}.png")) for n in order["wall"]}
    lm["far_col_patch"] = mask(os.path.join(M3, "wall--far_col_patch.png"))
    names = order["wall"] + ["far_col_patch"]
    # the patch belongs to the far column, under everything nearer than the column
    names.remove("far_col_patch")
    names.insert(names.index("face_far_column") + 1, "far_col_patch")
    vis = visible_masks(names, lm)
    new = np.zeros(da.shape)
    for n in NEW_WALL + ("far_col_patch",):
        new = np.maximum(new, vis[n])
    use_paint = ((new > 0.02) | (w2a < 0.02)) & inside
    out = np.where(use_paint[..., None], pc, w2rgb)
    # outside both the paint and v2 (none expected): the design
    out = np.where(((w2a < 0.02) & ~inside)[..., None], drgb, out)
    report["wall_px_from_design_fallback"] = int(((w2a < 0.02) & ~inside & (da > 0.02)).sum())
    changed_outside = 0
    for n in NEW_WALL + ("far_col_patch",):
        v = vis[n]
        if v.sum() < 2:
            continue
        snap = out.copy()
        if (v > 0.5).sum() > 3000:
            out = relight(out, drgb, v, 14.0)
        out, _ = hold_mean(out, drgb, v, 0.10)
        out = hold_chroma(out, drgb, v, 0.7)
        changed_outside += int(((np.abs(out - snap).max(-1) > 0.5) & ~(v > 0)).sum())
    # the far column's patch: the column's own low-frequency value round it (no lighter or darker patch)
    col = vis["face_far_column"] > 0.5
    patch = vis["far_col_patch"] > 0.5
    if patch.any():
        ring = col & ~patch & ndimage.binary_dilation(patch, iterations=10)
        Lw = lum(to_lin(out))
        k = mgauss(Lw, ring.astype(float), 6.0) / np.maximum(mgauss(Lw, patch.astype(float), 6.0), 1e-6)
        fixed = to_srgb(to_lin(out) * np.clip(k, 0.5, 2.0)[..., None])
        out = np.where(patch[..., None], fixed, out)
    # under the handwheel (a separate, turning sprite) the paint shows the edit target's wheel: the
    # gearbox, boss and backplate there are the design's, at the painted level of each part round it
    X, Y = cvd_grid()
    disc = np.hypot(X - 695.0, Y - 398.0) <= 12.5
    for n in ("bp_backplate", "bp_gearbox", "bp_gearbox_side", "bp_boss", "bp_gearbox_top"):
        v = (vis[n] > 0.5)
        sel = v & disc
        ok = v & ~ndimage.binary_dilation(disc, iterations=2)
        if sel.any():
            k = (to_lin(out[ok]).mean(0) + 1e-6) / (to_lin(drgb[ok]).mean(0) + 1e-6) if ok.sum() > 8 else np.ones(3)
            out[sel] = to_srgb(to_lin(drgb[sel]) * k)
    report["wheel_disc_repainted_px"] = int((disc & (new > 0.5)).sum())
    # caused wear: the floor line scuffed thin where feet cross it (the walk line passes x 752)
    X, Y = cvd_grid()
    fl = vis["floor_line_wide"]
    n2 = ndimage.zoom(np.random.default_rng(12).random((CVD[4] // 6 + 3, CVD[3] // 6 + 3)), 6, order=3)[:CVD[4], :CVD[3]]
    n2 = (n2 - n2.min()) / np.ptp(n2)
    scuff = np.exp(-(((X - 752.0) / 9.0) ** 2)) * (0.5 + 0.5 * n2) * fl
    lin = to_lin(out)
    grey = lum(lin)[..., None] * 0.9
    lin = lin * (1 - 0.55 * scuff[..., None]) + grey * 0.55 * scuff[..., None]
    out = to_srgb(lin)
    # contact shadows exactly as designed
    sh = mask(os.path.join(M3, "wall--contact_shadow.png"))
    solid = np.zeros(da.shape)
    for n in order["wall"]:
        solid = np.maximum(solid, lm[n])
    shadow_only = (sh > 0) & (solid < 0.5)
    out[shadow_only] = drgb[shadow_only]
    alpha = da.copy()
    # the bypass's own soft shadow on the wall behind it (lit from the corridor light, up left)
    bp = np.zeros(da.shape)
    for n in BYPASS:
        bp = np.maximum(bp, lm[n])
    bsh = soft_shadow(bp, 0.9, 0.7, 0.6, 0.55) * (1 - bp)
    on_wall = (alpha > 0.5) & (bsh > 0.002)
    out[on_wall] = to_srgb(to_lin(out[on_wall]) * (1 - bsh[on_wall])[:, None])
    free = (alpha <= 0.5) & (bsh > 0.002)
    dark = np.array([2.0, 4.0, 6.0])
    a_new = bsh + alpha * (1 - bsh)
    out[free] = (dark * bsh[free][:, None] + out[free] * (alpha[free] * (1 - bsh[free]))[:, None]) / np.maximum(a_new[free], 1e-6)[:, None]
    alpha = np.where(free, a_new, alpha)
    report["bypass_shadow_px"] = int((bsh > 0.02).sum())
    # grain on the calm faces
    gm = np.zeros(da.shape)
    for n in GRAIN_WALL:
        gm = np.maximum(gm, vis[n])
    out = out + (grain(da.shape, 301) * gm)[..., None]
    hole = mask(os.path.join(M3, "wall--HOLE.png"))
    out = decontaminate(np.clip(out, 0, 255), np.clip(alpha, 0, 1), band=3)
    out = despill(out, alpha)
    wall_checks = {"depth_order_writes_outside_visible": changed_outside, "spill": spill_check(out, alpha),
                   "alpha_equals_design_plus_bypass_shadow": bool(np.abs(np.where(free, da, alpha) - da).max() < 1 / 255),
                   "hole_alpha_max": float(alpha[hole > 0.999].max()) if (hole > 0.999).any() else 0.0}
    save_rgba(out, alpha, os.path.join(OUT, "portal-wall.png"))
    # ---- 2b. front layer
    f2 = rgba(os.path.join(V2, "portal-front.png"))
    f2rgb, f2a = on_cvd(f2[0]), on_cvd(f2[1])
    frgb, fa = rgba(os.path.join(D3, "design-front.png"))
    fm = {n: mask(os.path.join(M3, f"front--{n}.png")) for n in order["front"]}
    fvis = visible_masks(order["front"], fm)
    newf = np.zeros(fa.shape)
    for n in NEW_FRONT:
        newf = np.maximum(newf, fvis[n])
    use_paint = ((newf > 0.02) | (f2a < 0.02)) & inside
    fout = np.where(use_paint[..., None], pc, f2rgb)
    fout = np.where(((f2a < 0.02) & ~inside)[..., None], frgb, fout)
    changed_outside_f = 0
    for n in NEW_FRONT:
        v = fvis[n]
        snap = fout.copy()
        if (v > 0.5).sum() > 3000:
            fout = relight(fout, frgb, v, 14.0)
        fout, _ = hold_mean(fout, frgb, v, 0.10)
        fout = hold_chroma(fout, frgb, v, 0.7)
        changed_outside_f += int(((np.abs(fout - snap).max(-1) > 0.5) & ~(v > 0)).sum())
    # the cut section meets the pier's end face at its foot: no step in value across the join
    cut = fvis["pier_cut"] > 0.5
    end = fvis["pier_end"] > 0.5
    rows_cut = np.nonzero(cut.any(1))[0]
    if rows_cut.size:
        r0 = rows_cut.min()
        top_cut = cut & (np.arange(cut.shape[0])[:, None] < r0 + 12)
        foot_end = end & (np.arange(cut.shape[0])[:, None] >= r0 - 12) & (np.arange(cut.shape[0])[:, None] < r0)
        if top_cut.any() and foot_end.any():
            Lf = lum(to_lin(fout))
            k = float(Lf[foot_end].mean() / max(Lf[top_cut].mean(), 1e-6))
            ramp = np.clip(1 - (np.arange(cut.shape[0]) - r0) / 80.0, 0, 1)[:, None]
            g = 1 + (k - 1) * ramp
            fout = np.where(cut[..., None], to_srgb(to_lin(fout) * g[..., None]), fout)
            report["cut_join_gain"] = round(k, 3)
    # the stop button is grey (the view's reds are the live lockdown beacons)
    b2 = fvis["pb_button2"] > 0.3
    fout[b2] = frgb[b2]
    # the cut section's shadows on the floor either side of it (designed, cut_shadow)
    cs = mask(os.path.join(M3, "front--cut_shadow.png"))
    gh = mask(os.path.join(M3, "front--GLASS_HOLE.png"))
    fal = np.clip(fa, 0, 1)
    free = (fal < 0.5) & (cs > 0.002)
    a_new = cs + fal * (1 - cs)
    fout[free] = (dark * cs[free][:, None] + fout[free] * (fal[free] * (1 - cs[free]))[:, None]) / np.maximum(a_new[free], 1e-6)[:, None]
    fal = np.where(free, a_new, fal)
    gm = np.zeros(fa.shape)
    for n in GRAIN_FRONT:
        gm = np.maximum(gm, fvis[n])
    fout = fout + (grain(fa.shape, 302) * gm)[..., None]
    fout = decontaminate(np.clip(fout, 0, 255), fal, band=3)
    fout = despill(fout, fal)
    front_checks = {"depth_order_writes_outside_visible": changed_outside_f, "spill": spill_check(fout, fal),
                    "alpha_equals_design_plus_cut_shadow": bool(np.abs(np.where(free, fa, fal) - fa).max() < 1 / 255),
                    "glass_hole_alpha_max": float(fal[gh > 0.999].max()) if (gh > 0.999).any() else 0.0}
    save_rgba(fout, fal, os.path.join(OUT, "portal-front.png"))
    report["layers"] = {"wall": wall_checks, "front": front_checks}
    # ---- unchanged round-1 pieces
    for n in ("portal-frame.png", "portal-curtain.png", "portal-curtain-open.png", "bypass-wheel.png", "lens.png"):
        shutil.copy(os.path.join(V2, n), os.path.join(OUT, n))
    # ---- 3. the far plate: base (cleanup3_far.py) plus the painted slab, at 2 px per world px
    far = load_rgb(os.path.join(OUT, "corridor-far-base.png"))
    slab = rgba(os.path.join(D3, "design-slab-cvd.png"))
    srgb_d, sa = slab
    joints = mask(os.path.join(M3, "slab-joints--cvd.png"))
    sm = sa > 0.5
    sout = pc.copy()
    sout = relight(sout, srgb_d, sm.astype(float), 24.0)
    sout, ks = hold_mean(sout, srgb_d, sm.astype(float), 0.10)
    sout = hold_chroma(sout, srgb_d, sm.astype(float), 0.8)
    # the saw-cut joints stay as drawn (dark hairlines), and grain so the dark calm slab does not band
    sout = np.where((joints > 0.3)[..., None], np.minimum(sout, srgb_d), sout)
    sout = sout + (grain(sa.shape, 303) * sm)[..., None]
    # resample to the far plate (world x -> (x - 12.444) * 2, y -> (y - 78.5) * 2) with premultiplied alpha
    FX, FY = 12.444, 78.5
    hF, wF = far.shape[:2]
    yy, xx = np.mgrid[0:hF, 0:wF].astype(np.float64)
    wx = FX + (xx + 0.5) / 2.0
    wy = FY + (yy + 0.5) / 2.0
    px = (wx - CVD[0]) * CVD[2] - 0.5
    py = (wy - CVD[1]) * CVD[2] - 0.5
    sel = (px >= 0) & (px <= CVD[3] - 1) & (py >= 0) & (py <= CVD[4] - 1)
    a_s = np.zeros((hF, wF))
    a_s[sel] = ndimage.map_coordinates(sa, [py[sel], px[sel]], order=1)
    col_s = np.zeros((hF, wF, 3))
    for c in range(3):
        col_s[sel, c] = ndimage.map_coordinates(sout[..., c] * sa, [py[sel], px[sel]], order=1)
    col_s = col_s / np.maximum(a_s[..., None], 1e-6)
    far_out = far * (1 - a_s[..., None]) + col_s * a_s[..., None]
    left_unchanged = bool(np.array_equal(np.round(far_out[:, :1132]), np.round(far[:, :1132])))
    Image.fromarray(np.clip(far_out + 0.5, 0, 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "corridor-far.png"))
    Ls = lum(sout[sm])
    report["slab"] = {"hold_gain": round(float(ks), 3), "luma_mean": round(float(Ls.mean()), 1), "luma_p10_p90": [round(float(v), 1) for v in np.percentile(Ls, [10, 90])],
                      "far_left_of_source_1132_unchanged": left_unchanged}
    # value report for the new parts (sRGB luma means)
    report["values"] = {
        "cut_section": round(float(lum(fout[cut]).mean()), 1),
        "pier_end": round(float(lum(fout[end]).mean()), 1),
        "gearbox": round(float(lum(out[vis["bp_gearbox"] > 0.5]).mean()), 1),
        "chain_guard": round(float(lum(out[vis["bp_guard"] > 0.5]).mean()), 1),
        "backplate": round(float(lum(out[vis["bp_backplate"] > 0.5]).mean()), 1),
        "floor_line_rgb": [round(float(v), 1) for v in out[vis["floor_line_wide"] > 0.5].mean(0)],
    }
    report["pass"] = bool(f["pass"] and wall_checks["spill"]["pass"] and front_checks["spill"]["pass"] and wall_checks["hole_alpha_max"] == 0.0
                          and wall_checks["depth_order_writes_outside_visible"] == 0 and front_checks["depth_order_writes_outside_visible"] == 0)
    json.dump(report, open(os.path.join(R, "layers", "report3.json"), "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
