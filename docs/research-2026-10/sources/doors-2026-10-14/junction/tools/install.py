"""Packs the cleaned junction blast-door layers into ONE lossless atlas and writes placement.json and
the generated GDScript layout (scratch only).

Pieces and their scale in the game (world px per atlas px):
  door/leaf pieces drawn small (leaf, leafbreak, lens): 4 atlas px per world px (scale 0.25)
  wall, column, stub, alcove, hole, damage, cracks, lying: 2 atlas px per world px (scale 0.5)
Each piece is cropped to its opaque bounds on an even grid of the 4 px design canvas, resampled with
premultiplied alpha, and packed with 2 px of clear padding.

Writes layers/final/junction-door-atlas.png, layers/final/placement.json,
layers/final/junction_door_layout.gd and layers/final/<piece>.png (each piece alone, for review).
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import jmodel as M  # noqa: E402

L = os.path.join(M.WORK, "layers", "graded")  # fix round 1: the graded layers (jgrade.py)
OUT = os.path.join(M.WORK, "layers", "final")
DM = os.path.join(M.WORK, "design", "masks")

# piece: (source layer, set, ppw, part filter (None = whole layer), node, states, z relative to JunctionRoom, job)
COLUMN_PARTS = ("col_", "lamp_", "jb_", "light_feed_end", "riser")
PIECES = [
    ("hole", "hole", "blown", 2, None, "DoorHole", ["blown"], -3, "the empty doorway: far jamb liner with torn bolt keepers, buckled threshold, back rubble (under the actors)"),
    ("leaf", "leaf", "sealed", 4, None, "DoorLeaf", ["sealed"], -3, "the shut leaf in the opening (under the wall, so the frame laps it)"),
    ("leafbreak", "leafbreak", "blown", 4, None, "DoorLeafBreaking", ["breaking"], -3, "the leaf at the instant of failure, 0.15 s"),
    ("wall", "wall", "sealed", 2, None, "DoorWall", ["sealed", "breaking", "blown"], -3, "the cross-wall behind the walk line, doorway at alpha 0"),
    ("cracks", "cracks", "blown", 2, None, "DoorCracks", ["breaking"], -3, "cracks running from the frame, 0.15 s"),
    ("damage", "damage", "blown", 2, None, "DoorDamage", ["blown"], -3, "spall, exposed rebar, peeled latch flange, sagging head, soot"),
    ("alcove", "alcove", "sealed", 2, None, "ReleaseBay", ["sealed", "breaking", "blown"], -2, "the TANK RELEASE bay: recess, header, two posts on base plates, its fitting"),
    ("column", "front", "sealed", 2, "column", "DoorColumn", ["sealed", "breaking", "blown"], 2, "the near column over the actors: frame flange, armoured end, status lamp socket, junction box, conduit"),
    # fix round 2 (N4): the near column as the blast left it; the same DoorColumn sprite shows this region once blown
    ("colblown", "frontblown", "blown", 2, "colblown", "DoorColumn", ["blown"], 2, "the near column after the blast: torn hinges and sheared pins, the spalled hinge-jamb corner with its bars, the arris angle torn loose, soot"),
    ("stub", "front", "sealed", 2, "stub", "DoorStub", ["sealed", "breaking", "blown"], 2, "the wall's 0.15 m stub across the deck, over the actors"),
    ("lying", "lying", "blown", 2, None, "DoorLeafDown", ["blown"], 2, "the thrown leaf lying on the lane deck, the front rubble and the dust film (over the actors)"),
]


def load(layer, sset):
    im = np.asarray(Image.open(os.path.join(L, sset, f"{layer}.png")).convert("RGBA")).astype(np.float64) / 255.0
    return im


def part_union(layer, prefixes):
    u = None
    for f in os.listdir(DM):
        if f.startswith(f"{layer}--"):
            n = f[len(layer) + 2:-4]
            if any(n.startswith(p) for p in prefixes):
                m = np.asarray(Image.open(os.path.join(DM, f))).astype(np.float64) / 255.0
                u = m if u is None else np.maximum(u, m)
    return u


def resample(rgba, factor):
    """Premultiplied-alpha downscale by an integer factor (box filter: exact coverage)."""
    if factor == 1:
        return rgba
    h, w = rgba.shape[:2]
    a = rgba[..., 3:4]
    pm = np.concatenate([rgba[..., :3] * a, a], -1)
    pm = pm[: h // factor * factor, : w // factor * factor].reshape(h // factor, factor, w // factor, factor, 4).mean((1, 3))
    out = pm.copy()
    al = pm[..., 3:4]
    out[..., :3] = np.where(al > 1e-6, pm[..., :3] / np.maximum(al, 1e-6), 0)
    return out


def lens_texture():
    """The status lamp's glass: a shaded neutral globe (white, the game tints it), 4 px per world px
    for a 4 x 5 world px globe."""
    w, h = 18, 22
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    cx, cy, rx, ry = (w - 1) / 2, (h - 1) / 2, w / 2 - 0.5, h / 2 - 0.5
    d = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
    a = np.clip((1.0 - d) * 5.0, 0, 1)
    v = np.clip(0.8 + 0.2 * (1 - d ** 2) + 0.3 * np.exp(-(((xx - cx + 2.5) / 2.0) ** 2 + ((yy - cy + 3.5) / 2.6) ** 2)) - 0.3 * np.clip((d - 0.7) / 0.3, 0, 1), 0, 1)
    return np.dstack([v, v, v, a])


# Review round 2 (render.sh frames): the cross-wall's and column's upper faces read 1.6x brighter than
# the approved corridor wall (sRGB ~ (40, 51, 57) against (24, 30, 34)), a flat pale slab against the
# dark room. Above the door light nothing lights them but the room's far lamps, so their value falls
# off with height: x1.0 up to the door light's bracket (world y 345), easing to x0.6 above y 250.
# fix round 1: the room-relative grade (jgrade.py, ../../tools/grade.py) replaces this fall-off.
FALLOFF_PIECES = ()
FALLOFF_TOP_Y, FALLOFF_BOTTOM_Y, FALLOFF_MIN = 250.0, 345.0, 0.6


def upper_falloff(rows: int) -> np.ndarray:
    y = M.CV.y0 + (np.arange(rows) + 0.5) / M.CV.ppw
    u = np.clip((y - FALLOFF_TOP_Y) / (FALLOFF_BOTTOM_Y - FALLOFF_TOP_Y), 0.0, 1.0)
    u = u * u * (3.0 - 2.0 * u)
    return FALLOFF_MIN + (1.0 - FALLOFF_MIN) * u


def main():
    os.makedirs(OUT, exist_ok=True)
    spec = json.load(open(os.path.join(M.WORK, "design", "spec.json")))
    pieces = []
    col_sel = part_union("front", COLUMN_PARTS) > 0.002
    colb_sel = part_union("frontblown", COLUMN_PARTS) > 0.002
    for (pname, layer, sset, ppw, filt, node, states, z, job) in PIECES:
        im = load(layer, sset)
        if filt == "stub":
            im = im.copy()
            im[..., 3] *= ~col_sel
        elif filt == "column":
            im = im.copy()
            im[..., 3] *= col_sel
        elif filt == "colblown":
            im = im.copy()
            # fix round 2: the parts the blast leaves alone (the status lamp and its guard, the junction box,
            # the conduit feed, the riser) are the sealed column's own pixels, so one fitting never turns
            # into another between the two states; only the col_* parts (torn hinges, spall, bars, the
            # arris angle, soot) come from the blown painting
            keep_sealed = part_union("front", ("lamp_", "jb_", "light_feed_end", "riser"))
            if keep_sealed is not None:
                sealed = load("front", "sealed")
                ks = (keep_sealed > 0.002)[..., None]
                im = np.where(ks, sealed, im)
            im[..., 3] *= colb_sel
        im = im.copy()
        if pname in FALLOFF_PIECES:
            im[..., :3] *= upper_falloff(im.shape[0])[:, None, None]
        im[..., 3] = np.where(im[..., 3] < 0.01, 0.0, im[..., 3])  # the far tail of a contact shadow
        ys, xs = np.nonzero(im[..., 3] > 0.0)
        f = int(4 // ppw)
        x0 = (xs.min() // 4) * 4
        y0 = (ys.min() // 4) * 4
        x1 = -(-(xs.max() + 1) // 4) * 4
        y1 = -(-(ys.max() + 1) // 4) * 4
        crop = resample(im[y0:y1, x0:x1], f)
        pieces.append({"piece": pname, "node": node, "states": states, "z": z, "job": job, "scale": 1.0 / ppw,
                       "world_top_left": [M.CV.x0 + x0 / 4.0, M.CV.y0 + y0 / 4.0], "world_size": [(x1 - x0) / 4.0, (y1 - y0) / 4.0], "img": crop})
    gx, gy = spec["lamp_glass_centre"]
    lens = lens_texture()
    pieces.append({"piece": "lens", "node": "DoorLampLens", "states": ["sealed", "breaking", "blown"], "z": 2, "scale": 0.25,
                   "job": "the status lamp's glass, tinted live: red shut, amber while the line builds, flashing through the fuse, dark once blown",
                   "world_top_left": [gx - lens.shape[1] / 8.0, gy - lens.shape[0] / 8.0], "world_size": [lens.shape[1] / 4.0, lens.shape[0] / 4.0], "img": lens})
    # fix round 3: skyline (bottom-left) packing, tallest first, 1024 wide, 2 px padding: each piece goes
    # where its top is lowest, so short pieces fill the space under shorter neighbours on a shelf (the
    # wider thrown leaf, review r3 S3, then fits without growing the atlas)
    W, PAD = 1024, 2
    order = sorted(range(len(pieces)), key=lambda i: -pieces[i]["img"].shape[0])
    sky = np.full(W, PAD)
    for i in order:
        h, w = pieces[i]["img"].shape[:2]
        best = None
        for x in range(PAD, W - w - PAD + 1, 2):
            y = int(sky[x - PAD:x + w + PAD].max()) if x >= PAD else int(sky[:x + w + PAD].max())
            if best is None or y < best[1] or (y == best[1] and x < best[0]):
                best = (x, y)
        x, y = best
        pieces[i]["region"] = [x, y, w, h]
        sky[x:x + w] = y + h + PAD
    H = int(sky.max())
    Hp = -(-H // 4) * 4  # fix round 1: the used height (multiple of 4), not the next power-of-two step
    atlas = np.zeros((Hp, W, 4))
    for p in pieces:
        x, y, w, h = p["region"]
        atlas[y:y + h, x:x + w] = p["img"]
        Image.fromarray((np.clip(p["img"], 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, f"{p['piece']}.png"))
    a8 = (np.clip(atlas, 0, 1) * 255 + 0.5).astype(np.uint8)
    a8[a8[..., 3] == 0, :3] = 0
    Image.fromarray(a8, "RGBA").save(os.path.join(OUT, "junction-door-atlas.png"), optimize=True)
    place = {"atlas": "res://assets/props/junction-door-atlas.png", "atlas_size": [W, Hp],
             "import": "lossless (compress/mode=0), mipmaps on, filter linear with mipmaps: as corridor-seal-atlas.png",
             "parent": "JunctionRoom (z 1); z below is relative to it (props are -1, actors 2 absolute = 1 relative)",
             "draw_order": [p["node"] for p in pieces if p["piece"] not in ("lens", "colblown")][:7] + ["(Recesses, then ReleaseBay)", "(props, room drawing, actors)", "DoorLampLens", "DoorColumn", "DoorStub", "DoorLeafDown"],
             "pieces": [{k: (v if k != "img" else None) for k, v in p.items() if k != "img"} for p in pieces],
             "lamp_glass_centre": spec["lamp_glass_centre"], "camera": spec["camera"], "model": spec["model"], "screen": spec["screen"]}
    for p in place["pieces"]:
        p["world_top_left"] = [round(v, 3) for v in p["world_top_left"]]
    json.dump(place, open(os.path.join(OUT, "placement.json"), "w"), indent=1)
    # generated GDScript layout
    lines = ["class_name JunctionDoorLayout", "## GENERATED by the junction blast-door install tool (doors-r1/junction/tools/install.py) from",
             "## placement.json: atlas regions, world top-left corners and scales of every piece. Do not edit by hand.", "",
             'const ATLAS: Texture2D = preload("res://assets/props/junction-door-atlas.png")']
    for p in pieces:
        n = p["piece"].upper()
        x, y, w, h = p["region"]
        tx, ty = p["world_top_left"]
        lines.append(f"const {n}_REGION: Rect2 = Rect2({x}.0, {y}.0, {w}.0, {h}.0)")
        lines.append(f"const {n}_AT: Vector2 = Vector2({tx:.3f}, {ty:.3f})")
        lines.append(f"const {n}_SCALE: float = {p['scale']}")
    lines.append(f"const LAMP_CENTRE: Vector2 = Vector2({gx:.3f}, {gy:.3f})")
    fx, fy = spec["screen"]["far_jamb_foot"]
    nx, ny = spec["screen"]["near_jamb_foot"]
    lines.append("## The doorway's jamb feet on the deck (the far one behind the walk line, the near one in front).")
    lines.append(f"const FAR_JAMB_FOOT: Vector2 = Vector2({fx:.3f}, {fy:.3f})")
    lines.append(f"const NEAR_JAMB_FOOT: Vector2 = Vector2({nx:.3f}, {ny:.3f})")
    open(os.path.join(OUT, "junction_door_layout.gd"), "w").write("\n".join(lines) + "\n")
    print("atlas", W, Hp, "used height", H, [(p["piece"], p["region"]) for p in pieces])


if __name__ == "__main__":
    main()
