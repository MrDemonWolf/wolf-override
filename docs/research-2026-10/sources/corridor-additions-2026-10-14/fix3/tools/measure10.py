"""Round 10 measurements on render.sh captures (clean 1280x720 frames unless noted), round 8 (raw8/add,
for the marker only), round 9 (raw9/add) and round 10 (raw10/add):
  * the cutaway: mean and spread (std) of luma over the section's poche (design masks mapped to the
    screen, eroded) in s1, s5 and s7, against the near column's end face and approach face; and at
    its foot in s7 (x 1040-1200) the wet floor 2 px and 10 px below the poche's lowest pixel;
  * the control marker at the safe point (s7, frame WITH the HUD canvas hidden is the -clean frame,
    which still draws world items): cyan marker pixels under the engineer;
  * the engineer's body box in s7: round 9 against round 10 (must be 0 px over 3 levels);
  * WOLF in s7: his world x, his drawn span against the near column, the engineer and the relay;
  * the beacons: mean red excess (R - (G+B)/2) in a 52x60 px box under each red globe in s1.
Writes add7/shots/measure10.json and crops k-marker-count-s7-*.png."""
import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

R = "scratchpad/real-slice"
S = os.path.join(R, "add7", "shots")
D10 = os.path.join(R, "add7", "fix3", "door", "design", "masks")
D6 = os.path.join(R, "design", "portal6", "masks")
LUM = np.array([0.2126, 0.7152, 0.0722])
RUNS = {"round8": os.path.join(S, "raw8", "add"), "round9": os.path.join(S, "raw9", "add"), "round10": os.path.join(S, "raw10", "add")}
WOLF_PAINTED = (-56.0, 59.0)   # WOLF's painted tail tip and nose from his x, facing right (measured on s5)


def img(tag, run, slug, clean=True):
    return np.asarray(Image.open(os.path.join(RUNS[tag], run, slug + ("-clean" if clean else "") + ".png")).convert("RGB")).astype(float)


def shot(tag, run, slug):
    for s in json.load(open(os.path.join(RUNS[tag], run, "_run.json")))["shots"]:
        if s["slug"] == slug:
            return s


def to_screen(sh, wx, wy, W=1280, H=720):
    cx, cy = (float(v) for v in sh["camera"].strip("()").split(","))
    s = float(sh["zoom"]) * W / 960.0
    return (wx - cx) * s + W / 2, (wy - cy) * s + H / 2


def mask_px(sh, path, erode, W=1280, H=720):
    m = np.asarray(Image.open(path).convert("L")) > 200
    if erode:
        m = ndimage.binary_erosion(m, iterations=erode)
    ys, xs = np.nonzero(m)
    sx, sy = to_screen(sh, 676 + (xs + 0.5) / 4, 150 + (ys + 0.5) / 4)
    sx, sy = np.round(sx).astype(int), np.round(sy).astype(int)
    ok = (sx >= 0) & (sx < W) & (sy >= 0) & (sy < H)
    out = np.zeros((H, W), bool)
    out[sy[ok], sx[ok]] = True
    return out


def stats(im, m):
    v = im[m] @ LUM
    return {"mean": round(float(v.mean()), 1), "std": round(float(v.std()), 2), "px": int(m.sum())} if v.size else None


def marker(im, sh):
    ex = float(sh["engineer_x"])
    x0, y0 = to_screen(sh, ex - 26, 437.0)
    x1, y1 = to_screen(sh, ex + 26, 450.0)
    sub = im[int(y0):int(y1), int(x0):int(x1)]
    r, g, b = sub[..., 0], sub[..., 1], sub[..., 2]
    cyan = (b - r > 45) & (g - r > 35) & (b > 80)
    return int(cyan.sum()), [int(x0), int(y0), int(x1), int(y1)]


