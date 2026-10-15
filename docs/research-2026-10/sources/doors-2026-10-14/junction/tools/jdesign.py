"""Construction design of the Service Junction's blast door (scratch only). Every part is an exact
shape from measured numbers in the room's own camera (jmodel.py), with a job; nothing here comes
from an image tool. Writes design/ : one flat-shaded render per layer, one mask per part, contact
shadows, spec.json and composites over the room's plates.

The door: a hinged blast door (single steel leaf, concrete-filled, 2.3 x 2.6 m clear, 0.30 m thick,
in the manner of the Swiss PTO1 armoured gate, 2.4 x 2.1 m x 0.20 m) in a 0.40 m cast-concrete
cross-wall that stands ACROSS the walkway, its approach face turned 17 degrees to the camera. It is
hung and locked from the lane side ("sealed from the other side"): its hinges and locking levers are
on the lane face; the approach face shows only the plain leaf, the two capped lever spindles whose
approach-side levers are removed, the frame, and a guarded red status lamp on the wall's end. The
pressure line from the valve rises up the wall and enters it through a welded penetration plate
beside the door: it feeds the frame on the lane side. Overloaded, the frame cavity bursts, the leaf's
locking bolts shear at the latch (far) jamb and the leaf is thrown into the lane, swinging on its
lane-side hinges until they tear, and falls flat on the lane's deck in front of the release bay
(ASTM F2927 response category IV: the leaf separates from the frame, within 3 m). The back-blast
spalls the concrete round the frame's approach flange, peels that flange at the latch side, sags the
head flange, buckles the threshold and leaves soot over the head. Spalled concrete and frame
fragments lie in the doorway as a low pile up to the rubble line (x 540).

Layers (draw order in the game, bottom to top):
  hole      blown only: the far reveal with its torn bolt keepers, the buckled threshold, the back
            rubble (under the actors)
  leaf      sealed leaf in the opening (under the wall layer, so the frame flanges lap it)
  leafbreak the instant of failure (0.15 s): latch edge pulled 0.12 m into the lane, bolts bent
            across the gap, the face bowing
  wall      the cross-wall behind the walk line with the opening at alpha 0, the far and head frame
            flanges, the door light, the charge line and its penetration plate, the sleeve where the
            room's big pipe passes the wall (under the actors)
  cracks    breaking overlay: cracks running from the latch-side frame corners
  damage    blown overlay: spall round the frame with exposed rebar, the peeled latch flange, the
            sagging head flange, soot
  alcove    the TANK RELEASE bay: recess, header beam, two steel posts on base plates, its fitting
            (under the actors)
  front     over the actors: the near column (frame flange, armoured end, guarded status lamp,
            conduit and junction box) and the 0.15 m stub of the wall across the deck
  lying     blown, over the actors: the leaf lying on the lane deck, the front rubble
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import jmodel as M  # noqa: E402
from jmodel import (A_BACK, A_E, A_F, A_N, A_MID, CV, FR, H_OPEN, H_TOP, LAMP_H, LEAF_T0, LEAF_T1, STUB_H, T_WALL,  # noqa: E402
                    CONCRETE, CONCRETE_CUT, CONCRETE_DK, DARK, GUNSHIP, HOUSING, PIPE, REBAR, SOOT, STEEL, STEEL_WORN,
                    Part, face_plane, front_plane, general_plane, mask_of, poly, pt, quad_face, quad_side, quad_top, scr,
                    side_plane, top_plane)

OUT = os.path.join(M.WORK, "design")
RNG_SEED = 20261013

# ---------------------------------------------------------------------------------------- helpers

def cyl_mod(axis_a0, axis_a1):
    """Vertical pipe on the face: lighter down its middle (a cylinder lit from the front)."""
    def f(P, la, lb):
        c = (axis_a0 + axis_a1) / 2
        r = (axis_a1 - axis_a0) / 2
        u = np.clip((la - c) / r, -1, 1)
        return 0.55 + 0.6 * np.sqrt(np.clip(1 - u * u, 0, 1))
    return f


def soft_field(fn):
    """A clip mask from a function of world (X, Y) on the canvas."""
    X, Y = CV.grid()
    return np.clip(fn(X, Y), 0, 1)


def seg_poly(p0, p1, w):
    """A thin quad (screen px) from p0 to p1, w world px wide."""
    (x0, y0), (x1, y1) = p0, p1
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / L * w / 2, dx / L * w / 2
    return [(x0 + nx, y0 + ny), (x1 + nx, y1 + ny), (x1 - nx, y1 - ny), (x0 - nx, y0 - ny)]


# ---------------------------------------------------------------------------------------- wall

A_CL = 1.40 / math.cos(M.THETA)  # the charge line rises 1.4 m behind the walk line (x ~457)
CL_R = 0.055
H_CL_TOP = 3.08


def wall_parts() -> list:
    P = []
    fp = face_plane(0.0)
    P.append(Part("wall", "face_far_column", [quad_face(A_F + FR, A_BACK, 0.0, H_OPEN + FR)], CONCRETE, fp,
                  "cast reinforced concrete, 0.40 m thick; 4.7 m of face from the far jamb's frame back to the room's back wall", "the cross-wall the door is set in; carries the charge line"))
    P.append(Part("wall", "face_upper", [quad_face(A_E, A_BACK, H_OPEN + FR, H_TOP)], CONCRETE, fp,
                  "the same wall over the door head, up to the slab", "closes the junction off from the lane"))
    for i, h in enumerate((4.05, 6.75)):
        P.append(Part("wall", f"pour_joint{i}", [quad_face(A_E + 0.05, A_BACK, h - 0.012, h + 0.012)], CONCRETE_DK, fp,
                      "pour line between concrete lifts", "construction joint"))
    P.append(Part("wall", "back_corner", [quad_face(A_BACK - 0.08, A_BACK, 0.0, H_TOP, -0.004)], CONCRETE_DK, M.face_plane(-0.004),
                  "internal corner with the room's back wall", "where the cross-wall meets the back wall"))
    # the steel channel frame cast into the opening: its approach flanges (the near one is in front)
    P.append(Part("wall", "frame_far", [quad_face(A_F, A_F + FR, 0.0, H_OPEN + FR, -0.008)], GUNSHIP, face_plane(-0.008),
                  "steel channel frame, 120 mm approach flange, anchored into the concrete", "lines the latch jamb; carries the bolt keepers"))
    P.append(Part("wall", "frame_head", [quad_face(A_N - FR, A_F + FR, H_OPEN, H_OPEN + FR, -0.008)], GUNSHIP, face_plane(-0.008),
                  "steel channel head, 120 mm flange", "lines the head"))
    # threshold: a steel plate across the opening, flush with the deck
    P.append(Part("wall", "threshold", [quad_top(A_N - 0.05, A_F + 0.05, -0.12, 0.0, 0.004)], (0.27, 0.275, 0.29), top_plane(0.004),
                  "steel threshold plate 2.4 x 0.6 m (front strip; the rest is under the leaf)", "metal threshold of the opening; the leaf's drop seal lands on it"))
    # the door light: vapour-tight fitting on two brackets over the head
    for i, da in enumerate((-0.42, 0.42)):
        P.append(Part("wall", f"light_bracket{i}", [poly([pt(A_MID + da, 3.30, -0.01), pt(A_MID + da, 3.30, -0.32), pt(A_MID + da, 3.26, -0.32), pt(A_MID + da, 3.26, -0.01)])], HOUSING,
                      M.Plane(pt(A_MID + da, 0, 0), M.N, M.EY, -M.U), "flat bracket 0.3 m", "holds the fitting off the wall"))
    P.append(Part("wall", "light_body", [quad_face(A_MID - 0.6, A_MID + 0.6, 3.16, 3.28, -0.34)], (0.42, 0.45, 0.47), face_plane(-0.34),
                  "vapour-tight LED fitting 1.2 x 0.12 m", "lights the door, the threshold and the approach"))
    P.append(Part("wall", "light_lens", [quad_face(A_MID - 0.58, A_MID + 0.58, 3.14, 3.165, -0.35)], (1, 1, 1), face_plane(-0.35),
                  "diffuser", "the light source (painted lit, static)", emit=(0.86, 0.95, 1.0)))
    P.append(Part("wall", "light_feed", [quad_face(A_MID - 0.62, A_MID - 0.59, 3.28, 3.57, -0.03), quad_face(A_E, A_MID - 0.59, 3.545, 3.57, -0.03)], STEEL, face_plane(-0.03),
                  "20 mm rigid conduit", "feeds the door light from the junction box on the column's end"))
    P.append(Part("wall", "light_feed_strap", [quad_face(A_MID - 1.05, A_MID - 0.97, 3.53, 3.585, -0.04)], DARK, face_plane(-0.04),
                  "one-hole strap", "holds the conduit within 0.9 m of the fitting"))
    # the charge line: the valve's outlet rises behind the valve and enters the wall beside the door
    P.append(Part("wall", "charge_line", [quad_face(A_CL - CL_R, A_CL + CL_R, 0.30, H_CL_TOP, -0.09)], PIPE, face_plane(-0.09),
                  "100 mm steel pipe, the valve's outlet", "carries the overloaded line from the valve through the wall to the door's frame on the lane side",
                  mod=cyl_mod(A_CL - CL_R, A_CL + CL_R)))
    P.append(Part("wall", "charge_plate", [quad_face(A_CL - 0.24, A_CL + 0.24, 2.86, 3.32, -0.006)], STEEL, face_plane(-0.006),
                  "6 mm welded penetration plate 0.48 x 0.46 m, 150 mm past the pipe", "where the line passes the wall"))
    P.append(Part("wall", "charge_collar", [quad_face(A_CL - 0.085, A_CL + 0.085, H_CL_TOP - 0.06, H_CL_TOP + 0.04, -0.11)], HOUSING, face_plane(-0.11),
                  "welded sleeve collar", "seals the pipe to the plate"))
    for i, h in enumerate((2.05,)):
        P.append(Part("wall", f"charge_clamp{i}", [quad_face(A_CL - 0.085, A_CL + 0.085, h - 0.03, h + 0.03, -0.15)], DARK, face_plane(-0.15),
                      "U-bolt pipe clamp on a stand-off bracket", "holds the riser to the wall"))
    # the room's big pipe (mid plate, x <= 420 at y 224..277) passes the wall at its back corner
    P.append(Part("wall", "pipe_sleeve_plate", [quad_face(A_BACK - 1.05, A_BACK - 0.03, 3.45, 5.40, -0.006)], STEEL, face_plane(-0.006),
                  "6 mm welded penetration plate round the 1.3 m main", "where the junction's main passes into the lane"))
    return P


# ---------------------------------------------------------------------------------------- leaf

def leaf_parts(layer="leaf", t_far=LEAF_T0) -> list:
    """The leaf in the opening: its approach face (behind the stop, 30 mm in from the face), its
    perimeter seam, the drop seal and the two capped lever spindles. With t_far > LEAF_T0 the latch
    edge is pushed into the lane (the breaking frame)."""
    P = []
    t0 = LEAF_T0
    pl = M.general_plane(pt(A_N, 0, t0), pt(A_F, 0, t_far), pt(A_N, 1, t0))

    def L(a, h):  # a point on the (possibly turned) leaf face
        k = (a - A_N) / (A_F - A_N)
        return pt(a, h, t0 + k * (t_far - t0))

    def quad(a0, a1, h0, h1):
        return poly([L(a0, h0), L(a1, h0), L(a1, h1), L(a0, h1)])

    def bow(P_, la, lb):
        if t_far <= t0 + 1e-6:
            return 1.0
        # the face bows into the lane: its middle turns away from the door light
        u = (la - la.min()) / max(np.ptp(la), 1e-6)
        v = np.clip(lb / H_OPEN, 0, 1)
        return 1.0 - 0.35 * np.sin(np.pi * np.clip(u, 0, 1)) * np.sin(np.pi * v)

    P.append(Part(layer, "leaf_face", [quad(A_N, A_F, 0.02, H_OPEN - 0.008)], GUNSHIP, pl,
                  "steel leaf 2.3 x 2.6 m, 0.30 m thick, 10 mm skins over a concrete fill (about 4.5 t)", "the door; hung and locked from the lane side", mod=bow))
    for i, (a0, a1, h0, h1) in enumerate(((A_N + 0.06, A_F - 0.06, 0.07, 0.085), (A_N + 0.06, A_F - 0.06, H_OPEN - 0.075, H_OPEN - 0.06),
                                            (A_N + 0.06, A_N + 0.075, 0.07, H_OPEN - 0.06), (A_F - 0.075, A_F - 0.06, 0.07, H_OPEN - 0.06))):
        P.append(Part(layer, f"leaf_seam{i}", [quad(a0, a1, h0, h1)], DARK, pl, "skin-to-edge-channel weld seam, 60 mm in", "the skin's welded edge"))
    P.append(Part(layer, "leaf_drop_seal", [quad(A_N + 0.02, A_F - 0.02, 0.02, 0.045)], M.DARK, pl, "rubber drop seal", "seals to the threshold"))
    for i, h in enumerate((0.95, 1.55)):
        P.append(Part(layer, f"leaf_spindle_cap{i}", [quad(A_F - 0.25, A_F - 0.13, h - 0.06, h + 0.06)], STEEL_WORN, pl,
                      "capped square lever spindle, 120 mm boss", "the locking lever on this side is removed: the door is worked only from the lane side"))
    return P


def leafbreak_parts() -> list:
    """The instant of failure: the latch edge pushed 0.12 m into the lane, the steel liner of the far
    reveal showing in the gap, and the three locking bolts bent across it."""
    tf = LEAF_T0 + 0.12
    P = [Part("leafbreak", "gap_reveal", [quad_side(A_F, 0.0, tf + 0.02, 0.0, H_OPEN)], STEEL, side_plane(A_F),
              "the far reveal's steel liner, seen in the opening gap", "the frame the leaf is tearing out of")]
    P += leaf_parts("leafbreak", t_far=tf)
    for i, h in enumerate((0.40, 1.30, 2.20)):
        P.append(Part("leafbreak", f"bent_bolt{i}", [poly([pt(A_F + 0.002, h - 0.025, LEAF_T0 + 0.02), pt(A_F - 0.004, h - 0.045, tf), pt(A_F - 0.004, h + 0.005, tf), pt(A_F + 0.002, h + 0.025, LEAF_T0 + 0.02)])],
                      STEEL_WORN, side_plane(A_F - 0.001), "50 mm locking bolt, bent", "the bolts are shearing at the latch jamb"))
    return P


def crack_parts() -> list:
    """Breaking overlay: cracks in the approach face running from the latch-side frame corners and
    along the head, where the frame's anchors are pulling out."""
    rng = np.random.default_rng(RNG_SEED + 1)
    P = []
    starts = [(A_F + FR, 0.35), (A_F + FR, 1.3), (A_F + FR, 2.2), (A_F + FR, H_OPEN + FR), (A_MID, H_OPEN + FR), (A_N - FR, H_OPEN + FR)]
    lines = []
    for (a, h) in starts:
        pts = [(a, h)]
        ang = rng.uniform(-0.6, 0.6) + (0.0 if a > A_MID else math.pi / 2)
        for k in range(rng.integers(3, 6)):
            step = rng.uniform(0.08, 0.2)
            ang += rng.normal(0, 0.45)
            a2 = pts[-1][0] + math.cos(ang) * step
            h2 = pts[-1][1] + math.sin(ang) * step * (1 if h < H_OPEN else 1)
            pts.append((a2, h2))
        for p0, p1 in zip(pts, pts[1:]):
            lines.append(seg_poly(scr(pt(p0[0], p0[1], -0.002)), scr(pt(p1[0], p1[1], -0.002)), 0.32))
    P.append(Part("cracks", "cracks", lines, CONCRETE_DK, face_plane(-0.002), "hairline-to-3 mm cracks", "the frame's anchors pulling out of the concrete"))
    return P


