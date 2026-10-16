"""Round 8 cleanup (add7 fix round 1, track DOOR). Codex's paint (codex/paint-door8/out/door8-painted.png,
kept untouched with its C2PA chunk; a resampled copy is used) becomes material detail only: its
high-pass, clamped, inside the design masks. Every value is the part's albedo times the light round 6
painted at that place. Outside the new masks every pixel is the base layer's (round 7 minus its
redrawn parts), and the door light's bracket, body, lens and feed are round 6's pixels exactly.

Writes add7/fix1/door/layers/: portal-wall.png, portal-front.png, leaf-front.png, leaf-edge.png,
report8.json, plus copies of round 6's unchanged pieces.
"""
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
import portal8 as d8  # noqa: E402
from portal8 import p2, d7  # noqa: E402
from common import to_srgb_u8, from_srgb_u8  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
D = os.path.join(ROOT, "design")
J = os.path.join(ROOT, "..", "codex", "paint-door8")
OUT = os.path.join(ROOT, "layers")
V6 = os.path.join(d7.R6, "layers", "v6")
M3 = os.path.join(d7.R6, "design", "portal3", "masks")
M6 = os.path.join(d7.R6, "design", "portal6", "masks")
LUM = np.array([0.2126, 0.7152, 0.0722])

LINER = np.array((0.315, 0.345, 0.39))   # painted steel liner: cooler and lighter than the concrete (0.205); set so it reads luma ~50 in game against the concrete's ~41
ARRIS_GAIN = 1.55                          # 40 mm plate edge facing the light
YEL = np.array(p2.YELLOW) * 0.62
BLK = np.array(p2.BLACK) * 1.5


def mask(name):
    p = os.path.join(D, "masks", name)
    if not os.path.exists(p):
        return np.zeros((1900, 1232))
    return np.asarray(Image.open(p).convert("L")).astype(float) / 255.0


def masks(prefix):
    out = np.zeros((1900, 1232))
    for f in os.listdir(os.path.join(D, "masks")):
        if f.startswith(prefix):
            out = np.maximum(out, np.asarray(Image.open(os.path.join(D, "masks", f)).convert("L")).astype(float) / 255.0)
    return out


def load(p):
    return np.asarray(Image.open(p).convert("RGBA")).astype(float) / 255.0


def codex_1024():
    im = Image.open(os.path.join(J, "out", "door8-painted.png")).convert("RGB")
    return np.asarray(im.resize((1024, 1024), Image.Resampling.LANCZOS)).astype(float) / 255.0


def detail(lin_img, m, sigma, lo=0.88, hi=1.12):
    y = np.maximum((lin_img * LUM).sum(-1), 1e-5)
    w = (m > 0.5).astype(float)
    base = ndimage.gaussian_filter(y * w, sigma) / np.maximum(ndimage.gaussian_filter(w, sigma), 1e-6)
    return np.clip(np.where(w > 0, y / np.maximum(base, 1e-6), 1.0), lo, hi)


def smooth_light(L, surf, sigma):
    w = surf.astype(float)
    return np.stack([ndimage.gaussian_filter(L[..., c] * w, sigma) / np.maximum(ndimage.gaussian_filter(w, sigma), 1e-6) for c in range(3)], -1)


def m3(n):
    return np.asarray(Image.open(os.path.join(M3, f"{n}.png")).convert("L")) > 128


