"""Records doors: builds the game layers from the cleaned pieces (doors-r1, records track). Scratch.

Outputs (records/out/):
  assets/props/records-doors-atlas.png   one lossless atlas (one texture, so the pieces batch):
      exit-wall, entry-wall       the cross-walls behind the walk line (2 px per world px), doorway alpha 0
      exit-column, entry-column   the near columns with their lamp sockets (glass alpha 0), over the actors
      exit-stub, entry-stub       the 0.15 m stubs running to the camera, over the actors
      leaf-room, leaf-out-exit, leaf-out-entry, leaf-edge   the swinging leaf's faces (SwingLeaf)
      container                   the GSA security container (2 px per world px)
      lens                        the status lamps' glass, a neutral globe the game tints
  assets/rooms/records-far.png  main's plate with the service line passage (right, at the right clamp's
                                parallax) and the vestibule (left, at the left clamp's) painted in
  assets/rooms/records-mid.png  main's plate with the end machinery erased where the cross-walls stand
  placement.json                every region, its world top-left and scale, the leaves' model and lights
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rmodel as M  # noqa: E402
import rdesign as RD  # noqa: E402

TRACK = M.TRACK
GAME = os.path.join(TRACK, "..", "main-records", "apps", "game")
LAYERS = os.path.join(TRACK, "layers")
OUT = os.path.join(TRACK, "out")
PAD = 2


def to_2ppw(img4: Image.Image) -> Image.Image:
    """4 px -> 2 px per world px, premultiplied so edges keep their colour."""
    a = np.asarray(img4.convert("RGBA")).astype(np.float64) / 255.0
    pm = a[..., :3] * a[..., 3:4]
    h, w = a.shape[:2]
    h2, w2 = h // 2, w // 2
    pm = pm[:h2 * 2, :w2 * 2].reshape(h2, 2, w2, 2, 3).mean((1, 3))
    al = a[:h2 * 2, :w2 * 2, 3].reshape(h2, 2, w2, 2).mean((1, 3))
    rgb = pm / np.maximum(al[..., None], 1e-6)
    return Image.fromarray(np.dstack([np.clip(rgb * 255 + 0.5, 0, 255), np.clip(al * 255 + 0.5, 0, 255)]).astype(np.uint8), "RGBA")


def crop_alpha(img: Image.Image, x0: float, y0: float, ppw: float, box=None):
    """Crops to the alpha bbox (or to [box] world rect first); returns (img, world top-left)."""
    if box is not None:
        bx0, by0, bx1, by1 = box
        px = (int(round((bx0 - x0) * ppw)), int(round((by0 - y0) * ppw)), int(round((bx1 - x0) * ppw)), int(round((by1 - y0) * ppw)))
        px = (max(px[0], 0), max(px[1], 0), min(px[2], img.size[0]), min(px[3], img.size[1]))
        img = img.crop(px)
        x0 += px[0] / ppw
        y0 += px[1] / ppw
    bb = img.getchannel("A").point(lambda v: 255 if v > 0 else 0).getbbox()
    img = img.crop(bb)
    return img, (x0 + bb[0] / ppw, y0 + bb[1] / ppw)


def edited_mid():
    mid = Image.open(os.path.join(GAME, "assets", "rooms", "records-mid.png")).convert("RGBA")
    a = np.asarray(mid).copy()
    h, w = a.shape[:2]
    X = (np.arange(w) + 0.5) / 2.0
    Y = (np.arange(h) + 0.5) / 2.0 + 69.0
    XX, YY = np.meshgrid(X, Y)
    # the end machinery where the cross-walls now stand; everything right of the exit column and left of
    # the entry column (the rack pipes end behind the columns, where they pass the walls)
    erase = ((YY >= 166.0) & ((XX >= 792.5) | (XX < 160.5))) | (XX >= 905.0) | (XX < 56.0)
    a[..., 3] = np.where(erase, 0, a[..., 3])
    a[..., :3] = np.where(erase[..., None], 0, a[..., :3])
    return Image.fromarray(a, "RGBA"), {"erased_world": ["y >= 166 and (x >= 792.5 or x < 160.5)", "x >= 905", "x < 56"]}


def edited_far():
    far = Image.open(os.path.join(GAME, "assets", "rooms", "records-far.png")).convert("RGBA")
    for piece, shift in (("exit", RD.FAR_SHIFT_RIGHT), ("entry", RD.FAR_SHIFT_LEFT)):
        spec = json.load(open(os.path.join(M.DESIGN, piece, "spec.json")))
        cv = spec["canvas"]
        b = to_2ppw(Image.open(os.path.join(LAYERS, piece, "clean-beyond.png")))
        sx = int(round((cv["x0"] - shift) * 2))
        sy = int(round((cv["y0"] - 69.0) * 2))
        layer = Image.new("RGBA", far.size, (0, 0, 0, 0))
        layer.paste(b, (sx, sy))
        far = Image.alpha_composite(far, layer)
    return far.convert("RGB")


def lens():
    """The status lamp's glass: a neutral, softly shaded globe (white = full tint), 4 px per world px."""
    w, h = 16, 20
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)
    nx = (xs + 0.5 - w / 2) / (w / 2)
    ny = (ys + 0.5 - h / 2) / (h / 2)
    r = np.sqrt(nx ** 2 + ny ** 2)
    a = np.clip((1.0 - r) * 3.0, 0, 1)
    v = np.clip(0.80 + 0.20 * (1 - r) - 0.12 * ny, 0, 1)
    rgb = (v * 255).astype(np.uint8)
    return Image.fromarray(np.dstack([rgb, rgb, rgb, (a * 255).astype(np.uint8)]), "RGBA")


