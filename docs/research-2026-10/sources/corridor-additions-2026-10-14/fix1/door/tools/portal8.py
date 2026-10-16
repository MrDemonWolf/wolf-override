"""Round 8 (add7 fix round 1, track DOOR) construction design of the corridor's door end.

Round 7's model (add7/door/tools/portal7.py and round 6's stack under it, all imported read-only)
with the fixes the two round-7 reviews asked for:

  (a) blast frame      a continuous steel LINER round the head and the visible far jamb, lighter and
                       cooler than the concrete, 40 mm proud: head band from the opening (3.05 m) to
                       3.80 m (it shows 0.30 m above the hood), jamb strip 0.55 m wide on the face.
                       Plate joints at no more than 1.25 m (head: a = -1.0, 0.2, 1.4 m; jamb:
                       h = 1.3, 2.6 m). A 1-px lit top arris (it faces the door light) and a lit
                       outer arris (it faces the corridor luminaire), a 1-px shadow under the upper
                       plate at every joint, dark M24 anchor heads with one highlight each at 0.30 m.
                       The plates stop 0.12 m under the door light: its bracket, body and lens are
                       round 6's pixels, untouched (cleanup8 keeps them on top).
  (c) inner blast leaf 0.36 m thick (was 0.24) in a 0.40 m slot (t 0.14 .. 0.54; the wall is 0.66 m);
                       front face 10 mm faceplates welded in 1.0 m courses (horizontal weld seams at
                       1.0 and 2.0 m) and 1.3 m sheets (vertical seams), a 0.10 m leading-edge
                       channel with a 1-2 px lit arris and a 25 mm rubber seal down its nose, two
                       bogie housings 0.30 m tall x 0.60 m sitting on the rail at the foot (lit top,
                       bolted cover), a rubber sweep along the foot, three locking-bolt receivers on
                       the leading edge (h 0.55, 1.55, 2.55 m), and a feathered contact shadow strip
                       on the threshold in front of its foot (drawn by BlastLeaf from a black atlas
                       patch with vertex alpha).

Everything else (sign, strap, rail, wiper seals, the leaf's motion and pocket) is round 7's.
Writes add7/fix1/door/design/ (masks per part, design layers, leaf elevations, spec.json).
"""
from __future__ import annotations

import json
import os
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

R7T = "scratchpad/real-slice/add7/door/tools"
sys.path.insert(0, R7T)
from stack import common, p2, p3, p6  # noqa: E402
from common import save_mask, to_srgb_u8, write_json  # noqa: E402
import portal7 as d7  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "design"))
CVD = p3.CVD
A_F, A_N, A_E = d7.A_F, d7.A_N, d7.A_E
H_OPEN = p2.H_OPEN

# ---------------------------------------------------------------- (a) the liner
BF_T = -0.040            # 40 mm plate
BF_TOP = 3.80            # 0.30 m above the hood's top (3.5 m); door light bracket at 3.98 m
BF_JAMB_W = 0.55
BF_A1 = A_F + BF_JAMB_W
JAMB_SEAMS = (1.30, 2.60, H_OPEN)
HEAD_SEAMS = (-1.0, 0.2, 1.4)
ARRIS = 0.028            # lit arris band (about 1 px at 1280x720)
BOLT_R = 0.024
BOLT_PITCH = 0.30

# ---------------------------------------------------------------- (c) the leaf (overrides round 7's)
T_LF, T_LB = 0.16, 0.52
T_S0, T_S1 = 0.14, 0.54
LEAF_L, LEAF_H = d7.LEAF_L, d7.LEAF_H
EL_PPM = d7.EL_PPM
EDGE_ANGLE = 0.05
NOSE = 0.10
NOSE_SEAL = 0.025
COURSES = (1.0, 2.0)
SHEETS = (1.30, 2.60)
BOGIES = ((0.30, 0.90), (2.90, 3.50))
BOGIE_H = (0.02, 0.32)
RECEIVERS = (0.55, 1.55, 2.55)
RECEIVER_H = 0.14
SHADOW_DEPTH = 0.14      # the contact shadow strip's reach in front of the foot (m)

