"""Fix round 2 (review r2, N3; was jgrade.py): grades the cleaned blast-door layers into the junction's value plan (grade.py):
row gains from the cross-wall's concrete (its face parts) at 0.70x the room's back wall at the same
height, applied to every piece of the door end; the release bay set by its own back wall; the lenses
keep their value. Reads layers/{sealed,blown}/, writes layers/graded/{sealed,blown}/ (what install.py
packs) and layers/graded/gains.json."""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from scipy import ndimage
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools"))
import jmodel as M  # noqa: E402
import grade2 as G  # noqa: E402  (fix round 2: linear, at the corner)

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


# Fix round 3 (review r3, S1 and S4): set values on the graded layers, in linear light, each group's median
# to a target (layer values read as the screen does: the threshold's 0.0785 here is review r3's 0.064-0.094
# on screen).
#  S1: the threshold plate at the deck beside it (review r3: the deck reads 0.010-0.025 in j01's rows 494-518,
#      median about 0.018), its 12 mm nose a dull steel edge a little above it; the blown state's buckled
#      plate likewise.
#  S4: the blast's fresh damage lighter than the weathered face round it (Liu et al. 2018: cracking at the
#      wall corners, failure along the frame's plate edges; SDI 133 Cat. IV): fresh concrete fracture (the
#      spall faces) at FRACTURE x the weathered face, their arrises (spall lips) and torn bare steel (keepers
#      and their pockets, sheared lugs and pins, torn hinge leaves and knuckles, the torn liner and arris-angle
#      ends) at STEEL x; the soot and the open cracks stay as dark as they are. The weathered face is the
#      graded wall's face (0.0082) for the doorway's pieces and the near column's own end face (0.0197) for it.
FRACTURE, STEEL = 2.0, 2.6
WALL_FACE, COL_FACE, DECK = 0.0082, 0.0197, 0.0265  # DECK: closed on render.sh a1 (threshcheck.py: the deck beside it reads 0.024-0.036)
R3_TARGETS = {
    "wall": [(["threshold"], DECK), (["threshold_nose"], DECK * 1.35)],
    "hole": [(["threshold_full"], DECK), (["keeper0", "keeper1", "keeper2"], WALL_FACE * FRACTURE),
             (["keeper_tab0", "keeper_tab1", "keeper_tab2", "liner_curl"], WALL_FACE * STEEL)],
    "damage": [(["spall"], WALL_FACE * FRACTURE), (["spall_lip"], WALL_FACE * STEEL)],
    "frontblown": [(["col_spall"], COL_FACE * FRACTURE * 0.8), (["col_spall_lip"], COL_FACE * STEEL * 0.8),
                   (["col_hinge_frame0", "col_hinge_frame1", "col_hinge_frame2"], COL_FACE * STEEL * 0.8)],
}


def r3_values(out, layer, report):
    groups = R3_TARGETS.get(layer)
    if not groups:
        return out
    a = np.asarray(out).astype(np.float64)
    for parts, target in groups:
        m = mask(layer, parts)
        if m is None:
            continue
        sel = (m > 0.5) & (a[..., 3] > 200)
        if sel.sum() < 4:
            continue
        lin = G.to_lin(a.astype(np.uint8))
        lum = (lin * G.W709).sum(-1)
        med = float(np.median(lum[sel]))
        k = float(np.clip(target / max(med, 1e-6), 0.1, 8.0))
        if not any(n.startswith("threshold") for n in parts):
            k = max(k, 1.0)  # S4 only lifts: torn steel already lighter than its target keeps its value
        scaled = G.to_srgb8(lin * k).astype(np.float64)
        a[..., :3] = a[..., :3] * (1 - m[..., None]) + scaled * m[..., None]
        report.setdefault("fix_round_3_values", {})[f"{layer}:{'+'.join(parts)}"] = {"median_before": round(med, 4), "target": round(target, 4), "gain_lin": round(k, 3)}
    return np.clip(a + 0.5, 0, 255).astype(np.uint8)


