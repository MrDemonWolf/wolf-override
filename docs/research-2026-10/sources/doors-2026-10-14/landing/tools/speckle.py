"""Landing the doors (2026-10-14), review r5 C3: the junction entry's cross-wall carried an even light
bug-hole speckle over its whole face. Real bug holes (surface voids) gather in patches, most often
under form joints and pour lines; an even sprinkle reads as noise. Isolated specks (at most 4 px,
more than 12 levels off the 5x5 median) are faded towards that median, keeping a third to all of
their contrast in uneven patches (a low-frequency random field), so the face reads as cast
concrete with voids where they would be. Deterministic (NumPy, SciPy, Pillow; no image model).

usage: speckle.py ATLAS_IN ATLAS_OUT PREVIEW   (the junction entry atlas: wall and front pieces)
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

atlas_in, atlas_out, preview = sys.argv[1:4]
img = np.array(Image.open(atlas_in).convert("RGBA")).astype(np.float64)
before = img.copy()
LUM = np.array([0.2126, 0.7152, 0.0722])
rng = np.random.default_rng(20261015)
# The entry's cross-wall (ENTRY_WALL_REGION) and its column (ENTRY_FRONT_REGION), atlas px.
PIECES = [(92, 2, 280, 607), (2, 2, 88, 634)]
total = faded = 0
for x0, y0, w, h in PIECES:
    piece = img[y0:y0 + h, x0:x0 + w]
    rgb = piece[..., :3]
    opaque = ndimage.binary_erosion(piece[..., 3] >= 255, iterations=2)
    l = rgb @ LUM
    med = ndimage.median_filter(rgb, size=(5, 5, 1))
    d = l - med @ LUM
    cand = (np.abs(d) > 12.0) & opaque
    labels, n = ndimage.label(cand)
    sizes = ndimage.sum(cand, labels, index=np.arange(1, n + 1))
    small = np.isin(labels, np.nonzero(sizes <= 4)[0] + 1)
    field = ndimage.gaussian_filter(rng.standard_normal((h, w)), 9.0)
    field = (field - field.min()) / max(field.max() - field.min(), 1e-6)
    patch = np.clip((field - 0.55) / 0.2, 0.0, 1.0)
    keep = 0.33 + 0.67 * patch
    f = np.where(small, 1.0 - keep, 0.0)
    f = np.maximum(f, ndimage.gaussian_filter(f, 0.5) * small)
    rgb[:] = rgb * (1.0 - f[..., None]) + med * f[..., None]
    total += int(small.sum())
    faded += int((f > 0.4).sum())
img[..., :3] = np.clip(img[..., :3], 0, 255)
Image.fromarray(np.round(img).astype(np.uint8), "RGBA").save(atlas_out, optimize=True)


def view(a, box):
    c = Image.fromarray(np.round(a).astype(np.uint8), "RGBA").crop(box)
    bg = Image.new("RGBA", c.size, (255, 0, 255, 255))
    bg.alpha_composite(c)
    # Lifted 3x so the speckle shows at review size.
    arr = np.array(bg).astype(np.float64)
    arr[..., :3] = np.clip(arr[..., :3] * 3.0, 0, 255)
    return Image.fromarray(arr.astype(np.uint8)).resize((c.width * 3, c.height * 3), Image.NEAREST)


box = (150, 200, 330, 420)
a, b = view(before, box), view(img, box)
s = Image.new("RGBA", (a.width * 2 + 6, a.height), (0, 0, 0, 255))
s.paste(a, (0, 0))
s.paste(b, (a.width + 6, 0))
s.save(preview)
print("isolated specks %d px; faded by more than 40 %%: %d px" % (total, faded))
