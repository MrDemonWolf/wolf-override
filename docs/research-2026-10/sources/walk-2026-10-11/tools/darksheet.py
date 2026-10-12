import sys
from PIL import Image, ImageDraw
src, out = sys.argv[1], sys.argv[2]
base = int(sys.argv[3]) if len(sys.argv) > 3 else None; px = int(sys.argv[4]) if len(sys.argv) > 4 else None
cw = int(sys.argv[5]) if len(sys.argv) > 5 else None; ch = int(sys.argv[6]) if len(sys.argv) > 6 else None
im = Image.open(src); bg = Image.new('RGBA', im.size, (24, 32, 46, 255)); bg.alpha_composite(im)
d = ImageDraw.Draw(bg)
if base is not None:
    for y in range(0, im.height, ch):
        d.line([(0, y + base), (im.width, y + base)], fill=(90, 120, 150, 255))
    for x in range(0, im.width, cw):
        d.line([(x + px, 0), (x + px, im.height)], fill=(90, 120, 150, 255))
        d.line([(x, 0), (x, im.height)], fill=(60, 60, 60, 255))
bg.convert('RGB').save(out)
