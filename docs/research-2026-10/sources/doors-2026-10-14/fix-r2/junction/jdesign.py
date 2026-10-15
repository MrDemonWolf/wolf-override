"""Construction design of the Service Junction's blast door (scratch only). Every part is an exact
shape from measured numbers in the room's own camera (jmodel.py), with a job; nothing here comes
from an image tool. Writes design/ : one flat-shaded render per layer, one mask per part, contact
shadows, spec.json and composites over the room's plates.

The door: a hinged blast door (single steel leaf, concrete-filled, 2.3 x 2.6 m clear, 0.30 m thick,
in the manner of the Swiss PTO1 armoured gate, 2.4 x 2.1 m x 0.20 m) in a 0.40 m cast-concrete
cross-wall that stands ACROSS the walkway, its approach face turned 17 degrees to the camera. It is
locked from the lane side ("sealed from the other side"): its locking levers are on the lane face and
its bolts throw into keepers at the head, sill and jambs (UFGS 08 39 54 2.2.2.1). Fix round 2 (review
r2, S3): it is HUNG on the junction side, on three full-surface hinges (UFGS 08 39 54 2.2.1: "Blast door
hinges are normally full surface"; a blast door opens toward the side it is built to resist, so a blast
from that side seats the leaf in its frame): their frame leaves on the hinge jamb's flange, their door
leaves on the leaf's approach face, their knuckles standing proud of the face at the jamb. The approach
face also shows the two capped lever spindles whose approach-side levers are removed, the frame, and a
guarded red status lamp on the wall's end. The
pressure line from the valve rises up the wall and enters it through a welded penetration plate
beside the door: it feeds the frame on the lane side. Overloaded, the frame cavity bursts, the leaf's
locking bolts shear at the latch (far) jamb, its hinges tear off the hinge jamb (their knuckles shear,
the door leaves go with the leaf, the frame leaves stay on the jamb), and the leaf is thrown into the
lane and falls flat on the lane's deck in front of the release bay (ASTM F2927 response category IV:
the leaf separates from the frame, within 3 m). Fix round 2 (N4): the readable damage is where nothing
covers it, between 0.3 and 2.0 m: the near column's hinge jamb (torn hinges, the spalled corner with its
bars, the arris angle torn loose) and the latch jamb's face plate torn off and bent into the opening. The back-blast
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

PIPE_DK = (0.085, 0.088, 0.095)  # dark painted steel pipe, as the valve's
A_CL = 1.40 / math.cos(M.THETA)  # the charge line rises 1.4 m behind the walk line (x ~457)
CL_R = 0.08  # the 150 mm line (fix round 1: matches the spool from the valve)
H_CL_TOP = 3.08
# fix round 1 (C2): the latch-side frame's approach flange is a 300 mm steel face plate (a blast door's
# heavy welded frame, HET 02: "heavy steel frame fixed with 80 mm anchors"), so the frame reads beside
# the leaf; the head and the hinge-side flanges stay 180 mm.
FRF = 0.30
# (S2) the valve's outlet: its painted elbow ends in a down-facing flange at world x ~452..469, y ~417
# (h 0.57 m) on the walk line; a flanged spool runs down from it to a long-radius elbow at h 0.30 that
# turns back into the charge line's riser (A_CL, 1.4 m behind the walk line), which climbs the wall to
# the penetration plate. Measured from the valve image: VALVE_SCALE 0.2, flange centre at source x 470.
OUT_X = 460.6  # outlet flange centre (world px, walk line)
OUT_H0 = 0.545  # its face (m above the deck): source row 392
SPOOL_R = 0.058


def _noise2(a, h, scale_a, scale_h, seed):
    """Smooth value noise over the wall's (a, h) metres: sum of a few seeded sines (deterministic)."""
    rng = np.random.default_rng(seed)
    out = np.zeros_like(a)
    for k in range(6):
        fa, fh = rng.uniform(0.6, 1.6) / scale_a, rng.uniform(0.6, 1.6) / scale_h
        ph = rng.uniform(0, 2 * math.pi, 2)
        out += np.sin(a * fa * 2 * math.pi + ph[0]) * np.sin(h * fh * 2 * math.pi + ph[1]) / (k + 1)
    return out / 1.5


def concrete_wear(P_, la, lb):
    """Designed wear on the cast face (fix round 1, M1): what use and water do to it, nothing else.
    la = a (m along the face), lb = h (m up). Albedo multiplier.
      - a damp band at the floor joint (water off the deck wicks up 0.1-0.25 m, irregular top);
      - a darker band of seepage along each pour joint's underside (cold joints leak);
      - leach streaks only under the two penetrations (the charge line's plate, the main's sleeve);
      - broad board-form mottle +-6 % (cast in lifts against boards: uneven, never speckle);
      - the face falls a little darker toward the slab, away from every fixture."""
    a, h = la, lb
    f = 1.0 + 0.06 * _noise2(a, h, 1.4, 0.9, 11) + 0.025 * np.sign(np.sin(h / 0.15 * math.pi)) * (0.5 + 0.5 * _noise2(a, h, 3.0, 2.0, 12))
    top = 0.16 + 0.08 * (0.5 + 0.5 * _noise2(a, h * 0 + 1, 0.5, 1.0, 13))
    f = f * (1.0 - 0.38 * np.clip(1.0 - h / top, 0, 1) ** 0.7)
    for j in (4.05, 6.75):
        f = f * (1.0 - 0.12 * np.exp(-(((h - (j - 0.07)) / 0.07) ** 2)) * (0.6 + 0.4 * _noise2(a, h, 0.7, 1.0, 14)))
    for (ac, wd, h_top, seed) in ((A_CL, 0.22, 2.86, 15), (A_BACK - 0.54, 0.45, 3.45, 16)):
        across = np.abs(a - ac) / wd
        streak = np.clip(1.0 - across, 0, 1) * (0.55 + 0.45 * np.sin(a * 41.0 + seed) ** 2)
        down = np.clip((h_top - h) / 1.6, 0, 1) * (h < h_top)
        f = f * (1.0 - 0.22 * streak * np.exp(-((1.0 - down) * 0.0)) * np.clip(1.0 - (h_top - h) / 2.4, 0, 1) * (h < h_top))
    return f