def main():
    prof = G.profile("junction-blast")
    wall = np.asarray(Image.open(os.path.join(L, "sealed", "wall.png")).convert("RGBA"))
    conc = mask("wall", ["face_far_column", "face_upper"])
    conc = conc * (wall[..., 3] > 250)
    g = G.row_gains(wall, conc, M.CV.y0, M.CV.ppw, prof, world_x0=M.CV.x0, xr=G.wall_x("junction-blast"))
    gw = G.gains_to_world(g, M.CV.y0, M.CV.ppw)
    gw = G.with_feedback("junction-blast", gw)  # fix round 2: closed on the last render.sh pass (feedback.py)
    meds = G.row_medians(wall, conc, M.CV.y0, M.CV.ppw)
    keep = {"wall": mask("wall", ["light_lens"]), "alcove": mask("alcove", ["bay_light_lens"])}
    bay = np.asarray(Image.open(os.path.join(L, "sealed", "alcove.png")).convert("RGBA"))
    bm = mask("alcove", ["bay_back"]) * (bay[..., 3] > 250)
    gb = G.gains_to_world(G.row_gains(bay, bm, M.CV.y0, M.CV.ppw, prof, ratio=0.75), M.CV.y0, M.CV.ppw)
    bmeds = G.row_medians(bay, bm, M.CV.y0, M.CV.ppw)
    report = {"wall_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gw[0][::40], gw[1][::40])},
              "bay_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gb[0][::40], gb[1][::40])}}
    # fix round 2 (N3): the leaf's painted steel at LEAF_FRAC x the graded concrete beside it at the door's
    # rows (the thrown and breaking leaf take the same gain: the same steel)
    wall_g = G.apply_world_gains(wall, M.CV.y0, M.CV.ppw, gw, keep["wall"], meds)
    rows = M.CV.y0 + (np.arange(wall.shape[0]) + 0.5) / M.CV.ppw
    band = ((rows >= 330.0) & (rows <= 430.0))[:, None]
    wall_med = G.masked_median(wall_g, conc * band)
    leaf = np.asarray(Image.open(os.path.join(L, "sealed", "leaf.png")).convert("RGBA"))
    leaf_med = G.masked_median(G.apply_world_gains(leaf, M.CV.y0, M.CV.ppw, gw), (leaf[..., 3] > 250).astype(float) * band)
    lk = G.leaf_gain(leaf_med, wall_med) * G.LEAF_FB.get("junction-blast", 1.0)
    report["leaf"] = {"wall_med_door_rows": round(wall_med, 5), "leaf_med_after_wall_gain": round(leaf_med, 5), "extra_gain_lin": round(lk, 3)}
    # (the thrown leaf lies face up under the room's ceiling fittings: it keeps the wall's gain only)
    for sset, layers in (("sealed", ("wall", "leaf", "front", "alcove")), ("blown", ("hole", "damage", "lying", "frontblown", "leafbreak", "cracks"))):
        os.makedirs(os.path.join(OUT, sset), exist_ok=True)
        for layer in layers:
            im = np.asarray(Image.open(os.path.join(L, sset, f"{layer}.png")).convert("RGBA"))
            out = G.apply_world_gains(im, M.CV.y0, M.CV.ppw, gb if layer == "alcove" else gw, keep.get(layer), bmeds if layer == "alcove" else meds)
            if layer == "wall":
                # fix round 2 (human: "a stray white tick"): the batten over the door reads as a lamp: body,
                # caps and brackets at their painted value, lens at half the darkening, a soft pool round it
                lens = mask("wall", ["light_lens"])
                body = mask("wall", ["light_body", "light_cap0", "light_cap1", "light_bracket0", "light_bracket1"])
                if lens is not None:
                    pool = G.fitting_pool(im, M.CV.y0, M.CV.ppw, gw, None, lens, body, meds=meds)
                    near = ndimage.distance_transform_edt(lens < 0.5) / M.CV.ppw < 40.0
                    out = np.where(near[..., None], pool, out)
            if layer in ("leaf", "leafbreak"):
                out = G.scale_lin(out, lk)
            cm = {"wall": conc, "front": mask("front", ["col_end", "col_face_strip", "stub_face", "stub_top", "stub_cut"]),
                  "frontblown": mask("frontblown", ["col_end", "col_face_strip", "col_spall"]), "alcove": bm}.get(layer)
            if layer in ("front", "frontblown") and cm is not None:
                # fix round 2 (S5): the near column's even white flecks calmed to the concrete's own mottle
                # (median blend), and its detail lifted less than the wall's; wear stays where the design put it
                out = G.despeckle(out, cm, keep=0.25)
                out = G.boost_detail(out, cm, ppw=M.CV.ppw, amount=1.0)
            elif cm is not None:
                out = G.boost_detail(out, cm, ppw=M.CV.ppw)
            out = r3_values(out, layer, report)
            Image.fromarray(out, "RGBA").save(os.path.join(OUT, sset, f"{layer}.png"))
    json.dump(report, open(os.path.join(OUT, "gains.json"), "w"), indent=1)
    print(json.dumps(report))


if __name__ == "__main__":
    main()
