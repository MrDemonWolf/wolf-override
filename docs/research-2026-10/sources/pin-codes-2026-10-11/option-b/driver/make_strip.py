"""Builds option B's one-image summary: keypad mocks plus a map of where codes are found and used."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

B = Path(sys.argv[1])
SHOTS = B / "shots"
FONTS = B.parent / "export-cfe304f/apps/game/assets/fonts"
W = 1920
BG = (7, 14, 21)
INK = (237, 245, 247)
MUTED = (159, 195, 210)
CYAN = (115, 221, 245)
RED = (255, 106, 85)
AMBER = (243, 174, 75)
GREEN = (164, 240, 196)
STEEL = (62, 79, 90)


def font(name: str, size: int, weight: str = "Bold"):
    f = ImageFont.truetype(str(FONTS / name), size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


H1 = font("Montserrat-Variable.ttf", 40)
H2 = font("Montserrat-Variable.ttf", 22)
H3 = font("Montserrat-Variable.ttf", 17, "SemiBold")
BODY = font("Roboto-Variable.ttf", 17, "Regular")
SMALL = font("Roboto-Variable.ttf", 14, "Regular")

TILE_W, TILE_H = 600, 338
GUT = 20
tiles = [
    ("01-idle", "1  IDLE  ·  reader woken to LOCAL by the winch reroute; WOLF read the code from his spot in the hatch doorway (told route)", AMBER),
    ("02-entering", "2  ENTERING  ·  controller focus on 9. Rushed route: WOLF still reads the code; only his tone is cooler", CYAN),
    ("03-denied", "3  WRONG CODE  ·  touch layout, 12 px key gaps; DENIED 1 OF 3 counts tries, not progress", RED),
    ("04-lockout", "4  THIRD WRONG CODE  ·  LOCKOUT 8 s: lamp back to LOCKDOWN, a reader-lock tone (not the sentry's klaxon), no beacons", RED),
    ("05-granted", "5  ACCEPTED  ·  ACCESS GRANTED, lamp OPEN, card closes and the existing bolt arc plays", GREEN),
    ("07-world-local-sealed", "6  ENGINEER-ONLY ROUTE  ·  the red tamper seal can be broken with a hold at any time; WOLF's read is never required", AMBER),
]
rows = 2
MAP_H = 420
top = 150
H = top + rows * (TILE_H + 70) + MAP_H + 60
img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)
d.text((40, 26), "PIN OPTION B  ·  LOCKDOWN ACCESS", font=H1, fill=INK)
d.text((40, 82), "Keypads are dead or refusing codes under the lockdown. The slice's own power work wakes a reader to LOCAL; WOLF reads the code on either relay route (only his tone changes), or the engineer breaks a tamper-sealed card alone.", font=BODY, fill=MUTED)
d.text((40, 108), "Mocks rendered in Godot 4.7.2 from main cfe304f (logic round 3: WOLF waits in the hatch doorway) with the game's theme and fonts, over the real junction at the tank-down beat. All on-screen words are PROPOSED, AWAITING NATHANIAL. Digits 7294 are a placeholder.", font=SMALL, fill=AMBER)

for i, (name, caption, tint) in enumerate(tiles):
    r, c = divmod(i, 3)
    x = 40 + c * (TILE_W + GUT)
    y = top + r * (TILE_H + 70)
    shot = Image.open(SHOTS / f"{name}.png").convert("RGB").resize((TILE_W, TILE_H), Image.LANCZOS)
    img.paste(shot, (x, y))
    d.rectangle((x - 1, y - 1, x + TILE_W, y + TILE_H), outline=tint, width=2)
    words = caption.split(" ")
    line, lines = "", []
    for w in words:
        test = (line + " " + w).strip()
        if d.textlength(test, font=SMALL) > TILE_W:
            lines.append(line)
            line = w
        else:
            line = test
    lines.append(line)
    for j, ln in enumerate(lines[:3]):
        d.text((x, y + TILE_H + 8 + j * 18), ln, font=SMALL, fill=INK if j == 0 else MUTED)

# --- Map ------------------------------------------------------------------------------------------
my = top + rows * (TILE_H + 70) + 10
d.text((40, my), "WHERE CODES ARE FOUND AND USED", font=H2, fill=INK)
d.text((40, my + 34), "square = reader (lamp shows LOCKDOWN / LOCAL / OPEN)    diamond = where the code comes from    arrow = the existing beat that wakes the reader", font=SMALL, fill=MUTED)
rooms = [
    ("MAINTENANCE CORRIDOR", 40, 560, [
        (110, "BREAKER", STEEL, "none"), (270, "RELAY / BYPASS", AMBER, "wake"), (440, "SEAL READER", RED, "reader"),
    ], "Teaches the lamps. USE: the engineer's own code is refused (LOCKDOWN). Relay or bypass power flips it to LOCAL and the seal rolls up as today. No code needed, no gate added."),
    ("RECORDS ACCESS", 640, 1080, [
        (720, "PURGE QUEUE", STEEL, "none"), (850, "MIRROR PORT", STEEL, "none"), (990, "EXIT READER", RED, "reader"),
    ], "Lamp only: LOCKDOWN until FIRST COPY SECURED, then OPEN with the existing exit arc. No keypad, no change to the copy beats."),
    ("SERVICE JUNCTION", 1160, 1880, [
        (1220, "BREAKER", STEEL, "none"), (1330, "BLAST DOOR", RED, "forced"), (1450, "TANK RELEASE", AMBER, "wake"), (1570, "WOLF READS", CYAN, "source"), (1690, "EXIT BOLT", AMBER, "reader"), (1810, "TAMPER SEAL", RED, "source"),
    ], "Blast door reader: LOCKDOWN / SECURE SIDE, then DOOR FORCED after the blast. Exit bolt: the tank drop's winch power wakes it to LOCAL. Code: WOLF's readout on both relay routes (his tone changes, never whether he helps), or hold USE on the tamper seal. The only essential keypad."),
]
band_y = my + 66
for title, x0, x1, stations, note in rooms:
    d.rounded_rectangle((x0, band_y, x1, band_y + 230), radius=10, fill=(12, 26, 38), outline=(63, 117, 144), width=2)
    d.text((x0 + 16, band_y + 12), title, font=H3, fill=CYAN)
    floor = band_y + 150
    d.line((x0 + 14, floor, x1 - 14, floor), fill=STEEL, width=3)
    for sx, label, tint, kind in stations:
        if kind == "reader":
            d.rectangle((sx - 14, floor - 52, sx + 14, floor - 16), fill=(20, 32, 42), outline=tint, width=3)
            d.ellipse((sx - 5, floor - 66, sx + 5, floor - 56), fill=tint)
        elif kind == "source":
            d.polygon([(sx, floor - 58), (sx + 16, floor - 40), (sx, floor - 22), (sx - 16, floor - 40)], fill=tint)
        elif kind == "forced":
            d.rectangle((sx - 14, floor - 52, sx + 14, floor - 16), fill=(20, 32, 42), outline=RED, width=3)
            d.line((sx - 10, floor - 48, sx + 10, floor - 20), fill=RED, width=3)
        elif kind == "wake":
            d.rectangle((sx - 10, floor - 40, sx + 10, floor - 16), fill=STEEL, outline=tint, width=2)
        else:
            d.rectangle((sx - 10, floor - 40, sx + 10, floor - 16), fill=STEEL)
        tw = d.textlength(label, font=SMALL)
        d.text((sx - tw / 2, floor + 8), label, font=SMALL, fill=tint if kind != "none" else MUTED)
    # wake arrows: power beat -> reader
    wakes = [s for s in stations if s[3] == "wake"]
    readers = [s for s in stations if s[3] == "reader"]
    for wsx, *_ in wakes:
        for rsx, *_ in readers:
            ay = floor - 82
            d.line((wsx, floor - 44, wsx, ay, rsx, ay, rsx, floor - 70), fill=AMBER, width=2, joint="curve")
            d.polygon([(rsx - 6, floor - 76), (rsx + 6, floor - 76), (rsx, floor - 68)], fill=AMBER)
    for sx, label, tint, kind in stations:
        if kind == "source":
            rsx = readers[0][0]
            ay = floor - 98
            d.line((sx, floor - 58, sx, ay, rsx, ay, rsx, floor - 72), fill=tint, width=2)
    # note
    words, line, yy = note.split(" "), "", band_y + 240
    for w in words:
        test = (line + " " + w).strip()
        if d.textlength(test, font=SMALL) > (x1 - x0):
            d.text((x0, yy), line, font=SMALL, fill=MUTED)
            yy += 18
            line = w
        else:
            line = test
    d.text((x0, yy), line, font=SMALL, fill=MUTED)

d.text((40, H - 34), "Private design material for WOLF//OVERRIDE (Nathanial Henniges). Mood reference only: no outside franchise names, logos or designs. Nothing here is built into the game.", font=SMALL, fill=STEEL)
img.save(B / "strip.png", optimize=True)
print(img.size)
