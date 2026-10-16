"""Round 11 against the repainted atlas (same game copy, same driver, two render.sh runs): per frame,
how many pixels differ, the largest step, and how many differ inside the door end's hood box (world
x 690..830, y 270..345, mapped through each frame's camera). Usage: identity12.py R11_DIR R12_DIR OUT.json"""
import json, os, sys
import numpy as np
from PIL import Image

def main(a_dir, b_dir, out):
    rows = []
    for route in "OAB":
        meta = {s["slug"]: s for s in json.load(open(os.path.join(b_dir, route, "_run.json")))["shots"]}
        for f in sorted(os.listdir(os.path.join(a_dir, route))):
            if not f.endswith(".png"):
                continue
            a = np.array(Image.open(os.path.join(a_dir, route, f)).convert("RGB")).astype(int)
            b = np.array(Image.open(os.path.join(b_dir, route, f)).convert("RGB")).astype(int)
            d = np.abs(a - b).max(-1)
            slug = f.replace("-clean.png", "").replace(".png", "")
            s = meta[slug]
            cx, cy = [float(v) for v in s["camera"].strip("()").split(",")]
            k = a.shape[1] / 960.0 * float(s["zoom"])
            x0, x1 = int((690 - cx) * k + a.shape[1] / 2), int((830 - cx) * k + a.shape[1] / 2)
            y0, y1 = int((270 - cy) * k + a.shape[0] / 2), int((345 - cy) * k + a.shape[0] / 2)
            x0, x1, y0, y1 = max(0, x0), min(a.shape[1], x1), max(0, y0), min(a.shape[0], y1)
            box = int((d[y0:y1, x0:x1] > 0).sum()) if x1 > x0 and y1 > y0 else 0
            ys, xs = np.nonzero(d)
            rows.append({"frame": route + "/" + f, "identical": bool((d == 0).all()), "px": int((d > 0).sum()), "max": int(d.max()),
                         "hood_box_screen": [x0, y0, x1, y1] if x1 > x0 and y1 > y0 else None, "px_in_hood_box": box,
                         "diff_bbox": [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1] if len(xs) else None})
    json.dump(rows, open(out, "w"), indent=1)
    for r in rows:
        print(r["frame"], "identical" if r["identical"] else "px %d max %d, in hood box %d, bbox %s" % (r["px"], r["max"], r["px_in_hood_box"], r["diff_bbox"]))

if __name__ == "__main__":
    main(*sys.argv[1:4])
