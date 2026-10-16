"""The inner blast leaf as the game draws it: a mesh in the leaf's own planes, driven by the seal's
open value. This module is the reference for the GDScript (BlastLeaf) and for the previews: the
same projection, the same columns, rows, UVs and vertex colours.

open value o (SealLeaf.open, 0 shut .. 1 open, the seal's existing tween) -> slide fraction
    f = clamp((o - LEAF_START) / (1 - LEAF_START), 0, 1)        (no new timing: a function of o)
leading edge  a_lead(f) = A_LEAD_SHUT + f * TRAVEL_M
front face    plane t = T_LF, a from a_lead to A_F (the pocket's mouth), h from 0 to H_OPEN
edge face     plane a = a_lead, t from T_LF to T_LB, h from 0 to H_OPEN
texture u     on the front face = a - a_lead metres back from the leading edge
"""
from __future__ import annotations

import numpy as np

from stack import common, p2  # noqa: F401
import portal7 as d7

H_ROWS = (0.0, 0.4, 0.8, 1.2, 1.6, 2.0, 2.4, 2.75, d7.H_OPEN)


def project(a: float, h: float, t: float) -> tuple[float, float]:
    """World (clamp-world) px of the point (a, h, t) on the cross-wall's frame."""
    P = p2.O + a * p2.U + h * p2.EY + t * p2.N
    s = common.D0 / (common.D0 + P[2])
    X = common.VPX + (P[0] * common.PX_PER_M - common.VPX) * s
    Y = common.HORIZON + (common.FLOOR_Y - common.HORIZON) * s - h * common.PX_PER_M * s
    return X, Y


def slide(o: float) -> float:
    return float(np.clip((o - d7.LEAF_START) / (1.0 - d7.LEAF_START), 0.0, 1.0))


def a_lead(o: float) -> float:
    return d7.A_LEAD_SHUT + slide(o) * d7.TRAVEL_M


def light_front(a: float, h: float, spec: dict) -> float:
    lt = spec["leaf"]["light_table"]
    A = np.array(lt["a_cols"])[::-1]
    Hh = np.array(lt["h_rows"])
    V = np.array(lt["vertex_colour"])[::-1]
    ai = np.interp(a, A, np.arange(len(A)))
    hi = np.interp(h, Hh, np.arange(len(Hh)))
    a0, h0 = int(np.floor(ai)), int(np.floor(hi))
    a1, h1 = min(a0 + 1, len(A) - 1), min(h0 + 1, len(Hh) - 1)
    fa, fh = ai - a0, hi - h0
    return float((V[a0, h0] * (1 - fa) + V[a1, h0] * fa) * (1 - fh) + (V[a0, h1] * (1 - fa) + V[a1, h1] * fa) * fh)


def edge_light(o: float) -> float:
    """The leading edge faces the near jamb: it is lit by the plant room's high-bays through the gap
    between it and the near jamb (as the far reveal is, when the leaf is home in its pocket)."""
    gap = a_lead(o) - d7.A_N
    return float(0.35 + 0.65 * np.clip(gap / 1.2, 0.0, 1.0) ** 0.5)


def mesh(o: float, spec: dict):
    """Returns two lists of quads [(screen pts 4, uv metres 4, colours 4)] for the front face and the
    edge face, or ([], []) when the leaf is home (f = 1: the wall's painted pocket edge shows)."""
    al = a_lead(o)
    cols = [al] + [a for a in spec["leaf"]["light_table"]["a_cols"][::-1] if a > al + 1e-4 and a <= d7.A_F + 1e-6]
    if cols[-1] < d7.A_F - 1e-4:
        cols.append(d7.A_F)
    front = []
    for i in range(len(cols) - 1):
        for j in range(len(H_ROWS) - 1):
            q = [(cols[i], H_ROWS[j]), (cols[i + 1], H_ROWS[j]), (cols[i + 1], H_ROWS[j + 1]), (cols[i], H_ROWS[j + 1])]
            pts = [project(a, h, d7.T_LF) for a, h in q]
            uv = [(a - al, h) for a, h in q]
            c = [light_front(a, h, spec) for a, h in q]
            front.append((pts, uv, c))
    edge = []
    el = edge_light(o)
    for j in range(len(H_ROWS) - 1):
        q = [(d7.T_LF, H_ROWS[j]), (d7.T_LB, H_ROWS[j]), (d7.T_LB, H_ROWS[j + 1]), (d7.T_LF, H_ROWS[j + 1])]
        pts = [project(al, h, t) for t, h in q]
        uv = [(t - d7.T_LF, h) for t, h in q]
        edge.append((pts, uv, [el] * 4))
    return front, edge