def main():
    out = {"cutaway": {}, "marker_s7": {}, "safe_point_engineer": {}, "wolf_s7": {}, "beacons_s1": {}}
    for tag in ("round9", "round10"):
        for slug in ("s1-door-end-rest", "s5-door-open", "s7-safe-point"):
            im, sh = img(tag, "A-720", slug), shot(tag, "A-720", slug)
            sec = mask_px(sh, os.path.join(D10, "front--CUT_ALPHA.png"), 6)
            row = {"section_poche": stats(im, sec),
                   "section_face": stats(im, mask_px(sh, os.path.join(D10, "front--cut_face.png"), 6)),
                   "section_top": stats(im, mask_px(sh, os.path.join(D10, "front--cut_top.png"), 3)),
                   "column_end_face": stats(im, mask_px(sh, os.path.join(D6, "front--pier_end.png"), 6)),
                   "column_approach_frame": stats(im, mask_px(sh, os.path.join(D6, "front--frame_near_jamb.png"), 2))}
            if slug == "s7-safe-point":
                full = mask_px(sh, os.path.join(D10, "front--CUT_ALPHA.png"), 0)
                foot2, foot10 = [], []
                Y = im @ LUM
                for x in range(1040, 1201):
                    ys = np.nonzero(full[:, x])[0]
                    if ys.size and ys.max() + 10 < 720:
                        foot2.append(Y[ys.max() + 2, x])
                        foot10.append(Y[ys.max() + 10, x])
                row["floor_at_foot_2px_10px_x1040_1200"] = [round(float(np.mean(foot2)), 1), round(float(np.mean(foot10)), 1)]
            out["cutaway"].setdefault(slug, {})[tag] = row
    for tag in RUNS:
        im, sh = img(tag, "A-720", "s7-safe-point"), shot(tag, "A-720", "s7-safe-point")
        n, box = marker(im, sh)
        out["marker_s7"][tag] = {"cyan_marker_px": n, "box_xyxy": box, "engineer_x": sh["engineer_x"]}
    # the marker crop: round 8 | round 9 | round 10, 6x
    tiles = []
    for tag in RUNS:
        im = img(tag, "A-720", "s7-safe-point")
        b = out["marker_s7"][tag]["box_xyxy"]
        t = Image.fromarray(im[b[1] - 30:b[3] + 6, b[0] - 6:b[2] + 6].astype(np.uint8))
        t = t.resize((t.width * 6, t.height * 6), Image.NEAREST)
        d = ImageDraw.Draw(t)
        d.rectangle([0, 0, t.width, 14], fill=(0, 0, 0))
        d.text((3, 2), f"{tag}: {out['marker_s7'][tag]['cyan_marker_px']} marker px", fill=(230, 230, 230))
        tiles.append(t)
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + 16, max(t.height for t in tiles)), (255, 0, 255))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 8
    sheet.save(os.path.join(S, "crops", "k-marker-count-s7-r8-r9-r10-6x.png"))
    a, b = img("round9", "A-720", "s7-safe-point"), img("round10", "A-720", "s7-safe-point")
    sh = shot("round10", "A-720", "s7-safe-point")
    ex = float(sh["engineer_x"])
    x0, _ = to_screen(sh, ex - 14, 0)
    x1, _ = to_screen(sh, ex + 14, 0)
    _, y0 = to_screen(sh, 0, 375)
    _, y1 = to_screen(sh, 0, 438.6)
    box = (int(x0), int(y0), int(x1) + 1, int(y1) + 1)
    d = np.abs(a - b).max(-1)[box[1]:box[3], box[0]:box[2]]
    out["safe_point_engineer"] = {"engineer_x": ex, "screen_box_xyxy": box, "px_differing_over_3_r9_vs_r10": int((d > 3).sum()), "max_diff": int(d.max())}
    for tag in ("round9", "round10"):
        sh = shot(tag, "A-720", "s7-safe-point")
        wx, ex = float(sh["wolf_x"]), float(sh["engineer_x"])
        out["wolf_s7"][tag] = {"wolf_x": round(wx, 1), "engineer_x": round(ex, 1),
                               "painted_span": [round(wx + WOLF_PAINTED[0], 1), round(wx + WOLF_PAINTED[1], 1)],
                               "reach_span": [round(wx - 67, 1), round(wx + 67, 1)],
                               "clear_of_near_column_from_785": round(785.0 - (wx + 67), 1),
                               "clear_of_relay_to_648_1": round((wx - 67) - 648.1, 1),
                               "clear_of_relief_outlet_649_75_painted": round((wx + WOLF_PAINTED[0]) - 649.75, 1),
                               "gap_to_engineer_centres": round(ex - wx, 1),
                               "nose_in_opening_721_785": bool(721 <= wx + WOLF_PAINTED[1] <= 785)}
    for tag in ("round9", "round10"):
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
        out["beacons_s1"][tag] = rows
    json.dump(out, open(os.path.join(S, "measure10.json"), "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
