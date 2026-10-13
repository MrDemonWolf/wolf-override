"""Fix round 4 (v5) deterministic cleanup. No new image-tool paint: every new pixel carries paint
already in the slice or main's own far plate, under the design's light (REAL-LOOK section 4, step 3).
Inputs: layers/v4/* (round 3's layers), design/portal5 (the guide return), design/far-patch2 masks,
main's corridor-far.png.

Front layer (must 1, the see-through slit):
  * the near guide's return (design/portal5, part guide_near_side) is painted into the slit between
    the guide and the jamb: the guide's own painted steel, sampled from the nearest guide pixel on the
    same row (its texture over its design light), under the return's design light;
  * every internal anti-aliasing seam inside the column (a pixel below full alpha with fully opaque
    pixels within 2 px on both sides, across or along) is closed to alpha 1, its colour completed
    from those neighbours, so no part boundary inside the column lets anything behind show through;
  * the outer outline, the lamp's glass hole and the contact shadows keep their alpha.
Far plate (should 3 and 4):
  * the new bay (right of the seam column, the corridor wall and dado; pipes, clamps, luminaire,
    joints and the dado line are left as they are) takes the old bay's finish: main's own painted
    wall at the same pixels, as relative detail (luma over its 12 px low-pass, measured inside the bay) carries the painterly
    mottling and the drip stains under the pipe run where the leak would reach; main's old pilaster
    (source x 1236..1294) and its ceiling cables (y < 236) are not used, their band takes the detail
    either side, averaged; the bay's own fine block detail stays at 30 %; the low-pass value (the
    pendant's pool, the seam match) is unchanged; chroma rises 12 % toward the old bay's saturation;
    the pendant's lens takes the corridor fittings' cool tint;
  * the lockdown beacon's mount (far x 0.659, source (1265.3, 291.6); the beacon and its stalk are
    the game's live drawing): a 0.35 x 0.28 m steel back box above the stalk, lit from the pendant
    above it, with a lid seam, four screws and a soft cast shadow on the wall, and a 25 mm conduit
    from its top to the ceiling tray in two strap clamps (behind the hanging luminaire).
Writes layers/v5/ and layers/report5.json.
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
from imgkit import lum, to_lin, to_srgb  # noqa: E402
from cleanup2 import mask, rgba, save_rgba, visible_masks, spill_check, mgauss  # noqa: E402
from cleanup4 import fill_from  # noqa: E402

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "design"))  # the design tools (tools/design/)
import portal5 as p5  # noqa: E402

D5 = os.path.join(R, "design", "portal5")
V4 = os.path.join(R, "layers", "v4")
OUT = os.path.join(R, "layers", "v5")
M2 = os.path.join(R, "design", "far-patch2", "masks")
FX0 = 1112  # far-patch2 canvas origin in the far plate
BEACON = (0.659 * 1920.0, 0.27 * 1080.0)


def front(report: dict) -> None:
    rgb, a = rgba(os.path.join(V4, "portal-front.png"))
    parts = p5.front_parts_v5()
    names = [p.name for p in parts]
    m5 = {n: mask(os.path.join(D5, "masks", f"front--{n}.png")) for n in names}
    vis = visible_masks(names, m5)
    d5, _ = rgba(os.path.join(D5, "design-front.png"))
    L5 = lum(to_lin(d5))
    side = vis["guide_near_side"]
    # the guide's material: its v4 paint over its design light, carried along each row
    guide = vis["guide_near"] > 0.9
    lin = to_lin(rgb)
    tex = lin / np.maximum(L5, 1e-6)[..., None]
    tex = fill_from(tex, guide & (a > 0.999))
    col = to_srgb(tex * L5[..., None])
    before = a.copy()
    rgb = rgb * (1 - side[..., None]) + col * side[..., None]
    a = np.maximum(a, side)
    # close internal seams inside the column (design x 440..580)
    op = a >= 0.999
    seam = np.zeros_like(op)
    for ax in (0, 1):
        for d in (1, 2):
            lo = np.roll(op, d, ax)
            for e in (1, 2):
                hi = np.roll(op, -e, ax)
                seam |= lo & hi
    seam &= (a < 0.999) & (a > 0.0)
    seam[:, :440] = False
    seam[:, 580:] = False
    gh = mask(os.path.join(D5, "masks", "front--GLASS_HOLE.png"))
    seam &= ndimage.binary_dilation(gh > 0.01, iterations=2) == False  # noqa: E712
    nb = ndimage.uniform_filter(rgb * op[..., None], (5, 5, 1)) / np.maximum(ndimage.uniform_filter(op.astype(float), 5), 1e-6)[..., None]
    rgb = np.where(seam[..., None], rgb * a[..., None] + nb * (1 - a[..., None]), rgb)
    a = np.where(seam, 1.0, a)
    save_rgba(rgb, a, os.path.join(OUT, "portal-front.png"))
    # checks over the guide's height, from the guide's left edge to the chamfer
    g = json.load(open(os.path.join(D5, "spec.json")))["guide_return"]
    x0, x1 = g["slit_check_design_cols"]
    y0, y1 = g["slit_check_design_rows"]
    band = a[y0:y1, x0:x1]
    hole = gh[y0:y1, x0:x1] > 0.01
    hole = ndimage.binary_dilation(hole, iterations=2)
    inner = np.ones_like(band, bool)
    inner[:, -2:] = False  # the chamfer's outer outline
    bad = (band < 0.999) & ~hole & inner
    report["front"] = {
        "guide_return_px_filled": int((side > 0.01).sum()),
        "slit_px_before_alpha0": int(((before < 0.01) & (side > 0.5)).sum()),
        "seams_closed_px": int(seam.sum()),
        "column_band_design_px": [x0, y0, x1, y1],
        "column_band_non_opaque_px_excluding_glass_and_outline": int(bad.sum()),
        "column_band_min_alpha_excluding_glass_and_outline": round(float(band[~hole & inner].min()), 4),
        "spill": spill_check(rgb, a),
        "guide_return_mean_luma": round(float(lum(rgb[side > 0.9]).mean()), 1),
        "guide_mean_luma": round(float(lum(rgb[guide]).mean()), 1),
    }


def m2(n: str) -> np.ndarray:
    return np.asarray(Image.open(os.path.join(M2, n + ".png")).convert("L")).astype(np.float64) / 255.0


def far(report: dict) -> None:
    v4 = np.asarray(Image.open(os.path.join(V4, "corridor-far.png")).convert("RGB")).astype(np.float64)
    mn = np.asarray(Image.open(os.path.join(R, "game-main", "apps", "game", "assets", "rooms", "corridor-far.png")).convert("RGB")).astype(np.float64)
    H, W = v4.shape[:2]
    full = lambda m: np.pad(m, ((0, H - m.shape[0]), (FX0, W - FX0 - m.shape[1])))  # noqa: E731
    wall = np.clip(full(m2("corr_wall")) + full(m2("corr_dado")), 0, 1)
    keep = np.zeros((H, W))
    for n in ("corr_pipe0", "corr_pipe1", "corr_pipe2", "corr_pipe_clamp0", "corr_pipe_clamp1", "corr_panel_joint",
              "corr_dado_line", "lum_housing", "lum_lens", "lum_chains", "seam_column", "seam_column_web", "mach_wall"):
        keep = np.maximum(keep, full(m2(n)))
    keep = ndimage.grey_dilation(keep, size=(3, 3))
    region = wall * (1 - keep)
    xx = np.arange(W)[None, :]
    yy = np.arange(H)[:, None]
    region = region * (xx >= 1148) * (yy >= 192)
    # the bay's own block detail and main's painted detail (log luma over a 5 px low-pass)
    lin4 = to_lin(v4)
    L4 = lum(lin4)
    Lm = lum(to_lin(mn))
    # the split is at 12 px (6 world px): the bay's broad light (the pendant's pool, the seam match)
    # stays, main's mottling at the scale of the old bay's patches and drips comes in
    lp4 = mgauss(L4, (region > 0).astype(float), 12.0)
    own = np.log(np.maximum(L4, 1e-5)) - np.log(np.maximum(lp4, 1e-5))
    dm = np.log(np.maximum(Lm, 1e-5)) - np.log(np.maximum(mgauss(Lm, (region > 0).astype(float), 12.0), 1e-5))
    good = np.ones((H, W), bool)
    good[:, 1230:1300] = False
    good[:236, :] = False
    dm = np.clip(dm, -0.9, 0.9)
    fill = (np.roll(dm, 64, 1) + np.roll(dm, -64, 1)) / np.sqrt(2.0) * 0.85
    w_pil = np.clip(np.minimum(xx - 1230, 1300 - xx) / 6.0, 0, 1) * ((xx >= 1230) & (xx <= 1300))
    dmf = dm * (1 - w_pil) + fill * w_pil
    w_top = np.clip((yy - 236) / 16.0, 0, 1)
    detail = 0.3 * own + 1.0 * dmf * w_top  # the bay's own block detail stays at 30 %
    # soft edges into the kept parts so no outline forms
    rs = ndimage.gaussian_filter(region, 1.0) * (region > 0)
    newL = lp4 * np.exp(detail)
    k = np.where(L4 > 1e-6, newL / np.maximum(L4, 1e-6), 1.0)
    k = 1 + (k - 1) * rs
    lin5 = lin4 * k[..., None]
    # chroma toward the old bay (luma kept)
    Lk = lum(lin5)
    ch = 1 + 0.12 * rs
    lin5 = Lk[..., None] + (lin5 - Lk[..., None]) * ch[..., None]
    out = to_srgb(np.clip(lin5, 0, None))
    # the pendant's lens: the corridor fittings' cool tint (luma kept)
    lens = full(m2("lum_lens"))
    tint = to_lin(np.array([[188.0, 236.0, 255.0]]))[0]
    Ll = lum(to_lin(out))
    tl = tint / lum(tint[None])[0]
    lens_col = to_srgb(Ll[..., None] * tl[None, None, :])
    out = out * (1 - lens[..., None] * 0.85) + lens_col * lens[..., None] * 0.85
    out = beacon_mount(out, report)
    # nothing left of the seam column's right edge changes
    out[:, :1148] = v4[:, :1148]
    Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "corridor-far.png"))

    def stats(img, x0, y0, x1, y1, m=None):
        r = img[y0:y1, x0:x1]
        mm = region[y0:y1, x0:x1] > 0.9 if m is None else m
        px = r[mm]
        L = lum(px)
        mx, mnn = px.max(1), px.min(1)
        sat = float(((mx - mnn) / np.maximum(mx, 1)).mean())
        Lr = lum(r)
        hp = Lr - ndimage.gaussian_filter(Lr, 4)
        return {"mean_luma": round(float(L.mean()), 1), "sat": round(sat, 3), "hp_sd": round(float(hp[mm].std()), 2)}

    old_m = np.ones((180, 250), bool)
    report["far"] = {
        "new_bay_before": stats(v4, 1150, 380, 1430, 560),
        "new_bay_after": stats(out, 1150, 380, 1430, 560),
        "old_bay_reference_main": stats(mn, 850, 380, 1100, 560, old_m),
        "new_bay_upper_before": stats(v4, 1150, 236, 1430, 315),
        "new_bay_upper_after": stats(out, 1150, 236, 1430, 315),
        "unchanged_left_of_x1148": bool(np.array_equal(np.clip(out[:, :1148] + 0.5, 0, 255).astype(np.uint8), v4[:, :1148].astype(np.uint8))),
    }


def beacon_mount(out: np.ndarray, report: dict) -> np.ndarray:
    """Paints the beacon's back box and conduit (source px, 2 per world px). Light: the pendant
    directly above and in front (its lens at y 225), so the box's top edge and the conduit's
    left-front edge catch it and the box casts a short soft shadow straight down the wall."""
    H, W = out.shape[:2]
    cx, cy = BEACON
    rng = np.random.default_rng(505)
    lin = to_lin(out)
    wallL = float(np.median(lum(lin[240:254, int(cx) - 30:int(cx) + 30])))
    bx0, bx1 = cx - 14.0, cx + 14.0
    by0, by1 = cy - 18.0 - 22.0, cy - 18.0  # sits right on the stalk's top (the game draws the stalk)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)

    def box(x0, y0, x1, y1, soft=0.5):
        return (np.clip(xx - x0 + soft, 0, 1) * np.clip(x1 - xx + soft, 0, 1) * np.clip(yy - y0 + soft, 0, 1) * np.clip(y1 - yy + soft, 0, 1))

    # cast shadow on the wall: the box stands 0.1 m off it, the light is above and in front
    sh = box(bx0 + 1, by0 + 4, bx1 + 1, by1 + 5, 0.5)
    sh = ndimage.gaussian_filter(sh, 2.2) * 0.55
    lin = lin * (1 - sh[..., None])
    steel = np.array([0.150, 0.162, 0.190])  # gunship grey, like the door's hardware
    concrete = np.array([0.205, 0.21, 0.225])
    # the light at the box: the wall's own colour over the concrete's albedo (cool, from the pendant)
    light = ndimage.gaussian_filter(lin, (8, 8, 0)) / concrete[None, None, :]
    lightL = lum(light)
    light = light / np.maximum(lightL, 1e-6)[..., None]  # its colour only; the value is set below
    grain = ndimage.gaussian_filter(rng.standard_normal((H, W)), 0.7)
    grain = grain / grain.std() * 0.06
    # front face: a gentle fall from the top (nearer the lamp) to the bottom
    fall = np.clip(1.0 - (yy - by0) / (by1 - by0) * 0.35, 0.6, 1.0)
    face_L = wallL * 1.05 * fall * (1 + grain)
    face = box(bx0, by0, bx1, by1)
    col = steel / lum(steel[None])[0] * light * face_L[..., None]
    lin = lin * (1 - face[..., None]) + col * face[..., None]
    # lit top edge (the lid's rounded edge facing the lamp), darker bottom edge and sides
    top = box(bx0, by0, bx1, by0 + 2.0)
    lin = lin * (1 - top[..., None]) + steel / lum(steel[None])[0] * light * wallL * 1.9 * top[..., None]
    bot = box(bx0, by1 - 1.5, bx1, by1)
    lin = lin * (1 - bot[..., None] * 0.55)
    for sx in (bx0, bx1 - 1.2):
        sd = box(sx, by0 + 2, sx + 1.2, by1)
        lin = lin * (1 - sd[..., None] * 0.35)
    # the lid seam, 2 px in, and four screws
    seam = box(bx0 + 2.5, by0 + 4.0, bx1 - 2.5, by0 + 4.9)
    lin = lin * (1 - seam[..., None] * 0.45)
    for sx, sy in ((bx0 + 3.5, by0 + 7.0), (bx1 - 3.5, by0 + 7.0), (bx0 + 3.5, by1 - 3.5), (bx1 - 3.5, by1 - 3.5)):
        d = np.hypot(xx - sx, yy - sy)
        s = np.clip(1.6 - d, 0, 1)
        lin = lin * (1 - s[..., None]) + steel / lum(steel[None])[0] * light * wallL * 1.5 * s[..., None]
    # conduit from the box's top to the ceiling tray (y 192), 25 mm: 3 px, lit on its left-front
    c0, c1 = cx - 1.5, cx + 1.5
    # the luminaire hangs in front of the wall: the conduit passes behind its housing, lens and chains
    occ = np.zeros((H, W))
    for n in ("lum_housing", "lum_lens", "lum_chains"):
        mm = m2(n)
        occ[:mm.shape[0], FX0:FX0 + mm.shape[1]] = np.maximum(occ[:mm.shape[0], FX0:FX0 + mm.shape[1]], mm)
    occ = ndimage.grey_dilation(occ, size=(3, 1))
    vis_ = 1 - occ
    cond = box(c0, 192.0, c1, by0 + 0.5) * vis_
    cL = wallL * 1.2 * (1 + grain * 0.6)
    ccol = np.array([0.36, 0.37, 0.39])
    ccol = ccol / lum(ccol[None])[0]
    lin = lin * (1 - cond[..., None]) + (ccol[None, None, :] * light * cL[..., None]) * cond[..., None]
    hl = box(c0, 192.0, c0 + 1.0, by0) * vis_
    lin = lin * (1 - hl[..., None] * 0.6) + ccol[None, None, :] * light * wallL * 1.8 * hl[..., None] * 0.6
    dk = box(c1 - 0.8, 192.0, c1, by0) * vis_
    lin = lin * (1 - dk[..., None] * 0.4)
    csh = ndimage.gaussian_filter(box(c1, 192.0, c1 + 1.6, by0), 0.8) * 0.4 * (1 - cond) * vis_
    lin = lin * (1 - csh[..., None])
    for sy in (238.0, 204.0):
        st = box(c0 - 1.5, sy, c1 + 1.5, sy + 2.2) * vis_
        lin = lin * (1 - st[..., None]) + ccol[None, None, :] * light * wallL * 1.45 * st[..., None]
    report["beacon_mount"] = {"box_source_px": [round(bx0, 1), round(by0, 1), round(bx1, 1), round(by1, 1)],
                              "box_world_m": [0.35, 0.28], "conduit_source_x": [round(c0, 1), round(c1, 1)],
                              "conduit_y": [192, round(by0, 1)], "clamps_y": [204, 238], "wall_luma_reference": round(float(to_srgb(np.array([[wallL] * 3]))[0, 0]), 1)}
    return to_srgb(np.clip(lin, 0, None))


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    report: dict = {}
    front(report)
    far(report)
    for n in ("portal-wall.png", "portal-frame.png", "portal-curtain.png", "portal-curtain-open.png", "lens.png", "bypass-wheel.png"):
        shutil.copy(os.path.join(V4, n), os.path.join(OUT, n))
    json.dump(report, open(os.path.join(R, "layers", "report5.json"), "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