# round 7's functions read these module globals: point them at round 8's leaf
for k, v in dict(T_LF=T_LF, T_LB=T_LB, T_S0=T_S0, T_S1=T_S1, BF_T=BF_T, BF_TOP=BF_TOP).items():
    setattr(d7, k, v)


def bolt(a, h, t):
    return p2.quad_face(a - BOLT_R, a + BOLT_R, h - BOLT_R, h + BOLT_R, t)


def liner_parts(layer, a0, a1, with_jamb):
    """The liner's parts on the face between a0 and a1 (the wall piece, or the near column)."""
    P, Part, qf = [], p2.Part, p2.quad_face
    fp = p2.face_plane(BF_T)
    pre = "" if layer == "wall" else "near_"
    P.append(Part(layer, f"{pre}liner_head", [qf(a0, a1, H_OPEN, BF_TOP, BF_T)], p2.GUNSHIP, fp,
                  "steel liner head band, 40 mm plate, 3.05 to 3.80 m", "the blast frame's head, anchored to the embedded subframe"))
    if with_jamb:
        P.append(Part(layer, "liner_jamb", [qf(A_F, BF_A1, 0.0, H_OPEN, BF_T)], p2.GUNSHIP, fp,
                      "steel liner jamb strip, 40 mm plate, 0.55 m wide, 0 to 3.05 m", "the blast frame's far jamb"))
        for i, h in enumerate(JAMB_SEAMS):
            P.append(Part(layer, f"jamb_joint{i}", [qf(A_F, BF_A1, h - 0.012, h + 0.012, BF_T - 0.001)], p2.DARK, p2.face_plane(BF_T - 0.001),
                          "plate joint", "joint between two liner plates"))
            # the upper plate's lower edge throws a 1-px shadow on the plate below
            P.append(Part(layer, f"jamb_joint_shadow{i}", [qf(A_F, BF_A1, h - 0.045, h - 0.012, BF_T - 0.001)], p2.DARK, p2.face_plane(BF_T - 0.001),
                          "shadow under the joint", "the plate above stands proud of the one below"))
        P.append(Part(layer, "arris_outer", [qf(BF_A1 - ARRIS, BF_A1, 0.0, BF_TOP, BF_T - 0.001)], p2.STEEL_WORN, p2.face_plane(BF_T - 0.001),
                      "lit outer arris", "the plate's 40 mm edge faces the corridor luminaire"))
        bolts = [bolt(BF_A1 - 0.08, float(h), BF_T - 0.012) for h in np.arange(0.18, H_OPEN - 0.05, BOLT_PITCH)]
        P.append(Part(layer, "jamb_bolts", bolts, p2.DARK, p2.face_plane(BF_T - 0.012), "M24 anchor heads, 300 mm pitch", "anchor the jamb liner"))
    for i, a in enumerate(HEAD_SEAMS):
        if a0 < a < a1:
            P.append(Part(layer, f"{pre}head_joint{i}", [qf(a - 0.012, a + 0.012, H_OPEN, BF_TOP, BF_T - 0.001)], p2.DARK, p2.face_plane(BF_T - 0.001),
                          "plate joint", "joint between two liner plates"))
            P.append(Part(layer, f"{pre}head_joint_lit{i}", [qf(a + 0.012, a + 0.012 + ARRIS, H_OPEN, BF_TOP, BF_T - 0.001)], p2.STEEL_WORN, p2.face_plane(BF_T - 0.001),
                          "lit plate edge", "the next plate's edge catches the corridor light"))
    P.append(Part(layer, f"{pre}arris_top", [qf(a0, a1, BF_TOP - ARRIS, BF_TOP, BF_T - 0.001)], p2.STEEL_WORN, p2.face_plane(BF_T - 0.001),
                  "lit top arris", "the plate's 40 mm top edge faces the door light"))
    P.append(Part(layer, f"{pre}shadow_above", [qf(a0, a1 if with_jamb else a1, BF_TOP, BF_TOP + 0.03, 0.0)], p2.DARK, p2.face_plane(0.0),
                  "shadow line on the concrete over the plate", "the plate's top edge stands 40 mm proud (light from above: a hairline only)"))
    hb = [bolt(float(a), BF_TOP - 0.09, BF_T - 0.012) for a in np.arange(a0 + 0.10, a1 - 0.05, BOLT_PITCH)]
    P.append(Part(layer, f"{pre}head_bolts", hb, p2.DARK, p2.face_plane(BF_T - 0.012), "M24 anchor heads, 300 mm pitch", "anchor the head liner"))
    return P


