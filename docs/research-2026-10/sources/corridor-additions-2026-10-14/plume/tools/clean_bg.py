"""Removes round 6's sourceless steam disc from the s3 capture, for the mock frames only.

The corridor camera is the same in every door-end frame (604.444, 360), so where the disc sits the
wall and relay are the same pixels in s7 (A route, the engineer and WOLF are past the door). The
engineer is drawn over the disc (actors are above the bypass handle), so his pixels are kept from
s3: in the strip where he stands, a pixel is taken as 'disc over background' only when one blend
factor explains all three channels (s3 = steam * A + bg * (1 - A), steam #bfe8ff).
usage: clean_bg.py <s3.png> <s7.png> <out.png> <scale 1.8|2.7> <screen_w> <screen_h>
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

STEAM = np.array([191, 232, 255], float)


def world_to_screen(wx, wy, scale, w, h):
    return (wx - 604.444) * scale + w / 2, (wy - 360.0) * scale + h / 2


def main(s3_path, s7_path, out_path, scale, w, h):
    s3 = np.array(Image.open(s3_path).convert("RGB")).astype(float)
    s7 = np.array(Image.open(s7_path).convert("RGB")).astype(float)
    # the disc lives around world x 615..665, y 345..420 (round 6 HISS_OFFSET puff)
    x0, y0 = world_to_screen(618.0, 349.4, scale, w, h)
    x1, y1 = world_to_screen(692.0, 425.0, scale, w, h)
    xe, _ = world_to_screen(660.5, 0, scale, w, h)  # left edge of the engineer's strip
    x0, y0, x1, y1, xe = int(x0), int(y0), int(x1), int(y1), int(xe)
    out = s3.copy()
    out[y0:y1, x0:xe] = s7[y0:y1, x0:xe]
    lum = lambda c: c @ np.array([0.299, 0.587, 0.114])
    xe -= 3  # overlap the strip with the replaced block so its edge column is tested too
    reg3 = s3[y0:y1, xe:x1]; reg7 = s7[y0:y1, xe:x1]
    den = STEAM - reg7
    A = np.where(np.abs(den) > 8, (reg3 - reg7) / np.where(np.abs(den) > 8, den, 1), np.nan)
    spread = np.nanmax(A, axis=2) - np.nanmin(A, axis=2)
    amean = np.nanmean(A, axis=2)
    brighter = lum(reg3) - lum(reg7) > 3.0
    disc = (spread < 0.12) & (amean > 0.0) & (amean < 0.9) & brighter
    disc = ndimage.binary_opening(disc, iterations=1)
    disc[:, :3] = True
    sub = out[y0:y1, xe:x1]
    sub[disc] = reg7[disc]
    # the anti-aliased fringe where the disc met the engineer's outline: bluish, brighter than
    # the background and next to replaced pixels
    near = ndimage.binary_dilation(disc, iterations=2) & ~disc
    bluish = (reg3[..., 2] - reg3[..., 0] > 30) & brighter
    fringe = near & bluish
    sub[fringe] = reg7[fringe]
    actor = ~(disc | fringe)
    # above the relay, right of the COOLANT FAULT tag, the disc's glow reached up the wall
    tx, ty = world_to_screen(663.5, 330.0, scale, w, h)
    tx, ty = int(tx), int(ty)
    top3 = s3[ty:y0, tx:x1]; top7 = s7[ty:y0, tx:x1]
    up = (lum(top3) - lum(top7) > 2.0) & (top3[..., 2] >= top3[..., 0])
    out[ty:y0, tx:x1][up] = top7[up]
    Image.fromarray(np.clip(np.round(out), 0, 255).astype(np.uint8)).save(out_path)
    print("cleaned", (x0, y0, x1, y1), "engineer strip from", xe, "actor px", int(actor.sum()))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]))
