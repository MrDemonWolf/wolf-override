"""Typesets the approved sign and stencil marks (REAL-LOOK section 8 list; every one still
'proposed, awaiting Nathanial') as coverage masks registered to the portal canvases. No image tool
draws any letter: the glyphs come from the game's bundled Roboto (OFL), stencil bridges are cut by
script. Writes design/text/.

Marks used at the door end (everything else on the list is left off to keep the view calm):
  SECTOR 4B   stencil, 37875 white on the concrete bulkhead, high, 12 world px cap height
  DOOR 4B-07  stencil, 37875 white on the fixed hood (does not scroll with the slats); the hood is
              72 px wide, so the cap height is the largest that fits with a 3 px margin (>= 8 px)
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage  # noqa: F401  (optional; falls back below)

sys.path.insert(0, os.path.dirname(__file__))

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
OUT = os.path.join(ROOT, "text")
FONT = os.path.abspath(os.path.join(ROOT, "..", "game-main", "apps", "game", "assets", "fonts", "Roboto-Variable.ttf"))
PPW = 4.0
CANVAS_X0, CANVAS_Y0, CW, CH = 646.0, 140.0, 820, 1230
CAP = 0.711  # Roboto cap height / em


def font(px_cap: float, condensed: bool) -> ImageFont.FreeTypeFont:
    size = max(4, int(round(px_cap / CAP)))
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_axes([700, 75 if condensed else 100])
    return f


def glyph_run(text: str, cap_src: float, condensed: bool, tracking: float = 0.06) -> np.ndarray:
    """Coverage of the text at source resolution, cropped to the cap box, with stencil bridges."""
    f = font(cap_src, condensed)
    pad = int(cap_src)
    w = int(f.getlength(text) * 1.3) + 2 * pad
    h = int(cap_src * 2.2) + 2 * pad
    img = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(img)
    x = pad
    for ch in text:
        d.text((x, pad), ch, font=f, fill=255)
        x += f.getlength(ch) + tracking * cap_src
    a = np.asarray(img, dtype=np.float64) / 255.0
    rows = np.nonzero(a.max(1) > 0.5)[0]
    cols = np.nonzero(a.max(0) > 0.5)[0]
    a = a[rows.min():rows.max() + 1, cols.min():cols.max() + 1]
    return bridges(a, cap_src)


def bridges(a: np.ndarray, cap_src: float) -> np.ndarray:
    """Cuts stencil bridges: every enclosed counter (O, B, D, R, 4, 0...) gets a vertical tie cut
    from the counter to the glyph's outer edge, top and bottom, so the stencil plate would hold."""
    solid = a > 0.5
    bg = ~solid
    lab, n = ndimage.label(bg)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    out = a.copy()
    bw = max(1, int(round(cap_src * 0.07)))
    for k in range(1, n + 1):
        if k in border:
            continue
        ys, xs = np.nonzero(lab == k)
        cx = int(round(xs.mean()))
        # cut up from the counter's top and down from its bottom at the counter's centre column
        top, bot = ys.min(), ys.max()
        for y in range(top, -1, -1):
            if not solid[y, cx]:
                if y < top:
                    break
            out[y, cx - bw // 2: cx - bw // 2 + bw] = 0.0
        for y in range(bot, a.shape[0]):
            if not solid[y, cx]:
                if y > bot:
                    break
            out[y, cx - bw // 2: cx - bw // 2 + bw] = 0.0
    return out


def place(canvas: np.ndarray, run: np.ndarray, cx_world: float, top_world: float) -> list:
    h, w = run.shape
    x0 = int(round((cx_world - CANVAS_X0) * PPW - w / 2))
    y0 = int(round((top_world - CANVAS_Y0) * PPW))
    canvas[y0:y0 + h, x0:x0 + w] = np.maximum(canvas[y0:y0 + h, x0:x0 + w], run)
    return [CANVAS_X0 + x0 / PPW, top_world, CANVAS_X0 + (x0 + w) / PPW, top_world + h / PPW]


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    frame = np.zeros((CH, CW))
    front = np.zeros((CH, CW))
    marks = []
    run = glyph_run("SECTOR 4B", 12 * PPW, condensed=False)
    box = place(frame, run, 759.0, 176.0)
    marks.append({"text": "SECTOR 4B", "layer": "frame", "kind": "stencil", "paint": "37875 lusterless white", "cap_world_px": 12.0,
                  "box_world": box, "status": "proposed, awaiting Nathanial"})
    hood_w = 72.0 - 2 * 3.0
    cap = 12.0
    while cap > 8.0:
        r = glyph_run("DOOR 4B-07", cap * PPW, condensed=True)
        if r.shape[1] / PPW <= hood_w and r.shape[0] / PPW <= 15.0 - 3.0:
            break
        cap -= 0.25
    r = glyph_run("DOOR 4B-07", cap * PPW, condensed=True)
    box = place(front, r, 780.0, 304.0 + (15.0 - r.shape[0] / PPW) / 2 - 0.4)
    marks.append({"text": "DOOR 4B-07", "layer": "front", "kind": "stencil", "paint": "37875 lusterless white", "cap_world_px": round(r.shape[0] / PPW, 2),
                  "box_world": box, "status": "proposed, awaiting Nathanial",
                  "note": "the hood is 72 px wide, so the 12 px size in section 8 does not fit; this is the largest that does"})
    for name, arr in (("frame", frame), ("front", front)):
        Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(os.path.join(OUT, f"text-{name}.png"))
    with open(os.path.join(OUT, "spec.json"), "w") as f:
        json.dump({"font": "Roboto Variable (game's bundled copy, OFL), weight 700", "canvas": {"world_box": [CANVAS_X0, CANVAS_Y0, CANVAS_X0 + CW / PPW, CANVAS_Y0 + CH / PPW], "px_per_world": PPW}, "marks": marks}, f, indent=1)
    print(json.dumps(marks, indent=1))


if __name__ == "__main__":
    main()
