import json, os, sys
from PIL import Image, ImageDraw, ImageFont
B = sys.argv[1]; FONT = sys.argv[2]
run = os.path.join(B, "shots/run7-r2"); out = os.path.join(B, "render")  # revision 2
log = {e["file"]: e for e in json.load(open(os.path.join(run, "_log.json")))}
def F(sz, bold=False):
    f = ImageFont.truetype(FONT, sz)
    try: f.set_variation_by_name("Bold" if bold else "Regular")
    except Exception: pass
    return f
BEATS = [
    ("B1-standby.png", "02-beat1-standby.png", "BEAT 1  -  WOLF in standby, sealed inside",
     "Stack light green (sealed and locked), lock lamp green, reader unlit, umbilical on his shoulders, grey interior, no glare on the glass."),
    ("B3a-latch-fails.png", "08-beat3-latch-f008.png", "BEAT 3, 0.13 s after the tap  -  the latch fails from the inside",
     "Keeper tears out of the leaf's edge and falls; the bolt stays thrown; stack light red (the one red), lock lamp amber; sparks at the keeper."),
    ("B3b-steps-out.png", "17-beat3-latch-f060.png", "BEAT 3, 1.0 s after the tap  -  open, WOLF steps out toward the Director",
     "Leaf parked over the fixed panel; seal torn at the lock edge; a blue pool round WOLF's body lights; keeper on the floor."),
    ("extra-B2-wake.png", "04-beat2-wake-settled.png", "BEAT 2  -  WOLF wakes himself (extra)",
     "Umbilical ejected and reeled up; stack light stays green (no warning); his body lights make a small blue pool behind him."),
    ("extra-B6-route.png", "25-beat6-only-open-route.png", "BEAT 6  -  WOLF turns from the Director (extra)",
     "He walks left in front of the open cell, not back into it; exit direction is still Nathanial's call (problem 20)."),
]
BEATS.append(("B1-standby-no-text-no-keypad.png", "02-beat1-standby.png", "BEAT 1, alternative  -  no sign text, no keypad",
              "Blank equipment plate instead of CU-01; blanking cover instead of the keypad. Needs no exception from Nathanial.", "run7-r2-plain"))
made = []
for item in BEATS:
    name, src, title, note = item[:4]
    rr = os.path.join(B, "shots", item[4]) if len(item) > 4 else run
    im = Image.open(os.path.join(rr, src)).convert("RGB")
    e = {f["file"]: f for f in json.load(open(os.path.join(rr, "_log.json")))}[src]
    band = 92
    c = Image.new("RGB", (1280, 720 + band), (18, 22, 26))
    c.paste(im, (0, 0))
    d = ImageDraw.Draw(c)
    d.rectangle([0, 720, 1280, 720 + band], fill=(232, 234, 228))
    d.text((16, 728), "DESIGN RENDER, NOT FINAL ART  -  Option B (rev 2) sealed cell, flat-shaded, in main 7c19ee2's opening (1280x720 capture)", font=F(17, True), fill=(160, 40, 30))
    d.text((16, 752), title, font=F(19, True), fill=(25, 30, 35))
    d.text((16, 778), note + f"  [opening {e['opening']:.2f}, camera zoom {e['cam_zoom']:.2f}]", font=F(15), fill=(25, 30, 35))
    c.save(os.path.join(out, name)); made.append((name, c))
    print(name)
# phone-size check: 2.4x smaller than the 1280 window (about a 5.5-inch phone at arm's length)
ph = Image.new("RGB", (3 * 534 + 40, 300 + 40), (232, 234, 228))
d = ImageDraw.Draw(ph)
for i, (n, src) in enumerate([("B1", "02-beat1-standby.png"), ("B3a", "08-beat3-latch-f008.png"), ("B3b", "17-beat3-latch-f060.png")]):
    im = Image.open(os.path.join(run, src)).convert("RGB").resize((534, 300), Image.LANCZOS)
    ph.paste(im, (10 + i * 544, 30))
    d.text((10 + i * 544, 6), f"{n} at 534x300 (phone-size check)", font=F(15, True), fill=(25, 30, 35))
ph.save(os.path.join(out, "phone-check.png"))
# strip: three beats on top (each 640x406 incl. caption), construction drawing under
cons = Image.open(os.path.join(out, "construction.png")).convert("RGB")
tw = 3 * 640 + 4 * 16
cons_s = cons.resize((tw - 32, round(cons.height * (tw - 32) / cons.width)), Image.LANCZOS)
hdr = 70
H = hdr + 406 + 24 + cons_s.height + 16
st = Image.new("RGB", (tw, H), (232, 234, 228))
d = ImageDraw.Draw(st)
d.text((16, 12), "OPTION B (rev 2)  -  SEALED CONTAINMENT CELL  (design drawings and flat-shaded design renders, not final art; awaiting Nathanial)", font=F(24, True), fill=(25, 30, 35))
d.text((16, 44), "Top: three beats rendered in main 7c19ee2's opening at their real position. Bottom: construction drawing.", font=F(17), fill=(60, 60, 60))
for i in range(3):
    st.paste(made[i][1].resize((640, round(812 * 640 / 1280)), Image.LANCZOS), (16 + i * 656, hdr))
st.paste(cons_s, (16, hdr + 406 + 24))
st.save(os.path.join(B, "strip.png"))
print("strip", st.size)
