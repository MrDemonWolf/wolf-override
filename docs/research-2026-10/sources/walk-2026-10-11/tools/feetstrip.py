"""Feet strip: bottom band of each frame, shifted by -i*speed so planted feet line up vertically."""
import sys, numpy as np
from PIL import Image, ImageDraw
row, speed = sys.argv[1], float(sys.argv[2]); n = int(sys.argv[3]); out = sys.argv[4]
band = 70; base = 263 if row.startswith('wolf') else 311
W = 512 if row.startswith('wolf') else 256
tot = W + int(speed * n) + 40
img = Image.new('RGB', (tot, (band + 6) * (n + 1)), (30, 30, 40))
d = ImageDraw.Draw(img)
for i in range(n + 1):
    f = Image.open(f'frames/{row}/frame_{i % n:02d}.png').convert('RGBA')
    crop = f.crop((0, base - band + 4, W, base + 4))
    x = int(round(20 + (n - i) * speed)) if False else int(round(20 + i * speed))
    # world-fixed ground: character moves right by speed per frame, so draw at +i*speed
    img.paste(crop, (x, i * (band + 6)), crop)
    d.text((2, i * (band + 6)), str(i % n), fill=(255, 255, 0))
for gx in range(0, tot, 20):
    d.line([(gx, 0), (gx, img.height)], fill=(60, 60, 80))
img.save(out)
