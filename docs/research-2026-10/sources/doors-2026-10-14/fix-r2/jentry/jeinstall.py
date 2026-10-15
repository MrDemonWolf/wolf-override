"""Junction entry door: builds the game layers (doors-r1, fix round 1). Scratch only.
Outputs (jentry/out/):
  assets/props/junction-entry-atlas.png  one lossless atlas: the cross-wall (doorway alpha 0), the near
      column with its lamp socket, the stub, the leaf's junction-side face, its passage-side face, its
      latch edge, and the status lamp's glass (a neutral globe the game tints)
  assets/rooms/junction-far.png  main's plate with the service line passage painted in behind the doorway
      (at the camera's left clamp's parallax)
  assets/rooms/junction-mid.png  main's plate cleared left of the near column and the stub (the cutaway)
  placement.json"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jedesign as JE  # noqa: E402  (installs jemodel as rmodel)
import jemodel as M  # noqa: E402
import install as RI  # noqa: E402  (records/tools/install.py: to_2ppw, crop_alpha, pack, lens)
from jeinputs import mid_erase  # noqa: E402

GAME = os.path.join(M.TRACK, "..", "main-junction", "apps", "game")
LAYERS = os.path.join(M.TRACK, "layers", "graded")
OUT = os.path.join(M.TRACK, "out")


STRIP_X1 = 372.0  # world: the right end of a plain run of the header (x 300-372: no clamp, no steam)
HEADER_Y = (227.5, 280.0)


def pipes_from_mid(wall, cv):
    """Fix round 2 (review r2 N2, look): the header and the service line carry on over the cross-wall's face
    into their sleeves as THE ROOM'S OWN PIPE: each stub's pixels are the mid plate's header from a plain
    run of it (no clamp, no steam), the run's right end at STRIP_X1 laid at the join (x 147) and continuing
    left without repeating (the stub is shorter than the run); the service line takes the same pipe's
    cross-section scaled to its own diameter (a pipe's shading scales with it). The escutcheon collars
    keep their painted plate with its tone set to the pipe's (see below), not a pale card."""
    from jemid import edit_mid
    mid = np.asarray(edit_mid()[0]).astype(np.float64)
    a = np.asarray(wall).astype(np.float64).copy()
    H, W = a.shape[:2]
    XX, YY = np.meshgrid(cv["x0"] + (np.arange(W) + 0.5) / cv["ppw"], cv["y0"] + (np.arange(H) + 0.5) / cv["ppw"])
    xs = STRIP_X1 - (147.0 - XX)
    mx = np.clip((xs * 2.0).astype(int), 0, mid.shape[1] - 1)
    srcs = {}
    for name, y0, y1, _d in JE.PIPES:
        ysrc = HEADER_Y[0] + (YY - y0) / (y1 - y0) * (HEADER_Y[1] - HEADER_Y[0])
        my = np.clip(((ysrc - 52.0) * 2.0).astype(int), 0, mid.shape[0] - 1)
        srcs[name] = mid[my, mx, :4]
    md = os.path.join(M.DESIGN, "entry", "masks")
    for n in ("header", "thin"):
        st = np.asarray(Image.open(os.path.join(md, f"wall--pipe_{n}_stub.png"))).astype(np.float64) / 255.0
        co = np.asarray(Image.open(os.path.join(md, f"wall--pipe_{n}_collar.png"))).astype(np.float64) / 255.0
        src4 = srcs[n]
        # the plate's pipe edge is partly transparent: blend it over the painted stub there, never its RGB alone
        sa = src4[..., 3:4] / 255.0
        src = src4[..., :3] * sa + a[..., :3] * (1 - sa)
        a[..., :3] = a[..., :3] * (1 - st[..., None]) + src * st[..., None]
        # the collar keeps its painted plate (its texture and shading) with its tone set to 0.8 x the pipe's
        # in its rows (a steel plate in the same light, its face a little in shadow)
        rows = np.nonzero(st.max(1) > 0.5)[0]
        cm = co > 0.5
        if len(rows) and cm.sum() > 8:
            W709 = np.array([0.2126, 0.7152, 0.0722])
            lin = lambda u: np.where(u / 255.0 <= 0.04045, u / 255.0 / 12.92, ((u / 255.0 + 0.055) / 1.055) ** 2.4)
            pipe_l = np.median((lin(src[rows][st[rows] > 0.5]) * W709).sum(-1))
            col_l = np.median((lin(a[..., :3][cm]) * W709).sum(-1))
            k = 0.8 * pipe_l / max(col_l, 1e-5)
            new = lin(a[..., :3]) * k
            new = np.where(new <= 0.0031308, new * 12.92, 1.055 * np.power(np.clip(new, 0, 1), 1 / 2.4) - 0.055) * 255.0
            a[..., :3] = a[..., :3] * (1 - co[..., None]) + new * co[..., None]
    return Image.fromarray(np.clip(a + 0.5, 0, 255).astype(np.uint8), "RGBA")


def main():
    os.makedirs(os.path.join(OUT, "assets", "props"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "assets", "rooms"), exist_ok=True)
    door, lps = JE.lamps()
    spec = json.load(open(os.path.join(M.DESIGN, "entry", "spec.json")))
    cv = spec["canvas"]
    items, place = {}, {}
    wall = Image.open(os.path.join(LAYERS, "entry", "clean-wall.png")).convert("RGBA")
    wall = pipes_from_mid(wall, cv)
    wall = RI.to_2ppw(wall)
    img, tl = RI.crop_alpha(wall, cv["x0"], cv["y0"], 2.0)
    items["wall"], place["wall"] = img, {"world_top_left": [round(tl[0], 3), round(tl[1], 3)], "scale": 0.5}
    front = RI.to_2ppw(Image.open(os.path.join(LAYERS, "entry", "clean-front.png")))
    # the stub runs on to the deck's front edge far left of the room; the view never goes left of x 0
    img, tl = RI.crop_alpha(front, cv["x0"], cv["y0"], 2.0, (-2.0, cv["y0"], 200.0, cv["y0"] + cv["h"] / cv["ppw"]))
    items["front"], place["front"] = img, {"world_top_left": [round(tl[0], 3), round(tl[1], 3)], "scale": 0.5}
    for name in ("room", "out-exit", "edge"):
        items[f"leaf-{name}"] = Image.open(os.path.join(LAYERS, "leaf", f"clean-{name}.png")).convert("RGBA")
    items["lens"] = RI.lens()
    place["lens"] = {"scale": 0.25, "centre": spec["door"]["status_lamp_screen"]}
    atlas, regions = RI.pack(items)
    atlas.save(os.path.join(OUT, "assets", "props", "junction-entry-atlas.png"), optimize=True)
    for n, r in regions.items():
        place.setdefault(n, {})["region"] = list(r)
    # the far plate: the passage painted in at the left clamp's parallax
    far = Image.open(os.path.join(GAME, "assets", "rooms", "junction-far.png")).convert("RGBA")
    b = RI.to_2ppw(Image.open(os.path.join(LAYERS, "entry", "clean-beyond.png")))
    sx = int(round((cv["x0"] - JE.FAR_SHIFT_LEFT) * 2))
    sy = int(round((cv["y0"] - 79.0) * 2))
    layer = Image.new("RGBA", far.size, (0, 0, 0, 0))
    layer.paste(b, (sx, sy))
    Image.alpha_composite(far, layer).convert("RGB").save(os.path.join(OUT, "assets", "rooms", "junction-far.png"), optimize=True)
    # the mid plate (fix round 2, review r2 N2): jemid.edit_mid(): erased under the cross-wall, its doorway
    # and the floor triangle between the wall's foot and the walk line (deck re-laid there in the room's
    # camera), the header and the service line ended into the wall, the guard rail ended on a post; round
    # 1 cleared only plate x 0-25 here
    from jemid import edit_mid
    mid, mid_info = edit_mid()
    mid.save(os.path.join(OUT, "assets", "rooms", "junction-mid.png"), optimize=True)
    place["door"] = {"x_cross": door.xc, "hinge_foot_m": [round(float(v), 5) for v in door.hinge], "axis_u": [round(float(v), 6) for v in door.U], "axis_n": [round(float(v), 6) for v in door.N],
                     "near_jamb_foot": spec["door"]["near_jamb_foot"], "far_jamb_foot": spec["door"]["far_jamb_foot"], "column_end_face_at_1m": spec["door"]["column_end_face_at_1m"],
                     "leaf_lights": [{"name": l.name, "pos_m": [round(float(v), 4) for v in l.pos], "colour_x_intensity": [round(c * l.intensity, 4) for c in l.color], "reach_m": l.reach, "down": l.down}
                                     for l in lps if "passage" not in l.name]}
    place["mid_plate_edit"] = mid_info
    M.write_json(os.path.join(OUT, "placement.json"), {"atlas": "res://assets/props/junction-entry-atlas.png", "atlas_size": list(atlas.size), "pieces": place})
    print(json.dumps({"atlas": atlas.size, "regions": regions, "front": place["front"], "wall": place["wall"], "lens": place["lens"], "door": place["door"]}, indent=1))


if __name__ == "__main__":
    main()
