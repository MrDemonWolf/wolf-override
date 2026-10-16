"""Fix round 4: leafsim against round 3's render.sh frames (same constants): whole-face and near-hinge band medians."""
import json, sys, os
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, "doors-r1/fix-r3/tools")
import leafsim as S, measure3 as M3
fr = sys.argv[1]
run = json.load(open(fr + "/_run.json")); shots = {s["slug"]: s for s in run["shots"]}
cases = [("records-exit", "r07-exit-open", "r07-noleaf", 1.0), ("records-entry", "r01-arrival", "r01-noleaf", 1.0), ("junction-entry", "r09-after-leaving", "r09-noleaf", 1.0),
         ("records-exit", "r04-copy-point", None, 0.0), ("records-entry", "r03-arrival-closed", None, 0.0), ("junction-entry", "r11-entry-shut", None, 0.0)]
for name, slug, twin, op in cases:
    cfg = S.leaf(name)
    sim, tag = S.render(cfg, op, shots[slug]["canvas"], choice="parallel")
    real = M3.lin_lum(f"{fr}/{slug}-clean.png")
    m = (tag == "room") | (tag == "out")
    if twin:
        B = M3.lin_lum(f"{fr}/{twin}-clean.png")
        m &= np.abs(real - B) > 1e-4
    from scipy import ndimage
    m = ndimage.binary_erosion(m, iterations=1)
    print(f"{name:15s} {slug:20s} open {op}: face median sim {np.nanmedian(sim[m]):.4f} real {np.median(real[m]):.4f} ratio {np.median(real[m])/np.nanmedian(sim[m]):.2f}  px {m.sum()}")
    if op == 1.0:
        for y0, y1 in [(350, 380), (400, 440), (460, 490)]:
            band = np.zeros_like(m); band[y0:y1] = True
            hm = band & m
            cols = np.nonzero(hm.any(0))[0]
            if not len(cols): continue
            edge = cols.max() if cfg["side"] > 0 else cols.min()
            near = hm.copy(); near[:, :] = False
            if cfg["side"] > 0: near[y0:y1, edge - 8:edge + 1] = hm[y0:y1, edge - 8:edge + 1]
            else: near[y0:y1, edge:edge + 9] = hm[y0:y1, edge:edge + 9]
            print(f"     rows {y0}-{y1}: near-hinge sim {np.nanmedian(sim[near]):.4f} real {np.median(real[near]):.4f}  ratio {np.median(real[near])/np.nanmedian(sim[near]):.2f}")
