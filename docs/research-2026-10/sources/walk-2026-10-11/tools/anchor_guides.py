"""Anchored WOLF guide sheets (v2). Each 2x2 sheet carries one or two finished WOLF paintings
from the approved walk sheet (wolf-walk-1) next to grey mannequins, at the mannequins' scale,
so every new frame is painted against the same body, size and plate design.

Writes guides/<row>-a<k>.png and updates guides/guides.json (anchor slots are flagged and are
never extracted as animation frames)."""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import rig
import draw_guides as D
import register as R

ROOT = R.ROOT
KEY = (255, 0, 255)

# anchors: the four painted walk frames 0-3 of raw/wolf-walk-1.png
base = [f for f in R.extract('wolf-walk') if f['sheet'] == 'wolf-walk-1.png']
s_base = float(np.median([f['fit_free'][0] for f in base]))
anchors = {}
for f in base:
    _, tx, ty, _ = R.P.iou_fit(f['pm'], f['gm'], [s_base])
    ox, oy = f['fr']['origin']
    gx = ox - f['win'][0]; gy = oy - f['win'][1]
    rx = s_base * gx + tx + f['win'][0]; ry = s_base * gy + ty + f['win'][1]
    a = f['a']; col = f['col']
    ys, xs = np.nonzero(a > 0.01)
    y0, y1, x0, x1 = ys.min() - 4, ys.max() + 5, xs.min() - 4, xs.max() + 5
    rgba = np.dstack([np.clip(col[y0:y1, x0:x1], 0, 255), a[y0:y1, x0:x1] * 255]).astype(np.uint8)
    im = Image.fromarray(rgba, 'RGBA')
    # scale to guide px and remember where the guide origin falls inside the crop
    g = 1.0 / s_base
    im = im.resize((int(round(im.width * g)), int(round(im.height * g))), Image.LANCZOS)
    anchors[f['frame']] = (im, ((rx - x0) * g, (ry - y0) * g))

PLAN = {
    'wolf-walk': [('A', [('anchor', 3), ('pose', 4), ('pose', 5), ('pose', 6)]),
                  ('B', [('anchor', 0), ('pose', 7), ('pose', 8), ('pose', 9)]),
                  ('C', [('anchor', 1), ('pose', 10), ('pose', 11), ('anchor', 2)])],
    'wolf-trot': [('A', [('anchor', 0), ('pose', 0), ('pose', 1), ('pose', 2)]),
                  ('B', [('anchor', 1), ('pose', 3), ('pose', 4), ('pose', 5)]),
                  ('C', [('anchor', 2), ('pose', 6), ('pose', 7), ('pose', 8)]),
                  ('D', [('anchor', 3), ('pose', 9), ('pose', 10), ('pose', 11)])],
    'wolf-idle': [('A', [('anchor', 0), ('pose', 0), ('pose', 1), ('pose', 2)]),
                  ('B', [('anchor', 1), ('pose', 3), ('pose', 4), ('pose', 5)]),
                  ('C', [('anchor', 2), ('pose', 6), ('pose', 7), ('anchor', 3)])],
}


def build():
    G = json.load(open(os.path.join(ROOT, 'guides', 'guides-v1.json')))
    W, Hh, cols, rows = D.LAYOUTS['wolf']
    rects = D.cells(W, Hh, cols, rows)
    for row, sheets in PLAN.items():
        kind = row.split('-')[1]
        n = G[row]['n']
        new_sheets = []
        if row == 'wolf-walk':
            new_sheets.append(G[row]['sheets'][0])  # keep the approved painted frames 0-3
        for tag, slots in sheets:
            img = Image.new('RGB', (W * D.SS, Hh * D.SS), KEY)
            d = ImageDraw.Draw(img)
            meta = []
            pastes = []
            for slot, (what, fi) in enumerate(slots):
                x0, y0, x1, y1 = rects[slot]
                ox = (x0 + x1) / 2 + D.WOLF_CX_OFF; oy = y0 + D.WOLF_BASE
                if what == 'pose':
                    J = rig.wolf_pose(kind, fi, n)
                    pen = D.Pen(d, ox, oy, D.WOLF_S); D.draw_wolf(pen, J)
                    s = D.WOLF_S
                    contacts = {nm: [ox + (J[nm + '_paw'][0] - 28) * s, ox + (J[nm + '_paw'][0] + 52) * s]
                                for nm in ('RH', 'RF', 'LH', 'LF') if J[nm + '_stance']}
                    meta.append(dict(frame=fi, slot=slot, cell=[x0, y0, x1, y1], origin=[ox, oy], scale=s,
                                     hip=[ox + J['hip'][0] * s, oy - J['hip'][1] * s], baseline=oy, contacts=contacts,
                                     clamped=[nm for nm in ('RH', 'RF', 'LH', 'LF') if J[nm + '_clamped']],
                                     shoulder=[ox + J['shoulder'][0] * s, oy - J['shoulder'][1] * s]))
                else:
                    pastes.append((fi, ox, oy))
                    meta.append(dict(frame=-1, anchor_of=fi, slot=slot, cell=[x0, y0, x1, y1], origin=[ox, oy]))
            img = img.resize((W, Hh), Image.LANCZOS)
            for fi, ox, oy in pastes:
                im, (gx, gy) = anchors[fi]
                bg = Image.new('RGBA', img.size, KEY + (255,))
                layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
                layer.paste(im, (int(round(ox - gx)), int(round(oy - gy))), im)
                img = Image.alpha_composite(img.convert('RGBA'), layer).convert('RGB')
            name = '%s-a%s.png' % (row, tag)
            img.save(os.path.join(ROOT, 'guides', name))
            new_sheets.append(dict(file=name, frames=meta))
        G[row]['sheets'] = new_sheets
        G[row]['anchored_v2'] = True
    json.dump(G, open(os.path.join(ROOT, 'guides', 'guides.json'), 'w'), indent=1)
    print('s_base', s_base)


if __name__ == '__main__':
    build()
