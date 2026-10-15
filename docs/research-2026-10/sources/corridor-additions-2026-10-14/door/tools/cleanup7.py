"""Round 7 (add7, track DOOR) cleanup: Codex's paint (codex/paint-door7/out/door7-painted.png, kept
untouched with its C2PA chunk; a resampled copy is used) becomes material detail only. Every new part
is re-imposed from its design mask, and its value is the part's albedo times the light that round 6's
painted layers already carry at that place (light from the visible fittings), times Codex's relative
detail (its high-pass, clamped). Outside the new masks every pixel is round 6's, exactly.

Writes add7/door/layers/:
  portal-wall.png    round 6's wall layer + blast frame (far jamb and head plates, bolts, joints),
                     the RESTRICTED AREA sign plate and its typeset stencil, the pocket's wiper
                     seals and the leaf's parked leading edge in the far reveal, the floor rail
  portal-front.png   round 6's front layer + the near head plate and its bolt, the second saddle strap
  leaf-front.png     the blast leaf's front face, elevation at EL_PPM (160 px per m), lit flat at the
                     leaf's brightest place (the game multiplies by the place's light per vertex)
  leaf-edge.png      its leading edge, elevation at EL_PPM, lit as the far reveal is
  report7.json       the checks
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
from stack import common, p2  # noqa: E402
from common import to_srgb_u8, from_srgb_u8  # noqa: E402
import portal7 as d7  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
D = os.path.join(ROOT, "design")
J = os.path.join(ROOT, "codex", "paint-door7")
OUT = os.path.join(ROOT, "layers")
V6 = os.path.join(d7.R6, "layers", "v6")
LUM = np.array([0.2126, 0.7152, 0.0722])


def mask(name):
    return np.asarray(Image.open(os.path.join(D, "masks", name)).convert("L")).astype(float) / 255.0


def load(p):
    return np.asarray(Image.open(p).convert("RGBA")).astype(float) / 255.0


def codex_1024():
    """Codex's 1254 px output resampled to the 1024 edit-target grid (alignment measured: pure scale
    1254/1024, offset 0)."""
    im = Image.open(os.path.join(J, "out", "door7-painted.png")).convert("RGB")
    return np.asarray(im.resize((1024, 1024), Image.Resampling.LANCZOS)).astype(float) / 255.0


def detail(lin_img, m, sigma, lo=0.86, hi=1.14):
    """Codex's relative detail inside mask m: its luminance over its own blurred luminance (normalised
    blur restricted to the mask), clamped, so its broad light never comes through."""
    y = np.maximum((lin_img * LUM).sum(-1), 1e-5)
    w = (m > 0.5).astype(float)
    num = ndimage.gaussian_filter(y * w, sigma)
    den = ndimage.gaussian_filter(w, sigma)
    base = num / np.maximum(den, 1e-6)
    d = np.where(w > 0, y / np.maximum(base, 1e-6), 1.0)
    return np.clip(d, lo, hi)


def main():
    os.makedirs(OUT, exist_ok=True)
    panels = json.load(open(os.path.join(J, "panels.json")))
    C = from_srgb_u8((codex_1024() * 255).round())
    rep = {}

    # ------------------------------------------------------------ panel A -> the CVD canvas
    PA = panels["A"]
    x0, y0, x1, y1 = PA["world"]
    ax, ay = PA["at"]
    pw, ph = PA["px"]
    cA = np.zeros((1900, 1232, 3))
    cx0, cy0 = int((x0 - 676) * 4), int((y0 - 150) * 4)
    cA[cy0:cy0 + ph, cx0:cx0 + pw] = C[ay:ay + ph, ax:ax + pw]
    covered = np.zeros((1900, 1232))
    covered[cy0:cy0 + ph, cx0:cx0 + pw] = 1.0

    wall6 = load(os.path.join(V6, "portal-wall.png"))
    lin6 = from_srgb_u8((wall6[..., :3] * 255).round())
    wall = wall6.copy()
    lin = lin6.copy()

    def put(m, col_lin):
        nonlocal lin, wall
        m3 = m[..., None]
        lin = lin * (1 - m3) + col_lin * m3
        wall[..., 3] = np.maximum(wall[..., 3], m)

    # the light round 6 painted at each place, from the material it painted there
    L_conc = lin6 / np.array(p2.CONCRETE)       # on the cross-wall's concrete face
    L_rev = lin6 / np.array(p2.STEEL)           # on the far reveal's steel liner
    L_thr = lin6 / np.array((0.27, 0.275, 0.29))  # on the steel threshold
    # smooth each light field inside its own surface so the old paint's texture does not print through
    def smooth_light(L, surf, sigma=6.0):
        w = surf.astype(float)
        out = np.stack([ndimage.gaussian_filter(L[..., c] * w, sigma) / np.maximum(ndimage.gaussian_filter(w, sigma), 1e-6) for c in range(3)], -1)
        return out

    face_mask = np.asarray(Image.open(os.path.join(d7.R6, "design", "portal3", "masks", "wall--face_far_column.png")).convert("L")) > 128
    face_mask |= np.asarray(Image.open(os.path.join(d7.R6, "design", "portal3", "masks", "wall--face_upper.png")).convert("L")) > 128
    rev_mask = np.asarray(Image.open(os.path.join(d7.R6, "design", "portal3", "masks", "wall--reveal_far.png")).convert("L")) > 128
    thr_mask = np.asarray(Image.open(os.path.join(d7.R6, "design", "portal3", "masks", "wall--threshold.png")).convert("L")) > 128
    # keep only the bare surface (no hardware painted on it) for the light estimate
    hw = np.zeros((1900, 1232), bool)
    for n in ("jb_backplate", "jb_box", "jb_side", "conduit_up0", "conduit_up1", "conduit_up2", "penetration_plate", "door_light_feed", "operator_feed",
              "feed_strap", "door_light_bracket", "door_light_body", "door_light_lens", "pour_joint0", "far_col_joint", "frame_far_jamb", "frame_head", "reveal_angle_far"):
        p = os.path.join(d7.R6, "design", "portal3", "masks", f"wall--{n}.png")
        if os.path.exists(p):
            hw |= ndimage.binary_dilation(np.asarray(Image.open(p).convert("L")) > 60, iterations=3)
    Lc = smooth_light(np.where((face_mask & ~hw)[..., None], L_conc, 0), face_mask & ~hw, 8.0)
    Lr = smooth_light(np.where((rev_mask & ~hw)[..., None], L_rev, 0), rev_mask & ~hw, 4.0)
    Lt = smooth_light(np.where(thr_mask[..., None], L_thr, 0), thr_mask, 4.0)

    # ---- (a) blast frame plates: GUNSHIP under the concrete's light, Codex detail; joints; bolts
    plates = np.clip(mask("wall--bf_jamb_plate.png") + mask("wall--bf_head_plate.png"), 0, 1)
    dt = detail(cA, plates * covered, 5.0)
    col = np.array(p2.GUNSHIP) * Lc * 0.92 * dt[..., None]
    put(plates, col)
    seams = np.clip(sum(mask(f"wall--bf_jamb_seam{i}.png") + mask(f"wall--bf_head_seam{i}.png") for i in range(2)), 0, 1)
    put(seams * 0.85, np.array(p2.GUNSHIP) * Lc * 0.40)
    bolts = mask("wall--bf_bolts.png")
    put(bolts, np.array(p2.STEEL) * Lc * 0.95)
    # a 1 px shadow line under each bolt head (the light is above and to the left)
    bsh = np.clip(ndimage.shift(bolts, (2, -1), order=1) - bolts, 0, 1) * plates
    put(bsh * 0.45, np.array(p2.GUNSHIP) * Lc * 0.45)
    rep["blast_frame"] = {"plate_px": int((plates > 0.5).sum()), "bolt_px": int((bolts > 0.5).sum())}

    # ---- (b) the sign plate: weathered white under the concrete's light, Codex detail; then the text
    sp = mask("wall--sign_plate.png")
    dt = detail(cA, sp * covered, 6.0, 0.9, 1.1)
    WHITE = np.array((0.62, 0.61, 0.62))  # lusterless white 37875, weathered
    col = WHITE * Lc * dt[..., None]
    # grime gathered along the bottom edge (Codex was asked for it; kept, but its value is set here)
    put(sp, col)
    sb = mask("wall--sign_bolts.png")
    put(sb, np.array(p2.STEEL) * Lc * 0.8)
    txt = mask("wall--TEXT-sign.png")
    INK = np.array(p2.BLACK) * 1.6  # 37038 black, matte, slightly greyed by dust
    put(txt * sp, INK * Lc)
    # its 12 mm edge: a thin dark line under the plate (it stands off the wall; light from above)
    under = np.clip(ndimage.shift(sp, (3, 0), order=1) - sp, 0, 1)
    put(under * 0.5, np.array(p2.CONCRETE) * Lc * 0.45)
    sp_l = (np.where(sp[..., None] > 0.9, to_srgb_u8(lin).astype(float), np.nan) * LUM).sum(-1)
    rep["sign"] = {"plate_mean_luma": round(float(np.nanmean(np.where(sp > 0.9, (to_srgb_u8(lin).astype(float) * LUM).sum(-1), np.nan))), 1),
                   "letter_mean_luma": round(float(np.nanmean(np.where((txt > 0.8) & (sp > 0.9), (to_srgb_u8(lin).astype(float) * LUM).sum(-1), np.nan))), 1)}

    # ---- (c) the pocket's mouth in the far reveal: wiper seals and the parked leading edge
    seals = np.clip(mask("wall--slot_seal_front.png") + mask("wall--slot_seal_back.png"), 0, 1)
    put(seals, np.array(p2.RUBBER) * Lr * 1.4)
    edge = mask("wall--leaf_edge_parked.png")
    stripes = mask("wall--leaf_edge_stripes.png")
    angles = mask("wall--leaf_edge_angles.png")
    dt = detail(cA, edge * covered, 3.0, 0.88, 1.12)
    YEL = np.array(p2.YELLOW) * 0.62  # safety yellow, aged and grimed
    BLK = np.array(p2.BLACK) * 1.5
    # the stripes: yellow where the design's stripe mask is, black between
    _, la, lb = p2.side_plane(d7.A_F).points()
    band = (((la - d7.T_LF) + lb) / 0.10) % 2.0 < 1.0
    alb = np.where(band[..., None], YEL, BLK)
    alb = np.where((angles > 0.5)[..., None], np.array(p2.STEEL) * 0.9, alb)
    put(edge, alb * Lr * dt[..., None])
    # the leaf's own foot: its rubber sweep sits on the rail, a darker line at the floor
    rep["leaf_edge_parked"] = {"px": int((edge > 0.5).sum()),
                               "yellow_mean_luma": round(float(np.nanmean(np.where((edge > 0.9) & band & (angles < 0.1), (to_srgb_u8(lin).astype(float) * LUM).sum(-1), np.nan))), 1)}

    # ---- the floor rail across the threshold
    rr = mask("wall--rail_recess.png")
    put(rr, np.array((0.035, 0.037, 0.04)) * Lt * 1.2)
    rh = mask("wall--rail_head.png")
    dt = detail(cA, rh * covered, 2.0, 0.9, 1.15)
    put(rh, np.array(p2.STEEL_WORN) * Lt * 0.85 * dt[..., None])

    wall[..., :3] = to_srgb_u8(lin) / 255.0
    Image.fromarray((np.clip(wall, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, "portal-wall.png"))
    newm = np.clip(plates + seams + bolts + sp + sb + seals + edge + rr + rh + under + bsh, 0, 1)
    same = np.abs(np.asarray(Image.open(os.path.join(OUT, "portal-wall.png")).convert("RGBA")).astype(int) - (wall6 * 255).round().astype(int)).max(-1)
    rep["wall_outside_new_masks_changed_px"] = int(((same > 0) & (ndimage.binary_dilation(newm > 0.001, iterations=1) == 0)).sum())

    # ------------------------------------------------------------ the front layer (near column)
    front6 = load(os.path.join(V6, "portal-front.png"))
    flin6 = from_srgb_u8((front6[..., :3] * 255).round())
    flin = flin6.copy()
    front = front6.copy()
    # the column's approach face above the jamb frame: concrete lit by the corridor; take its light
    pier = np.asarray(Image.open(os.path.join(d7.R6, "design", "portal6", "masks", "front--pier_face.png")).convert("L")) > 128
    fL = smooth_light(np.where(pier[..., None], flin6 / np.array(p2.CONCRETE), 0), pier, 3.0)
    nh = mask("front--bf_near_head.png")
    dt = detail(cA, nh * covered, 3.0)
    col = np.array(p2.GUNSHIP) * fL * 0.92 * dt[..., None]
    flin = flin * (1 - nh[..., None]) + col * nh[..., None]
    nb = mask("front--bf_near_bolts.png")
    flin = flin * (1 - nb[..., None]) + np.array(p2.STEEL) * fL * 0.95 * nb[..., None]
    # (h) the second saddle strap, painted from the existing strap's own steel (round 6)
    s1 = np.asarray(Image.open(os.path.join(d7.R6, "design", "portal6", "masks", "front--lamp_conduit_strap.png")).convert("L")) > 128
    strap_col = flin6[s1].mean(0)
    s2 = mask("front--lamp_conduit_strap2.png")
    flin = flin * (1 - s2[..., None]) + strap_col * s2[..., None]
    rep["strap2"] = {"px": int((s2 > 0.5).sum()), "colour_from_round6_strap_srgb": [int(v) for v in to_srgb_u8(strap_col)]}
    front[..., :3] = to_srgb_u8(flin) / 255.0
    front[..., 3] = np.maximum(front6[..., 3], np.clip(nh + nb + s2, 0, 1))
    Image.fromarray((np.clip(front, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, "portal-front.png"))

    # ------------------------------------------------------------ the leaf's elevations
    LREF = 0.083 * np.array([0.92, 1.0, 1.06])
    for key, nm, size_m in (("B", "leaf-front", (d7.LEAF_L, d7.LEAF_H)), ("C", "leaf-edge", (d7.T_LB - d7.T_LF, d7.LEAF_H))):
        P = panels[key]
        bx, by = P["at"]
        w, h = P["px"]
        cp = C[by:by + h, bx:bx + w]
        W2, H2 = int(round(size_m[0] * d7.EL_PPM)), int(round(size_m[1] * d7.EL_PPM))
        cp = np.stack([np.asarray(Image.fromarray(cp[..., c].astype(np.float32), "F").resize((W2, H2), Image.Resampling.BICUBIC)) for c in range(3)], -1)
        alb = from_srgb_u8(np.asarray(Image.open(os.path.join(D, f"design-{nm}-albedo.png")).convert("RGB")).astype(float))
        whole = np.ones((H2, W2))
        if nm == "leaf-front":
            dt = detail(cp, whole, 10.0, 0.85, 1.15)
            out = alb * dt[..., None]
        else:
            # the edge, lit as the far reveal is at the same heights (its parked place)
            rows_h = d7.LEAF_H - (np.arange(H2) + 0.5) / d7.EL_PPM
            Lrow = np.zeros((H2, 3))
            ys = []
            for i, hh in enumerate(rows_h):
                X, Y = p2.scr(p2.pt(d7.A_F, min(hh, d7.H_OPEN), (d7.T_LF + d7.T_LB) / 2))
                ys.append(Y)
            ys = np.array(ys)
            xs = p2.scr(p2.pt(d7.A_F, 1.0, (d7.T_LF + d7.T_LB) / 2))[0]
            col_x = int((xs - 676) * 4)
            prof = Lr[:, col_x - 2:col_x + 3].mean(1)
            for i, Y in enumerate(ys):
                Lrow[i] = prof[int(np.clip((Y - 150) * 4, 0, 1899))]
            dt = detail(cp, whole, 4.0, 0.88, 1.12)
            s = (np.arange(W2) + 0.5) / d7.EL_PPM
            bandE = (((s[None, :] + rows_h[:, None]) / 0.10) % 2.0) < 1.0
            angE = (s[None, :] < d7.EDGE_ANGLE) | (s[None, :] > (d7.T_LB - d7.T_LF) - d7.EDGE_ANGLE)
            albE = np.where(bandE[..., None], YEL, BLK)
            albE = np.where(angE[..., None], np.array(p2.STEEL) * 0.9, albE)
            albE[rows_h < 0.02] = np.array(p2.RUBBER)
            out = albE * Lrow[:, None, :] * dt[..., None]
            LREF_E = Lrow
        rgba = np.dstack([to_srgb_u8(out), np.full((H2, W2), 255, np.uint8)])
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, f"{nm}.png"))
        rep[nm] = {"size": [W2, H2], "mean_luma": round(float((to_srgb_u8(out).astype(float) * LUM).sum(-1).mean()), 1)}
    for f in ("portal-curtain.png", "portal-curtain-open.png", "portal-frame.png", "bypass-wheel.png", "lens.png"):
        shutil.copy(os.path.join(V6, f), os.path.join(OUT, f))
    for f in ("corridor-far.png", "corridor-mid.png"):
        shutil.copy(os.path.join(V6, "game", f), os.path.join(OUT, f))
    json.dump(rep, open(os.path.join(OUT, "report7.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
