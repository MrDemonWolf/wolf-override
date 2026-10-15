"""Before/after sheet: round 6 s3 (render.sh) | mock after | this track's render.sh s3, at 720p
(1x context and a 4x crop) and phone shape (3x crop). Labels are typeset with the game's font."""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW6 = "scratchpad/real-slice/shots/raw6/slice"
FONT = os.path.join(ROOT, "game-plume/apps/game/assets/fonts")


def font(size):
    for f in sorted(os.listdir(FONT)):
        if f.lower().endswith((".ttf", ".otf")) and "regular" in f.lower():
            return ImageFont.truetype(os.path.join(FONT, f), size)
    for f in sorted(os.listdir(FONT)):
        if f.lower().endswith((".ttf", ".otf")):
            return ImageFont.truetype(os.path.join(FONT, f), size)
    return ImageFont.load_default()


def crop(path, box, k):
    im = Image.open(path).convert("RGB").crop(box)
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def main():
    cols = [
        ("Round 6 (render.sh): sourceless disc", os.path.join(RAW6, "B-720/s3-bypass-crank-clean.png"), os.path.join(RAW6, "B-phone/s3-bypass-crank-clean.png")),
        ("Mock: valve + simulated jet", os.path.join(ROOT, "mock/s3-720-after-1.png"), os.path.join(ROOT, "mock/s3-phone-after-0.png")),
        ("This track (render.sh, patch applied)", os.path.join(ROOT, "shots/B-720/s3-bypass-crank-clean.png"), os.path.join(ROOT, "shots/B-phone/s3-bypass-crank-clean.png")),
    ]
    rows = []
    for title, p720, pphone in cols:
        ctx = crop(p720, (540, 280, 860, 520), 1)  # 320x240
        ctx = ctx.resize((480, 360), Image.NEAREST)
        z = crop(p720, (690, 330, 780, 420), 4)  # 360x360
        ph = crop(pphone, (1010, 480, 1130, 600), 3) if os.path.exists(pphone) else Image.new("RGB", (360, 360), (20, 20, 20))
        rows.append((title, ctx, z, ph))
    W = 30 + 3 * (480 + 360 + 360 + 40)
    pad = 20
    colw = 480 + 360 + 360 + 2 * pad
    sheet = Image.new("RGB", (colw + 40, 3 * (360 + 60) + 70), (14, 15, 17))
    d = ImageDraw.Draw(sheet)
    d.text((20, 16), "s3 bypass crank: coolant relief jet (add7/plume). Left: 720p context (1.5x). Middle: 720p 4x. Right: phone shape 3x.", fill=(220, 225, 230), font=font(18))
    y = 60
    for title, ctx, z, ph in rows:
        d.text((20, y), title, fill=(200, 210, 215), font=font(18))
        sheet.paste(ctx, (20, y + 28)); sheet.paste(z, (20 + 480 + pad, y + 28)); sheet.paste(ph, (20 + 480 + 360 + 2 * pad, y + 28))
        y += 360 + 60
    sheet.save(os.path.join(ROOT, "mock", "sheet-before-after.png"))


if __name__ == "__main__":
    main()
