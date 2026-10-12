import sys
from PIL import Image, ImageDraw, ImageFont
O = sys.argv[1]
FONTS = O + "/../export-cfe304f/apps/game/assets/fonts/"
def mont(size, style="Bold"):
    f = ImageFont.truetype(FONTS + "Montserrat-Variable.ttf", size)
    try: f.set_variation_by_name(style)
    except Exception: pass
    return f
def rob(size):
    return ImageFont.truetype(FONTS + "Roboto-Variable.ttf", size)
BG = (7, 16, 27); PANEL = (16, 33, 48); LINE = (61, 90, 106); CYAN = (115, 221, 245)
AMBER = (242, 196, 109); RED = (255, 138, 143); GREEN = (164, 240, 196); MUTED = (159, 195, 210); WHITE = (236, 244, 247)
W = 1920
shots = O + "/shots/mock/"
def shot(name, w, h):
    return Image.open(shots + name + ".png").convert("RGB").resize((w, h), Image.LANCZOS)
H = 64 + 400 + 34 + 270 + 34 + 270 + 24 + 150 + 40
img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)
d.text((24, 16), "WOLF//OVERRIDE  ·  PIN OPTION A: THE FOUND CODE", font=mont(26), fill=WHITE)
d.text((W - 24, 22), "MOCK ONLY · NOTHING BUILT · EVERY LINE PROPOSED, AWAITING NATHANIAL · CODE 4071 IS A PLACEHOLDER", font=mont(13, "SemiBold"), fill=AMBER, anchor="ra")
# Row 1: the find, then the map.
y0 = 64
img.paste(shot("0-records-find", 704, 396), (24, y0))
d.rectangle((24, y0, 24 + 704, y0 + 396), outline=LINE, width=2)
d.text((36, y0 + 404), "FOUND  Records Access: hold USE at the ACCESS SCREEN; the code becomes a fact in the case", font=mont(13, "SemiBold"), fill=AMBER)
mx, my, mw, mh = 752, y0, W - 752 - 24, 396
d.rounded_rectangle((mx, my, mx + mw, my + mh), radius=10, fill=PANEL, outline=LINE, width=2)
d.text((mx + 20, my + 14), "WHERE THE CODE IS FOUND AND USED", font=mont(18), fill=WHITE)
rooms = [("MAINTENANCE CORRIDOR", 0.0, 0.31), ("RECORDS ACCESS", 0.345, 0.655), ("SERVICE JUNCTION", 0.69, 1.0)]
rx0, rx1, ry0, ry1 = mx + 24, mx + mw - 24, my + 92, my + 244
def X(f): return rx0 + (rx1 - rx0) * f
for name, a, b in rooms:
    d.rounded_rectangle((X(a), ry0, X(b), ry1), radius=8, fill=(10, 24, 36), outline=LINE, width=2)
    d.text((X(a) + 10, ry0 - 24), name, font=mont(13, "SemiBold"), fill=MUTED)
    d.line((X(a) + 8, ry1 - 26, X(b) - 8, ry1 - 26), fill=(40, 62, 76), width=3)
for a in (0.31, 0.655):
    d.polygon([(X(a) + 6, (ry0 + ry1) / 2 - 8), (X(a) + 20, (ry0 + ry1) / 2), (X(a) + 6, (ry0 + ry1) / 2 + 8)], fill=MUTED)
