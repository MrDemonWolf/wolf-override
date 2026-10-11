#!/usr/bin/env python3
"""Rebuild the game's three layers of the opening's maintenance crawl hatch from its two originals.

The originals (closed and open, one 1536x1024 canvas, generated as an edit pair so the frame lines up)
are not modified. Each layer is cut from them on that shared canvas: the frame (the closed art with
its opening cut out), the leaf (the closed art inside the opening) and the duct (the open art inside
the opening). The faint generation halo below alpha 24 is cleared and the body's 248-254 alpha set to
opaque; the opening is an anti-aliased chamfered rectangle measured on the originals; the layers are
cropped to the art plus an 8 px margin and downscaled to 640 px wide with Lanczos in premultiplied
linear light. The script prints the opening and lamp rectangles in layer pixels (OpeningHatch uses
them).

Usage (needs NumPy and Pillow; the committed copies were made with NumPy 2.5 and Pillow 12.3):
	python3 scripts/prepare_opening_hatch.py apps/game/art-source/opening <output directory>
Compare the output with apps/game/assets/props/opening-hatch-*.png before replacing them, and update
the SHA-256 values in apps/game/assets/manifest.json if anything changes.
"""
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

if len(sys.argv) != 3:
	sys.exit("usage: prepare_opening_hatch.py <art-source/opening directory> <output directory>")
SRC = Path(sys.argv[1])
OUT = Path(sys.argv[2])
OUT.mkdir(parents=True, exist_ok=True)

OUT_WIDTH = 640
# Measured on the 1536x1024 originals: the opening (x0, y0, x1, y1, corner chamfer), the unlit lamp
# lens on the top bar, and the crop (the art's alpha bbox, 107..1428 x 116..910, plus 8 px).
OPENING = (336, 314, 1204, 727, 44)
LAMP = (684, 182, 850, 213)
CROP = (99, 108, 1437, 918)


def srgb_to_linear(c):
	return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
	c = np.clip(c, 0, 1)
	return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def resize(rgb, alpha, size):
	lin = srgb_to_linear(rgb) * alpha[..., None]
	chans = [np.asarray(Image.fromarray(lin[..., i].astype(np.float32), "F").resize(size, Image.LANCZOS)) for i in range(3)]
	a = np.clip(np.asarray(Image.fromarray(alpha.astype(np.float32), "F").resize(size, Image.LANCZOS)), 0, 1)
	lin = np.stack(chans, -1)
	un = np.where(a[..., None] > 1e-4, lin / np.maximum(a[..., None], 1e-4), 0)
	return linear_to_srgb(np.clip(un, 0, 1)), a


def opening_mask(size, supersample=4):
	x0, y0, x1, y1, ch = OPENING
	width, height = size
	img = Image.new("L", (width * supersample, height * supersample), 0)
	poly = [(x0 + ch, y0), (x1 - ch, y0), (x1, y0 + ch), (x1, y1 - ch), (x1 - ch, y1), (x0 + ch, y1), (x0, y1 - ch), (x0, y0 + ch)]
	ImageDraw.Draw(img).polygon([(px * supersample, py * supersample) for px, py in poly], fill=255)
	return np.asarray(img.resize(size, Image.LANCZOS)).astype(np.float64) / 255


def load(path):
	px = np.asarray(Image.open(path).convert("RGBA")).astype(np.float64) / 255
	alpha = px[..., 3].copy()
	alpha[alpha < 24 / 255] = 0.0
	alpha[alpha >= 248 / 255] = 1.0
	return px[..., :3], alpha


def save(rgb, alpha, name, meta):
	x0, y0, x1, y1 = CROP
	rgb, alpha = rgb[y0:y1, x0:x1], alpha[y0:y1, x0:x1]
	size = (OUT_WIDTH, round(OUT_WIDTH * (y1 - y0) / (x1 - x0)))
	rgb, alpha = resize(rgb, alpha, size)
	out = np.dstack([rgb, alpha]) * 255
	path = OUT / name
	Image.fromarray(np.round(out).astype(np.uint8), "RGBA").save(path, optimize=True)
	meta[name] = {"size": list(size), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
	return size


closed_rgb, closed_alpha = load(SRC / "opening-hatch-closed.png")
open_rgb, _open_alpha = load(SRC / "opening-hatch-open.png")
mask = opening_mask((closed_alpha.shape[1], closed_alpha.shape[0]))
meta = {}
canvas = save(closed_rgb, closed_alpha * (1.0 - mask), "opening-hatch-frame.png", meta)
save(closed_rgb, np.maximum(closed_alpha, mask) * mask, "opening-hatch-leaf.png", meta)
save(open_rgb, mask, "opening-hatch-duct.png", meta)
scale = OUT_WIDTH / (CROP[2] - CROP[0])


def to_layer(rect):
	return [round((rect[0] - CROP[0]) * scale, 1), round((rect[1] - CROP[1]) * scale, 1), round((rect[2] - rect[0]) * scale, 1), round((rect[3] - rect[1]) * scale, 1)]


meta["canvas"] = list(canvas)
meta["opening_rect"] = to_layer(OPENING[:4])
meta["lamp_rect"] = to_layer(LAMP)
print(json.dumps(meta, indent=1))
