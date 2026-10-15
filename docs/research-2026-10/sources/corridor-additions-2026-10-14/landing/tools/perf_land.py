"""Per-state performance, main (before) against the landing (after): render.sh perf passes (draw calls,
additive items, overdraw estimate, full-screen translucent layers, texture and video memory, nodes) and
headless CPU frame times. Usage: perf_land.py BEFORE_RAW AFTER_RAW HEADLESS_BEFORE.json HEADLESS_AFTER.json OUT.md"""
import json, re, sys

def rows_from(path):
    out = {}
    for p in ("A-perf", "B-perf"):
        try:
            j = json.load(open("%s/%s/_run.json" % (path, p)))
        except FileNotFoundError:
            continue
        for r in j["perf"]:
            out[r["slug"]] = r
    return out

def headless(path):
    out = {}
    text = open(path).read()
    dec = json.JSONDecoder()
    i = 0
    while True:
        i = text.find("{", i)
        if i < 0:
            break
        try:
            obj, end = dec.raw_decode(text, i)
        except ValueError:
            i += 1
            continue
        for r in obj.get("perf", []):
            out[r["slug"]] = r
        i = end
    return out

def main(b, a, hb, ha, out):
    B, A, HB, HA = rows_from(b), rows_from(a), headless(hb), headless(ha)
    order = ["s1-door-end-rest", "s2-relay-wolf", "s3-bypass-crank", "s4-door-opening", "s4b-leaf-moving", "s5-door-open", "s6-walk-through", "s7-safe-point"]
    lines = ["| State | Draw calls p50 (max) | Additive items | Overdraw estimate | Full-screen translucent layers | Texture MB | Video MB | Nodes | Headless CPU frame p50 / p99 ms |",
             "|---|---|---|---|---|---|---|---|---|"]
    for s in order:
        def cell(f, fmt="%s"):
            vb, va = B.get(s, {}).get(f), A.get(s, {}).get(f)
            return "%s -> %s" % (fmt % vb if vb is not None else "-", fmt % va if va is not None else "-")
        dc = "%s (%s) -> %s (%s)" % (B.get(s, {}).get("draw_calls_p50", "-"), B.get(s, {}).get("draw_calls_max", "-"), A.get(s, {}).get("draw_calls_p50", "-"), A.get(s, {}).get("draw_calls_max", "-"))
        cpu = "%.2f / %.2f -> %.2f / %.2f" % (HB.get(s, {}).get("frame_ms_p50", float("nan")), HB.get(s, {}).get("frame_ms_p99", float("nan")), HA.get(s, {}).get("frame_ms_p50", float("nan")), HA.get(s, {}).get("frame_ms_p99", float("nan")))
        lines.append("| %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (s, dc, cell("additive_items_on_screen"), cell("overdraw_estimate", "%.2f"), cell("fullscreen_translucent_layers"), cell("texture_mem_mb", "%.2f"), cell("video_mem_mb", "%.2f"), cell("nodes", "%d"), cpu))
    open(out, "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))

if __name__ == "__main__":
    main(*sys.argv[1:6])
