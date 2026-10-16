"""Round 7 (add7, track DOOR) construction design of the corridor's door end: round 6's model
(design/tools/portal6.py and the stack under it, imported read-only) with Nathanial's additions of
2026-10-12:

  (a) steel blast frame   a 25 mm steel face frame of bolted armour plates round the doorway on the
                          cross-wall's face: a 0.55 m jamb plate on the far column (0 to 3.92 m) in
                          three plates, a 0.87 m head plate over the opening (3.05 to 3.92 m, above
                          the hood it shows from 3.5 m) in three plates, carried over the near
                          column's 0.16 m approach face; M24 anchor bolts at 300 mm pitch.
  (b) RESTRICTED AREA     a 3.15 x 0.58 m steel sign plate bolted to the cross-wall's face over the
                          door (4.78 to 5.36 m), lusterless white, the text typeset by script in the
                          game's Roboto (OFL) as a stencil (bridges cut by script), black 37038,
                          0.28 m cap height (11.2 world px, 20 px at 1280x720).
  (c) inner blast door    a 0.24 m thick sliding blast leaf (steel faceplates on a concrete core) in
                          a 0.28 m slot in the wall's thickness (t 0.20..0.48 m behind the face). It
                          closes into a receiver in the near jamb and slides back into a pocket in
                          the far side of the wall on flanged wheels in a floor rail. Open, its
                          leading edge (yellow/black caught-between stripes between two steel
                          angles) stands flush in the pocket's mouth in the far reveal, between two
                          rubber wiper seals; the rail runs across the threshold into the pocket.
  (h) conduit strap       one saddle strap on the 1.54 m vertical lamp conduit at 3.45 m.

Writes add7/door/design/ (masks per part, flat-shaded design layers, leaf elevations, spec.json).
"""
from __future__ import annotations

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from stack import common, p2, p3, p4, p5, p6  # noqa: E402
from common import save_mask, to_srgb_u8, from_srgb_u8, write_json  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "design"))
R6 = "scratchpad/real-slice"
FONT = os.path.join(R6, "game-main", "apps", "game", "assets", "fonts", "Roboto-Variable.ttf")
CVD = p3.CVD

A_F, A_N, A_E, A_BACK = p2.A_F, p2.A_N, p4.A_END4, p2.A_BACK
H_OPEN = p2.H_OPEN

# ---------------------------------------------------------------- (a) blast frame
BF_T = -0.025          # face plates 25 mm proud of the concrete
BF_TOP = 3.92          # top of the frame (the door light's bracket starts at 3.98 m)
BF_JAMB_W = 0.55       # far jamb plate width on the face
BF_A1 = A_F + BF_JAMB_W
BF_JAMB_SEAMS = (1.30, 2.60)
BF_HEAD_SEAMS = (-0.85, 0.35)
BOLT_R = 0.022         # M24 bolt head, 44 mm across flats (drawn round)
BOLT_PITCH = 0.30

# ---------------------------------------------------------------- (b) the sign
SIGN_A0, SIGN_A1 = -1.90, 1.10
SIGN_H0, SIGN_H1 = 4.80, 5.34
SIGN_T = -0.012
SIGN_TEXT = "RESTRICTED AREA"
SIGN_CAP = 0.24

# ---------------------------------------------------------------- (c) the inner blast leaf
T_LF, T_LB = 0.22, 0.46     # leaf faces (0.24 m thick)
T_S0, T_S1 = 0.20, 0.48     # slot in the wall
LEAF_L = 3.95               # leaf length (leading edge to tail)
LEAF_H = 3.20               # its top runs in a guide slot in the head (hidden)
A_LEAD_SHUT = A_N - 0.10    # leading edge in the near jamb's receiver (behind the column)
A_LEAD_OPEN = A_F           # leading edge flush in the pocket's mouth
TRAVEL_M = A_LEAD_OPEN - A_LEAD_SHUT
RAIL_T = (0.30, 0.38)       # recess for the floor rail (rail head 0.325..0.355)
EDGE_ANGLE = 0.05           # steel angles on the leading edge
LEAF_START = 0.40           # the leaf starts to slide when the seal's open value passes this
# leaf elevation canvases (metres -> px)
EL_PPM = 160.0

# ---------------------------------------------------------------- (h) strap
STRAP_H = 3.45


