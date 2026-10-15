"""Round 8 (add7 fix round 1; adapted from integrate/tools/perf_table7.py): the render-monitor table
(render.sh, 1280x720, 300 uncapped frames per held state) and the CPU-side headless table.
Main, round 6 and round 8 are this round's runs with the round-8 driver (add7/shots/raw8/{main,r6,add});
round 7 is its own run (add7/shots/raw7/add), whose s3 row mostly measured the seal opening.
Writes add7/shots/perf.json and add7/shots/perf-table.md."""
import json
import os

R = "scratchpad/real-slice"
S = os.path.join(R, "add7", "shots")
ORDER = ["s1-door-end-rest", "s2-relay-wolf", "s3-bypass-crank", "s4-door-opening", "s4b-leaf-moving", "s5-door-open", "s6-walk-through", "s7-safe-point"]


def load(dirs):
    rows = {}
    for d in dirs:
        p = os.path.join(d, "_run.json")
        if os.path.exists(p):
            for row in json.load(open(p))["perf"]:
                rows.setdefault(row["slug"], row)
    return rows


main = load([os.path.join(S, "raw8", "main", r) for r in ("A-720-perf", "B-720-perf")])
r6 = load([os.path.join(S, "raw8", "r6", r) for r in ("A-720-perf", "B-720-perf")])
r7 = load([os.path.join(S, "raw7", "add", r) for r in ("A-720-perf", "B-720-perf")])
r8 = load([os.path.join(S, "raw8", "add", r) for r in ("A-720-perf", "B-720-perf")])
head = {c: load([os.path.join(S, "raw8", c, r) for r in ("A-headless", "B-headless")]) for c in ("main", "r6", "add")}
json.dump({"main": main, "round6": r6, "round7": r7, "round8": r8, "headless": head}, open(os.path.join(S, "perf.json"), "w"), indent=1)
ALL = (main, r6, r7, r8)


def cell(rows, k, key, fmt="{}"):
    return fmt.format(rows[k][key]) if k in rows and key in rows[k] else "-"


lines = ["# Perf, round 8 (add7 fix round 1; render.sh, 1280x720, 300 uncapped frames per held state)", "",
         "Each cell reads main -> round 6 -> round 7 -> round 8. Main, round 6 and round 8 were captured this round with the round-8 driver; round 7 is its own run (add7/shots/raw7/add). "
         "In round 8's driver the s3 hold keeps cranking (USE held, ticks held under the last one), so s3 measures cranking in main, round 6 and round 8; round 7's s3 row mostly measured the seal opening. "
         "Draw calls, texture and video memory, object counts and the item counts are deterministic in the container; frame times there are software GL on a shared machine and are left out.", "",
         "| State | Draw calls p50 (max) | Texture MB | Video MB | Full-screen translucent world layers | Overdraw est. | Additive items | Particle emitters on | Door open after the hold | Nodes |",
         "|---|---|---|---|---|---|---|---|---|---|"]
for k in ORDER:
    def quad(key, fmt="{}"):
        return " -> ".join(cell(x, k, key, fmt) for x in ALL)
    dc = " -> ".join(f"{x[k]['draw_calls_p50']} ({x[k]['draw_calls_max']})" if k in x else "-" for x in ALL)
    lines.append(f"| {k} | {dc} | {quad('texture_mem_mb', '{:.2f}')} | {quad('video_mem_mb', '{:.2f}')} | {quad('fullscreen_translucent_layers')} | {quad('overdraw_estimate', '{:.2f}')} | {quad('additive_items_on_screen')} | {quad('particles_emitting')} | {quad('door_open_after')} | {quad('nodes', '{:.0f}')} |")
s1 = "s1-door-end-rest"
lines += ["", "Full-screen translucent world layers (s1): main %s; round 6 %s; round 8 %s" % (main[s1]["fullscreen_list"], r6[s1]["fullscreen_list"], r8[s1]["fullscreen_list"]),
          "Full-screen canvas-layer quads (s1): main %s; round 6 %s; round 8 %s" % (main[s1]["fullscreen_canvaslayer_list"], r6[s1]["fullscreen_canvaslayer_list"], r8[s1]["fullscreen_canvaslayer_list"]), ""]
lines += ["## CPU side, godot --headless (frame wall time over 300 uncapped frames, p50 / p99 ms; on a machine shared with other render jobs)", "",
          "| State | Main | Round 6 | Round 8 |", "|---|---|---|---|"]
for k in ORDER:
    lines.append(f"| {k} | " + " | ".join(f"{head[c][k]['frame_ms_p50']:.2f} / {head[c][k]['frame_ms_p99']:.2f}" if k in head[c] else "-" for c in ("main", "r6", "add")) + " |")
open(os.path.join(S, "perf-table.md"), "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
