"""Option A revision 2: labelled beat renders (caption band BELOW the frame), the no-text/no-keypad
variant, a 534x300 phone-size check and the strip. Inputs are the real captures in shots/r2 and
shots/r2-plain. Usage: python -I renders_r2.py <option-a dir> <Roboto ttf>"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont

O, FONT = sys.argv[1], sys.argv[2]
R2 = os.path.join(O, "shots", "r2")
PL = os.path.join(O, "shots", "r2-plain")
log = {e["file"]: e for e in json.load(open(os.path.join(R2, "_log.json")))}


def f(px, b=False):
    t = ImageFont.truetype(FONT, px)
    t.set_variation_by_axes([700 if b else 400, 100])
    return t


TAG = "OPTION A (rev 2) DESIGN DRAWING: flat-shaded layers drawn in a scratch copy of main's opening; not final art, not in the game"


def label(im, title):
    im = im.convert("RGB")
    out = Image.new("RGB", (im.width, im.height + 72), (12, 16, 20))
    out.paste(im, (0, 0))
    d = ImageDraw.Draw(out)
    d.text((16, im.height + 8), title, font=f(26, True), fill=(255, 255, 255))
    d.text((16, im.height + 42), TAG, font=f(18), fill=(255, 196, 120))
    return out


BEATS = [
    (R2, "02-beat1-standby.png", "beat1-standby.png", "Beat 1  Standby: lock lamp green, dock lamp amber, umbilical on his withers; lining lit by the roof fitting"),
    (R2, "08-beat3-f005.png", "beat3-latch-fails.png", "Beat 3, inside the 0.15 s hold  Keeper torn off, hook bolt still thrown, lamp amber; the leaf has not moved"),
    (R2, "19-beat3-f064.png", "beat3-open-wolf-steps-out.png", "Beat 3, after the 0.5 s slide  Leaf parked over the fixed bay; WOLF steps out to the Director"),
    (R2, "04-beat2-wake-settled.png", "beat2-wake-extra.png", "Beat 2  He wakes himself: dock lamp blue, lock lamp still green (no warning)"),
    (PL, "02-beat1-standby.png", "beat1-standby-no-text-no-keypad.png", "Beat 1, alternative  Blank plates and a blanking cover: no sign text, no keypad"),
]
made = []
for folder, src, dst, title in BEATS:
    if folder == R2 and src in log:
        assert src != "08-beat3-f005.png" or log[src]["gate_opening"] == 0.0
    im = label(Image.open(os.path.join(folder, src)), title)
    im.save(os.path.join(O, "renders", dst))
    made.append(im)
# Phone-size check: the three beats shrunk to 534x300 (as B did).
ph = Image.new("RGB", (3 * 534 + 40, 300 + 40), (232, 234, 228))
d = ImageDraw.Draw(ph)
for i, (src, n) in enumerate((("02-beat1-standby.png", "beat 1"), ("08-beat3-f005.png", "beat 3, hold"), ("19-beat3-f064.png", "beat 3, open"))):
    im = Image.open(os.path.join(R2, src)).convert("RGB").resize((534, 300), Image.LANCZOS)
    ph.paste(im, (10 + i * 544, 30))
    d.text((10 + i * 544, 6), f"{n} at 534x300 (shrunk; not a device test)", font=f(15, True), fill=(25, 30, 35))
ph.save(os.path.join(O, "renders", "phone-check.png"))
# Strip: three beats on top, the construction drawing below.
draw_img = Image.open(os.path.join(O, "construction-drawing.png")).convert("RGB")
tw = 800
th = round(made[0].height * tw / made[0].width)
W = 2400
S = Image.new("RGB", (W, 90 + th + 20 + draw_img.height), (238, 237, 231))
D = ImageDraw.Draw(S)
D.text((24, 18), "OPTION A (rev 2)  ·  secure barred enclosure  ·  design renders in main's real opening (7c19ee2), 1280x720, real camera, UI and timing", font=f(26, True), fill=(24, 34, 42))
D.text((24, 54), "Flat-shaded design drawing layers, not final art. Today's cage hidden in a scratch export; nothing in Git changed.", font=f(20), fill=(176, 58, 46))
for i in range(3):
    S.paste(made[i].resize((tw, th), Image.LANCZOS), (i * tw, 90))
S.paste(draw_img, (0, 90 + th + 20))
S.save(os.path.join(O, "strip.png"))
print("ok", S.size)
