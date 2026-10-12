"""Copy the chosen final frames into deliver/sprites/<row>/, removing stray specks (opaque
islands under MIN_ISLAND px that are not part of the figure, plus their soft fringe), and
write 4-column sheets. Also records per-row size, scale and the no-slide ground speed.

usage: finalize.py   (edit ROWS below to choose sources)
"""
import json, os, shutil, sys
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = os.path.join(ROOT, 'deliver')
MIN_ISLAND = 120

ROWS = json.load(open(os.path.join(ROOT, 'tools', 'rows.json')))


def clean(img):
    a = img[..., 3]
    lab, n = ndimage.label(a >= 128, structure=np.ones((3, 3)))
    if n <= 1:
        return img, 0
    sizes = ndimage.sum(np.ones_like(a), lab, range(1, n + 1))
    keep = np.zeros(n + 1, bool); keep[1:] = sizes >= MIN_ISLAND
    km = keep[lab]
    grown = ndimage.binary_dilation(km, iterations=3)
    out = img.copy()
    out[~grown] = 0
    return out, int((~keep[1:]).sum())


def main():
    info = {}
    for row, cfg in ROWS.items():
        src = os.path.join(ROOT, cfg['src'])
        dst = os.path.join(OUT, 'sprites', row); shutil.rmtree(dst, ignore_errors=True); os.makedirs(dst)
        files = sorted(f for f in os.listdir(src) if f.startswith('frame_'))
        imgs, removed = [], []
        for f in files:
            im = np.asarray(Image.open(os.path.join(src, f)).convert('RGBA'))
            im, k = clean(im)
            removed.append(k)
            Image.fromarray(im).save(os.path.join(dst, f), optimize=True)
            imgs.append(im)
        H, W = imgs[0].shape[:2]
        cols = 4; rows_ = (len(imgs) + cols - 1) // cols
        sheet = np.zeros((H * rows_, W * cols, 4), np.uint8)
        for i, im in enumerate(imgs):
            sheet[(i // cols) * H:(i // cols + 1) * H, (i % cols) * W:(i % cols + 1) * W] = im
        Image.fromarray(sheet).save(os.path.join(OUT, 'sprites', row + '-sheet.png'), optimize=True)
        hs, ws = [], []
        for im in imgs:
            ys, xs = np.nonzero(im[..., 3] >= 128); hs.append(ys.max() - ys.min() + 1); ws.append(xs.max() - xs.min() + 1)
        info[row] = dict(src=cfg['src'], n=len(imgs), cell=[W, H], specks_removed=removed,
                         opaque_height_median=float(np.median(hs)), opaque_length_median=float(np.median(ws)))
    json.dump(info, open(os.path.join(OUT, 'sprites', 'rows-info.json'), 'w'), indent=1)
    for k, v in info.items():
        print(k, v)


if __name__ == '__main__':
    main()
