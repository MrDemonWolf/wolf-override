"""Landing comparisons from render.sh stills (land-corridor/raw/<run>/<route>/):
  opening  before (main) against after, o0-o8: differing pixels in all, outside the two beacon zones
           (world +-60 px round each beacon), and left of world x 540 outside them.
  sheets   side-by-side PNGs: before | after for every state, and approved round 11 | after.
Usage: compare_land.py BEFORE AFTER ROUND11_DIR OUT_DIR (ROUND11_DIR holds A-720, B-720, O-720)."""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

BEACONS = [(327.36, 224.3), (632.64, 224.3)]

def load(p):
    return np.array(Image.open(p).convert("RGB")).astype(int)

def cam(meta, slug):
    s = meta[slug]
    cx, cy = [float(v) for v in s["camera"].strip("()").split(",")]
    return cx, cy, float(s["zoom"])

def world_to_screen(x, y, cx, cy, z, w, h):
    k = h / 540.0 * z
    return (x - cx) * k + w / 2, (y - cy) * k + h / 2, k

def opening(before, after):
    rows = []
    mb = {s["slug"]: s for s in json.load(open(os.path.join(before, "O", "_run.json")))["shots"]}
    for f in sorted(os.listdir(os.path.join(before, "O"))):
        if not f.endswith(".png"):
            continue
        a, b = load(os.path.join(before, "O", f)), load(os.path.join(after, "O", f))
        d = np.abs(a - b).max(-1) > 3
        h, w = d.shape
        cx, cy, z = cam(mb, f[:-4])
        zone = np.zeros_like(d)
        for bx, by in BEACONS:
            sx, sy, k = world_to_screen(bx, by, cx, cy, z, w, h)
            r = int(60 * k)
            zone[max(0, int(sy) - r):int(sy) + r, max(0, int(sx) - r):int(sx) + r] = True
        x540 = int(world_to_screen(540, 0, cx, cy, z, w, h)[0])
        left = np.zeros_like(d)
        left[:, :max(0, min(w, x540))] = True
        rows.append({"frame": f, "px_over_3": int(d.sum()), "outside_beacons": int((d & ~zone).sum()),
                     "left_of_540_outside_beacons": int((d & ~zone & left).sum()), "screen_x_of_world_540": x540})
    return rows

def pair(paths, labels, out, scale=0.5):
    ims = [Image.open(p).convert("RGB") for p in paths]
    ims = [im.resize((int(im.width * scale), int(im.height * scale))) for im in ims]
    W = sum(im.width for im in ims) + 8 * (len(ims) - 1)
    H = max(im.height for im in ims) + 22
    sheet = Image.new("RGB", (W, H), (20, 20, 22))
    draw = ImageDraw.Draw(sheet)
    x = 0
    for im, lab in zip(ims, labels):
        sheet.paste(im, (x, 22))
        draw.text((x + 4, 4), lab, fill=(230, 230, 230))
        x += im.width + 8
    sheet.save(out)

def main(before, after, r11, out):
    os.makedirs(out, exist_ok=True)
    res = {"opening": opening(before, after)}
    for route in "OAB":
        for f in sorted(os.listdir(os.path.join(after, route))):
            if not f.endswith(".png"):
                continue
            bp = os.path.join(before, route, f)
            if os.path.exists(bp):
                pair([bp, os.path.join(after, route, f)], ["main (before)", "landed (after)"], os.path.join(out, "pair-%s-%s" % (route, f)))
            if r11:
                rp = os.path.join(r11, route + "-720", f)
                if os.path.exists(rp):
                    pair([rp, os.path.join(after, route, f)], ["approved round 11", "landed (after)"], os.path.join(out, "approved-%s-%s" % (route, f)))
    json.dump(res, open(os.path.join(out, "compare.json"), "w"), indent=1)
    for r in res["opening"]:
        print(r)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3] if sys.argv[3] != "-" else "", sys.argv[4])
