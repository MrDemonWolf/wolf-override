#!/usr/bin/env python3
"""Rebuild the game's import copies of the approved design A bulkhead art.

For each door family the states and the front lip are registered onto one canvas whose bottom row
is the floor, the black matte fringe is removed (alpha decontamination), and the result is
downscaled by half in premultiplied alpha. The originals are not modified.

Usage (needs NumPy and Pillow; the committed copies were made with NumPy 2.5 and Pillow 12.3, and
these versions reproduce them byte for byte):
    python3 scripts/prepare_bulkheads.py apps/game/art-source/doors <output directory>
Compare the output with apps/game/assets/props/*-bulkhead-*.png before replacing them, and update
the SHA-256 values in apps/game/assets/manifest.json if anything changes.
"""
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

if len(sys.argv) != 3:
	sys.exit("usage: prepare_bulkheads.py <art-source/doors directory> <output directory>")
SRC = Path(sys.argv[1])
OUT = Path(sys.argv[2])
OUT.mkdir(parents=True, exist_ok=True)

# Offsets (x, y) that put each image on its family canvas, measured by registering the images
# (alpha silhouettes for the states, colour and coverage for the lips).
FAMILIES = {
	"junction": {
		"height": 1280,
		"images": {
			"sealed": ("junction-sealed.png", (0, 0)),
			"breaking": ("junction-breaking.png", (0, 0)),
			"blown": ("junction-blown.png", (1, 0)),
			"front-lip": ("junction-front-lip.png", (79, 25)),
		},
	},
	"corridor": {
		"height": 1296,
		"images": {
			"sealed": ("corridor-sealed.png", (0, 0)),
			"open": ("corridor-open.png", (1, 15)),
			"front-lip": ("corridor-front-lip.png", (99, 44)),
		},
	},
}
LOW_ALPHA = 40
FRINGE_PX = 3


def min_filter(a: np.ndarray, r: int) -> np.ndarray:
	out = a.copy()
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			out = np.minimum(out, np.roll(np.roll(a, dy, 0), dx, 1))
	return out


def box3(a: np.ndarray) -> np.ndarray:
	acc = np.zeros_like(a, dtype=np.float32)
	for dy in (-1, 0, 1):
		for dx in (-1, 0, 1):
			acc += np.roll(np.roll(a, dy, 0), dx, 1)
	return acc / 9.0


def defringe(rgba: np.ndarray) -> np.ndarray:
	rgb = rgba[:, :, :3].astype(np.float32)
	a = rgba[:, :, 3].astype(np.float32)
	a[a < LOW_ALPHA] = 0.0
	interior = min_filter((a >= 250).astype(np.uint8), FRINGE_PX).astype(bool)
	known = interior.copy()
	colour = np.where(known[:, :, None], rgb, 0.0)
	fringe = (a > 0) & ~interior
	# Bleed the interior colour outward one pixel at a time over the fringe band.
	for _ in range(FRINGE_PX + 3):
		todo = fringe & ~known
		if not todo.any():
			break
		acc = np.zeros_like(rgb)
		cnt = np.zeros(a.shape, dtype=np.float32)
		for dy in (-1, 0, 1):
			for dx in (-1, 0, 1):
				k = np.roll(np.roll(known, dy, 0), dx, 1)
				c = np.roll(np.roll(colour, dy, 0), dx, 1)
				acc += c * k[:, :, None]
				cnt += k
		grow = todo & (cnt > 0)
		colour[grow] = acc[grow] / cnt[grow][:, None]
		known |= grow
	rgb = np.where((fringe & known)[:, :, None], colour, rgb)
	# Pull the edge in by one pixel (the dark matte line) and keep it anti-aliased.
	a = np.minimum(a, box3(min_filter(a, 1)))
	a[a < 8] = 0.0
	out = np.dstack([rgb, a]).clip(0, 255).astype(np.uint8)
	return out


def place(img: np.ndarray, offset, height: int) -> np.ndarray:
	canvas = np.zeros((height, 768, 4), dtype=np.uint8)
	dx, dy = offset
	h, w = img.shape[:2]
	ys0, xs0 = max(0, dy), max(0, dx)
	ys1, xs1 = min(height, dy + h), min(768, dx + w)
	canvas[ys0:ys1, xs0:xs1] = img[ys0 - dy:ys1 - dy, xs0 - dx:xs1 - dx]
	return canvas


def downscale(arr: np.ndarray) -> Image.Image:
	img = Image.fromarray(arr, "RGBA").convert("RGBa")
	img = img.resize((arr.shape[1] // 2, arr.shape[0] // 2), Image.LANCZOS)
	return img.convert("RGBA")


report = {}
for family, spec in FAMILIES.items():
	placed = {}
	for state, (name, offset) in spec["images"].items():
		raw = np.asarray(Image.open(SRC / name).convert("RGBA"))
		placed[state] = place(defringe(raw), offset, spec["height"])
	if family == "corridor":
		# The sealed image's base is cut off by its canvas; the open image (same frame, registered
		# 15 px lower) supplies the rows below that cut so both stand on the same floor row.
		sealed = placed["sealed"]
		cut = 1280
		fill = placed["open"][cut:]
		sealed[cut:] = np.where(sealed[cut:, :, 3:4] > 0, sealed[cut:], fill)
	for state, arr in placed.items():
		out = OUT / f"{family}-bulkhead-{state}.png"
		downscale(arr).save(out, optimize=True)
		data = out.read_bytes()
		bbox = Image.open(out).getchannel("A").getbbox()
		report[out.name] = {"size": Image.open(out).size, "alpha_bbox": bbox, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}
print(json.dumps(report, indent=1))