# ---------------------------------------------------------------------------------------- blown

def hole_parts() -> list:
    P = []
    P.append(Part("hole", "reveal_far", [quad_side(A_F, 0.0, T_WALL, 0.0, H_OPEN)], (0.24, 0.25, 0.27), side_plane(A_F),
                  "the latch jamb's frame web: 6 mm steel liner over the 0.40 m wall", "the jamb the bolts sheared out of; seen through the empty opening"))
    for i, h in enumerate((0.40, 1.30, 2.20)):
        P.append(Part("hole", f"keeper{i}", [quad_side(A_F - 0.004, 0.10, 0.26, h - 0.08, h + 0.08)], DARK, side_plane(A_F - 0.004),
                      "torn bolt keeper pocket 160 x 160 mm", "where a locking bolt was"))
        P.append(Part("hole", f"keeper_tab{i}", [poly([pt(A_F - 0.004, h + 0.08, 0.10), pt(A_F - 0.004, h + 0.08, 0.26), pt(A_F - 0.10, h + 0.13, 0.24), pt(A_F - 0.10, h + 0.12, 0.12)])],
                      STEEL_WORN, side_plane(A_F - 0.05), "keeper lip bent out", "torn steel at the pocket"))
    P.append(Part("hole", "threshold_full", [quad_top(A_N - 0.05, A_F + 0.05, -0.12, T_WALL + 0.06, 0.006)], (0.25, 0.255, 0.27), top_plane(0.006),
                  "steel threshold plate 2.4 x 0.6 m, bowed up 40 mm where the leaf tore out", "metal threshold of the opening",
                  mod=lambda P_, la, lb: 1.0 + 0.35 * np.exp(-((lb - 0.24) / 0.05) ** 2)))
    return P


