"""Round 11 (add7 fix round 4) construction design: the steel blast frame's side jambs as heavy bolted
armour plates (human review r4, should-fix 6: "the side jambs read as thin steel channels, not heavy
armour plates ... give the jambs a wider plate face with a visible bolt row, without adding draw
calls"). Everything is drawn in the round-10 atlas's own regions (wall: world 684,150 at 2 px per
world px; column: world 785,150 at 2 px), so no region, position, node or draw call changes.

  far jamb   round 7's 0.55 m armour plate on the far column's face (A_F .. A_F + 0.55, 0 .. 3.92 m)
             widens to 0.85 m (to 0.20 m short of the corner with the corridor's back wall, where the
             bypass chain guard runs), 25 mm steel painted 36118 like the head plate, the same plate
             joints (1.30 and 2.60 m), and TWO rows of M30 anchor bolts with 90 mm square plate washers
             at 300 mm pitch (round 7 had one row of M24 heads, 1-2 px at 1x).
  near jamb  the near column's end face (the wall end toward the camera) gets the matching jamb plate:
             25 mm bare galvanised steel (the column's own armour: its chamfer plate and arris angle
             are bare steel) 0.20 m wide from the arris, wrapping round the old 65 mm arris angle, from
             the cut wall's top (0.36 m, Nathanial's clean cutaway) to the head plate's top (3.92 m),
             joints at 1.30 and 2.60 m, one row of M30 bolts with plate washers at 300 mm pitch. The
             status lamp, the push-button station and the conduit stay on top of it, untouched.

Real basis: a blast door's frame is a steel subframe cast into the concrete opening, its jamb and head
plates anchored through into the wall so blast and rebound loads go into the structure (DoD UFC 3-340-02
"Structures to resist the effects of accidental explosions", ch. 6 blast doors and frames; blast-door
makers' frame details); exposed wall ends at vehicle and cart routes are armoured with steel plate and
angles. Bolt rows at about 300 mm are the usual anchor pitch for such plates.

Writes add7/fix4/door/design/: masks (atlas-region coordinates), design-wall.png and design-column.png
(the two regions with the new parts drawn flat at their albedo times the light the round-10 art
already carries there), spec.json.
"""
from __future__ import annotations

import json
import os
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image
from scipy import ndimage

R = "scratchpad/real-slice"
sys.path.insert(0, os.path.join(R, "add7", "door", "tools"))
from stack import common, p2, p4, p6  # noqa: E402  (round 6's stack, read only)
import portal7 as d7  # noqa: E402  (round 7's additions, read only)
from common import Canvas, to_srgb_u8, from_srgb_u8, save_mask  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "design"))
ATLAS10 = os.path.join(R, "add7", "fix3", "door", "game", "corridor-seal-atlas.png")
REG = json.load(open(os.path.join(R, "add7", "fix3", "door", "game", "atlas-regions.json")))["atlas"]
LUM = np.array([0.2126, 0.7152, 0.0722])

# the two regions as canvases (world -> atlas-region px)
W = REG["wall"]
C = REG["column"]
CW = Canvas("wall11", W["world_top_left"][0], W["world_top_left"][1], 2.0, W["region"][2], W["region"][3])
CC = Canvas("col11", C["world_top_left"][0], C["world_top_left"][1], 2.0, C["region"][2], C["region"][3])

# ---------------------------------------------------------------- dimensions (metres)
A_F, A_N, A_BACK, A_E = p2.A_F, p2.A_N, p2.A_BACK, p4.A_END4
BF_T, BF_TOP = d7.BF_T, d7.BF_TOP
FAR_W = 0.85                      # far jamb plate width along the face (round 7: 0.55)
FAR_A1 = A_F + FAR_W
SEAMS = (1.30, 2.60)              # plate joints, as round 7's
SEAM_HALF = 0.006                 # 12 mm joint
PITCH = 0.30
FAR_ROWS = (A_F + 0.20, FAR_A1 - 0.09)   # two bolt rows on the far plate (the guide hides the first 0.12 m)
NEAR_T1 = 0.20                    # near plate width across the end face from the arris
NEAR_ROW_T = 0.095                # its bolt row
NEAR_H0 = 0.36                    # stands on the cut wall's top (the clean cutaway)
NEAR_A = A_E - 0.025              # its face, 25 mm proud of the end face
WASHER = 0.045                    # half of a 90 mm square plate washer
HEAD = 0.026                      # half of an M30 head (46 mm across flats, drawn round)
BOLT_H = [round(h, 3) for h in np.arange(0.24, BF_TOP - 0.08, PITCH)]


