"""Fix round 3 (review r3, S4): the blast's fresh damage against the weathered faces round it, on the render
(j04-blown, j06-lane-sentry). Each part's design mask is carried to the screen as in threshcheck.py; medians in
linear light. Target: fresh fracture and torn steel lighter than the weathered face (ratio > 1), soot darker.
usage: damagecheck.py FRAMES_DIR [OUT_JSON]"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import measure3 as M3  # noqa: E402
from threshcheck import DM, to_screen  # noqa: E402


def m(layer, names):
    u = None
    for n in names:
        p = os.path.join(DM, f"{layer}--{n}.png")
        if os.path.exists(p):
            a = np.asarray(Image.open(p)) > 127
            u = a if u is None else (u | a)
    return u


GROUPS = [
    ("spall faces (head, latch side)", "damage", ["spall"], "wall face", "wall", ["face_far_column", "face_upper"]),
    ("spall arrises", "damage", ["spall_lip"], "wall face", "wall", ["face_far_column", "face_upper"]),
    ("keeper pockets", "hole", ["keeper0", "keeper1", "keeper2"], "wall face", "wall", ["face_far_column", "face_upper"]),
    ("column spall", "frontblown", ["col_spall"], "column end", "frontblown", ["col_end"]),
    ("column spall arrises", "frontblown", ["col_spall_lip"], "column end", "frontblown", ["col_end"]),
    ("torn hinge leaves", "frontblown", ["col_hinge_frame0", "col_hinge_frame1", "col_hinge_frame2"], "column end", "frontblown", ["col_end"]),
    ("soot (stays dark)", "damage", ["soot"], "wall face", "wall", ["face_far_column", "face_upper"]),
]


def main():
    fr = sys.argv[1]
    run = json.load(open(os.path.join(fr, "_run.json")))
    shots = {s["slug"]: s for s in run["shots"]}
    out = {}
    for slug in ("j04-blown", "j06-lane-sentry"):
        if slug not in shots:
            continue
        L = M3.lin_lum(os.path.join(fr, f"{slug}-clean.png"))
        out[slug] = {}
        for name, layer, parts, refname, rlayer, rparts in GROUPS:
            a = ndimage.binary_erosion(to_screen(m(layer, parts), shots[slug], run["size"], L.shape), iterations=1)
            ref = to_screen(m(rlayer, rparts), shots[slug], run["size"], L.shape) & ~to_screen(m("damage", ["spall", "spall_lip", "soot", "rebar", "cracks_open", "flange_peeled"]), shots[slug], run["size"], L.shape)
            ref &= ~to_screen(m("frontblown", ["col_spall", "col_spall_lip", "col_soot", "col_rebar", "col_cracks"]), shots[slug], run["size"], L.shape)
            if a.sum() < 4 or ref.sum() < 4:
                continue
            ys, _ = np.nonzero(a)
            band = np.zeros_like(ref)
            band[max(ys.min() - 20, 0):ys.max() + 20] = True
            r = ref & band if (ref & band).sum() > 20 else ref
            va, vr = float(np.median(L[a])), float(np.median(L[r]))
            out[slug][name] = {"part": round(va, 4), refname: round(vr, 4), "ratio": round(va / max(vr, 1e-6), 2), "px": int(a.sum())}
            print(f"{slug:16s} {name:32s} {va:.4f} vs {refname} {vr:.4f}  ratio {va / max(vr, 1e-6):.2f}")
    if len(sys.argv) > 2:
        json.dump(out, open(sys.argv[2], "w"), indent=1)


if __name__ == "__main__":
    main()
