"""crop.py IN OUT x0 y0 x1 y1 scale  (nearest-neighbour zoom)"""
import sys
from PIL import Image
a = sys.argv
im = Image.open(a[1]).convert("RGB").crop(tuple(int(v) for v in a[3:7]))
s = int(a[7])
im.resize((im.width * s, im.height * s), Image.NEAREST).save(a[2])