def wall_parts8() -> list:
    P = liner_parts("wall", A_N, BF_A1, True)
    keep = ("sign_plate", "sign_bolts", "slot_seal_front", "slot_seal_back", "leaf_edge_parked", "rail_recess", "rail_head")
    P += [p for p in d7.wall_add_parts() if p.name in keep]
    # the leaf's locking-bolt receivers on the parked leading edge (side plane at A_F)
    sp = p2.side_plane(A_F)
    tm = (T_LF + T_LB) / 2
    rec = [p2.quad_side(A_F, tm - 0.07, tm + 0.07, h - RECEIVER_H / 2, h + RECEIVER_H / 2) for h in RECEIVERS]
    P.append(p2.Part("wall", "edge_receivers_parked", rec, p2.DARK, sp, "locking-bolt receivers 140 x 140 mm", "the jamb's locking bolts engage them when the leaf is shut"))
    return P


def front_parts8() -> list:
    P = liner_parts("front", A_E, A_N, False)
    P += [p for p in d7.front_add_parts() if p.name == "lamp_conduit_strap2"]
    return P


def leaf_front_elevation():
    W, H = int(round(LEAF_L * EL_PPM)), int(round(LEAF_H * EL_PPM))
    alb = np.zeros((H, W, 3))
    masks = {}

    def rect(name, u0, u1, h0, h1, col):
        m = np.zeros((H, W))
        x0, x1 = int(round(u0 * EL_PPM)), int(round(u1 * EL_PPM))
        y0, y1 = int(round((LEAF_H - h1) * EL_PPM)), int(round((LEAF_H - h0) * EL_PPM))
        m[max(y0, 0):min(y1, H), max(x0, 0):min(x1, W)] = 1.0
        alb[m > 0] = col
        masks[name] = np.maximum(masks.get(name, np.zeros((H, W))), m)

    FACE = (0.265, 0.27, 0.29)    # dark grey faceplate, lifted so the face reads luma 30-34 in the doorway (review)
    rect("leaf_face", 0.0, LEAF_L, 0.0, LEAF_H, FACE)
    rect("leaf_nose", 0.0, NOSE, 0.0, LEAF_H, p2.STEEL)
    rect("nose_arris", NOSE - 0.03, NOSE, 0.0, LEAF_H, p2.STEEL_WORN)      # lit arris where the channel meets the face
    rect("nose_seal", 0.0, NOSE_SEAL, 0.0, LEAF_H, p2.RUBBER)               # rubber seal down the nose
    for i, u in enumerate(SHEETS):
        rect(f"sheet_seam{i}", u - 0.012, u + 0.012, BOGIE_H[1], LEAF_H, p2.DARK)
    for i, h in enumerate(COURSES):
        rect(f"course_seam{i}", NOSE, LEAF_L, h - 0.012, h + 0.012, p2.DARK)          # weld groove
        rect(f"course_bead{i}", NOSE, LEAF_L, h + 0.012, h + 0.030, p2.STEEL)         # weld bead catching light
        rect(f"course_shadow{i}", NOSE, LEAF_L, h - 0.040, h - 0.012, (0.10, 0.10, 0.115))
    rect("bottom_rail", 0.0, LEAF_L, 0.0, BOGIE_H[1] + 0.04, (0.12, 0.125, 0.14))
    for i, (u0, u1) in enumerate(BOGIES):
        rect(f"bogie{i}", u0, u1, BOGIE_H[0], BOGIE_H[1], p2.GUNSHIP)
        rect(f"bogie_top{i}", u0, u1, BOGIE_H[1] - 0.03, BOGIE_H[1], p2.STEEL_WORN)
        rect(f"bogie_side{i}", u1 - 0.035, u1, BOGIE_H[0], BOGIE_H[1] - 0.03, (0.07, 0.075, 0.085))
        for j, uu in enumerate(np.linspace(u0 + 0.07, u1 - 0.09, 4)):
            for hh in (BOGIE_H[0] + 0.07, BOGIE_H[1] - 0.09):
                rect(f"bogie_bolts{i}", uu - 0.018, uu + 0.018, hh - 0.018, hh + 0.018, p2.DARK)
    rect("sweep", 0.0, LEAF_L, 0.0, 0.025, p2.RUBBER)
    return alb, masks