def damage_parts() -> list:
    """Blown overlay on the approach face (drawn over the wall layer)."""
    P = []
    rng = np.random.default_rng(RNG_SEED + 2)

    def ragged(a0, a1, h0, h1, n=14, amp=0.05):
        pts = []
        for k in range(n):  # around a rounded rectangle with jitter
            tt = k / n * 2 * math.pi
            a = (a0 + a1) / 2 + (a1 - a0) / 2 * math.copysign(abs(math.cos(tt)) ** 0.6, math.cos(tt)) + rng.normal(0, amp)
            h = (h0 + h1) / 2 + (h1 - h0) / 2 * math.copysign(abs(math.sin(tt)) ** 0.6, math.sin(tt)) + rng.normal(0, amp)
            pts.append(pt(a, h, -0.001))
        return poly(pts)

    sp = M.face_plane(0.03)
    spalls = [ragged(A_F + FR - 0.02, A_F + FR + 0.34, 0.15, 1.15), ragged(A_F + FR - 0.02, A_F + FR + 0.28, 1.4, 2.35),
              ragged(A_N - 0.1, A_F + FR + 0.3, H_OPEN + FR - 0.02, H_OPEN + FR + 0.30, n=18)]
    P.append(Part("damage", "spall", spalls, CONCRETE_CUT, sp,
                  "concrete spalled off the face round the frame's anchors, 30-60 mm deep", "the back-blast tore the frame's approach flange loose"))
    rebar = []
    for a in (A_F + FR + 0.22,):
        rebar.append(seg_poly(scr(pt(a, 0.25, 0.02)), scr(pt(a, 2.25, 0.02)), 0.6))
    for h in (0.55, 0.95, 1.65, 2.05):
        rebar.append(seg_poly(scr(pt(A_F + FR + 0.02, h, 0.02)), scr(pt(A_F + FR + 0.30, h, 0.02)), 0.45))
    rebar.append(seg_poly(scr(pt(A_N - 0.02, H_OPEN + FR + 0.16, 0.02)), scr(pt(A_F + FR + 0.24, H_OPEN + FR + 0.16, 0.02)), 0.6))
    P.append(Part("damage", "rebar", rebar, REBAR, sp, "16 mm reinforcing bars exposed in the spall", "the wall's reinforcement"))
    # the latch-side flange: anchored at the bottom, peeled off the face above 1.1 m
    peel = poly([pt(A_F, 1.10, -0.008), pt(A_F + FR, 1.10, -0.008), pt(A_F + FR + 0.05, H_OPEN + FR, -0.32), pt(A_F + 0.04, H_OPEN + FR - 0.05, -0.30)])
    P.append(Part("damage", "flange_peeled", [peel], GUNSHIP, M.general_plane(pt(A_F, 1.1, -0.008), pt(A_F + FR, 1.1, -0.008), pt(A_F + 0.04, H_OPEN, -0.3)),
                  "the latch flange, torn off its anchors above 1.1 m and bent 0.3 m out", "frame damage"))
    P.append(Part("damage", "flange_far_low", [quad_face(A_F, A_F + FR, 0.0, 1.10, -0.008)], GUNSHIP, face_plane(-0.008), "latch flange, still anchored", "frame"))
    # the head flange sags 0.08 m in the middle
    sag = []
    n = 10
    top = [pt(A_N - FR + (A_F + FR - A_N + FR) * k / n, H_OPEN + FR - 0.08 * math.sin(math.pi * k / n), -0.03) for k in range(n + 1)]
    bot = [pt(A_N - FR + (A_F + FR - A_N + FR) * k / n, H_OPEN - 0.08 * math.sin(math.pi * k / n), -0.03) for k in range(n + 1)]
    sag.append(poly(top + bot[::-1]))
    P.append(Part("damage", "head_sag", sag, GUNSHIP, face_plane(-0.03), "head flange bowed 80 mm", "frame damage"))
    # soot: the gas vented out through the gap round the leaf, up over the head and along the latch side
    def soot_fn(X, Y):
        hx, hy = scr(pt(A_MID, H_OPEN + 0.1, 0.0))
        lx, ly = scr(pt(A_F + 0.1, 1.4, 0.0))
        f1 = np.exp(-(((X - hx) / 13.0) ** 2) - (np.clip(hy - Y, 0, None) / 30.0) ** 2) * (Y < hy + 4)
        f2 = np.exp(-(((X - lx) / 6.0) ** 2) - ((Y - ly) / 42.0) ** 2)
        return 0.75 * np.maximum(f1, 0.8 * f2)
    face_all = mask_of([quad_face(A_E, A_BACK, 0.0, H_TOP)])
    hole = mask_of([quad_face(A_N, A_F, 0.0, H_OPEN)])
    P.append(Part("damage", "soot", [quad_face(A_E, A_BACK, 0.0, 5.0)], SOOT, face_plane(-0.0005),
                  "soot from the vented gas", "where the blast left the frame", clip=soot_fn(*CV.grid()) * face_all * (1 - hole) if False else soft_field(soot_fn) * (1 - hole)))
    return P


