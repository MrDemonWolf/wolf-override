"""Bake each layer/state of the Option B spec into small textures (scratch), to measure what a
texture-based build costs to draw. Textures are 4 texels per world px; offsets in world px."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(__file__))
import render_lib as R

spec = R.load(sys.argv[1]); out = sys.argv[2]; fontp = sys.argv[3]
os.makedirs(out, exist_ok=True)
K = 4
EPS = 0.0011
jobs = {
    "back_p0": ("back", 0, 0.0, lambda p: True),
    "back_p1": ("back", 1, 0.0, lambda p: True),
    "front_static": ("front", 0, 0.0, lambda p: p["cond"] == "always"),
    "front_p0": ("front", 0, 0.0, lambda p: p["cond"] != "always"),
    "front_p1": ("front", 1, 0.0, lambda p: p["cond"] != "always"),
    "front_open": ("front", 2, EPS, lambda p: p["cond"] != "always"),
    "leaf_body": ("leaf", 0, 0.0, lambda p: p["g"] == "leaf" and p["cond"] == "always"),
    "leaf_open": ("leaf", 2, EPS, lambda p: p["g"] == "leaf" and p["cond"] == "open"),
    "keeper_on": ("leaf", 0, 0.0, lambda p: p["g"] == "static" and p["cond"] == "closed"),
    "keeper_fall": ("leaf", 2, EPS, lambda p: p["g"] == "keeper_fall"),
    "bolt": ("leaf", 0, 0.0, lambda p: p["g"] == "static" and p["cond"] == "always"),
}
man = {}
total = 0
for name, (layer, ph, op, keep) in jobs.items():
    t = time.time()
    view = (20, 305, 216, 452)
    cv = R.Canvas(view, K, ss=2)
    R.draw_prims(cv, spec, ph, op, fontp, keep=lambda p, keep=keep, layer=layer: p["layer"] == layer and keep(p))
    im = cv.result()
    bb = im.getbbox()
    if bb is None:
        continue
    bb = (max(bb[0] - 2, 0), max(bb[1] - 2, 0), min(bb[2] + 2, im.width), min(bb[3] + 2, im.height))
    im = im.crop(bb)
    im.save(os.path.join(out, name + ".png"))
    man[name] = {"pos": [view[0] + bb[0] / K, view[1] + bb[1] / K], "size": [im.width / K, im.height / K], "px": [im.width, im.height]}
    total += im.width * im.height * 4
    print(name, im.size, round(time.time() - t, 1), "s")
man["_texels_per_px"] = K
man["_bytes_rgba"] = total
json.dump(man, open(os.path.join(out, "bake.json"), "w"), indent=1)
print("total RGBA bytes", total)
