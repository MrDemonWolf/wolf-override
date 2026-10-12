"""Option A containment unit: single-source geometry (world px, y down, floor y 440).

Scratch design tool, never part of the repository. Every part below has a job (see DESIGN.md).
Revision 2 (judge's fixes): frame, bars and header brought down to the room's values while the lining
behind WOLF stays light, lit by a caged fitting in the roof (painted, no glow); dock lamp amber in
standby with a 3 px light umbilical; lock lamp green = locked, amber flashing = forced (red is kept for
danger); a 0.25 m lock mounting plate welded to the latch post carries the lock box, lamp and a keypad
backplate; stencils at 8 px caps or blank plates; keypad optional (blank backplate variant).
Scale: 1 m = 39.8 world px (engineer 69.6 px = 1.75 m); rounded to 40 in the tables.
The unit's origin stays where today's IntroCage sits, (115, 365); coordinates here are world.
"""
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PX_PER_M = 39.8
FLOOR = 440.0
FONT = None  # set by caller to Roboto path

# ---- frame -------------------------------------------------------------------------------------
POSTS = [(27, 33), (111, 117), (197, 203)]           # 150 mm SHS posts (6 px)
HEADER = (338, 350)                                   # 300 mm header beam, roof plate edge on top
ROOF_EDGE = (337, 338)
TRACK = (350, 356)                                    # 150 mm enclosed box track, full front
CLEAR_TOP = 356                                       # clear opening 356..440 = 84 px = 2.11 m
CEIL = (356, 359)                                     # roof underside seen through the bars
BACK = (33, 197, 359, 431)                            # 6 mm steel back lining, seen 2.5 m deep
CELL_FLOOR = (431, 436)
SILL = (27, 203, 436, 440)                            # floor guide channel, caught-between stripes
BASE_PLATES = [(24, 36), (108, 120), (194, 206)]      # anchored post base plates
FIXED = (33, 111)                                     # fixed bar panel (left bay)
FIXED_RAILS = [(356, 359), (396, 398), (432, 436)]
BAR_W = 2.0                                           # 50 mm round bar
BAR_PITCH = 5.0                                       # 125 mm centres -> 75 mm clear gap

# ---- leaf (slide gate), closed position --------------------------------------------------------
LEAF = (115, 199)                                     # 84 px = 2.11 m leaf; laps both posts
LEAF_Y = (357, 435)
LEAF_TRAVEL = 82.0                                    # parks over the fixed panel, x 33..117
LEAF_RAILS = [(357, 360), (396, 398), (431, 435)]
LEAF_STILE = 3.0
HANGERS = [(125, 128), (186, 189)]                    # trolley hangers into the track slot
KEEPER = (194, 200, 368, 381)                         # keeper welded to the leading stile

# ---- lock side (keeper's side, outside the cell) -----------------------------------------------
LOCK_BOX = (203, 213, 366, 383)                       # fail-secure hook-bolt lock, 0.25 x 0.43 m
LAMP = (205, 211, 357, 363)                           # guarded status globe on the lock box
LAMP_BASE = (204.5, 211.5, 363, 366)
READER = (205, 211, 387.5, 396.5)                     # card reader + PIN keypad, centre 1.2 m
CONDUIT_X = (207, 209)
FLOOR_BOX = (205, 211, 437, 440)
CAMERA_C = (207.0, 329.0)

# ---- inside ------------------------------------------------------------------------------------
DOCK = (120, 140, 361, 376)                           # standby power/data unit on the lining
DOCK_LAMP = (135, 138, 364, 367)
VENT = (40, 72, 364, 374)                             # cooling vent in the lining
SEAMS = [74, 157]
UMB_TOP = (130.0, 376.0)
UMB_PLUG = (134.5, 395.0)                             # WOLF's withers, measured from the sprite

