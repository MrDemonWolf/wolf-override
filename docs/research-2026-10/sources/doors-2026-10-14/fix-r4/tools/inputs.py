"""Fix round 4 (M1): the fit's measured inputs from round 3's render.sh frames, which this round leaves
unchanged (the walls and reveals are painted): for each swing leaf, the far-jamb reveal beside the open leaf's
hinge edge in the reviewer's three row bands (from the leaf-hidden twin frame), the cross-wall beside the
door (shutleaf.py's box), and the sim-to-render scale (validate.py). usage: inputs.py FRAMES_DIR OUT_JSON"""
import json, os, sys
import numpy as np
from scipy import ndimage
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, "doors-r1/fix-r3/tools")
import leafsim as S, measure3 as M3, measure4 as M4
BANDS = [(350, 380), (400, 440), (460, 490)]
OPEN = {"records-exit": ("r07-exit-open", "r07-noleaf"), "records-entry": ("r01-arrival", "r01-noleaf"), "junction-entry": ("r09-after-leaving", "r09-noleaf")}
SHUT = {"records-exit": "r04-copy-point", "records-entry": "r03-arrival-closed", "junction-entry": "r11-entry-shut"}
HINGE_PX, REV = 9, (3, 12)
# review r4's own columns (review-real-r4/tools/leaf_vs_reveal.py, 1280 x 720): the open leaf next to its hinge
# and the far-jamb reveal it hangs on. The fit and the check use these, so they measure what the reviewer did.
COLS = {"records-exit": ((1108, 1117), (1121, 1133)), "records-entry": ((144, 153), (128, 140)), "junction-entry": ((73, 82), (57, 68))}


def near_hinge(mask, side, y0, y1):
    """Per row, the leaf pixels within HINGE_PX of its hinge edge, and the reveal REV px beyond that edge."""
    near = np.zeros_like(mask); rev = np.zeros_like(mask)
    for y in range(y0, y1):
        xs = np.nonzero(mask[y])[0]
        if len(xs) < HINGE_PX:
            continue
        if side > 0:
            e = xs.max(); near[y, e - HINGE_PX + 1:e + 1] = mask[y, e - HINGE_PX + 1:e + 1]; rev[y, e + REV[0]:e + REV[1]] = True
        else:
            e = xs.min(); near[y, e:e + HINGE_PX] = mask[y, e:e + HINGE_PX]; rev[y, max(e - REV[1] + 1, 0):max(e - REV[0] + 1, 0)] = True
    return near, rev


if __name__ == "__main__":
    fr = sys.argv[1]
    run = json.load(open(fr + "/_run.json")); shots = {s["slug"]: s for s in run["shots"]}
    out = {}
    for name, (a, b) in OPEN.items():
        cfg = S.leaf(name)
        sim, tag = S.render(cfg, 1.0, shots[a]["canvas"], choice="parallel")
        face = (tag == "room") | (tag == "out")
        La, Lb = M3.lin_lum(f"{fr}/{a}-clean.png"), M3.lin_lum(f"{fr}/{b}-clean.png")
        m = ndimage.binary_erosion(face & (np.abs(La - Lb) > 1e-4), iterations=1)
        bands = []
        (lx0, lx1), (rx0, rx1) = COLS[name]
        for y0, y1 in BANDS:
            near = np.zeros_like(m); near[y0:y1, lx0:lx1] = True
            bands.append({"rows": [y0, y1], "reveal": float(np.median(Lb[y0:y1, rx0:rx1])), "leaf_r3": float(np.median(La[y0:y1, lx0:lx1])),
                          "sim_r3": float(np.nanmedian(sim[near & face]))})
        s = SHUT[name]
        Ls = M3.lin_lum(f"{fr}/{s}-clean.png")
        simS, tagS = S.render(cfg, 0.0, shots[s]["canvas"], choice="parallel")
        ms = ndimage.binary_erosion((tagS == "room") | (tagS == "out"), iterations=2)
        ys = np.nonzero(ms.any(1))[0]
        x0, _, x1, _ = M4.screen_box(shots[s], run["size"], M3.ENDS[name][2], (330.0, 430.0), Ls.shape)
        wall = float(np.median(Ls[ys.min():ys.max() + 1, x0:x1]))
        c_open = float(np.median(La[m]) / np.nanmedian(sim[m]))
        c_shut = float(np.median(Ls[ms]) / np.nanmedian(simS[ms]))
        out[name] = {"open_frame": a, "open_canvas": shots[a]["canvas"], "shut_frame": s, "shut_canvas": shots[s]["canvas"], "bands": bands, "wall": wall,
                     "c_open": c_open, "c_shut": c_shut, "c": (c_open + c_shut) / 2, "shut_r3": float(np.median(Ls[ms]))}
        print(name, json.dumps(out[name], indent=None)[:600])
    json.dump(out, open(sys.argv[2], "w"), indent=1)