def bolt(a, h, t, plane_t=None):
    return p2.quad_face(a - BOLT_R, a + BOLT_R, h - BOLT_R, h + BOLT_R, t)


def wall_add_parts() -> list:
    """New parts in the wall layer (behind the actors)."""
    P, Part, qf, qs, qt = [], p2.Part, p2.quad_face, p2.quad_side, p2.quad_top
    fp = p2.face_plane(BF_T)
    P.append(Part("wall", "bf_jamb_plate", [qf(A_F, BF_A1, 0.0, BF_TOP, BF_T)], p2.GUNSHIP, fp,
                  "blast frame jamb plates: 25 mm steel, 0.55 m wide, 0 to 3.92 m, three plates", "armour round the opening's far jamb; part of the embedded steel subframe that carries the blast load into the wall"))
    P.append(Part("wall", "bf_head_plate", [qf(A_N, BF_A1, H_OPEN, BF_TOP, BF_T)], p2.GUNSHIP, fp,
                  "blast frame head plates: 25 mm steel, 0.87 m tall (3.05 to 3.92 m), three plates", "armour over the opening (shows above the hood from 3.5 m)"))
    for i, h in enumerate(BF_JAMB_SEAMS):
        P.append(Part("wall", f"bf_jamb_seam{i}", [qf(A_F, BF_A1, h - 0.007, h + 0.007, BF_T - 0.001)], p2.DARK, p2.face_plane(BF_T - 0.001),
                      "plate joint", "joint between two armour plates"))
    for i, a in enumerate(BF_HEAD_SEAMS):
        P.append(Part("wall", f"bf_head_seam{i}", [qf(a - 0.007, a + 0.007, H_OPEN, BF_TOP, BF_T - 0.001)], p2.DARK, p2.face_plane(BF_T - 0.001),
                      "plate joint", "joint between two armour plates"))
    # bolts: the jamb plate's outer row and the head plate's top row (the inner rows are under the guide and the hood)
    bolts = []
    for h in np.arange(0.15, BF_TOP - 0.05, BOLT_PITCH):
        bolts.append(bolt(BF_A1 - 0.07, float(h), BF_T - 0.012))
    for a in np.arange(A_N + 0.08, BF_A1 - 0.02, BOLT_PITCH):
        bolts.append(bolt(float(a), BF_TOP - 0.08, BF_T - 0.012))
    P.append(Part("wall", "bf_bolts", bolts, p2.STEEL, p2.face_plane(BF_T - 0.012),
                  "M24 anchor bolts at 300 mm pitch", "hold the armour plates to the embedded subframe"))
    # the sign plate and its six bolts
    P.append(Part("wall", "sign_plate", [qf(SIGN_A0, SIGN_A1, SIGN_H0, SIGN_H1, SIGN_T)], (0.40, 0.395, 0.40), p2.face_plane(SIGN_T),
                  "steel sign plate 3.0 x 0.54 m, 3 mm, lusterless white (37875, weathered)", "carries the RESTRICTED AREA stencil at the security boundary"))
    sb = [bolt(a, h, SIGN_T - 0.006) for a in (SIGN_A0 + 0.06, (SIGN_A0 + SIGN_A1) / 2, SIGN_A1 - 0.06) for h in (SIGN_H0 + 0.06, SIGN_H1 - 0.06)]
    P.append(Part("wall", "sign_bolts", sb, p2.STEEL, p2.face_plane(SIGN_T - 0.006), "six M10 anchors", "hold the sign plate to the concrete"))
    # the pocket's mouth in the far reveal (side plane at A_F), and the leaf's edge parked in it
    sp = p2.side_plane(A_F)
    P.append(Part("wall", "slot_seal_front", [qs(A_F, T_S0, T_LF, 0.0, H_OPEN)], p2.RUBBER, sp,
                  "rubber wiper seal 20 mm", "seals the leaf's front face at the pocket's mouth"))
    P.append(Part("wall", "slot_seal_back", [qs(A_F, T_LB, T_S1, 0.0, H_OPEN)], p2.RUBBER, sp,
                  "rubber wiper seal 20 mm", "seals the leaf's back face at the pocket's mouth"))
    P.append(Part("wall", "leaf_edge_parked", [qs(A_F, T_LF, T_LB, 0.0, H_OPEN)], p2.YELLOW, sp,
                  "the blast leaf's leading edge, 0.24 m, parked flush in the pocket's mouth", "the inner blast door, slid open into the wall", texture="edge"))
    # the floor rail across the threshold, into the pocket
    P.append(Part("wall", "rail_recess", [qt(A_LEAD_SHUT, A_F, RAIL_T[0], RAIL_T[1], 0.0)], (0.035, 0.037, 0.04), p2.top_plane(0.0),
                  "rail recess 80 mm in the steel threshold", "the floor rail's channel"))
    P.append(Part("wall", "rail_head", [qt(A_LEAD_SHUT, A_F, 0.325, 0.355, 0.001)], p2.STEEL_WORN, p2.top_plane(0.001),
                  "crane-rail head 30 mm, flush, polished by the wheels", "the blast leaf's wheels run on it"))
    return P


