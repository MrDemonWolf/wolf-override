"""Landing the doors (2026-10-14): deterministic fixes to the junction exit atlas
(apps/game/assets/props/junction-exit-atlas.png). No image model; NumPy, SciPy and Pillow only.

S2 (review r5): the wall pack's hard diagonal shadow on the cross-wall's room face read as a solid
sloped hood over the door. The band is refilled with the face's own concrete from the same row
(14 px further along the wall), brought to 0.9x the lit concrete beside it, with an edge that softens
with distance from the fitting (a penumbra widening as the shadow gets longer). A short soft contact
shadow stays under the housing. The fitting's light pool keeps its value; its edge is softened.

C1 (review r4/r5): the orange reflection streaks in the floor wedge in front of the exit (the back
piece's floor and the carried-on deck) were copied from the room's warm lamps and sat under a lamp
that turns green. Their hue is moved to the cool white of the wall pack above the door, at 0.85x
their luminance.

Pipe (Nathanial, 2026-10-14, Q-G "The coolant pipe"): the room's coolant line runs on past the
exit. Through the open doorway the passage's back wall now carries the line on: two 0.2 m pipes on a
strap clamp at about 1.0-1.4 m, shaded as cylinders lit from the passage's own fitting above, in the
wall's tint, with the fine grain of the room's painted pipes, and a soft contact shadow under them on
the wall. They run the whole width the doorway shows, from behind the far jamb's reveal to behind the
near jamb, so they read as running on in both directions.

usage: exit_fixes.py ATLAS_IN FAR_PLATE ATLAS_OUT PREVIEW_DIR
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

atlas_in, far_path, atlas_out, preview = sys.argv[1:5]
src = np.array(Image.open(atlas_in).convert("RGBA")).astype(np.float64)
img = src.copy()
rgb = img[..., :3]
alpha = img[..., 3]
LUM = np.array([0.2126, 0.7152, 0.0722])


def lum(a):
    return a[..., :3] @ LUM


# ---------------------------------------------------------------- S2: the wall pack's shadow
# Front piece (atlas x 0..226). The band's lit edge runs from the housing's top right (58, 336)
# down to the door head's corner (104, 405): x = 58 + 0.67 (y - 336); the band is 11 px wide left of it.
opaque = alpha >= 255
inner = ndimage.binary_erosion(opaque, iterations=2)
H, W = alpha.shape
yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
edge_x = 58.0 + 0.67 * (yy - 336.0)
centre = edge_x - 5.0
half = 6.0
# The penumbra widens with distance from the fitting.
sigma = 1.0 + 0.09 * np.clip(yy - 336.0, 0.0, None)
w = np.clip((half - np.abs(xx - centre)) / sigma + 0.5, 0.0, 1.0)
region = (yy >= 336) & (yy <= 414) & (xx < 112) & inner
keep = ((xx >= 56) & (xx <= 88) & (yy >= 371) & (yy <= 399)) | ((xx < 60) & (yy < 351))  # operator box, housing
w = np.where(region & ~keep, w, 0.0)
w = ndimage.gaussian_filter(w, 0.8)
w = np.where(region & ~keep, w, 0.0)

# The concrete the band is refilled with: the same row, 14 px further along the wall (clamped short
# of the column's arris line at x 110).
sx = np.clip(xx + 14.0, 0, 109).astype(int)
tex = rgb[yy.astype(int), sx]
tex_l = lum(tex)
tex_mean = ndimage.gaussian_filter(tex_l, 3.0)
# The lit concrete's level beside the band, row by row (x edge+3 .. edge+15), smoothed down the rows.
level = np.zeros(H)
for y in range(330, 420):
    x0 = int(58.0 + 0.67 * (y - 336.0)) + 3
    xs = [x for x in range(x0, min(x0 + 13, 110)) if opaque[y, x]]
    level[y] = np.median(lum(rgb[y, xs][None, :])[0]) if xs else 0.0
level = ndimage.uniform_filter1d(level, 9)
target = 0.9 * level[yy.astype(int)]
# A short soft contact shadow under the housing's lower right corner.
contact = 1.0 - 0.5 * np.exp(-(((yy - 352.0) / 5.0) ** 2) - (((xx - 61.0) / 6.0) ** 2))
fill = tex * (target / np.maximum(tex_mean, 1.0))[..., None] * contact[..., None]
rgb[:] = rgb * (1.0 - w[..., None]) + fill * w[..., None]
# The light pool's right edge, beside the band, softened along the row.
pool = (yy >= 351) & (yy <= 372) & (np.abs(xx - (edge_x - 12.0)) <= 4.0) & region & ~keep
blur = ndimage.gaussian_filter1d(rgb, 2.0, axis=1)
rgb[pool] = 0.5 * rgb[pool] + 0.5 * blur[pool]
s2_mask = (w > 0.02) | pool

# ---------------------------------------------------------------- C1: warm streaks in the floor wedge
# The back piece's floor (atlas x 428..714, rows 540..607) and the carried-on deck (x 716..868, rows 0..140).
floor = np.zeros_like(opaque)
floor[540:607, 428:714] = True
floor[0:140, 716:868] = True
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
mx = rgb.max(-1)
mn = rgb.min(-1)
sat = (mx - mn) / np.maximum(mx, 1.0)
warm = floor & (alpha > 0) & (r > b + 12) & (r >= g) & (sat > 0.18)
warm = ndimage.binary_dilation(warm, iterations=1) & floor & (alpha > 0)
wl = lum(rgb) * 0.85
cool = np.stack([wl * 0.88, wl * 0.98, wl * 1.08], -1)
soft = ndimage.gaussian_filter(warm.astype(np.float64), 0.7)
soft = np.where(floor, soft, 0.0)
rgb[:] = rgb * (1.0 - soft[..., None]) + cool * soft[..., None]
c1_count = int(warm.sum())

# ---------------------------------------------------------------- the coolant line in the passage
# Two 0.2 m pipes on a strap clamp along the passage's back wall, shaded as cylinders lit from the
# passage fitting above (diffuse plus the bright top highlight the room's own pipes carry), in the
# wall's own tint, with the fine grain of the room's painted pipes (far plate source x 1590..1640,
# rows 435..489, high-passed) so they are not flat CG.
far = np.array(Image.open(far_path).convert("RGB")).astype(np.float64)
grain_src = lum(far[435:490, 1590:1640])
grain = grain_src - ndimage.gaussian_filter(grain_src, 2.0)
grain = grain / max(np.abs(grain).max(), 1.0)
# The passage's visible back wall in the beyond piece: atlas x 261..306 (between the far jamb's reveal
# and the near jamb), its foot at atlas y 555 and its fitting (2.05 m) at y 416: 68 atlas px per metre.
foot, per_m = 555.0, (555.0 - 416.0) / 2.05
radius = 0.1 * per_m
centres = [foot - 1.27 * per_m, foot - 1.27 * per_m + 2.0 * radius + 1.5]
x_from, x_to = 261, 307
wall_tint = rgb[440:500, 270:300].reshape(-1, 3).mean(0)
wall_tint = wall_tint / (wall_tint @ LUM)
SS = 4


def cylinder(v, albedo, gloss):
    """Brightness of a horizontal cylinder's row at v (-1 top .. 1 bottom), lit from above-front."""
    nz = np.sqrt(max(0.0, 1.0 - v * v))
    diffuse = max(0.0, -v * 0.75 + nz * 0.66)
    spec = np.exp(-(((v + 0.62) / 0.17) ** 2))
    bounce = 0.12 * max(0.0, v) * nz  # the passage floor's bounce on the underside
    rim = 0.6 if v > 0.84 else 1.0
    return (albedo * (0.22 + 0.78 * diffuse + bounce) + gloss * spec) * rim