def main():
    os.makedirs(OUT, exist_ok=True)
    panels = json.load(open(os.path.join(J, "panels.json")))
    C = from_srgb_u8((codex_1024() * 255).round())
    rep = {}
    PA = panels["A"]
    x0, y0, _, _ = PA["world"]
    ax, ay = PA["at"]
    pw, ph = PA["px"]
    cA = np.zeros((1900, 1232, 3))
    cx0, cy0 = int((x0 - 676) * 4), int((y0 - 150) * 4)
    cA[cy0:cy0 + ph, cx0:cx0 + pw] = C[ay:ay + ph, ax:ax + pw]
    covered = np.zeros((1900, 1232))
    covered[cy0:cy0 + ph, cx0:cx0 + pw] = 1.0

    wall6 = load(os.path.join(V6, "portal-wall.png"))
    lin6 = from_srgb_u8((wall6[..., :3] * 255).round())
    base = load(os.path.join(OUT, "base-wall.png"))
    wall = base.copy()
    lin = from_srgb_u8((base[..., :3] * 255).round())

    def put(m, col_lin):
        nonlocal lin
        m3_ = m[..., None]
        lin = lin * (1 - m3_) + col_lin * m3_
        wall[..., 3] = np.maximum(wall[..., 3], m)

    # the light round 6 painted at each place (as round 7's cleanup7)
    face = m3("wall--face_far_column") | m3("wall--face_upper")
    rev = m3("wall--reveal_far")
    hw = np.zeros((1900, 1232), bool)
    for n in ("jb_backplate", "jb_box", "jb_side", "conduit_up0", "conduit_up1", "conduit_up2", "penetration_plate", "door_light_feed", "operator_feed",
              "feed_strap", "door_light_bracket", "door_light_body", "door_light_lens", "pour_joint0", "far_col_joint", "frame_far_jamb", "frame_head", "reveal_angle_far"):
        p = os.path.join(M3, f"wall--{n}.png")
        if os.path.exists(p):
            hw |= ndimage.binary_dilation(np.asarray(Image.open(p).convert("L")) > 60, iterations=3)
    Lc = smooth_light(np.where((face & ~hw)[..., None], lin6 / np.array(p2.CONCRETE), 0), face & ~hw, 8.0)
    Lr = smooth_light(np.where((rev & ~hw)[..., None], lin6 / np.array(p2.STEEL), 0), rev & ~hw, 4.0)

    # ---- (a) the liner
    plates = np.clip(mask("wall--liner_head.png") + mask("wall--liner_jamb.png"), 0, 1)
    dt = detail(cA, plates * covered, 5.0)
    put(plates, LINER * Lc * dt[..., None])
    jsh = masks("wall--jamb_joint_shadow")
    put(jsh * 0.8, LINER * Lc * 0.55)
    joints = np.clip(masks("wall--jamb_joint") - jsh + masks("wall--head_joint") - masks("wall--head_joint_lit"), 0, 1)
    put(joints * 0.9, LINER * Lc * 0.30)
    lit = np.clip(masks("wall--head_joint_lit") + mask("wall--arris_outer.png") + mask("wall--arris_top.png"), 0, 1)
    put(lit * 0.9, LINER * Lc * ARRIS_GAIN)
    sa = mask("wall--shadow_above.png") * (1 - plates)
    put(sa * 0.55, np.array(p2.CONCRETE) * Lc * 0.45)
    bolts = np.clip(mask("wall--jamb_bolts.png") + mask("wall--head_bolts.png"), 0, 1)
    put(bolts, LINER * Lc * 0.32)
    # one dull highlight per anchor head, toward the light (up and to the left)
    hl = np.clip(ndimage.shift(bolts, (1.6, 1.6), order=1) * 0 + bolts - ndimage.shift(bolts, (-1.5, -1.5), order=1), 0, 1)
    hl = ndimage.binary_erosion(bolts > 0.5, iterations=1) & (hl > 0.5)
    put(hl.astype(float) * 0.85, LINER * Lc * 1.25)
    rep["liner"] = {"plate_px": int((plates > 0.5).sum()), "bolt_px": int((bolts > 0.5).sum()), "highlight_px": int(hl.sum())}

    # ---- (c) the pocket's mouth: wiper seals, the parked leading edge with its receivers
    seals = np.clip(mask("wall--slot_seal_front.png") + mask("wall--slot_seal_back.png"), 0, 1)
    edge = mask("wall--leaf_edge_parked.png")
    put(np.clip(edge + seals, 0, 1), np.array(p2.RUBBER) * Lr * 1.4)  # clear round 7's narrower edge first
    put(seals, np.array(p2.RUBBER) * Lr * 1.4)
    angles = mask("wall--leaf_edge_angles.png")
    recv = mask("wall--edge_receivers_parked.png")
    dt = detail(cA, edge * covered, 3.0)
    _, la, lb = p2.side_plane(d8.A_F).points()
    band = (((la - d8.T_LF) + lb) / 0.10) % 2.0 < 1.0
    alb = np.where(band[..., None], YEL, BLK)
    alb = np.where((angles > 0.5)[..., None], np.array(p2.STEEL) * 0.9, alb)
    put(edge, alb * Lr * dt[..., None])
    rim = np.clip(ndimage.grey_dilation(recv, size=(5, 5)) - recv, 0, 1) * edge
    put(rim * 0.8, np.array(p2.STEEL) * Lr * 0.75)
    put(recv, np.array(p2.DARK) * Lr * 0.8)
    rep["leaf_edge_parked"] = {"px": int((edge > 0.5).sum()), "receiver_px": int((recv > 0.5).sum())}

    # ---- the door light stays round 6's, exactly; nothing new within 2 world px of it
    lamp = np.zeros((1900, 1232), bool)
    for n in ("door_light_body", "door_light_lens", "door_light_bracket", "door_light_feed"):
        lamp |= m3(f"wall--{n}")
    lamp_d = ndimage.binary_dilation(lamp, iterations=2)
    out_srgb = to_srgb_u8(lin)
    out_srgb[lamp_d] = (wall6[lamp_d, :3] * 255).round().astype(np.uint8)
    wall[lamp_d, 3] = wall6[lamp_d, 3]
    newm = np.clip(plates + jsh + joints + lit + sa + bolts + seals + edge, 0, 1)
    near = ndimage.binary_dilation(lamp, iterations=8) & (newm > 0.01)
    rep["lamp"] = {"lamp_px_equal_round6": bool((out_srgb[lamp] == (wall6[lamp, :3] * 255).round().astype(np.uint8)).all()),
                   "new_part_px_within_2_world_px_of_lamp": int(near.sum())}
    wall[..., :3] = out_srgb / 255.0
    Image.fromarray((np.clip(wall, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, "portal-wall.png"))
    res = np.asarray(Image.open(os.path.join(OUT, "portal-wall.png")).convert("RGBA")).astype(int)
    changed = np.abs(res - (base * 255).round().astype(int)).max(-1) > 0
    rep["wall_changed_outside_new_masks_px"] = int((changed & ~ndimage.binary_dilation(newm > 0.001, iterations=1)).sum())
    # luma of liner vs the concrete beside it (layer values)
    Yl = (res[..., :3] * LUM).sum(-1)
    conc = face & ~hw & (plates < 0.01) & ~ndimage.binary_dilation(plates > 0.01, iterations=12) & (np.arange(1900)[:, None] > 400) & (np.arange(1900)[:, None] < 640)
    rep["layer_luma"] = {"liner_head_mean": round(float(Yl[mask("wall--liner_head.png") > 0.9].mean()), 1), "liner_jamb_mean": round(float(Yl[mask("wall--liner_jamb.png") > 0.9].mean()), 1),
                         "concrete_near_head_mean": round(float(Yl[conc].mean()), 1)}

    # ---- the front layer (near column): the head band carried over its approach face
    front6 = load(os.path.join(V6, "portal-front.png"))
    flin6 = from_srgb_u8((front6[..., :3] * 255).round())
    fbase = load(os.path.join(OUT, "base-front.png"))
    flin = from_srgb_u8((fbase[..., :3] * 255).round())
    front = fbase.copy()
    pier = np.asarray(Image.open(os.path.join(M6, "front--pier_face.png")).convert("L")) > 128
    fL = smooth_light(np.where(pier[..., None], flin6 / np.array(p2.CONCRETE), 0), pier, 3.0)

    def fput(m, col):
        nonlocal flin
        flin = flin * (1 - m[..., None]) + col * m[..., None]
        front[..., 3] = np.maximum(front[..., 3], m)

    nh = mask("front--near_liner_head.png")
    dt = detail(cA, nh * covered, 3.0)
    fput(nh, LINER * fL * dt[..., None])
    fput(mask("front--near_arris_top.png") * 0.9, LINER * fL * ARRIS_GAIN)
    fput(mask("front--near_shadow_above.png") * (1 - nh) * 0.55, np.array(p2.CONCRETE) * fL * 0.45)
    nb = mask("front--near_head_bolts.png")
    fput(nb, LINER * fL * 0.32)
    front[..., :3] = to_srgb_u8(flin) / 255.0
    Image.fromarray((np.clip(front, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, "portal-front.png"))

    # ---- the leaf's elevations
    LREF = 0.083 * np.array([0.92, 1.0, 1.06])
    for key, nm, size_m in (("B", "leaf-front", (d8.LEAF_L, d8.LEAF_H)), ("C", "leaf-edge", (d8.T_LB - d8.T_LF, d8.LEAF_H))):
        P = panels[key]
        bx, by = P["at"]
        w, h = P["px"]
        cp = C[by:by + h, bx:bx + w]
        W2, H2 = int(round(size_m[0] * d8.EL_PPM)), int(round(size_m[1] * d8.EL_PPM))
        cp = np.stack([np.asarray(Image.fromarray(cp[..., c].astype(np.float32), "F").resize((W2, H2), Image.Resampling.BICUBIC)) for c in range(3)], -1)
        alb = np.load(os.path.join(D, f"design-{nm}-albedo.npy"))
        whole = np.ones((H2, W2))
        if nm == "leaf-front":
            dt = detail(cp, whole, 10.0, 0.86, 1.14)
            out = alb * LREF * dt[..., None]
        else:
            rows_h = d8.LEAF_H - (np.arange(H2) + 0.5) / d8.EL_PPM
            ys = np.array([p2.scr(p2.pt(d8.A_F, min(hh, d8.H_OPEN), (d8.T_LF + d8.T_LB) / 2))[1] for hh in rows_h])
            xs = p2.scr(p2.pt(d8.A_F, 1.0, (d8.T_LF + d8.T_LB) / 2))[0]
            col_x = int((xs - 676) * 4)
            prof = Lr[:, col_x - 2:col_x + 3].mean(1)
            Lrow = np.array([prof[int(np.clip((Y - 150) * 4, 0, 1899))] for Y in ys])
            dt = detail(cp, whole, 4.0)
            em = {n: np.asarray(Image.open(os.path.join(D, "masks", f"leaf-edge--{n}.png")).convert("L")).astype(float) / 255.0 > 0.5
                  for n in ("edge_stripes", "edge_angles", "edge_receivers", "edge_receiver_rims", "edge_seal", "edge_sweep")}
            s = (np.arange(W2) + 0.5) / d8.EL_PPM
            bandE = (((s[None, :] + rows_h[:, None]) / 0.10) % 2.0) < 1.0
            albE = np.where(bandE[..., None], YEL, BLK)
            albE[em["edge_angles"]] = np.array(p2.STEEL) * 0.9
            albE[em["edge_receiver_rims"]] = np.array(p2.STEEL) * 0.75
            albE[em["edge_receivers"]] = np.array(p2.DARK)
            albE[em["edge_seal"] | em["edge_sweep"]] = np.array(p2.RUBBER)
            out = albE * Lrow[:, None, :] * dt[..., None]
        rgba = np.dstack([to_srgb_u8(out), np.full((H2, W2), 255, np.uint8)])
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, f"{nm}.png"))
        rep[nm] = {"size": [W2, H2], "mean_luma": round(float((to_srgb_u8(out).astype(float) * LUM).sum(-1).mean()), 1)}
    for f in ("portal-curtain.png", "portal-curtain-open.png", "portal-frame.png", "bypass-wheel.png", "lens.png"):
        shutil.copy(os.path.join(V6, f), os.path.join(OUT, f))
    for f in ("corridor-far.png", "corridor-mid.png"):
        shutil.copy(os.path.join(V6, "game", f), os.path.join(OUT, f))
    json.dump(rep, open(os.path.join(OUT, "report8.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