def front_add_parts() -> list:
    """New parts in the front layer (the near column, over the actors)."""
    P, Part, qf = [], p2.Part, p2.quad_face
    P.append(Part("front", "bf_near_head", [qf(A_E, A_N, H_OPEN, BF_TOP, BF_T)], p2.GUNSHIP, p2.face_plane(BF_T),
                  "blast frame head plate over the near jamb, 0.16 m", "the head plate carried over the column's approach face"))
    P.append(Part("front", "bf_near_bolts", [bolt(A_E + 0.08, BF_TOP - 0.08, BF_T - 0.012)], p2.STEEL_WORN, p2.face_plane(BF_T - 0.012),
                  "M24 anchor bolt", "holds the head plate"))
    A_C, TL = p6.A_C, p6.TL
    P.append(Part("front", "lamp_conduit_strap2", [p2.quad_side(A_C - 0.006, TL - 0.022, TL + 0.022, STRAP_H - 0.012, STRAP_H + 0.012)], p2.STEEL_WORN,
                  p2.side_plane(A_C - 0.006), "one-hole saddle strap 24 mm at 3.45 m, anchored to the concrete",
                  "holds the 1.54 m vertical lamp conduit (within 0.9 m of the elbow and of the lamp box's strap point)"))
    return P


# ---------------------------------------------------------------- the leaf elevations (flat, leaf-local metres)

def leaf_front_elevation():
    """Front face of the leaf, u = metres back from the leading edge (0..LEAF_L), h up (0..LEAF_H).
    Returns (albedo linear HxWx3, masks dict) on an EL_PPM canvas, row 0 = top (h = LEAF_H)."""
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
        return m

    HOUSING = p2.HOUSING
    rect("leaf_face", 0.0, LEAF_L, 0.0, LEAF_H, HOUSING)                     # 10 mm faceplate, 36081
    rect("leaf_nose", 0.0, 0.10, 0.0, LEAF_H, p2.STEEL)                      # leading-edge channel
    for i, u in enumerate((1.30, 2.60)):
        rect(f"leaf_seam{i}", u - 0.008, u + 0.008, 0.16, LEAF_H, p2.DARK)   # faceplate weld seams
    rect("leaf_bottom_rail", 0.0, LEAF_L, 0.0, 0.16, (0.10, 0.105, 0.115))  # bottom rail over the wheel trucks
    for i, (u0, u1) in enumerate(((0.35, 0.85), (2.95, 3.45))):
        rect(f"leaf_truck{i}", u0, u1, 0.025, 0.145, p2.GUNSHIP)            # bolted truck covers
    rect("leaf_sweep", 0.0, LEAF_L, 0.0, 0.02, p2.RUBBER)                    # rubber bottom sweep
    return alb, masks


def leaf_edge_elevation():
    """Leading edge face, s = metres across the leaf from its front face (0..0.24), h up."""
    Wd = T_LB - T_LF
    W, H = int(round(Wd * EL_PPM)), int(round(LEAF_H * EL_PPM))
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    s = (xx + 0.5) / EL_PPM
    h = LEAF_H - (yy + 0.5) / EL_PPM
    band = ((s + h) / 0.10) % 2.0 < 1.0
    alb = np.where(band[..., None], np.array(p2.YELLOW), np.array(p2.BLACK))
    angles = (s < EDGE_ANGLE) | (s > Wd - EDGE_ANGLE)
    alb[angles] = p2.STEEL
    sweep = h < 0.02
    alb[sweep] = p2.RUBBER
    return alb, {"edge_stripes": (~angles & ~sweep).astype(float), "edge_angles": angles.astype(float), "edge_sweep": sweep.astype(float)}