def keep_clear(h, lo=0.0):
    """A bolt is not set on a plate joint (it would straddle two plates)."""
    return h >= lo and all(abs(h - s) > 0.09 for s in SEAMS)


def far_parts():
    """The wider jamb plate. Over the opening's height (H_OPEN up) round 7's head plate already covers
    A_F .. A_F + 0.55 with its own top bolt row, so that corner keeps round 10's pixels; the new strip
    beside it carries the head's top row on at the head's own pitch."""
    plate = [p2.quad_face(A_F, FAR_A1, 0.0, d7.H_OPEN, BF_T), p2.quad_face(d7.BF_A1, FAR_A1, d7.H_OPEN - 0.01, BF_TOP, BF_T)]
    seams = [p2.quad_face(A_F, FAR_A1, s - SEAM_HALF, s + SEAM_HALF, BF_T - 0.001) for s in SEAMS]
    washers, heads, centres = [], [], []
    rows = [(a, h) for a in FAR_ROWS for h in BOLT_H if keep_clear(h) and (a > d7.BF_A1 or h < d7.H_OPEN - 0.06)]
    a = A_N + 0.08
    while a <= FAR_A1 - 0.02:
        if a > d7.BF_A1 + 0.03:
            rows.append((round(a, 4), BF_TOP - 0.08))
        a += d7.BOLT_PITCH
    for a, h in rows:
        if True:
            washers.append(p2.quad_face(a - WASHER, a + WASHER, h - WASHER, h + WASHER, BF_T - 0.008))
            c = p2.scr(p2.pt(a, h, BF_T - 0.02))
            # the head is a short cylinder on the turned face: an ellipse foreshortened like the face
            e0 = p2.scr(p2.pt(a - HEAD, h, BF_T - 0.02))
            e1 = p2.scr(p2.pt(a + HEAD, h, BF_T - 0.02))
            rx = abs(e1[0] - e0[0]) / 2
            heads.append(("ellipse", c[0], c[1], max(rx, 0.45), HEAD * p2.PX_PER_M))
            centres.append([round(a, 3), h, round(c[0], 3), round(c[1], 3)])
    return {"far_plate": plate, "far_seams": seams, "far_washers": washers, "far_heads": heads}, centres


def near_parts():
    plate = [p2.quad_side(NEAR_A, 0.0, NEAR_T1, NEAR_H0, BF_TOP)]
    seams = [p2.quad_side(NEAR_A - 0.001, 0.0, NEAR_T1, s - SEAM_HALF, s + SEAM_HALF) for s in SEAMS]
    # the plate's 25 mm edge along t = NEAR_T1 throws a thin shadow on the end face's concrete (light
    # from the corridor's lamps, in front and to the left)
    edge_shadow = [p2.quad_side(A_E, NEAR_T1, NEAR_T1 + 0.03, NEAR_H0, BF_TOP)]
    washers, heads, centres = [], [], []
    for h in BOLT_H:
        if not keep_clear(h, NEAR_H0 + 0.12):
            continue
        # not under the push-button station's backplate (1.42-1.80 m) or the lamp body (2.48-2.79 m)
        if 1.36 <= h <= 1.86 or 2.42 <= h <= 2.85:
            continue
        washers.append(p2.quad_side(NEAR_A - 0.008, NEAR_ROW_T - WASHER, NEAR_ROW_T + WASHER, h - WASHER, h + WASHER))
        c = p2.scr(p2.pt(NEAR_A - 0.02, h, NEAR_ROW_T))
        e0 = p2.scr(p2.pt(NEAR_A - 0.02, h, NEAR_ROW_T - HEAD))
        e1 = p2.scr(p2.pt(NEAR_A - 0.02, h, NEAR_ROW_T + HEAD))
        heads.append(("ellipse", c[0], c[1], abs(e1[0] - e0[0]) / 2, HEAD * p2.PX_PER_M))
        centres.append([NEAR_ROW_T, h, round(c[0], 3), round(c[1], 3)])
    return {"near_plate": plate, "near_seams": seams, "near_washers": washers, "near_heads": heads, "near_edge_shadow": edge_shadow}, centres


