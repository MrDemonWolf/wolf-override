"""Fix round 2 (v3): builds the game-ready files from layers/v3 and copies them into game-slice.

- corridor-mid.png: main's mid plate with the old pipe column and hazard pump erased (as v1/v2), the
  v3 cross-wall's wall layer (everything behind the walk line, with the doorway transparent, the
  wall-mounted bypass and its shadow) AND the whole near pier with its cut section (the front layer)
  under the ceiling rack, plus the stations' footprint contact shadows, all at 2 px per world px.
- corridor-far.png: layers/v3/corridor-far.png (the plant room at the actors' values, the tank's head
  lit from its lamp, the beacon mount back under main's beacon, the plant room's near slab, grain).
- corridor-seal-atlas.png: ONE lossless atlas for every door-end sprite (review: draw calls), with
  each piece's region in placement.json:
    curtain   the closed curtain (DoorArt and SealLeaf's art), 4 px per world px
    open      the bottom bar tucked under the hood (CorridorDoorOpen), 4 px
    frame     far guide, hood, operator (over the curtain, under the actors), 4 px
    front     the near pier top to foot with its cut section, near guide, lamp socket and guard,
              push buttons and camera (over the actors), cut from the same pixels as the mid plate at
              2 px per world px, so its edges match the plate (no pasted rectangle); clear where the
              hood is in front of it
    lens      the lamp's glass (tinted live), 4 px
    wheel     the handwheel, centred on its hub, 4 px
Writes layers/v3/game/ and placement.json, then copies into game-slice/apps/game/assets.
"""
from __future__ import annotations

import json
import os
import shutil

import numpy as np
from PIL import Image

from install2 import load, over, down2, trim, save, station_shadow

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
L = os.path.join(R, "layers", "v3")
OUT = os.path.join(L, "game")
GS = os.path.join(R, "game-slice", "apps", "game", "assets")
GM = os.path.join(R, "game-main", "apps", "game", "assets")
MID_TOP = 51.5
CVD_X0, CVD_Y0 = 676.0, 150.0
CV2_X0, CV2_Y0 = 680.0, 150.0
ATLAS = (1024, 1024)


