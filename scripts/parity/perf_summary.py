#!/usr/bin/env python3
"""Summarises headless perf runs (scripts/parity/run.sh perf) as a Markdown table, before against after.

Each folder holds one or more <label>.json runs from the same commit; take them interleaved in the
same session (before, after, before, after, ...) so a busy machine affects both sides alike. Every
figure is the median across that folder's runs; the last column is after against before. A figure
only one side has (say, a run from before the probe measured it) shows "-" on the other side.
Usage: python3 -I scripts/parity/perf_summary.py <before dir> <after dir>
"""
import json
import pathlib
import statistics
import sys


def load(folder: pathlib.Path) -> list[dict]:
    return [json.loads(p.read_text()) for p in sorted(folder.glob("*.json"))]


def figures(run: dict) -> dict[str, float]:
    out = {f"startup {k}": float(v) for k, v in run["startup"].items()}
    for state, s in run["states"].items():
        out[f"{state} frame p50 ms"] = s["frame_ms"]["p50"]
        out[f"{state} frame p99 ms"] = s["frame_ms"]["p99"]
        out[f"{state} _process span p50 ms"] = s["node_process_span_ms"]["p50"]
        out[f"{state} _refresh_ui us"] = s["refresh_ui_us"]
        out[f"{state} junction redraws per frame"] = s["junction_redraws_per_frame"]
        for key in ("junction_draw_us", "recesses_draw_us"):
            if s.get(key, -1.0) >= 0.0:
                out[f"{state} {key.replace('_draw_us', ' _draw us')}"] = s[key]
    opening = run.get("opening")
    if opening:
        out["opening new game call ms"] = opening["new_game_call_ms"]
        out["opening frame p99 ms"] = opening["frame_ms"]["p99"]
        out["opening frame max ms"] = opening["frame_ms"]["max"]
        out[f"opening frames over {opening['hitch_ms']:g} ms"] = float(opening["over_hitch_ms"])
    for room, times in run.get("room_loads", {}).items():
        out[f"load {room} call ms"] = times["call_ms"]
        out[f"load {room} through first frame ms"] = times["through_first_frame_ms"]
    for code, times in run.get("languages", {}).items():
        out[f"language {code} through first frame ms"] = times["through_first_frame_ms"]
    # Memory figures; rss_mb and peak_rss_mb are -1 where the system does not give them
    # (parity_kit.gd's rss_mb), and those are left out rather than averaged in.
    for part in ("final", "after_languages"):
        for key in ("nodes", "objects", "resources", "static_mb", "static_max_mb", "rss_mb"):
            if run.get(part, {}).get(key, -1) >= 0:
                out[f"{part.replace('_', ' ')} {key}"] = float(run[part][key])
    if run.get("peak_rss_mb", -1) >= 0:
        out["peak rss_mb"] = float(run["peak_rss_mb"])
    return out


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    sides = [[figures(r) for r in load(pathlib.Path(a))] for a in sys.argv[1:3]]
    if not sides[0] or not sides[1]:
        print("no runs found", file=sys.stderr)
        return 1
    print(f"| Figure (median of {len(sides[0])} before, {len(sides[1])} after) | Before | After | Change |")
    print("|---|---:|---:|---:|")
    # Every figure either side has, in first-seen order (dicts keep insertion order).
    keys = list(dict.fromkeys(k for side in sides for run in side for k in run))
    for key in keys:
        medians = []
        for side in sides:
            values = [f[key] for f in side if key in f]
            medians.append(statistics.median(values) if values else None)
        before, after = medians
        change = ""
        if before is not None and after is not None and before != 0:
            change = f"{(after - before) / before * 100.0:+.1f}%"
        cells = ["-" if v is None else f"{v:.3f}" for v in medians]
        print(f"| {key} | {cells[0]} | {cells[1]} | {change} |")
    return 0


if __name__ == "__main__":
    sys.exit(main())