def station(f, room, label, col, shape="dot", up=False):
    a, b = room
    x = X(a) + (X(b) - X(a)) * f
    yy = ry1 - 26
    if shape == "dot":
        d.ellipse((x - 5, yy - 5, x + 5, yy + 5), fill=(90, 120, 136))
    elif shape == "find":
        d.rectangle((x - 11, yy - 52, x + 11, yy - 34), fill=(11, 26, 18), outline=col, width=2)
        for i in range(3): d.line((x - 7, yy - 48 + i * 5, x + 5 - i * 3, yy - 48 + i * 5), fill=col, width=2)
        d.line((x, yy - 34, x, yy - 6), fill=col, width=2)
    elif shape == "use":
        d.rounded_rectangle((x - 13, yy - 54, x + 13, yy - 28), radius=4, fill=(10, 24, 36), outline=col, width=2)
        for i in range(3):
            for j in range(3): d.rectangle((x - 9 + j * 7, yy - 50 + i * 7, x - 5 + j * 7, yy - 46 + i * 7), fill=col)
        d.line((x, yy - 28, x, yy - 6), fill=col, width=2)
    elif shape == "lamp":
        d.ellipse((x - 7, yy - 44, x + 7, yy - 30), outline=col, width=2)
        d.ellipse((x - 3, yy - 40, x + 3, yy - 34), fill=col)
    fnt = rob(12)
    if shape == "dot":
        d.text((x, yy - 10 if up else yy + 8), label, font=fnt, fill=col, anchor="md" if up else "ma")
    else:
        if shape == "use":
            d.text((x - 20, yy - 41), label, font=mont(11, "SemiBold"), fill=col, anchor="rm")
        else:
            top = {"find": yy - 56, "lamp": yy - 48}[shape]
            d.text((x, top), label, font=mont(11, "SemiBold"), fill=col, anchor="md")
    return x
C, R, J = (0.0, 0.31), (0.345, 0.655), (0.69, 1.0)
station(0.3, C, "BREAKER", MUTED)
station(0.52, C, "RELAY", MUTED)
station(0.66, C, "BYPASS", MUTED, up=True)
station(0.8, C, "SEAL (optional lamp)", RED, "lamp")
station(0.93, C, "SAFE", MUTED)
station(0.16, R, "PURGE", MUTED)
fx = station(0.36, R, "ACCESS SCREEN", AMBER, "find")
station(0.56, R, "MIRROR", MUTED)
station(0.86, R, "EXIT", MUTED)
station(0.21, J, "BREAKER", MUTED)
station(0.44, J, "VALVE", MUTED)
station(0.62, J, "RELEASE", MUTED)
ux = station(0.86, J, "HATCH READER", GREEN, "use")
# The code travels in the case: a dashed arc from find to use.
ay = ry0 - 46
pts = []
import math
for i in range(0, 101):
    t = i / 100
    px = fx + (ux - fx) * t
    py = (ry1 - 82) - math.sin(t * math.pi) * 96
    pts.append((px, py))
for i in range(0, len(pts) - 1, 4):
    d.line([pts[i], pts[min(i + 2, len(pts) - 1)]], fill=AMBER, width=3)
d.polygon([(ux - 9, ry1 - 92), (ux + 7, ry1 - 92), (ux - 1, ry1 - 80)], fill=AMBER)
mid = pts[50]
d.rounded_rectangle((mid[0] - 150, mid[1] - 30, mid[0] + 150, mid[1] - 6), radius=6, fill=BG, outline=AMBER, width=1)
d.text((mid[0], mid[1] - 18), "carried as a case fact: SERVICE OVERRIDE", font=mont(12, "SemiBold"), fill=AMBER, anchor="mm")
ly = ry1 + 32
rows = [
    (AMBER, "FOUND", "Optional read on the walk from PURGE to MIRROR. Engineer-only. WOLF may notice it (told the truth) or look past it (rushed). He never fetches it."),
    (GREEN, "USED", "Sentry down, calm beat: USE the HATCH READER. ENTER 4071 is one press; typing it works too. Accepted: the approved bolt whine, arc and hatch play."),
    (RED, "WRONG", "DENIED n/3 (tries, not a completion count); three wrong = READER LOCKED 5 s, a reader-lock tone. No sentry cue, nothing saved."),
    (MUTED, "NOT FOUND", "MANUAL RELEASE: hold USE 2.4 s, DOOR FORCED alarm (its own tone), then the SAME bolt whine, arc, flash and hatch."),
]
for i, (col, tag, text) in enumerate(rows):
    yy = ly + i * 30
    d.rounded_rectangle((mx + 20, yy, mx + 120, yy + 22), radius=5, outline=col, width=2)
    d.text((mx + 70, yy + 11), tag, font=mont(11), fill=col, anchor="mm")
    d.text((mx + 132, yy + 3), text, font=rob(14), fill=WHITE)
