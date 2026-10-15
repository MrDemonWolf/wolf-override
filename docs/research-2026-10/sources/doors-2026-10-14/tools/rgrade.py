"""Fix round 1 (M1): grades cleaned door-end layers in the records track's format (Records exit and
entry, the junction entry) into their rooms' value plan (grade.py). Per door end: row gains from the
cross-wall's concrete face at 0.70x the room's back wall at the same height, applied to the wall, its
column and stub; the passage or vestibule behind the doorway at PASSAGE_RATIO of the room; the leaf faces
by one gain (the median of the wall's gains over the door's rows); lenses keep their value.
usage: rgrade.py TRACK_DIR piece:ref[,piece:ref]   e.g. rgrade.py ../records exit:records-exit entry:records-entry
Writes TRACK_DIR/layers/graded/ (same names) and gains.json."""
from __future__ import annotations

import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grade as G  # noqa: E402


def mask(dirp, layer, names, shape):
    u = np.zeros(shape)
    for n in names:
        p = os.path.join(dirp, f"{layer}--{n}.png")
        if os.path.exists(p):
            u = np.maximum(u, np.asarray(Image.open(p)).astype(np.float64) / 255.0)
    return u


def main():
    track = os.path.abspath(sys.argv[1])
    L = os.path.join(track, "layers")
    OUT = os.path.join(L, "graded")
    os.makedirs(OUT, exist_ok=True)
    report = {}
    leaf_gains = []
    for arg in sys.argv[2:]:
        piece, ref = arg.split(":")
        spec = json.load(open(os.path.join(track, "design", piece, "spec.json")))
        cv = spec["canvas"]
        md = os.path.join(track, "design", piece, "masks")
        prof = G.profile(ref)
        wall = np.asarray(Image.open(os.path.join(L, piece, "clean-wall.png")).convert("RGBA"))
        conc = mask(md, "wall", ["face_back", "face_head"], wall.shape[:2]) * (wall[..., 3] > 250)
        g = G.row_gains(wall, conc, cv["y0"], cv["ppw"], prof)
        gw = G.gains_to_world(g, cv["y0"], cv["ppw"])
        meds = G.row_medians(wall, conc, cv["y0"], cv["ppw"])
        beyond = np.asarray(Image.open(os.path.join(L, piece, "clean-beyond.png")).convert("RGBA"))
        bm = mask(md, "beyond", ["back_wall"], beyond.shape[:2]) * (beyond[..., 3] > 250)
        gb = G.gains_to_world(G.row_gains(beyond, bm, cv["y0"], cv["ppw"], prof, ratio=G.PASSAGE_RATIO), cv["y0"], cv["ppw"])
        bmeds = G.row_medians(beyond, bm, cv["y0"], cv["ppw"])
        os.makedirs(os.path.join(OUT, piece), exist_ok=True)
        for layer, gg, keepn, mm in (("wall", gw, ["light_diffuser"], meds), ("front", gw, [], meds), ("beyond", gb, ["light_diffuser"], bmeds)):
            im = np.asarray(Image.open(os.path.join(L, piece, f"clean-{layer}.png")).convert("RGBA"))
            keep = mask(md, layer, keepn, im.shape[:2]) if keepn else None
            out = G.apply_world_gains(im, cv["y0"], cv["ppw"], gg, keep, mm)
            if layer == "wall":
                # the exit sign hangs out in the room under its own conduit-fed lamp: it takes only half
                # the wall's darkening (the square root of its gain), so its housing reads round the legend
                sign = mask(md, "wall", ["sign_housing", "sign_face", "sign_bracket", "sign_wallplate"], im.shape[:2])
                if sign.max() > 0:
                    half = G.apply_world_gains(im, cv["y0"], cv["ppw"], (gg[0], np.sqrt(gg[1])), keep)
                    out = np.where(sign[..., None] > 0.5, half, out)
            cm = {"wall": conc, "front": mask(md, "front", ["col_face", "col_end", "stub_face", "stub_top"], im.shape[:2]), "beyond": bm}.get(layer)
            if cm is not None:
                out = G.boost_detail(out, cm)
            Image.fromarray(out, "RGBA").save(os.path.join(OUT, piece, f"clean-{layer}.png"))
        lg = G.median_gain(gw, 352.0, 436.0)
        leaf_gains.append(lg)
        report[piece] = {"ref": ref, "leaf_rows_gain": round(lg, 3),
                         "wall_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gw[0][::40], gw[1][::40])},
                         "passage_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gb[0][::40], gb[1][::40])}}
    # the leaf's faces: one gain for all of them (shared by the doors of this track), eased (its square
    # root): painted steel sheet under the door light holds more of its value than the cast face, and at
    # the wall's full gain an open leaf goes to a dark slab with no detail (review r1, the human pass)
    lgain = float(np.exp(np.mean(np.log(leaf_gains)))) ** 0.5
    os.makedirs(os.path.join(OUT, "leaf"), exist_ok=True)
    for f in os.listdir(os.path.join(L, "leaf")):
        im = np.asarray(Image.open(os.path.join(L, "leaf", f)).convert("RGBA")).astype(np.float64)
        im[..., :3] *= lgain
        Image.fromarray(np.clip(im, 0, 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "leaf", f))
    report["leaf_gain"] = round(lgain, 3)
    if os.path.isdir(os.path.join(L, "container")):
        # the security container in the room's light: a grey enamel safe in a dark room, lit from the
        # ceiling lamp above it (lighter at its top, darker toward its base), not a pale clay box
        os.makedirs(os.path.join(OUT, "container"), exist_ok=True)
        for f in os.listdir(os.path.join(L, "container")):
            im = np.asarray(Image.open(os.path.join(L, "container", f)).convert("RGBA")).astype(np.float64)
            h = im.shape[0]
            ramp = np.linspace(0.92, 0.62, h)[:, None, None]
            im[..., :3] *= ramp
            Image.fromarray(np.clip(im, 0, 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "container", f))
    json.dump(report, open(os.path.join(OUT, "gains.json"), "w"), indent=1)
    print(json.dumps({k: (v if not isinstance(v, dict) else {"leaf_rows_gain": v["leaf_rows_gain"]}) for k, v in report.items()}))


if __name__ == "__main__":
    main()
