"""Round 7 integration: the render-monitor table (render.sh, 1280x720, 300 uncapped frames per held
state) and the CPU-side headless table.
Render: additions = add7/shots/raw7/add/{A,B}-720-perf (this round); round 6 = shots/raw6/slice/
{A,B}-720-perf (round 6's own runs, same driver code for these states); main = shots/raw5/main/
{A,B}-720-perf. s4b (inner leaf sliding) exists only with this round's driver: round 6 and main
from add7/shots/raw7/{r6,main}/A-720-perf when present.
Headless: add7/shots/raw7/{main,r6,add}/{A,B}-headless, all run this round under the same load
(main and round 6 on private copies in add7/integrate/probe/).
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


main = load([os.path.join(R, "shots", "raw5", "main", r) for r in ("A-720-perf", "B-720-perf")] + [os.path.join(S, "raw7", "main", "A-720-perf")])
r6 = load([os.path.join(R, "shots", "raw6", "slice", r) for r in ("A-720-perf", "B-720-perf")] + [os.path.join(S, "raw7", "r6", "A-720-perf")])
add = load([os.path.join(S, "raw7", "add", r) for r in ("A-720-perf", "B-720-perf")])
head = {c: load([os.path.join(S, "raw7", c, r) for r in ("A-headless", "B-headless")]) for c in ("main", "r6", "add")}
json.dump({"main": main, "round6": r6, "additions": add, "headless": head}, open(os.path.join(S, "perf.json"), "w"), indent=1)


def cell(rows, k, key, fmt="{}"):
    return fmt.format(rows[k][key]) if k in rows else "-"


lines = ["# Perf, round 7 additions (render.sh, 1280x720, 300 uncapped frames per held state)", "",
         "Each cell reads main -> round 6 -> round 7 additions. Draw calls, texture and video memory, object counts and the item counts are deterministic in the container (the draw-call maximum has a known +4/+5 transient in some runs). Frame times there are software GL on a shared machine and are not a measurement, so they are left out.", "",
         "| State | Draw calls p50 (max) | Texture MB | Video MB | Full-screen translucent world layers | Overdraw est. | Additive items | Particle emitters on | Objects | Nodes |",
         "|---|---|---|---|---|---|---|---|---|---|"]
for k in ORDER:
    def tri(key, fmt="{}"):
        return " -> ".join(cell(x, k, key, fmt) for x in (main, r6, add))
    dc = " -> ".join(f"{x[k]['draw_calls_p50']} ({x[k]['draw_calls_max']})" if k in x else "-" for x in (main, r6, add))
    lines.append(f"| {k} | {dc} | {tri('texture_mem_mb', '{:.2f}')} | {tri('video_mem_mb', '{:.2f}')} | {tri('fullscreen_translucent_layers')} | {tri('overdraw_estimate', '{:.2f}')} | {tri('additive_items_on_screen')} | {tri('particles_emitting')} | {tri('objects', '{:.0f}')} | {tri('nodes', '{:.0f}')} |")
lines += ["", "Full-screen translucent world layers (s1): main %s; round 6 %s; additions %s" % (main["s1-door-end-rest"]["fullscreen_list"], r6["s1-door-end-rest"]["fullscreen_list"], add["s1-door-end-rest"]["fullscreen_list"]),
          "Full-screen canvas-layer quads (s1): main %s; round 6 %s; additions %s" % (main["s1-door-end-rest"]["fullscreen_canvaslayer_list"], r6["s1-door-end-rest"]["fullscreen_canvaslayer_list"], add["s1-door-end-rest"]["fullscreen_canvaslayer_list"]), ""]
lines += ["## CPU side, godot --headless (frame wall time over 300 uncapped frames, p50 / p99 ms; all three copies run this round, back to back, on a machine shared with other render jobs)", "",
          "| State | Main | Round 6 | Additions |", "|---|---|---|---|"]
for k in ORDER:
    lines.append(f"| {k} | " + " | ".join(f"{head[c][k]['frame_ms_p50']:.2f} / {head[c][k]['frame_ms_p99']:.2f}" if k in head[c] else "-" for c in ("main", "r6", "add")) + " |")
open(os.path.join(S, "perf-table.md"), "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
