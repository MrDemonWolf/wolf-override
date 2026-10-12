"""Render Option A's runtime layers (as Godot would draw them) to PNG at 4 px per world px."""
import json, os, sys
PLAIN = os.environ.get("A_PLAIN") == "1"   # revision 2: blank plates and a blank keypad backplate
from PIL import Image
import geom

OUT = sys.argv[1]
geom.FONT = sys.argv[2]
os.makedirs(OUT, exist_ok=True)
SS = 8   # supersample, then halve to 4 px per world px
REG = (15, 315, 225, 450)
LEAF_REG = (112, 350, 202, 438)
manifest = {}


def save(name, P, reg):
    im = P.im.resize((P.w // 2, P.h // 2), Image.LANCZOS)
    im.save(os.path.join(OUT, name + ".png"))
    manifest[name] = {"x": reg[0], "y": reg[1], "scale": 0.25}


for st in ["standby", "wake", "swing", "released"]:
    P = geom.Painter(*REG, SS)
    geom.paint_back(P, {"dock": "amber" if st == "standby" else "blue",
                        "umb": {"standby": "docked", "wake": "docked", "swing": "swing", "released": "released"}[st]})
    save("back_" + st, P, REG)
P = geom.Painter(*REG, SS); geom.paint_frame(P); save("frame", P, REG)
for st, torn in [("intact", False), ("torn", True)]:
    P = geom.Painter(*LEAF_REG, SS); geom.paint_leaf(P, torn); save("leaf_" + st, P, LEAF_REG)
for st, d in [("locked", {"lamp": "green"}), ("forced", {"lamp": "amber", "bolt_exposed": True}),
              ("forced_off", {"lamp": "off", "bolt_exposed": True})]:
    d = dict(d, text=not PLAIN, keypad=not PLAIN)
    P = geom.Painter(*REG, SS); geom.paint_top(P, d); save("top_" + st, P, REG)
P = geom.Painter(-6, -9, 6, 9, SS); geom.paint_keeper(P, 0, 0, 0); save("keeper", P, (-6, -9))
for name, rx, ry, col, peak in [("glow_blue", 34, 26, "#3aa0ff", 0.42), ("glow_red", 7, 7, "#ff3020", 0.75), ("glow_green", 7, 7, "#30e070", 0.6), ("glow_amber", 8, 8, "#ffa010", 0.85)]:
    im = geom.glow(rx, ry, col, peak, 4)
    im.save(os.path.join(OUT, name + ".png"))
    manifest[name] = {"w": rx * 2, "h": ry * 2, "scale": 0.25}
json.dump(manifest, open(os.path.join(OUT, "manifest.json"), "w"), indent=1)
print("layers", len(manifest))