# ---------------------------------------------------------------------------------------- rubble

def chunk_parts(layer, name, rng, centres, size_rng, h_ratio=(0.22, 0.5), albedo=CONCRETE_CUT, job="spalled concrete"):
    """Broken concrete pieces on the floor: irregular footprints (6-9 corners), faceted tops (a fan of
    triangles round a raised centre, each its own plane, as a fracture surface is), camera-facing
    sides; sizes follow the centres' size range, drawn far to near. centres: (x_walk px, d metres)."""
    items = []
    for (xw, d) in centres:
        s = rng.uniform(*size_rng)
        nv = int(rng.integers(6, 10))
        ang0 = rng.uniform(0, 2 * math.pi)
        rad = [s / 2 * rng.uniform(0.45, 1.0) for _ in range(nv)]
        cx, cd = xw / M.PXM, d
        foot = [(cx + math.cos(ang0 + 2 * math.pi * k / nv) * rad[k], cd + math.sin(ang0 + 2 * math.pi * k / nv) * rad[k] * 0.85) for k in range(nv)]
        hc = s * rng.uniform(*h_ratio)
        tops = [np.array([fx, hc * rng.uniform(0.35, 0.95), fd]) for fx, fd in foot]
        apex = np.array([cx + rng.normal(0, s * 0.08), hc * rng.uniform(1.0, 1.15), cd + rng.normal(0, s * 0.08)])
        bots = [np.array([fx, 0.0, fd]) for fx, fd in foot]
        items.append((d, tops, bots, apex, s))
    items.sort(key=lambda it: -it[0])
    P = []
    eye = np.array([M.VPX / M.PXM, (M.FLOOR_Y - M.HORIZON) / M.PXM, -M.D0])
    for (d, tops, bots, apex, s) in items:
        n = len(tops)
        for k in range(n):
            a0, a1 = bots[k], bots[(k + 1) % n]
            b0, b1 = tops[k], tops[(k + 1) % n]
            nrm = np.cross(a1 - a0, b0 - a0)
            cen = (a0 + a1 + b0 + b1) / 4
            if (nrm * (eye - cen)).sum() <= 0:
                continue
            P.append(Part(layer, name, [poly([a0, a1, b1, b0])], np.array(CONCRETE_DK) * 1.25, general_plane(a0, a1, b0), f"{job} {s:.2f} m", "rubble from the blast"))
        for k in range(n):
            t0, t1 = tops[k], tops[(k + 1) % n]
            P.append(Part(layer, name, [poly([apex, t0, t1])], albedo, general_plane(apex, t0, t1), f"{job} {s:.2f} m: fracture facet", "rubble from the blast"))
    return P


