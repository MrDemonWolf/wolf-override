import json, sys
from PIL import Image, ImageDraw, ImageFont
O, FONT = sys.argv[1], sys.argv[2]
d = O + "/shots/final/"
log = {e["file"]: e for e in json.load(open(d + "_log.json"))}
def f(px, b=False):
    t = ImageFont.truetype(FONT, px)
    t.set_variation_by_axes([700 if b else 400, 100]); return t
beats = [("02-beat1-standby.png", "1  STANDBY (beat 1)", "Lock lamp red: locked. Dock lamp dark, umbilical in: lockout."),
         ("05-beat3-f002.png", "2  THE LATCH FAILS (beat 3, 3 frames after the tap)", "Keeper torn off the leaf, bolt still thrown, lamp amber, leaf starts to roll."),
         ("19-beat3-f064.png", "3  OPEN, WOLF STEPS OUT (beat 3, +1.07 s)", "Leaf parked over the fixed bay; umbilical hanging; WOLF in front, z 5.")]
W = 2400; tw, th = 800, 450
draw_img = Image.open(O + "/construction-drawing.png")
S = Image.new("RGB", (W, 90 + th + 96 + draw_img.height), (238, 237, 231))
D = ImageDraw.Draw(S)
D.text((24, 18), "OPTION A  ·  secure barred enclosure  ·  design renders composited in-engine on main's real opening (7c19ee2), 1280x720, real camera, UI and timing", font=f(26, True), fill=(24, 34, 42))
D.text((24, 54), "Flat-shaded design drawing layers, not final art. Today's cage hidden in a scratch export; nothing in Git changed.", font=f(20), fill=(176, 58, 46))
for i, (fn, title, sub) in enumerate(beats):
    im = Image.open(d + fn).convert("RGB")
    if i == 1:
        # 3x inset of the lock, taken from the same frame
        e = log[fn]; z = e["cam_zoom"]; ox, oy = e["canvas_xform"][4], e["canvas_xform"][5]
        sx = lambda wx: 1.3333333 * (z * wx + ox); sy = lambda wy: 1.3333333 * (z * wy + oy)
        box = (int(sx(186)), int(sy(352)), int(sx(222)), int(sy(400)))
        crop = im.crop(box); crop = crop.resize((crop.width * 3, crop.height * 3), Image.LANCZOS)
        im.paste(crop, (1280 - crop.width - 20, 200)); ImageDraw.Draw(im).rectangle([1280 - crop.width - 20, 200, 1260, 200 + crop.height], outline=(255, 176, 32), width=3)
        ImageDraw.Draw(im).rectangle(box, outline=(255, 176, 32), width=2)
    S.paste(im.resize((tw, th), Image.LANCZOS), (i * tw, 90))
    D.text((i * tw + 14, 90 + th + 10), title, font=f(22, True), fill=(24, 34, 42))
    D.text((i * tw + 14, 90 + th + 44), sub, font=f(17), fill=(60, 70, 78))
S.paste(draw_img, (0, 90 + th + 96))
S.save(O + "/strip.png")
print(S.size)
