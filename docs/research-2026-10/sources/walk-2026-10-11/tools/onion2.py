"""Ground-locked onion of consecutive frames' lower band: frame i in red, frame i+1 shifted right
by the ground speed v in cyan. A planted foot shows as white (overlap).
usage: onion2.py DIR SPEED BASE OUT i [i ...]"""
import sys, numpy as np
from PIL import Image
d, v, base, out = sys.argv[1], float(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
idx = [int(x) for x in sys.argv[5:]]
tiles = []
for i in idx:
    import glob
    n = len(glob.glob(d + '/frame_*.png'))
    a = np.asarray(Image.open(f'{d}/frame_{i:02d}.png'))[..., 3] >= 128
    b = np.asarray(Image.open(f'{d}/frame_{(i+1)%n:02d}.png'))[..., 3] >= 128
    sh = int(round(v)); b2 = np.zeros_like(b); b2[:, sh:] = b[:, :b.shape[1]-sh]
    band = slice(base - 90, base + 4)
    t = np.zeros(a[band].shape + (3,), np.uint8)
    t[..., 0] = a[band] * 255; t[..., 1] = b2[band] * 255; t[..., 2] = b2[band] * 255
    t[-5, :] = [90, 90, 0]
    tiles.append(t); tiles.append(np.full((6, a.shape[1], 3), 60, np.uint8))
Image.fromarray(np.concatenate(tiles)).save(out)
