"""Option B construction drawing (scratch): front elevation from the spec at game scale with WOLF's
real sprite at his opening position, plus an end section and a plan built from the same numbers."""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import render_lib as R

SPEC, GAME, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
FONT = os.path.join(GAME, "assets/fonts/Roboto-Variable.ttf")
spec = R.load(SPEC)
PXM = 39.8


def F(sz, bold=False):
    f = ImageFont.truetype(FONT, sz)
    try:
        f.set_variation_by_name("Bold" if bold else "Regular")
    except Exception:
        pass
    return f


def m(px):
    return f"{px / PXM:.2f} m"


INK = (28, 34, 40)
DIM = (40, 92, 150)
RED = (180, 50, 40)
PAPER = (236, 238, 233)
W, H = 2400, 1640
sheet = Image.new("RGB", (W, H), PAPER)
d = ImageDraw.Draw(sheet)

# ---------------- title block ----------------
d.text((40, 26), "OPTION B (revision 2)  -  SEALED CONTAINMENT CELL (equipment code CU-01, proposed)", font=F(34, True), fill=INK)
d.text((40, 70), "DESIGN DRAWING, NOT FINAL ART.  Flat-shaded construction render from cell_spec.json.  "
       "Scale: 1 world px = 25.1 mm (1 m = 39.8 px), floor y 440.  Node origin (115, 365).", font=F(19), fill=INK)