cov = np.zeros((H, W))
shade = np.zeros((H, W))
# The strut the clamps hang on: a vertical channel behind the pipes, visible above and below them,
# and the clamp bands that wrap each pipe in front of it (lighter galvanised steel, shaded with it).
clamp_x0, clamp_x1 = 283, 287
top_c = int(centres[0] - radius) - 3
bot_c = int(centres[1] + radius) + 3
for y in range(top_c, bot_c + 1):
    t = (y - top_c) / max(bot_c - top_c, 1)
    for x in range(clamp_x0, clamp_x1 + 1):
        side = x in (clamp_x0, clamp_x1)
        cov[y, x] = 1.0
        shade[y, x] = (30.0 if side else 64.0) - 14.0 * t
for c in centres:
    for y in range(int(c - radius) - 1, int(c + radius) + 2):
        acc_c = acc_p = acc_k = 0.0
        for k in range(SS):
            v = (y + (k + 0.5) / SS - c) / radius
            if abs(v) >= 1.0:
                continue
            acc_c += 1.0
            acc_p += cylinder(v, 64.0, 92.0)
            acc_k += cylinder(v, 96.0, 70.0)
        if not acc_c:
            continue
        a = acc_c / SS
        for x in range(x_from, x_to):
            clamp = clamp_x0 - 1 <= x <= clamp_x1 + 1
            value = (acc_k if clamp else acc_p) / acc_c
            if clamp and x in (clamp_x0 - 1, clamp_x1 + 1):
                value *= 0.55  # the band's edges
            shade[y, x] = shade[y, x] * (1.0 - a) + value * a if cov[y, x] > 0 else value
            cov[y, x] = max(cov[y, x], a)
