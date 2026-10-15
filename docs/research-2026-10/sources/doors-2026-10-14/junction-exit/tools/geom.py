"""Junction exit door: measured 3D construction, camera and a small ray caster (scratch only).

Camera: the corridor door end's measured camera (docs/.../corridor-door-end-2026-10-12/tools/design/
common.py), which the junction's painted floor joints also fit (vanishing point near world x 484):
vanishing point (483.9, 158.5), the walk line 38 m from the eye, 40 px per metre there, eye 7.04 m up.

3D coordinates in metres: x along the room (x = world px / 40 at the walk line), y up from the deck,
z behind the walk line (negative = toward the camera). A point projects to
  s = 38 / (38 + z);  X = 483.9 + (40 x - 483.9) s;  Y = 158.5 + (440 - 40 y - 158.5) s.

The cross-wall (cast concrete, 0.66 m thick, the corridor's) is turned 17 degrees across the walk line
like the corridor's door end: its approach face crosses the walk line at world x 962. A point on it is
W(s, n, h) = C + s u + n v + h up, with u the wall's direction toward the back (into the room) and v its
normal toward the passage beyond.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np

# fix round 1 (C1): the junction's own camera, measured from its mid plate's deck seams (the blast door's,
# jmodel.py): vanishing point (511, 162). One vanishing point for the room.
VPX, HOR, D0, PPM, FLOOR = 511.0, 162.0, 38.0, 40.0, 440.0
EYE = np.array([VPX / PPM, (FLOOR - HOR) / PPM, -D0])
ANG = math.radians(17.0)
U = np.array([-math.sin(ANG), 0.0, math.cos(ANG)])   # along the wall, toward the back
V = np.array([math.cos(ANG), 0.0, math.sin(ANG)])    # wall normal, toward the passage beyond
UP = np.array([0.0, 1.0, 0.0])
X_CROSS = 962.0                                       # approach face meets the walk line (world px)
C = np.array([X_CROSS / PPM, 0.0, 0.0])
T = 0.66                                              # wall thickness (corridor's)
Z_BACK = 4.2                                          # the junction's back wall: the far plate's 0.9 parallax
S_FAR, S_NEAR = 1.6, -0.4                             # opening jambs along the wall (2.0 m clear)
H_OPEN = 2.4                                          # clear height
TRIM = 0.08                                           # steel frame trim on the approach face
LEAF_N0, LEAF_N1 = 0.27, 0.39                         # leaf runs in the wall's middle (120 mm leaf)
SLOT_N0, SLOT_N1 = 0.25, 0.41                         # pocket mouth in the far jamb
LEAF_W, LEAF_H = 2.15, 2.47                           # leaf (seats 0.1 m in the near jamb rebate)
LEAD_SHUT, LEAD_OPEN = -0.5, 1.62                     # leading edge s, shut and open (20 mm inside the mouth)
Z_PASSAGE_BACK = 2.6                                  # passage beyond: its back wall
PACK_S0, PACK_S1, PACK_H0 = 0.62, 1.12, 3.05          # wall pack over the door
POUR_JOINT_H = 3.6                                    # horizontal pour joint on the cross-wall
# fix round 2: the room's back-wall pipe runs where they meet this wall (h centre, radius; from j08)
PIPE_RUNS_EXIT = ((3.41, 0.05), (3.12, 0.08), (2.75, 0.08), (2.42, 0.06))
# fix round 1 (S4): the wall ends in a column 0.16 m past the near jamb's trim, as the corridor's and the
# blast door's do, and is cut down to a 0.15 m stub running to the deck's front edge, then straight down
# through the deck and its fascia (the cutaway), so the room's deck no longer runs on in front of it.
A_END = S_NEAR - TRIM - 0.16
STUB_H = 0.15
DECK_FRONT_Z = -6.2
ARRIS = 0.05


def W(s: float, n: float, h: float) -> np.ndarray:
    return C + s * U + n * V + h * UP


def s_at_z(z: float, n: float = 0.0) -> float:
    return (z - n * V[2]) / U[2]


def project(p) -> tuple[float, float]:
    p = np.asarray(p, dtype=float)
    s = D0 / (D0 + p[..., 2])
    return VPX + (PPM * p[..., 0] - VPX) * s, HOR + (FLOOR - PPM * p[..., 1] - HOR) * s


@dataclass
class Rect:
    """A planar rectangle: origin o, edges a and b (perpendicular). Faces the side n_out points to."""
    name: str
    o: np.ndarray
    a: np.ndarray
    b: np.ndarray
    layer: str
    albedo: tuple
    group: str = "wall"
    rough: float = 1.0
    emissive: float = 0.0
    n_out: np.ndarray = field(default=None)

    def __post_init__(self):
        n = np.cross(self.a, self.b)
        n = n / np.linalg.norm(n)
        if self.n_out is not None and np.dot(n, self.n_out) < 0:
            n = -n
        self.n = n


@dataclass
class Sphere:
    name: str
    c: np.ndarray
    r: float
    layer: str
    albedo: tuple
    group: str = "wall"
    emissive: float = 0.0


def rect_snh(name, s0, s1, n0, n1, h0, h1, plane, layer, albedo, group="wall", n_out=None, **kw) -> Rect:
    """A rectangle on one of the wall's planes: plane 'n' (constant n = n0, spans s and h), 's' (constant
    s = s0, spans n and h) or 'h' (constant h = h0, spans s and n)."""
    if plane == "n":
        o, a, b = W(s0, n0, h0), (s1 - s0) * U, (h1 - h0) * UP
    elif plane == "s":
        o, a, b = W(s0, n0, h0), (n1 - n0) * V, (h1 - h0) * UP
    else:
        o, a, b = W(s0, n0, h0), (s1 - s0) * U, (n1 - n0) * V
    return Rect(name, o, a, b, layer, albedo, group, n_out=n_out, **kw)


def box_snh(name, s0, s1, n0, n1, h0, h1, layer, albedo, group="wall", faces=("front", "top", "lead", "bottom", "trail")) -> list:
    """A box aligned with the wall (n0 < n1; n0 toward the approach side). Only faces that can face
    the camera are made: its approach face (n0), top, its s0 end (toward the camera)."""
    out = []
    if "front" in faces:
        out.append(rect_snh(name + ":front", s0, s1, n0, n0, h0, h1, "n", layer, albedo, group, n_out=-V))
    if "top" in faces:
        out.append(rect_snh(name + ":top", s0, s1, n0, n1, h1, h1, "h", layer, albedo, group, n_out=UP))
    if "lead" in faces:
        out.append(rect_snh(name + ":lead", s0, s0, n0, n1, h0, h1, "s", layer, albedo, group, n_out=-U))
    if "bottom" in faces:
        out.append(rect_snh(name + ":bottom", s0, s1, n0, n1, h0, h0, "h", layer, albedo, group, n_out=-UP))
    if "trail" in faces:
        out.append(rect_snh(name + ":trail", s1, s1, n0, n1, h0, h1, "s", layer, albedo, group, n_out=U))
    return out


def hex2lin(h: str) -> tuple:
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


# Materials (FED-STD-595 chips from REAL-LOOK section 8; graded to the junction later).
CONCRETE = hex2lin("#7E7E87")      # 36231 structural grey
CONCRETE_CUT = hex2lin("#6E6E76")
STEEL_FRAME = hex2lin("#5B5E6A")   # 36118 gunship grey (frames, leaf)
HOUSING = hex2lin("#4E4F54")       # 36081 (boxes, conduit)
SILL_STEEL = hex2lin("#8A8C90")    # bare worn steel threshold
DARK = hex2lin("#141619")
YELLOW = hex2lin("#FFAA07")        # 33538, caught-between only
BLACK = hex2lin("#343236")         # 37038
LAMP_GLASS = hex2lin("#C8CCD0")
PASS_CONCRETE = hex2lin("#74757C")
PASS_FLOOR = hex2lin("#5E6066")
PIPE = hex2lin("#4E4F54")

# Lights (world metres). L1: the junction's right ceiling fitting painted on the far plate (lamps[2]
# at 0.857, 0.268 of the plate, drawn at clamp-world (835, 172) on its 4.2 m deep wall). L2: the
# passage's vapour-tight bulkhead fitting on its back wall, just above what the opening shows.
L1 = np.array([(VPX + (835.0 - VPX) / 0.9) / PPM, (FLOOR - HOR - (172.0 - HOR) / 0.9) / PPM, 3.95])
L2 = np.array([24.92, 2.06, Z_PASSAGE_BACK - 0.16])
L3 = None  # set below (needs W)


def parts(lead_s: float, with_leaf: bool = True) -> list:
    P: list = []
    s_bw0 = s_at_z(Z_BACK, 0.0)
    BIG = 9.0
    # --- cross-wall, approach face (n = 0), split around the opening and its steel frame
    P.append(rect_snh("back_face", S_FAR + TRIM, s_bw0, 0, 0, -1.6, BIG, "n", "back", CONCRETE, n_out=-V))
    P.append(rect_snh("below_sill", S_NEAR - TRIM, S_FAR + TRIM, 0, 0, -1.6, -0.0, "n", "back", CONCRETE_CUT, n_out=-V))
    P.append(rect_snh("lintel_face", S_NEAR - TRIM, S_FAR + TRIM, 0, 0, H_OPEN + TRIM, BIG, "n", "front", CONCRETE, n_out=-V))
    P.append(rect_snh("front_face", A_END, S_NEAR - TRIM, 0, 0, STUB_H, BIG, "n", "front", CONCRETE, n_out=-V))
    # the column's end face toward the camera (the wall's 0.66 m cut), its steel arris angles
    P.append(rect_snh("col_end", A_END, A_END, 0.0, T, STUB_H, BIG, "s", "front", CONCRETE, n_out=-U))
    P.append(rect_snh("col_arris_face", A_END, A_END + ARRIS, -0.004, -0.004, STUB_H, BIG, "n", "front", STEEL_FRAME, n_out=-V))
    P.append(rect_snh("col_arris_l", A_END - 0.004, A_END - 0.004, 0.0, ARRIS, STUB_H, BIG, "s", "front", STEEL_FRAME, n_out=-U))
    P.append(rect_snh("col_arris_r", A_END - 0.004, A_END - 0.004, T - ARRIS, T, STUB_H, BIG, "s", "front", STEEL_FRAME, n_out=-U))
    # the stub: approach face, top, steel edge angle, and its cut down through the deck's fascia
    s_stub = s_at_z(DECK_FRONT_Z, 0.0)
    P.append(rect_snh("stub_face", s_stub, S_NEAR - TRIM, 0, 0, 0.0, STUB_H, "n", "front", CONCRETE, n_out=-V))
    P.append(rect_snh("stub_top", s_stub, A_END, 0.0, T, STUB_H, STUB_H, "h", "front", CONCRETE, n_out=UP))
    P.append(rect_snh("stub_angle", s_stub, A_END, -0.004, ARRIS, STUB_H + 0.003, STUB_H + 0.003, "h", "front", SILL_STEEL, n_out=UP))
    xa = W(s_stub, 0.0, 0.0)[0]
    xl = W(s_at_z(DECK_FRONT_Z, T), T, 0.0)[0]
    P.append(Rect("stub_cut", np.array([xa, -1.8, DECK_FRONT_Z - 0.01]), np.array([xl - xa, 0.0, 0.0]), np.array([0.0, 1.8 + STUB_H, 0.0]), "front", CONCRETE_CUT, n_out=-np.array([0, 0, 1.0])))
    # cast-in steel frame (channel) round the opening, flush with the face
    P.append(rect_snh("far_jamb_trim", S_FAR, S_FAR + TRIM, 0, 0, 0.0, H_OPEN + TRIM, "n", "back", STEEL_FRAME, n_out=-V))
    P.append(rect_snh("near_jamb_trim", S_NEAR - TRIM, S_NEAR, 0, 0, 0.0, H_OPEN + TRIM, "n", "front", STEEL_FRAME, n_out=-V))
    P.append(rect_snh("head_trim", S_NEAR - TRIM, S_FAR + TRIM, 0, 0, H_OPEN, H_OPEN + TRIM, "n", "front", STEEL_FRAME, n_out=-V))
    # far reveal (faces the opening, toward the camera): steel-lined, split by the pocket mouth
    P.append(rect_snh("reveal_front", S_FAR, S_FAR, 0.0, SLOT_N0, 0.0, H_OPEN, "s", "back", STEEL_FRAME, n_out=-U))
    P.append(rect_snh("reveal_rear", S_FAR, S_FAR, SLOT_N1, T, 0.0, H_OPEN, "s", "beyond", CONCRETE_CUT, n_out=-U))
    P.append(rect_snh("pocket_dark", S_FAR + 0.35, S_FAR + 0.35, SLOT_N0, SLOT_N1, 0.0, H_OPEN, "s", "beyond", DARK, n_out=-U))
    P.append(rect_snh("pocket_side", S_FAR, S_FAR + 3.0, SLOT_N1, SLOT_N1, 0.0, H_OPEN, "n", "beyond", DARK, n_out=-V))
    # near reveal (faces away; kept for occlusion and shadows), soffit (faces down)
    P.append(rect_snh("reveal_near", S_NEAR, S_NEAR, 0.0, T, 0.0, H_OPEN, "s", "front", CONCRETE_CUT, n_out=U))
    P.append(rect_snh("soffit", S_NEAR, S_FAR, 0.0, T, H_OPEN, H_OPEN, "h", "front", CONCRETE_CUT, n_out=-UP))
    # sill: steel threshold plate on the wall's sill, the leaf's bottom track slot in it
    P.append(rect_snh("sill", S_NEAR, S_FAR, 0.0, T, 0.0, 0.0, "h", "back", SILL_STEEL, n_out=UP))
    P.append(rect_snh("pocket_floor", S_FAR, S_FAR + 3.0, SLOT_N0, SLOT_N1, 0.0, 0.0, "h", "beyond", DARK, n_out=UP))
    # --- exit bolt: an electric locking bolt in a steel housing over the head, its bolt dropping
    # through the head frame into a keeper on the leaf's top edge (UFGS 08 39 54 2.2.2: latching
    # points at the head; latch bolts slide into a strike).
    P += box_snh("bolt_box", 0.02, 0.36, -0.17, 0.0, H_OPEN + TRIM + 0.05, H_OPEN + TRIM + 0.33, "front", HOUSING)
    # its feed: 25 mm rigid conduit along the head line to the status lamp's back box, then down the
    # wall into the lower level behind the deck (straps within 0.9 m of each box)
    hc = H_OPEN + TRIM + 0.19
    P += box_snh("conduit_run", 0.36, 1.86, -0.045, 0.0, hc - 0.022, hc + 0.022, "front", HOUSING, faces=("front", "top", "bottom"))
    for i, sc in enumerate((0.95, 1.55)):
        P += box_snh(f"strap_run{i}", sc, sc + 0.04, -0.055, 0.0, hc - 0.035, hc + 0.035, "front", HOUSING, faces=("front", "top", "lead"))
    # wall pack over the door (vapour-tight LED bulkhead, 0.5 x 0.2 m) lighting the door face and the
    # threshold (L3), fed by a short conduit up from the bolt run
    P += box_snh("wallpack", PACK_S0, PACK_S1, -0.26, 0.0, PACK_H0, PACK_H0 + 0.2, "front", HOUSING)
    # fix round 2 (S7): a wall pack throws its light forward and down through a glass on its FRONT (a
    # forward-throw LED wall pack); the camera, 7 m up, sees that glass lit, never the box's underside.
    # Its pool falls on the leaf, the threshold and the deck in front (L3).
    P.append(rect_snh("wallpack_lens", PACK_S0 + 0.04, PACK_S1 - 0.04, -0.262, -0.262, PACK_H0 + 0.03, PACK_H0 + 0.15, "n", "front", LAMP_GLASS, emissive=1.0, n_out=-V))
    P += box_snh("conduit_pack", 1.10, 1.144, -0.045, 0.0, hc + 0.022, PACK_H0, "front", HOUSING, faces=("front", "lead"))
    # status lamp: guarded globe on a back box on the wall left of the opening (red shut, amber moving,
    # green open: its lens is the live sprite)
    P += box_snh("lamp_box", 1.86, 2.10, -0.10, 0.0, hc - 0.12, hc + 0.10, "back", HOUSING)
    P += box_snh("conduit_down", 1.958, 2.002, -0.045, 0.0, -1.6, hc - 0.12, "back", HOUSING, faces=("front", "lead"))
    for i, hh in enumerate((2.05, 1.25, 0.45)):
        P += box_snh(f"strap_down{i}", 1.945, 2.015, -0.055, 0.0, hh, hh + 0.04, "back", HOUSING, faces=("front", "top", "lead"))
    gc = W(1.98, -0.17, hc - 0.01)
    P.append(Sphere("lamp_globe", gc, 0.065, "lens", LAMP_GLASS))
    for i, ds in enumerate((-0.07, 0.0, 0.07)):
        P += box_snh(f"lamp_guard{i}", 1.98 + ds - 0.007, 1.98 + ds + 0.007, -0.255, -0.24, hc - 0.09, hc + 0.07, "back", HOUSING, faces=("front", "lead"))
    P += box_snh("lamp_guard_cap", 1.89, 2.07, -0.26, -0.10, hc + 0.07, hc + 0.085, "back", HOUSING, faces=("front", "top", "lead"))
    # fix round 2 (human: "smooth empty slab"): the room's pipe runs on its back wall (far plate: four
    # lines 0.3 m off the wall at 2.4-3.4 m, measured in j08) end at this wall's back corner: they pass
    # through it into the passage, each through a welded wall sleeve with a steel escutcheon collar on
    # the face (the collar's ring seen nearly edge-on at this turn).
    for i, (hp, rp) in enumerate(PIPE_RUNS_EXIT):
        s_in = s_at_z(Z_BACK - 0.30, 0.0)
        rc = rp + 0.06
        P.append(rect_snh(f"pipe_collar{i}", s_in - rc, min(s_in + rc, s_at_z(Z_BACK, 0.0) - 0.01), -0.012, -0.012, hp - rc, hp + rc, "n", "back", HOUSING, n_out=-V))
        P.append(rect_snh(f"pipe_stub{i}", s_at_z(Z_BACK, 0.0) - 0.01, s_in, -0.30 + 0.30, -0.30 + 0.30, hp - rp, hp + rp, "n", "back", PIPE, n_out=-V))
    # --- leaf (moves): a sliding steel leaf running in the wall's middle on bottom rollers in the sill
    # track, into a pocket in the far jamb
    if with_leaf:
        P += leaf_parts(lead_s)
    # --- passage beyond (background): its floor and back wall, the service line on brackets, the fitting
    xo = W(s_at_z(Z_PASSAGE_BACK, T), T, 0.0)[0] - 0.05
    P.append(rect_snh("pass_floor", -8.0, 4.0, T - 0.01, T + 5.0, 0.0, 0.0, "h", "beyond", PASS_FLOOR, "beyond", n_out=UP))
    P.append(Rect("pass_wall", np.array([xo, 0.0, Z_PASSAGE_BACK]), np.array([4.0, 0.0, 0.0]), np.array([0.0, 8.5, 0.0]), "beyond", PASS_CONCRETE, "beyond", n_out=-np.array([0, 0, 1.0])))
    pz = Z_PASSAGE_BACK - 0.22
    # the passage's vapour-tight bulkhead fitting on its back wall at 2.05 m (L2 sits in front of its lens)
    P += [Rect("pass_fitting_body", np.array([L2[0] - 0.2, 1.98, Z_PASSAGE_BACK - 0.09]), np.array([0.4, 0.0, 0.0]), np.array([0.0, 0.16, 0.0]), "beyond", HOUSING, "beyond", n_out=-np.array([0, 0, 1.0])),
          Rect("pass_fitting", np.array([L2[0] - 0.16, 2.0, Z_PASSAGE_BACK - 0.1]), np.array([0.32, 0.0, 0.0]), np.array([0.0, 0.12, 0.0]), "beyond", LAMP_GLASS, "beyond", emissive=1.0, n_out=-np.array([0, 0, 1.0]))]
    # the junction's deck in front of the walk line: not ours (the mid plate draws it), but it hides
    # whatever lies behind and below it
    P.append(Rect("deck_key", np.array([18.0, 0.0, DECK_FRONT_Z]), np.array([10.0, 0.0, 0.0]), np.array([0.0, 0.0, -DECK_FRONT_Z]), "key", DARK, "key", n_out=UP))
    # the deck's fascia (its front face, down to the lower level): nothing of the wall shows through it
    P.append(Rect("fascia_key", np.array([18.0, -3.0, DECK_FRONT_Z]), np.array([10.0, 0.0, 0.0]), np.array([0.0, 3.0, 0.0]), "key", DARK, "key", n_out=-np.array([0, 0, 1.0])))
    return P


def leaf_parts(lead_s: float) -> list:
    s0, s1 = lead_s, lead_s + LEAF_W
    out = [
        rect_snh("leaf_face", s0, s1, LEAF_N0, LEAF_N0, 0.004, LEAF_H, "n", "leaf", STEEL_FRAME, "leaf", n_out=-V),
        rect_snh("leaf_edge", s0, s0, LEAF_N0, LEAF_N1, 0.004, LEAF_H, "s", "leaf", YELLOW, "leaf", n_out=-U),
        rect_snh("leaf_top", s0, s1, LEAF_N0, LEAF_N1, LEAF_H, LEAF_H, "h", "leaf", STEEL_FRAME, "leaf", n_out=UP),
    ]
    return out


# ---------------------------------------------------------------- ray casting

def rays(X: np.ndarray, Y: np.ndarray):
    """Ray through world-screen points (X, Y): p(z) = P0 + z * B."""
    P0 = np.stack([X / PPM, (FLOOR - Y) / PPM, np.zeros_like(X)], -1)
    B = np.stack([(X - VPX) / (D0 * PPM), -(Y - HOR) / (D0 * PPM), np.ones_like(X)], -1)
    return P0, B


def hit_rect(r: Rect, P0, B):
    nd = (B * r.n).sum(-1)
    with np.errstate(divide="ignore", invalid="ignore"):
        z = (np.dot(r.o, r.n) - (P0 * r.n).sum(-1)) / nd
    p = P0 + z[..., None] * B
    d = p - r.o
    ua = (d * r.a).sum(-1) / np.dot(r.a, r.a)
    vb = (d * r.b).sum(-1) / np.dot(r.b, r.b)
    ok = (ua >= 0) & (ua <= 1) & (vb >= 0) & (vb <= 1) & (z > -D0 + 0.5) & np.isfinite(z)
    # facing: the camera must be on the n side (rays travel +z, so B . n < 0)
    ok &= nd < 0
    return np.where(ok, z, np.inf), p, ua, vb


def hit_sphere(sp: Sphere, P0, B):
    # p(z) = P0 + z B; |p - c|^2 = r^2 -> quadratic in z
    d = P0 - sp.c
    a = (B * B).sum(-1)
    b = 2 * (B * d).sum(-1)
    c = (d * d).sum(-1) - sp.r ** 2
    disc = b * b - 4 * a * c
    with np.errstate(invalid="ignore"):
        z = (-b - np.sqrt(disc)) / (2 * a)
    ok = disc >= 0
    z = np.where(ok, z, np.inf)
    p = P0 + np.where(ok, z, 0)[..., None] * B
    return z, p


def occluded(points: np.ndarray, light: np.ndarray, occluders: list, skip: str | None = None) -> np.ndarray:
    """True where the segment from each point to the light crosses an occluder rectangle (either side)."""
    d = light - points
    out = np.zeros(points.shape[:-1], bool)
    for r in occluders:
        if not isinstance(r, Rect) or r.name == skip:
            continue
        nd = (d * r.n).sum(-1)
        with np.errstate(divide="ignore", invalid="ignore"):
            t = (np.dot(r.o, r.n) - (points * r.n).sum(-1)) / nd
        p = points + t[..., None] * d
        q = p - r.o
        ua = (q * r.a).sum(-1) / np.dot(r.a, r.a)
        vb = (q * r.b).sum(-1) / np.dot(r.b, r.b)
        out |= (t > 1e-3) & (t < 0.999) & (ua >= 0) & (ua <= 1) & (vb >= 0) & (vb <= 1)
    return out


L3 = W((PACK_S0 + PACK_S1) / 2, -0.17, PACK_H0 - 0.03)
