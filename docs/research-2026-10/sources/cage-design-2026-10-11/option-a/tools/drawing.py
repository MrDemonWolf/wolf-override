"""Option A construction drawing: front elevation at game scale, section A-A, plan, lamp table.
Scratch design tool. Same geometry as the runtime layers (geom.py)."""
import math, sys
from PIL import Image, ImageDraw, ImageFont
import geom
from geom import Painter, C, PX_PER_M

OUT, FONT, ASSETS = sys.argv[1], sys.argv[2], sys.argv[3]
geom.FONT = FONT
PAPER = (238, 237, 231, 255)
INK = (24, 34, 42, 255)
DIM = (176, 58, 46, 255)
GHOST = (110, 120, 128, 255)
W, H = 2400, 1500
sheet = Image.new("RGBA", (W, H), PAPER)
d = ImageDraw.Draw(sheet)


def font(px, bold=False):
    f = ImageFont.truetype(FONT, px)
    try:
        f.set_variation_by_axes([700 if bold else 400, 100])
    except Exception:
        pass
    return f


def m(px):
    return px / PX_PER_M


# ---------------- front elevation ----------------
K = 4.6
EX0, EY0, EX1, EY1 = 0, 284, 300, 468
OX, OY = 190, 150
P = Painter(EX0, EY0, EX1, EY1, K, bg=(0, 0, 0, 0))
geom.paint_back(P, {"dock": "amber", "umb": "docked"})
elev_back = P.im
P2 = Painter(EX0, EY0, EX1, EY1, K)
geom.paint_frame(P2)
geom.paint_leaf(P2)
geom.paint_top(P2, {"lamp": "green"})


def W2D(x, y):
    return (OX + (x - EX0) * K, OY + (y - EY0) * K)


