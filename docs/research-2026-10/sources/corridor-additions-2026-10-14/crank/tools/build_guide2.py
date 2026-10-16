"""Round 2 guide: the round-1 painting (raw/crank-1a.png) with only the parts to fix marked.

Round 1 (crank-1a) kept the identity, the legs and frame A's near arm well, but
  - both far hands were painted as an open palm facing forward, fingers spread: a wave, not a brace;
  - frame B's fist stopped about 10 cell px short of the rim (forearm painted too short).
This guide erases those parts (to the key) and lays flat mannequin shapes where they must go:
  - far arm (DARK GREY), both crank figures: the forearm from the chest front, level, and a flat mitten
    (the back of the glove, fingers together pointing forward) at chest height, braced on the wall plate;
  - frame B's near forearm and fist (LIGHT GREY): elbow at the waist, forearm level, the fist's centre on
    the rim point that frame A's grip reaches after one 45 deg tick (geometry.GRIP_B).
Everything else is the round-1 painting, unchanged.

usage: build_guide2.py RAW OUTDIR
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import geometry as GEO  # noqa: E402

CRANK = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
G = json.load(open(os.path.join(CRANK, 'guides', 'guide.json')))
REG = json.load(open(os.path.join(CRANK, 'frames', 'crank-1a', 'register.json')))
K = G['K']
MAG = (255, 0, 255)
NEAR_GREY = (196, 200, 206)
FAR_GREY = (98, 102, 110)


def to_raw(i, x, y):
    px, py = G['cells'][i]['paste']
    t = REG['legs_fit'][['', 'crank-a', 'crank-b'][i]]['t']
    return px + x * K + t[0], py + y * K + t[1]


def box(i, x0, y0, x1, y1):
    a = to_raw(i, x0, y0); b = to_raw(i, x1, y1)
    return [a[0], a[1], b[0], b[1]]


def capsule(d, i, p, q, w, fill):
    P = to_raw(i, *p); Q = to_raw(i, *q); r = w * K / 2
    d.line([P, Q], fill=fill, width=int(round(w * K)))
    for c in (P, Q):
        d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=fill)


def main(raw, outdir):
    im = Image.open(raw).convert('RGB')
    d = ImageDraw.Draw(im)
    for i in (1, 2):
        # erase the waving far hand and the far sleeve end in front of the chest
        # (rows 84-92 only right of x 172, clear of the chin and collar)
        d.rectangle(box(i, 170, 92, 194, 117), fill=MAG)
        d.rectangle(box(i, 172, 84, 194, 92), fill=MAG)
        # the new far arm: forearm level from behind the chest front, then a flat mitten pointing
        # forward; drawn only on the key, so the chest stays in front of it
        lay = Image.new('RGB', im.size, MAG); ld = ImageDraw.Draw(lay)
        capsule(ld, i, (156, 109), (178, 106), 11, FAR_GREY)
        ld.rounded_rectangle(box(i, 175, 100, 194, 111), radius=4 * K, fill=FAR_GREY)
        cur = np.asarray(im).astype(int); new = np.asarray(lay).astype(int)
        key = np.abs(cur - MAG).sum(2) < 90
        put = key & (np.abs(new - MAG).sum(2) > 90)
        cur[put] = new[put]
        # chips of the old glove left under the new forearm, beyond the chest front: to the key
        x0, y0, x1, y1 = [int(round(v)) for v in box(i, 167, 111, 173, 122)]
        sub = cur[y0:y1, x0:x1]
        lum = sub[..., :3].mean(2)
        sub[(lum < 70) & (np.abs(sub - MAG).sum(2) > 90)] = MAG
        im = Image.fromarray(cur.astype(np.uint8)); d = ImageDraw.Draw(im)
    # frame B: erase the short fist and wrist beyond the jacket front, then the longer forearm and fist
    d.rectangle(box(2, 158, 125, 178, 156), fill=MAG)
    # the old wrist and cuff above the new forearm, inside the jacket: flat jacket red (to repaint)
    d.rectangle(box(2, 145, 124, 156, 137), fill=(102, 37, 43))
    gx, gy = GEO.GRIP_B
    capsule(d, 2, (138, 142), (gx, gy), 15, NEAR_GREY)
    c = to_raw(2, gx, gy); r = 9 * K
    d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=NEAR_GREY)
    os.makedirs(outdir, exist_ok=True)
    im.save(os.path.join(outdir, 'crank-guide2.png'))
    print('saved', os.path.join(outdir, 'crank-guide2.png'))


if __name__ == '__main__':
    main(*sys.argv[1:])
