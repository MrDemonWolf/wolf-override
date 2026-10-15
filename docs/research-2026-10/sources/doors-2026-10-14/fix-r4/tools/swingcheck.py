"""Fix round 4 (review r4, M1): every swing leaf through its swing, on render.sh frames. Scratch only.

For each swing leaf (Records entry r01, Records exit r07, junction entry r09):
  swing    the frames at 10, 20, 30 and 50 % open (time frozen) and the shut and open frames: the face the
           camera sees (leafsim's outline at that swing, with the round-4 face choice), less any pixel the
           leaf-hidden twin shows the same (an actor in front), median linear luminance, against the
           cross-wall beside the door in the same frame (shutleaf.py's box at the leaf's rows).
           Targets: >= 0.45x the wall at every swing, and not below the shut leaf (>= 0.97x its median).
  reveal   the open leaf next to its hinge against the far-jamb reveal, in review r4's own columns and rows
           (350-380, 400-440, 460-490). Target 0.6-1.0.
usage: swingcheck.py FRAMES_DIR [OUT_JSON]   (exit 1 if any target is missed)"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "fix-r3", "tools"))
import leafsim as S  # noqa: E402
import measure3 as M3  # noqa: E402
import measure4 as M4  # noqa: E402
import inputs as I  # noqa: E402

DOORS = {"records-entry": ("r01", "r01-arrival", "r01-noleaf", "r03-arrival-closed"),
         "records-exit": ("r07", "r07-exit-open", "r07-noleaf", "r04-copy-point"),
         "junction-entry": ("r09", "r09-after-leaving", "r09-noleaf", "r11-entry-shut")}
WALL_MIN, SHUT_MIN, BAND = 0.45, 0.97, (0.6, 1.0)


def leaf_median(fr, shots, size, name, slug, twin, opened):
    s = shots[slug]
    L = M3.lin_lum(os.path.join(fr, slug + "-clean.png"))
    _, tag = S.render(S.leaf(name), opened, s["canvas"], size=tuple(size))
    m = ndimage.binary_erosion((tag == "room") | (tag == "out"), iterations=1)
    if twin:
        B = M3.lin_lum(os.path.join(fr, twin + "-clean.png"))
        m &= np.abs(L - B) > 1e-4
    ys = np.nonzero(m.any(1))[0]
    x0, _, x1, _ = M4.screen_box(s, size, M3.ENDS[name][2], (330.0, 430.0), L.shape)
    wall = float(np.median(L[ys.min():ys.max() + 1, x0:x1]))
    face = "room" if S.faces(S.leaf(name), opened, "camera")[0][4] == "room" else "out"
    return float(np.median(L[m])), wall, int(m.sum()), face


def main():
    fr = sys.argv[1]
    run = json.load(open(os.path.join(fr, "_run.json")))
    shots = {s["slug"]: s for s in run["shots"]}
    size = run["size"]
    if size[0] != 1280:
        print("swingcheck measures 1280 x 720 frames (the reviewer's columns)"); sys.exit(2)
    out, ok = {}, True
    lines = ["| Door | Frame | Open | Face seen | Leaf | Wall beside | Leaf / wall | Leaf / shut leaf |", "|---|---|---|---|---|---|---|---|"]
    for name, (pre, opened_slug, noleaf, shut) in DOORS.items():
        rows = []
        lm_shut, wall_shut, _, f0 = leaf_median(fr, shots, size, name, shut, None, 0.0)
        rows.append((shut, 0.0, f0, lm_shut, wall_shut))
        for pc in (10, 20, 30, 50):
            slug = f"{pre}-swing-{pc:02d}"
            if slug not in shots:
                continue
            lm, wl, n, f = leaf_median(fr, shots, size, name, slug, f"{pre}-swing-noleaf", pc / 100.0)
            rows.append((slug, pc / 100.0, f, lm, wl))
        lm, wl, n, f = leaf_median(fr, shots, size, name, opened_slug, noleaf, 1.0)
        rows.append((opened_slug, 1.0, f, lm, wl))
        res = []
        for slug, op, f, lm, wl in rows:
            r_w, r_s = lm / wl, lm / lm_shut
            good = r_w >= WALL_MIN and r_s >= SHUT_MIN
            ok &= good
            res.append({"frame": slug, "open": op, "face": f, "leaf": lm, "wall": wl, "leaf_over_wall": r_w, "leaf_over_shut": r_s, "pass": bool(good)})
            lines.append(f"| {name} | {slug} | {op:.1f} | {f} | {lm:.4f} | {wl:.4f} | **{r_w:.2f}** | **{r_s:.2f}** |")
        # the reveal, review r4's columns
        L = M3.lin_lum(os.path.join(fr, opened_slug + "-clean.png"))
        B = M3.lin_lum(os.path.join(fr, noleaf + "-clean.png"))
        (lx0, lx1), (rx0, rx1) = I.COLS[name]
        bands = []
        for y0, y1 in I.BANDS:
            lv, rv = float(np.median(L[y0:y1, lx0:lx1])), float(np.median(B[y0:y1, rx0:rx1]))
            good = BAND[0] <= lv / rv <= BAND[1]
            ok &= good
            bands.append({"rows": [y0, y1], "leaf": lv, "reveal": rv, "ratio": lv / rv, "pass": bool(good)})
        out[name] = {"swing": res, "reveal_bands": bands}
    lines.append("")
    lines.append("| Door | Rows | Leaf by the hinge | Reveal | Leaf / reveal |")
    lines.append("|---|---|---|---|---|")
    for name, d in out.items():
        for b in d.get("reveal_bands", []):
            lines.append(f"| {name} | {b['rows'][0]}-{b['rows'][1]} | {b['leaf']:.4f} | {b['reveal']:.4f} | **{b['ratio']:.2f}** |")
    print("\n".join(lines))
    if len(sys.argv) > 2:
        json.dump(out, open(sys.argv[2], "w"), indent=1)
        open(sys.argv[2].replace(".json", ".md"), "w").write("\n".join(lines) + "\n")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
