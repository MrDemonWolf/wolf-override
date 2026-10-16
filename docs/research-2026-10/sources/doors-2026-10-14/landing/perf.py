"""Per-state budget table, before (main) against after (the doors), from the capture driver's _run.json
(perf rows at 1280x720: draw calls p50 and max, objects, texture memory, visible additive items).
usage: perf.py BEFORE_RUN_JSON AFTER_RUN_JSON
"""
import json
import sys

before = {r["slug"]: r for r in json.load(open(sys.argv[1]))["perf"]}
after = {r["slug"]: r for r in json.load(open(sys.argv[2]))["perf"]}
print("| State | Draw calls p50 (max), main -> doors | Objects p50 | Additive items (room) | Texture MB |")
print("|---|---|---|---|---|")
for slug in after:
    a = after[slug]
    b = before.get(slug)
    if b is None:
        print("| %s | (no main frame) -> %d (%d) | %d | %d (%d) | %.2f |" % (
            slug, a["draw_calls_p50"], a["draw_calls_max"], a["objects_p50"], a["additive_visible"], a["additive_visible_room"], a["texture_mem_mb"]))
        continue
    print("| %s | %d (%d) -> %d (%d) | %d -> %d | %d (%d) -> %d (%d) | %.2f -> %.2f |" % (
        slug, b["draw_calls_p50"], b["draw_calls_max"], a["draw_calls_p50"], a["draw_calls_max"], b["objects_p50"], a["objects_p50"],
        b["additive_visible"], b["additive_visible_room"], a["additive_visible"], a["additive_visible_room"], b["texture_mem_mb"], a["texture_mem_mb"]))