def leaf_edge_elevation():
    Wd = T_LB - T_LF
    W, H = int(round(Wd * EL_PPM)), int(round(LEAF_H * EL_PPM))
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    s = (xx + 0.5) / EL_PPM
    h = LEAF_H - (yy + 0.5) / EL_PPM
    band = ((s + h) / 0.10) % 2.0 < 1.0
    alb = np.where(band[..., None], np.array(p2.YELLOW), np.array(p2.BLACK))
    angles = (s < EDGE_ANGLE) | (s > Wd - EDGE_ANGLE)
    alb[angles] = p2.STEEL
    seal = s < NOSE_SEAL * 0.6
    alb[seal] = p2.RUBBER
    rec = np.zeros_like(s, bool)
    rim = np.zeros_like(s, bool)
    for hc in RECEIVERS:
        inner = (np.abs(s - Wd / 2) < 0.07) & (np.abs(h - hc) < RECEIVER_H / 2)
        outer = (np.abs(s - Wd / 2) < 0.095) & (np.abs(h - hc) < RECEIVER_H / 2 + 0.025)
        rim |= outer & ~inner
        rec |= inner
    alb[rim] = p2.STEEL_WORN
    alb[rec] = p2.DARK
    sweep = h < 0.025
    alb[sweep] = p2.RUBBER
    return alb, {"edge_stripes": (~angles & ~sweep & ~rec & ~rim & ~seal).astype(float), "edge_angles": angles.astype(float),
                 "edge_receivers": rec.astype(float), "edge_receiver_rims": rim.astype(float), "edge_seal": seal.astype(float), "edge_sweep": sweep.astype(float)}


