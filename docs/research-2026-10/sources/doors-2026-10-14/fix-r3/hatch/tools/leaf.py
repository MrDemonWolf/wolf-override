"""The sliding leaf alone (no occluders), shut, lit as in the room: the sprite the game moves.
Usage: python leaf.py OUT_DIR PPW"""
import sys
import numpy as np
from PIL import Image
sys.path.insert(0, __file__.rsplit("/", 1)[0])
import geom as g
import design as d

out, ppw = sys.argv[1], float(sys.argv[2])
d.EXPOSURE = float(open(sys.argv[3]).read()) if len(sys.argv) > 3 else 0.696
allp = g.parts(g.LEAD_SHUT, True)
leaf = [p for p in allp if p.group == "leaf"]
occ_world = [p for p in allp if p.group != "leaf" and isinstance(p, g.Rect) and p.layer != "key"]
x0, x1, y0, y1 = 930.0, 990.0, 328.0, 446.0
X, Y = d.grid(x0, x1, y0, y1, ppw)
idx, z, pos, uv = d.cast(leaf, X, Y)
# light the leaf with the room's occluders in place (the far jamb, the lintel), as it stands shut
parts_for_shade = leaf + occ_world
rgb = d.shade(parts_for_shade, idx, pos, uv)
srgb = d.to_srgb(rgb)
img = np.zeros(X.shape + (4,), np.uint8)
img[..., :3] = np.clip(srgb + 0.5, 0, 255).astype(np.uint8)
img[..., 3] = (idx >= 0) * 255
Image.fromarray(img, "RGBA").save(f"{out}/leaf-design-{int(ppw)}.png")
for i, p in enumerate(leaf):
    Image.fromarray(((idx == i) * 255).astype(np.uint8)).save(f"{out}/leaf-mask-{p.name}-{int(ppw)}.png")
print("leaf", img.shape, (idx >= 0).sum())
