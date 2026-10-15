"""Blanks the hood's typeset DOOR 4B-07 stencil in a Codex edit-target composite (added when these
tools were filed, 2026-10-14, after review r5 found a faint copy of the stencil painted into the
head plate behind the hood). The image tool must never see lettering it could copy into a plate, so
every edit-target script calls this on its composed panel before saving it.

blank_hood_text(rgb, x0, y0, ppw) takes a float RGB panel (0..1) that shows world x0.. and y0.. at
ppw px per world px. Inside the hood's lettering box (HOOD_TEXT_BOX, world px) it finds the stencil
(letter-sized marks lighter than the darker hood paint around them), grows that mask by half a world px and fills it
from the surrounding hood paint (a normalized Gaussian of the pixels that are not lettering), so the
hood reads as plain painted steel. Returns a new array and the number of pixels filled."""
from __future__ import annotations

import numpy as np
from scipy import ndimage

# The hood's face, where DOOR 4B-07 is typeset (world px): x 716.75..763.5, y 299.5..321.5, with a margin.
HOOD_TEXT_BOX = (715.5, 296.0, 768.0, 325.0)
LUM = np.array([0.2126, 0.7152, 0.0722])
# A stencil letter (or a run of touching letters' strokes) is at most this wide and tall, and at least
# this tall, in world px; the cap height on the hood is about 9 world px, slanted with the hood.
LETTER_MAX = (12.0, 18.0)
LETTER_MIN_TALL = 1.0
# Straight runs at least this long (world px; across, up) are edges of the hood, not letters: no
# stroke of a letter runs 6 px across or 16 px up.
LINE_RUN = (6.0, 16.0)


def blank_hood_text(rgb, x0, y0, ppw, lift=0.05):
    out = np.array(rgb, dtype=float, copy=True)
    bx0, by0, bx1, by1 = HOOD_TEXT_BOX
    h, w = out.shape[:2]
    c0, c1 = max(0, int(np.floor((bx0 - x0) * ppw))), min(w, int(np.ceil((bx1 - x0) * ppw)))
    r0, r1 = max(0, int(np.floor((by0 - y0) * ppw))), min(h, int(np.ceil((by1 - y0) * ppw)))
    if c1 <= c0 or r1 <= r0:
        return out, 0
    sub = out[r0:r1, c0:c1]
    lum = (sub * LUM).sum(-1)
    # The hood behind the letters: a low percentile over about 6 world px, which the strokes (the
    # light minority of any such window) do not lift.
    size = max(5, int(round(6.0 * ppw)) | 1)
    text = lum - ndimage.percentile_filter(lum, 20, size=size) > lift
    # Keep only letter-sized marks: the hood's lit top edge, bottom arris and end edge are long, thin
    # lines (longer than a letter), so lines are taken out first and the rest is sized.
    tall_run = max(3, int(round(LINE_RUN[1] * ppw)))
    wide_run = max(3, int(round(LINE_RUN[0] * ppw)))
    lines = ndimage.binary_opening(text, structure=np.ones((tall_run, 1), bool)) | ndimage.binary_opening(text, structure=np.ones((1, wide_run), bool))
    text &= ~ndimage.binary_dilation(lines, iterations=1)
    labels, count = ndimage.label(text)
    for index, box in enumerate(ndimage.find_objects(labels), start=1):
        if box is None:
            continue
        tall = (box[0].stop - box[0].start) / ppw
        wide = (box[1].stop - box[1].start) / ppw
        if wide > LETTER_MAX[0] or tall > LETTER_MAX[1] or tall < LETTER_MIN_TALL:
            text[labels == index] = False
    text = ndimage.binary_dilation(text, iterations=max(1, int(round(ppw * 0.5))))
    keep = (~text).astype(float)
    sigma = max(1.0, ppw)
    den = ndimage.gaussian_filter(keep, sigma)
    for ch in range(3):
        fill = ndimage.gaussian_filter(sub[..., ch] * keep, sigma) / np.maximum(den, 1e-6)
        sub[..., ch] = np.where(text, fill, sub[..., ch])
    out[r0:r1, c0:c1] = sub
    return out, int(text.sum())
