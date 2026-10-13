"""Option C sheets (scratch): the construction drawing, the three labelled beat renders and strip.png.
Usage: python -I sheets.py <option-c dir> <game dir> <font>
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
OUT = Path(sys.argv[1])
GAME = Path(sys.argv[2])
FONT_PATH = sys.argv[3]
sys.argv = [sys.argv[0], str(OUT / "render" / "layers"), FONT_PATH]
import design_art as da  # noqa: E402

INK = (29, 39, 51, 255)
INK_SOFT = (90, 100, 112, 255)
RED = (179, 38, 30, 255)
BLUE = (30, 96, 170, 255)
PAPER = (235, 232, 225, 255)


def font(px: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, px)


def bold(px: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(FONT_PATH, px)
    try:
        f.set_variation_by_axes([700, 100])
    except Exception:
        pass
    return f


ORIGIN = (115.0, 365.0)


def paste_layer(canvas: Image.Image, im: Image.Image, bbox, wx0: float, wy0: float, p: float, ox: int, oy: int) -> None:
    """Paste a layer whose local bbox is given, onto a canvas showing world from (wx0, wy0) at p px/world px."""
    x = ox + (ORIGIN[0] + bbox[0] - wx0) * p
    y = oy + (ORIGIN[1] + bbox[1] - wy0) * p
    canvas.alpha_composite(im, (int(round(x)), int(round(y))))


def sprite(path: Path, scale: float, p: float, tint=None, flip=False) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    if flip:
        im = ImageOps.mirror(im)
    w = max(1, int(round(im.width * scale * p)))
    h = max(1, int(round(im.height * scale * p)))
    im = im.resize((w, h), Image.LANCZOS)
    if tint is not None:
        r, g, b, a = im.split()
        rgb = Image.merge("RGB", (r, g, b))
        tr = Image.new("RGB", im.size, tint[:3])
        rgb = Image.composite(Image.blend(rgb, tr, 0.0), rgb, Image.new("L", im.size, 255))
        # modulate (multiply) as Godot does
        from PIL import ImageChops
        rgb = ImageChops.multiply(rgb, tr)
        im = Image.merge("RGBA", (*rgb.split(), a))
    return im


def elevation(p: float, wx0: float, wy0: float, wx1: float, wy1: float, state: str, frame_key: str = "frame") -> Image.Image:
    """Front elevation at p px/world px over a plain floor/wall tone, world window (wx0..wx1, wy0..wy1)."""
    W = int((wx1 - wx0) * p)
    H = int((wy1 - wy0) * p)
    cv = Image.new("RGBA", (W, H), (58, 66, 76, 255))
    d = ImageDraw.Draw(cv)
    fy = (440 - wy0) * p
    d.rectangle([0, fy, W, H], fill=(40, 46, 54, 255))
    L = da.layers(p, 2)
    paste_layer(cv, L["back"], da.BACK_BBOX, wx0, wy0, p, 0, 0)
    g = da.Painter((wx0 - ORIGIN[0], wy0 - ORIGIN[1], wx1 - ORIGIN[0], wy1 - ORIGIN[1]), p, 2)
    # Live back parts: umbilical, connector, dock lamp.
    released = state != "standby"
    da.draw_umbilical(g, released, None if released else da.hexc("#ffae2a"))
    cv.alpha_composite(g.result())
    # WOLF (standby tint) or empty.
    if state == "standby":
        wolf = sprite(GAME / "assets" / "wolf-side-right-provisional.png", 0.18325, p, tint=(0x36, 0x52, 0x63))
        cv.alpha_composite(wolf, (int(round((115 - 761 * 0.18325 / 2 - wx0) * p)), int(round((408 - 406 * 0.18325 / 2 - wy0) * p))))
    # Leaves.
    for k in range(4):
        lx = -82 + 40 * k if state == "standby" else -82
        im = L["leaf_lead"] if k == 3 else L["leaf"]
        paste_layer(cv, im, (lx, -21, lx + 44, 69), wx0, wy0, p, 0, 0)
    g = da.Painter((wx0 - ORIGIN[0], wy0 - ORIGIN[1], wx1 - ORIGIN[0], wy1 - ORIGIN[1]), p, 2)
    if state != "standby":
        da.draw_hook_bolt(g, -82 + 44, True)
    cv.alpha_composite(g.result())
    paste_layer(cv, L[frame_key], da.FRAME_BBOX, wx0, wy0, p, 0, 0)
    g = da.Painter((wx0 - ORIGIN[0], wy0 - ORIGIN[1], wx1 - ORIGIN[0], wy1 - ORIGIN[1]), p, 2)
    lx_, ly_ = da.LAMP_AT
    if state == "standby":
        paste_layer(cv, L["lock"], (da.LOCK_AT[0], da.LOCK_AT[1], da.LOCK_AT[0] + 8, da.LOCK_AT[1] + 14), wx0, wy0, p, 0, 0)
        g.circle(lx_, ly_, 4.0, (79, 210, 127, 90))
        g.rect(lx_ - 1.3, ly_ - 1.3, 2.6, 2.6, da.hexc("#4fd27f"))
        cv.alpha_composite(g.result())
    else:
        g.rect(85.5, 27.6, 2.2, 1.4, da.hexc("#a7b0ba"))
        g.rect(85.5, 39.0, 2.2, 1.4, da.hexc("#a7b0ba"))
        g.rect(87, 41, 1, 9, (14, 18, 21, 255))
        g.circle(lx_, ly_, 5.0, (255, 59, 47, 110))
        g.rect(lx_ - 1.3, ly_ - 1.3, 2.6, 2.6, da.hexc("#ff3b2f"))
        cv.alpha_composite(g.result())
        lock = L["lock"].rotate(-32, expand=True, resample=Image.BICUBIC)
        cx = (ORIGIN[0] + 84 - wx0) * p
        cy = (ORIGIN[1] + 43 - wy0) * p
        cv.alpha_composite(lock, (int(cx - lock.width / 2), int(cy - lock.height / 2)))
    # The Director at his spot, for scale.
    if wx1 > 250:
        dr = sprite(GAME / "assets" / "director-side-left-provisional.png", 0.188, p)
        src = Image.open(GAME / "assets" / "director-side-left-provisional.png")
        cv.alpha_composite(dr, (int(round((255 - src.width * 0.188 / 2 - wx0) * p)), int(round((410 - src.height * 0.188 / 2 - wy0) * p))))
    return cv


def arrow_dim(d: ImageDraw.ImageDraw, a, b, text: str, f, color=INK, horizontal=True, off=0) -> None:
    d.line([a, b], fill=color, width=2)
    for pt, sgn in ((a, 1), (b, -1)):
        if horizontal:
            d.polygon([pt, (pt[0] + 10 * sgn, pt[1] - 5), (pt[0] + 10 * sgn, pt[1] + 5)], fill=color)
            d.line([(pt[0], pt[1] - 12), (pt[0], pt[1] + 12)], fill=color, width=1)
        else:
            d.polygon([pt, (pt[0] - 5, pt[1] + 10 * sgn), (pt[0] + 5, pt[1] + 10 * sgn)], fill=color)
            d.line([(pt[0] - 12, pt[1]), (pt[0] + 12, pt[1])], fill=color, width=1)
    if horizontal:
        d.text(((a[0] + b[0]) / 2, a[1] - 8 + off), text, fill=color, font=f, anchor="md")
    else:
        d.text((a[0] + 10, (a[1] + b[1]) / 2), text, fill=color, font=f, anchor="lm")


def construction() -> Image.Image:
    P = 7.0
    WX0, WY0, WX1, WY1 = 14.0, 318.0, 272.0, 452.0
    W, H = 2700, 2720
    sheet = Image.new("RGBA", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((60, 50), "WOLF CONTAINMENT, OPTION C: STANDBY DOCK IN A GUARDED BAY (revision 2)", fill=INK, font=bold(44))
    d.text((60, 108), "Construction drawing. DESIGN DRAWING ONLY: flat-shaded, not final art, not in the game. Scratch, 2026-10-11. "
           "Scale 1 m = 40 world px; world px shown in brackets.", fill=INK_SOFT, font=font(26))
    d.text((60, 146), "Sign text (8 px caps) and the keypad are PROPOSED, awaiting Nathanial. Without his exception: blank plates and a blank backplate (F).", fill=RED, font=font(26))

    ex, ey = 60, 230
    elev = elevation(P, WX0, WY0, WX1, WY1, "standby")
    sheet.alpha_composite(elev, (ex, ey))
    d.rectangle([ex - 1, ey - 1, ex + elev.width, ey + elev.height], outline=INK, width=2)
    d.text((ex, ey - 44), "A. FRONT ELEVATION, closed, WOLF in standby (as on screen at beats 0-1)", fill=INK, font=bold(30))

    def X(wx: float) -> float:
        return ex + (wx - WX0) * P

    def Y(wy: float) -> float:
        return ey + (wy - WY0) * P

    f20 = font(22)
    # Floor line.
    d.line([(X(WX0), Y(440)), (X(WX1), Y(440))], fill=(230, 200, 60, 255), width=2)
    d.text((X(222), Y(440) + 6), "floor y 440", fill=(230, 200, 60, 255), font=f20)
    # Dimensions below the elevation.
    by = ey + elev.height + 40
    arrow_dim(d, (X(27), by), (X(203), by), "frame 4.40 m [176]", f20)
    arrow_dim(d, (X(33), by + 62), (X(197), by + 62), "clear between posts 4.10 m [164]", f20)
    arrow_dim(d, (X(77), by + 124), (X(197), by + 124), "clear opening when open 3.00 m [120]", f20)
    arrow_dim(d, (X(33), by + 186), (X(77), by + 186), "stacked leaves 1.10 m [44]", f20)
    arrow_dim(d, (X(201), by + 186), (X(213), by + 186), "", f20)
    d.text((X(213) + 10, by + 186), "lock pilaster 0.30 m [12]; outer edge x 213", fill=INK, font=f20, anchor="lm")
    # Heights on the left.
    hx = ex - 0
    WHITE = (235, 235, 235, 255)
    arrow_dim(d, (X(19), Y(328)), (X(19), Y(440)), "", f20, color=WHITE, horizontal=False)
    d.text((X(19) + 14, Y(300 + 86)), "2.80 m", fill=WHITE, font=f20, anchor="la")
    d.text((X(19) + 14, Y(300 + 86)), "\n[112]", fill=WHITE, font=f20, anchor="la")
    # WOLF fit box.
    LB = (130, 190, 255, 255)
    d.rectangle([X(58.8), Y(376.6), X(174.1), Y(438.2)], outline=LB, width=2)
    d.text((X(60), Y(376.6) - 6), "WOLF 2.90 x 1.55 m [115 x 62]", fill=LB, font=f20, anchor="ld")

    # Callouts: (number, anchor world point, label position).
    callouts = [
        (1, (60, 340), (40, 322)),
        (2, (30, 380), (18, 360)),
        (3, (60, 437), (52, 447)),
        (4, (115, 439), (102, 449)),
        (5, (95, 360), (88, 325)),
        (6, (195, 360), (186, 325)),
        (7, (199, 399), (232, 424)),
        (8, (207, 392), (232, 396)),
        (9, (207, 383), (232, 380)),
        (10, (205, 323), (232, 322)),
        (11, (211, 360), (232, 348)),
        (12, (70, 372), (75, 330)),
        (13, (46, 405), (40, 425)),
        (14, (126, 409), (140, 448)),
        (15, (132, 350), (150, 325)),
        (16, (132, 389), (160, 362)),
        (17, (196.5, 425), (180, 445)),
        (18, (150, 442), (165, 450)),
        (19, (207, 430), (232, 440)),
        (20, (105, 351), (118, 325)),
        (21, (207, 432), (226, 452)),
    ]
    fnum = bold(22)
    for n, (ax, ay), (lx, ly) in callouts:
        a = (X(ax), Y(ay))
        l = (X(lx), Y(ly))
        col = RED if n == 7 else (255, 255, 255, 255)
        d.line([a, l], fill=col, width=2)
        d.ellipse([a[0] - 4, a[1] - 4, a[0] + 4, a[1] + 4], fill=col)
        d.ellipse([l[0] - 17, l[1] - 17, l[0] + 17, l[1] + 17], fill=RED if n == 7 else INK, outline=(255, 255, 255, 255), width=2)
        d.text(l, str(n), fill=(255, 255, 255, 255), font=fnum, anchor="mm")

    # Legend (right column).
    lx0 = ex + elev.width + 50
    d.text((lx0, ey - 44), "PARTS (real size, [world px], job)", fill=INK, font=bold(28))
    legend = [
        ("1", "Head beam 0.35 m [14], holds the 4 top tracks and leaf trolleys; cap plate over it with equal overhang. Proposed stencils CU-01 and KEEP CLEAR at 8 px caps, or blank plates (F)."),
        ("2", "Posts, 150 mm steel box section [6], on base plates."),
        ("3", "Sill and bottom guide 0.15 m [6]: the leaves run in it; steel threshold."),
        ("4", "Anchor plates 0.35 m [14], 2 anchor bolts each into the slab."),
        ("5", "4 leaves 1.10 x 2.25 m [44 x 90]: welded mesh in a steel frame, 0.15 m kick plate [6] so his legs and feet read. Telescoping on 4 parallel tracks; the left leaf is fixed."),
        ("6", "Leading stile: crush point, yellow/black stripes (the one yellow element); handle module that throws the HOOK BOLT (E)."),
        ("7", "GUARD LOCK, the part that fails: fail-secure (spring-locked, power-to-unlock), hook bolt monitored, 0.20 x 0.35 m [8 x 14], 0.85-1.20 m up, on the latch post and pilaster. Out of WOLF's reach. His outward drive loads the hook in prying; the mounting bolts shear and it hangs by its cable."),
        ("8", "OPTIONAL: card slot + 12-key PIN pad on the backplate at 1.20 m [y 392], drawn 1.5x real so it reads. No code is entered in the opening. Until the PIN design is picked: a blank backplate with a blanking cover (F)."),
        ("9", "Status lamp on the backplate: steady GREEN = locked, bolt monitored; RED 2 Hz = door forced (the only red in view)."),
        ("10", "Fixed camera with sun hood on an arm on top of the pilaster, aimed down-left at the door, 2.9 m up. Static art, no glow."),
        ("11", "One surface conduit down the pilaster face: camera, backplate, into the floor box; strapped."),
        ("12", "Back plate 6 mm, 3 bolted panels; plate ends and roof. Only the front is mesh."),
        ("13", "Charger / cell-controller cabinet 0.5 x 1.3 m [20 x 52], fed from the floor."),
        ("14", "ROBOT STAND: 0.70 x 0.35 m plinth with base flange and 2 anchor bolts, gussets, column, U saddle with side lips, rubber contact pad with 2 charging contacts. Carries his weight while the motors are locked out. Floor conduit to the cabinet."),
        ("15", "Spring cable reel under the roof [16 x 8], conduit along the roof to the cabinet."),
        ("16", "Umbilical 75 mm [3], lighter than the plate, into the breakaway connector on his back [7 x 12]. DOCK LAMP: amber = standby; blue = his computers on, motors still locked out; off = released, reel wound up."),
        ("17", "Rubber closing-edge buffer on the latch post, where the leading stile lands."),
        ("18", "Contact shadow, darkest at the contact line."),
        ("19", "LOCK PILASTER 0.30 m [12]: steel column through-bolted to the latch post, anchored base plate. Carries 7, 8, 9, 10 and 11."),
        ("20", "ROOF FITTING: vapour-tight LED fitting on two stems. The light on the back plate, cabinet lid, stand and saddle is painted from it (no runtime glow); it keeps dark WOLF readable in standby."),
        ("21", "Floor box at the pilaster foot, lockable cover; all wiring enters the slab here."),
    ]
    yy = ey
    fL = font(21)
    for n, txt in legend:
        col = RED if n == "7" else INK
        d.ellipse([lx0, yy, lx0 + 30, yy + 30], fill=col)
        d.text((lx0 + 15, yy + 15), n, fill=(255, 255, 255, 255), font=bold(18), anchor="mm")
        # wrap
        words = txt.split()
        line = ""
        lines = []
        for w in words:
            t = (line + " " + w).strip()
            if d.textlength(t, font=fL) > W - lx0 - 100:
                lines.append(line)
                line = w
            else:
                line = t
        lines.append(line)
        for i, ln in enumerate(lines):
            d.text((lx0 + 44, yy + 3 + i * 27), ln, fill=col, font=fL)
        yy += 27 * len(lines) + 12

    # B. Plan view.
    PP = 6.0
    px0, py0 = 60, by + 340
    d.text((px0, py0 - 82), "B. PLAN (top view), closed; outlined boxes = leaves when open. Depth 1.60 m [64]; front faces the camera.", fill=INK, font=bold(28))
    # plan coordinates: world x, depth z (0 = back outer face, 64 = front outer face).

    def PX(wx: float) -> float:
        return px0 + (wx - WX0) * PP

    def PZ(z: float) -> float:
        return py0 + z * PP

    d.rectangle([PX(WX0), PZ(-8), PX(WX1), PZ(100)], fill=(214, 210, 202, 255))
    d.rectangle([PX(27), PZ(0), PX(203), PZ(3)], fill=(60, 68, 78, 255))
    d.rectangle([PX(27), PZ(0), PX(33), PZ(64)], fill=(60, 68, 78, 255))
    d.rectangle([PX(197), PZ(0), PX(203), PZ(64)], fill=(60, 68, 78, 255))
    for cx in (27, 197):
        for cz in (0, 58):
            d.rectangle([PX(cx), PZ(cz), PX(cx + 6), PZ(cz + 6)], fill=(30, 36, 44, 255))
    d.rectangle([PX(27), PZ(52), PX(203), PZ(64)], outline=INK_SOFT, width=1)
    d.text((PX(36), PZ(52) - 4), "head beam over 4 tracks, 0.30 m; fixed leaf on the back track", fill=INK_SOFT, font=font(18), anchor="ld")
    for k in range(4):
        tz = 54 + k * 2.6
        x0 = 33 + 40 * k
        d.rectangle([PX(x0), PZ(tz), PX(x0 + 44), PZ(tz + 1.6)], fill=(70, 80, 92, 255))
        d.rectangle([PX(33), PZ(tz), PX(77), PZ(tz + 1.6)], outline=INK, width=1)
    for xx in range(int(PX(33)), int(PX(77)), 14):
        pass
    # cabinet, cradle, reel
    d.rectangle([PX(36), PZ(3), PX(56), PZ(23)], fill=(90, 98, 108, 255))
    d.text((PX(46), PZ(13)), "13", fill=(255, 255, 255, 255), font=bold(18), anchor="mm")
    # WOLF top outline
    d.ellipse([PX(84), PZ(14), PX(160), PZ(40)], outline=BLUE, width=3)
    d.ellipse([PX(150), PZ(20), PX(176), PZ(34)], outline=BLUE, width=3)
    d.polygon([(PX(84), PZ(25)), (PX(58), PZ(27)), (PX(84), PZ(29))], outline=BLUE)
    d.rectangle([PX(121), PZ(19), PX(131), PZ(35)], fill=(110, 118, 128, 255))
    d.text((PX(126), PZ(27)), "14", fill=(255, 255, 255, 255), font=bold(16), anchor="mm")
    d.rectangle([PX(124), PZ(22), PX(140), PZ(32)], outline=INK, width=1)
    d.text((PX(124), PZ(21)), "15 reel (overhead)", fill=INK, font=font(16), anchor="ld")
    # keypad station, camera, conduit
    d.rectangle([PX(201), PZ(52), PX(213), PZ(64)], fill=(46, 53, 61, 255))
    d.text((PX(214), PZ(56)), "19 lock pilaster (7-11 on its face)", fill=INK, font=font(18), anchor="lm")
    d.rectangle([PX(203), PZ(64), PX(211), PZ(66)], fill=(30, 36, 44, 255))
    d.text((PX(214), PZ(66)), "8/9 backplate, 10 camera above", fill=INK, font=font(18), anchor="la")
    # Director
    d.ellipse([PX(247), PZ(68), PX(263), PZ(80)], outline=INK, width=3)
    d.text((PX(255), PZ(82)), "Director x 255", fill=INK, font=font(18), anchor="ma")
    # Exit path
    d.line([(PX(120), PZ(27)), (PX(122), PZ(80)), (PX(185), PZ(82))], fill=RED, width=4)
    d.polygon([(PX(185), PZ(82)), (PX(178), PZ(78)), (PX(178), PZ(86))], fill=RED)
    d.text((PX(40), PZ(90)), "Exit: a 0.8 m sidestep forward out of the 1.22 m deep bay (a quadruped robot can strafe), then the walk right to x 185. "
           "The side view cannot show the sidestep;", fill=RED, font=font(20))
    d.text((PX(40), PZ(95)), "on screen it is only main's 8 px step-down. Nothing on screen moves the leaves once the lock has failed (see DESIGN.md 4).", fill=RED, font=font(20))
    arrow_dim(d, (PX(232), PZ(0)), (PX(232), PZ(64)), "", f20, horizontal=False)
    d.text((PX(232) + 14, PZ(32)), "depth 1.60 m [64]", fill=INK, font=f20, anchor="lm")
    d.text((PX(84), PZ(42)), "WOLF ~0.8 m wide (est); 0.2 m clear each side", fill=BLUE, font=font(18), anchor="la")

    # C. Lamp language and beats (right column under legend).
    cy0 = max(yy + 30, py0 - 44)
    d.text((lx0, cy0), "LAMP STATES (2 persistent glows; budget is 4)", fill=INK, font=bold(26))
    rows = [
        ("Status lamp (9)", [((79, 210, 127), "green: locked"), ((255, 59, 47), "red 2 Hz: door forced")]),
        ("Dock lamp (16)", [((255, 174, 42), "amber: standby"), ((79, 176, 255), "blue: awake, locked out"), ((20, 26, 31), "off: released")]),
    ]
    ry = cy0 + 46
    for name, sw in rows:
        d.text((lx0, ry + 4), name, fill=INK, font=font(21))
        sx = lx0 + 190
        for col, lab in sw:
            d.ellipse([sx, ry, sx + 26, ry + 26], fill=col + (255,), outline=INK, width=1)
            d.text((sx + 34, ry + 3), lab, fill=INK, font=font(19))
            sx += 34 + d.textlength(lab, font=font(19)) + 22
        ry += 44

    # D. Actual-size inset.
    shot = Image.open(OUT / "shots" / "design-r2" / "02-beat1-standby-noui.png").convert("RGBA")
    crop = shot.crop((50, 270, 690, 600))
    ix, iy = lx0, ry + 70
    d.text((ix, iy - 40), "D. ACTUAL SIZE at 1280x720, beat 1 (1 world px = 2.6 screen px)", fill=INK, font=bold(24))
    sheet.alpha_composite(crop, (ix, iy))
    d.rectangle([ix - 1, iy - 1, ix + crop.width, iy + crop.height], outline=INK, width=2)

    # E. Hook-bolt detail (plan section through the guard lock at bolt height).
    E0x, E0y = 60, 2230
    d.text((E0x, E0y), "E. HOOK BOLT IN THE GUARD LOCK (detail: plan section at 1.0 m, 24 px = 1 world px)", fill=INK, font=bold(26))
    q = 24.0
    def ex_(x): return E0x + 300 + (x - 74) * q
    def ez_(z): return E0y + 130 + z * q
    d.rectangle([ex_(74), ez_(0), ex_(82), ez_(1.2)], fill=(70, 80, 92, 255))           # leaf stile
    d.text((ex_(74) - 8, ez_(0.6)), "leading stile (leaf)", fill=INK, font=font(18), anchor="rm")
    d.rectangle([ex_(82), ez_(-3), ex_(88), ez_(1.2)], fill=(60, 68, 78, 255))          # latch post
    d.text((ex_(88) + 10, ez_(-2.0)), "latch post (2) with the pilaster (19) on its face", fill=INK, font=font(18), anchor="lm")
    d.rectangle([ex_(80), ez_(1.2), ex_(88), ez_(5.6)], fill=(47, 54, 62, 255))         # guard lock body
    d.rectangle([ex_(80.8), ez_(2.0), ex_(83.3), ez_(4.6)], fill=(12, 15, 18, 255))      # keeper slot
    d.polygon([(ex_(76), ez_(0.5)), (ex_(82.6), ez_(0.5)), (ex_(82.6), ez_(4.0)), (ex_(81.6), ez_(4.0)),
               (ex_(81.6), ez_(1.3)), (ex_(76), ez_(1.3))], fill=(154, 163, 173, 255))     # hook bolt
    d.text((ex_(76) - 8, ez_(2.2)), "hook bolt (thrown) from the handle module (6)", fill=INK, font=font(18), anchor="rm")
    d.text((ex_(88) + 10, ez_(3.4)), "guard lock (7): keeper slot; mounting bolts into post and pilaster", fill=INK, font=font(18), anchor="lm")
    d.line([(ex_(78.5), ez_(-2.6)), (ex_(78.5), ez_(6.2))], fill=RED, width=3)
    d.polygon([(ex_(78.5), ez_(6.9)), (ex_(78.1), ez_(6.0)), (ex_(78.9), ez_(6.0))], fill=RED)
    d.text((ex_(78.5) + 10, ez_(6.6)), "WOLF's drive out of the bay (toward the camera) loads the hook in prying", fill=RED, font=font(18), anchor="lm")
    d.text((E0x, ez_(8.2)), "The hook catches behind the keeper, so the leaf can be neither slid open nor pried outward while the lock holds. Pushed outward,", fill=INK, font=font(19))
    d.text((E0x, ez_(8.2) + 26), "the hook loads the keeper in prying; the mounting bolts shear and the module tears off, twists free of the hook and hangs by its cable.", fill=INK, font=font(19))

    # F. The alternative that needs no exception: blank plates, blank 1.2 m backplate.
    alt = Image.open(OUT / "shots" / "design-r2-plain" / "02-beat1-standby-noui.png").convert("RGBA").crop((50, 270, 690, 600))
    alt = alt.resize((int(alt.width * 0.9), int(alt.height * 0.9)), Image.LANCZOS)
    fx_, fy_ = lx0, iy + crop.height + 80
    d.text((fx_, fy_ - 40), "F. NO TEXT, NO KEYPAD (needs no exception), beat 1", fill=INK, font=bold(24))
    sheet.alpha_composite(alt, (fx_, fy_))
    d.rectangle([fx_ - 1, fy_ - 1, fx_ + alt.width, fy_ + alt.height], outline=INK, width=2)
    return sheet


def label(im: Image.Image, title: str, sub: str) -> Image.Image:
    """Caption band BELOW the frame, so it never covers the game's top card or PAUSE button."""
    im = im.convert("RGBA")
    out = Image.new("RGBA", (im.width, im.height + 72), (12, 16, 20, 255))
    out.alpha_composite(im, (0, 0))
    d = ImageDraw.Draw(out)
    d.text((16, im.height + 8), title, fill=(255, 255, 255, 255), font=bold(26))
    d.text((16, im.height + 42), sub, fill=(255, 196, 120, 255), font=font(18))
    return out