def screen_of(a, h, t):
    return [round(float(v), 2) for v in p2.scr(p2.pt(a, h, t))]


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    wall = p2.render(wall_parts8(), CVD)["wall"]
    front = p2.render(front_parts8(), CVD)["front"]
    # the parked edge's stripes and angles in the reveal plane (as round 7, at round 8's thickness)
    _, la, lb = p2.side_plane(A_F).points()
    stripe = (((la - T_LF) + lb) / 0.10) % 2.0 < 1.0
    em = wall["masks"]["leaf_edge_parked"]
    angles = ((la - T_LF) < EDGE_ANGLE) | ((T_LB - la) < EDGE_ANGLE)
    wall["masks"]["leaf_edge_stripes"] = em * (~angles) * stripe * (1 - wall["masks"]["edge_receivers_parked"])
    wall["masks"]["leaf_edge_angles"] = em * angles
    txt, tinfo = d7.sign_text_mask()
    wall["masks"]["TEXT-sign"] = txt * wall["masks"]["sign_plate"] * (1 - wall["masks"]["sign_bolts"])
    for name, lay in (("wall", wall), ("front", front)):
        rgba = np.dstack([to_srgb_u8(lay["lin"]), (np.clip(lay["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, f"design-add-{name}.png"))
        for n, m in lay["masks"].items():
            save_mask(m, os.path.join(OUT, "masks", f"{name}--{n}.png"))
    fa, fm = leaf_front_elevation()
    ea, emk = leaf_edge_elevation()
    LREF = 0.083 * np.array([0.92, 1.0, 1.06])
    for nm, alb, mm in (("leaf-front", fa, fm), ("leaf-edge", ea, emk)):
        Image.fromarray(to_srgb_u8(alb * LREF), "RGB").save(os.path.join(OUT, f"design-{nm}-albedo.png"))
        np.save(os.path.join(OUT, f"design-{nm}-albedo.npy"), alb)
        for n, m in mm.items():
            save_mask(m, os.path.join(OUT, "masks", f"{nm}--{n}.png"))
    # light table on the leaf's new front plane (round 7's model, t = 0.16)
    a_cols = np.round(np.linspace(d7.A_LEAD_OPEN, d7.A_LEAD_SHUT, 9), 4)
    h_rows = np.array([0.0, 0.4, 0.8, 1.2, 1.6, 2.0, 2.4, 2.75, H_OPEN])
    AG, HG = np.meshgrid(a_cols, h_rows, indexing="ij")
    Lf = d7.leaf_front_light(AG, HG)
    lum = (Lf * np.array([0.2126, 0.7152, 0.0722])).sum(-1)
    ref = lum.max()
    alb_mid = 0.16
    fac = (to_srgb_u8(np.array([alb_mid * lum])).astype(float) + 0.5) / (to_srgb_u8(np.array([alb_mid * ref])).astype(float) + 0.5)
    fac = np.clip(fac[0], 0.2, 1.0)
    spec = {
        "units": "metres, round 7's frame (a along the face from world (752, 440) toward the back wall, t into the wall, h up)",
        "liner": {"plate_t": BF_T, "top_h": BF_TOP, "head_a": [round(A_E, 4), round(BF_A1, 4)], "jamb_a": [round(A_F, 4), round(BF_A1, 4)],
                  "joints": {"head_a": HEAD_SEAMS, "jamb_h": JAMB_SEAMS}, "bolts": "M24 anchor heads, dark, one highlight, 300 mm pitch",
                  "screen": {"head_top_near": screen_of(A_E, BF_TOP, BF_T), "head_top_far": screen_of(BF_A1, BF_TOP, BF_T),
                             "jamb_outer_foot": screen_of(BF_A1, 0, BF_T), "door_light": screen_of(-0.05, 4.05, -0.34)}},
        "leaf": {"thickness_m": round(T_LB - T_LF, 3), "front_t": T_LF, "back_t": T_LB, "slot_t": [T_S0, T_S1], "length_m": LEAF_L, "height_m": LEAF_H,
                 "a_lead_shut": round(d7.A_LEAD_SHUT, 5), "a_lead_open": round(d7.A_LEAD_OPEN, 5), "travel_m": round(d7.TRAVEL_M, 5),
                 "courses_h": COURSES, "sheets_u": SHEETS, "bogies_u": BOGIES, "bogie_h": BOGIE_H, "receivers_h": RECEIVERS, "shadow_depth_m": SHADOW_DEPTH,
                 "screen": {"mouth_foot": screen_of(A_F, 0, T_LF), "mouth_head": screen_of(A_F, H_OPEN, T_LF),
                            "edge_parked_foot": [screen_of(A_F, 0, t) for t in (T_LF, T_LB)], "receiver_foot": screen_of(d7.A_LEAD_SHUT, 0, T_LF)},
                 "light_table": {"a_cols": a_cols.tolist(), "h_rows": h_rows.tolist(), "vertex_colour": np.round(fac, 3).tolist()}},
        "parts": {"wall": [{"name": p.name, "dims": p.dims, "job": p.job} for p in wall_parts8()],
                  "front": [{"name": p.name, "dims": p.dims, "job": p.job} for p in front_parts8()]},
        "sign_text_info": tinfo,
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print(json.dumps({k: v for k, v in spec["leaf"].items() if k != "light_table"}, indent=1))
    print(json.dumps(spec["liner"], indent=1))
    print("light table\n", np.round(fac, 3))


if __name__ == "__main__":
    main()
