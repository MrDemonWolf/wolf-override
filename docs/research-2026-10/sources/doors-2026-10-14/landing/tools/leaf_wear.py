"""Landing the doors (2026-10-14), review r4/r5 C2: wear on the swing leaves, deterministic (NumPy,
SciPy and Pillow; no image model).

- Kick plates: the push faces' kick plates read as mottled granite. A satin stainless or painted
  protection plate (ANSI/BHMA A156.6) shows fine horizontal scratches: each plate's interior is
  rebuilt as brushed steel at its own mean value and top-to-bottom falloff, with fine horizontal
  grain, a few longer scratches and two darker toe scuffs low in the middle; its rim is kept.
- Scuffs: the leaf faces carried evenly scattered short dashes. Wear gathers where hands, feet and
  carts touch a door: by the lever on the lock side and low on the leaf. Dashes elsewhere fade to a
  fifth of their contrast; those in the wear zones stay, in uneven clusters.

The leaf images are albedo (SwingLeaf lights them per vertex), so nothing here paints light.
usage: leaf_wear.py ATLAS_IN ATLAS_OUT PREVIEW KIND   (KIND: records | jentry)
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

atlas_in, atlas_out, preview, kind = sys.argv[1:5]
img = np.array(Image.open(atlas_in).convert("RGBA")).astype(np.float64)
before = img.copy()
LUM = np.array([0.2126, 0.7152, 0.0722])
rng = np.random.default_rng(20261014)

# (x, y, w, h) of each leaf face in the atlas, and whether it carries a kick plate (the push face).
FACES = {
    "records": [((552, 2, 73, 171), False), ((627, 2, 73, 171), True), ((702, 2, 73, 171), True)],
    "jentry": [((374, 2, 73, 171), False), ((449, 2, 73, 171), True)],
}[kind]


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


report = []
for (fx, fy, fw, fh), plate in FACES:
    face = img[fy:fy + fh, fx:fx + fw]
    rgb = face[..., :3]
    l = rgb @ LUM
    yy, xx = np.mgrid[0:fh, 0:fw].astype(np.float64)
    keep_out = np.zeros((fh, fw), bool)
    keep_out[:, :2] = keep_out[:, -2:] = True
    keep_out[:2, :] = keep_out[-4:, :] = True
    # Hardware: the lever and its rose, the sign plate and the card reader (bright or dark compact blobs
    # well above the floor), kept as painted.
    hard = (np.abs(l - ndimage.median_filter(l, 9)) > 45) & (yy < 140)
    hard = ndimage.binary_dilation(ndimage.binary_opening(hard, iterations=1), iterations=4)
    keep_out |= hard
    plate_rows = None
    if plate:
        rows = [y for y in range(120, fh - 2) if (l[y, 4:fw - 4] > 230).mean() > 0.6]
        if rows:
            top = rows[0]
            bottom = max(y for y in range(top + 4, fh - 1) if (l[y, 4:fw - 4] > 200).mean() > 0.35)
            cols = np.nonzero(l[top, :] > 230)[0]
            x0, x1 = int(cols.min()), int(cols.max())
            plate_rows = (top, bottom, x0, x1)
            keep_out[top - 2:bottom + 2, x0 - 1:x1 + 2] = True
    # --- scuffs: fade the evenly scattered dashes outside the wear zones
    detail = l - ndimage.gaussian_filter(l, 1.0)
    dash = (np.abs(detail) > 22) & ~keep_out
    dash = ndimage.binary_opening(dash, structure=np.ones((1, 2))) | (dash & (np.abs(detail) > 40))
    lever_side = fw - 14.0
    wear = np.clip(
        smoothstep(105.0, 150.0, yy) * (1.0 - 0.55 * np.abs(xx - fw * 0.5) / (fw * 0.5))
        + np.exp(-(((yy - 92.0) / 16.0) ** 2) - (((xx - lever_side) / 10.0) ** 2)),
        0.0, 1.0)
    clusters = ndimage.gaussian_filter(rng.standard_normal((fh, fw)), 6.0)
    clusters = smoothstep(-0.02, 0.06, clusters)
    keep = 0.2 + 0.8 * wear * (0.35 + 0.65 * clusters)
    soft = ndimage.gaussian_filter(dash.astype(np.float64), 0.6)
    soft = np.where(keep_out, 0.0, soft)
    fade = soft * (1.0 - keep)
    blur = ndimage.gaussian_filter(rgb, (1.0, 1.0, 0.0))
    rgb[:] = rgb * (1.0 - fade[..., None]) + blur * fade[..., None]
    # --- the kick plate: brushed stainless
    if plate_rows:
        top, bottom, x0, x1 = plate_rows
        ys0, ys1, xs0, xs1 = top + 1, bottom, x0 + 2, x1 - 1
        region = rgb[ys0:ys1, xs0:xs1]
        h, w = region.shape[:2]
        tint = region.reshape(-1, 3).mean(0)
        tint = tint / (tint @ LUM)
        means = (region @ LUM).mean(1)
        level = np.linspace(means[:3].mean(), means[-3:].mean(), h)
        level = 0.5 * level + 0.5 * means.mean()
        grain = ndimage.gaussian_filter1d(rng.standard_normal((h, w)), 5.0, axis=1) * 9.0
        grain += rng.standard_normal((h, 1)) * 2.5
        grain += ndimage.gaussian_filter1d(rng.standard_normal((h, w)), 1.0, axis=1) * 2.0
        val = level[:, None] + grain
        for _ in range(4):  # longer scratches
            sy = int(rng.integers(1, h - 1))
            sx = int(rng.integers(0, w - 12))
            ln = int(rng.integers(8, 26))
            val[sy, sx:sx + ln] += rng.uniform(10.0, 18.0)
        for cx in (w * 0.42, w * 0.6):  # toe scuffs, low in the middle
            gy, gx = np.mgrid[0:h, 0:w]
            val -= 26.0 * np.exp(-(((gy - (h - 4.0)) / 2.6) ** 2) - (((gx - cx) / 7.5) ** 2))
        rgb[ys0:ys1, xs0:xs1] = np.clip(val[..., None] * tint[None, None, :], 0, 255)
        report.append("face %s plate rows %d..%d cols %d..%d, mean %.1f, mottle std %.1f -> %.1f" % (
            (fx, fy), top, bottom, x0, x1, means.mean(), (before[fy + ys0:fy + ys1, fx + xs0:fx + xs1, :3] @ LUM).std(),
            (rgb[ys0:ys1, xs0:xs1] @ LUM).std()))
    report.append("face %s dashes faded %d px (of %d found)" % ((fx, fy), int((fade > 0.3).sum()), int(dash.sum())))

img[..., :3] = np.clip(img[..., :3], 0, 255)
Image.fromarray(np.round(img).astype(np.uint8), "RGBA").save(atlas_out, optimize=True)

panels = []
for (fx, fy, fw, fh), _ in FACES:
    for src in (before, img):
        crop = Image.fromarray(np.round(src[fy:fy + fh, fx:fx + fw]).astype(np.uint8), "RGBA")
        panels.append(crop.resize((fw * 3, fh * 3), Image.NEAREST))
sheet = Image.new("RGBA", (sum(p.width + 6 for p in panels), panels[0].height), (255, 0, 255, 255))
x = 0
for p in panels:
    sheet.paste(p, (x, 0))
    x += p.width + 6
sheet.save(preview)
print("\n".join(report))
