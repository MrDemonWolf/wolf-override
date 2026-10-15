"""Builds the edit targets and paint maps for the Codex paint jobs (scratch only).

Target framing for every job: world x 400..664, y 122..518 (the design canvas plus room context),
1024 x 1536 px (3.8788 px per world px). The room plates and props are composited as context and
marked BLACK (leave unchanged); the construction layers are WHITE (paint these).

usage: codex_inputs.py sealed|blown
  sealed: wall + leaf + alcove + front, flat design renders, over the room
  blown:  the cleaned (painted) sealed layers where the blown state shares them, plus the flat
          hole, damage, lying, leafbreak and cracks layers to paint
"""
from __future__ import annotations

import os
import shutil
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import jmodel as M  # noqa: E402
import preview as P  # noqa: E402

TX0, TY0, TX1, TY1 = 400.0, 122.0, 664.0, 518.0
TW, TH = 1024, 1536
S = P.S  # 4 px per world px in the room composite


def to_target(img4: Image.Image) -> Image.Image:
    return img4.crop((int(TX0 * S), int(TY0 * S), int(TX1 * S), int(TY1 * S))).resize((TW, TH), Image.Resampling.LANCZOS)


# Soft designed gradients (soot, dust) are not painted by the image tool: the cleanup composites
# them from the design. They are left out of the paint maps.
SOFT_PARTS = {"damage": ["soot"], "lying": ["dust_film"]}


def layer_alpha_world(path: str) -> Image.Image:
    """A layer's alpha placed on the room-sized (S px per world px) canvas, without its soft parts."""
    im = Image.open(path).convert("RGBA")
    al = np.asarray(im.getchannel("A")).astype(np.float64)
    base = os.path.basename(path)
    layer = base[len("design-"):-4] if base.startswith("design-") else base[:-4]
    for part in SOFT_PARTS.get(layer, []):
        mp = os.path.join(M.WORK, "design", "masks", f"{layer}--{part}.png")
        if os.path.exists(mp):
            soft = np.asarray(Image.open(mp)).astype(np.float64)
            others = np.zeros_like(al)
            for f in os.listdir(os.path.join(M.WORK, "design", "masks")):
                if f.startswith(f"{layer}--") and f[len(layer) + 2:-4] not in SOFT_PARTS[layer] + ["ALPHA", "contact_shadow"]:
                    others = np.maximum(others, np.asarray(Image.open(os.path.join(M.WORK, "design", "masks", f))).astype(np.float64))
            al = np.where(others > 8, al, np.minimum(al, 0))
    a = Image.new("L", (960 * S, 640 * S), 0)
    a.paste(Image.fromarray(np.clip(al, 0, 255).astype(np.uint8)), (int(M.CV.x0 * S), int(M.CV.y0 * S)))
    return a


def build(job: str) -> None:
    D = os.path.join(M.WORK, "design")
    F = os.path.join(M.WORK, "layers", "sealed")
    out = os.path.join(M.WORK, "..", "codex", f"junction-paint-{job}", "refs")
    os.makedirs(out, exist_ok=True)
    img = P.room()
    white = Image.new("L", img.size, 0)

    def put(path, paint=True):
        P.layer(img, path)
        if paint:
            a = layer_alpha_world(path)
            white.paste(255, (0, 0), a.point(lambda v: 255 if v > 8 else 0))

    def unpaint(path):
        a = layer_alpha_world(path)
        white.paste(0, (0, 0), a.point(lambda v: 255 if v > 8 else 0))

    if job == "sealed":
        put(os.path.join(D, "design-leaf.png"))
        put(os.path.join(D, "design-wall.png"))
        put(os.path.join(D, "design-alcove.png"))
        P.props_under(img)
        # the props sit in front of the wall: they stay as painted
        props = P.room()
        base = props.copy()
        P.props_under(props)
        diff = np.abs(np.asarray(props).astype(int) - np.asarray(base).astype(int)).sum(-1) > 0
        w = np.asarray(white).copy()
        w[diff] = 0
        white = Image.fromarray(w)
        put(os.path.join(D, "design-front.png"))
        names = [("1-edit-target-junction-door-shut.png", img), ("2-areas-to-paint.png", white)]
    elif job == "blown":
        put(os.path.join(D, "design-hole.png"))
        put(os.path.join(F, "wall.png"), paint=False)
        put(os.path.join(D, "design-damage.png"))
        put(os.path.join(F, "alcove.png"), paint=False)
        P.props_under(img)
        props = P.room()
        base = props.copy()
        P.props_under(props)
        diff = np.abs(np.asarray(props).astype(int) - np.asarray(base).astype(int)).sum(-1) > 0
        w = np.asarray(white).copy()
        w[diff] = 0
        white = Image.fromarray(w)
        put(os.path.join(F, "front.png"), paint=False)
        unpaint(os.path.join(F, "front.png"))
        put(os.path.join(D, "design-lying.png"))
        names = [("1-edit-target-junction-door-blown.png", img), ("2-areas-to-paint-blown.png", white)]
        # the breaking frame: the shut set with the breaking leaf and the cracks
        img2 = P.room()
        white2 = Image.new("L", img2.size, 0)
        P.layer(img2, os.path.join(D, "design-leafbreak.png"))
        a = layer_alpha_world(os.path.join(D, "design-leafbreak.png"))
        white2.paste(255, (0, 0), a.point(lambda v: 255 if v > 8 else 0))
        P.layer(img2, os.path.join(F, "wall.png"))
        unpaint_w = layer_alpha_world(os.path.join(F, "wall.png"))
        white2.paste(0, (0, 0), unpaint_w.point(lambda v: 255 if v > 8 else 0))
        P.layer(img2, os.path.join(D, "design-cracks.png"))
        a = layer_alpha_world(os.path.join(D, "design-cracks.png"))
        white2.paste(255, (0, 0), a.point(lambda v: 255 if v > 8 else 0))
        P.layer(img2, os.path.join(F, "alcove.png"))
        P.props_under(img2)
        P.layer(img2, os.path.join(F, "front.png"))
        white2.paste(0, (0, 0), layer_alpha_world(os.path.join(F, "front.png")).point(lambda v: 255 if v > 8 else 0))
        names += [("3-edit-target-junction-door-breaking.png", img2), ("4-areas-to-paint-breaking.png", white2)]
    else:
        raise SystemExit("job?")
    for name, im in names:
        t = to_target(im.convert("RGB") if im.mode != "L" else im)
        if im.mode == "L":  # close the hairline seams between layers (the cleanup re-imposes exact alpha)
            t = t.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
        t.save(os.path.join(out, name))
    # material reference: the approved corridor door end, painted (concrete wall, frame, column)
    ref = os.path.join(M.WORK, "ref", "s1-door-end-rest-before-after-720.png")
    if os.path.exists(ref):
        r = Image.open(ref).convert("RGB")
        pass  # the material reference is made once by hand-free crop (see NOTES), not here
    print("refs in", out)


if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else "sealed")
