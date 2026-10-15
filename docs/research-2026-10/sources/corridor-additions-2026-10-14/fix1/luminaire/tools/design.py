"""The corridor's chain-hung luminaire near the door end (far plate, round 6's far patch v2), round 8.

Found when round 6 landed (PR #58) and by first-time players: at 1280x720 the fitting ends as a thin
bright bar right against the PAUSE button (o8, and the 1600x900 site capture), so it reads like a
stray UI line. It becomes a real fitting that reads as a lamp, shorter so its right end clears the
PAUSE button: a 0.6 m vapour-tight LED luminaire (80 plate px per metre: 48 x 9 px) centred on its
own feed conduit (x 1265), a grey body with end caps over an opal diffuser that glows, hung on two
rods from canopy plates under the ceiling tray. The old 1.2 m bar's ends and its two thin hangers
are taken back to the wall (inpainted from the wall beside them, then painted).

Writes luminaire/design/: flat.png (far-plate crop with the construction drawn flat), masks/*.png
(on the crop), spec.json. Crop: plate x 1200..1360, y 176..260."""
import json
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "design"))
FAR = "scratchpad/real-slice/game-slice/apps/game/assets/rooms/corridor-far.png"
CX0, CY0, CX1, CY1 = 1200, 176, 1360, 260
X0, X1 = 1213, 1261          # the fitting (0.6 m), 28 px left of where it was painted (PAINT_SHIFT)
PAINT_SHIFT = 28             # Codex painted it at x 1241..1289; the cleanup samples its paint 28 px to the right
BODY = (219, 224)
DIFF = (224, 227)
HANGERS = (1217, 1256)
CANOPY_Y = (192, 194)
OLD_BAR = (1230, 1329, 214, 232)
OLD_RODS = (1238, 1248, 1306, 1320)


