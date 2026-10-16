"""The flat-shaded design layer set (design/flat7/): round 6's painted layers with the round-7 parts
drawn flat over them (design-add-wall, design-add-front) and the leaf's flat elevations, so the
construction can be checked in place before anything is painted."""
import os, shutil, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from stack import p2  # noqa
import portal7 as d7
R6 = d7.R6
D = os.path.join(os.path.dirname(__file__), "..", "design")
OUT = os.path.join(D, "flat7")
os.makedirs(OUT, exist_ok=True)
V6 = os.path.join(R6, "layers", "v6")
for f in ("portal-curtain.png", "portal-curtain-open.png", "portal-frame.png", "bypass-wheel.png", "lens.png"):
    shutil.copy(os.path.join(V6, f), os.path.join(OUT, f))
shutil.copy(os.path.join(V6, "game", "corridor-far.png"), os.path.join(OUT, "corridor-far.png"))
shutil.copy(os.path.join(V6, "game", "corridor-mid.png"), os.path.join(OUT, "corridor-mid.png"))
for n in ("wall", "front"):
    base = Image.open(os.path.join(V6, f"portal-{n}.png")).convert("RGBA")
    add = Image.open(os.path.join(D, f"design-add-{n}.png")).convert("RGBA")
    base.alpha_composite(add)
    base.save(os.path.join(OUT, f"portal-{n}.png"))
for n in ("front", "edge"):
    a = Image.open(os.path.join(D, f"design-leaf-{n}-albedo.png")).convert("RGBA")
    a.save(os.path.join(OUT, f"leaf-{n}.png"))
print("ok")