def rubble_back_parts() -> list:
    rng = np.random.default_rng(RNG_SEED + 3)
    P = []
    # the heap: spalled concrete and fines piled in the doorway's foot, highest (0.24 m) just inside
    # the opening and running out to nothing at the rubble line (x 540), from 0.6 m behind the walk
    # line to 0.5 m in front of it
    def heap_h(xw, d):
        u = (xw - 486.0) / (54.0 if xw > 486.0 else 20.0)
        v = (d - 0.05) / 0.6
        return 0.34 * max(0.0, 1.0 - u * u) * max(0.0, 1.0 - v * v)
    top, front = [], []
    xs = np.linspace(466.0, 540.0, 30)
    for xw in xs:  # its skyline (the ridge seen from the camera) and its foot toward the camera
        best = max((heap_h(xw, d), d) for d in np.linspace(-0.55, 0.65, 25))
        top.append(np.array([xw / M.PXM, best[0], best[1]]))
        front.append(np.array([xw / M.PXM, 0.0, -0.5 * max(0.0, 1.0 - ((xw - 492.0) / 52.0) ** 2) - 0.02]))
    heap = poly(top + front[::-1])
    P.append(Part("hole", "rubble_heap", [heap], CONCRETE_CUT, front_plane(0.0),
                  "a heap of spalled concrete and fines 0.34 m high, 1.8 m long", "what the blast tore out of the jambs; the rubble line (x 540) is its end",
                  mod=lambda P_, la, lb: 0.75 + 0.5 * np.clip(lb / 0.34, 0, 1)))
    cen = []
    for _ in range(18):  # broken pieces on and round the heap
        xw = rng.uniform(470, 536)
        cen.append((xw, rng.uniform(-0.35, 0.45)))
    P += chunk_parts("hole", "rubble_back", rng, cen, (0.08, 0.22))
    P += chunk_parts("hole", "rubble_back", rng, [(478.0, 0.3), (492.0, 0.1), (507.0, 0.35), (522.0, 0.0), (500.0, -0.25)], (0.24, 0.34), h_ratio=(0.4, 0.55))
    # the bigger slabs that came off the jambs lie at the foot of the opening
    P += chunk_parts("hole", "rubble_back", rng, [(476.0, 0.35), (489.0, 0.1), (503.0, 0.3), (518.0, 0.0)], (0.30, 0.42), h_ratio=(0.45, 0.6))
    # a torn length of the frame's channel lying across the threshold
    c0 = np.array([12.05, 0.0, 0.25])
    c1 = np.array([13.05, 0.0, -0.05])
    up = np.array([0, 0.11, 0])
    P.append(Part("hole", "frame_piece", [poly([c0, c1, c1 + up, c0 + up])], GUNSHIP, general_plane(c0, c1, c0 + up),
                  "1.0 m of the frame's 120 mm channel, torn off", "frame fragment"))
    P.append(Part("hole", "frame_piece_top", [poly([c0 + up, c1 + up, c1 + up + np.array([0, 0, 0.12]), c0 + up + np.array([0, 0, 0.12])])], STEEL_WORN, top_plane(0.11),
                  "its torn top edge", "frame fragment"))
    return P


# ---------------------------------------------------------------------------------------- lying leaf

LY_A0 = A_N - 1.00  # the leaf's bottom edge, 1 m in front of the near jamb (thrown clear of the bay)
LY_T0 = T_WALL + 0.30  # its hinge edge, 0.30 m off the wall's lane face
LY_YAW = math.radians(16.0)


def lying_parts() -> list:
    P = []
    W, H, TH = M.W_OPEN, H_OPEN, 0.30
    ca, sa = math.cos(LY_YAW), math.sin(LY_YAW)
    cen = (LY_A0 - H / 2, LY_T0 + W / 2)

    def corner(da, dt):  # (da along -U from the bottom edge, dt along +N from the hinge edge), yawed about the centre
        a = LY_A0 - da - cen[0]
        t = LY_T0 + dt - cen[1]
        a, t = a * ca - t * sa, a * sa + t * ca
        return cen[0] + a, cen[1] + t

    def P3(da, dt, z):  # the bottom face rests propped 0.08 m on the hinge side (a chunk under it)
        a, t = corner(da, dt)
        prop = 0.08 * (1 - dt / W)
        sag = -0.04 * math.sin(math.pi * da / H)
        return pt(a, z + prop + sag, t)

    top = [P3(0, 0, TH), P3(0, W, TH), P3(H, W, TH), P3(H, 0, TH)]
    # its top edge (toward the camera) and the hinge edge (left) are the visible edges
    front = [P3(H, 0, 0), P3(H, W, 0), P3(H, W, TH), P3(H, 0, TH)]
    left = [P3(0, 0, 0), P3(H, 0, 0), P3(H, 0, TH), P3(0, 0, TH)]
    shadow_pts = [P3(-0.05, -0.05, 0), P3(-0.05, W + 0.08, 0), P3(H + 0.1, W + 0.08, 0), P3(H + 0.1, -0.05, 0)]
    for q in shadow_pts:
        q[1] = 0.0
    pa, pt_ = corner(H * 0.55, 0.15)
    pc = pt(pa, 0.0, pt_)
    P += chunk_parts("lying", "prop_chunk", np.random.default_rng(RNG_SEED + 9), [(pc[0] * M.PXM, pc[2])], (0.26, 0.28), h_ratio=(0.42, 0.45))
    P.append(Part("lying", "leaf_shadow", [poly(shadow_pts)], (0.004, 0.005, 0.006), top_plane(0.0), "contact shadow", "the leaf lies on the deck"))
    P.append(Part("lying", "leaf_left_edge", [poly(left)], np.array(GUNSHIP) * 0.8, general_plane(left[0], left[1], left[3]),
                  "the leaf's hinge edge, 0.30 m", "torn hinge side"))
    P.append(Part("lying", "leaf_top_edge", [poly(front)], np.array(GUNSHIP) * 0.9, general_plane(front[0], front[1], front[3]),
                  "the leaf's top edge, 0.30 m: 10 mm skins and the edge channel over the concrete fill", "the door's edge, toward the camera"))
    tp = general_plane(top[0], top[1], top[3])

    def bowmod(P_, la, lb):
        return 0.9 + 0.12 * np.clip(lb / max(H, 1e-6), -1, 1)

    P.append(Part("lying", "leaf_up_face", [poly(top)], np.array(GUNSHIP) * 0.7, tp,
                  "the leaf's approach face, up: bowed 40 mm", "the door, thrown 2-3 m into the lane", mod=bowmod))
    for i, (da, dt) in enumerate(((0.95, W - 0.19), (1.55, W - 0.19))):
        q = [P3(da - 0.06, dt - 0.06, TH + 0.01), P3(da - 0.06, dt + 0.06, TH + 0.01), P3(da + 0.06, dt + 0.06, TH + 0.01), P3(da + 0.06, dt - 0.06, TH + 0.01)]
        P.append(Part("lying", f"leaf_spindle_cap{i}", [poly(q)], STEEL_WORN, tp, "capped lever spindle", "the same caps as on the shut door"))
    for i, da in enumerate((0.35, 1.30, 2.25)):  # torn hinge knuckles on the hinge edge
        q = [P3(da - 0.09, -0.07, 0.04), P3(da + 0.09, -0.07, 0.04), P3(da + 0.09, -0.07, 0.24), P3(da - 0.09, -0.07, 0.24)]
        P.append(Part("lying", f"hinge_knuckle{i}", [poly(q)], STEEL_WORN, general_plane(q[0], q[1], q[3]),
                      "torn hinge knuckle 180 mm, its pin sheared", "the leaf hung on three of these on the lane side"))
    return P