def hardware_mask():
    """Everything round 6 mounted on the end face (lamp, station, conduits, straps, camera), which
    stays on top of the new plate."""
    keep = ("lamp_base", "lamp_conduit", "lamp_conduit_up", "lamp_cap", "lamp_guard0", "lamp_guard1", "lamp_guard2",
            "pb_backplate", "pb_box", "pb_hinge", "pb_lock", "pb_button0", "pb_button1", "pb_button2", "pb_conduit",
            "lamp_conduit_elbow", "lamp_conduit_run", "lamp_conduit_strap", "cam_plate", "cam_arm")
    m = np.zeros((CC.h, CC.w))
    for part in p6.front_parts_v6():
        if part.name in keep:
            m = np.maximum(m, p2.mask_of(part.polys, CC))
    for part in d7.front_add_parts():
        if part.name.startswith("lamp_conduit_strap"):
            m = np.maximum(m, p2.mask_of(part.polys, CC))
    # the lamp's globe hole (the live lens draws there) and a 1 px margin round every part
    lcx, lcy = p2.scr(p2.pt(A_E - 0.12, p4.LAMP_H, p4.T_END / 2))
    m = np.maximum(m, p2.mask_of([("ellipse", lcx, lcy, 2.6, 3.1)], CC))
    return ndimage.binary_dilation(m > 0.15, iterations=1)


def light_field(lin, surf, sigma):
    """Normalised smoothing of a light estimate over the pixels in surf (rows, cols sigma)."""
    w = surf.astype(float)
    den = np.maximum(ndimage.gaussian_filter(w, sigma), 1e-6)
    return np.stack([ndimage.gaussian_filter(lin[..., c] * w, sigma) / den for c in range(3)], -1)


