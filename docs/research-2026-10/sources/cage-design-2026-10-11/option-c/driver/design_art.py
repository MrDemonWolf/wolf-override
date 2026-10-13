"""Option C: flat-shaded design layers for WOLF's standby bay (scratch, design drawing only, not final art).

Revision 2 (2026-10-11, after the judge's fixes): roof fitting and painted light on the back plate, a
readable umbilical and connector, a cradle that reads as a robot stand, a lock pilaster carrying the guard
lock, keypad backplate, status lamp, camera and floor box, a hook bolt, 8 px stencils or blank plates,
and a blank 1.2 m backplate as the no-keypad alternative.

Draws every part from one table of measured local coordinates (origin = world (115, 365), 1 m = 40 px,
floor = local y 75) into separate layer PNGs at S px per world px:
  back.png            the bay behind WOLF (z 1): back plate lit by the roof fitting, fitting, conduit,
                      charger cabinet, cradle on its plinth, umbilical reel
  leaf.png            one telescoping mesh leaf (z 3)
  leaf_lead.png       the leading leaf: hazard-striped stile and handle module (hook bolt drawn live)
  leaf_plain.png, leaf_lead_plain.png   the same leaves with a flat tone instead of mesh (shimmer test)
  frame.png           the frame (z 4) with 8 px stencils and the keypad
  frame_notext.png    blank equipment plates instead of stencils, keypad kept
  frame_plain.png     blank plates and a blank 1.2 m backplate (no text, no keypad): the alternative
                      that needs no exception from Nathanial
  lock.png            the guard-lock module (drawn live: intact, or torn off and hanging by its cable)
The same functions draw the construction drawing at a larger scale (see sheets.py).
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

FONT = sys.argv[2] if len(sys.argv) > 2 else ""


def hexc(h: str, a: float = 1.0) -> tuple[int, int, int, int]:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), int(round(a * 255)))


STEEL = hexc("#30363e")
STEEL_LIT = hexc("#5c6571")
STEEL_DARK = hexc("#161a1f")
LEAF = hexc("#383f48")
LEAF_LIT = hexc("#606a76")
MESH = (13, 18, 23, 56)
STRAND = (140, 158, 178, 38)
BACK_PLATE = hexc("#252b32")
BACK_SEAM = hexc("#0f1317")
CABINET = hexc("#2b3138")
HAZARD = hexc("#d39a1c")
HAZARD_DARK = hexc("#16191c")
STENCIL = hexc("#a9a6a8")
PLATE = hexc("#454d57")
SOCKET = hexc("#141a1f")
CONDUIT = hexc("#3f4750")
CRADLE = hexc("#4a535d")
CRADLE_LIT = hexc("#76808c")
CABLE = hexc("#8a939d")
CABLE_LIT = hexc("#b1b9c1")
CABLE_SHADE = hexc("#5f6872")
CONNECTOR = hexc("#7a8590")
COPPER = hexc("#b9824f")
RUBBER = hexc("#1d2226")
FITTING = hexc("#5c6571")
DIFFUSER = hexc("#e3e8ec")

# Stencils: Roboto caps are 0.711 em, so 11.4 world px type gives 8.1 px caps (REAL-LOOK section 8 minimum 8).
STENCIL_SIZE = 11.4
# Kick plate top (local y). Revision 2: 0.15 m [6] instead of 0.30 m, so WOLF's legs and feet read.
KICK_Y = 63.0
# The roof fitting, in local coordinates: a vapour-tight LED fitting hung on two stems under the bay roof.
FIT_X0, FIT_X1, FIT_Y = -40.0, 6.0, -16.0
# Painted light from the fitting: centre x, centre y, radius x, radius y, gain (linear light).
import os as _os
WASH = tuple(float(v) for v in _os.environ.get("C_WASH", "-12,-8,80,65,3.4").split(","))


class Painter:
    """Draws in local world coordinates onto an RGBA image covering bbox (x0, y0, x1, y1) at s px per
    world px, supersampled ss times, with real alpha blending for translucent fills."""

    def __init__(self, bbox: tuple[float, float, float, float], s: float, ss: int = 2):
        self.x0, self.y0, self.x1, self.y1 = bbox
        self.s = s
        self.ss = ss
        self.k = s * ss
        w = int(round((self.x1 - self.x0) * self.k))
        h = int(round((self.y1 - self.y0) * self.k))
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    def p(self, x: float, y: float) -> tuple[float, float]:
        return ((x - self.x0) * self.k, (y - self.y0) * self.k)

    def _blend(self, fn, color) -> None:
        if color[3] >= 255:
            fn(ImageDraw.Draw(self.im), color)
        else:
            layer = Image.new("RGBA", self.im.size, (0, 0, 0, 0))
            fn(ImageDraw.Draw(layer), color)
            self.im = Image.alpha_composite(self.im, layer)

    def rect(self, x: float, y: float, w: float, h: float, color) -> None:
        a = self.p(x, y)
        b = self.p(x + w, y + h)
        self._blend(lambda d, c: d.rectangle([a[0], a[1], b[0] - 1, b[1] - 1], fill=c), color)

    def poly(self, pts, color) -> None:
        q = [self.p(x, y) for x, y in pts]
        self._blend(lambda d, c: d.polygon(q, fill=c), color)

    def circle(self, cx: float, cy: float, r: float, color) -> None:
        a = self.p(cx - r, cy - r)
        b = self.p(cx + r, cy + r)
        self._blend(lambda d, c: d.ellipse([a[0], a[1], b[0], b[1]], fill=c), color)

    def line(self, x0: float, y0: float, x1: float, y1: float, width: float, color) -> None:
        a = self.p(x0, y0)
        b = self.p(x1, y1)
        self._blend(lambda d, c: d.line([a, b], fill=c, width=max(1, int(round(width * self.k)))), color)

    def text(self, x: float, y: float, s: str, size: float, color) -> None:
        font = ImageFont.truetype(FONT, int(round(size * self.k)))
        a = self.p(x, y)
        self._blend(lambda d, c: d.text(a, s, fill=c, font=font, anchor="ls"), color)

    def wash(self, cx: float, cy: float, rx: float, ry: float, gain: float, y_min: float) -> None:
        """Painted light from one fitting: brightens what is already drawn (in linear light) with an
        elliptical falloff centred on the fitting, only below y_min (the fitting throws no light up)."""
        a = np.asarray(self.im).astype(np.float64)
        h, w = a.shape[:2]
        ys = (np.arange(h) / self.k) + self.y0
        xs = (np.arange(w) / self.k) + self.x0
        X, Y = np.meshgrid(xs, ys)
        r2 = ((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2
        I = np.exp(-r2) * (Y >= y_min)
        rgb = a[..., :3] / 255.0
        lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
        lin = lin * (1.0 + gain * I[..., None])
        lin = np.clip(lin, 0, 1)
        srgb = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)
        a[..., :3] = srgb * 255.0
        self.im = Image.fromarray(np.clip(a + 0.5, 0, 255).astype(np.uint8), "RGBA")

    def result(self) -> Image.Image:
        if self.ss == 1:
            return self.im
        return self.im.resize((self.im.width // self.ss, self.im.height // self.ss), Image.LANCZOS)


BACK_BBOX = (-82.0, -21.0, 82.0, 75.0)
LEAF_BBOX = (0.0, -21.0, 44.0, 69.0)
FRAME_BBOX = (-93.0, -45.0, 100.0, 81.0)
LOCK_BBOX = (0.0, 0.0, 8.0, 14.0)
LOCK_AT = (80.0, 27.0)          # guard lock top-left on the latch post / pilaster face
LAMP_AT = (92.0, 18.3)          # status lamp on the pilaster's backplate
PILASTER = (86.0, 98.0)         # 0.30 m steel column bolted to the latch post's outer face


def draw_back(g: Painter) -> None:
    g.rect(-82, -21, 164, 96, BACK_PLATE)
    for sx in (-27.0, 27.0):
        g.rect(sx - 0.5, -21, 1, 96, BACK_SEAM)
    # Panel bolts along the seams (they catch the fitting's light).
    for sx in (-27.0, 27.0):
        for sy in (-12.0, 20.0, 52.0):
            g.rect(sx - 2.2, sy, 1.2, 1.2, hexc("#3a424b"))
            g.rect(sx + 1.0, sy, 1.2, 1.2, hexc("#3a424b"))
    # Conduit: cabinet up the back wall, along under the roof to the fitting and the reel.
    g.rect(-71, -19, 2, 42, CONDUIT)
    g.rect(-71, -19.5, 96, 1.6, CONDUIT)
    for sx, sy in ((-70, 4), (-50, -20), (-12, -20)):
        g.rect(sx - 1.5, sy - 0.5, 3, 2.4, hexc("#555e69"))
    # Charger and cell-controller cabinet.
    g.rect(-79, 23, 20, 52, CABINET)
    g.rect(-79, 23, 20, 1, STEEL_LIT)
    g.rect(-69.5, 25, 1, 48, STEEL_DARK)
    for ly in (30.0, 33.0, 36.0):
        g.rect(-77, ly - 0.5, 6, 1, STEEL_DARK)
    g.rect(-66, 28, 5, 3, hexc("#59616c"))
    # Floor conduit from the cabinet to the cradle plinth, on clips (visible above the sill when open).
    g.rect(-59, 65.5, 57, 1.8, CONDUIT)
    g.rect(-59, 65.5, 57, 0.6, STEEL_LIT)
    for sx in (-45.0, -20.0):
        g.rect(sx, 65, 1.5, 3, hexc("#555e69"))
    # Cradle (robot stand): plinth with base flange and anchors, column, V saddle, contact pad.
    g.rect(-3, 61, 28, 14, STEEL)                       # plinth 0.70 x 0.35 m
    g.rect(-3, 61, 28, 1.2, CRADLE_LIT)                 # flange top edge, lit
    g.rect(-3, 62.2, 28, 0.8, STEEL_DARK)
    for ax in (-1.0, 21.5):                             # anchor nuts on the flange
        g.rect(ax, 59.6, 2.5, 1.6, hexc("#9aa3ad"))
        g.rect(ax + 0.6, 58.8, 1.3, 0.8, hexc("#c3cad1"))
    for gx in (3.0, 17.0):                              # gussets
        g.poly([(gx, 61), (gx + 2, 61), (gx + 2, 55), (gx + 1.6, 55)], CRADLE)
    g.rect(6, 47, 10, 14, CRADLE)                       # column
    g.rect(6, 47, 1, 14, CRADLE_LIT)
    g.rect(15, 47, 1, 14, hexc("#353c44"))
    g.rect(2, 45, 18, 2.5, CRADLE)                      # saddle beam
    g.rect(-2, 42, 26, 3, CRADLE)                       # U saddle
    g.rect(-2, 39.5, 3, 3, CRADLE)                      # side lips that keep him centred
    g.rect(21, 39.5, 3, 3, CRADLE)
    g.rect(-2, 39.5, 3, 0.6, CRADLE_LIT)
    g.rect(21, 39.5, 3, 0.6, CRADLE_LIT)
    g.rect(1, 41, 20, 1.6, RUBBER)                      # rubber contact pad
    for cx in (6.0, 14.0):                              # charging contacts in the pad
        g.rect(cx, 40.6, 2.5, 1.0, COPPER)
    # Umbilical reel hung from the roof.
    g.rect(12, -21, 3, 4, STEEL_DARK)
    g.rect(19, -21, 3, 4, STEEL_DARK)
    g.rect(9, -17, 16, 8, STEEL)
    g.rect(9, -17, 16, 1, STEEL_LIT)
    g.circle(17, -13, 3.0, STEEL_DARK)
    # The roof fitting: two stems, housing, diffuser. Light is painted in, no runtime glow.
    for sx in (FIT_X0 + 4, FIT_X1 - 4):
        g.rect(sx - 0.5, -21, 1, 5, STEEL_DARK)
    # Painted light from the fitting onto everything in the bay (one light logic).
    g.wash(cx=WASH[0], cy=WASH[1], rx=WASH[2], ry=WASH[3], gain=WASH[4], y_min=FIT_Y + 1)
    # Under the roof, above the fitting, stays in shadow.
    g.rect(-82, -21, 164, 5, (0, 0, 0, 40))
    g.rect(FIT_X0, FIT_Y, FIT_X1 - FIT_X0, 3, FITTING)
    g.rect(FIT_X0, FIT_Y, FIT_X1 - FIT_X0, 0.8, hexc("#7a838e"))
    g.rect(FIT_X0 + 1, FIT_Y + 2.2, FIT_X1 - FIT_X0 - 2, 1.2, DIFFUSER)
    # Top faces facing the fitting catch it (cabinet lid, plinth flange, saddle edge).
    g.rect(-79, 23, 20, 0.8, hexc("#8a949f"))
    g.rect(-2, 42, 26, 0.5, hexc("#9aa4ae"))


def draw_umbilical(g: Painter, released: bool, lamp=None) -> None:
    """The umbilical (3 px, lighter than the plate) and its breakaway connector. Plugged into WOLF's back in
    standby; once the lock goes, the connector has let go and the spring reel has wound it up."""
    head_y = -7.0 if released else 20.0
    top = -9.0
    g.rect(15.5, top, 3, head_y - top + 1, CABLE)
    g.rect(15.5, top, 0.8, head_y - top + 1, CABLE_LIT)
    g.rect(17.7, top, 0.8, head_y - top + 1, CABLE_SHADE)
    g.rect(15.0, head_y - 2.0, 4, 2.2, hexc("#3a424b"))       # strain relief
    g.rect(13.5, head_y, 7, 12, CONNECTOR)                     # connector housing
    g.rect(13.5, head_y, 7, 0.8, hexc("#a9b2bb"))
    g.rect(13.5, head_y + 5.0, 7, 1.6, hexc("#2b3138"))       # latch band
    g.rect(13.5, head_y + 10.2, 7, 1.8, hexc("#1b2026"))      # mating face
    lens = (17.0, head_y + 2.6)
    if lamp is None:
        g.rect(lens[0] - 1.2, lens[1] - 1.2, 2.4, 2.4, hexc("#141a1f"))
    else:
        g.circle(lens[0], lens[1], 4.0, lamp[:3] + (90,))
        g.rect(lens[0] - 1.5, lens[1] - 1.5, 3, 3, lamp)


def draw_leaf(g: Painter, leading: bool, plain: bool = False) -> None:
    if plain:
        g.rect(3, -18, 38, KICK_Y + 18, MESH)
        g.rect(3, -18, 38, KICK_Y + 18, (STRAND[0], STRAND[1], STRAND[2], 17))
    else:
        g.rect(3, -18, 38, KICK_Y + 18, MESH)
        sx = 3.0
        while sx < 41:
            g.rect(sx, -18, 0.75, KICK_Y + 18, STRAND)
            sx += 3.0
        sy = -18.0
        while sy < KICK_Y:
            g.rect(3, sy, 38, 0.75, STRAND)
            sy += 3.0
    g.rect(0, -21, 3, 90, LEAF)
    g.rect(41, -21, 3, 90, LEAF)
    g.rect(0, -21, 44, 3, LEAF)
    g.rect(3, 26, 38, 2, LEAF)
    g.rect(0, -21, 44, 1, LEAF_LIT)
    g.rect(3, 26, 38, 1, LEAF_LIT)
    g.rect(0, -21, 1, 90, LEAF_LIT)
    g.rect(0, KICK_Y, 44, 69 - KICK_Y, hexc("#323940"))
    g.rect(0, KICK_Y, 44, 1, LEAF_LIT)
    if leading:
        stile = Painter((40.0, -21.0, 44.0, 69.0), g.s, g.ss)
        stile.rect(40, -21, 4, 90, HAZARD_DARK)
        y = -24.0
        while y < 69:
            stile.poly([(40, y), (44, y - 2), (44, y + 1), (40, y + 3)], HAZARD)
            y += 6.0
        tile = stile.im
        g.im.alpha_composite(tile, (int(round((40 - g.x0) * g.k)), int(round((-21 - g.y0) * g.k))))
        # Handle module that throws the hook bolt into the guard lock.
        g.rect(33, 28, 7, 11, hexc("#2c3239"))
        g.rect(33, 28, 7, 1, LEAF_LIT)


def draw_hook_bolt(g: Painter, x: float, thrown: bool) -> None:
    """The hook bolt from the handle module: a bar with a downturned hook that catches behind the keeper,
    so the leaf can be neither slid open nor pried outward while the lock holds."""
    if thrown:
        g.rect(x, 32, 4.5, 2.0, hexc("#9aa3ad"))
        g.rect(x + 3.0, 33.2, 1.5, 2.6, hexc("#9aa3ad"))
    else:
        g.rect(x, 32, 1.5, 2.0, hexc("#9aa3ad"))


def _stencil_or_plate(g: Painter, stencils: bool) -> None:
    if stencils:
        g.text(-80, -24.2, "CU-01", STENCIL_SIZE, STENCIL)
        g.text(80 - 64.7, -24.2, "KEEP CLEAR", STENCIL_SIZE, STENCIL)
    else:
        # Blank equipment plates (REAL-LOOK section 8: anything not on the approved list is a blank plate).
        for x0, w in ((-81.0, 32.0), (80.0 - 66.0, 66.0)):
            g.rect(x0, -32.0, w, 9.0, PLATE)
            g.rect(x0, -32.0, w, 0.7, hexc("#6a737e"))
            for rx in (x0 + 1.2, x0 + w - 2.4):
                for ry in (-31.0, -25.2):
                    g.rect(rx, ry, 1.2, 1.2, hexc("#7d8691"))


def draw_frame(g: Painter, stencils: bool = True, keypad: bool = True) -> None:
    # Contact shadow, darkest at the contact line.
    for i in range(5):
        g.rect(-92, 75 + i, 191, 1, (0, 0, 0, int(255 * (0.5 - i * 0.1))))
    g.rect(-88, 69, 176, 6, STEEL)
    g.rect(-88, 69, 176, 1, STEEL_LIT)
    g.rect(-82, 71, 164, 1, STEEL_DARK)
    for ax in (-85.0, 0.0):
        g.rect(ax - 7, 73, 14, 2, STEEL_DARK)
        g.rect(ax - 7, 72.5, 14, 0.8, STEEL_LIT)
        for bx in (ax - 5, ax + 4):
            g.rect(bx, 71.5, 1.5, 1.5, hexc("#8b949e"))
    for px in (-88.0, 82.0):
        g.rect(px, -35, 6, 110, STEEL)
        g.rect(px, -35, 1, 110, STEEL_LIT)
        g.rect(px + 5, -35, 1, 110, STEEL_DARK)
    # Rubber closing-edge buffer on the latch post's inner face (where the leading stile lands).
    g.rect(81, -19, 1, 87, RUBBER)
    # Head beam 0.35 m [14] (room for 8 px caps) under a cap plate with equal overhang.
    g.rect(-90, -37, 180, 2, STEEL_DARK)
    g.rect(-90, -37, 180, 1, STEEL_LIT)
    g.rect(-88, -35, 176, 14, STEEL)
    g.rect(-88, -35, 176, 1, STEEL_LIT)
    g.rect(-82, -22, 164, 1, STEEL_DARK)
    g.poly([(-82, -21), (-77, -21), (-82, -16)], STEEL)
    g.poly([(82, -21), (77, -21), (82, -16)], STEEL)
    for bx in (-86.0, 84.5):
        for by in (-32.0, -25.0):
            g.rect(bx, by, 1.5, 1.5, hexc("#7d8691"))
    _stencil_or_plate(g, stencils)

    # LOCK PILASTER: 0.30 m steel column bolted to the latch post, base plate anchored, floor box at its
    # foot. It carries the guard lock, the backplate at 1.2 m, the status lamp and the camera.
    x0, x1 = PILASTER
    g.rect(x0, -33, x1 - x0, 108, hexc("#3a414a"))
    g.rect(x0 - 0.5, -34, x1 - x0 + 0.5, 1.2, STEEL_DARK)   # cap
    g.rect(x0, -33, 1, 108, STEEL_LIT)
    g.rect(x1 - 1, -33, 1, 108, STEEL_DARK)
    for by in (-28.0, 4.0, 46.0):                       # through-bolts into the latch post
        g.rect(x0 + 0.6, by, 1.3, 1.3, hexc("#8b949e"))
    g.rect(x0 - 1, 72.5, x1 - x0 + 1, 2.5, STEEL_DARK)   # base plate
    g.rect(x0 - 1, 72.5, x1 - x0 + 1, 0.7, STEEL_LIT)
    g.rect(x0 + 1, 71.6, 1.5, 1.2, hexc("#8b949e"))
    # Floor box at the foot: lockable cover, conduit enters from above.
    g.rect(x0 + 1.5, 62, x1 - x0 - 2.5, 10.5, hexc("#2c333b"))
    g.rect(x0 + 1.5, 62, x1 - x0 - 2.5, 0.8, STEEL_LIT)
    for sx, sy in ((x0 + 2.5, 63.5), (x1 - 3, 63.5), (x0 + 2.5, 70), (x1 - 3, 70)):
        g.rect(sx, sy, 1.0, 1.0, hexc("#7d8691"))
    # One surface conduit down the pilaster face: camera -> backplate -> floor box, strapped.
    g.rect(95.2, -33, 1.8, 48, hexc("#46505a"))
    g.rect(95.2, 37, 1.8, 25, hexc("#46505a"))
    g.rect(95.2, -33, 0.6, 48, STEEL_LIT)
    g.rect(95.2, 37, 0.6, 25, STEEL_LIT)
    for sy in (-6.0, 50.0):
        g.rect(94.7, sy, 2.8, 1.4, hexc("#59626d"))
    # Camera: fixed housing with a sun hood on a short arm on top of the pilaster, aimed down-left at the
    # door (static art, no glow). Its cable drops into the pilaster conduit.
    g.rect(89.5, -34.5, 7, 1.5, STEEL_DARK)              # mounting plate on the pilaster cap
    g.rect(92.2, -38.0, 1.8, 3.5, hexc("#3f4750"))       # arm
    g.poly([(85.5, -41.0), (97.2, -43.0), (97.6, -39.4), (86.2, -37.6)], hexc("#525b66"))
    g.poly([(84.4, -42.2), (97.4, -44.4), (97.4, -43.1), (85.4, -41.0)], hexc("#3a414a"))   # hood
    g.rect(86.0, -40.6, 11.0, 0.6, hexc("#6e7782"))
    g.poly([(84.9, -40.8), (86.4, -41.0), (86.9, -37.9), (85.4, -37.7)], hexc("#0b0e11"))   # lens
    # Backplate at 1.2 m (pad centre y 27 local = world 392) with the status-lamp socket.
    g.rect(88, 15, 8, 22, hexc("#2e353d"))
    g.rect(88, 15, 8, 1, STEEL_LIT)
    for sx, sy in ((88.6, 15.8), (94.4, 15.8), (88.6, 35.2), (94.4, 35.2)):
        g.rect(sx, sy, 1.0, 1.0, hexc("#7d8691"))
    g.circle(LAMP_AT[0], LAMP_AT[1], 1.9, SOCKET)
    if keypad:
        # Card slot and 12-key PIN pad: proposed lock hardware only, no code entered in the opening.
        g.rect(89, 21.5, 6, 1, hexc("#090c0e"))
        g.rect(89, 24, 6, 9, hexc("#1b2026"))
        for r in range(4):
            for c in range(3):
                g.rect(89.6 + c * 1.8, 24.7 + r * 2.0, 1.0, 1.2, hexc("#7f8a95"))
    else:
        # Blanking cover over the keypad cut-out: a plain plate, four screws.
        g.rect(89, 22, 6, 12, hexc("#353c45"))
        g.rect(89, 22, 6, 0.7, hexc("#5f6873"))
        for sx, sy in ((89.5, 22.6), (93.6, 22.6), (89.5, 32.4), (93.6, 32.4)):
            g.rect(sx, sy, 0.9, 0.9, hexc("#7d8691"))


def draw_lock(g: Painter) -> None:
    g.rect(0, 0, 8, 14, hexc("#2f363e"))
    g.rect(0, 0, 8, 1, STEEL_LIT)
    g.rect(0.8, 5.0, 2.5, 4.0, hexc("#0c0f12"))        # keeper slot the hook bolt enters
    g.rect(4.5, 2.5, 2.5, 1, STEEL_DARK)
    g.rect(4.5, 10.5, 2.5, 1, STEEL_DARK)
    for sx, sy in ((5.8, 0.9), (5.8, 12.2)):           # mounting bolts (they shear when it tears off)
        g.rect(sx, sy, 1.2, 1.2, hexc("#8b949e"))


def layers(s: float, ss: int = 2) -> dict[str, Image.Image]:
    out: dict[str, Image.Image] = {}
    g = Painter(BACK_BBOX, s, ss)
    draw_back(g)
    out["back"] = g.result()
    for name, lead, plain in (("leaf", False, False), ("leaf_lead", True, False),
                              ("leaf_plain", False, True), ("leaf_lead_plain", True, True)):
        g = Painter(LEAF_BBOX, s, ss)
        draw_leaf(g, lead, plain)
        out[name] = g.result()
    for name, st, kp in (("frame", True, True), ("frame_notext", False, True), ("frame_plain", False, False)):
        g = Painter(FRAME_BBOX, s, ss)
        draw_frame(g, st, kp)
        out[name] = g.result()
    g = Painter(LOCK_BBOX, s, ss)
    draw_lock(g)
    out["lock"] = g.result()
    return out


if __name__ == "__main__":
    dest = Path(sys.argv[1])
    dest.mkdir(parents=True, exist_ok=True)
    for name, im in layers(4.0, 2).items():
        im.save(dest / f"{name}.png")
        print(name, im.size)