def place_on(canvas_shape, img, x, y):
    """img (RGBA float) pasted into a transparent canvas at integer (x, y), cropped to the canvas."""
    out = np.zeros(canvas_shape)
    h, w = img.shape[:2]
    H, W = canvas_shape[:2]
    x0, y0 = max(x, 0), max(y, 0)
    x1, y1 = min(x + w, W), min(y + h, H)
    out[y0:y1, x0:x1] = img[y0 - y:y1 - y, x0 - x:x1 - x]
    return out


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    place: dict = {}
    mid0 = load(os.path.join(GM, "rooms", "corridor-mid.png"))
    mid = mid0.copy()
    mid[200:, 1400:, 3] = 0.0  # the old pipe column and pump (as v1, v2)
    wall = load(os.path.join(L, "portal-wall.png"))
    front = load(os.path.join(L, "portal-front.png"))
    frame2 = load(os.path.join(L, "portal-frame.png"))
    # the hood (frame layer, v2 canvas) is in front of the near pier: the front sprite is clear under it
    frame_on_cvd = np.zeros_like(front)
    frame_on_cvd[:frame2.shape[0], 16:16 + frame2.shape[1]] = frame2
    front_sprite = front.copy()
    front_sprite[..., 3] *= 1.0 - np.clip(frame_on_cvd[..., 3] * 1.5, 0, 1)
    # the plate: wall, then the whole front (pier and cut), then main's plate (the ceiling rack) over
    stack = wall.copy()
    over(stack, front, 0, 0)
    small = down2(stack)
    fx, fy = int(CVD_X0 * 2), int(round((CVD_Y0 - MID_TOP) * 2))
    base = place_on(mid.shape, small, fx, fy)
    over(base, mid, 0, 0)
    mid = base
    spec = json.load(open(os.path.join(R, "design", "stations", "spec.json")))
    shadows = {}
    for name, s in spec.items():
        x0p, _, x1p, _ = s["plinth_px"]
        wx0 = s["centre_world_x"] + (x0p - s["sprite_centre_px_x"]) / 4.0
        wx1 = s["centre_world_x"] + (x1p - s["sprite_centre_px_x"]) / 4.0
        sh = station_shadow(wx0, wx1)
        over(mid, sh, int(round((wx0 - 4) * 2)), int(round((440 - MID_TOP) * 2)))
        shadows[name] = [round(wx0, 2), round(wx1, 2)]
    save(mid, os.path.join(OUT, "corridor-mid.png"))
    shutil.copy(os.path.join(L, "corridor-far.png"), os.path.join(OUT, "corridor-far.png"))
    # the front sprite: the front layer's own colour at 2 px per world px (where it is opaque the plate
    # under it holds the same pixels), with the main plate's rack over it where the rack is in front
    fs = down2(front_sprite)
    rack = place_on(fs.shape, mid0[:, :, :], -fx, -fy)  # main's plate on the same 2 px grid
    rack_a = rack[..., 3].copy()
    rack_a[(np.arange(fs.shape[0]) + fy) >= 200, :] = 0.0  # only the ceiling band of main's plate (as cleared above)
    fs_rgb = fs[..., :3] * (1 - rack_a[..., None]) + rack[..., :3] * rack_a[..., None]
    fs = np.dstack([fs_rgb, fs[..., 3]])
    fs, (fx0, fy0, fx1, fy1) = trim(fs)
    pieces = {
        "curtain": (load(os.path.join(L, "portal-curtain.png")), 4.0, (CV2_X0, CV2_Y0)),
        "open": (load(os.path.join(L, "portal-curtain-open.png")), 4.0, (CV2_X0, CV2_Y0)),
        "frame": (frame2, 4.0, (CV2_X0, CV2_Y0)),
    }
    trimmed = {}
    for key, (img, ppw, (cx, cy)) in pieces.items():
        t, (x0, y0, x1, y1) = trim(img)
        trimmed[key] = (t, ppw, [cx + x0 / ppw, cy + y0 / ppw])
    trimmed["front"] = (fs, 2.0, [CVD_X0 + (fx0) / 2.0, CVD_Y0 + (fy0) / 2.0])
    trimmed["lens"] = (load(os.path.join(L, "lens.png")), 4.0, None)
    trimmed["wheel"] = (load(os.path.join(L, "bypass-wheel.png")), 4.0, None)
    # shelf-pack: front (tall) on the left, then the rest in columns
    layout = {"front": (2, 2)}
    fw = trimmed["front"][0].shape[1]
    x = fw + 6
    layout["curtain"] = (x, 2)
    layout["open"] = (x, 2 + trimmed["curtain"][0].shape[0] + 4)
    x2 = x + max(trimmed["curtain"][0].shape[1], trimmed["open"][0].shape[1]) + 4
    layout["frame"] = (x2, 2)
    layout["wheel"] = (x2, 2 + trimmed["frame"][0].shape[0] + 4)
    layout["lens"] = (x2 + trimmed["wheel"][0].shape[1] + 4, 2 + trimmed["frame"][0].shape[0] + 4)
    atlas = np.zeros((ATLAS[1], ATLAS[0], 4))
    regions = {}
    for key, (img, ppw, tl) in trimmed.items():
        ax, ay = layout[key]
        h, w = img.shape[:2]
        assert ax + w <= ATLAS[0] and ay + h <= ATLAS[1], (key, ax, ay, w, h)
        atlas[ay:ay + h, ax:ax + w] = img
        regions[key] = {"region": [ax, ay, w, h], "scale": 1.0 / ppw}
        if tl is not None:
            regions[key]["world_top_left"] = [round(tl[0], 4), round(tl[1], 4)]
    save(atlas, os.path.join(OUT, "corridor-seal-atlas.png"))
    place["atlas"] = regions
    place["wheel_centre_world"] = [695.0, 398.0]
    place["station_contact_shadows_world_x"] = shadows
    place["front_sprite_world_rect"] = [regions["front"]["world_top_left"], [fs.shape[1] / 2.0, fs.shape[0] / 2.0]]
    json.dump(place, open(os.path.join(OUT, "placement.json"), "w"), indent=1)
    for f in ("corridor-far.png", "corridor-mid.png"):
        shutil.copy(os.path.join(OUT, f), os.path.join(GS, "rooms", f))
    shutil.copy(os.path.join(OUT, "corridor-seal-atlas.png"), os.path.join(GS, "props", "corridor-seal-atlas.png"))
    print(json.dumps(place, indent=1))


if __name__ == "__main__":
    main()