def wall_parts() -> list:
    P = []
    fp = face_plane(0.0)
    P.append(Part("wall", "face_far_column", [quad_face(A_F + FRF, A_BACK, 0.0, H_OPEN + FR)], CONCRETE, fp,
                  "cast reinforced concrete, 0.40 m thick; 4.6 m of face from the far jamb's frame back to the room's back wall", "the cross-wall the door is set in; carries the charge line",
                  mod=concrete_wear))
    P.append(Part("wall", "face_upper", [quad_face(A_E, A_BACK, H_OPEN + FR, H_TOP)], CONCRETE, fp,
                  "the same wall over the door head, up to the slab", "closes the junction off from the lane", mod=concrete_wear))
    for i, h in enumerate((4.05, 6.75)):
        P.append(Part("wall", f"pour_joint{i}", [quad_face(A_E + 0.05, A_BACK, h - 0.012, h + 0.012)], CONCRETE_DK, fp,
                      "pour line between concrete lifts", "construction joint"))
    P.append(Part("wall", "back_corner", [quad_face(A_BACK - 0.08, A_BACK, 0.0, H_TOP, -0.004)], CONCRETE_DK, M.face_plane(-0.004),
                  "internal corner with the room's back wall", "where the cross-wall meets the back wall"))
    # the steel channel frame cast into the opening: its approach flanges (the near one is in front)
    P.append(Part("wall", "frame_far", [quad_face(A_F, A_F + FRF, 0.0, H_OPEN + FR, -0.008)], GUNSHIP, face_plane(-0.008),
                  "welded steel frame, 300 mm approach face plate on the latch jamb, anchored into the concrete", "lines the latch jamb; carries the bolt keepers"))
    P.append(Part("wall", "frame_head", [quad_face(A_N - FR, A_F + FRF, H_OPEN, H_OPEN + FR, -0.008)], GUNSHIP, face_plane(-0.008),
                  "steel channel head, 180 mm flange", "lines the head"))
    # threshold: a steel plate across the opening and 0.35 m out onto the approach deck (C2)
    # fix round 2 (S4): a steel plate on a wet deck nobody crosses (the door is sealed): the deck's own value,
    # its edge a dull steel line, not a worn bright nosing
    P.append(Part("wall", "threshold", [quad_top(A_N - 0.05, A_F + 0.10, -0.35, 0.0, 0.006)], (0.13, 0.135, 0.145), top_plane(0.006),
                  "steel threshold plate 2.5 x 0.75 m, 12 mm, chequer-free (its approach strip; the rest is under the leaf)", "metal threshold of the opening; the leaf's drop seal lands on it"))
    P.append(Part("wall", "threshold_nose", [quad_face(A_N - 0.05, A_F + 0.10, 0.0, 0.006, -0.35)], (0.17, 0.175, 0.185), face_plane(-0.35),
                  "its front edge, dull steel", "the plate's edge on the deck"))
    # the door light: vapour-tight fitting on two brackets over the head
    for i, da in enumerate((-0.42, 0.42)):
        P.append(Part("wall", f"light_bracket{i}", [poly([pt(A_MID + da, 3.30, -0.01), pt(A_MID + da, 3.30, -0.32), pt(A_MID + da, 3.26, -0.32), pt(A_MID + da, 3.26, -0.01)])], HOUSING,
                      M.Plane(pt(A_MID + da, 0, 0), M.N, M.EY, -M.U), "flat bracket 0.3 m", "holds the fitting off the wall"))
    P.append(Part("wall", "light_body", [quad_face(A_MID - 0.6, A_MID + 0.6, 3.16, 3.28, -0.34)], (0.42, 0.45, 0.47), face_plane(-0.34),
                  "vapour-tight LED fitting 1.2 x 0.12 m", "lights the door, the threshold and the approach"))
    # fix round 2 (human: "a stray white tick with no fitting"): seen from 7 m up, a batten on brackets shows
    # its top and front; its opal diffuser glows only along the front's lower edge, softly, under the grey
    # body and its end caps
    P.append(Part("wall", "light_lens", [quad_face(A_MID - 0.56, A_MID + 0.56, 3.155, 3.175, -0.35)], (1, 1, 1), face_plane(-0.35),
                  "diffuser's lower edge, lit", "the light source (painted lit, static)", emit=(0.40, 0.45, 0.48)))
    for i, da in enumerate((-0.6, 0.6)):
        P.append(Part("wall", f"light_cap{i}", [quad_face(A_MID + da - 0.03, A_MID + da + 0.03, 3.15, 3.29, -0.36)], HOUSING, face_plane(-0.36),
                      "end cap with its cable gland", "seals the batten"))
    P.append(Part("wall", "light_feed", [quad_face(A_MID - 0.62, A_MID - 0.59, 3.28, 3.57, -0.03), quad_face(A_E, A_MID - 0.59, 3.545, 3.57, -0.03)], STEEL, face_plane(-0.03),
                  "20 mm rigid conduit", "feeds the door light from the junction box on the column's end"))
    P.append(Part("wall", "light_feed_strap", [quad_face(A_MID - 1.05, A_MID - 0.97, 3.53, 3.585, -0.04)], DARK, face_plane(-0.04),
                  "one-hole strap", "holds the conduit within 0.9 m of the fitting"))
    # the charge line: the valve's outlet, down, back and up the wall into the penetration plate
    # the riser: a 150 mm pipe standing 0.09 m off the face, drawn as the cylinder it is (its full
    # diameter on screen whatever the wall's turn), dark painted steel like the valve's
    rc = pt(A_CL, 0.0, -0.09 - CL_R)
    rcx = rc[0]
    P.append(Part("wall", "charge_line", [poly([np.array([rcx - CL_R, 0.40, rc[2]]), np.array([rcx + CL_R, 0.40, rc[2]]), np.array([rcx + CL_R, H_CL_TOP, rc[2]]), np.array([rcx - CL_R, H_CL_TOP, rc[2]])])],
                  PIPE_DK, front_plane(float(rc[2])),
                  "150 mm steel pipe, the valve's outlet riser", "carries the overloaded line from the valve through the wall to the door's frame on the lane side",
                  mod=lambda P_, la, lb: 0.45 + 0.9 * np.clip(1 - ((la - rcx + 0.025) / CL_R) ** 2, 0, 1) ** 1.5))
    # (S2) the valve's outlet (its painted pipe end, 0.36 m across, faces down at h 0.545) carries on:
    # a mating flange, a concentric reducer to the 150 mm line, a short spool down, a long-radius elbow
    # back toward the wall, a 1 m run at h 0.22 behind the valve's base and an elbow up into the riser.
    ox = OUT_X / M.PXM

    def W3(x, h, d):
        return np.array([x, h, d])

    def cyl(pts, r):  # a pipe along a polyline of 3D centre points, as a band in the screen (outline only)
        L, R = [], []
        for k, c in enumerate(pts):
            c0 = pts[max(k - 1, 0)]
            c1 = pts[min(k + 1, len(pts) - 1)]
            p0, p1 = np.array(scr(c0)), np.array(scr(c1))
            t = p1 - p0
            t = t / (np.linalg.norm(t) or 1.0)
            nrm = np.array([-t[1], t[0]])
            cc = np.array(scr(c))
            rp = r * M.PXM * M.D0 / (M.D0 + c[2])
            L.append(tuple(cc + nrm * rp))
            R.append(tuple(cc - nrm * rp))
        return L + R[::-1]

    def pipe_mod(cx_m, r):
        return lambda P_, la, lb: 0.45 + 0.9 * np.clip(1 - ((la - cx_m + 0.3 * r) / r) ** 2, 0, 1) ** 1.5
    RO, RL = 0.18, 0.08
    h_fl = OUT_H0
    P.append(Part("wall", "spool_flange", [poly([W3(ox - 0.245, h_fl, 0.0), W3(ox + 0.245, h_fl, 0.0), W3(ox + 0.245, h_fl - 0.05, 0.0), W3(ox - 0.245, h_fl - 0.05, 0.0)])], HOUSING, front_plane(0.0),
                  "mating flange 490 mm, bolted to the valve's outlet flange", "joins the line to the valve"))
    P.append(Part("wall", "spool_reducer", [poly([W3(ox - RO, h_fl - 0.05, 0.0), W3(ox + RO, h_fl - 0.05, 0.0), W3(ox + RL, h_fl - 0.17, 0.0), W3(ox - RL, h_fl - 0.17, 0.0)])], PIPE_DK, front_plane(0.0),
                  "concentric reducer 350 x 150 mm", "steps the valve's outlet down to the charge line", mod=pipe_mod(ox, RO)))
    P.append(Part("wall", "spool", [poly([W3(ox - RL, h_fl - 0.17, 0.0), W3(ox + RL, h_fl - 0.17, 0.0), W3(ox + RL, 0.40, 0.0), W3(ox - RL, 0.40, 0.0)])], PIPE_DK, front_plane(0.0),
                  "150 mm spool", "carries the line down from the valve", mod=pipe_mod(ox, RL)))
    rb = 0.18
    e1 = [W3(ox, 0.40 - rb * math.sin(math.pi / 2 * k / 8), rb - rb * math.cos(math.pi / 2 * k / 8)) for k in range(9)]
    run = [W3(ox + (A_CL * math.sin(M.THETA) * 0 + (pt(A_CL, 0, -0.09)[0] - ox)) * k / 6, 0.22, rb + (pt(A_CL, 0, -0.09)[2] - 2 * rb) * k / 6) for k in range(7)]
    rx, rz = pt(A_CL, 0, -0.09)[0], pt(A_CL, 0, -0.09)[2]
    e2 = [W3(rx, 0.40 - rb * math.cos(math.pi / 2 * k / 8), rz - rb + rb * math.sin(math.pi / 2 * k / 8)) for k in range(9)]
    P.append(Part("wall", "spool_run", [cyl(run + e2, RL)], PIPE_DK, front_plane(0.8), "150 mm run and elbow up, behind the valve's base", "takes the line back to the riser", mod=lambda P_, la, lb: 0.75))
    P.append(Part("wall", "spool_elbow", [cyl(e1, RL)], PIPE_DK, front_plane(0.1), "150 mm long-radius elbow", "turns the line back toward the wall",
                  mod=pipe_mod(ox, RL)))
    for i, hh in enumerate((h_fl - 0.17, 0.40)):
        P.append(Part("wall", f"spool_joint{i}", [poly([W3(ox - 0.13, hh + 0.02, -0.001), W3(ox + 0.13, hh + 0.02, -0.001), W3(ox + 0.13, hh - 0.02, -0.001), W3(ox - 0.13, hh - 0.02, -0.001)])], HOUSING, front_plane(-0.001),
                      "flange pair 260 mm", "bolted joint of the spool"))
    P.append(Part("wall", "riser_foot", [quad_face(A_CL - 0.085, A_CL + 0.085, 0.0, 0.06, -0.12)], HOUSING, face_plane(-0.12),
                  "pipe support: welded base plate 170 mm on the deck", "carries the riser's weight"))
    P.append(Part("wall", "charge_plate", [quad_face(A_CL - 0.24, A_CL + 0.24, 2.86, 3.32, -0.006)], STEEL, face_plane(-0.006),
                  "6 mm welded penetration plate 0.48 x 0.46 m, 150 mm past the pipe", "where the line passes the wall"))
    # at the top the riser turns into the wall: a long-radius elbow and a 0.17 m stub through the collar
    top_pts = [rc + np.array([0, H_CL_TOP - 0.12, 0]) + 0.12 * (math.sin(math.pi / 2 * k / 6) * M.N + (1 - math.cos(math.pi / 2 * k / 6)) * M.EY) for k in range(7)]
    top_pts.append(pt(A_CL, H_CL_TOP, -0.005))
    band_l, band_r = [], []
    for k, c in enumerate(top_pts):
        c0, c1 = top_pts[max(k - 1, 0)], top_pts[min(k + 1, len(top_pts) - 1)]
        t2 = np.array(scr(c1)) - np.array(scr(c0))
        t2 = t2 / (np.linalg.norm(t2) or 1)
        nr = np.array([-t2[1], t2[0]]) * CL_R * M.PXM * M.D0 / (M.D0 + c[2])
        band_l.append(tuple(np.array(scr(c)) + nr))
        band_r.append(tuple(np.array(scr(c)) - nr))
    P.append(Part("wall", "charge_entry", [band_l + band_r[::-1]], PIPE_DK, face_plane(-0.09), "150 mm elbow into the wall", "takes the line through the wall to the door's frame on the lane side",
                  mod=lambda P_, la, lb: 0.75))
    P.append(Part("wall", "charge_collar", [quad_face(A_CL - 0.12, A_CL + 0.12, H_CL_TOP - 0.12, H_CL_TOP + 0.12, -0.012)], HOUSING, face_plane(-0.012),
                  "welded sleeve collar 240 mm", "seals the pipe to the plate"))
    for i, h in enumerate((1.25, 2.05)):
        P.append(Part("wall", f"charge_clamp{i}", [poly([np.array([rcx - CL_R - 0.02, h - 0.03, rc[2] - 0.01]), np.array([rcx + CL_R + 0.02, h - 0.03, rc[2] - 0.01]), np.array([rcx + CL_R + 0.02, h + 0.03, rc[2] - 0.01]), np.array([rcx - CL_R - 0.02, h + 0.03, rc[2] - 0.01])])], DARK, front_plane(float(rc[2]) - 0.01),
                      "U-bolt pipe clamp on a stand-off bracket", "holds the riser to the wall"))
    # the room's big pipe (mid plate, x <= 420 at y 224..277) passes the wall at its back corner
    P.append(Part("wall", "pipe_sleeve_plate", [quad_face(A_BACK - 1.05, A_BACK - 0.03, 3.45, 5.40, -0.006)], STEEL, face_plane(-0.006),
                  "6 mm welded penetration plate round the 1.3 m main", "where the junction's main passes into the lane"))
    return P