def rubble_front_parts() -> list:
    rng = np.random.default_rng(RNG_SEED + 4)
    cen = []
    for _ in range(16):  # thrown forward from the doorway onto the approach-side deck
        cen.append((rng.uniform(446, 494), rng.uniform(-1.7, -0.35)))
    P = chunk_parts("lying", "rubble_front", rng, cen, (0.04, 0.12))
    P += chunk_parts("lying", "rubble_front", rng, [(466.0, -0.8), (481.0, -1.25), (458.0, -0.45), (527.0, -0.9)], (0.22, 0.32))
    cen = [(rng.uniform(512, 545), rng.uniform(-1.4, -0.3)) for _ in range(10)]  # on the lane deck by the wall
    P += chunk_parts("lying", "rubble_front", rng, cen, (0.04, 0.14))
    # concrete dust settled on the deck round the doorway (a thin film, darkest-free, no glow)
    def dust_fn(X, Y):
        cx, cy = 492.0, 447.0
        return 0.30 * np.exp(-(((X - cx) / 42.0) ** 2) - (((Y - cy) / 7.0) ** 2)) * (Y > 440.5)
    deck = [poly([np.array([x / M.PXM, 0.0, d]) for x, d in ((430, 0.0), (575, 0.0), (575, -2.2), (430, -2.2))])]
    P.insert(0, Part("lying", "dust_film", deck, (0.30, 0.30, 0.31), top_plane(0.001), "a film of concrete dust", "settled after the blast", clip=soft_field(dust_fn)))
    return P


# ---------------------------------------------------------------------------------------- front

def stub_far_a() -> float:
    return M.DECK_FRONT_D / math.cos(M.THETA)


def front_parts() -> list:
    P = []
    tl = T_WALL / 2
    P.append(Part("front", "col_flange_near", [quad_face(A_N - FR, A_N, 0.0, H_OPEN + FR, -0.008)], GUNSHIP, face_plane(-0.008),
                  "steel channel frame, 120 mm approach flange", "lines the hinge jamb"))
    P.append(Part("front", "col_face_strip", [quad_face(A_E, A_N - FR, 0.0, H_TOP)], CONCRETE, face_plane(0.0), "20 mm of face", "the wall's end"))
    P.append(Part("front", "col_end", [quad_side(A_E, 0.0, T_WALL, 0.0, H_TOP)], CONCRETE, side_plane(A_E),
                  "the cross-wall's end face toward the camera, 0.40 m", "the wall's end; carries the status lamp and the junction box"))
    P.append(Part("front", "col_arris_face", [quad_face(A_E, A_E + 0.05, 0.0, H_TOP, -0.004)], STEEL, face_plane(-0.004), "50 mm steel arris angle, face leg", "armours the corner"))
    P.append(Part("front", "col_arris_end_l", [quad_side(A_E - 0.002, 0.0, 0.05, 0.0, H_TOP)], STEEL, side_plane(A_E - 0.002), "50 mm steel arris angle", "armours the corner"))
    P.append(Part("front", "col_arris_end_r", [quad_side(A_E - 0.002, T_WALL - 0.05, T_WALL, 0.0, H_TOP)], STEEL, side_plane(A_E - 0.002), "50 mm steel arris angle", "armours the lane-side corner"))
    # the guarded status lamp (live lens: red shut, amber charging, off once blown)
    P.append(Part("front", "lamp_base", [quad_side(A_E - 0.10, tl - 0.09, tl + 0.09, LAMP_H - 0.17, LAMP_H - 0.10)], HOUSING, side_plane(A_E - 0.10), "cast lamp body on a conduit box", "carries the globe"))
    P.append(Part("front", "lamp_cap", [quad_side(A_E - 0.10, tl - 0.07, tl + 0.07, LAMP_H + 0.085, LAMP_H + 0.12)], HOUSING, side_plane(A_E - 0.10), "guard cap", "tops the wire guard"))
    for i, dt in enumerate((-0.055, 0.0, 0.055)):
        P.append(Part("front", f"lamp_guard{i}", [quad_side(A_E - 0.13, tl + dt - 0.007, tl + dt + 0.007, LAMP_H - 0.10, LAMP_H + 0.09)], STEEL, side_plane(A_E - 0.13), "wire guard bar", "protects the globe"))
    P.append(Part("front", "lamp_conduit", [quad_side(A_E - 0.03, tl - 0.012, tl + 0.012, LAMP_H + 0.12, 3.40)], STEEL, side_plane(A_E - 0.03), "20 mm rigid conduit", "feeds the lamp from the junction box"))
    P.append(Part("front", "jb_backplate", [quad_side(A_E - 0.01, tl - 0.15, tl + 0.15, 3.38, 3.84)], HOUSING, side_plane(A_E - 0.01), "backplate", "carries the box"))
    P.append(Part("front", "jb_box", [quad_side(A_E - 0.13, tl - 0.12, tl + 0.12, 3.41, 3.81)], GUNSHIP, side_plane(A_E - 0.13), "lockable junction box 0.24 x 0.40 x 0.12 m", "terminates the lamp's and the door light's feeds"))
    P.append(Part("front", "jb_hinge", [quad_side(A_E - 0.14, tl - 0.12, tl - 0.10, 3.43, 3.79)], DARK, side_plane(A_E - 0.14), "cover hinge", "hinged cover"))
    P.append(Part("front", "jb_lock", [quad_side(A_E - 0.14, tl + 0.085, tl + 0.105, 3.59, 3.63)], STEEL, side_plane(A_E - 0.14), "padlock hasp", "lockable"))
    P.append(Part("front", "light_feed_end", [quad_side(A_E - 0.03, 0.0, tl - 0.12, 3.545, 3.57)], STEEL, side_plane(A_E - 0.03), "20 mm conduit round the arris", "the door light's feed into the box"))
    P.append(Part("front", "riser", [quad_side(A_E - 0.03, tl - 0.012, tl + 0.012, 3.84, H_TOP)], STEEL, side_plane(A_E - 0.03), "20 mm conduit up to the slab tray", "feeds the box from above"))
    for i, h in enumerate((4.55, 5.45, 6.35, 7.25)):
        P.append(Part("front", f"riser_strap{i}", [quad_side(A_E - 0.04, tl - 0.03, tl + 0.03, h - 0.02, h + 0.02)], DARK, side_plane(A_E - 0.04), "one-hole strap", "holds the riser every 0.9 m"))
    # the stub: the cross-wall cut down to 0.15 m across the deck (the cutaway the corridor uses)
    af = stub_far_a()
    P.append(Part("front", "stub_face", [quad_face(af, A_E, 0.0, STUB_H)], CONCRETE, face_plane(0.0), "the wall's 0.15 m stub, approach-side face", "the wall's line carried across the deck to the camera (cutaway)"))
    P.append(Part("front", "stub_top", [quad_top(af, A_E, 0.0, T_WALL, STUB_H)], CONCRETE, top_plane(STUB_H), "stub top, the wall's 0.40 m thickness", "the cut section, seen from above"))
    P.append(Part("front", "stub_angle_top", [quad_top(af, A_E, 0.0, 0.05, STUB_H + 0.003)], STEEL_WORN, top_plane(STUB_H + 0.003), "50 mm steel edge angle", "armours the approach-side edge"))
    P.append(Part("front", "stub_angle_face", [quad_face(af, A_E, STUB_H - 0.05, STUB_H, -0.004)], STEEL, face_plane(-0.004), "50 mm steel edge angle", "armours the approach-side edge"))
    P.append(Part("front", "stub_angle_far", [quad_top(af, A_E, T_WALL - 0.05, T_WALL, STUB_H + 0.003)], STEEL_WORN, top_plane(STUB_H + 0.003), "50 mm steel edge angle", "armours the lane-side edge"))
    P.append(Part("front", "stub_end", [quad_side(af, 0.0, T_WALL, 0.0, STUB_H)], STEEL, side_plane(af), "10 mm steel end plate", "closes the stub at the deck's front edge"))
    return P


