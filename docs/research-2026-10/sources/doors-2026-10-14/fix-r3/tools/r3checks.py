"""Fix round 3: the review r3 items measured on render.sh frames, same boxes for every run (scratch only).
usage: r3checks.py FRAMES_DIR [OUT_JSON]   (1280x720 frames; boxes in screen px as the reviews gave them)

  ending      engineer and WOLF x in j12 (at the door) and j13 (the closing shot, after one USE): the engineer
              must not step back toward the bolt panel (human r3 must-fix: 849 -> 747 on round 2)
  violet      pixels with b-g > 20 and r-g > 8 round the exit door in j08-j10 (x 1040-1200, y 280-520)
              (review r3 R3-1: 84, 84, 24 on round 2)
  header      near-white pixels (min channel > 170) at the junction entry's header, r09 x 150-300 y 90-230,
              and in j04 at the same place (review r3 R3-3: the 37 x 8 lens and the 29 x 5 smear)
  battens     the brightest pixel and the near-white count of the passage battens at the screen edges:
              r01 x 0-80 y 240-265, r04 x 1195-1280 y 240-265 (human r3)"""
import json
import os
import sys

import numpy as np
from PIL import Image


def rgb(fr, slug):
    p = os.path.join(fr, f"{slug}-clean.png")
    return np.asarray(Image.open(p).convert("RGB")).astype(int) if os.path.exists(p) else None


def main():
    fr = sys.argv[1]
    run = json.load(open(os.path.join(fr, "_run.json")))
    by = {s["slug"]: s for s in run["shots"]}
    out = {"ending": {k: {"engineer_x": round(by[k]["engineer_x"], 1), "wolf_x": round(by[k]["wolf_x"], 1), "beat": by[k]["beat"]} for k in ("j12-at-the-door", "j13-closing-shot") if k in by}}
    out["violet"] = {}
    for slug in ("j08-exit-bolt", "j09-bolt-whine", "j10-hatch-opening"):
        a = rgb(fr, slug)
        if a is None:
            continue
        r = a[280:520, 1040:1200]
        out["violet"][slug] = int(((r[..., 2] - r[..., 1] > 20) & (r[..., 0] - r[..., 1] > 8)).sum())
    out["header_white"] = {}
    for slug in ("r09-after-leaving", "r10-entry-closing", "r11-entry-shut", "j01-sealed", "j04-blown"):
        a = rgb(fr, slug)
        if a is None:
            continue
        r = a[90:230, 150:300]
        out["header_white"][slug] = int((r.min(-1) > 170).sum())
    out["battens"] = {}
    for slug, (x0, x1) in (("r01-arrival", (0, 80)), ("r03-arrival-closed", (0, 80)), ("r04-copy-point", (1195, 1280)), ("r07-exit-open", (1195, 1280))):
        a = rgb(fr, slug)
        if a is None:
            continue
        r = a[240:265, x0:x1]
        out["battens"][slug] = {"max_rgb": r.reshape(-1, 3)[r.sum(-1).argmax()].tolist(), "near_white_px": int((r.min(-1) > 200).sum())}
    print(json.dumps(out, indent=1))
    if len(sys.argv) > 2:
        json.dump(out, open(sys.argv[2], "w"), indent=1)


if __name__ == "__main__":
    main()
