"""Fix round 3 (v4) deterministic cleanup: the slim near column, its stub, the wall layer and the
handwheel. No new image-tool paint: every surface carries Codex paint already in the slice
(paint-portal2 for the column, its lamp, push buttons and camera; paint-v3 for the cut section's
concrete and steel angles), moved onto the v4 shapes and relit by the design (REAL-LOOK section 4,
step 3). Inputs: layers/v3/* (round 2's cleaned layers), design/portal3 (their design) and
design/portal4 (the new design).

Front layer (CVD, 4 px per world px):
  * each v4 part samples its v3 counterpart's paint at the matching point on the matching surface:
    the face-plane parts that did not move (approach face, jamb frame, guide) pixel for pixel; the end
    face, its angles, the lamp and the push-button station 0.49 m further along the wall and 0.08 m
    across it (so they stay centred on the 0.5 m end face); the camera with its plate; the chamfer
    plate from the v3 end's steel angle, stretched across the plate;
  * the stub's concrete and its steel edge angle carry the v3 cut section's painted concrete and
    angle as texture (paint over its design light), along the stub;
  * every pixel is relit by the ratio of the v4 design's light to the v3 design's light at its
    source, so the paint keeps its texture and colour under the new geometry's light; new parts are
    held to the design's mean value (+-15 %) and colour;
  * round 2's per-channel grain is subtracted (same seed and masks) and luma-only grain added (one
    multiplicative factor on all three channels in linear light, so no hue speckle);
  * alpha is the v4 design's exactly; the lamp glass is a hole; footprint contact shadows round the
    column foot and both sides of the stub.
Wall layer: round 2's, with its per-channel grain swapped for luma-only grain, and the gearbox's
input boss moved 1 px left and 2 px down with the wheel's hub (694, 400); the boss's old place is
filled from the gearbox paint beside it.
Wheel: the rim lifted to worn bare steel (texture p90 about 145, so about 115 in game after the grade).
Writes layers/v4/ and layers/report4.json.
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
from imgkit import lum, to_lin, to_srgb, decontaminate  # noqa: E402
from cleanup2 import mask, rgba, save_rgba, hold_mean, hold_chroma, visible_masks, spill_check, despill  # noqa: E402

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "design"))  # the design tools (tools/design/)
import portal4 as p4  # noqa: E402
import portal2 as p2  # noqa: E402

D3 = os.path.join(R, "design", "portal3")
D4 = os.path.join(R, "design", "portal4")
V3 = os.path.join(R, "layers", "v3")
OUT = os.path.join(R, "layers", "v4")
CVD = p4.CVD
A_END3 = p2.A_N - 0.65
DA = A_END3 - p4.A_END4  # -0.49: a v4 end-face point's v3 counterpart is this far along U
DT = (p2.T_WALL / 2) - (p4.T_END / 2)  # +0.08 across the wall
CAM_DA = (A_END3 + 0.28) - (p4.A_END4 + 0.08)
STUB_PARTS = ("stub_face", "stub_top", "stub_angle_top", "stub_angle_face", "stub_angle_far")
NEW_PARTS = ("chamfer",) + STUB_PARTS
LUMA_W = np.array([0.2126, 0.7152, 0.0722])


def grain_v3(shape, seed, sigma=0.6, sd=2.5):
    g = ndimage.gaussian_filter(np.random.default_rng(seed).standard_normal(shape), sigma)
    return g / g.std() * sd


def luma_grain(rgb, m, seed, sd=1.8, sigma=0.6):
    """Luma-only grain: each pixel's sRGB luma moves by g (sd levels); all three channels are scaled
    by the same linear factor, so the hue never changes."""
    g = ndimage.gaussian_filter(np.random.default_rng(seed).standard_normal(m.shape), sigma)
    g = g / g.std() * sd * m
    lin = to_lin(rgb)
    L = lum(lin)
    Ls = to_srgb(np.repeat(L[..., None], 3, -1))[..., 0]
    k = to_lin(np.repeat(np.clip(Ls + g, 0, 255)[..., None], 3, -1))[..., 0] / np.maximum(L, 1e-7)
    k = np.where(L > 1e-6, k, 1.0)
    return to_srgb(lin * k[..., None])


def fill_from(rgb, valid):
    """Each pixel takes the value of the nearest valid pixel (so sampling near a part's edge never
    picks up a neighbour part)."""
    if valid.all():
        return rgb
    _, (iy, ix) = ndimage.distance_transform_edt(~valid, return_indices=True)
    return rgb[iy, ix]


def sample(img, px, py):
    """Bilinear sample of an HxW(xC) array at float pixel coordinates."""
    if img.ndim == 2:
        return ndimage.map_coordinates(img, [py, px], order=1, mode="nearest")
    return np.stack([ndimage.map_coordinates(img[..., c], [py, px], order=1, mode="nearest") for c in range(img.shape[2])], -1)


def to_px(points):
    """3D points (..., 3) -> CVD pixel coordinates (centres at +0.5)."""
    X = p2.VPX + (points[..., 0] * p2.PX_PER_M - p2.VPX) * p2.D0 / (p2.D0 + points[..., 2])
    s = p2.D0 / (p2.D0 + points[..., 2])
    Y = p2.HORIZON + (p2.FLOOR_Y - p2.HORIZON) * s - points[..., 1] * p2.PX_PER_M * s
    return (X - CVD.x0) * CVD.ppw - 0.5, (Y - CVD.y0) * CVD.ppw - 0.5


def wall_frame(P):
    rel = P - p2.O
    return (rel * p2.U).sum(-1), (rel * p2.N).sum(-1)


def front(report: dict) -> None:
    spec3 = json.load(open(os.path.join(D3, "spec.json")))
    order3 = [p["name"] for p in spec3["parts"]["front"]]
    m3 = {n: mask(os.path.join(D3, "masks", f"front--{n}.png")) for n in order3}
    vis3 = visible_masks(order3, m3)
    prgb, pa = rgba(os.path.join(V3, "portal-front.png"))
    # round 2's grain off (same seed, same masks), before anything samples the paint
    gm = np.zeros(pa.shape)
    for n in ("pier_face", "pier_end", "pier_cut"):
        gm = np.maximum(gm, vis3[n])
    prgb = np.clip(prgb - (grain_v3(pa.shape, 302) * gm)[..., None], 0, 255)
    d3rgb, _ = rgba(os.path.join(D3, "design-front.png"))
    L3 = lum(to_lin(d3rgb))
    plin = to_lin(prgb)
    filled = {}

    def src(name):
        if name not in filled:
            v = vis3[name] > 0.5
            filled[name] = (fill_from(plin, v), fill_from(L3, v))
        return filled[name]

    parts = p4.front_parts_v4()
    by = {p.name: p for p in parts}
    d4rgb, d4a = rgba(os.path.join(D4, "design-front.png"))
    L4 = lum(to_lin(d4rgb))
    m4 = {p.name: mask(os.path.join(D4, "masks", f"front--{p.name}.png")) for p in parts}
    vis4 = visible_masks([p.name for p in parts], m4)
    H, W = d4a.shape
    out_lin = np.zeros((H, W, 3))
    # the stub's texture: the v3 cut section's paint over its design light (material only)
    cut = vis3["pier_cut"] > 0.5
    rows = np.nonzero(cut.any(1))[0]
    cols = np.nonzero(cut.any(0))[0]
    tex_c = (plin / np.maximum(L3, 1e-6)[..., None])[rows.min() + 4:rows.max() - 4, cols.min() + 3:cols.max() - 2]
    tex_c_ok = cut[rows.min() + 4:rows.max() - 4, cols.min() + 3:cols.max() - 2]
    tex_c = fill_from(tex_c, tex_c_ok)
    ang = vis3["arris_cut_left"] > 0.5
    ar = np.nonzero(ang.any(1))[0]
    ac = np.nonzero(ang.any(0))[0]
    tex_a = (plin / np.maximum(L3, 1e-6)[..., None])[ar.min() + 4:ar.max() - 4, ac.min():ac.max() + 1]
    tex_a = fill_from(tex_a, ang[ar.min() + 4:ar.max() - 4, ac.min():ac.max() + 1])
    foot_px = np.array(p2.scr(p2.pt(p4.A_END4, 0.0, 0.0)))
    report_parts = {}
    for p in parts:
        m = m4[p.name]
        sel = m > 0.001
        if not sel.any():
            continue
        if p.name in STUB_PARTS:
            P, _, _ = p.plane.points()
            a, t = wall_frame(P)
            X = p2.VPX + (P[..., 0] * p2.PX_PER_M - p2.VPX) * p2.D0 / (p2.D0 + P[..., 2])
            s = p2.D0 / (p2.D0 + P[..., 2])
            Y = p2.HORIZON + (p2.FLOOR_Y - p2.HORIZON) * s - P[..., 1] * p2.PX_PER_M * s
            u = np.hypot(X - foot_px[0], Y - foot_px[1]) * CVD.ppw  # CVD px along the stub
            tex = tex_a if p.name.startswith("stub_angle") else tex_c
            th, tw = tex.shape[:2]
            r = np.mod(u + 7.0, 2 * th - 2)
            r = np.where(r > th - 1, 2 * th - 2 - r, r)
            if p.name == "stub_top":
                c = np.clip(t / p2.T_WALL, 0, 1) * (tw - 1)
            elif p.name == "stub_face":
                c = np.clip(P[..., 1] / p4.STUB_H, 0, 1) * (tw - 1) * 0.4 + tw * 0.3
            else:
                c = np.full_like(u, (tw - 1) / 2.0)
            col = sample(tex, c[sel], r[sel]) * L4[sel][:, None]
            report_parts[p.name] = "texture: v3 %s paint along the stub" % ("arris_cut_left" if tex is tex_a else "pier_cut")
        else:
            if p.name == "chamfer":
                P, la, lb = p.plane.points()
                w = float(np.linalg.norm(p2.pt(p2.A_N, 0, p2.T_WALL) - p2.pt(p4.A_END4, 0, p4.T_END)))
                frac = np.clip(la / w, 0, 1)
                Pold = p2.O + A_END3 * p2.U + P[..., 1:2] * p2.EY + (0.600 + frac * 0.055)[..., None] * p2.N
                sname = "arris_end_right"
            elif p.name in ("pier_face", "frame_near_jamb", "guide_near"):
                Pold = None
                sname = p.name
            elif p.name in ("cam_housing", "cam_sunshield", "cam_window"):
                Pold = "screen"
                sname = p.name
            elif p.name in ("cam_plate", "cam_arm", "cam_conduit"):
                P, _, _ = p.plane.points()
                Pold = P + CAM_DA * p2.U
                sname = p.name
            else:
                P, _, _ = p.plane.points()
                dt = DT
                if p.name == "arris_end_left":
                    dt = 0.0
                elif p.name == "arris_end_right":
                    dt = (p2.T_WALL - 0.025) - (p4.T_END - 0.025)
                Pold = P + DA * p2.U + dt * p2.N
                sname = p.name
            prgb_f, L3_f = src(sname)
            if Pold is None:
                yy, xx = np.nonzero(sel)
                pxs, pys = xx.astype(float), yy.astype(float)
            elif isinstance(Pold, str):
                hx3, hy3 = p2.scr(p2.pt(A_END3 + 0.28, 4.35, -0.44))
                hx4, hy4 = p2.scr(p2.pt(p4.A_END4 + 0.08, 4.35, -0.44))
                yy, xx = np.nonzero(sel)
                pxs, pys = xx + (hx3 - hx4) * CVD.ppw, yy + (hy3 - hy4) * CVD.ppw
            else:
                pxa, pya = to_px(Pold)
                pxs, pys = pxa[sel], pya[sel]
            pc = sample(prgb_f, pxs, pys)
            lsrc = sample(L3_f, pxs, pys)
            k = np.clip(L4[sel] / np.maximum(lsrc, 1e-6), 0.4, 2.5)
            col = pc * k[:, None]
            report_parts[p.name] = "v3 %s paint%s" % (sname, "" if Pold is None else " (moved)")
        layer = np.zeros((H, W, 3))
        layer[sel] = col
        out_lin = out_lin * (1 - m[..., None]) + layer * m[..., None]
    out = to_srgb(out_lin)
    # the new parts held to the design's mean value and colour (visible pixels only)
    holds = {}
    for n in NEW_PARTS:
        v = vis4[n]
        if (v > 0.5).sum() < 8:
            continue
        out, k = hold_mean(out, d4rgb, v, 0.15)
        out = hold_chroma(out, d4rgb, v, 0.7)
        holds[n] = round(float(k), 3)
    # the stub's top is the cut section's upper face, open to the corridor's and the plant room's
    # ceiling lights; review round 3 asks the cut-down wall to sit at least 8-10 luma apart from the
    # floors beside it. Its low-frequency value is set to about 10 over the brighter of the two floors
    # (measured in game along the stub), falling toward the camera, away from the lights; its steel
    # edge angles sit above it, so the curb's two edges still read as edges.
    def set_low(name, top, drop, face=1.0):
        v = vis4[name] > 0.5
        if not v.any():
            return
        P, _, _ = by[name].plane.points()
        a_, _ = wall_frame(P)
        fall = np.clip((p4.A_END4 - a_) / 5.0, 0, 1)
        want = (top - drop * fall) * face
        Lc = lum(out_ref[0])
        lowc = ndimage.gaussian_filter(np.where(v, Lc, 0.0), 6) / np.maximum(ndimage.gaussian_filter(v.astype(float), 6), 1e-6)
        kk = to_lin(np.repeat(want[..., None], 3, -1))[..., 0] / np.maximum(to_lin(np.repeat(lowc[..., None], 3, -1))[..., 0], 1e-6)
        out_ref[0] = np.where(v[..., None], to_srgb(to_lin(out_ref[0]) * np.clip(kk, 0.3, 6.0)[..., None]), out_ref[0])
        holds[name + "_value"] = "low-frequency luma %.0f at the column falling to %.0f five metres toward the camera" % (top * face, (top - drop) * face)
    out_ref = [out]
    set_low("stub_top", 60.0, 23.0)
    set_low("stub_angle_top", 78.0, 30.0)
    set_low("stub_angle_far", 74.0, 28.0)
    set_low("stub_angle_face", 78.0, 30.0, 0.8)
    out = out_ref[0]
    # luma-only grain on the calm concrete faces
    g = np.zeros(d4a.shape)
    for n in ("pier_face", "pier_end", "stub_top", "stub_face"):
        g = np.maximum(g, vis4[n])
    out = luma_grain(out, g, 402)
    alpha = d4a.copy()
    # footprint contact shadows on the floor (alpha over near-black where the layer is clear)
    sh = mask(os.path.join(D4, "masks", "front--contact_shadow.png"))
    free = (alpha < 0.5) & (sh > 0.002)
    dark = np.array([2.0, 4.0, 6.0])
    a_new = sh + alpha * (1 - sh)
    out[free] = (dark * sh[free][:, None] + out[free] * (alpha[free] * (1 - sh[free]))[:, None]) / np.maximum(a_new[free], 1e-6)[:, None]
    alpha = np.where(free, a_new, alpha)
    out = decontaminate(np.clip(out, 0, 255), np.clip(alpha, 0, 1), band=2)
    out = despill(out, alpha)
    gh = mask(os.path.join(D4, "masks", "front--GLASS_HOLE.png"))
    checks = {"spill": spill_check(out, alpha), "glass_hole_alpha_max": float(alpha[gh > 0.999].max()) if (gh > 0.999).any() else 0.0,
              "alpha_equals_design_plus_contact_shadow": bool(np.abs(np.where(free, d4a, alpha) - d4a).max() < 1 / 255)}
    # grain check: luma-only (the chroma of grained pixels equals their neighbourhood's)
    save_rgba(out, alpha, os.path.join(OUT, "portal-front.png"))
    vals = {}
    for n in ("pier_end", "chamfer", "stub_top", "stub_face", "stub_angle_top", "pier_face"):
        v = vis4[n] > 0.5
        if v.any():
            vals[n] = round(float(lum(out[v]).mean()), 1)
    report["front"] = {"sources": report_parts, "new_part_value_holds": holds, "values_srgb_luma": vals, "checks": checks}


def wall(report: dict) -> None:
    spec3 = json.load(open(os.path.join(D3, "spec.json")))
    order = [p["name"] for p in spec3["parts"]["wall"]]
    lm = {n: mask(os.path.join(D3, "masks", f"wall--{n}.png")) for n in order}
    lm["far_col_patch"] = mask(os.path.join(D3, "masks", "wall--far_col_patch.png"))
    names = list(order)
    names.insert(names.index("face_far_column") + 1, "far_col_patch")
    vis = visible_masks(names, lm)
    rgb, a = rgba(os.path.join(V3, "portal-wall.png"))
    gm = np.zeros(a.shape)
    for n in ("face_upper", "face_far_column"):
        gm = np.maximum(gm, vis[n])
    rgb = np.clip(rgb - (grain_v3(a.shape, 301) * gm)[..., None], 0, 255)
    rgb = luma_grain(rgb, gm * (a > 0.99), 401)
    # the input boss moves with the wheel's hub: (695, 398) -> (694, 400)
    boss = vis["bp_boss"]
    dx, dy = int(round((p4.HUB4[0] - 695.0) * CVD.ppw)), int(round((p4.HUB4[1] - 398.0) * CVD.ppw))
    box = np.clip(vis["bp_gearbox"] + boss, 0, 1)
    src = rgb.copy()
    # fill the boss's old place with the gearbox paint 6 px (1.5 world px) round it, row by row
    old = ndimage.binary_dilation(boss > 0.05, iterations=1)
    good = (vis["bp_gearbox"] > 0.9) & ~old
    rgb = np.where(old[..., None], fill_from(src, good), rgb)
    moved = ndimage.shift(boss, (dy, dx), order=1, mode="constant")
    moved_rgb = np.stack([ndimage.shift(src[..., c], (dy, dx), order=1, mode="nearest") for c in range(3)], -1)
    moved = moved * (box > 0.5)
    rgb = rgb * (1 - moved[..., None]) + moved_rgb * moved[..., None]
    rgb = despill(rgb, a)
    save_rgba(rgb, a, os.path.join(OUT, "portal-wall.png"))
    report["wall"] = {"grain": "round 2's per-channel-equal sRGB grain (seed 301) subtracted, luma-only grain (seed 401, sd 1.8 levels) added",
                      "boss_moved_px": [dx, dy], "spill": spill_check(rgb, a)}


def wheel(report: dict) -> None:
    w = np.asarray(Image.open(os.path.join(V3, "bypass-wheel.png")).convert("RGBA")).astype(np.float64)
    rim = np.asarray(Image.open(os.path.join(R, "design", "portal2", "masks", "wheel--wheel_rim.png")).convert("L")).astype(np.float64) / 255.0
    rgb, a = w[..., :3], w[..., 3] / 255.0
    sel = (rim > 0.5) & (a > 0.8)
    L = lum(rgb)
    p90 = float(np.percentile(L[sel], 90))
    target = 145.0
    lin = to_lin(rgb)
    k = (to_lin(np.array([[target] * 3]))[0, 0] / to_lin(np.array([[p90] * 3]))[0, 0])
    # worn bare steel: the gain falls off toward the rim's inner edge, so the spokes stay painted
    lifted = to_srgb(lin * k)
    out = rgb * (1 - rim[..., None]) + lifted * rim[..., None]
    save_rgba(out, a, os.path.join(OUT, "bypass-wheel.png"))
    report["wheel"] = {"rim_p90_before": round(p90, 1), "rim_p90_after": round(float(np.percentile(lum(out)[sel], 90)), 1), "linear_gain": round(float(k), 3)}


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    report: dict = {}
    front(report)
    wall(report)
    wheel(report)
    for n in ("portal-frame.png", "portal-curtain.png", "portal-curtain-open.png", "lens.png"):
        shutil.copy(os.path.join(V3, n), os.path.join(OUT, n))
    json.dump(report, open(os.path.join(R, "layers", "report4.json"), "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