# ---------------------------------------------------------------- light on the leaf (belongs to the place)

FRONT_LAMPS = (p2.F_CORR, p2.F_DOOR, p2.F_BOUNCE)


def lit_through_opening(lamp, P):
    """1 where the lamp (in front of the wall) sees the point through the doorway, else 0: the
    segment from the lamp to the point must cross the wall's face plane (t = 0) inside the opening."""
    rel_l = lamp.pos - p2.O
    rel_p = P - p2.O
    tl = rel_l @ p2.N
    tp = (rel_p * p2.N).sum(-1)
    k = np.clip(tl / np.where(np.abs(tl - tp) < 1e-9, 1e-9, tl - tp), 0, 1)
    X = lamp.pos + (P - lamp.pos) * k[..., None]
    a = ((X - p2.O) * p2.U).sum(-1)
    h = X[..., 1]
    return ((a >= A_N) & (a <= A_F) & (h <= H_OPEN)).astype(float)


def leaf_front_light(a_grid, h_grid):
    """Linear light on the leaf's front plane (t = T_LF, facing -N) at (a, h)."""
    P = p2.O + a_grid[..., None] * p2.U + h_grid[..., None] * p2.EY + T_LF * p2.N
    Nrm = np.broadcast_to(-p2.N, P.shape)
    out = np.broadcast_to(p2.AMBIENT * 0.7, P.shape).copy()  # inside the doorway: less sky of ambient
    for lp in FRONT_LAMPS:
        L = lp.pos - P
        dist = np.linalg.norm(L, axis=-1, keepdims=True)
        Ln = L / np.maximum(dist, 1e-6)
        ndl = np.clip((Ln * Nrm).sum(-1, keepdims=True), 0, 1)
        ndl = np.where(ndl > 0, p2.WRAP + (1 - p2.WRAP) * ndl, 0.0)
        fall = 1.0 / (1.0 + (dist / lp.reach) ** 2)
        if lp.down > 0:
            below = np.clip((Ln[..., 1:2] + 0.35) / 1.35, 0, 1)
            fall = fall * (0.04 + 0.96 * below ** lp.down)
        vis = lit_through_opening(lp, P)[..., None]
        out = out + lp.intensity * ndl * fall * np.array(lp.color) * vis
    return out


def screen_of(a, h, t):
    return p2.scr(p2.pt(a, h, t))


# ---------------------------------------------------------------- the sign's text (in the face plane)

