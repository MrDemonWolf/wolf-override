"""Previews a CVD-canvas RGBA layer over a render.sh capture (1280x720, door-end camera), as the game
places it (world = 676 + px/4, 150 + py/4; screen = ((world - cam) * 1.35 + (480, 270)) * 4/3).
usage: preview.py <capture.png> <layer.png> <out.png> [crop x0 y0 x1 y1 scale]"""
import sys
import numpy as np
from PIL import Image
cap = Image.open(sys.argv[1]).convert("RGBA")
lay = Image.open(sys.argv[2]).convert("RGBA")
cam = (604.4, 360.0)
k = 1.35 * 4 / 3 / 4
sx0 = ((676 - cam[0]) * 1.35 + 480) * 4 / 3
sy0 = ((150 - cam[1]) * 1.35 + 270) * 4 / 3
w, h = lay.size
big = lay.resize((int(round(w * k)), int(round(h * k))), Image.Resampling.LANCZOS)
out = cap.copy()
out.alpha_composite(big, (int(round(sx0)), int(round(sy0))))
if len(sys.argv) > 4:
    x0, y0, x1, y1, s = map(int, sys.argv[4:9])
    out = out.crop((x0, y0, x1, y1)).resize(((x1 - x0) * s, (y1 - y0) * s), Image.NEAREST)
out.convert("RGB").save(sys.argv[3])
