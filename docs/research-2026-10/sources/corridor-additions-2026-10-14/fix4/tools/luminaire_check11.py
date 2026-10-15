# Round 11 (add7 fix round 4; copied from add7/fix3/tools/luminaire_check10.py): the same checks on round 9, round 10 and
# round 11 (raw11/add); the luminaire's art is unchanged in round 11, so this re-checks it on the new captures.
"""Round 10 (add7 fix round 3; from fix2/tools/luminaire_check9.py): real review r3 MUST 1's checks on
the clean 1280x720 frames of route A (render.sh), for round 8 (raw8/add), round 9 (raw9/add) and
round 10 (raw10/add):
  * box edge: rows 28-50, the wall's column profile across round 9's old left edge (x 655-668): the
    largest step between neighbouring columns (pass: <= 1.5 levels per px);
  * conduit: the wall's mean on the two sides of the vertical conduit, x 707-711 against 716-720,
    rows 28-50 (pass: within 2 levels);
  * as round 9: the lit diffuser's span and centre, the wall pool's peak and centroid (rows 62-100)
    and the floor streak's peak (rows 560-680) within +-5 px of the fitting's centre;
  * the stray-streak zone below the cut wall (rows 630-700, x 1140-1240): max over median.
Writes add7/shots/luminaire-check.json and crops m1-luminaire-*.png."""
import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

S = "scratchpad/real-slice/add7/shots"
LUM = np.array([0.2126, 0.7152, 0.0722])
RUNS = {"round9": os.path.join(S, "raw9", "add", "A-720"), "round10": os.path.join(S, "raw10", "add", "A-720"), "round11": os.path.join(S, "raw11", "add", "A-720")}


def prof(Y, y0, y1, x0, x1, k=7):
    return ndimage.uniform_filter1d(Y[y0:y1, x0:x1].mean(0), k)


def main():
    out = {}
    crops = {}
    for tag, d in RUNS.items():
        out[tag] = {}
        for slug in ("s1-door-end-rest", "s5-door-open", "s7-safe-point"):
            im = np.asarray(Image.open(os.path.join(d, slug + "-clean.png")).convert("RGB")).astype(float)
            Y = im @ LUM
            row = {}
            if slug != "s7-safe-point":
                band = Y[40:60, 640:760]
                yb = int(np.argmax(band.max(1)))
                r = Y[40 + yb, 640:760]
                lit = np.nonzero(r > 0.6 * r.max())[0]
                x0, x1 = 640 + int(lit.min()), 640 + int(lit.max())
                c = (x0 + x1) / 2
                xs = np.arange(600, 800)
                p = prof(Y, 62, 100, 600, 800)
                w = np.clip(p - np.percentile(p, 20), 0, None)
                pool_c = float((xs * w).sum() / w.sum())
                pool_pk = int(xs[np.argmax(p)])
                f = prof(Y, 560, 680, 600, 800, 9)
                fl_pk = int(xs[np.argmax(f)])
                edge = Y[28:51, 655:669].mean(0)
                steps = np.abs(np.diff(edge))
                left, right = float(Y[28:51, 707:712].mean()), float(Y[28:51, 716:721].mean())
                row = {"diffuser_x": [x0, x1], "fitting_centre": c, "pool_centroid": round(pool_c, 1), "pool_peak": pool_pk, "floor_streak_peak": fl_pk,
                       "pool_peak_off": round(pool_pk - c, 1), "pool_centroid_off": round(pool_c - c, 1), "floor_peak_off": round(fl_pk - c, 1),
                       "box_edge_profile_x655_668": [round(float(v), 1) for v in edge], "box_edge_max_step": round(float(steps.max()), 2),
                       "conduit_sides_x707_711_vs_716_720": [round(left, 1), round(right, 1)], "conduit_sides_diff": round(left - right, 2)}
                row["pass"] = bool(abs(pool_pk - c) <= 5 and abs(pool_c - c) <= 5 and abs(fl_pk - c) <= 5 and steps.max() <= 1.5 and abs(left - right) <= 2.0)
                if slug == "s5-door-open":
                    crops[tag] = im[10:110, 620:760].astype(np.uint8)
                    vis = Image.fromarray(im.astype(np.uint8)).crop((560, 0, 840, 720))
                    dr = ImageDraw.Draw(vis)
                    for x, col in ((c, (0, 255, 255)), (pool_pk, (255, 210, 0)), (fl_pk, (255, 120, 0))):
                        dr.line([(x - 560, 0), (x - 560, 720)], fill=col, width=1)
                    dr.rectangle([0, 0, 280, 14], fill=(0, 0, 0))
                    dr.text((3, 2), f"{tag}: cyan fit {c:.1f} | yellow pool {pool_pk} | orange floor {fl_pk}", fill=(230, 230, 230))
                    vis.resize((560, 1440), Image.NEAREST).save(os.path.join(S, "crops", f"m1-luminaire-profile-{tag}-2x.png"))
            p = prof(Y, 630, 700, 1140, 1240, 9)
            row["stray_zone_s_max_over_median"] = round(float(p.max() / np.median(p)), 3)
            out[tag][slug] = row
    # the review's own crop, redrawn: round 8 | round 9 | round 10, 4x, and the same with contrast x2.5
    tiles = []
    for gain in (1.0, 2.5):
        for tag in RUNS:
            t = Image.fromarray(np.clip(crops[tag].astype(float) * gain, 0, 255).astype(np.uint8)).resize((560, 400), Image.NEAREST)
            d = ImageDraw.Draw(t)
            d.rectangle([0, 0, 559, 14], fill=(0, 0, 0))
            d.text((4, 2), f"{tag} s5 720p x 620-760, y 10-110, 4x" + (", contrast x2.5" if gain > 1 else ""), fill=(230, 230, 230))
            tiles.append(t)
    sheet = Image.new("RGB", (560 * 3 + 8, 800 + 4), (255, 0, 255))
    for i, t in enumerate(tiles):
        sheet.paste(t, ((i % 3) * 564, (i // 3) * 404))
    sheet.save(os.path.join(S, "crops", "m1-luminaire-box-r9-r10-r11-s5-4x.png"))
    json.dump(out, open(os.path.join(S, "luminaire-check.json"), "w"), indent=1)
    print(json.dumps({t: {k: {kk: v for kk, v in r.items() if kk not in ("box_edge_profile_x655_668",)} for k, r in rows.items()} for t, rows in out.items()}, indent=1))


if __name__ == "__main__":
    main()
