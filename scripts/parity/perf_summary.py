#!/usr/bin/env python3
"""Summarises headless perf runs (scripts/parity/run.sh perf) as a Markdown table, before against after.

Each folder holds one or more <label>.json runs from the same commit; take them interleaved in the
same session (before, after, before, after, ...) so a busy machine affects both sides alike. Every
figure is the median across that folder's runs; the last column is after against before.
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
    final = run["final"]
    for key in ("nodes", "objects", "resources", "static_mb"):
        out[f"final {key}"] = float(final[key])
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
    for key in sides[0][0]:
        before = statistics.median(f[key] for f in sides[0] if key in f)
        after_values = [f[key] for f in sides[1] if key in f]
        if not after_values:
            continue
        after = statistics.median(after_values)
        change = "" if before == 0 else f"{(after - before) / before * 100.0:+.1f}%"
        print(f"| {key} | {before:.3f} | {after:.3f} | {change} |")
    return 0


if __name__ == "__main__":
    sys.exit(main())
