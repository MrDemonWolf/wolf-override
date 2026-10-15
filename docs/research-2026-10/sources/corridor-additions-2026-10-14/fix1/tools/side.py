"""side.py OUT x0 y0 x1 y1 scale IMG1 [IMG2 ...]  crops each image and puts them side by side (nearest zoom)."""
import sys
from PIL import Image
a = sys.argv
box = tuple(int(v) for v in a[2:6]); s = int(a[6])
ims = [Image.open(p).convert("RGB").crop(box) for p in a[7:]]
ims = [im.resize((im.width * s, im.height * s), Image.NEAREST) for im in ims]
out = Image.new("RGB", (sum(i.width for i in ims) + 6 * (len(ims) - 1), ims[0].height), (255, 0, 255))
x = 0
for i in ims:
    out.paste(i, (x, 0)); x += i.width + 6
out.save(a[1])
