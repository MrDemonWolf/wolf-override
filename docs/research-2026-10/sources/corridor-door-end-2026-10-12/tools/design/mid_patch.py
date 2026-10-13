"""Mid-plate patch for the door end (the play plane, 1:1 with the room, 2 source px per world px).

- Erases the mid plate below the ceiling rack right of world x 700 (source x >= 1400, rows >= 200):
  the old pipe column (now inside the cast bulkhead, and it would show through the doorway) and the
  old pump with its hazard-striped skid (it stood where the machinery room now is).
- Adds the coolant relay's feed: two 25 mm rigid conduits dropping from the ceiling rack to the
  relay's roof gland plate (ANATOMY C: cables come down through the roof gland plate from a tray),
  with a strut clamp at the rack and a coupling every 3 m. Shaded as cylinders lit from above, in the
  rack's own steel values (sampled from the plate), so they need no painting at 1.2 world px wide.
Writes design/mid-patch/.
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
GAME = os.path.abspath(os.path.join(ROOT, "..", "game-main", "apps", "game"))
OUT = os.path.join(ROOT, "mid-patch")
MID_TOP = 51.5  # world y of the mid plate's top row (440 - 777 * 0.5)
ERASE_X = 1400
ERASE_ROW = 200
CONDUIT_X_WORLD = (573.0, 578.0)
CONDUIT_TOP_WORLD = 146.0
CONDUIT_BOTTOM_WORLD = 347.0  # hidden under the relay's roof edge (roof ~ y 345)
R_SRC = 1.2  # conduit radius in source px (25 mm EMT = 1.2 world px across)


def src_y(world_y: float) -> float:
    return (world_y - MID_TOP) * 2.0


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    mid = np.asarray(Image.open(os.path.join(GAME, "assets/rooms/corridor-mid.png")).convert("RGBA")).astype(np.float64)
    out = mid.copy()
    erase = np.zeros(mid.shape[:2])
    erase[ERASE_ROW:, ERASE_X:] = 1.0
    out[..., 3] *= (1 - erase)
    out[erase > 0, :3] = 0
    # sample the rack's steel: median of opaque rack pixels, and its light top value
    rack = mid[100:190, 1000:1400]
    opaque = rack[..., 3] > 250
    lum = rack[..., :3].mean(-1)
    dark = np.median(rack[opaque][:, :3], axis=0)
    light = np.percentile(rack[opaque][:, :3], 92, axis=0)
    H, W = mid.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
    cond = np.zeros((H, W))
    y0, y1 = src_y(CONDUIT_TOP_WORLD), src_y(CONDUIT_BOTTOM_WORLD)
    for xw in CONDUIT_X_WORLD:
        cx = xw * 2.0
        t = (xx + 0.5 - cx) / R_SRC
        inside = (np.abs(t) <= 1.0) & (yy >= y0) & (yy <= y1)
        cov = np.clip(1.0 + R_SRC - np.abs(xx + 0.5 - cx), 0, 1) * ((yy >= y0) & (yy <= y1))
        shade = np.clip(0.55 - 0.45 * t, 0, 1)  # lit from the upper left (the corridor luminaire)
        col = dark[None, None, :] * (1 - shade[..., None]) + light[None, None, :] * shade[..., None]
        m = cov
        out[..., :3] = out[..., :3] * (1 - m[..., None]) + col * m[..., None]
        out[..., 3] = np.maximum(out[..., 3], m * 255)
        cond = np.maximum(cond, m)
    # strut clamp at the rack and couplings every 3 m (120 world px = 240 source px)
    def band(yw, h_src, w_src):
        ys = src_y(yw)
        x0 = CONDUIT_X_WORLD[0] * 2 - w_src
        x1 = CONDUIT_X_WORLD[1] * 2 + w_src
        return (yy >= ys) & (yy < ys + h_src) & (xx >= x0) & (xx < x1)
    clamp = band(CONDUIT_TOP_WORLD + 1.0, 5, 4)
    out[clamp, :3] = dark * 0.9
    out[clamp, 3] = 255
    for yw in (CONDUIT_TOP_WORLD + 120.0,):
        for xw in CONDUIT_X_WORLD:
            c = (yy >= src_y(yw)) & (yy < src_y(yw) + 3) & (np.abs(xx + 0.5 - xw * 2) <= R_SRC + 0.6)
            out[c, :3] = light * 0.9
            out[c, 3] = 255
            cond = np.maximum(cond, c)
    cond = np.maximum(cond, clamp)
    img = Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8), "RGBA")
    img.save(os.path.join(OUT, "corridor-mid-patched.png"))
    Image.fromarray((erase * 255).astype(np.uint8)).save(os.path.join(OUT, "masks", "erased.png"))
    Image.fromarray((cond * 255).astype(np.uint8)).save(os.path.join(OUT, "masks", "relay_conduits.png"))
    bg = Image.new("RGBA", img.size, (255, 0, 255, 255))
    bg.alpha_composite(img)
    bg.convert("RGB").resize((960, 540)).save(os.path.join(OUT, "preview-on-magenta.png"))
    print("mid patch written; rack steel", dark.round(1), light.round(1))


if __name__ == "__main__":
    main()