def pack(items):
    """Shelf packing, tallest first. items: {name: Image}. Returns atlas and {name: (x, y, w, h)}."""
    order = sorted(items, key=lambda n: -items[n].size[1])
    width = 1024
    x = y = PAD
    shelf = 0
    regions = {}
    for n in order:
        w, h = items[n].size
        if x + w + PAD > width:
            x = PAD
            y += shelf + PAD
            shelf = 0
        regions[n] = (x, y, w, h)
        x += w + PAD
        shelf = max(shelf, h)
    used_w = max(r[0] + r[2] for r in regions.values()) + PAD
    used_h = y + shelf + PAD
    atlas = Image.new("RGBA", (used_w, used_h), (0, 0, 0, 0))
    for n, (x, y, w, h) in regions.items():
        atlas.paste(items[n], (x, y))
    return atlas, regions


def main():
    os.makedirs(os.path.join(OUT, "assets", "props"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "assets", "rooms"), exist_ok=True)
    mid, mid_note = edited_mid()
    mid_a = np.asarray(mid)[..., 3]
    items, place = {}, {}
    for side in (1, -1):
        piece = "exit" if side > 0 else "entry"
        spec = json.load(open(os.path.join(M.DESIGN, piece, "spec.json")))
        cv = spec["canvas"]
        door = M.DoorEnd(side, RD.XC if side > 0 else RD.XE)
        wall4 = Image.open(os.path.join(LAYERS, piece, "clean-wall.png"))
        wall = to_2ppw(wall4)
        # the mid plate's pillars stand in front of the wall's back end: clear the wall under them
        wa = np.asarray(wall).copy()
        h, w = wa.shape[:2]
        sx0 = int(round(cv["x0"] * 2))
        sy0 = int(round((cv["y0"] - 69.0) * 2))
        for yy in range(h):
            for_x = np.arange(w) + sx0
            ok = (for_x >= 0) & (for_x < mid_a.shape[1]) & (yy + sy0 >= 0) & (yy + sy0 < mid_a.shape[0])
            occ = np.zeros(w, bool)
            occ[ok] = mid_a[yy + sy0, for_x[ok]] > 8
            wa[yy, occ, 3] = 0
        wall = Image.fromarray(wa, "RGBA")
        img, tl = crop_alpha(wall, cv["x0"], cv["y0"], 2.0)
        items[f"{piece}-wall"] = img
        place[f"{piece}-wall"] = {"world_top_left": [round(tl[0], 3), round(tl[1], 3)], "scale": 0.5}
        front = to_2ppw(Image.open(os.path.join(LAYERS, piece, "clean-front.png")))
        # column: everything above the stub's top line near the column; stub: the rest
        col_x = spec["door"]["column_end_face_at_1m"]
        xs = list(col_x) + [spec["door"]["near_jamb_foot"][0], spec["door"]["status_lamp_screen"][0]]
        cx0, cx1 = min(xs) - 4.0, max(xs) + 4.0
        img, tl = crop_alpha(front, cv["x0"], cv["y0"], 2.0, (cx0, cv["y0"], cx1, 446.5))
        items[f"{piece}-column"] = img
        place[f"{piece}-column"] = {"world_top_left": [round(tl[0], 3), round(tl[1], 3)], "scale": 0.5}
        fa = np.asarray(front).copy()
        X = cv["x0"] + (np.arange(fa.shape[1]) + 0.5) / 2.0
        Y = cv["y0"] + (np.arange(fa.shape[0]) + 0.5) / 2.0
        XX, YY = np.meshgrid(X, Y)
        in_col = (XX >= cx0) & (XX < cx1) & (YY < 446.5)
        fa[..., 3] = np.where(in_col, 0, fa[..., 3])
        img, tl = crop_alpha(Image.fromarray(fa, "RGBA"), cv["x0"], cv["y0"], 2.0)
        items[f"{piece}-stub"] = img
        place[f"{piece}-stub"] = {"world_top_left": [round(tl[0], 3), round(tl[1], 3)], "scale": 0.5}
        lx, ly = spec["door"]["status_lamp_screen"]
        place[f"{piece}-lamp"] = {"centre": [lx, ly]}
        place[f"{piece}-door"] = {
            "x_cross": door.xc, "hinge_foot_m": [round(v, 5) for v in door.hinge], "axis_u": [round(v, 6) for v in door.U], "axis_n": [round(v, 6) for v in door.N],
            "near_jamb_foot": spec["door"]["near_jamb_foot"], "far_jamb_foot": spec["door"]["far_jamb_foot"],
            "column_end_face_at_1m": col_x,
            "latch_strike_screen": [round(v, 2) for v in door.s(door.A_N, door.LEVER_H, -0.02)],
        }
        _, lamps, f_door, _ = RD.lamps_for(side)
        place[f"{piece}-door"]["leaf_lights"] = [
            {"name": l.name, "pos_m": [round(v, 4) for v in l.pos], "colour_x_intensity": [round(c * l.intensity, 4) for c in l.color], "reach_m": l.reach, "down": l.down}
            for l in lamps if "passage" not in l.name and "vestibule" not in l.name]
    for name in ("room", "out-exit", "out-entry", "edge"):
        items[f"leaf-{name}"] = Image.open(os.path.join(LAYERS, "leaf", f"clean-{name}.png")).convert("RGBA")
    cont = to_2ppw(Image.open(os.path.join(LAYERS, "container", "clean-container.png")))
    cs = json.load(open(os.path.join(M.DESIGN, "container", "spec.json")))
    img, tl = crop_alpha(cont, cs["canvas"]["x0"], cs["canvas"]["y0"], 2.0)
    items["container"] = img
    place["container"] = {"world_top_left": [round(tl[0], 3), round(tl[1], 3)], "scale": 0.5, "centre_x": RD.CONTAINER_X,
                          "front_left_right_x": cs["screen_front_left_right"], "lock_screen": cs["lock_screen"]}
    items["lens"] = lens()
    place["lens"] = {"scale": 0.25}
    atlas, regions = pack(items)
    atlas.save(os.path.join(OUT, "assets", "props", "records-doors-atlas.png"), optimize=True)
    for n, r in regions.items():
        place.setdefault(n, {})["region"] = list(r)
    mid.save(os.path.join(OUT, "assets", "rooms", "records-mid.png"), optimize=True)
    edited_far().save(os.path.join(OUT, "assets", "rooms", "records-far.png"), optimize=True)
    placement = {"atlas": "res://assets/props/records-doors-atlas.png", "atlas_size": list(atlas.size), "pieces": place,
                 "mid_plate": mid_note, "far_plate": {"exit_passage_shift": RD.FAR_SHIFT_RIGHT, "entry_vestibule_shift": RD.FAR_SHIFT_LEFT},
                 "memory": {"atlas_rgba_bytes_lossless_no_mipmaps": atlas.size[0] * atlas.size[1] * 4,
                            "removed_records_exit_hatch_with_mipmaps": int(512 * 512 * 4 * 4 / 3)}}
    M.write_json(os.path.join(OUT, "placement.json"), placement)
    print(json.dumps({"atlas": atlas.size, "regions": regions, "memory": placement["memory"]}, indent=1))


if __name__ == "__main__":
    main()