# Grain from the painted pipes, tiled along the run, and a slow grime variation along it.
gy, gx = grain.shape
for y in range(top_c, bot_c + 1):
    for x in range(x_from, x_to):
        slow = 1.0 - 0.08 * np.sin((x - x_from) * 0.21 + (y - top_c) * 0.05) * np.cos((x - x_from) * 0.07)
        shade[y, x] *= (1.0 + 0.14 * grain[(y - top_c) % gy, (x - x_from) % gx]) * slow
inside = (alpha >= 255).astype(np.float64)
cov = cov * inside
pipe_rgb = np.clip(shade[..., None] * wall_tint[None, None, :], 0, 255)
# A soft contact shadow on the wall under the pipes and the clamp (light from the fitting above).
sh = np.zeros((H, W))
sh[bot_c - 1:bot_c + 5, x_from:x_to] = 1.0
sh = ndimage.gaussian_filter(sh, (2.2, 0.6)) * inside
sh[:, :x_from] = 0.0
sh[:, x_to:] = 0.0
rgb[:] = rgb * (1.0 - 0.38 * sh[..., None])
rgb[:] = rgb * (1.0 - cov[..., None]) + pipe_rgb * cov[..., None]
pipe_box = (x_from, top_c, x_to, bot_c + 5)
top = top_c
run_w = x_to - x_from
strip = np.zeros((bot_c - top_c + 1, run_w))

img[..., :3] = np.clip(rgb, 0, 255)
out = Image.fromarray(np.round(img).astype(np.uint8), "RGBA")
out.save(atlas_out, optimize=True)

# ---------------------------------------------------------------- previews and numbers
def checker(a):
    im = Image.fromarray(np.round(a).astype(np.uint8), "RGBA")
    bg = Image.new("RGBA", im.size, (255, 0, 255, 255))
    bg.alpha_composite(im)
    return bg


def pair(box, z, name):
    a = checker(src).crop(box)
    b = checker(img).crop(box)
    s = Image.new("RGBA", (a.width * z * 2 + 8, a.height * z), (0, 0, 0, 255))
    s.paste(a.resize((a.width * z, a.height * z), Image.NEAREST), (0, 0))
    s.paste(b.resize((b.width * z, b.height * z), Image.NEAREST), (a.width * z + 8, 0))
    s.save(f"{preview}/{name}.png")


pair((0, 300, 130, 420), 5, "s2-wallpack")
pair((428, 520, 714, 607), 3, "c1-floor-back")
pair((716, 0, 868, 140), 3, "c1-floor-deck")
pair((228, 390, 320, 600), 4, "pipe-passage")
print("pipe centres (atlas y) %s, %.2f and %.2f m" % ([round(c, 1) for c in centres], (foot - centres[0]) / per_m, (foot - centres[1]) / per_m))
band = s2_mask & (yy > 352)
print("S2 band px %d, mean lum before %.1f after %.1f, lit concrete beside %.1f" % (
    band.sum(), lum(src[..., :3])[band].mean(), lum(img[..., :3])[band].mean(), level[340:410].mean()))
print("C1 warm px recoloured %d" % c1_count)
print("pipe box (atlas) %s, top row %d (%.2f m), %d x %d px" % (pipe_box, top, (foot - top) / per_m, run_w, strip.shape[0]))
