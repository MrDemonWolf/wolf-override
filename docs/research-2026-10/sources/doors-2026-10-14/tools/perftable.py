"""Fix round 4: the per-state budget from two render.sh runs (the driver's perf rows): draw calls (p50, max),
visible additive items in the room, texture memory. usage: perftable.py BEFORE_DIR AFTER_DIR OUT_MD [ROUND3_DIR]"""
import json
import sys

b = {r["slug"]: r for r in json.load(open(sys.argv[1] + "/_run.json"))["perf"]}
a = {r["slug"]: r for r in json.load(open(sys.argv[2] + "/_run.json"))["perf"]}
r2 = {r["slug"]: r for r in json.load(open(sys.argv[4] + "/_run.json"))["perf"]} if len(sys.argv) > 4 else {}
lines = ["| State | Draw calls p50, main → round 4 | max, main → round 4 | Additive (room), main → round 4 | Texture MB, main → round 4 (round 3) |", "|---|---|---|---|---|"]
worst = {"dc": 0, "add": 0, "tex": -99.0}
for slug in a:
    if slug not in b:
        continue
    x, y = b[slug], a[slug]
    t2 = f" ({r2[slug]['texture_mem_mb']:.2f})" if slug in r2 else ""
    lines.append(f"| {slug} | {x['draw_calls_p50']} → {y['draw_calls_p50']} | {x['draw_calls_max']} → {y['draw_calls_max']} | {x['additive_visible_room']} → {y['additive_visible_room']} | {x['texture_mem_mb']:.2f} → {y['texture_mem_mb']:.2f}{t2} |")
    worst["dc"] = max(worst["dc"], y["draw_calls_max"] - x["draw_calls_max"], y["draw_calls_p50"] - x["draw_calls_p50"])
    worst["add"] = max(worst["add"], y["additive_visible_room"] - x["additive_visible_room"])
    worst["tex"] = max(worst["tex"], y["texture_mem_mb"] - x["texture_mem_mb"])
lines += ["", f"Largest change over main in any state: draw calls {worst['dc']:+d}, additive items {worst['add']:+d}, texture memory {worst['tex']:+.2f} MB."]
open(sys.argv[3], "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