# Row 2: the four requested keypad states.
y1 = y0 + 396 + 34
names = [("1-idle", "IDLE · code in case, focus on ENTER 4071", AMBER), ("2-entering", "ENTERING · typed or pad, digits fill left to right", AMBER),
         ("3-wrong", "WRONG CODE · DENIED 1/3, cross shape + red + 3 short beeps", RED), ("5-accepted", "ACCEPTED · ACCESS GRANTED, tick + green + chirp", GREEN)]
for i, (n, cap, col) in enumerate(names):
    x = 24 + i * (456 + 16)
    img.paste(shot(n, 456, 256), (x, y1))
    d.rectangle((x, y1, x + 456, y1 + 256), outline=col, width=2)
    d.text((x + 4, y1 + 262), cap, font=mont(12, "SemiBold"), fill=col)
# Row 3: lockout, touch, and the MANUAL RELEASE route (crank, then the same arc).
y2 = y1 + 256 + 34
row3 = [("4-lockout", "LOCKOUT · 5 s, keys off, padlock lamp drains", RED),
        ("6-touch-unknown", "TOUCH, NO CODE · 92x78 keys, 12 px gaps", MUTED),
        ("7-manual-crank", "MANUAL RELEASE · crank, DOOR FORCED lamp", RED),
        ("8-manual-arc", "6/6 · the same bolt arc and flash", GREEN)]
for i, (n, cap, col) in enumerate(row3):
    x = 24 + i * (456 + 16)
    img.paste(shot(n, 456, 256), (x, y2))
    d.rectangle((x, y2, x + 456, y2 + 256), outline=col, width=2)
    d.text((x + 4, y2 + 262), cap, font=mont(12, "SemiBold"), fill=col)
# Row 4: the input notes.
y3 = y2 + 256 + 34
nx = 24
d.rounded_rectangle((nx, y3, W - 24, y3 + 150), radius=10, fill=PANEL, outline=LINE, width=2)
d.text((nx + 18, y3 + 12), "ONE CARD, THREE DEVICES, NO NEW INPUT ACTIONS", font=mont(16), fill=WHITE)
notes = [
    "Keyboard: digits typed directly (top row or numpad, read as text so AZERTY works), Backspace, Enter.",
    "Controller: D-pad or stick moves focus over the 3x4 phone-layout pad; only ui_accept (A) presses a key.",
    "Joypad A is also interact: the card ignores interact from joypad events, so one press never fires twice.",
    "Esc and Start are both pause_game: the first press (or B / ui_cancel) closes the card, the next one pauses.",
    "Touch: tap the keys (12 px gaps); move buttons hide, PAUSE stays; a tap outside the card closes it.",
    "Digit keys 1 and 2 are consumed by the card before Main._input, so the answer actions never fire behind it.",
    "The reader's state is a LAMP on the bolt panel (shape + colour); words only in reach and on the card.",
    "Lockout and DOOR FORCED use a door-alarm tone, never the sentry's klaxon. Save v5: the case id only.",
]
for i, t in enumerate(notes):
    cx = nx + 20 + (i % 2) * 940
    cy = y3 + 44 + (i // 2) * 25
    d.ellipse((cx, cy + 6, cx + 6, cy + 12), fill=CYAN)
    d.text((cx + 14, cy), t, font=rob(14), fill=WHITE)
d.text((24, H - 26), "Stills rendered from main @ cfe304f (logic round 3: WOLF waits in the hatch doorway) in Godot 4.7.2 with the game's own theme and fonts; the ACCESS SCREEN, reader lamp and card are scratch mocks over a frozen frame; still 8 is the game's own bolt arc. Not played, not device-tested.", font=rob(13), fill=MUTED)
img.save(O + "/strip.png")
print(img.size)