def floor_coords(canvas=CV):
    A, B = M.rays(canvas)
    tt = (0.0 - A[1]) / np.where(np.abs(B[..., 1]) < 1e-9, -1e-9, B[..., 1])
    P = A + B * tt[..., None]
    rel = P - M.O
    return (rel * M.U).sum(-1), (rel * M.N).sum(-1)


def contact_shadows_front() -> np.ndarray:
    a, t = floor_coords()
    near = a <= A_E + 0.02
    sh = np.zeros(a.shape)
    sh = np.maximum(sh, np.where(near & (t < 0), 0.62 * np.exp(-np.clip(-t, 0, 50) / 0.10), 0))
    sh = np.maximum(sh, np.where(near & (t > T_WALL), 0.55 * np.exp(-np.clip(t - T_WALL, 0, 50) / 0.12), 0))
    sh = np.maximum(sh, np.where((a >= A_E) & (a <= A_N) & (t < 0), 0.58 * np.exp(-np.clip(-t, 0, 50) / 0.14), 0))
    af = stub_far_a()
    sh = sh * (a >= af - 0.02)
    return sh


# ---------------------------------------------------------------------------------------- alcove

D_POST = 0.15  # the posts stand on the deck's back rail, just behind the walk line
D_BAY = 1.30  # the bay's back face
POST_X = (545.0, 626.0)  # SentryBrain.COVER_MIN_X / COVER_MAX_X: the posts stand on them
H_HEAD = 2.70


def alcove_parts() -> list:
    P = []
    x0, x1 = POST_X

    def W(x, h, d):
        return np.array([x / M.PXM, h, d])

    P.append(Part("alcove", "bay_back", [poly([W(x0, 0, D_BAY), W(x1, 0, D_BAY), W(x1, H_HEAD, D_BAY), W(x0, H_HEAD, D_BAY)])], CONCRETE, front_plane(D_BAY),
                  "the bay's back wall, cast concrete, 1.15 m behind the posts", "the recess the TANK RELEASE stands in"))
    P.append(Part("alcove", "bay_side", [poly([W(x1, 0, D_POST), W(x1, 0, D_BAY), W(x1, H_HEAD, D_BAY), W(x1, H_HEAD, D_POST)])], CONCRETE,
                  M.Plane(W(x1, 0, 0), np.array([0, 0, 1.0]), M.EY, np.array([-1.0, 0, 0])), "the bay's right reveal", "the recess's side"))
    P.append(Part("alcove", "bay_floor", [poly([W(x0, 0, D_POST), W(x1, 0, D_POST), W(x1, 0, D_BAY), W(x0, 0, D_BAY)])], (0.16, 0.165, 0.175), top_plane(0.0),
                  "the bay's floor", "concrete floor of the recess"))
    P.append(Part("alcove", "header", [poly([W(x0 - 6, H_HEAD, D_POST - 0.01), W(x1 + 6, H_HEAD, D_POST - 0.01), W(x1 + 6, H_HEAD + 0.30, D_POST - 0.01), W(x0 - 6, H_HEAD + 0.30, D_POST - 0.01)])], GUNSHIP, front_plane(D_POST - 0.01),
                  "W310 steel header beam 2.3 m", "spans the bay; the wall above sits on it"))
    P.append(Part("alcove", "header_flange", [poly([W(x0 - 6, H_HEAD, D_POST - 0.02), W(x1 + 6, H_HEAD, D_POST - 0.02), W(x1 + 6, H_HEAD + 0.03, D_POST - 0.02), W(x0 - 6, H_HEAD + 0.03, D_POST - 0.02)])], STEEL, front_plane(D_POST - 0.02),
                  "its bottom flange edge", "beam flange"))
    for i, x in enumerate(POST_X):
        P.append(Part("alcove", f"post{i}", [poly([W(x - 3, 0.02, D_POST - 0.02), W(x + 3, 0.02, D_POST - 0.02), W(x + 3, H_HEAD, D_POST - 0.02), W(x - 3, H_HEAD, D_POST - 0.02)])], GUNSHIP, front_plane(D_POST - 0.02),
                      "W150 steel post, 150 mm flange, 2.7 m", "carries the header; marks where the bay's cover ends"))
        P.append(Part("alcove", f"post_web{i}", [poly([W(x - 0.6, 0.02, D_POST - 0.025), W(x + 0.6, 0.02, D_POST - 0.025), W(x + 0.6, H_HEAD, D_POST - 0.025), W(x - 0.6, H_HEAD, D_POST - 0.025)])], DARK, front_plane(D_POST - 0.025),
                      "flange edge shadow line", "the section's front flange edges"))
        P.append(Part("alcove", f"post_base{i}", [poly([W(x - 6, 0.0, D_POST - 0.06), W(x + 6, 0.0, D_POST - 0.06), W(x + 6, 0.03, D_POST - 0.06), W(x - 6, 0.03, D_POST - 0.06)])], STEEL, front_plane(D_POST - 0.06),
                      "base plate 300 x 300 x 30 mm", "bolts the post to the floor"))
        for j, dx in enumerate((-4.4, 4.4)):
            c = M.scr(W(x + dx, 0.045, D_POST - 0.07))
            P.append(Part("alcove", f"post_anchor{i}{j}", [("ellipse", c[0], c[1], 0.7, 0.45)], STEEL_WORN, front_plane(D_POST - 0.07), "M20 anchor nut", "holds the base plate down"))
    lx = 585.5
    P.append(Part("alcove", "bay_light_body", [poly([W(lx - 12, H_HEAD - 0.12, 0.6), W(lx + 12, H_HEAD - 0.12, 0.6), W(lx + 12, H_HEAD - 0.02, 0.6), W(lx - 12, H_HEAD - 0.02, 0.6)])], (0.42, 0.45, 0.47), front_plane(0.6),
                  "vapour-tight LED 0.6 m under the header", "lights the bay and the TANK RELEASE"))
    P.append(Part("alcove", "bay_light_lens", [poly([W(lx - 11.5, H_HEAD - 0.14, 0.62), W(lx + 11.5, H_HEAD - 0.14, 0.62), W(lx + 11.5, H_HEAD - 0.115, 0.62), W(lx - 11.5, H_HEAD - 0.115, 0.62)])], (1, 1, 1), front_plane(0.62),
                  "diffuser", "light source", emit=(0.86, 0.95, 1.0)))
    return P