# ---- colours (flat shading, light from the room fixtures above) --------------------------------
C = dict(
    post="#363c43", post_hi="#565e67", post_lo="#1f2328",
    header="#383e45", header_hi="#5c646e", header_lo="#202429",
    track="#353b42", slot="#14171a", stop="#1d2024",
    back="#3d454d", back_top="#2f363d", back_seam="#2a3036", back_seam_hi="#4a525a",
    cell_floor="#2a3035", cell_edge="#22272c", ceil="#1a1e22",
    bar="#22272c", bar_hi="#4b525a", fbar="#1f2328", fbar_hi="#40464e",
    rail="#383e45", rail_hi="#58606a", rail_lo="#202429",
    yellow="#b98a1f", black="#1b1c1e",
    plate="#3a4047", bolt="#8b949b",
    box="#3f454c", box_hi="#626a73", box_lo="#24292e",
    keypad="#1c2024", key="#6d767f", reader="#2b3036",
    conduit="#5a6169", conduit_lo="#30353b",
    cam="#3b4148", cam_lens="#0d0f11",
    dock="#353b42", dock_hi="#555d66",
    lamp_off="#2a2e2c", lamp_red="#ff4232", lamp_amber="#ffb020", lamp_green="#3cff7a",
    dock_off="#22303a", dock_blue="#6fd6ff", dock_amber="#ffae2a",
    plate_mount="#30363c", fitting="#4f5760", diffuser="#e3e8ec",
    vent="#2b3137", vent_hole="#15191c",
    cable="#121417", coupler="#7a8590", umb="#8a939d", umb_hi="#9ea7b0", umb_lo="#5f6872",
    weld="#c9ccc8", steel_raw="#a9b0b5",
    stencil="#a9a6a8",
)


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


class Painter:
    """Draws world-coordinate primitives onto an RGBA canvas at `scale` px per world px."""

    def __init__(self, x0, y0, x1, y1, scale, bg=(0, 0, 0, 0)):
        self.x0, self.y0, self.s = x0, y0, scale
        self.w = int(round((x1 - x0) * scale))
        self.h = int(round((y1 - y0) * scale))
        self.im = Image.new("RGBA", (self.w, self.h), bg)
        self.d = ImageDraw.Draw(self.im)

    count = 0

    def p(self, x, y):
        Painter.count += 1
        return ((x - self.x0) * self.s, (y - self.y0) * self.s)

    def rect(self, x0, y0, x1, y1, col, a=255):
        (a0, b0), (a1, b1) = self.p(x0, y0), self.p(x1, y1)
        self.d.rectangle([a0, b0, max(a0, a1 - 1), max(b0, b1 - 1)], fill=hexc(col, a) if isinstance(col, str) else col)

    def poly(self, pts, col, a=255):
        self.d.polygon([self.p(*q) for q in pts], fill=hexc(col, a) if isinstance(col, str) else col)

    def line(self, pts, col, w, a=255):
        self.d.line([self.p(*q) for q in pts], fill=hexc(col, a) if isinstance(col, str) else col,
                    width=max(1, int(round(w * self.s))), joint="curve")

    def circle(self, x, y, r, col, a=255):
        (a0, b0), (a1, b1) = self.p(x - r, y - r), self.p(x + r, y + r)
        self.d.ellipse([a0, b0, a1, b1], fill=hexc(col, a) if isinstance(col, str) else col)

    def text(self, x, y, s, size_px, col, anchor="ls", a=255):
        f = ImageFont.truetype(FONT, int(round(size_px * self.s)))
        try:
            f.set_variation_by_axes([700, 100])
        except Exception:
            pass
        self.d.text(self.p(x, y), s, font=f, fill=hexc(col, a), anchor=anchor)