# ---------------- front elevation ----------------
VIEW = (0, 288, 240, 472)
K = 5
OX, OY = 40, 150
cv = R.Canvas(VIEW, K, bg=(214, 219, 222, 255), ss=2)
# floor
cv.fill(lambda dd: dd.rectangle([*cv.P(VIEW[0], 440), *cv.P(VIEW[2], VIEW[3])], fill=255), (150, 156, 160, 1.0))
R.draw_prims(cv, spec, 0, 0.0, FONT, keep=lambda p: p["layer"] == "back")
# WOLF, real sprite, real scale and position, standby tint
wolf = Image.open(os.path.join(GAME, "assets/wolf-side-right-provisional.png")).convert("RGBA")
s = 0.18325 * cv.k
ws = wolf.resize((round(wolf.width * s), round(wolf.height * s)), Image.LANCZOS)
tint = (0x36, 0x52, 0x63)
px = ws.load()
r_, g_, b_, a_ = ws.split()
ws = Image.merge("RGBA", (r_.point(lambda v: v * tint[0] // 255), g_.point(lambda v: v * tint[1] // 255), b_.point(lambda v: v * tint[2] // 255), a_))
cx, cy = cv.P(115, 423 - 15)
lay = Image.new("RGBA", cv.img.size, (0, 0, 0, 0))
lay.paste(ws, (round(cx - ws.width / 2), round(cy - ws.height / 2)))
cv.img = Image.alpha_composite(cv.img, lay)
R.draw_prims(cv, spec, 0, 0.0, FONT, keep=lambda p: p["layer"] in ("front", "leaf"))
front = cv.result().convert("RGB")
sheet.paste(front, (OX, OY))


def E(x, y):
    return (OX + (x - VIEW[0]) * K, OY + (y - VIEW[1]) * K)


def dashed(p, q, fill, w=2, dash=10):
    L = math.dist(p, q)
    n = max(1, int(L // dash))
    for i in range(0, n, 2):
        a = (p[0] + (q[0] - p[0]) * i / n, p[1] + (q[1] - p[1]) * i / n)
        b = (p[0] + (q[0] - p[0]) * min(i + 1, n) / n, p[1] + (q[1] - p[1]) * min(i + 1, n) / n)
        d.line([a, b], fill=fill, width=w)


def arrow(p, q, fill, w=2, head=10):
    d.line([p, q], fill=fill, width=w)
    ang = math.atan2(q[1] - p[1], q[0] - p[0])
    for s_ in (-1, 1):
        d.line([q, (q[0] - head * math.cos(ang + s_ * 0.45), q[1] - head * math.sin(ang + s_ * 0.45))], fill=fill, width=w)


def hdim(x0, x1, y, label, sheetfn=E, above=True):
    a, b = sheetfn(x0, y), sheetfn(x1, y)
    arrow(((a[0] + b[0]) / 2, a[1]), a, DIM)
    arrow(((a[0] + b[0]) / 2, a[1]), b, DIM)
    for p in (a, b):
        d.line([(p[0], p[1] - 8), (p[0], p[1] + 8)], fill=DIM, width=2)
    f = F(17)
    tw = d.textlength(label, font=f)
    ty = a[1] - 24 if above else a[1] + 5
    d.rectangle([(a[0] + b[0]) / 2 - tw / 2 - 4, ty, (a[0] + b[0]) / 2 + tw / 2 + 4, ty + 20], fill=PAPER)
    d.text(((a[0] + b[0]) / 2 - tw / 2, ty), label, font=f, fill=DIM)


def vdim(x, y0, y1, label, sheetfn=E, left=True):
    a, b = sheetfn(x, y0), sheetfn(x, y1)
    mid = (a[0], (a[1] + b[1]) / 2)
    arrow(mid, a, DIM)
    arrow(mid, b, DIM)
    for p in (a, b):
        d.line([(p[0] - 8, p[1]), (p[0] + 8, p[1])], fill=DIM, width=2)
    f = F(17)
    lines = label.split("\n")
    tw = max(d.textlength(t, font=f) for t in lines)
    tx = a[0] - tw - 12 if left else a[0] + 12
    d.rectangle([tx - 3, mid[1] - 11 * len(lines), tx + tw + 3, mid[1] + 11 * len(lines)], fill=PAPER)
    for i, t in enumerate(lines):
        d.text((tx, mid[1] - 11 * len(lines) + i * 21), t, font=f, fill=DIM)


# open-leaf ghost and travel
g0, g1 = E(32, 343), E(115, 439)
for p, q in [((g0[0], g0[1]), (g1[0], g0[1])), ((g1[0], g0[1]), (g1[0], g1[1])), ((g1[0], g1[1]), (g0[0], g1[1])), ((g0[0], g1[1]), (g0[0], g0[1]))]:
    dashed(p, q, RED, 3)
d.text((g0[0] + 10, g1[1] - 30), "leaf parked (open)", font=F(17, True), fill=RED)
arrow(E(190, 447.5), E(109, 447.5), RED, 3, 14)
d.text(E(124, 449), "leaf travel 2.04 m / 81 px", font=F(17, True), fill=RED)

# dimensions
hdim(30, 206, 466, f"overall 4.42 m / 176 px (old cage x 27-203)", above=False)
hdim(115, 194, 297, "clear opening 1.98 m / 79 px")
vdim(212, 312.6, 330, "stack 0.44 m", left=False)
vdim(236, 392, 440, "keypad\ncentre\n1.20 m", left=False)

# callouts
CALL = [
    (5, (186, 300), (199, 316)), (1, (231, 340), (201, 352)), (4, (231, 372), (203, 390)),
    (2, (231, 404), (204, 407)), (3, (231, 424), (190, 409)), (14, (231, 452), (201, 432)),
    (10, (206, 300), (193, 348)), (7, (85, 300), (85, 339)), (12, (150, 309), (140, 372)),
    (17, (60, 302), (58, 349)), (16, (16, 318), (35, 323)), (8, (14, 352), (39, 360)),
    (11, (14, 380), (60, 400)), (13, (14, 410), (31, 414)), (15, (14, 437), (27.5, 437)),
    (9, (96, 458), (114, 426)), (6, (140, 458), (150, 424)), (18, (176, 458), (170, 439.4)),
]
for n, b, t in CALL:
    bp, tp = E(*b), E(*t)
    d.line([bp, tp], fill=INK, width=2)
    d.ellipse([tp[0] - 4, tp[1] - 4, tp[0] + 4, tp[1] + 4], fill=INK)
    d.ellipse([bp[0] - 17, bp[1] - 17, bp[0] + 17, bp[1] + 17], fill=PAPER, outline=INK, width=3)
    f = F(18, True)
    tw = d.textlength(str(n), font=f)
    d.text((bp[0] - tw / 2, bp[1] - 11), str(n), font=f, fill=INK)
d.text((OX, OY - 34), "FRONT ELEVATION  (as the camera sees it; closed, standby; WOLF's real sprite at (115, 423), standby tint)", font=F(20, True), fill=INK)
sx, sy = E(6, 462)
d.line([(sx, sy - 2), (sx + 39.8 * K, sy - 2)], fill=INK, width=4)
d.text((sx, sy + 2), "1 m = 39.8 px", font=F(16), fill=INK)

# ---------------- end section A-A (looking from the lock end) ----------------
KS = 2.7
SX, SY = 1440, 160   # sheet position of d=0 (front face) , y world 300


def S_(dpt, y):
    # depth increases to the RIGHT here (front face at left); world y as in game
    return (SX + dpt * KS, SY + (y - 300) * KS)


d.text((1290, 120), "SECTION A-A  (cut across the cell, front to back)", font=F(20, True), fill=INK)


def srect(d0, y0, d1, y1, fill, outline=INK):
    a, b = S_(d0, y0), S_(d1, y1)
    d.rectangle([min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])], fill=fill, outline=outline, width=1)


# slab and floor vault
srect(-40, 440, 140, 452, (170, 170, 165))
for i in range(-40, 140, 6):
    d.line([S_(i, 452), S_(i + 6, 440)], fill=(140, 140, 135), width=1)
srect(-22, 442, -10, 451, (120, 126, 130))
d.text(S_(-46, 455), "floor vault", font=F(15), fill=INK)
srect(0, 436, 115, 440, (95, 108, 116))            # base frame
srect(0, 330, 115, 336, (70, 84, 92))              # roof
srect(0, 336, 6, 355, (70, 84, 92))                # front wall above window
srect(0, 418, 6, 436, (70, 84, 92))                # front wall below window
srect(2, 355, 4, 418, (160, 196, 210))             # glazing in section
srect(109, 336, 115, 436, (70, 84, 92))            # back wall
srect(6, 438.5, 109, 440, (120, 130, 136))         # floor plate
srect(6, 336, 109, 438.5, (200, 206, 208), outline=None)  # interior (light grey)
srect(-5, 343, -2, 439, (58, 70, 78))              # leaf
srect(-4.3, 357, -2.7, 416, (160, 196, 210))
srect(-2, 343, 0, 347, (15, 15, 15)); srect(-2, 434, 0, 438, (15, 15, 15))  # seal
srect(-10, 335, 0, 343, (40, 48, 54))              # track beam
c = S_(-3.5, 338.5); d.ellipse([c[0] - 6, c[1] - 6, c[0] + 6, c[1] + 6], fill=(20, 20, 20))
srect(-6, 438, -1, 440, (150, 150, 150))           # bottom guide
srect(50, 336, 66, 343, (40, 48, 54))              # reel
d.line([S_(58, 343), S_(58, 386)], fill=(15, 18, 20), width=4)
srect(55, 385, 61, 392, (58, 68, 74))
# WOLF envelope in end view (est.)
a, b = S_(41, 377), S_(75, 438)
for p, q in [((a[0], a[1]), (b[0], a[1])), ((b[0], a[1]), (b[0], b[1])), ((b[0], b[1]), (a[0], b[1])), ((a[0], b[1]), (a[0], a[1]))]:
    dashed(p, q, RED, 2, 8)
d.text(S_(24, 368), "WOLF, end view (est.)", font=F(15), fill=RED)
# camera arm
d.line([S_(2, 330), S_(-4, 323)], fill=INK, width=3); srect(-12, 319, -2, 324, (90, 100, 108))
# conduit from JB down to vault
srect(-4, 408, -1, 420, (120, 126, 130)); d.line([S_(-2.5, 420), S_(-2.5, 440), S_(-16, 446)], fill=INK, width=3)
lbl = [((-60, 339), "top-hung box track,\ntrolley, leaf on outside"), ((-62, 400), "armour leaf 0.08 m,\nseal on frame"),
       ((70, 320), "roof 0.15 m"), ((80, 418), "back wall\n0.15 m"), ((64, 350), "umbilical reel")]
for (dd_, yy), t in lbl:
    for i, tl in enumerate(t.split("\n")):
        d.text((S_(dd_, yy)[0], S_(dd_, yy)[1] + i * 18), tl, font=F(15), fill=INK)
# dims
def Sdim_h(d0, d1, y, label):
    hdim(d0, d1, y, label, sheetfn=S_, above=False)
Sdim_h(0, 115, 456, "outer depth 2.90 m / 115 px")
Sdim_h(6, 109, 302, "clear depth 2.60 m")
vdim(130, 343, 440, "clear\n2.44 m", sheetfn=S_, left=False)
vdim(158, 330, 440, "roof\n2.76 m\n110 px", sheetfn=S_, left=False)

# ---------------- plan ----------------
KP = 2.4
PX0, PY0 = 1290, 806   # sheet pos of world x 20, depth 0 (front face)
d.text((1290, 640), "PLAN  (front face toward the camera at the bottom)", font=F(20, True), fill=INK)


def Pp(x, dep):
    # depth increases UP the sheet (back wall at top); front face at dep 0
    return (PX0 + (x - 20) * KP, PY0 + (115 - dep) * KP - 115 * KP + 230)


def prect(x0, d0, x1, d1, fill, outline=INK, w=1):
    a, b = Pp(x0, d0), Pp(x1, d1)
    d.rectangle([min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1])], fill=fill, outline=outline, width=w)


prect(30, 0, 206, 115, (200, 206, 208))
prect(30, 0, 36, 115, (70, 84, 92)); prect(194, 0, 206, 115, (70, 84, 92))   # end wall / pilaster
prect(30, 109, 206, 115, (70, 84, 92))                                      # back wall
prect(36, 0, 115, 6, (70, 84, 92))                                          # fixed front panel
prect(43, 2, 108, 4, (160, 196, 210), outline=None)
prect(113, -5, 196, -2, (58, 70, 78))                                       # leaf closed
for (p, q) in [((32, -6), (115, -6)), ((115, -6), (115, -1)), ((115, -1), (32, -1)), ((32, -1), (32, -6))]:
    dashed(Pp(*p), Pp(*q), RED, 2, 8)
prect(28, -10, 206, -8, (40, 48, 54), outline=None)                         # track line (overhead)
# WOLF top envelope and turning circle
a, b = Pp(59, 40), Pp(174, 72)
d.rounded_rectangle([a[0], b[1], b[0], a[1]], radius=10, outline=RED, width=2)
cc = Pp(115, 57.5); r = 1.2 * PXM * KP
d.ellipse([cc[0] - r, cc[1] - r, cc[0] + r, cc[1] + r], outline=RED, width=2)
d.text((cc[0] - 70, cc[1] - r - 2), "turn: 2.4 m circle fits", font=F(15), fill=RED)
d.text(Pp(64, 66), "WOLF 2.9 x 0.85 m", font=F(15), fill=RED)
# exit path
arrow(Pp(150, 56), Pp(150, -22), RED, 3)
arrow(Pp(150, -22), Pp(232, -22), RED, 3)
d.text(Pp(152, -26), "steps out, turns to the Director", font=F(15), fill=RED)
# Director
dc = Pp(255, -22); d.ellipse([dc[0] - 12, dc[1] - 12, dc[0] + 12, dc[1] + 12], fill=(90, 90, 90))
d.text((dc[0] - 34, dc[1] + 14), "Director", font=F(15), fill=INK)
# keypad, lock, camera FOV
prect(198, -2, 205, 0, (20, 20, 20), outline=None)
d.text(Pp(209, 14), "keypad + lock\n(outside, secure side)", font=F(14), fill=INK)
cam = Pp(35, -2)
d.polygon([cam, Pp(150, -55), Pp(205, -30)], outline=(90, 110, 130))
d.text(Pp(60, -48), "camera field", font=F(14), fill=(90, 110, 130))
hdim(30, 206, 128, "4.42 m", sheetfn=Pp, above=True)
vdim(22, 0, 115, "2.90 m", sheetfn=Pp, left=True)
hdim(115, 194, -64, "opening 1.98 m", sheetfn=Pp, above=False)

# ---------------- legend ----------------
LEG = [
    (1, "Lock pilaster (0.30 m wide): carries the lock, keypad, stack light and their wiring"),
    (2, "Fail-secure bolt lock: spring-locked, power-to-unlock, bolt-bonded lamp (green = bonded / amber = not bonded), manual back-up key"),
    (3, "Bolt keeper on the leaf's leading edge: THE LATCH. Tears out of the leaf when WOLF forces the door"),
    (4, "OPTIONAL PIN keypad + card reader on a tamper-proof backplate, centre 1.20 m (1.5x real); no code entered. Alternative: blanking cover"),
    (5, "Stack light: green = sealed and locked, until the breach; red = breach (the only red the unit shows). Amber is not used"),
    (6, "Sliding armour leaf, top-hung, ballistic vision panel; parks over the fixed panel"),
    (7, "Top-hung box track with two trolleys and an end stop"),
    (8, "Fixed armour panel with ballistic vision panel (no glare streaks: nothing lights them); kick plate below"),
    (9, "Inflatable door seal on the frame (seen only when the leaf is open; torn at the lock edge after the breach)"),
    (10, "Caught-between stripes on the leaf's leading edge"),
    (11, "Interior: light-grey back wall (for the camera), steel floor plate; awake, a blue pool round WOLF's body lights only"),
    (12, "Umbilical reel in the ceiling; power/data umbilical plugged into WOLF's shoulders in standby"),
    (13, "Junction box: power/data feed for the umbilical, conduit up from a floor vault"),
    (14, "Rigid conduit from the lock down to a floor box (wiring only on the outside, secure side)"),
    (15, "Base channel, anchor flanges and anchor bolts into the slab; contact shadow"),
    (16, "Fixed camera on an arm, aimed along the front at the door"),
    (17, "Stencil 'CU-01' (8 px caps): PROPOSED, awaiting Nathanial (REAL-LOOK rule 7); else a blank plate. KEEP CLEAR dropped"),
    (18, "Threshold plate, flush with the floor"),
]
LX, LY = 40, 1300
d.text((LX, LY - 36), "PARTS (every part has a job; sizes and sources in DESIGN.md)", font=F(20, True), fill=INK)
colw = 1150
for i, (n, t) in enumerate(LEG):
    x = LX + (i // 9) * colw
    y = LY + (i % 9) * 30
    d.ellipse([x, y, x + 24, y + 24], outline=INK, width=2)
    f = F(15, True)
    tw = d.textlength(str(n), font=f)
    d.text((x + 12 - tw / 2, y + 3), str(n), font=f, fill=INK)
    d.text((x + 34, y + 2), t, font=F(17), fill=INK)
d.text((40, H - 40), "Option B, cage-design scratch, 2026-10-11. Not an approved design; the game keeps main's cage until Nathanial picks.",
       font=F(17), fill=(90, 90, 90))
sheet.save(OUT)
print("saved", OUT, sheet.size)
