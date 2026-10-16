"""Relief discharge, round 8 (add7 fix round 1, item g): the relief valve's tailpipe is carried DOWN
the relay's side to a safe point 0.42 m above the floor (real practice: discharge piped downward to
a safe point, supported, terminating where it is visible), so the coolant no longer vents at the
engineer's head height 0.6 m from where they crank.

Construction on the relay art (368x408, 0.25 world px per art px, about 6 mm per art px):
  union         y 92..96, x 347..358   a union where the drop is joined to round 7's tailpipe
  drop          y 96..336, x 348..357  the same 40 mm discharge pipe (round 7's own pixel profile)
  clamps        y 188..191 and 282..285 round the drop, each with a bracket bar to the coolant
                pipe's flange side (x 331..347), 2 px, bolted
  open end      y 333..336             the cut end, its bore dark
  damp patch    an ellipse on the floor at the relay's foot under the outlet, (352, 404) rx 15 ry 3
Writes plume8/design/: flat.png (the relay with the construction drawn flat), masks/*.png, spec.json.
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "design"))
RELAY = "scratchpad/real-slice/add7/plume/layer/corridor-coolant-relay.png"
X0, X1 = 348, 358
DROP = (96, 336)
UNION = (92, 97)
CLAMPS = (188, 282)
END = 336
PATCH = (352.0, 404.0, 15.0, 3.0)
OUTLET_ART = (352.5, 337.0)


def main():
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    a = np.asarray(Image.open(RELAY).convert("RGBA")).astype(float)
    H, W = a.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    m = {}
    m["drop"] = (xx >= X0) & (xx < X1) & (yy >= DROP[0]) & (yy < DROP[1])
    m["union"] = (xx >= X0 - 1) & (xx < X1 + 1) & (yy >= UNION[0]) & (yy < UNION[1])
    cl = np.zeros((H, W), bool)
    br = np.zeros((H, W), bool)
    for c in CLAMPS:
        cl |= (xx >= X0 - 1) & (xx < X1 + 1) & (yy >= c) & (yy < c + 4)
        br |= (xx >= 331) & (xx < X0 - 1) & (yy >= c) & (yy < c + 4)
    m["clamps"] = cl
    m["brackets"] = br & (a[..., 3] < 128)   # only where the coolant pipe is not already in front
    m["end"] = (xx >= X0) & (xx < X1) & (yy >= END - 3) & (yy < END)
    px, py, rx, ry = PATCH
    m["damp"] = (((xx + 0.5 - px) / rx) ** 2 + ((yy + 0.5 - py) / ry) ** 2) <= 1.0
    # flat construction: the drop takes round 7's tailpipe profile (row 86, x 348..357), darkening
    # gently downward as the relay's own pipes do; union and clamps steel; damp patch dark
    prof = a[86, X0:X1, :3]
    flat = a.copy()
    for y in range(DROP[0], DROP[1]):
        k = 1.0 - 0.25 * (y - DROP[0]) / (DROP[1] - DROP[0])
        flat[y, X0:X1, :3] = prof * k
        flat[y, X0:X1, 3] = np.where(np.arange(X0, X1) == X0, 140, 255)
    steel = np.array([70, 82, 96], float)
    for name in ("union", "clamps", "brackets"):
        flat[m[name], :3] = steel
        flat[m[name], 3] = 255
    flat[m["end"], :3] = flat[m["end"], :3] * 0.55
    dm = m["damp"] & (a[..., 3] < 10)
    flat[dm, :3] = [12, 16, 20]
    flat[dm, 3] = 110
    Image.fromarray(flat.round().astype(np.uint8), "RGBA").save(os.path.join(OUT, "flat.png"))
    for n, mk in m.items():
        Image.fromarray((mk * 255).astype(np.uint8)).save(os.path.join(OUT, "masks", f"{n}.png"))
    world = (561.625 + OUTLET_ART[0] * 0.25, 338.0 + OUTLET_ART[1] * 0.25)
    spec = {"art_px_m": 0.006, "outlet_art": OUTLET_ART, "outlet_world": [round(world[0], 3), round(world[1], 3)],
            "outlet_height_m": round((440.0 - world[1]) / 40.0, 3), "drop_art_y": DROP, "clamps_art_y": CLAMPS, "damp_patch": PATCH,
            "basis": "Apollo safety relief valve tag I352500: discharge directed downward to a safe point of discharge, terminating "
                     "freely to atmosphere where any discharge is clearly visible; Emerson Kunkle KUKDR-0001: discharge piping other "
                     "than a short tailpipe must be supported (round 7's plume NOTES sources)."}
    json.dump(spec, open(os.path.join(OUT, "spec.json"), "w"), indent=1)
    print(json.dumps(spec, indent=1))


if __name__ == "__main__":
    main()