def main():
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    far = np.asarray(Image.open(FAR).convert("RGB")).astype(float)
    crop = far[CY0:CY1, CX0:CX1].copy()
    H, W = crop.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    X, Y = xx + CX0, yy + CY0
    m = {}
    m["body"] = (X >= X0) & (X < X1) & (Y >= BODY[0]) & (Y < BODY[1])
    m["end_caps"] = m["body"] & ((X < X0 + 2) | (X >= X1 - 2))
    m["diffuser"] = (X >= X0 + 1) & (X < X1 - 1) & (Y >= DIFF[0]) & (Y < DIFF[1])
    rods = np.zeros((H, W), bool)
    can = np.zeros((H, W), bool)
    for hx in HANGERS:
        rods |= (X >= hx) & (X < hx + 2) & (Y >= CANOPY_Y[1]) & (Y < BODY[0])
        can |= (X >= hx - 2) & (X < hx + 4) & (Y >= CANOPY_Y[0]) & (Y < CANOPY_Y[1])
    m["hanger_rods"] = rods
    m["canopies"] = can
    old = ((X >= OLD_BAR[0]) & (X < OLD_BAR[1]) & (Y >= OLD_BAR[2]) & (Y < OLD_BAR[3]))
    # the old hangers (and the right one's chain, which ran on below the fitting) to the wall
    rod_zone = (((X >= OLD_RODS[0]) & (X < OLD_RODS[1])) & (Y >= 192) & (Y < 233)) | (((X >= OLD_RODS[2]) & (X < OLD_RODS[3])) & (Y >= 192) & (Y < 250))
    old |= rod_zone
    new = m["body"] | m["diffuser"] | rods | can
    feed = (X >= 1263) & (X < 1268)   # the feed conduit stays as painted
    m["inpaint"] = old & ~new & ~feed
    # where the old bar crossed the feed conduit, the conduit runs on (its own pixels from just above)
    m["feed_run"] = old & feed & ~new & (Y >= OLD_BAR[2]) & (Y < OLD_BAR[3])
    # deterministic inpaint: bar rows from the wall 9 rows above, rods from the wall 3 px either side
    flat = crop.copy()
    from scipy import ndimage
    # rods first: from the wall 5 px either side
    rr = m["inpaint"] & rod_zone
    # across each rod zone: a linear blend between the wall columns just outside it, with the
    # concrete's grain from the wall 16 px to the left (clear of every rod)
    sm = ndimage.uniform_filter(crop, size=(5, 5, 1))
    g0 = crop - sm
    for zx0, zx1 in ((OLD_RODS[0], OLD_RODS[1]), (OLD_RODS[2], OLD_RODS[3])):
        a0, a1 = zx0 - 1 - CX0, zx1 - CX0
        zone = rr & (X >= zx0) & (X < zx1)
        f = (xx[zone] - a0) / float(a1 - a0)
        smooth_interp = sm[yy[zone], a0] * (1 - f)[:, None] + sm[yy[zone], a1] * f[:, None]
        flat[zone] = smooth_interp + g0[yy[zone], np.clip(xx[zone] - 16, 0, W - 1)]
    base = flat.copy()
    # bar rows: per column, a linear blend between the wall row just above and just below the old
    # fitting (rods already gone), with the concrete's grain (high-pass) from the wall 19 rows higher
    bar = m["inpaint"] & (Y >= OLD_BAR[2]) & (Y < OLD_BAR[3]) & (X >= OLD_BAR[0]) & (X < OLD_BAR[1])
    ya, yb = OLD_BAR[2] - 1 - CY0, OLD_BAR[3] - CY0
    f = np.clip((yy - ya) / float(yb - ya), 0, 1)[..., None]
    lin = base[ya][None, :, :] * (1 - f) + base[yb][None, :, :] * f
    grain = base - ndimage.uniform_filter(base, size=(5, 5, 1))
    src_y = np.clip(yy - 19, 0, H - 1)
    flat[bar] = lin[bar] + grain[src_y[bar], xx[bar]]
    fr = m["feed_run"]
    flat[fr] = crop[OLD_BAR[2] - 3 - CY0, xx[fr]]
    m["inpaint"] = m["inpaint"] | fr
    # the construction, flat
    flat[m["body"]] = [62, 72, 80]
    flat[m["body"] & (Y == BODY[0])] = [88, 100, 110]          # top edge catches the corridor's bounce
    flat[m["end_caps"]] = [44, 50, 56]
    t = np.clip(1 - np.abs((X + 0.5) - (X0 + X1) / 2) / ((X1 - X0) / 2), 0, 1)
    dif = np.stack([150 + 70 * t, 200 + 45 * t, 212 + 38 * t], -1)
    flat[m["diffuser"]] = dif[m["diffuser"]]
    flat[m["hanger_rods"]] = [52, 62, 70]
    flat[m["hanger_rods"] & (X == np.array(HANGERS)[np.newaxis, np.newaxis].min())] = [52, 62, 70]
    flat[m["canopies"]] = [40, 48, 54]
    Image.fromarray(np.clip(flat, 0, 255).round().astype(np.uint8)).save(os.path.join(OUT, "flat.png"))
    Image.fromarray(np.clip(crop, 0, 255).round().astype(np.uint8)).save(os.path.join(OUT, "crop-round6.png"))
    for n, mk in m.items():
        Image.fromarray((mk * 255).astype(np.uint8)).save(os.path.join(OUT, "masks", f"{n}.png"))
    spec = {"crop_plate": [CX0, CY0, CX1, CY1], "fitting_plate_x": [X0, X1], "length_m": (X1 - X0) / 80.0, "body_y": BODY, "diffuser_y": DIFF,
            "hangers_x": HANGERS, "canopy_y": CANOPY_Y, "old_bar": OLD_BAR, "old_rods_x": OLD_RODS,
            "real": "0.6 m (2 ft) vapour-tight LED batten: polycarbonate body, opal diffuser, end caps, suspended on two rods from the tray"}
    json.dump(spec, open(os.path.join(OUT, "spec.json"), "w"), indent=1)
    print(json.dumps(spec))


if __name__ == "__main__":
    main()