def wash(P, cx, cy, rx, ry, gain, y_min, x0, x1, y1):
    """Painted light from the roof fitting: brightens what is drawn (linear light), elliptical falloff,
    only inside the lining (x0..x1, y_min..y1)."""
    import numpy as np
    a = np.asarray(P.im).astype(np.float64)
    h, w = a.shape[:2]
    ys = np.arange(h) / P.s + P.y0
    xs = np.arange(w) / P.s + P.x0
    X, Y = np.meshgrid(xs, ys)
    I = np.exp(-(((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2)) * (Y >= y_min) * (Y <= y1) * (X >= x0) * (X <= x1)
    rgb = a[..., :3] / 255.0
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    lin = np.clip(lin * (1.0 + gain * I[..., None]), 0, 1)
    a[..., :3] = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055) * 255.0
    P.im = Image.fromarray(np.clip(a + 0.5, 0, 255).astype(np.uint8), "RGBA")
    P.d = ImageDraw.Draw(P.im)


FIT = (60.0, 100.0, 359.0, 362.0)                     # caged bulkhead fitting under the roof


# ---- part painters -----------------------------------------------------------------------------

def bars(P, x0, x1, y0, y1, pitch, first, col, hi):
    x = first
    while x + BAR_W / 2 <= x1 + 0.01:
        if x - BAR_W / 2 >= x0 - 0.01:
            P.rect(x - BAR_W / 2, y0, x + BAR_W / 2, y1, col)
            P.rect(x - BAR_W / 2, y0, x - BAR_W / 2 + 0.6, y1, hi)
        x += pitch


def paint_back(P, state):
    """z 1, behind WOLF: lining, roof underside, cell floor, vent, dock, umbilical, contact shadow."""
    bx0, bx1, by0, by1 = BACK
    P.rect(bx0, CEIL[0], bx1, CEIL[1], C["ceil"])
    P.rect(bx0, by0, bx1, by1, C["back"])
    P.rect(bx0, by0, bx1, by0 + 7, C["back_top"])                     # roof shadow on the lining
    for sx in SEAMS:
        P.rect(sx, by0, sx + 1, by1, C["back_seam"])
        P.rect(sx + 1, by0, sx + 1.5, by1, C["back_seam_hi"])
    P.rect(bx0, CELL_FLOOR[0], bx1, CELL_FLOOR[1], C["cell_floor"])
    P.rect(bx0, CELL_FLOOR[0], bx1, CELL_FLOOR[0] + 0.7, C["cell_edge"])
    # cooling vent (honeycomb at <= 4 px cells, drawn as a staggered hole grid)
    vx0, vx1, vy0, vy1 = VENT
    P.rect(vx0 - 1, vy0 - 1, vx1 + 1, vy1 + 1, C["box_lo"])
    P.rect(vx0, vy0, vx1, vy1, C["vent"])
    row = 0
    y = vy0 + 1.6
    while y < vy1 - 0.8:
        x = vx0 + 1.6 + (1.2 if row % 2 else 0)
        while x < vx1 - 0.8:
            P.circle(x, y, 0.75, C["vent_hole"])
            x += 2.4
        y += 2.1
        row += 1
    # dock unit with penetration flange; its feed leaves through the lining to the far side
    dx0, dx1, dy0, dy1 = DOCK
    P.rect(dx0 - 1.5, dy0 - 1.5, dx1 + 1.5, dy1 + 1.5, C["back_seam"])
    P.rect(dx0, dy0, dx1, dy1, C["dock"])
    P.rect(dx0, dy0, dx1, dy0 + 0.8, C["dock_hi"])
    P.rect(dx0 + 2, dy0 + 3, dx0 + 11, dy0 + 4, C["box_lo"])            # blank ID plate slot
    P.rect(dx0 + 8, dy1 - 3, dx1 - 8, dy1, C["box_lo"])                 # umbilical gland
    lx0, lx1, ly0, ly1 = DOCK_LAMP
    P.rect(lx0 - 0.6, ly0 - 0.6, lx1 + 0.6, ly1 + 0.6, C["box_lo"])
    P.rect(lx0, ly0, lx1, ly1, {"blue": C["dock_blue"], "amber": C["dock_amber"]}.get(state.get("dock"), C["dock_off"]))
    # umbilical: docked (to WOLF's withers), swinging free, or hanging released
    tx, ty = UMB_TOP
    um = state.get("umb", "docked")
    if um == "docked":
        pts = [(tx, ty)] + [(tx + (UMB_PLUG[0] - tx) * t, ty + (UMB_PLUG[1] - ty) * t + 2.2 * math.sin(math.pi * t))
                            for t in [i / 8 for i in range(1, 9)]]
        P.line(pts, C["umb_lo"], 3.0)
        P.line([(x - 0.5, y - 0.4) for x, y in pts], C["umb"], 2.0)
        P.line([(x - 0.9, y - 0.6) for x, y in pts], C["umb_hi"], 0.7)
        P.line([UMB_PLUG, (UMB_PLUG[0] + 1.6, UMB_PLUG[1] + 2.4)], C["coupler"], 3.2)
    elif um == "swing":
        end = (tx + 9.0, ty + 20.0)
        pts = [(tx, ty)] + [(tx + (end[0] - tx) * t, ty + (end[1] - ty) * t + 1.5 * math.sin(math.pi * t)) for t in [i / 8 for i in range(1, 9)]]
        P.line(pts, C["umb"], 3.0)
        P.line([end, (end[0] + 1.6, end[1] + 2.4)], C["coupler"], 3.2)
    else:
        end = (tx + 0.8, ty + 25.0)
        P.line([(tx, ty), (tx + 0.4, ty + 12), end], C["umb"], 3.0)
        P.line([end, (end[0] + 0.2, end[1] + 3.2)], C["coupler"], 3.2)
    # caged bulkhead fitting under the roof; its light on the lining is painted (no runtime glow)
    fx0, fx1, fy0, fy1 = FIT
    wash(P, (fx0 + fx1) / 2, fy1 + 4, 70.0, 50.0, float(__import__("os").environ.get("A_GAIN", "0.9")), fy1, bx0, bx1, CELL_FLOOR[1])
    P.rect(fx0, CEIL[0], fx0 + 1, fy0, C["post_lo"])
    P.rect(fx1 - 1, CEIL[0], fx1, fy0, C["post_lo"])
    P.rect(fx0, fy0, fx1, fy1, C["fitting"])
    P.rect(fx0 + 1, fy1 - 1.0, fx1 - 1, fy1, C["diffuser"])
    for gx in range(int(fx0) + 4, int(fx1), 5):
        P.rect(gx, fy1 - 1.0, gx + 0.6, fy1 + 0.4, C["post_lo"])          # wire guard
    # contact shadow on the room floor along the front (darkest at the contact line)
    for i in range(8):
        a = int(150 * (1 - i / 8) ** 1.6)
        P.rect(24, FLOOR + i, 214, FLOOR + i + 1, (6, 9, 12, a))


def paint_frame(P):
    """z 3: posts, header, fixed bar panel, sill with stripes, base plates and anchors."""
    fx0, fx1 = FIXED
    bars(P, fx0 + 4.5, fx1 - 3, FIXED_RAILS[0][1], FIXED_RAILS[2][0], BAR_PITCH, fx0 + 7.0, C["fbar"], C["fbar_hi"])
    for s0, s1 in ((fx0, fx0 + 4.5), (fx1 - 3, fx1)):
        P.rect(s0, FIXED_RAILS[0][0], s1, FIXED_RAILS[2][1], C["rail"])
        P.rect(s0, FIXED_RAILS[0][0], s0 + 0.6, FIXED_RAILS[2][1], C["rail_hi"])
        P.rect(s1 - 0.6, FIXED_RAILS[0][0], s1, FIXED_RAILS[2][1], C["rail_lo"])
    for r0, r1 in FIXED_RAILS:
        P.rect(fx0, r0, fx1, r1, C["rail"])
        P.rect(fx0, r0, fx1, r0 + 0.6, C["rail_hi"])
        P.rect(fx0, r1 - 0.5, fx1, r1, C["rail_lo"])
    for x0, x1 in POSTS:
        P.rect(x0, HEADER[1], x1, SILL[2], C["post"])
        P.rect(x0, HEADER[1], x0 + 1, SILL[2], C["post_hi"])
        P.rect(x1 - 1, HEADER[1], x1, SILL[2], C["post_lo"])
    P.rect(27, HEADER[0], 203, HEADER[1], C["header"])
    P.rect(27, ROOF_EDGE[0], 203, ROOF_EDGE[1] + 0.4, C["header_hi"])
    P.rect(27, HEADER[1] - 0.7, 203, HEADER[1], C["header_lo"])
    # sill: floor guide channel, yellow/black 45 degree caught-between stripes, worn mid-travel
    sx0, sx1, sy0, sy1 = SILL
    P.rect(sx0, sy0, sx1, sy1, C["black"])
    x = sx0 - 8
    while x < sx1:
        wear = 1.0 - 0.35 * math.exp(-((x - 157) / 30) ** 2)
        col = tuple(int(c * wear + 40 * (1 - wear)) for c in hexc(C["yellow"])[:3]) + (255,)
        P.poly([(x, sy1), (x + 2.5, sy1), (x + 2.5 + 4, sy0), (x + 4, sy0)], col)
        x += 5
    P.rect(sx0, sy0, sx1, sy0 + 0.7, C["post_lo"])
    P.rect(sx0 - 0.01, sy0, sx0, sy1, C["post_lo"])
    for b0, b1 in BASE_PLATES:
        P.rect(b0, 437.4, b1, 440, C["plate"])
        P.rect(b0, 437.4, b1, 437.9, C["post_hi"])
        for bx in (b0 + 1.6, b1 - 1.6):
            P.circle(bx, 438.6, 0.9, C["bolt"])


def paint_leaf(P, torn=False, dx=0.0):
    """z 4: the slide gate leaf (hung on two trolleys, guided in the sill)."""
    lx0, lx1 = LEAF[0] + dx, LEAF[1] + dx
    ly0, ly1 = LEAF_Y
    bars(P, lx0 + LEAF_STILE, lx1 - LEAF_STILE, LEAF_RAILS[0][1], LEAF_RAILS[2][0], BAR_PITCH, lx0 + 5.5, C["bar"], C["bar_hi"])
    for r0, r1 in LEAF_RAILS:
        P.rect(lx0, r0, lx1, r1, C["rail"])
        P.rect(lx0, r0, lx1, r0 + 0.6, C["rail_hi"])
        P.rect(lx0, r1 - 0.6, lx1, r1, C["rail_lo"])
    for s0 in (lx0, lx1 - LEAF_STILE):
        P.rect(s0, ly0, s0 + LEAF_STILE, ly1, C["rail"])
        P.rect(s0, ly0, s0 + 0.7, ly1, C["rail_hi"])
        P.rect(s0 + LEAF_STILE - 0.6, ly0, s0 + LEAF_STILE, ly1, C["rail_lo"])
    for h0, h1 in HANGERS:
        P.rect(h0 + dx, 353, h1 + dx, ly0 + 1, C["rail_lo"])
    kx0, kx1, ky0, ky1 = KEEPER
    if not torn:
        P.rect(kx0 + dx, ky0, kx1 + dx, ky1, C["box"])
        P.rect(kx0 + dx, ky0, kx1 + dx, ky0 + 0.7, C["box_hi"])
        P.rect(kx0 + dx, ky1 - 0.7, kx1 + dx, ky1, C["box_lo"])
        for by in (ky0 + 2.5, ky1 - 2.5):
            P.circle(kx0 + 1.6 + dx, by, 0.8, C["bolt"])
    else:
        # torn weld beads where the keeper was: raw steel on the stile
        for by in (ky0 + 0.5, ky1 - 1.0):
            P.rect(lx1 - LEAF_STILE, by, lx1, by + 0.8, C["weld"])
        P.rect(lx1 - LEAF_STILE + 0.8, ky0 + 2, lx1 - 0.6, ky1 - 2, C["steel_raw"], 120)


def paint_keeper(P, cx, cy, ang):
    w, h = KEEPER[1] - KEEPER[0], KEEPER[3] - KEEPER[2]
    ca, sa = math.cos(ang), math.sin(ang)
    pts = [(cx + ca * x - sa * y, cy + sa * x + ca * y) for x, y in [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]]
    P.poly(pts, C["box"])
    P.line([pts[0], pts[1]], C["box_hi"], 0.7)
    P.line([pts[2], pts[3]], C["weld"], 0.7)


def paint_top(P, state):
    """z 4, after the leaf: track (over the hangers), lock box, lamp, reader, conduit, camera, marks."""
    P.rect(27, TRACK[0], 203, TRACK[1], C["track"])
    P.rect(27, TRACK[0], 203, TRACK[0] + 0.6, C["header_lo"])
    P.rect(27, TRACK[1] - 1.0, 203, TRACK[1], C["slot"])
    for bx in range(36, 200, 24):
        P.circle(bx, TRACK[0] + 2.3, 0.7, C["bolt"])
    P.rect(33, TRACK[0] + 1, 35.5, TRACK[1] - 1, C["stop"])               # end stops (rubber)
    P.rect(199, TRACK[0] + 1, 201.5, TRACK[1] - 1, C["stop"])
    P.rect(190, TRACK[0] + 1.2, 195.5, TRACK[0] + 4.2, C["box_lo"])          # gate position switch
    # header marks (proposed text, awaiting Nathanial)
    if state.get("text", True):
        # 8.1 px caps (Roboto caps are 0.711 em): REAL-LOOK section 8 minimum
        P.text(37, HEADER[1] - 1.9, "CU-01", 11.4, C["stencil"], a=225)
        P.text(194, HEADER[1] - 1.9, "KEEP CLEAR 2 M", 11.4, C["stencil"], anchor="rs", a=225)
    else:
        for x0_, x1_ in ((36.0, 72.0), (104.0, 194.0)):
            P.rect(x0_, HEADER[0] + 1.6, x1_, HEADER[1] - 1.4, C["plate"])
            P.rect(x0_, HEADER[0] + 1.6, x1_, HEADER[0] + 2.2, C["header_hi"])
            for rx_ in (x0_ + 1.2, x1_ - 1.2):
                P.circle(rx_, HEADER[0] + 3.0, 0.5, C["bolt"])
                P.circle(rx_, HEADER[1] - 2.8, 0.5, C["bolt"])
    # camera on a wall arm over the latch post, aimed into the cell
    P.rect(199.5, 331, 201.5, HEADER[0], C["post_lo"])
    cx, cy = CAMERA_C
    ang = math.radians(-14)
    ca, sa = math.cos(ang), math.sin(ang)

    def r(x, y):
        return (cx + ca * x - sa * y, cy + sa * x + ca * y)

    P.poly([r(-7, -2.6), r(6, -2.6), r(6, 2.6), r(-7, 2.6)], C["cam"])
    P.poly([r(-8.5, -3.4), r(5, -3.4), r(5, -2.6), r(-8.5, -2.6)], C["box_hi"])  # sun hood
    P.poly([r(-7.6, -1.6), r(-7, -1.6), r(-7, 1.6), r(-7.6, 1.6)], C["cam_lens"])
    P.line([r(6, 0), (203.5, 333), (203.5, HEADER[0])], C["cable"], 0.8)
    # lock mounting plate: 0.25 m x 10 mm plate welded to the latch post, base angle anchored to the slab.
    # Everything on the keeper side sits on it (REAL-LOOK section 8: devices on a backplate or bracket).
    P.rect(203, HEADER[0] + 2, 213, 437.4, C["plate_mount"])
    P.rect(203, HEADER[0] + 2, 213, HEADER[0] + 2.6, C["post_hi"])
    P.rect(212.4, HEADER[0] + 2, 213, 437.4, C["post_lo"])
    for wy in (352.0, 400.0, 428.0):
        P.rect(203, wy, 204, wy + 3, C["weld"], 90)                          # stitch welds to the post
    P.rect(202.5, 436.6, 214, 440, C["plate"])
    P.rect(202.5, 436.6, 214, 437.1, C["post_hi"])
    P.circle(212.4, 438.6, 0.8, C["bolt"])
    # lock box on the mounting plate (keeper side, out of WOLF's reach)
    x0, x1, y0, y1 = LOCK_BOX
    P.rect(x0, y0, x1, y1, C["box"])
    P.rect(x0, y0, x1, y0 + 0.8, C["box_hi"])
    P.rect(x1 - 0.8, y0, x1, y1, C["box_lo"])
    P.rect(x0, y1 - 0.8, x1, y1, C["box_lo"])
    for by in (y0 + 2, y1 - 2):
        P.circle(x1 - 2, by, 0.6, C["bolt"])
    P.circle(208, 378.5, 1.3, C["box_lo"])                                   # manual override cylinder
    P.circle(208, 378.5, 0.6, C["bolt"])
    # guarded status lamp
    P.rect(LAMP_BASE[0], LAMP_BASE[2], LAMP_BASE[1], LAMP_BASE[3], C["box_lo"])
    lamp = {"amber": C["lamp_amber"], "green": C["lamp_green"]}.get(state.get("lamp"), C["lamp_off"])
    P.rect(LAMP[0], LAMP[2], LAMP[1], LAMP[3], lamp)
    P.rect(LAMP[0] + 0.6, LAMP[2] + 0.5, LAMP[0] + 1.6, LAMP[2] + 1.6, (255, 255, 255, 110))
    gx = (LAMP[0] + LAMP[1]) / 2
    P.rect(gx - 0.25, LAMP[2] - 0.6, gx + 0.25, LAMP[3], C["box_lo"], 200)      # wire guard
    P.rect(LAMP[0] - 0.3, LAMP[2] - 0.7, LAMP[1] + 0.3, LAMP[2] - 0.2, C["box_lo"])
    # reader + PIN keypad (keeper side, 1.2 m), nipple to the lock box, conduit down into the slab
    P.rect(CONDUIT_X[0], y1, CONDUIT_X[1], READER[2], C["conduit"])
    rx0, rx1, ry0, ry1 = READER
    P.rect(rx0 - 1.2, ry0 - 2.0, rx1 + 1.2, ry1 + 2.0, C["box_lo"])            # tamper-switched backplate
    P.rect(rx0 - 1.2, ry0 - 2.0, rx1 + 1.2, ry0 - 1.4, C["box_hi"])
    for bx_, by_ in ((rx0 - 0.5, ry0 - 1.2), (rx1 + 0.5, ry0 - 1.2), (rx0 - 0.5, ry1 + 1.2), (rx1 + 0.5, ry1 + 1.2)):
        P.circle(bx_, by_, 0.35, C["bolt"])
    if state.get("keypad", True):
        P.rect(rx0, ry0, rx1, ry1, C["reader"])
        P.rect(rx0, ry0, rx1, ry0 + 0.6, C["box_hi"])
        P.rect(rx0 + 0.8, ry0 + 0.9, rx1 - 0.8, ry0 + 2.6, C["keypad"])              # card zone
        P.rect(rx0 + 1.1, ry0 + 1.2, rx0 + 1.9, ry0 + 2.0, C["lamp_off"])            # reader LED unlit
        P.rect(rx0 + 0.8, ry0 + 3.1, rx1 - 0.8, ry1 - 0.7, C["keypad"])
        for i in range(3):
            for j in range(4):
                P.rect(rx0 + 1.2 + i * 1.3, ry0 + 3.5 + j * 1.2, rx0 + 1.95 + i * 1.3, ry0 + 4.2 + j * 1.2, C["key"])
    else:
        P.rect(rx0, ry0, rx1, ry1, C["plate"])                                       # blanking cover
        P.rect(rx0, ry0, rx1, ry0 + 0.6, C["box_hi"])
    P.rect(CONDUIT_X[0], ry1, CONDUIT_X[1], FLOOR_BOX[2], C["conduit"])
    P.rect(CONDUIT_X[1] - 0.5, ry1, CONDUIT_X[1], FLOOR_BOX[2], C["conduit_lo"])
    P.rect(CONDUIT_X[0] - 1, 417, CONDUIT_X[1] + 1, 418.4, C["box_lo"])      # strap
    P.rect(FLOOR_BOX[0], FLOOR_BOX[2], FLOOR_BOX[1], FLOOR_BOX[3], C["plate"])
    P.rect(FLOOR_BOX[0], FLOOR_BOX[2], FLOOR_BOX[1], FLOOR_BOX[2] + 0.5, C["post_hi"])
    if state.get("bolt_exposed"):
        # the hook bolt still thrown, its keeper gone: raw steel out of the post face
        P.rect(197.5, 372.5, 203, 375.5, C["steel_raw"])
        P.rect(197.5, 375.5, 199.5, 378, C["steel_raw"])
        P.rect(197.5, 372.5, 203, 373.1, (255, 255, 255, 160))


def glow(radius_x, radius_y, color, peak, scale):
    """Additive glow texture (one sprite), gaussian falloff, sized tight."""
    w, h = int(radius_x * 2 * scale), int(radius_y * 2 * scale)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    r, g, b, _ = hexc(color)
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - w / 2) / (w / 2)
            dy = (y + 0.5 - h / 2) / (h / 2)
            k = math.exp(-3.2 * (dx * dx + dy * dy)) - math.exp(-3.2)
            k = max(0.0, k) * peak
            px[x, y] = (int(r * k), int(g * k), int(b * k), 255)
    return im