def alcove_shadow() -> np.ndarray:
    X, Y = CV.grid()
    sh = np.zeros(X.shape)
    for x in POST_X:
        dy = Y - 439.4
        inside = (dy >= -0.5) & (np.abs(X - x) <= 7.5)
        sh = np.maximum(sh, np.where(inside, 0.55 * np.exp(-np.clip(dy, 0, 50) / 2.0) * np.clip((7.5 - np.abs(X - x)) / 2.0, 0, 1), 0))
    return sh


# ---------------------------------------------------------------------------------------- main

def close_seams(a):
    """Two anti-aliased polygons that share an edge leave a hairline of partial alpha (each covers
    about half of the edge pixel): a pixel whose neighbours 2 px either side, across or along, are
    both solid is solid too."""
    from scipy import ndimage
    out = a.copy()
    for ax in (0, 1):
        lo = np.roll(a, 2, axis=ax)
        hi = np.roll(a, -2, axis=ax)
        both = np.minimum(lo, hi)
        out = np.maximum(out, np.where(both > 0.98, both, 0))
    return out


def composite_layer(lay, sh=None):
    lin, a = lay["lin"], lay["a"]
    if sh is not None:
        out_a = a + sh * (1 - a)
        w = np.where(out_a > 0, sh * (1 - a) / np.maximum(out_a, 1e-6), 0)
        lin = lin * (1 - w[..., None]) + np.array([0.0008, 0.0015, 0.0025]) * w[..., None]
        a = out_a
    return lin, a


def _lying_order() -> list:
    rf = rubble_front_parts()
    return [p for p in rf if p.name == "dust_film"] + lying_parts() + [p for p in rf if p.name != "dust_film"]


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    groups = {
        "wall": wall_parts(), "leaf": leaf_parts(), "leafbreak": leafbreak_parts(), "cracks": crack_parts(),
        "hole": hole_parts() + rubble_back_parts(), "damage": damage_parts(), "lying": _lying_order(),
        "front": front_parts(), "alcove": alcove_parts(),
    }
    spec = {"camera": {"vp": [M.VPX, M.HORIZON], "d0_m": M.D0, "px_per_m": M.PXM, "floor_y": M.FLOOR_Y, "vp2": [round(M.VP2_X, 2), M.HORIZON], "turn_deg": 17.0},
            "model": {"origin_walkline": [472.0, 440.0], "a_far_jamb": A_F, "a_near_jamb": A_N, "a_wall_end": A_E, "a_back": A_BACK, "wall_t_m": T_WALL,
                      "opening_m": [M.W_OPEN, H_OPEN], "leaf_t_m": [LEAF_T0, LEAF_T1], "frame_flange_m": FR},
            "canvas": {"world_box": [CV.x0, CV.y0, CV.x0 + CV.w / CV.ppw, CV.y0 + CV.h / CV.ppw], "px_per_world": CV.ppw},
            "lamps": [{"name": l.name, "pos_m": [round(float(v), 3) for v in l.pos], "screen": [round(v, 1) for v in l.screen()], "note": l.note} for l in M.LAMPS],
            "parts": {}}
    hole_face = mask_of([quad_face(A_N, A_F, 0.0, H_OPEN)])
    for name, parts in groups.items():
        lay = M.render(parts)[name]
        if name in ("wall", "front", "alcove", "leaf", "leafbreak", "hole", "lying", "damage"):
            lay["a"] = close_seams(lay["a"])
        sh = None
        if name == "wall":
            lay["a"] = lay["a"] * (1 - hole_face)
            lay["masks"]["HOLE"] = hole_face
        if name == "front":
            sh = contact_shadows_front() * (1 - np.clip(lay["a"], 0, 1))
            tl = T_WALL / 2
            lcx, lcy = scr(pt(A_E - 0.12, LAMP_H, tl))
            glass = mask_of([("ellipse", lcx, lcy, 2.0, 2.5)])
            guard = np.clip(sum(lay["masks"][f"lamp_guard{i}"] for i in range(3)), 0, 1)
            gh = np.clip(glass - guard, 0, 1)
            lay["a"] = lay["a"] * (1 - gh)
            lay["masks"]["GLASS_HOLE"] = gh
            spec["lamp_glass_centre"] = [round(lcx, 3), round(lcy, 3)]
        if name == "alcove":
            sh = alcove_shadow() * (1 - np.clip(lay["a"], 0, 1))
        if sh is not None:
            lay["masks"]["contact_shadow"] = sh
        lin, a = composite_layer(lay, sh)
        M.save_rgba(lin, a, os.path.join(OUT, f"design-{name}.png"))
        for mn, m in lay["masks"].items():
            M.save_mask(m, os.path.join(OUT, "masks", f"{name}--{mn}.png"))
        M.save_mask(a, os.path.join(OUT, "masks", f"{name}--ALPHA.png"))
        seen = {}
        for p in parts:
            seen.setdefault(p.name, {"name": p.name, "dims": p.dims, "job": p.job})
        spec["parts"][name] = list(seen.values())
    af = stub_far_a()
    spec["screen"] = {
        "far_jamb_foot": [round(v, 2) for v in scr(pt(A_F, 0))], "near_jamb_foot": [round(v, 2) for v in scr(pt(A_N, 0))],
        "opening_top": [[round(v, 2) for v in scr(pt(A_F, H_OPEN))], [round(v, 2) for v in scr(pt(A_N, H_OPEN))]],
        "column_at_1m": [round(scr(pt(A_N - FR, 1.0, -0.008))[0], 2), round(scr(pt(A_E, 1.0, T_WALL))[0], 2)],
        "back_corner_x": round(scr(pt(A_BACK, 3.0))[0], 2), "stub_line": [[round(v, 2) for v in scr(pt(A_E, 0))], [round(v, 2) for v in scr(pt(af, 0))]],
        "charge_line_x": round(scr(pt(A_CL, 2.5, -0.09))[0], 2),
    }
    M.write_json(os.path.join(OUT, "spec.json"), spec)
    print({k: spec["screen"][k] for k in spec["screen"]})


if __name__ == "__main__":
    main()