def sign_text_mask():
    cov, info = p2.text_layer(SIGN_TEXT, SIGN_CAP, p2.face_plane(SIGN_T - 0.001), (SIGN_A0 + SIGN_A1) / 2,
                              (SIGN_H0 + SIGN_H1) / 2 - SIGN_CAP / 2, condensed=True)
    return cov, info


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    wall = p2.render(wall_add_parts(), CVD)["wall"]
    front = p2.render(front_add_parts(), CVD)["front"]
    # the leaf edge's stripes (in the reveal plane)
    _, la, lb = p2.side_plane(A_F).points()  # la = t, lb = h
    stripe = (((la - T_LF) + lb) / 0.10) % 2.0 < 1.0
    em = wall["masks"]["leaf_edge_parked"]
    angles = ((la - T_LF) < EDGE_ANGLE) | ((T_LB - la) < EDGE_ANGLE)
    yel = np.where(angles[..., None], np.array(p2.STEEL), np.where(stripe[..., None], np.array(p2.YELLOW), np.array(p2.BLACK)))
    Pp, _, _ = p2.side_plane(A_F).points()
    Lr = p2.shade(Pp, -p2.U)
    col = yel * Lr
    wall["lin"] = wall["lin"] * (1 - em[..., None]) + col * em[..., None]
    wall["masks"]["leaf_edge_stripes"] = em * (~angles) * stripe
    wall["masks"]["leaf_edge_angles"] = em * angles
    # the sign's text: a mask in the face plane, inside the plate
    rgba0 = np.dstack([to_srgb_u8(wall["lin"]), (np.clip(wall["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
    Image.fromarray(rgba0, "RGBA").save(os.path.join(OUT, "design-add-wall-notext.png"))
    txt, tinfo = sign_text_mask()
    txt = txt * wall["masks"]["sign_plate"] * (1 - wall["masks"]["sign_bolts"])
    wall["masks"]["TEXT-sign"] = txt
    wall["lin"] = wall["lin"] * (1 - txt[..., None]) + np.array(p2.BLACK) * p2.shade(p2.face_plane(SIGN_T).points()[0], -p2.N) * txt[..., None]
    for name, lay in (("wall", wall), ("front", front)):
        rgba = np.dstack([to_srgb_u8(lay["lin"]), (np.clip(lay["a"], 0, 1) * 255 + 0.5).astype(np.uint8)])
        Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, f"design-add-{name}.png"))
        for n, m in lay["masks"].items():
            save_mask(m, os.path.join(OUT, "masks", f"{name}--{n}.png"))
        save_mask(lay["a"], os.path.join(OUT, "masks", f"{name}-add--ALPHA.png"))
    # the leaf elevations: albedo under a flat reference light
    fa, fm = leaf_front_elevation()
    ea, emk = leaf_edge_elevation()
    # flat reference light: the 36081 faceplate reads about luma 30 at the leaf's brightest place
    LREF = 0.083 * np.array([0.92, 1.0, 1.06])
    for nm, alb, mm in (("leaf-front", fa, fm), ("leaf-edge", ea, emk)):
        Image.fromarray(to_srgb_u8(alb * LREF), "RGB").save(os.path.join(OUT, f"design-{nm}-albedo.png"))
        for n, m in mm.items():
            save_mask(m, os.path.join(OUT, "masks", f"{nm}--{n}.png"))
    # light tables on the leaf's front plane: columns at fixed a from the mouth toward the receiver
    a_cols = np.round(np.linspace(A_LEAD_OPEN, A_LEAD_SHUT, 9), 4)
    h_rows = np.array([0.0, 0.4, 0.8, 1.2, 1.6, 2.0, 2.4, 2.75, H_OPEN])
    AG, HG = np.meshgrid(a_cols, h_rows, indexing="ij")
    Lf = leaf_front_light(AG, HG)
    lum = (Lf * np.array([0.2126, 0.7152, 0.0722])).sum(-1)
    ref = lum.max()
    # vertex colour = sRGB(alb * L) / sRGB(alb * L_ref) for a mid albedo (Godot modulates in sRGB)
    alb_mid = 0.16
    fac = (to_srgb_u8(np.array([alb_mid * lum])).astype(float) + 0.5) / (to_srgb_u8(np.array([alb_mid * ref])).astype(float) + 0.5)
    fac = np.clip(fac[0], 0.2, 1.0)
    spec = {
        "units": "metres; a along the cross-wall's face from O = world (752, 440) toward the corridor's back wall, t into the wall (beyond side), h up. Screen: common.project / portal2.scr (clamp-world px).",
        "camera": {"VPX": common.VPX, "HORIZON": common.HORIZON, "FLOOR_Y": common.FLOOR_Y, "D0": common.D0, "PX_PER_M": common.PX_PER_M,
                   "O_m": [round(float(v), 6) for v in p2.O], "U": [round(float(v), 7) for v in p2.U], "N": [round(float(v), 7) for v in p2.N]},
        "jambs_a": {"A_F": round(A_F, 5), "A_N": round(A_N, 5), "A_END4": round(A_E, 5), "A_BACK": round(A_BACK, 5)},
        "blast_frame": {"face_t": BF_T, "top_h": BF_TOP, "jamb_plate_a": [round(A_F, 4), round(BF_A1, 4)], "head_plate_a": [round(A_E, 4), round(BF_A1, 4)],
                        "head_plate_h": [H_OPEN, BF_TOP], "jamb_seams_h": BF_JAMB_SEAMS, "head_seams_a": BF_HEAD_SEAMS, "bolt": "M24, 44 mm head, 300 mm pitch",
                        "screen": {"jamb_outer_edge_at_1m": [round(v, 2) for v in screen_of(BF_A1, 1.0, BF_T)], "head_top_near": [round(v, 2) for v in screen_of(A_E, BF_TOP, BF_T)],
                                   "head_top_far": [round(v, 2) for v in screen_of(BF_A1, BF_TOP, BF_T)]}},
        "sign": {"text": SIGN_TEXT, "plate_a": [SIGN_A0, SIGN_A1], "plate_h": [SIGN_H0, SIGN_H1], "cap_m": SIGN_CAP, "text_info": tinfo,
                 "font": "Roboto (game's bundled Roboto-Variable.ttf, SIL OFL 1.1, Roboto-OFL.txt), wght 700, wdth 75, stencil bridges cut by script (design/tools/text_layer.py bridges())",
                 "colours": "plate lusterless white 37875 (weathered), letters black 37038",
                 "screen": {"plate_corners": [[round(v, 2) for v in screen_of(a, h, SIGN_T)] for a, h in ((SIGN_A0, SIGN_H1), (SIGN_A1, SIGN_H1), (SIGN_A1, SIGN_H0), (SIGN_A0, SIGN_H0))],
                            "cap_world_px": round(SIGN_CAP * 40, 2), "cap_px_1280x720": round(SIGN_CAP * 40 * 1.8, 1)}},
        "leaf": {"thickness_m": round(T_LB - T_LF, 3), "front_t": T_LF, "back_t": T_LB, "slot_t": [T_S0, T_S1], "length_m": LEAF_L, "height_m": LEAF_H,
                 "a_lead_shut": round(A_LEAD_SHUT, 5), "a_lead_open": round(A_LEAD_OPEN, 5), "travel_m": round(TRAVEL_M, 4),
                 "pocket": f"a from {A_F:.3f} to {A_F + LEAF_L + 0.05:.3f} m along the wall (into the mass behind the corridor's back wall)",
                 "rail_recess_t": RAIL_T, "rail_head_t": [0.325, 0.355], "start_open_value": LEAF_START,
                 "screen": {"mouth_foot": [round(v, 2) for v in screen_of(A_F, 0, T_LF)], "mouth_head": [round(v, 2) for v in screen_of(A_F, H_OPEN, T_LF)],
                            "receiver_foot": [round(v, 2) for v in screen_of(A_LEAD_SHUT, 0, T_LF)], "edge_parked_foot": [[round(v, 2) for v in screen_of(A_F, 0, t)] for t in (T_LF, T_LB)]},
                 "light_table": {"a_cols": a_cols.tolist(), "h_rows": h_rows.tolist(), "vertex_colour": np.round(fac, 3).tolist(),
                                 "note": "vertex colour (grey) per (a column, h row) on the leaf's front plane: the place's light (corridor luminaire, door light, floor bounce, each seen only through the doorway) over the brightest place, in sRGB as Godot modulates"}},
        "strap": {"h": STRAP_H, "screen": [round(v, 2) for v in screen_of(p6.A_C, STRAP_H, p6.TL)]},
        "parts": {"wall": [{"name": p.name, "dims": p.dims, "job": p.job} for p in wall_add_parts()],
                  "front": [{"name": p.name, "dims": p.dims, "job": p.job} for p in front_add_parts()],
                  "leaf": [{"name": "leaf_face", "dims": "10 mm steel faceplate (36081) over a concrete core, 3.95 x 3.2 m", "job": "the blast leaf's face"},
                           {"name": "leaf_nose", "dims": "100 mm steel channel", "job": "stiffens the leading edge that seats in the receiver"},
                           {"name": "leaf_seam0..1", "dims": "faceplate weld seams at 1.3 and 2.6 m", "job": "faceplates are 1.3 m sheets"},
                           {"name": "leaf_bottom_rail", "dims": "160 mm bottom rail", "job": "carries the leaf's weight onto the wheel trucks"},
                           {"name": "leaf_truck0..1", "dims": "bolted cover plates 0.5 m", "job": "cover the two flanged-wheel trucks on the floor rail"},
                           {"name": "leaf_sweep", "dims": "20 mm rubber sweep", "job": "seals the leaf's foot to the threshold"},
                           {"name": "edge_stripes", "dims": "0.14 m yellow/black 45 degree bands, 0.10 m", "job": "caught-between marking on the leading edge (OSHA yellow)"},
                           {"name": "edge_angles", "dims": "two 50 mm steel angles", "job": "armour the leading edge's corners"}]},
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    print(json.dumps({k: spec[k] for k in ("blast_frame", "sign", "strap")}, indent=1))
    print(json.dumps({k: v for k, v in spec["leaf"].items() if k != "light_table"}, indent=1))
    print("vertex colour table\n", np.round(fac, 2))


if __name__ == "__main__":
    main()