# ---------------------------------------------------------------------------------------- hinges
# fix round 2 (S3, N4): three full-surface blast-door hinges on the junction side of the hinge (near) jamb,
# the thrown leaf's torn knuckles at the same heights (lying_parts)
HINGE_H = (0.40, 1.30, 2.20)
HINGE_LEN = 0.30
HINGE_LEAF_W = 0.22
KN_R = 0.040  # knuckle barrel radius (80 mm)
KN_A, KN_T = A_N - 0.004, -0.055  # the barrel's axis: at the jamb's edge, standing 55 mm proud of the face


def knuckle_poly(h0, h1):
    """A vertical knuckle barrel (a cylinder seen side-on: its full diameter on screen)."""
    c0 = pt(KN_A, h0, KN_T)
    c1 = pt(KN_A, h1, KN_T)
    x0, y0 = scr(c0)
    x1, y1 = scr(c1)
    r = KN_R * M.PXM * M.D0 / (M.D0 + c0[2])
    return [(x0 - r, y0), (x0 + r, y0), (x1 + r, y1), (x1 - r, y1)]


def knuckle_mod(P_, la, lb):
    return 1.0


def hinge_frame_parts(blown: bool) -> list:
    """The jamb's halves of the hinges: frame leaves on the near flange; sealed, the whole knuckle stack
    (five 60 mm knuckles, the frame's three and the door's two, on one pin); blown, only the frame's
    three, the pin sheared in the two gaps (bright fracture stubs), the middle frame leaf torn half off
    its welds and bent out."""
    P = []
    seg = HINGE_LEN / 5
    for i, hc in enumerate(HINGE_H):
        h0 = hc - HINGE_LEN / 2
        bent = blown and i == 1
        if bent:
            P.append(Part("front", f"col_hinge_frame{i}", [poly([pt(A_N - FR + 0.02, h0, -0.020), pt(A_N - 0.004, h0, -0.020), pt(A_N - 0.004, h0 + HINGE_LEN, -0.12), pt(A_N - FR + 0.04, h0 + HINGE_LEN, -0.10)])], STEEL_WORN,
                          M.general_plane(pt(A_N - FR + 0.02, h0, -0.02), pt(A_N - 0.004, h0, -0.02), pt(A_N - 0.004, h0 + HINGE_LEN, -0.12)),
                          "full-surface hinge, frame leaf, torn half off its welds and bent out 100 mm", "what the leaf tore off the jamb"))
        else:
            P.append(Part("front", f"col_hinge_frame{i}", [quad_face(A_N - FR + 0.02, A_N - 0.004, h0, h0 + HINGE_LEN, -0.020)], HOUSING, face_plane(-0.020),
                          "full-surface hinge, frame leaf 16 mm x 0.30 x 0.16 m, welded to the frame flange", "hangs the leaf (UFGS 08 39 54 2.2.1)"))
        for k in range(5):
            mine = k % 2 == 0  # the frame's knuckles: 1st, 3rd, 5th
            if blown and not mine:
                # the door's knuckle went with the leaf: the pin sheared here
                pc = hc - HINGE_LEN / 2 + (k + 0.5) * seg
                x0, y0 = scr(pt(KN_A, pc - 0.02, KN_T))
                x1, y1 = scr(pt(KN_A, pc + 0.02, KN_T))
                P.append(Part("front", f"col_hinge_pin{i}_{k}", [[(x0 - 0.7, y0), (x0 + 0.7, y0), (x1 + 0.9, y1), (x1 - 0.5, y1)]], (0.62, 0.63, 0.65), front_plane(float(pt(KN_A, pc, KN_T)[2])),
                              "the 32 mm hinge pin, sheared (bright fracture)", "the pin that failed"))
                continue
            ka, kb = h0 + k * seg + 0.003, h0 + (k + 1) * seg - 0.003
            P.append(Part("front", f"col_hinge_knuckle{i}_{k}", [knuckle_poly(ka, kb)], STEEL if mine else GUNSHIP, front_plane(float(pt(KN_A, ka, KN_T)[2])),
                          "hinge knuckle 80 mm x 60 mm" + ("" if mine else " (the door's)"), "the hinge's barrel round its pin"))
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
    # fix round 2 (S3): the door leaves of the three full-surface hinges, 16 mm plate 0.30 x 0.22 m, on the
    # leaf's approach face at its hinge edge
    for i, hc in enumerate(HINGE_H):
        P.append(Part(layer, f"leaf_hinge{i}", [quad(A_N + 0.015, A_N + 0.015 + HINGE_LEAF_W, hc - HINGE_LEN / 2, hc + HINGE_LEN / 2)], HOUSING, pl,
                      "full-surface hinge, door leaf 16 mm x 0.30 x 0.22 m, welded and bolted to the skin", "hangs the leaf (UFGS 08 39 54 2.2.1)"))
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


