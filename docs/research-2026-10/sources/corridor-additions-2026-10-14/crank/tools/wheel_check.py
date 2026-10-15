"""Check the crank frames against the MANUAL BYPASS wheel at its real place and size.

Draws, in the engineer's cell space (cell px; the world is 0.254 world px per cell px), the game's own
wheel art (corridor-seal-atlas.png region 730,619 88x88 at 0.25 world px per atlas px, hub at world
(694, 400) with the engineer at x 674) behind each frame, at the rotation it has in that frame
(A: n x 45 deg, B: (n + 1) x 45 deg), on the wall colour, and measures the glove: the centroid of the
glove-coloured pixels (dark, neutral, alpha 255) within 16 cell px of the designed grip point, and how
far that centroid is from the rim's tube centre line (|distance to hub - rim radius|).

usage: wheel_check.py FRAMEDIR OUT.png [scale]
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import geometry as GEO  # noqa: E402

ATLAS = 'scratchpad/real-slice/game-slice/apps/game/assets/props/corridor-seal-atlas.png'
WALL = (24, 34, 42, 255)
TUBE_HALF = 0.9 * GEO.CELL_PER_WORLD  # the rim tube is about 1.8 world px thick


def wheel_layer(rot_deg):
    w = Image.open(ATLAS).convert('RGBA').crop((730, 619, 818, 707))
    k = 0.25 * GEO.CELL_PER_WORLD  # cell px per atlas px
    big = w.resize((int(round(88 * k * 4)), int(round(88 * k * 4))), Image.LANCZOS)
    big = big.rotate(-rot_deg, resample=Image.BICUBIC)  # Godot rotation_degrees > 0 is clockwise on screen
    sm = big.resize((int(round(88 * k)), int(round(88 * k))), Image.LANCZOS)
    layer = Image.new('RGBA', (GEO.CELL_W, GEO.CELL_H), (0, 0, 0, 0))
    layer.alpha_composite(sm, (int(round(GEO.HUB[0] - sm.width / 2)), int(round(GEO.HUB[1] - sm.height / 2))))
    return layer


def glove(frame, target):
    a = np.asarray(frame).astype(int)
    yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]]
    near = np.hypot(xx - target[0], yy - target[1]) <= 16
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    mx = np.maximum(np.maximum(r, g), b); mn = np.minimum(np.minimum(r, g), b)
    gl = near & (al >= 250) & (mx < 110) & (mx - mn < 30)
    if gl.sum() < 10:
        return None
    cx, cy = float(xx[gl].mean()), float(yy[gl].mean())
    d_hub = math.hypot(cx - GEO.HUB[0], cy - GEO.HUB[1])
    return dict(px=int(gl.sum()), centroid=[round(cx, 2), round(cy, 2)], to_target=round(math.hypot(cx - target[0], cy - target[1]), 2),
                off_rim_line=round(abs(d_hub - GEO.RIM_R), 2), clock_deg=round(math.degrees(math.atan2(cx - GEO.HUB[0], -(cy - GEO.HUB[1]))) % 360, 1),
                bbox=[int(xx[gl].min()), int(yy[gl].min()), int(xx[gl].max()), int(yy[gl].max())])


def main(framedir, out, scale=4):
    scale = int(scale)
    frames = [('A', 'frame_00.png', GEO.GRIP_A, 0.0), ('B', 'frame_01.png', GEO.GRIP_B, 45.0)]
    tiles, rep = [], {}
    for name, fn, tgt, rot in frames:
        fr = Image.open(os.path.join(framedir, fn)).convert('RGBA')
        bg = Image.new('RGBA', (GEO.CELL_W, GEO.CELL_H), WALL)
        bg.alpha_composite(wheel_layer(rot))
        bg.alpha_composite(fr)
        rep[name] = glove(fr, tgt)
        big = bg.resize((GEO.CELL_W * scale, GEO.CELL_H * scale), Image.NEAREST)
        d = ImageDraw.Draw(big)
        tx, ty = tgt[0] * scale, tgt[1] * scale
        d.ellipse([tx - 4, ty - 4, tx + 4, ty + 4], outline=(255, 140, 0, 255), width=1)
        d.line([(0, (GEO.BASE_ROW + 1) * scale), (big.width, (GEO.BASE_ROW + 1) * scale)], fill=(0, 200, 255, 255))
        d.text((6, 6), 'frame %s (%s), wheel %d deg' % (name, fn, rot), fill=(230, 230, 230, 255))
        tiles.append(big)
    sheet = Image.new('RGBA', (sum(t.width for t in tiles), tiles[0].height), WALL)
    x = 0
    for t in tiles:
        sheet.alpha_composite(t, (x, 0)); x += t.width
    sheet.convert('RGB').save(out)
    print(json.dumps(rep, indent=1))
    json.dump(rep, open(os.path.splitext(out)[0] + '.json', 'w'), indent=1)


if __name__ == '__main__':
    main(*sys.argv[1:])
