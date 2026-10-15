"""Round 8 base layers: round 7's painted wall and front layers with round 7's blast-frame plates,
their bolts and bolt shadows, the wiper seals and the parked leaf edge taken back to round 6's
pixels (everything round 7 added that round 8 redraws). The sign, its stencil, the rail and the
second strap stay round 7's, byte for byte. Also writes the union of the new parts (NEW masks).

Writes add7/fix1/door/layers/base-wall.png, base-front.png, base-report.json.
"""
from __future__ import annotations

import json
import os
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
RS = "scratchpad/real-slice"
V6 = os.path.join(RS, "layers", "v6")
R7L = os.path.join(RS, "add7", "door", "layers")
R7M = os.path.join(RS, "add7", "door", "design", "masks")
OUT = os.path.join(ROOT, "layers")

R7_WALL_REDRAWN = ("bf_jamb_plate", "bf_head_plate", "bf_jamb_seam0", "bf_jamb_seam1", "bf_head_seam0", "bf_head_seam1", "bf_bolts",
                   "slot_seal_front", "slot_seal_back", "leaf_edge_parked")
R7_FRONT_REDRAWN = ("bf_near_head", "bf_near_bolts")


def m7(name):
    return np.asarray(Image.open(os.path.join(R7M, name)).convert("L")) > 0


def main():
    os.makedirs(OUT, exist_ok=True)
    rep = {}
    for layer, names in (("wall", R7_WALL_REDRAWN), ("front", R7_FRONT_REDRAWN)):
        r7 = np.asarray(Image.open(os.path.join(R7L, f"portal-{layer}.png")).convert("RGBA")).copy()
        v6 = np.asarray(Image.open(os.path.join(V6, f"portal-{layer}.png")).convert("RGBA"))
        zone = np.zeros(r7.shape[:2], bool)
        for n in names:
            zone |= m7(f"{layer}--{n}.png")
        # bolt shadows were shifted (2, -1) under the bolts: widen the zone by 3 px
        zone = ndimage.binary_dilation(zone, iterations=3)
        if layer == "wall":
            # keep round 7's sign, its bolts, its stand-off shadow, the stencil and the rail exactly
            keep = np.zeros_like(zone)
            for n in ("sign_plate", "sign_bolts", "TEXT-sign", "rail_recess", "rail_head"):
                keep |= ndimage.binary_dilation(m7(f"wall--{n}.png"), iterations=4 if n == "sign_plate" else 1)
            zone &= ~keep
        else:
            zone &= ~ndimage.binary_dilation(m7("front--lamp_conduit_strap2.png"), iterations=1)
        out = r7.copy()
        out[zone] = v6[zone]
        Image.fromarray(out, "RGBA").save(os.path.join(OUT, f"base-{layer}.png"))
        diff7 = np.abs(r7.astype(int) - v6.astype(int)).max(-1) > 0
        left = np.abs(out.astype(int) - v6.astype(int)).max(-1) > 0
        rep[layer] = {"reverted_px": int((zone & diff7).sum()), "round7_px_kept": int(left.sum()), "round7_px_total": int(diff7.sum())}
    json.dump(rep, open(os.path.join(OUT, "base-report.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
