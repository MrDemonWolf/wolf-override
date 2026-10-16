"""Checks of the head-plate repaint: high-pass detail in the review's box, and 5x stretched crops."""
import os, sys
sys.dont_write_bytecode = True
import numpy as np
from PIL import Image
from scipy import ndimage
LUM = np.array([0.2126, 0.7152, 0.0722])
BOX = (slice(296, 338), slice(728, 840))

def hp_std(path, sigma):
    a = np.array(Image.open(path).convert("RGBA")).astype(float)
    L = (a[..., :3] * LUM).sum(-1)
    h = L - ndimage.gaussian_filter(L, sigma)
    return float(h[BOX].std())

def crops(path, out_prefix):
    a = np.array(Image.open(path).convert("RGBA")).astype(float)
    x0, x1, y0, y1 = 700, 870, 270, 370
    c = a[y0:y1, x0:x1, :3]
    L = (c * LUM).sum(-1)
    hp = L - ndimage.gaussian_filter(L, 3)
    Image.fromarray(np.clip(128 + hp * 8, 0, 255).astype(np.uint8)).resize(((x1 - x0) * 5, (y1 - y0) * 5), Image.NEAREST).save(out_prefix + "-hp-5x.png")
    lo, hi = np.percentile(L, 2), np.percentile(L, 98)
    st = np.clip((c - lo) / max(hi - lo, 1) * 255, 0, 255)
    Image.fromarray(st.astype(np.uint8)).resize(((x1 - x0) * 5, (y1 - y0) * 5), Image.NEAREST).save(out_prefix + "-stretch-5x.png")

if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(os.path.basename(p), " ".join("sigma %.1f: %.2f" % (s, hp_std(p, s)) for s in (1.0, 1.5, 2.0, 3.0)))
        crops(p, os.path.splitext(p)[0])


def plate_hp_std(path, sigma, mask):
    """High-pass luma spread over the head plate's flat paint inside the box (the designed joints,
    bolts, edges, the parked leaf's stripes and the doorway left out), 1 px in from its edges."""
    a = np.array(Image.open(path).convert("RGBA")).astype(float)
    L = (a[..., :3] * LUM).sum(-1)
    h = L - ndimage.gaussian_filter(L, sigma)
    return float(h[mask].std())