# today's footprint, dashed, for comparison
def dashed_rect(x0, y0, x1, y1, col, w=2, dash=10):
    pts = [W2D(x0, y0), W2D(x1, y0), W2D(x1, y1), W2D(x0, y1), W2D(x0, y0)]
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        L = math.hypot(bx - ax, by - ay)
        n = int(L // dash)
        for i in range(0, n, 2):
            t0, t1 = i / n, min(1, (i + 1) / n)
            d.line([(ax + (bx - ax) * t0, ay + (by - ay) * t0), (ax + (bx - ax) * t1, ay + (by - ay) * t1)], fill=col, width=w)


# floor slab band
d.rectangle([W2D(EX0, 440), W2D(EX1, 468)], fill=(214, 212, 205, 255))
d.line([W2D(EX0, 440), W2D(EX1, 440)], fill=INK, width=3)
sheet.alpha_composite(elev_back, (OX, OY))
# WOLF in standby (sprite, measured scale) between the lining and the bars
wolf = Image.open(ASSETS + "/wolf-side-right-provisional.png").convert("RGBA")
ws = 0.18325 * K
wolf = wolf.resize((int(wolf.width * ws), int(wolf.height * ws)), Image.LANCZOS)
px = wolf.load()
for yy in range(wolf.height):
    for xx in range(wolf.width):
        r, g, b, a = px[xx, yy]
        px[xx, yy] = (int(r * 0.35 + 20), int(g * 0.4 + 30), int(b * 0.45 + 40), a)
cx, cy = W2D(115, 408)
sheet.alpha_composite(wolf, (int(cx - wolf.width / 2), int(cy - wolf.height / 2)))
sheet.alpha_composite(P2.im, (OX, OY))
# Director (provisional sprite) for scale, at his beat 0-3 mark
director = Image.open(ASSETS + "/director-side-left-provisional.png").convert("RGBA")
dsc = 0.188 * K
director = director.resize((int(director.width * dsc), int(director.height * dsc)), Image.LANCZOS)
director.putalpha(director.getchannel("A").point(lambda a: a * 0.55))
dx, dy = W2D(255, 410)
sheet.alpha_composite(director, (int(dx - director.width / 2), int(dy - director.height / 2)))
# open position of the leaf (ghost) and today's frame (ghost)
dashed_rect(33, 357, 117, 435, (40, 110, 170, 255), 2, 12)
dashed_rect(27, 292, 203, 451, GHOST, 2, 8)
d.text(W2D(30, 298), "today's frame on main (x 27-203, y 292-451), for comparison", font=font(17), fill=GHOST, anchor="ls")
d.text(W2D(36, 434.5), "leaf parked open (dashed)", font=font(15), fill=(40, 110, 170, 255), anchor="ls")
# reference lines
d.line([W2D(214, 444.2), W2D(EX1, 444.2)], fill=DIM, width=1)
d.text(W2D(246.5, 465), "red line: dialogue box top, beats 2-6 (y 444)", font=font(15), fill=DIM, anchor="ls")
d.text(W2D(246.5, 460.5), "floor y 440 (collision top)", font=font(15), fill=INK, anchor="ls")
d.line([W2D(245.8, 372), W2D(245.8, 452)], fill=GHOST, width=1)
d.text(W2D(246.5, 456), "Director's coat x 245.8 (beats 0-3)", font=font(15), fill=GHOST, anchor="ls")


def dim_h(x0, x1, y, label, below=False):
    a, b = W2D(x0, y), W2D(x1, y)
    d.line([a, b], fill=DIM, width=2)
    for p in (a, b):
        d.line([(p[0], p[1] - 9), (p[0], p[1] + 9)], fill=DIM, width=2)
    d.text(((a[0] + b[0]) / 2, a[1] + (22 if below else -6)), label, font=font(21, True), fill=DIM, anchor="ms")


def dim_v(y0, y1, x, label, left=True):
    a, b = W2D(x, y0), W2D(x, y1)
    d.line([a, b], fill=DIM, width=2)
    for p in (a, b):
        d.line([(p[0] - 9, p[1]), (p[0] + 9, p[1])], fill=DIM, width=2)
    tx = a[0] - 10 if left else a[0] + 10
    d.text((tx, (a[1] + b[1]) / 2), label, font=font(21, True), fill=DIM, anchor="rm" if left else "lm")


dim_h(27, 203, 290, "4.42 m / 176 px (frame)")
dim_h(117, 197, 452, "clear opening 2.01 m / 80 px", below=True)
dim_h(33, 111, 452, "fixed bay 1.96 m / 78 px", below=True)
dim_h(115, 197, 462, "leaf travel 2.06 m / 82 px", below=True)
dim_v(337, 440, 21, "2.59 m / 103 px")
dim_v(356, 440, 8.5, "")
d.text(W2D(3, 400), "clear 2.11 m / 84", font=font(19, True), fill=DIM, anchor="mm")
dim_v(392, 440, 272, "keypad 1.20 m / 48", left=False)
dim_v(357, 440, 290, "", left=False)
d.text(W2D(268, 352), "lock lamp top 2.08 m / 83 px", font=font(19, True), fill=DIM, anchor="ls")
d.text(W2D(204, 300), "bars 50 mm on 125 mm centres:", font=font(16, True), fill=DIM, anchor="ls")
d.text(W2D(204, 304.5), "2 px on 5 px, 75 mm / 3 px gap", font=font(16, True), fill=DIM, anchor="ls")

# callouts
CALL = [
    (1, (60, 343), (60, 318)), (2, (150, 353), (150, 318)), (3, (160, 410), (168, 318)),
    (4, (70, 420), (70, 318)), (5, (114, 415), (100, 318)), (6, (114, 439), (128, 318)),
    (7, (85, 438), (85, 318)), (8, (95, 410), (95, 318)), (9, (56, 369), (40, 318)),
    (10, (130, 368), (138, 318)), (11, (132, 386), (180, 318)), (12, (197, 374), (220, 345)),
    (13, (210, 372), (226, 362)), (14, (208, 359), (219, 334)), (15, (208, 392), (222, 402)),
    (16, (208, 425), (222, 425)), (17, (209, 327), (226, 318)), (18, (193, 352), (196, 318)),
    (19, (176, 345), (120, 318)), (20, (211, 410), (230, 410)), (21, (80, 360), (80, 318)),
]
left = sorted([c for c in CALL if c[1][0] < 196], key=lambda c: c[1][0])
right = sorted([c for c in CALL if c[1][0] >= 196], key=lambda c: c[1][1])
placed = []
for i, (n, tip, _) in enumerate(left):
    placed.append((n, tip, (34 + i * (180 / max(1, len(left) - 1)), 314)))
for i, (n, tip, _) in enumerate(right):
    placed.append((n, tip, (226 + (i % 2) * 9, 322 + i * 18)))
for n, tip, lab in placed:
    a, b = W2D(*tip), W2D(*lab)
    d.line([a, b], fill=(24, 34, 42, 150), width=1)
    d.ellipse([a[0] - 3, a[1] - 3, a[0] + 3, a[1] + 3], fill=INK)
    d.ellipse([b[0] - 14, b[1] - 14, b[0] + 14, b[1] + 14], fill=PAPER, outline=INK, width=2)
    d.text(b, str(n), font=font(17, True), fill=INK, anchor="mm")
# remove callout label collisions with dims: labels at y 318 sit between the two dim rows; fine.

# title
d.text((60, 40), "OPTION A (revision 2)  ·  SECURE BARRED ENCLOSURE  ·  CONSTRUCTION DRAWING", font=font(38, True), fill=INK)
d.text((60, 88), "Design drawing, not final art. Front elevation at game scale (1 world px = 4.6 drawing px; 1 m = 39.8 world px), "
                 "registered to main's opening: floor y 440, unit origin (115, 365). Standby state; WOLF sprite at his real start.",
       font=font(21), fill=INK)

# ---------------- legend ----------------
LX, LY = 1690, 200
LEG = [
    ("1", "Header beam + 6 mm roof plate", "0.30 m / 12 px", "closes the top; carries the track"),
    ("2", "Enclosed box track, rubber end stops", "0.15 m / 6 px, full front", "hangs the leaf; stops it at both ends"),
    ("3", "Slide leaf, 2 trolleys, guide fin", "2.11 x 1.96 m / 84 x 78 px", "the gate; travel 2.06 m / 82 px left"),
    ("4", "Fixed bar panel", "1.96 m bay, framed", "front of the left bay; leaf parks over it"),
    ("5", "Posts, 150 SHS steel", "0.15 m / 6 px, x3", "carry header, panel and lock"),
    ("6", "Base plates, 4 anchor bolts each", "0.30 m / 12 px", "fix the unit to the slab"),
    ("7", "Sill / floor guide channel", "0.10 m / 4 px", "guides the leaf; yellow = caught-between"),
    ("8", "6 mm steel back lining (and ends, roof)", "4.12 x 2.04 m seen", "solid cell; lit by fitting 21 so dark WOLF reads"),
    ("9", "Cooling vent, honeycomb", "0.80 x 0.25 m", "air for a charging robot"),
    ("10", "Standby dock unit + dock lamp", "0.50 x 0.38 m, at 1.8 m", "power + data; lamp: amber standby / blue awake"),
    ("11", "Umbilical, breakaway coupler", "75 mm / 3 px, light grey", "keeps WOLF in standby; drops on wake"),
    ("12", "Keeper, welded to leaf stile", "0.15 x 0.33 m / 6 x 13 px", "the hook bolt holds it: the weak point"),
    ("13", "Fail-secure hook-bolt lock box", "0.25 x 0.43 m, at 1.65 m", "spring-locked, power to unlock; key override"),
    ("14", "Guarded lock-status lamp", "0.15 m / 6 px, top 2.08 m", "green locked / amber flashing forced"),
    ("15", "OPTIONAL reader + PIN keypad on backplate", "0.15 x 0.23 m (1.8x real)", "1.2 m; no code entered; else blanking cover"),
    ("16", "Rigid conduit to floor box", "50 mm, strapped", "lock wiring stays on the keeper side"),
    ("17", "Fixed camera on wall arm", "0.35 x 0.13 m, at 2.8 m", "watches the cell"),
    ("18", "Gate position switch", "0.13 m", "reports leaf closed"),
    ("19", "Header marks (PROPOSED text)", "8.1 px caps (0.20 m)", "or blank plates without his exception"),
    ("20", "Lock mounting plate, welded to post", "0.25 m / 10 px, anchored", "carries 13-16: nothing hangs on conduit"),
    ("21", "Caged bulkhead fitting under the roof", "1.0 m, 2 stems", "its light on the lining is painted, no glow"),
]
d.text((LX, LY - 44), "PARTS (size real / world px; job)", font=font(24, True), fill=INK)
for i, (n, name, size, job) in enumerate(LEG):
    y = LY + i * 42
    d.ellipse([LX, y, LX + 26, y + 26], outline=INK, width=2)
    d.text((LX + 13, y + 13), n, font=font(15, True), fill=INK, anchor="mm")
    d.text((LX + 36, y - 2), name, font=font(19, True), fill=INK)
    d.text((LX + 36, y + 19), size + "  ·  " + job, font=font(15), fill=(60, 70, 78, 255))

# ---------------- section A-A (cut through the gate bay, looking left) ----------------
SK = 3.2
SX0, SY0 = 130, 1100
# z axis: 0 = front face of frame (posts), positive = into the cell; leaf at -0.15 m


def S2D(z_px, y):
    return (SX0 + z_px * SK, SY0 + (y - 336) * SK)


d.text((SX0 - 100, SY0 - 90), "SECTION A-A  (through the gate bay, looking left; 1 world px = 3.2 drawing px)", font=font(22, True), fill=INK)
DEP = 100  # 2.5 m clear depth
d.rectangle([S2D(-30, 440), S2D(DEP + 30, 452)], fill=(205, 203, 196, 255))
d.line([S2D(-30, 440), S2D(DEP + 30, 440)], fill=INK, width=2)
d.rectangle([S2D(0, 337), S2D(DEP + 0.6, 338.6)], fill=geom.hexc(C["header"]))
d.rectangle([S2D(0, 338), S2D(6, 350)], fill=geom.hexc(C["header"]))
d.rectangle([S2D(DEP, 337), S2D(DEP + 0.6, 440)], fill=geom.hexc(C["back"]))
d.rectangle([S2D(0, 350), S2D(6, 440)], fill=geom.hexc(C["post"]))
d.rectangle([S2D(-6, 350), S2D(-0.3, 356)], fill=geom.hexc(C["track"]))
d.rectangle([S2D(-4.5, 357), S2D(-2.5, 435)], fill=geom.hexc(C["rail"]))
d.rectangle([S2D(-8, 436), S2D(0, 440)], fill=geom.hexc(C["yellow"]))
d.rectangle([S2D(DEP - 6, 361), S2D(DEP - 0.6, 376)], fill=geom.hexc(C["dock"]))
d.line([S2D(DEP - 6, 374), S2D(DEP * 0.62, 386), S2D(DEP * 0.5, 393)], fill=geom.hexc(C["cable"]), width=5)
# WOLF envelope seen head-on: 0.6 m wide, 1.55 m to ear tips
d.rectangle([S2D(DEP * 0.5 - 12, 376.6), S2D(DEP * 0.5 + 12, 440)], outline=(40, 110, 170, 255), width=2)
d.text(S2D(DEP * 0.5, 372), "WOLF 0.6 x 1.55 m", font=font(17), fill=(40, 110, 170, 255), anchor="ms")
d.line([S2D(0, 446), S2D(DEP, 446)], fill=DIM, width=2)
d.text(S2D(DEP / 2, 451), "clear depth 2.50 m / 100 px", font=font(18, True), fill=DIM, anchor="ms")
d.text(S2D(-8, 331), "leaf + track outside the posts", font=font(16), fill=INK, anchor="ls")
d.text(S2D(DEP - 2, 333), "6 mm lining, roof + back", font=font(16), fill=INK, anchor="rs")

# ---------------- plan ----------------
PK = 2.6
PX0, PY0 = 640, 1390


def P2D(x, z):
    return (PX0 + (x - 20) * PK, PY0 + z * PK)


d.text((PX0, PY0 - 300), "PLAN  (1 world px = 2.6 drawing px; front at the bottom)", font=font(22, True), fill=INK)
DEPZ = 100
# walls: ends and back
d.rectangle([P2D(27, -DEPZ - 2), P2D(203, -DEPZ)], fill=geom.hexc(C["back"]))
for x0 in (27, 201):
    d.rectangle([P2D(x0, -DEPZ - 2), P2D(x0 + 2, 0)], fill=geom.hexc(C["back"]))
for x0, x1 in geom.POSTS:
    d.rectangle([P2D(x0, -6), P2D(x1, 0)], fill=geom.hexc(C["post"]))
d.rectangle([P2D(33, -2), P2D(111, 0)], fill=geom.hexc(C["fbar"]))
d.rectangle([P2D(115, 2), P2D(199, 4)], fill=geom.hexc(C["rail"]))
dashed = (40, 110, 170, 255)
for x in range(33, 117, 6):
    d.line([P2D(x, 5.5), P2D(min(x + 3, 117), 5.5)], fill=dashed, width=3)
d.text(P2D(75, 13), "leaf open", font=font(16), fill=dashed, anchor="ms")
d.text(P2D(157, 13), "leaf closed", font=font(16), fill=INK, anchor="ms")
d.rectangle([P2D(203, -8), P2D(213, 1)], fill=geom.hexc(C["box"]))
d.text(P2D(216, -3), "lock box + keypad (outside)", font=font(16), fill=INK, anchor="lm")
# WOLF footprint and turn circle
d.rectangle([P2D(58, -62), P2D(150, -38)], outline=(40, 110, 170, 255), width=2)
cxp, czp = P2D(114, -50)
r = 46 * PK
d.ellipse([cxp - r, czp - r, cxp + r, czp + r], outline=(40, 110, 170, 255), width=1)
d.text(P2D(114, -50), "WOLF 2.3 x 0.6 m; turns in 2.3 m", font=font(16), fill=(40, 110, 170, 255), anchor="mm")
d.text(P2D(114, -8), "4.12 x 2.50 m clear cell", font=font(18, True), fill=DIM, anchor="ms")

# ---------------- lamp language ----------------
TX, TY = 1690, 1110
d.text((TX, TY), "LAMP LANGUAGE (proposal)", font=font(24, True), fill=INK)
rows = [
    (C["lamp_green"], "Lock lamp green, steady", "locked, bolt thrown and monitored (beats 0-2)"),
    (C["lamp_amber"], "Lock lamp amber, flashing", "forced: bolt thrown but keeper gone (beat 3 on)"),
    (C["lamp_green"], "Lock lamp green, flashing", "released by a valid code (PIN gameplay, later)"),
    (C["dock_amber"], "Dock lamp amber", "standby: docked, charging, motors locked out (beats 0-1)"),
    (C["dock_blue"], "Dock lamp blue", "WOLF's computers on: he woke himself (beat 2 on)"),
]
for i, (col, a, b) in enumerate(rows):
    y = TY + 48 + i * 50
    d.rectangle([TX, y, TX + 30, y + 30], fill=geom.hexc(col), outline=INK, width=1)
    d.text((TX + 44, y - 2), a, font=font(19, True), fill=INK)
    d.text((TX + 44, y + 20), b, font=font(15), fill=(60, 70, 78, 255))
d.text((TX, TY + 320), "Proposed marks (8 px caps), awaiting Nathanial: CU-01, KEEP CLEAR 2 M. Else blank plates.", font=font(17, True), fill=DIM)
d.text((TX, TY + 344), "They conflict with REAL-LOOK rule 7 unless he allows them.\nRed is not used on the unit (danger only).", font=font(16), fill=DIM)

sheet.convert("RGB").save(OUT)
print("drawing", OUT)
