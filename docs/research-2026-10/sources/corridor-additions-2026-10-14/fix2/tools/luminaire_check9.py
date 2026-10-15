"""Round 9: MUST 2's check, as the real review measured it (REVIEW-real-r2.md item 2): on the clean
1280x720 frames of route A (s1, s5), the luminaire's lit diffuser span and centre, the wall pool's
column profile (rows y 62-100: centroid and peak) and the wet-floor reflection streak's peak (rows
y 560-680), each between screen x 600 and 800, for round 8 (raw8/add) and round 9 (raw9/add).
Pass: pool and streak peaks within +-5 px of the fitting's centre.
Also: the stray streak by the safe point (rows 630-700, below the new wall, x 1140-1240): max over median of the
column profile. Writes add7/shots/luminaire-check.json and a marked crop per round."""
import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

S = "scratchpad/real-slice/add7/shots"
LUM = np.array([0.2126, 0.7152, 0.0722])
RUNS = {"round8": os.path.join(S, "raw8", "add", "A-720"), "round9": os.path.join(S, "raw9", "add", "A-720")}


def prof(Y, y0, y1, x0, x1, k=7):
    return ndimage.uniform_filter1d(Y[y0:y1, x0:x1].mean(0), k)


def main():
    out = {}
    for tag, d in RUNS.items():
        out[tag] = {}
        for slug in ("s1-door-end-rest", "s5-door-open", "s7-safe-point"):
            im = np.asarray(Image.open(os.path.join(d, slug + "-clean.png")).convert("RGB")).astype(float)
            Y = im @ LUM
            row = {}
            if slug != "s7-safe-point":
                # the diffuser: the brightest compact run in rows 40-60 between x 640 and 760
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
                row = {"diffuser_x": [x0, x1], "fitting_centre": c, "pool_centroid": round(pool_c, 1), "pool_peak": pool_pk, "floor_streak_peak": fl_pk,
                       "pool_peak_off": round(pool_pk - c, 1), "pool_centroid_off": round(pool_c - c, 1), "floor_peak_off": round(fl_pk - c, 1),
                       "pass": abs(pool_pk - c) <= 5 and abs(fl_pk - c) <= 5}
                if slug == "s5-door-open":
                    vis = Image.fromarray(im.astype(np.uint8)).crop((560, 0, 840, 720))
                    dr = ImageDraw.Draw(vis)
                    for x, col in ((c, (0, 255, 255)), (pool_pk, (255, 210, 0)), (fl_pk, (255, 120, 0))):
                        dr.line([(x - 560, 0), (x - 560, 720)], fill=col, width=1)
                    dr.rectangle([0, 0, 280, 14], fill=(0, 0, 0))
                    dr.text((3, 2), f"{tag}: cyan fit {c:.1f} | yellow pool {pool_pk} | orange floor {fl_pk}", fill=(230, 230, 230))
                    vis.resize((560, 1440), Image.NEAREST).save(os.path.join(S, "crops", f"m2-luminaire-profile-{tag}-2x.png"))
            p = prof(Y, 630, 700, 1140, 1240, 9)   # below the new wall face
            row["stray_zone_s_max_over_median"] = round(float(p.max() / np.median(p)), 3)
            row["stray_zone_peak_x"] = int(1140 + np.argmax(p))
            out[tag][slug] = row
    json.dump(out, open(os.path.join(S, "luminaire-check.json"), "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
