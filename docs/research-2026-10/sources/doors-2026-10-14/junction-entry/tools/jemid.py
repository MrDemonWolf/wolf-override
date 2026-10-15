"""Junction entry, fix round 2 (review r2, N2): the junction's mid plate where the entry's cross-wall
stands. Scratch only; deterministic (NumPy, Pillow).

Round 1 cleared only plate x 0-25. The machinery the wall now stands over (the pipe column, the big
tank, the elbow of the main header) still showed through the doorway and below the wall's diagonal foot,
where the wall cut the tops off things standing in front of it. Here:

  1. everything left of the wall's back corner (x 124.1) above the walk line is erased: the wall's face,
     its doorway (the passage painted into the far plate shows there) and the floor triangle between the
     wall's foot and the walk line;
  2. (round 2 only) the header's elbow and the thin line's end between the corner and JOIN_X (x 147) were
     erased so both pipes could carry on into the wall; fix round 3 keeps them (RESTORE_ELBOW): the
     header turns up into its riser at the corner, as on main;
  3. the floor triangle is deck: the mid plate's own deck, re-sampled in the room's camera (vanishing
     point (511, 162)) from DECK_SHIFT metres nearer the camera along the same lines to the vanishing
     point, so its plate seams run to (511, 162); a little darker toward the wall's foot (further from the
     wet, lit front of the deck);
  4. left of the stub's lane face below the walk line it stays clear (the cutaway, as round 1).
Writes nothing itself: edit_mid() returns the RGBA plate (1920 x 1080, 2 px per world px, y from 52)."""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jedesign as JE  # noqa: E402
import jemodel as M  # noqa: E402

GAME = os.path.join(M.TRACK, "..", "main-junction", "apps", "game")
DECK_SHIFT = 5.0
RESTORE_ELBOW = True  # fix round 3
TRIANGLE_DARKEN = 0.82


def foot_line(door):
    """The wall's foot on the deck (its approach face at h 0): screen y as a function of x."""
    p0 = door.s(door.A_F + door.FRAME_FACE, 0.0)
    p1 = door.s(door.A_BACK, 0.0)
    xa, ya = door.s(-0.2, 0.0)
    pts = sorted([(xa, ya), p0, p1])
    xs = np.array([p[0] for p in pts])
    ys = np.array([p[1] for p in pts])
    return lambda X: np.interp(X, xs, ys)


RAIL_AXIS = 325.0  # plate px: the rail's right elbow and post (x 345-396) mirrored about this line


def rail_end(out, mid):
    """The yellow-black guard rail at 1.1 m ran on left into the machinery the wall now stands over; it
    now ends as it does at its right end: an elbow down into a post on the deck (its own right elbow and
    post, mirrored), at world x 129-137, clear of the wall's corner. The rail's stub between the corner
    and the new post is filled with the vertical pipe it hid (the pipe's own pixels from just above)."""
    h, w = out.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)
    # source shape: the straight rail (rows 684-699), the bend (centre (366, 708), radii 11..26), the post
    straight = (ys >= 683) & (ys <= 700) & (xs >= 345) & (xs <= 366)
    rr = np.hypot(xs - 366.0, ys - 708.0)
    bend = (rr >= 10.0) & (rr <= 27.0) & (xs >= 366) & (ys <= 708)
    post = (xs >= 376) & (xs <= 393) & (ys >= 706) & (ys <= 774)
    src = straight | bend | post
    tx = (2 * RAIL_AXIS - xs).astype(int)
    sel = src & (tx >= 0) & (tx < w)
    # fill the old rail left of the new post with the pipe above it (rows 664-682 copied down 18 px)
    x_post_out = int(2 * RAIL_AXIS - 393)
    covered = np.zeros((h, w), bool)
    covered[ys[sel].astype(int), tx[sel]] = True
    for x in range(248, x_post_out + 10):
        for y in range(681, 702):
            if not covered[y, x]:
                out[y, x] = mid[y - 18, x]
    out[ys[sel].astype(int), tx[sel]] = mid[ys[sel].astype(int), xs[sel].astype(int)]


def edit_mid():
    door, _ = JE.lamps()
    mid = np.asarray(Image.open(os.path.join(GAME, "assets", "rooms", "junction-mid.png")).convert("RGBA")).astype(np.float64)
    h, w = mid.shape[:2]
    XX, YY = np.meshgrid((np.arange(w) + 0.5) / 2.0, (np.arange(h) + 0.5) / 2.0 + 52.0)
    corner_x = door.s(door.A_BACK, 0.0)[0]
    foot = foot_line(door)
    er1 = (XX < corner_x) & (YY < 440.0)
    # fix round 3 (review r3 R3-3, human r3): the header's elbow and riser and the service line's end between
    # the wall's back corner and JOIN_X are the room's own again (as on main): the header turns up into its
    # riser at the corner instead of a pasted straight run into the wall, so the far plate's ceiling lamp 0
    # stays hidden behind the elbow as on main (round 2 erased them here and exposed its bare lens).
    er2 = np.zeros_like(er1) if RESTORE_ELBOW else (XX >= corner_x - 1.0) & (XX < JE.JOIN_X) & (YY < 227.5)
    from jeinputs import mid_erase
    er3 = mid_erase(XX, YY, door) & (YY >= 440.0)
    out = mid.copy()
    erase = er1 | er2 | er3
    out[erase, 3] = 0
    out[erase, :3] = 0
    # the floor triangle: deck re-sampled from DECK_SHIFT m nearer the camera
    x_cross = 30.0
    tri = (XX >= x_cross - 0.5) & (XX < corner_x) & (YY >= foot(XX) - 1.0) & (YY < 440.0)
    s = (YY - M.HORIZON) / (M.FLOOR_Y - M.HORIZON)
    d = M.D0 / np.maximum(s, 1e-3) - M.D0
    xm = M.VPX + (XX - M.VPX) / np.maximum(s, 1e-3)
    d2 = d - DECK_SHIFT
    s2 = M.D0 / (M.D0 + d2)
    X2 = M.VPX + (xm - M.VPX) * s2
    Y2 = M.HORIZON + (M.FLOOR_Y - M.HORIZON) * s2
    # sample the plate (deck rows only: y > 441)
    px = X2 * 2.0 - 0.5
    py = (Y2 - 52.0) * 2.0 - 0.5
    samp = np.stack([ndimage.map_coordinates(mid[..., c], [py[tri], px[tri]], order=1, mode="nearest") for c in range(4)], -1)
    # darker toward the wall's foot (from the front edge of the triangle, y 440, up to the foot)
    depth_f = np.clip((440.0 - YY[tri]) / np.maximum(440.0 - foot(XX[tri]), 1.0), 0, 1)
    samp[:, :3] *= (1.0 - (1.0 - TRIANGLE_DARKEN) * depth_f)[:, None]
    samp[:, 3] = 255.0
    out[tri] = samp
    rail_end(out, mid)
    info = {"corner_x": round(float(corner_x), 2), "join_x": JE.JOIN_X, "erased_px": int(erase.sum()), "deck_triangle_px": int(tri.sum()),
            "deck_source_shift_m": DECK_SHIFT}
    return Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8), "RGBA"), info


if __name__ == "__main__":
    im, info = edit_mid()
    os.makedirs(os.path.join(M.TRACK, "out", "preview"), exist_ok=True)
    im.save(os.path.join(M.TRACK, "out", "preview", "junction-mid-edited.png"))
    print(info)
