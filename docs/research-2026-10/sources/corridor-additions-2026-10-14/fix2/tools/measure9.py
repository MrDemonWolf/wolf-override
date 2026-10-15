"""Round 9 measurements on render.sh captures (clean 1280x720 frames), round 8 (raw8/add) vs round 9
(raw9/add):
  * the cut section: mean luma of its corridor face and its top (design masks mapped to the screen,
    eroded 6 CVD px) in s1, s5 and s7, against the near column's end face and approach face;
  * the safe point: the engineer's body box in s7 (engineer_x from the run) must not differ between
    round 8 and round 9 except where WOLF/UI do not reach (boots whole: max diff in the box rows
    above y 505);
  * the relief spray in s3 (route B): its zone's mean and p90 luma;
  * the beacons: mean red excess (R - (G+B)/2) in a 52x60 px box under each red globe in s1.
Writes add7/shots/measure9.json."""
import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

R = "scratchpad/real-slice"
S = os.path.join(R, "add7", "shots")
D9 = os.path.join(R, "add7", "fix2", "door", "design", "masks")
D6 = os.path.join(R, "design", "portal6", "masks")
LUM = np.array([0.2126, 0.7152, 0.0722])
RUNS = {"round8": os.path.join(S, "raw8", "add"), "round9": os.path.join(S, "raw9", "add")}


def img(tag, run, slug):
    return np.asarray(Image.open(os.path.join(RUNS[tag], run, slug + "-clean.png")).convert("RGB")).astype(float)


def shot(tag, run, slug):
    for s in json.load(open(os.path.join(RUNS[tag], run, "_run.json")))["shots"]:
        if s["slug"] == slug:
            return s


def to_screen(sh, wx, wy, W=1280, H=720):
    cx, cy = (float(v) for v in sh["camera"].strip("()").split(","))
    s = float(sh["zoom"]) * W / 960.0
    return (wx - cx) * s + W / 2, (wy - cy) * s + H / 2


def mask_lum(im, sh, path, erode=6):
    m = ndimage.binary_erosion(np.asarray(Image.open(path).convert("L")) > 200, iterations=erode)
    ys, xs = np.nonzero(m)
    sx, sy = to_screen(sh, 676 + (xs + 0.5) / 4, 150 + (ys + 0.5) / 4)
    sx, sy = np.round(sx).astype(int), np.round(sy).astype(int)
    ok = (sx >= 0) & (sx < im.shape[1]) & (sy >= 0) & (sy < im.shape[0])
    v = im[sy[ok], sx[ok]] @ LUM
    return round(float(v.mean()), 1) if v.size else None


def main():
    out = {"cut_section": {}, "safe_point_engineer": {}, "relief_spray": {}, "beacons": {}}
    for tag in RUNS:
        for slug in ("s1-door-end-rest", "s5-door-open", "s7-safe-point"):
            im, sh = img(tag, "A-720", slug), shot(tag, "A-720", slug)
            row = {"column_end_face": mask_lum(im, sh, os.path.join(D6, "front--pier_end.png")),
                   "column_approach_frame": mask_lum(im, sh, os.path.join(D6, "front--frame_near_jamb.png"), 2)}
            if tag == "round9":
                row["section_face"] = mask_lum(im, sh, os.path.join(D9, "front--cut_face.png"))
                row["section_top"] = mask_lum(im, sh, os.path.join(D9, "front--cut_top.png"), 3)
            else:
                row["curb_face"] = mask_lum(im, sh, os.path.join(D6, "front--stub_face.png"), 3)
                row["curb_top"] = mask_lum(im, sh, os.path.join(D6, "front--stub_top.png"), 3)
            out["cut_section"].setdefault(slug, {})[tag] = row
    # the engineer at the safe point: round 8 vs round 9 inside their sprite box
    a, b = img("round8", "A-720", "s7-safe-point"), img("round9", "A-720", "s7-safe-point")
    sh = shot("round9", "A-720", "s7-safe-point")
    ex = float(sh["engineer_x"])
    x0, _ = to_screen(sh, ex - 14, 0)
    x1, _ = to_screen(sh, ex + 14, 0)
    _, y0 = to_screen(sh, 0, 375)
    _, y1 = to_screen(sh, 0, 438.6)   # down to the soles (438.3)
    box = (int(x0), int(y0), int(x1) + 1, int(y1) + 1)
    d = np.abs(a - b).max(-1)[box[1]:box[3], box[0]:box[2]]
    out["safe_point_engineer"] = {"engineer_x": ex, "screen_box_xyxy": box, "px_differing_over_3": int((d > 3).sum()), "max_diff": int(d.max())}
    # the relief spray (route B, s3), zone round the outlet (649.75, 422.25) to the floor
    for tag in RUNS:
        im, sh = img(tag, "B-720", "s3-bypass-crank"), shot(tag, "B-720", "s3-bypass-crank")
        x0, y0 = to_screen(sh, 644.0, 421.0)
        x1, y1 = to_screen(sh, 656.0, 441.0)
        z = im[int(y0):int(y1), int(x0):int(x1)] @ LUM
        out["relief_spray"][tag] = {"zone_mean": round(float(z.mean()), 1), "zone_p90": round(float(np.percentile(z, 90)), 1), "zone_max": round(float(z.max()), 1)}
    # the beacons: red excess under each globe in s1
    for tag in RUNS:
        im = img(tag, "A-720", "s1-door-end-rest")
        r, g, bl = im[..., 0], im[..., 1], im[..., 2]
        lab, n = ndimage.label((r > 120) & (r - g > 70) & (r - bl > 70))
        cents = []
        for i in range(1, n + 1):
            ys, xs = np.nonzero(lab == i)
            if len(xs) >= 4 and ys.mean() < 260 and all(abs(xs.mean() - c[0]) > 30 for c in cents):
                cents.append((xs.mean(), ys.mean()))
        rows = []
        for gx, gy in sorted(cents)[:2]:
            bx = im[int(gy + 8):int(gy + 68), int(gx - 26):int(gx + 26)]
            ex_ = bx[..., 0] - (bx[..., 1] + bx[..., 2]) / 2
            rows.append({"globe_screen": [round(gx, 1), round(gy, 1)], "red_excess_mean_below": round(float(ex_.mean()), 2)})
        out["beacons"][tag] = rows
    json.dump(out, open(os.path.join(S, "measure9.json"), "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
