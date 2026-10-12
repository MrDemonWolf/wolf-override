"""Builds strip.png: the keypad mocks plus a small map of where codes are found and used.
Scratch only. Usage: python -I make_strip.py <option-c dir>"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(sys.argv[1])
MOCKS = ROOT / "mocks"
FONTS = ROOT.parent / "export-cfe304f/apps/game/assets/fonts"

BG = (6, 13, 22)
PANEL = (10, 24, 38)
LINE = (63, 117, 144)
CYAN = (115, 221, 245)
MUTED = (159, 195, 210)
AMBER = (255, 196, 107)
RED = (255, 138, 144)
GREEN = (164, 240, 196)
WHITE = (237, 245, 247)


def font(name: str, size: int, weight: str = "Regular") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONTS / name), size)
    f.set_variation_by_name(weight)
    return f


H1 = font("Montserrat-Variable.ttf", 34, "Bold")
H2 = font("Montserrat-Variable.ttf", 19, "Bold")
H3 = font("Montserrat-Variable.ttf", 15, "SemiBold")
BODY = font("Roboto-Variable.ttf", 16)
SMALL = font("Roboto-Variable.ttf", 14)
TINY = font("Roboto-Variable.ttf", 12)

W = 1920
TILE = (456, 256)
GAP = 16
M = 24

img = Image.new("RGB", (W, 1240), BG)
d = ImageDraw.Draw(img)

d.text((M, 18), "OPTION C  ·  SMALL AND OPTIONAL FIRST", font=H1, fill=WHITE)
d.text((M, 62), "Two optional keypads that guard extra evidence. The essential path never needs a code. "
       "Every word on screen is proposed, awaiting Nathanial.", font=BODY, fill=MUTED)
d.text((M, 84), "Mocks rendered in the game itself (main at cfe304f, logic round 3; its theme and fonts, 1280x720); the locker and terminal "
       "are code-drawn placeholders, the digits are placeholders.", font=SMALL, fill=MUTED)
d.rectangle((M, 110, W - M, 113), fill=CYAN)


def tile(path: str, x: int, y: int, num: str, title: str, note: str, tint) -> None:
    im = Image.open(MOCKS / path).convert("RGB").resize(TILE, Image.LANCZOS)
    img.paste(im, (x, y))
    d.rectangle((x - 1, y - 1, x + TILE[0], y + TILE[1]), outline=LINE, width=1)
    d.rectangle((x, y + TILE[1] + 6, x + 4, y + TILE[1] + 48), fill=tint)
    d.text((x + 12, y + TILE[1] + 4), f"{num}  {title}", font=H3, fill=WHITE)
    d.text((x + 12, y + TILE[1] + 26), note, font=TINY, fill=MUTED)


row1 = 130
d.text((M, row1), "KEYPAD 1  ·  RECORDS ACCESS  ·  MEDIA LOCKER (ACCESS: MAINT)  ·  holds the DATA CARTRIDGE", font=H2, fill=CYAN)
y = row1 + 32
x = M
tile("k1-1-idle.png", x, y, "1", "IDLE", "Controller focus starts on the known code: one press enters it.", CYAN)
x += TILE[0] + GAP
tile("k1-2-entering.png", x, y, "2", "ENTERING DIGITS", "Typing by hand stays optional (keyboard hint shown).", AMBER)
x += TILE[0] + GAP
tile("k1-3-wrong.png", x, y, "3", "WRONG CODE", "DENIED 1/3 counts tries, not progress. Touch layout: 12 px key gaps.", RED)
x += TILE[0] + GAP
tile("k1-5-accepted.png", x, y, "4", "ACCEPTED", "Green, a tick, ACCESS GRANTED; the door swings open in the room.", GREEN)

row2 = y + TILE[1] + 66
d.text((M, row2), "THIRD WRONG CODE, THE ROOM, AND KEYPAD 2 (PHASE 2)", font=H2, fill=CYAN)
y2 = row2 + 32
x = M
tile("k1-4-lockout.png", x, y2, "5", "LOCKED OUT 0:06", "Keys grey out for 6 s, amber lamp, one two-tone chirp. Nothing else.", AMBER)
x += TILE[0] + GAP
tile("k1-6-after.png", x, y2, "6", "AFTERWARDS, IN THE ROOM", "LOCKER OPEN; the approved cartridge text follows.", GREEN)
x += TILE[0] + GAP
tile("k2-1-idle.png", x, y2, "7", "KEYPAD 2  ·  LANE TERMINAL (SECURITY)", "WOLF waits in the hatch doorway (round 3). Terminal spot schematic.", RED)

bx = M + 3 * (TILE[0] + GAP)
d.rounded_rectangle((bx, y2, bx + TILE[0], y2 + TILE[1] + 48), radius=8, fill=PANEL, outline=LINE)
info = [
    ("ONE CARD, THREE INPUTS (no new actions)", CYAN, H3),
    ("Keyboard: type 0-9 (top row or numpad, read as", WHITE, SMALL),
    ("typed text so AZERTY works), Backspace deletes,", WHITE, SMALL),
    ("Enter submits, Esc closes.", WHITE, SMALL),
    ("Controller: D-pad or stick moves focus; A presses via", WHITE, SMALL),
    ("ui_accept only (joypad interact ignored). B closes.", WHITE, SMALL),
    ("Touch: tap. Keys 84x74 with 12 px gaps (about 8.6 pt);", WHITE, SMALL),
    ("walk and USE buttons hide, PAUSE stays.", WHITE, SMALL),
    ("", WHITE, SMALL),
    ("Digits 1 and 2 are the answer keys in play: the", MUTED, SMALL),
    ("card eats digit presses so no answer fires.", MUTED, SMALL),
    ("Every state = words + shape + colour + sound.", MUTED, SMALL),
]
iy = y2 + 14
for text, col, f in info:
    d.text((bx + 16, iy), text, font=f, fill=col)
    iy += 22 if f is SMALL else 26

# The map, right of the three tiles in row 2... use the remaining width at the bottom instead.
map_top = y2 + TILE[1] + 66
d.text((M, map_top), "WHERE THE CODES ARE FOUND AND USED", font=H2, fill=CYAN)
mx0 = M
mw = W - 2 * M
lane_h = 74
rooms = [
    ("MAINTENANCE CORRIDOR", [(350, "BREAKER", MUTED, 1), (605, "RELAY", MUTED, 1), (700, "BYPASS", MUTED, 1), (752, "SEAL", MUTED, -1), (876, "SAFE PT", MUTED, 1)]),
    ("RECORDS ACCESS", [(190, "PURGE QUEUE", MUTED, 1), (365, "MEDIA LOCKER  K1", CYAN, 1), (520, "MIRROR PORT", MUTED, 1), (830, "EXIT", MUTED, 1)]),
    ("SERVICE JUNCTION", [(200, "BREAKER", MUTED, 1), (420, "VALVE", MUTED, 1), (540, "RUBBLE", MUTED, 1), (586, "RELEASE", MUTED, -1), (700, "SENTRY (DOWN)", AMBER, 1), (790, "LANE TERMINAL  K2", RED, -1), (880, "HATCH", MUTED, 1)]),
]
label_w = 250
track_x0 = mx0 + label_w
track_w = 1000
ty = map_top + 34
lane_hs = [74, 74, 96]
tops = []
top = ty
for i, (name, stations) in enumerate(rooms):
    h = lane_hs[i]
    tops.append(top)
    d.rounded_rectangle((mx0, top, track_x0 + track_w + 20, top + h), radius=8, fill=PANEL, outline=LINE)
    d.text((mx0 + 14, top + 26), name, font=H3, fill=WHITE)
    fy = top + 46
    d.line((track_x0, fy, track_x0 + track_w, fy), fill=LINE, width=3)
    for wx, lab, col, side in stations:
        px = track_x0 + int(wx / 960 * track_w)
        big = col in (CYAN, RED, AMBER)
        r = 7 if big else 4
        d.ellipse((px - r, fy - r, px + r, fy + r), fill=col)
        f = H3 if big else TINY
        tw = d.textlength(lab, font=f)
        ly_ = (fy - (34 if big else 26)) if side > 0 else fy + 10
        d.text((px - tw / 2, ly_), lab, font=f, fill=col)
    top += h + 10
d.text((track_x0 + int(80 / 960 * track_w), tops[0] + 54), "No keypad in phases 1-2 (phase 3 idea: a SEAL reader that shows ACCESS REVOKED, flavour only)", font=TINY, fill=MUTED)
d.text((track_x0 + int(80 / 960 * track_w), tops[1] + 54), "K1 code: the engineer's own MAINT code, shown on the card from the start", font=TINY, fill=CYAN)
jt = tops[2]
fy = jt + 46
sx = track_x0 + int(700 / 960 * track_w)
kx = track_x0 + int(790 / 960 * track_w)
ay = jt + 82
d.line((sx, fy + 8, sx, ay, kx, ay, kx, fy + 30), fill=AMBER, width=2)
d.polygon([(kx - 5, fy + 36), (kx + 5, fy + 36), (kx, fy + 28)], fill=AMBER)
msg = "K2 code: pulled over the terminal's paired link (hold at the terminal) or WOLF's readout"
d.text((sx - 12 - d.textlength(msg, font=TINY), ay - 8), msg, font=TINY, fill=AMBER)
# Legend / key facts on the right of the map.
lx = track_x0 + track_w + 50
lines = [
    ("K1  MEDIA LOCKER", CYAN, H3),
    ("Code: the engineer's own MAINT code, known from the start.", WHITE, SMALL),
    ("The lockdown cut the network; this locker runs on its own controller.", MUTED, SMALL),
    ("Holds: DATA CARTRIDGE (approved item). WOLF: none (he is at the mirror).", MUTED, SMALL),
    ("", MUTED, SMALL),
    ("K2  LANE TERMINAL  (phase 2, needs the wider junction)", RED, H3),
    ("Refuses the MAINT code. The downed sentry holds its pairing code:", WHITE, SMALL),
    ("engineer: HOLD E at the terminal pulls it over the paired link (1.2 s), or", WHITE, SMALL),
    ("WOLF reads the link from the hatch doorway; no walk back (tone only).", WHITE, SMALL),
    ("Holds: SENTRY PATROL LOG (approved; STAND-DOWN CODE: NO RECORD).", MUTED, SMALL),
    ("", MUTED, SMALL),
    ("Wrong code: DENIED n/3, then a 6 s LOCKED OUT. Never a death, never a dead end.", AMBER, SMALL),
    ("No new input actions. Optional: skipping both changes nothing.", GREEN, SMALL),
]
ly = ty - 2
for text, col, f in lines:
    d.text((lx, ly), text, font=f, fill=col)
    ly += 22 if f is SMALL else 24

foot = top + 4
d.text((M, foot), "Station x positions are today's 960 px rooms (code at cfe304f); the room expansion moves them. "
       "Private design material: keep out of Git, public docs and PR text.", font=TINY, fill=MUTED)
img = img.crop((0, 0, W, foot + 30))
img.save(ROOT / "strip.png")
print(img.size)
