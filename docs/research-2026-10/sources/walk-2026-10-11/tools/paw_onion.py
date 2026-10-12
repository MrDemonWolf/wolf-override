"""Ground-locked red/green overlay of the bottom rows for frame pairs (yellow = planted and still).
usage: paw_onion.py ROW SPEED OUT i>j [i>j ...]"""
import sys, numpy as np
from PIL import Image, ImageDraw
row, v, out = sys.argv[1], float(sys.argv[2]), sys.argv[3]
pairs = [tuple(map(int, p.split('>'))) for p in sys.argv[4:]]
eng = row.startswith('eng'); base = 311 if eng else 263; W = 256 if eng else 512; band = 46
tiles = []
for i, j in pairs:
    A = np.asarray(Image.open(f'frames/{row}/frame_{i:02d}.png').convert('RGBA')).astype(float)[base - band:base + 2, :, 3]
    B = np.asarray(Image.open(f'frames/{row}/frame_{j:02d}.png').convert('RGBA')).astype(float)[base - band:base + 2, :, 3]
    Bs = np.zeros_like(B); s = int(round(v))
    if s > 0: Bs[:, s:] = B[:, :-s]
    else: Bs = B
    t = np.zeros(A.shape + (3,)); t[..., 0] = A; t[..., 1] = Bs
    t[-3, ::10] = 120
    im = Image.fromarray(t.clip(0, 255).astype(np.uint8)).resize((W * 3, (band + 2) * 3), Image.NEAREST)
    d = ImageDraw.Draw(im); d.text((4, 2), f'{i}->{j}', fill=(255, 255, 255))
    tiles.append(im)
H = sum(t.height + 4 for t in tiles)
canvas = Image.new('RGB', (W * 3, H), (40, 40, 60)); y = 0
for t in tiles: canvas.paste(t, (0, y)); y += t.height + 4
canvas.save(out)