def _crack_lines(rng, starts, steps=(3, 6), step_len=(0.08, 0.2), width=0.32, t=-0.002):
    lines = []
    for (a, h, ang0) in starts:
        pts = [(a, h)]
        ang = ang0
        for k in range(int(rng.integers(*steps))):
            step = rng.uniform(*step_len)
            ang += rng.normal(0, 0.35)
            pts.append((pts[-1][0] + math.cos(ang) * step, pts[-1][1] + math.sin(ang) * step))
        for p0, p1 in zip(pts, pts[1:]):
            lines.append(seg_poly(scr(pt(p0[0], p0[1], t)), scr(pt(p1[0], p1[1], t)), width))
        if len(pts) > 3 and rng.uniform() < 0.7:  # a branch
            q = pts[len(pts) // 2]
            ang = ang0 + rng.choice([-0.7, 0.7])
            q2 = (q[0] + math.cos(ang) * 0.25, q[1] + math.sin(ang) * 0.25)
            lines.append(seg_poly(scr(pt(q[0], q[1], t)), scr(pt(q2[0], q2[1], t)), width * 0.8))
    return lines


# where cracks start (Liu et al., NDIA 2018: from the opening's corners) and which way they run (in
# the wall's (a, h): +a is away from the doorway on the latch side, up is +h)
HEAD_FAR = (A_F + FRF, H_OPEN + FR)
HEAD_NEAR = (A_N - FR, H_OPEN + FR)


def crack_parts() -> list:
    """Breaking overlay: cracks in the approach face running from the frame's corners and along the
    latch jamb, where the frame's anchors are pulling out."""
    rng = np.random.default_rng(RNG_SEED + 1)
    starts = [(A_F + FRF, 0.35, 0.3), (A_F + FRF, 1.3, 0.2), (A_F + FRF, 2.2, 0.5), (HEAD_FAR[0], HEAD_FAR[1], 0.8),
              (A_MID, H_OPEN + FR, math.pi / 2), (HEAD_NEAR[0], HEAD_NEAR[1], math.pi - 0.8)]
    return [Part("cracks", "cracks", _crack_lines(rng, starts, width=0.45), CONCRETE_DK, face_plane(-0.002), "hairline-to-3 mm cracks", "the frame's anchors pulling out of the concrete")]


# ---------------------------------------------------------------------------------------- blown

def hole_parts() -> list:
    P = []

    def reveal_mod(P_, la, lb):  # la: t into the wall, lb: h. Soot from the vented gas up the liner, buckled waves
        soot = 0.45 + 0.55 * np.clip(1.0 - np.exp(-((lb - 2.0) / 0.9) ** 2) * 0.6, 0, 1)
        wave = 1.0 + 0.10 * np.sin(lb / 0.32 * math.pi + la * 6.0)
        return soot * wave
    P.append(Part("hole", "reveal_far", [quad_side(A_F, 0.0, T_WALL, 0.0, H_OPEN)], (0.15, 0.155, 0.165), side_plane(A_F),
                  "the latch jamb's frame web: 6 mm steel liner over the 0.40 m wall, buckled and sooted", "the jamb the bolts sheared out of; seen through the empty opening", mod=reveal_mod))
    for i, h in enumerate((0.40, 1.30, 2.20)):
        P.append(Part("hole", f"keeper{i}", [poly([pt(A_F - 0.004, h - 0.10, 0.08), pt(A_F - 0.004, h - 0.09, 0.29), pt(A_F - 0.004, h + 0.11, 0.30), pt(A_F - 0.004, h + 0.12, 0.10), pt(A_F - 0.004, h + 0.02, 0.06)])], DARK, side_plane(A_F - 0.004),
                      "torn bolt keeper pocket, its cast-in box ripped open", "where a locking bolt was"))
        P.append(Part("hole", f"keeper_tab{i}", [poly([pt(A_F - 0.004, h + 0.11, 0.08), pt(A_F - 0.004, h + 0.12, 0.30), pt(A_F - 0.16, h + 0.20, 0.27), pt(A_F - 0.15, h + 0.17, 0.11)])],
                      STEEL_WORN, side_plane(A_F - 0.08), "keeper lip torn and bent out 150 mm", "torn steel at the pocket"))
    # the liner's front edge, torn loose and curled out from the jamb above the top keeper
    P.append(Part("hole", "liner_curl", [poly([pt(A_F - 0.004, 1.55, 0.0), pt(A_F - 0.004, H_OPEN, 0.0), pt(A_F - 0.22, H_OPEN - 0.05, -0.06), pt(A_F - 0.18, 1.75, -0.03)])], (0.20, 0.205, 0.215),
                  M.general_plane(pt(A_F, 1.55, 0.0), pt(A_F, H_OPEN, 0.0), pt(A_F - 0.2, H_OPEN, -0.05)), "the liner's front edge, torn off its anchors and curled 0.2 m into the opening", "frame damage"))
    # fix round 2 (N4): the lane seen through the doorway: the cross-wall shades the lane right behind it
    # (the lane's fittings are further along), so its back wall and deck there are darker than the lit
    # lane beyond; a soft film, darkest low and at the jambs
    def lane_fn(X, Y):
        fx, fy = scr(pt(A_F, 0.0, T_WALL))
        nx, _ = scr(pt(A_N, 0.0, T_WALL))
        u = np.clip((X - fx) / max(nx - fx, 1.0), 0, 1)
        low = np.clip((Y - (fy - 104.0)) / 104.0, 0, 1)
        return 0.38 + 0.22 * low + 0.12 * (1 - np.sin(np.pi * u))
    P.append(Part("hole", "lane_shade", [quad_side(A_F - 0.0005, T_WALL, T_WALL + 0.001, 0.0, H_OPEN), quad_face(A_N, A_F, 0.0, H_OPEN, T_WALL + 0.002)], (0.004, 0.006, 0.009), face_plane(T_WALL + 0.002),
                  "the cross-wall's shadow on the lane behind it, seen through the doorway", "the lane's own value at that depth", clip=soft_field(lane_fn)))
    P.append(Part("hole", "threshold_full", [quad_top(A_N - 0.05, A_F + 0.10, -0.35, T_WALL + 0.06, 0.006)], (0.25, 0.255, 0.27), top_plane(0.006),
                  "steel threshold plate 2.5 x 0.75 m, bowed up 60 mm along the leaf's line", "metal threshold of the opening",
                  mod=lambda P_, la, lb: 1.0 + 0.45 * np.exp(-((lb - 0.20) / 0.06) ** 2)))
    return P


def damage_parts() -> list:
    """Blown overlay on the approach face (drawn over the wall layer). Sized to read at the play zoom
    (fix round 1, M3): every feature is at least 3-4 world px."""
    P = []
    rng = np.random.default_rng(RNG_SEED + 2)

    def ragged(pts_ah, jit=0.04, n_sub=3):
        out = []
        for (a0, h0), (a1, h1) in zip(pts_ah, pts_ah[1:] + pts_ah[:1]):
            for k in range(n_sub):
                u = k / n_sub
                out.append(pt(a0 + (a1 - a0) * u + rng.normal(0, jit), h0 + (h1 - h0) * u + rng.normal(0, jit), -0.001))
        return poly(out)
    xf = A_F + FRF  # the frame's outer edge on the latch side
    # the spall bite: deepest at the latch jamb (where the bolts tore out), up the jamb and over the head
    bite_latch = [(xf - 0.02, 0.05), (xf + 0.35, 0.10), (xf + 0.62, 0.55), (xf + 0.85, 1.05), (xf + 0.70, 1.55), (xf + 0.95, 2.10), (xf + 0.80, 2.60),
                  (xf + 0.55, H_OPEN + FR + 0.50), (xf + 0.10, H_OPEN + FR + 0.62), (xf - 0.02, H_OPEN + FR - 0.02)]
    bite_head = [(A_N - FR - 0.05, H_OPEN + FR - 0.02), (A_MID, H_OPEN + FR - 0.02), (xf + 0.05, H_OPEN + FR - 0.02), (xf + 0.05, H_OPEN + FR + 0.45),
                 (A_MID + 0.4, H_OPEN + FR + 0.55), (A_MID - 0.3, H_OPEN + FR + 0.38), (A_N - FR - 0.05, H_OPEN + FR + 0.30)]
    lip = M.face_plane(0.0)
    P.append(Part("damage", "spall_lip", [ragged(bite_latch, 0.035), ragged(bite_head, 0.03)], (0.17, 0.172, 0.18), lip,
                  "the broken edge of the spall, 10-20 mm", "where the face broke away"))

    def inset(poly_ah, k, dh):
        ca = sum(p[0] for p in poly_ah) / len(poly_ah)
        ch = sum(p[1] for p in poly_ah) / len(poly_ah)
        return [(ca + (p[0] - ca) * k, ch + (p[1] - ch) * k + dh) for p in poly_ah]
    deep = M.face_plane(0.07)

    def bite_mod(P_, la, lb):  # broken concrete: coarse aggregate mottle, darker deeper in
        return 0.75 + 0.18 * _noise2(la, lb, 0.12, 0.10, 21) + 0.08 * _noise2(la, lb, 0.05, 0.05, 22)
    P.append(Part("damage", "spall", [ragged(inset(bite_latch, 0.86, 0.04), 0.03), ragged(inset(bite_head, 0.85, 0.03), 0.025)], CONCRETE_CUT, deep,
                  "concrete spalled off the face round the frame's anchors, 50-90 mm deep", "the back-blast tore the frame loose", mod=bite_mod))
    # reinforcement exposed in the bite (25 mm bars; drawn 1 world px wide so they read at the play zoom)
    rebar = []
    for a in (xf + 0.28, xf + 0.58):
        rebar.append(seg_poly(scr(pt(a, 0.25, 0.08)), scr(pt(a, 2.75, 0.08)), 1.0))
    for h in (0.45, 0.95, 1.45, 1.95, 2.45):
        rebar.append(seg_poly(scr(pt(xf + 0.06, h, 0.08)), scr(pt(xf + 0.66, h, 0.08)), 0.9))
    rebar.append(seg_poly(scr(pt(A_N - FR + 0.05, H_OPEN + FR + 0.22, 0.08)), scr(pt(xf + 0.30, H_OPEN + FR + 0.22, 0.08)), 1.0))
    # bar ends torn loose and bent out of the face toward the approach (sticking out 0.2-0.3 m)
    for (h, out, drop) in ((0.95, 0.26, 0.10), (1.45, 0.30, 0.16), (1.95, 0.22, 0.06), (2.45, 0.28, 0.12)):
        p0 = pt(xf + 0.05, h, 0.04)
        p1 = pt(xf - 0.02, h - drop * 0.4, -out * 0.55)
        p2 = pt(xf - 0.06, h - drop, -out)
        rebar.append(seg_poly(scr(p0), scr(p1), 1.1))
        rebar.append(seg_poly(scr(p1), scr(p2), 1.1))
    for a in (A_MID - 0.35, A_MID + 0.25):  # two bars hanging down out of the head bite
        p0 = pt(a, H_OPEN + FR + 0.22, 0.05)
        p1 = pt(a + 0.05, H_OPEN + FR - 0.05, -0.12)
        rebar.append(seg_poly(scr(p0), scr(p1), 1.1))
    P.append(Part("damage", "rebar", rebar, REBAR, M.face_plane(0.06), "25 mm reinforcing bars exposed in the spall, four ends torn out and bent toward the approach", "the wall's reinforcement"))
    # fix round 2 (N4): the latch jamb's 300 mm face plate: the leaf's bolts dragged its inner edge (where
    # the keepers are welded) after the leaf into the lane. Below 0.9 m it still sits on its anchors; above,
    # its outer edge still hangs on the outer anchors and its inner edge is bent 0.25 m into the opening and
    # back toward the lane, so it shows in the doorway against the lane: torn steel, its torn edge bright.
    fp_b = poly([pt(A_F, 0.90, -0.008), pt(A_F + FRF, 0.90, -0.008), pt(A_F + FRF, H_OPEN + FR, -0.008), pt(A_F + FRF * 0.55, H_OPEN + FR, -0.008), pt(A_F + FRF * 0.40, 1.10, -0.008)])
    P.append(Part("damage", "flange_far_low", [quad_face(A_F, A_F + FRF, 0.0, 0.90, -0.008), fp_b], GUNSHIP, face_plane(-0.008), "latch face plate, still on its anchors", "frame"))
    bend = [pt(A_F + FRF * 0.40, 1.10, -0.008), pt(A_F + FRF * 0.55, H_OPEN + FR - 0.05, -0.008), pt(A_F - 0.10, H_OPEN - 0.10, 0.24), pt(A_F - 0.16, 1.70, 0.26), pt(A_F - 0.04, 1.05, 0.10)]
    P.append(Part("damage", "flange_peeled", [poly(bend)], GUNSHIP, M.general_plane(bend[0], bend[1], bend[3]),
                  "the latch face plate's inner half, torn off its anchors above 1.0 m and bent 0.25 m into the opening toward the lane", "frame damage: the bolts dragged it after the leaf"))
    P.append(Part("damage", "flange_peel_edge", [poly([pt(A_F - 0.10, H_OPEN - 0.10, 0.24), pt(A_F - 0.16, 1.70, 0.26), pt(A_F - 0.13, 1.70, 0.30), pt(A_F - 0.07, H_OPEN - 0.10, 0.28)])], STEEL_WORN,
                  M.general_plane(bend[2], bend[3], pt(A_F - 0.13, 1.70, 0.30)), "its torn edge, bare steel", "frame damage"))
    for i, hk in enumerate((1.30, 2.20)):  # two keeper lugs still welded to it, sheared
        q = [pt(A_F - 0.06 - 0.02 * i, hk - 0.06, 0.20), pt(A_F - 0.12 - 0.02 * i, hk - 0.06, 0.24), pt(A_F - 0.12 - 0.02 * i, hk + 0.06, 0.24), pt(A_F - 0.06 - 0.02 * i, hk + 0.06, 0.20)]
        P.append(Part("damage", f"keeper_lug{i}", [poly(q)], STEEL_WORN, M.general_plane(q[0], q[1], q[3]), "bolt keeper lug 120 mm, sheared off its bolt", "where a locking bolt held"))
    # the head flange sags 0.11 m in the middle (about 4 world px)
    n = 12
    top = [pt(A_N - FR + (xf - A_N + FR) * k / n, H_OPEN + FR - 0.11 * math.sin(math.pi * k / n), -0.03) for k in range(n + 1)]
    bot = [pt(A_N - FR + (xf - A_N + FR) * k / n, H_OPEN - 0.11 * math.sin(math.pi * k / n), -0.03) for k in range(n + 1)]
    P.append(Part("damage", "head_sag", [poly(top + bot[::-1])], GUNSHIP, face_plane(-0.03), "head flange bowed 110 mm", "frame damage"))
    # cracks from the head corners (Liu et al.) and the latch jamb, out through the calm wall
    starts = [(HEAD_FAR[0] + 0.55, HEAD_FAR[1] + 0.55, 0.75), (HEAD_FAR[0] + 0.85, HEAD_FAR[1] + 0.2, 0.35), (HEAD_NEAR[0] - 0.02, HEAD_NEAR[1] + 0.25, math.pi - 0.9),
              (xf + 0.9, 1.8, 0.15), (xf + 0.85, 0.9, -0.2), (A_MID, H_OPEN + FR + 0.55, math.pi / 2 - 0.2)]
    P.append(Part("damage", "cracks_open", _crack_lines(np.random.default_rng(RNG_SEED + 7), starts, steps=(4, 7), step_len=(0.12, 0.3), width=0.6), CONCRETE_DK, face_plane(-0.002),
                  "open cracks 1-4 mm from the opening's corners", "the wall round the frame cracked as the door went (Liu et al. 2018)"))
    # soot: the gas vented out through the gap round the leaf, up over the head and along the latch side
    def soot_fn(X, Y):
        hx, hy = scr(pt(A_MID, H_OPEN + 0.1, 0.0))
        lx, ly = scr(pt(A_F + 0.1, 1.4, 0.0))
        f1 = np.exp(-(((X - hx) / 14.0) ** 2) - (np.clip(hy - Y, 0, None) / 34.0) ** 2) * (Y < hy + 4)
        f2 = np.exp(-(((X - lx) / 7.0) ** 2) - ((Y - ly) / 46.0) ** 2)
        return 0.62 * np.maximum(f1, 0.8 * f2)
    hole = mask_of([quad_face(A_N, A_F, 0.0, H_OPEN)])
    P.append(Part("damage", "soot", [quad_face(A_E, A_BACK, 0.0, 5.0)], SOOT, face_plane(-0.0005),
                  "soot from the vented gas", "where the blast left the frame", clip=soft_field(soot_fn) * (1 - hole)))
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
    # the heap: spalled concrete and fines piled in the doorway's foot, highest (0.45 m) just inside
    # the opening and running out to nothing at the rubble line (x 540)
    def heap_h(xw, d):
        u = (xw - 486.0) / (54.0 if xw > 486.0 else 20.0)
        v = (d - 0.05) / 0.65
        return 0.45 * max(0.0, 1.0 - u * u) * max(0.0, 1.0 - v * v)
    top, front = [], []
    xs = np.linspace(466.0, 540.0, 34)
    for xw in xs:
        best = max((heap_h(xw, d), d) for d in np.linspace(-0.6, 0.7, 27))
        top.append(np.array([xw / M.PXM, best[0], best[1]]))
        front.append(np.array([xw / M.PXM, 0.0, -0.55 * max(0.0, 1.0 - ((xw - 492.0) / 52.0) ** 2) - 0.02]))
    heap = poly(top + front[::-1])
    P.append(Part("hole", "rubble_heap", [heap], CONCRETE_CUT, front_plane(0.0),
                  "a heap of spalled concrete and fines 0.45 m high, 1.8 m long", "what the blast tore out of the jambs; the rubble line (x 540) is its end",
                  mod=lambda P_, la, lb: 0.7 + 0.55 * np.clip(lb / 0.45, 0, 1) + 0.12 * _noise2(la, lb, 0.08, 0.05, 31)))
    cen = [(rng.uniform(470, 536), rng.uniform(-0.35, 0.45)) for _ in range(20)]
    P += chunk_parts("hole", "rubble_back", rng, cen, (0.10, 0.24))
    P += chunk_parts("hole", "rubble_back", rng, [(478.0, 0.3), (492.0, 0.1), (507.0, 0.35), (522.0, 0.0), (500.0, -0.25), (531.0, 0.25)], (0.28, 0.40), h_ratio=(0.4, 0.55))
    P += chunk_parts("hole", "rubble_back", rng, [(476.0, 0.35), (489.0, 0.1), (503.0, 0.3), (518.0, 0.0)], (0.36, 0.52), h_ratio=(0.45, 0.6))
    # a torn length of the frame's channel lying across the threshold
    c0 = np.array([12.05, 0.0, 0.25])
    c1 = np.array([13.05, 0.0, -0.05])
    up = np.array([0, 0.13, 0])
    P.append(Part("hole", "frame_piece", [poly([c0, c1, c1 + up, c0 + up])], GUNSHIP, general_plane(c0, c1, c0 + up),
                  "1.0 m of the frame's channel, torn off", "frame fragment"))
    P.append(Part("hole", "frame_piece_top", [poly([c0 + up, c1 + up, c1 + up + np.array([0, 0, 0.14]), c0 + up + np.array([0, 0, 0.14])])], STEEL_WORN, top_plane(0.13),
                  "its torn top edge", "frame fragment"))
    return P


# ---------------------------------------------------------------------------------------- lying leaf
# (fix round 1, M2) The leaf tore off its lane-side hinges and was thrown into the lane, where it lies
# approach face up, its hinge edge toward the camera. ASTM F2927 category IV ("severely deformed"):
# it is bowed (the blast pushed its middle 0.09 m further than its edges) and dished; its far (latch)
# edge and right (bottom) end lie on chunks of the jamb, so it tilts about 6.5 degrees toward the camera
# and 3.5 degrees along its length, and it rocks on its belly near the left end. On the hinge edge: three torn knuckles with sheared pins; out of the latch edge: the three
# locking bolts, bent. It lies clear of the cross-wall's stub (at least 8 world px).
LY_C = (608.0, -4.30)  # its centre on the deck (world x at walk scale, d metres): its far edge stays below the actors' feet (y 440)
LY_YAW = math.radians(17.0)  # thrown straight out from the wall: its ends run parallel to the wall (and its stub)
LY_LEN, LY_WID, LY_TH = H_OPEN, M.W_OPEN, 0.30
LY_BOW, LY_DISH, LY_LIFT, LY_LIFT_V = 0.09, 0.04, 0.10, 0.18


def _ly_axes():
    yaw = LY_YAW
    dl = np.array([math.cos(yaw), 0.0, math.sin(yaw)])  # along the leaf's length (its height when hung), left to right
    dv = np.array([-math.sin(yaw), 0.0, math.cos(yaw)])  # across it, from the hinge edge (near the camera) to the latch edge
    c = np.array([LY_C[0] / M.PXM, 0.0, LY_C[1]])
    return c, dl, dv


def _ly_bottom(u, v):
    """Height of the leaf's underside at (u, v) (u 0..LEN left to right, v 0..WID near to far): tilted up
    to the right end's chunk, bowed down in the middle; offset so it just touches the deck."""
    x = 2.0 * u / LY_LEN - 1.0
    z = LY_LIFT * (u / LY_LEN) + LY_LIFT_V * (v / LY_WID) - LY_BOW * (1.0 - x * x)
    return z


_US = np.linspace(0, LY_LEN, 200)
_LY_Z0 = -min(_ly_bottom(u, v) for u in _US for v in (0.0, LY_WID))


def ly_point(u, v, up):
    """A point of the leaf: (u, v) on it, up = 0 on its underside, LY_TH on its top (approach) face."""
    c, dl, dv = _ly_axes()
    base = c + (u - LY_LEN / 2) * dl + (v - LY_WID / 2) * dv
    xx, yy = 2.0 * u / LY_LEN - 1.0, 2.0 * v / LY_WID - 1.0
    z = _ly_bottom(u, v) + _LY_Z0 + up - (LY_DISH * (1 - yy * yy) * (1 - xx * xx) if up > 0 else 0.0)
    return base + np.array([0.0, z, 0.0])


def lying_parts() -> list:
    P = []
    nu, nv = 14, 5
    us = np.linspace(0, LY_LEN, nu + 1)
    vs = np.linspace(0, LY_WID, nv + 1)
    # the chunk under the right end, then the contact shadow, then the leaf's faces
    c, dl, dv = _ly_axes()
    pc = c + (LY_LEN / 2 - 0.28) * dl + 0.05 * dv
    P += chunk_parts("lying", "prop_chunk", np.random.default_rng(RNG_SEED + 9), [(pc[0] * M.PXM, pc[2] - 0.15)], (0.30, 0.32), h_ratio=(0.55, 0.6))
    foot = [ly_point(0, 0, 0), ly_point(LY_LEN, 0, 0), ly_point(LY_LEN, LY_WID, 0), ly_point(0, LY_WID, 0)]
    for q in foot:
        q[1] = 0.0
    P.append(Part("lying", "leaf_shadow", [poly(foot)], (0.004, 0.005, 0.006), top_plane(0.0), "contact shadow", "the leaf lies on the deck",
                  clip=None))
    # the left end face (toward the camera's left), then the hinge edge (toward the camera)
    left = [ly_point(0, 0, 0), ly_point(0, LY_WID, 0), ly_point(0, LY_WID, LY_TH), ly_point(0, 0, LY_TH)]
    P.append(Part("lying", "leaf_end", [poly(left)], np.array(GUNSHIP) * 0.75, general_plane(left[0], left[1], left[3]),
                  "the leaf's top edge, 0.30 m: 10 mm skins and the edge channel over the concrete fill", "the door's edge"))
    for k in range(nu):
        q = [ly_point(us[k], 0, 0), ly_point(us[k + 1], 0, 0), ly_point(us[k + 1], 0, LY_TH), ly_point(us[k], 0, LY_TH)]
        P.append(Part("lying", "leaf_hinge_edge", [poly(q)], np.array(GUNSHIP) * 0.85, general_plane(q[0], q[1], q[3]),
                      "the leaf's hinge edge, 0.30 m, bowed with the leaf", "the edge it hung by, toward the camera"))
    for j in range(nv):
        for k in range(nu):
            q = [ly_point(us[k], vs[j], LY_TH), ly_point(us[k + 1], vs[j], LY_TH), ly_point(us[k + 1], vs[j + 1], LY_TH), ly_point(us[k], vs[j + 1], LY_TH)]
            P.append(Part("lying", "leaf_up_face", [poly(q)], np.array(GUNSHIP) * 0.8, general_plane(q[0], q[1], q[3]),
                          "the leaf's approach face, up: bowed 90 mm and dished 40 mm", "the door, thrown 2-3 m into the lane"))
    # the weld seam 60 mm in from the edges (the skin's edge channel), on the up face
    seam = []
    for (u0, v0, u1, v1) in ((0.06, 0.06, LY_LEN - 0.06, 0.06), (0.06, LY_WID - 0.06, LY_LEN - 0.06, LY_WID - 0.06)):
        for k in range(nu):
            ua, ub = u0 + (u1 - u0) * k / nu, u0 + (u1 - u0) * (k + 1) / nu
            seam.append(seg_poly(scr(ly_point(ua, v0, LY_TH + 0.002)), scr(ly_point(ub, v0, LY_TH + 0.002)), 0.35))
    P.append(Part("lying", "leaf_seam", seam, DARK, top_plane(0.3), "skin-to-edge-channel weld seam", "the skin's welded edge"))
    for i, u in enumerate((0.95, 1.55)):  # the capped spindles near the latch edge
        q = [ly_point(u - 0.06, LY_WID - 0.25, LY_TH + 0.015), ly_point(u + 0.06, LY_WID - 0.25, LY_TH + 0.015), ly_point(u + 0.06, LY_WID - 0.13, LY_TH + 0.015), ly_point(u - 0.06, LY_WID - 0.13, LY_TH + 0.015)]
        P.append(Part("lying", f"leaf_spindle_cap{i}", [poly(q)], STEEL_WORN, top_plane(0.3), "capped lever spindle", "the same caps as on the shut door"))
    # the three locking bolts out of the latch edge (far side), bent up and back as they sheared
    for i, u in enumerate((0.40, 1.30, 2.20)):
        p0 = ly_point(u, LY_WID - 0.02, LY_TH * 0.5)
        p1 = p0 + 0.10 * dv + np.array([0, 0.05, 0])
        p2 = p1 + 0.05 * dv + np.array([0, 0.13, 0])
        P.append(Part("lying", f"bent_bolt{i}", [seg_poly(scr(p0), scr(p1), 2.0), seg_poly(scr(p1), scr(p2), 1.8)], STEEL_WORN, front_plane(float(p1[2])),
                      "50 mm locking bolt, sheared and bent up", "the bolts that held it shut tore out of the latch jamb"))
    # fix round 2 (S3, human: "reads as a pallet"): the door leaves of the three full-surface hinges stay
    # on the leaf's approach face (now up) at its hinge edge: 16 mm plates 0.30 x 0.22 m, the door's two
    # knuckles of each still on them, torn off their pins
    for i, u in enumerate((LY_LEN - 0.40, LY_LEN - 1.30, LY_LEN - 2.20)):
        q = [ly_point(u - 0.15, 0.015, LY_TH + 0.016), ly_point(u + 0.15, 0.015, LY_TH + 0.016), ly_point(u + 0.15, 0.015 + 0.22, LY_TH + 0.016), ly_point(u - 0.15, 0.015 + 0.22, LY_TH + 0.016)]
        P.append(Part("lying", f"hinge_leafplate{i}", [poly(q)], HOUSING, general_plane(q[0], q[1], q[3]),
                      "full-surface hinge, door leaf 16 mm x 0.30 x 0.22 m", "it hung the leaf; it came with it"))
    # the torn hinge knuckles on the hinge edge (toward the camera), each with its sheared pin
    for i, u in enumerate((0.35, 1.30, 2.25)):
        k0 = ly_point(u - 0.10, -0.06, LY_TH * 0.25)
        k1 = ly_point(u + 0.10, -0.06, LY_TH * 0.25)
        k2 = ly_point(u + 0.10, -0.06, LY_TH * 0.80)
        k3 = ly_point(u - 0.10, -0.06, LY_TH * 0.80)
        P.append(Part("lying", f"hinge_plate{i}", [poly([ly_point(u - 0.12, 0, LY_TH * 0.18), ly_point(u + 0.12, 0, LY_TH * 0.18), ly_point(u + 0.12, -0.02, LY_TH * 0.86), ly_point(u - 0.12, -0.02, LY_TH * 0.86)])], STEEL,
                      general_plane(k0, k1, k3), "hinge leaf welded to the edge channel", "carried the leaf"))
        P.append(Part("lying", f"hinge_knuckle{i}", [poly([k0, k1, k2, k3])], STEEL_WORN, general_plane(k0, k1, k3),
                      "torn hinge knuckle 200 mm, its barrel split", "the leaf hung on three of these on the lane side"))
        pc0 = ly_point(u + 0.10, -0.06, LY_TH * 0.52)
        pc1 = ly_point(u + 0.17, -0.07, LY_TH * 0.60)
        P.append(Part("lying", f"hinge_pin{i}", [seg_poly(scr(pc0), scr(pc1), 1.6)], (0.62, 0.63, 0.65), front_plane(float(pc0[2])),
                      "80 mm hinge pin, sheared (bright fracture)", "the pin that failed"))
    return P


def rubble_front_parts() -> list:
    rng = np.random.default_rng(RNG_SEED + 4)
    cen = [(rng.uniform(446, 500), rng.uniform(-1.9, -0.45)) for _ in range(18)]  # thrown forward from the doorway
    P = chunk_parts("lying", "rubble_front", rng, cen, (0.06, 0.16))
    P += chunk_parts("lying", "rubble_front", rng, [(466.0, -0.8), (481.0, -1.35), (458.0, -0.55), (497.0, -1.0), (452.0, -1.6)], (0.26, 0.40), h_ratio=(0.4, 0.55))
    cen = [(rng.uniform(512, 560), rng.uniform(-2.6, -0.5)) for _ in range(12)]  # on the lane deck by the wall
    P += chunk_parts("lying", "rubble_front", rng, cen, (0.06, 0.18))
    P += chunk_parts("lying", "rubble_front", rng, [(537.0, -1.1), (551.0, -2.3), (646.0, -2.4), (620.0, -4.6)], (0.22, 0.32), h_ratio=(0.4, 0.55))
    # concrete dust settled on the deck round the doorway (a thin film, no glow)
    def dust_fn(X, Y):
        cx, cy = 496.0, 449.0
        return 0.34 * np.exp(-(((X - cx) / 52.0) ** 2) - (((Y - cy) / 9.0) ** 2)) * (Y > 440.5)
    deck = [poly([np.array([x / M.PXM, 0.0, d]) for x, d in ((430, 0.0), (590, 0.0), (590, -2.6), (430, -2.6))])]
    P.insert(0, Part("lying", "dust_film", deck, (0.30, 0.30, 0.31), top_plane(0.001), "a film of concrete dust", "settled after the blast", clip=soft_field(dust_fn)))
    return P


# ---------------------------------------------------------------------------------------- front

def stub_far_a() -> float:
    return M.DECK_FRONT_D / math.cos(M.THETA)


def front_parts(blown: bool = False) -> list:
    P = []
    tl = T_WALL / 2
    P.append(Part("front", "col_flange_near", [quad_face(A_N - FR, A_N, 0.0, H_OPEN + FR, -0.008)], GUNSHIP, face_plane(-0.008),
                  "steel channel frame, 120 mm approach flange", "lines the hinge jamb"))
    P.append(Part("front", "col_face_strip", [quad_face(A_E, A_N - FR, 0.0, H_TOP)], CONCRETE, face_plane(0.0), "20 mm of face", "the wall's end"))
    P.append(Part("front", "col_end", [quad_side(A_E, 0.0, T_WALL, 0.0, H_TOP)], CONCRETE, side_plane(A_E),
                  "the cross-wall's end face toward the camera, 0.40 m", "the wall's end; carries the status lamp and the junction box"))
    if not blown:
        P.append(Part("front", "col_arris_face", [quad_face(A_E, A_E + 0.05, 0.0, H_TOP, -0.004)], STEEL, face_plane(-0.004), "50 mm steel arris angle, face leg", "armours the corner"))
        P.append(Part("front", "col_arris_end_l", [quad_side(A_E - 0.002, 0.0, 0.05, 0.0, H_TOP)], STEEL, side_plane(A_E - 0.002), "50 mm steel arris angle", "armours the corner"))
    else:
        P += column_damage_parts()
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
    P += hinge_frame_parts(blown)
    if blown:
        P += column_soot_parts()
        for p_ in P:
            p_.layer = "frontblown"
        return P
    # the stub: the cross-wall cut down to 0.15 m across the deck (the cutaway the corridor uses)
    af = stub_far_a()
    P.append(Part("front", "stub_face", [quad_face(af, A_E, 0.0, STUB_H)], CONCRETE, face_plane(0.0), "the wall's 0.15 m stub, approach-side face", "the wall's line carried across the deck to the camera (cutaway)"))
    P.append(Part("front", "stub_top", [quad_top(af, A_E, 0.0, T_WALL, STUB_H)], CONCRETE, top_plane(STUB_H), "stub top, the wall's 0.40 m thickness", "the cut section, seen from above"))
    P.append(Part("front", "stub_angle_top", [quad_top(af, A_E, 0.0, 0.05, STUB_H + 0.003)], STEEL_WORN, top_plane(STUB_H + 0.003), "50 mm steel edge angle", "armours the approach-side edge"))
    P.append(Part("front", "stub_angle_face", [quad_face(af, A_E, STUB_H - 0.05, STUB_H, -0.004)], STEEL, face_plane(-0.004), "50 mm steel edge angle", "armours the approach-side edge"))
    P.append(Part("front", "stub_angle_far", [quad_top(af, A_E, T_WALL - 0.05, T_WALL, STUB_H + 0.003)], STEEL_WORN, top_plane(STUB_H + 0.003), "50 mm steel edge angle", "armours the lane-side edge"))
    # (S9) the wall does not stand on the raised steel deck: it runs down through it to the slab. At the
    # deck's front edge its cut section carries on down the deck's fascia, out of the bottom of the view,
    # with a 50 mm steel angle where the deck plates stop against it each side.
    d_front = M.DECK_FRONT_D
    xa = pt(af, 0.0, 0.0)
    a_l = (d_front - T_WALL * M.N[2]) / M.U[2]
    xl = pt(a_l, 0.0, T_WALL)
    cut = [np.array([xa[0], STUB_H, d_front]), np.array([xl[0], STUB_H, d_front]), np.array([xl[0], -1.8, d_front]), np.array([xa[0], -1.8, d_front])]
    P.append(Part("front", "stub_cut", [poly(cut)], CONCRETE_CUT, front_plane(d_front),
                  "the cross-wall's cut section, 0.40 m (0.42 m on the slant), down through the deck and its fascia to the slab", "the wall's line carried to the camera and through the raised deck (cutaway)",
                  mod=lambda P_, la, lb: 0.8 + 0.1 * _noise2(la, lb, 0.2, 0.3, 41)))
    for i, xx in enumerate((xa[0], xl[0])):
        P.append(Part("front", f"stub_cut_angle{i}", [poly([np.array([xx - 0.03, STUB_H, d_front - 0.01]), np.array([xx + 0.03, STUB_H, d_front - 0.01]), np.array([xx + 0.03, -1.8, d_front - 0.01]), np.array([xx - 0.03, -1.8, d_front - 0.01])])],
                      STEEL, front_plane(d_front - 0.01), "50 mm steel angle", "trims the deck plate and its fascia where they stop against the wall"))
    return P


def column_damage_parts() -> list:
    """Fix round 2 (N4): the near column after the blast, where it reads at play size (0.3-2.0 m, on its
    end face toward the camera, 0.40 m = 16 world px wide). The hinges were anchored in this 0.2 m of
    concrete beside the opening; the leaf tearing off pulled them, so the corner at the hinge jamb spalled
    off down to the bars (two 25 mm verticals and their 12 mm ties), cracks run from it across the end
    face, and the 50 mm arris angle at that corner tore off its anchors between 0.4 and 1.9 m and bowed
    out 0.12 m toward the camera; above and below it still holds."""
    P = []
    rng = np.random.default_rng(RNG_SEED + 21)
    # the arris angle: held at the foot and above 1.9 m, bowed out in between
    hs = np.linspace(0.0, H_TOP, 60)
    bow = np.where((hs > 0.4) & (hs < 1.9), 0.12 * np.sin(np.pi * (hs - 0.4) / 1.5), 0.0)
    left = [pt(A_E - 0.004 - b, h, 0.0) for h, b in zip(hs, bow)]
    right = [pt(A_E - 0.004 - b, h, 0.05) for h, b in zip(hs, bow)]
    face_l = [pt(A_E + 0.05 - b * 0.4, h, -0.004 - b * 0.3) for h, b in zip(hs, bow)]
    P.append(Part("front", "col_arris_end_l", [poly(left + right[::-1])], STEEL_WORN, side_plane(A_E - 0.004), "50 mm arris angle, torn off its anchors from 0.4 to 1.9 m and bowed out 120 mm", "blast damage at the hinge jamb"))
    P.append(Part("front", "col_arris_face", [poly([pt(A_E, h, -0.004) for h in (0.0, H_TOP)] + [pt(A_E + 0.05, h, -0.004) for h in (H_TOP, 0.0)])], STEEL, face_plane(-0.004), "50 mm steel arris angle, face leg", "armours the corner"))
    # the spall: a ragged bite out of the end face's junction-side corner, 0.18 m deep across the face
    ts = [0.0, 0.10, 0.17, 0.13, 0.19, 0.15, 0.08, 0.0]
    hh = [0.28, 0.40, 0.72, 1.05, 1.38, 1.72, 2.02, 2.10]
    pts = [pt(A_E - 0.001, h + rng.normal(0, 0.02), t + rng.normal(0, 0.012)) for t, h in zip(ts, hh)]
    P.append(Part("front", "col_spall_lip", [poly(pts + [pt(A_E - 0.001, 2.10, 0.0), pt(A_E - 0.001, 0.28, 0.0)])], (0.17, 0.172, 0.18), side_plane(A_E - 0.001),
                  "the spall's broken edge, 10-20 mm", "where the corner broke away"))
    inner = [pt(A_E + 0.06, h, max(t - 0.025, 0.0)) for t, h in zip(ts, hh)]
    P.append(Part("front", "col_spall", [poly([pt(A_E + 0.06, 0.32, 0.0)] + inner[1:-1] + [pt(A_E + 0.06, 2.06, 0.0)])], CONCRETE_CUT, side_plane(A_E + 0.06),
                  "the corner spalled off 60-80 mm deep, 0.3-2.1 m", "the hinges' anchors pulled out of the jamb's concrete",
                  mod=lambda P_, la, lb: 0.72 + 0.2 * _noise2(la, lb, 0.06, 0.05, 23)))
    bars = []
    for t in (0.055, 0.115):
        bars.append(seg_poly(scr(pt(A_E + 0.05, 0.36, t)), scr(pt(A_E + 0.05, 2.02, t)), 1.1))
    for h in (0.62, 1.12, 1.62):
        bars.append(seg_poly(scr(pt(A_E + 0.05, h, 0.03)), scr(pt(A_E + 0.05, h + 0.02, 0.14)), 0.9))
    # one tie torn out and bent toward the camera
    bars.append(seg_poly(scr(pt(A_E + 0.05, 1.37, 0.05)), scr(pt(A_E - 0.10, 1.30, 0.06)), 1.0))
    P.append(Part("front", "col_rebar", bars, REBAR, side_plane(A_E + 0.05), "two 25 mm vertical bars and their 12 mm ties, bared; one tie torn out", "the column's reinforcement"))
    # cracks running from the spall across the end face and up
    starts = [(0.17, 0.72, 0.15), (0.19, 1.38, -0.2), (0.15, 1.72, 0.6), (0.10, 0.40, -0.5), (0.08, 2.02, 1.1)]
    lines = []
    for (t0, h0, ang) in starts:
        tt, h = t0, h0
        pts_ = [(tt, h)]
        for k in range(int(rng.integers(3, 6))):
            ang += rng.normal(0, 0.35)
            stp = rng.uniform(0.04, 0.09)
            tt, h = tt + math.cos(ang) * stp, h + math.sin(ang) * stp
            if tt > T_WALL - 0.03:
                break
            pts_.append((tt, h))
        for (ta, ha), (tb, hb) in zip(pts_, pts_[1:]):
            lines.append(seg_poly(scr(pt(A_E - 0.002, ha, ta)), scr(pt(A_E - 0.002, hb, tb)), 0.9))
    P.append(Part("front", "col_cracks", lines, CONCRETE_DK, side_plane(A_E - 0.002), "open cracks 2-4 mm from the spall across the end face", "the jamb's concrete split as the hinges tore"))
    return P


def column_soot_parts() -> list:
    """Soot the vented gas left on the column round the opening (a soft film; its colour from the design)."""
    def soot_fn(X, Y):
        jx, jy = scr(pt(A_N, 1.4, 0.0))
        return 0.55 * np.exp(-(((X - jx) / 5.0) ** 2) - ((Y - jy) / 44.0) ** 2)
    return [Part("front", "col_soot", [quad_face(A_E, A_N, 0.0, H_OPEN + FR)] + [quad_side(A_E - 0.003, 0.0, T_WALL, 0.0, H_OPEN + FR)], SOOT, face_plane(-0.0005),
                 "soot from the gas vented past the hinge jamb", "where the blast left the frame", clip=soft_field(soot_fn))]


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
        "front": front_parts(), "frontblown": front_parts(True), "alcove": alcove_parts(),
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
        if name in ("wall", "front", "frontblown", "alcove", "leaf", "leafbreak", "hole", "lying", "damage"):
            lay["a"] = close_seams(lay["a"])
        sh = None
        if name == "wall":
            lay["a"] = lay["a"] * (1 - hole_face)
            lay["masks"]["HOLE"] = hole_face
        if name in ("front", "frontblown"):
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
