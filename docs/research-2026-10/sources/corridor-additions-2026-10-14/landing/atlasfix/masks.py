"""Atlas-space masks for the head plate's clean repaint (shared by the repaint and its checks)."""
import numpy as np, glob, os
from PIL import Image
from scipy import ndimage
ROOT = os.environ["ADD7"]
M = os.path.join(ROOT, "fix1/door/design/masks/")
F = os.path.join(ROOT, "fix4/door/design/masks/")
# The wall region in the atlas, and where it sits in round 8's 2-px design canvas (alpha matched).
WALL = (672, 2, 267, 613)
CANVAS_DX, CANVAS_DY = 16, 0
BOX = (slice(296, 338), slice(728, 840))

def canvas_mask(name):
    m = np.array(Image.open(M + name).convert("L")).astype(float) / 255
    h, w = m.shape
    d = m.reshape(h // 2, 2, w // 2, 2).mean((1, 3))
    out = np.zeros((1024, 1024))
    x, y, rw, rh = WALL
    out[y:y + rh, x:x + rw] = d[CANVAS_DY:CANVAS_DY + rh, CANVAS_DX:CANVAS_DX + rw]
    return out

def region_mask(name):
    m = np.array(Image.open(F + name).convert("L")).astype(float) / 255
    out = np.zeros((1024, 1024))
    x, y, rw, rh = WALL
    out[y:y + rh, x:x + rw] = m
    return out

def plate_mask():
    """The head plate's flat paint: its liner mask, less every designed feature on or next to it
    (joints and their lit edges, arrises, jamb pieces, the parked leaf's edge, the slot seals, the
    shadow under the plate) and less round 11's far jamb plate, each grown by 1 px."""
    plate = canvas_mask("wall--liner_head.png") > 0.5
    other = np.zeros_like(plate)
    for p in glob.glob(M + "wall--*.png"):
        n = os.path.basename(p)
        if n == "wall--liner_head.png":
            continue
        other |= canvas_mask(n) > 0.25
    for n in ("wall--far_plate.png", "wall--far_heads.png", "wall--far_washers.png", "wall--far_seams.png"):
        other |= region_mask(n) > 0.25
    other = ndimage.binary_dilation(other, iterations=1)
    return plate & ~other