def main():
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    atlas = np.asarray(Image.open(ATLAS10).convert("RGBA")).astype(float)
    wx, wy, ww, wh = W["region"]
    cx, cy, cw, ch = C["region"]
    wall = atlas[wy:wy + wh, wx:wx + ww] / 255.0
    col = atlas[cy:cy + ch, cx:cx + cw] / 255.0
    spec = {"round": 11, "units": "metres; masks in atlas-region px (2 per world px)", "far": {}, "near": {}}

    # ---------------------------------------------------------------- far jamb (wall region)
    fparts, fcent = far_parts()
    fm = {k: p2.mask_of(v, CW) for k, v in fparts.items()}
    # round 7's plate, seams and bolts (to read the light under them)
    old = {p.name: p2.mask_of(p.polys, CW) for p in d7.wall_add_parts() if p.name.startswith("bf_")}
    old_plate = old["bf_jamb_plate"]
    old_marks = ndimage.binary_dilation((old["bf_bolts"] + old["bf_jamb_seam0"] + old["bf_jamb_seam1"]) > 0.1, iterations=2)
    face = p2.mask_of([p2.quad_face(A_F, A_BACK, 0.0, BF_TOP + 0.3, 0.0)], CW)
    lin = from_srgb_u8((wall[..., :3] * 255).round())
    opaque = wall[..., 3] > 0.99
    conc = (face > 0.99) & (old_plate < 0.01) & opaque
    onplate = (old_plate > 0.99) & ~old_marks & opaque
    est = np.where(conc[..., None], lin / np.array(p2.CONCRETE), 0.0) + np.where(onplate[..., None], lin / (np.array(p2.GUNSHIP) * 0.92), 0.0)
    Lf = light_field(est, conc | onplate, (10.0, 3.0))
    spec["far"] = {"plate_a": [round(A_F, 4), round(FAR_A1, 4)], "width_m": FAR_W, "round7_width_m": d7.BF_JAMB_W, "h": [0.0, BF_TOP], "t": BF_T,
                   "seams_h": SEAMS, "bolt_rows_a": [round(a, 4) for a in FAR_ROWS], "bolts": len(fcent), "bolt_centres_a_h_worldxy": fcent, "pitch_m": PITCH,
                   "washer_m": 2 * WASHER, "head_m": 2 * HEAD, "paint": "36118 Gunship Gray, as the head plate",
                   "screen_x_at_2m_world": [round(p2.scr(p2.pt(FAR_A1, 2.0, BF_T))[0], 2), round(p2.scr(p2.pt(A_F, 2.0, BF_T))[0], 2)],
                   "corner_x_at_2m_world": round(p2.scr(p2.pt(A_BACK, 2.0, 0.0))[0], 2)}

    # ---------------------------------------------------------------- near jamb (column region)
    nparts, ncent = near_parts()
    nm = {k: p2.mask_of(v, CC) for k, v in nparts.items()}
    hw = hardware_mask()
    clin = from_srgb_u8((col[..., :3] * 255).round())
    copaque = col[..., 3] > 0.99
    endf = p2.mask_of([p2.quad_side(A_E, 0.065, p4.T_END - 0.05, NEAR_H0, BF_TOP + 0.4)], CC)
    arris = p2.mask_of([p2.quad_side(A_E, 0.0, 0.065, NEAR_H0, BF_TOP + 0.4)], CC)
    cc = (endf > 0.99) & ~hw & copaque
    ca = (arris > 0.99) & ~hw & copaque
    est = np.where(cc[..., None], clin / np.array(p2.CONCRETE), 0.0) + np.where(ca[..., None], clin / np.array(p2.STEEL), 0.0)
    Ln = light_field(est, cc | ca, (12.0, 4.0))
    spec["near"] = {"plane_a": round(NEAR_A, 4), "t": [0.0, NEAR_T1], "h": [NEAR_H0, BF_TOP], "seams_h": SEAMS, "bolt_row_t": NEAR_ROW_T,
                    "bolts": len(ncent), "bolt_h": [c[1] for c in ncent], "bolt_centres_t_h_worldxy": ncent, "pitch_m": PITCH, "material": "bare galvanised steel, as the column's chamfer plate and arris angle",
                    "kept_on_top": "status lamp (body, cap, guard, globe hole), push-button station (backplate, box, hinge, lock, buttons), conduits and straps",
                    "screen_x_at_2m_world": [round(p2.scr(p2.pt(NEAR_A, 2.0, 0.0))[0], 2), round(p2.scr(p2.pt(NEAR_A, 2.0, NEAR_T1))[0], 2)]}

    # ---------------------------------------------------------------- the flat design (albedo x light)
    GUN = np.array(p2.GUNSHIP) * 0.92
    GALV = np.array(p2.STEEL) * 0.80          # weathered galvanising, dull
    WASH = np.array(p2.STEEL) * 0.95
    HEADC = np.array(p2.STEEL_WORN) * 0.85
    dw = lin.copy()
    da = wall[..., 3].copy()
    vis_w = opaque | (wall[..., 3] > 0.0)

    def put(arr, alpha, m, colr):
        m3 = m[..., None]
        arr[:] = arr * (1 - m3) + colr * m3
        alpha[:] = np.maximum(alpha, m)

    put(dw, da, fm["far_plate"], GUN * Lf)
    put(dw, da, np.clip(fm["far_seams"] * fm["far_plate"], 0, 1) * 0.9, GUN * Lf * 0.35)
    put(dw, da, fm["far_washers"], WASH * Lf)
    put(dw, da, fm["far_heads"], HEADC * Lf)
    dc = clin.copy()
    dca = col[..., 3].copy()
    npl = nm["near_plate"] * (~hw) * copaque
    nsh = nm["near_edge_shadow"] * (1 - nm["near_plate"]) * (~hw) * copaque
    put(dc, dca, npl, GALV * Ln)
    put(dc, dca, np.clip(nm["near_seams"] * npl, 0, 1) * 0.9, GALV * Ln * 0.35)
    put(dc, dca, nsh * 0.55, np.array(p2.CONCRETE) * Ln * 0.45)
    put(dc, dca, nm["near_washers"] * (~hw), WASH * Ln)
    put(dc, dca, nm["near_heads"] * (~hw), HEADC * Ln)
    dca = col[..., 3]  # the column's alpha never changes
    da = wall[..., 3]
    for name, arr, a in (("design-wall.png", dw, da), ("design-column.png", dc, dca)):
        Image.fromarray(np.dstack([to_srgb_u8(arr), (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)]), "RGBA").save(os.path.join(OUT, name))
    for k, m in fm.items():
        save_mask(m, os.path.join(OUT, "masks", f"wall--{k}.png"))
    for k, m in nm.items():
        save_mask(m, os.path.join(OUT, "masks", f"column--{k}.png"))
    save_mask(hw.astype(float), os.path.join(OUT, "masks", "column--KEEP_hardware.png"))
    np.save(os.path.join(OUT, "light-far.npy"), Lf)
    np.save(os.path.join(OUT, "light-near.npy"), Ln)
    spec["light"] = {"far_plate_mean_luma_design": round(float((to_srgb_u8(dw).astype(float) * LUM).sum(-1)[fm["far_plate"] > 0.99].mean()), 1),
                     "near_plate_mean_luma_design": round(float((to_srgb_u8(dc).astype(float) * LUM).sum(-1)[npl > 0.99].mean()), 1),
                     "near_end_face_concrete_mean_luma": round(float((to_srgb_u8(clin).astype(float) * LUM).sum(-1)[cc].mean()), 1),
                     "far_face_concrete_mean_luma": round(float((to_srgb_u8(lin).astype(float) * LUM).sum(-1)[conc].mean()), 1)}
    json.dump(spec, open(os.path.join(OUT, "spec.json"), "w"), indent=1)
    print(json.dumps(spec, indent=1))


if __name__ == "__main__":
    main()
