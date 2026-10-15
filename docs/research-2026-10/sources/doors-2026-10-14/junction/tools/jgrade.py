"""Fix round 1 (M1): grades the cleaned blast-door layers into the junction's value plan (grade.py):
row gains from the cross-wall's concrete (its face parts) at 0.70x the room's back wall at the same
height, applied to every piece of the door end; the release bay set by its own back wall; the lenses
keep their value. Reads layers/{sealed,blown}/, writes layers/graded/{sealed,blown}/ (what install.py
packs) and layers/graded/gains.json."""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools"))
import jmodel as M  # noqa: E402
import grade as G  # noqa: E402

L = os.path.join(M.WORK, "layers")
OUT = os.path.join(L, "graded")
DM = os.path.join(M.WORK, "design", "masks")


def mask(layer, names):
    u = None
    for n in names:
        p = os.path.join(DM, f"{layer}--{n}.png")
        if os.path.exists(p):
            m = np.asarray(Image.open(p)).astype(np.float64) / 255.0
            u = m if u is None else np.maximum(u, m)
    return u


def main():
    prof = G.profile("junction-blast")
    wall = np.asarray(Image.open(os.path.join(L, "sealed", "wall.png")).convert("RGBA"))
    conc = mask("wall", ["face_far_column", "face_upper"])
    conc = conc * (wall[..., 3] > 250)
    g = G.row_gains(wall, conc, M.CV.y0, M.CV.ppw, prof)
    gw = G.gains_to_world(g, M.CV.y0, M.CV.ppw)
    meds = G.row_medians(wall, conc, M.CV.y0, M.CV.ppw)
    keep = {"wall": mask("wall", ["light_lens"]), "alcove": mask("alcove", ["bay_light_lens"])}
    bay = np.asarray(Image.open(os.path.join(L, "sealed", "alcove.png")).convert("RGBA"))
    bm = mask("alcove", ["bay_back"]) * (bay[..., 3] > 250)
    gb = G.gains_to_world(G.row_gains(bay, bm, M.CV.y0, M.CV.ppw, prof, ratio=0.75), M.CV.y0, M.CV.ppw)
    bmeds = G.row_medians(bay, bm, M.CV.y0, M.CV.ppw)
    report = {"wall_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gw[0][::40], gw[1][::40])},
              "bay_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gb[0][::40], gb[1][::40])}}
    for sset, layers in (("sealed", ("wall", "leaf", "front", "alcove")), ("blown", ("hole", "damage", "lying", "leafbreak", "cracks"))):
        os.makedirs(os.path.join(OUT, sset), exist_ok=True)
        for layer in layers:
            im = np.asarray(Image.open(os.path.join(L, sset, f"{layer}.png")).convert("RGBA"))
            out = G.apply_world_gains(im, M.CV.y0, M.CV.ppw, gb if layer == "alcove" else gw, keep.get(layer), bmeds if layer == "alcove" else meds)
            cm = {"wall": conc, "front": mask("front", ["col_end", "col_face_strip", "stub_face", "stub_top", "stub_cut"]), "alcove": bm}.get(layer)
            if cm is not None:
                out = G.boost_detail(out, cm)
            Image.fromarray(out, "RGBA").save(os.path.join(OUT, sset, f"{layer}.png"))
    json.dump(report, open(os.path.join(OUT, "gains.json"), "w"), indent=1)
    print(json.dumps(report))


if __name__ == "__main__":
    main()