def phone_check() -> Image.Image:
    """534x300 check: (top) the three beats shrunk to 534x300 as B did; (bottom) real renders with the game
    window at 534x300 (Godot drew 533x300), standby and 0.10 s into the break, plus the mesh during beat 2's
    camera zoom at 4x nearest-neighbour (frames 1, 11, 22, 33) to look for shimmer."""
    D = OUT / "shots" / "design-r2"
    M = OUT / "shots" / "motion-mesh-534"
    W_, H_ = 534 * 3 + 40, 300 * 2 + 300 + 260
    cv = Image.new("RGBA", (W_, H_), PAPER)
    d = ImageDraw.Draw(cv)
    d.text((10, 8), "OPTION C, PHONE-SIZE CHECK (534 x 300). Design drawing, not final art. Stills on a Mac, not a device test.", fill=INK, font=bold(20))
    y = 44
    for i, (f, t) in enumerate((("02-beat1-standby.png", "beat 1 standby (shrunk)"),
                                ("07-beat3-latch-f009.png", "beat 3, 0.15 s (shrunk)"),
                                ("13-beat3-latch-f048.png", "beat 3, 0.80 s (shrunk)"))):
        im = Image.open(D / f).convert("RGBA").resize((534, 300), Image.LANCZOS)
        cv.alpha_composite(im, (10 + i * 544, y))
        d.text((10 + i * 544, y + 302), t, fill=INK, font=font(18))
    y += 330
    for i, (f, t) in enumerate((("01-m-beat1-static.png", "beat 1, rendered at 533x300 (UI hidden)"),
                                ("40-m-beat3-shake-f06.png", "beat 3, 0.10 s, rendered at 533x300"))):
        im = Image.open(M / f).convert("RGBA")
        cv.alpha_composite(im, (10 + i * 544, y))
        d.text((10 + i * 544, y + 302), t, fill=INK, font=font(18))
    # mesh crops during the zoom
    cx = 10 + 2 * 544
    d.text((cx, y - 2), "mesh during beat 2's zoom, 4x nearest:", fill=INK, font=font(18))
    for j, fr in enumerate((1, 11, 22, 33)):
        name = "%02d-m-beat2-zoom-f%02d.png" % (fr + 1, fr)
        im = Image.open(M / name).convert("RGBA").crop((110, 192, 174, 224)).resize((256, 128), Image.NEAREST)
        cv.alpha_composite(im, (cx + (j % 2) * 266, y + 24 + (j // 2) * 150))
        d.text((cx + (j % 2) * 266, y + 24 + (j // 2) * 150 + 128), "f%02d" % fr, fill=INK, font=font(16))
    y += 340
    lines = open(OUT / "logs" / "r2-shimmer.txt").read().strip().splitlines()
    d.text((10, y), "Flicker during the zoom (shimmer.py; second difference of each frame resampled to world, blurred over one mesh cell):", fill=INK, font=font(18))
    for k_, ln in enumerate(lines):
        d.text((10, y + 26 + k_ * 20), ln, fill=INK_SOFT, font=ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 15))
    return cv


if __name__ == "__main__":
    sheet = construction()
    sheet.convert("RGB").save(OUT / "construction-drawing.png")
    tag = "OPTION C (rev 2) DESIGN DRAWING: flat-shaded layers drawn in a scratch copy of main's opening; not final art, not in the game"
    beats = [
        ("02-beat1-standby.png", "beat1-standby.png", "Beat 1  Standby: dark WOLF on the stand, lit by the roof fitting; umbilical on his back (amber); lock green"),
        ("07-beat3-latch-f009.png", "beat3-latch-fails.png", "Beat 3, 0.15 s  The guard lock tears off and hangs by its cable; lamp to red; connector lets go"),
        ("13-beat3-latch-f048.png", "beat3-stepping-out.png", "Beat 3, 0.80 s  Leaves telescoped aside; WOLF steps out, then walks right to the Director"),
    ]
    out_beats = []
    for src, dst, title in beats:
        im = label(Image.open(OUT / "shots" / "design-r2" / src), title, tag)
        im.convert("RGB").save(OUT / dst)
        out_beats.append(im)
    alt = label(Image.open(OUT / "shots" / "design-r2-plain" / "02-beat1-standby.png"),
                "Beat 1, alternative  Blank plates and a blank 1.2 m backplate: no sign text, no keypad", tag)
    alt.convert("RGB").save(OUT / "beat1-standby-no-text-no-keypad.png")
    phone_check().convert("RGB").save(OUT / "render" / "phone-check.png")
    # Strip: three beats on top, the construction drawing below, same width.
    bw = 1280
    top_h = out_beats[0].height
    strip_w = bw * 3
    cd = sheet.resize((strip_w, int(sheet.height * strip_w / sheet.width)), Image.LANCZOS)
    strip = Image.new("RGBA", (strip_w, top_h + cd.height), PAPER)
    for i, im in enumerate(out_beats):
        strip.alpha_composite(im, (i * bw, 0))
    strip.alpha_composite(cd, (0, top_h))
    strip = strip.resize((strip.width // 2, strip.height // 2), Image.LANCZOS)
    strip.convert("RGB").save(OUT / "strip.png")
    print("ok", sheet.size, strip.size)
