import sys, json, numpy as np
from PIL import Image, ImageDraw
row = sys.argv[1]; pairs = [tuple(map(int, p.split(','))) for p in sys.argv[2].split(';')]; out = sys.argv[3]
y0 = int(sys.argv[4]) if len(sys.argv) > 4 else 180
v = json.load(open('qa/%s-process.json' % row)).get('ground_cell_px_per_frame') or 0
tiles = []
for a, b in pairs:
    A = np.asarray(Image.open('frames/%s/frame_%02d.png' % (row, a))).astype(float)
    B = Image.open('frames/%s/frame_%02d.png' % (row, b))
    # shift B by +v so the ground is fixed
    Bs = Image.new('RGBA', B.size, (0, 0, 0, 0)); Bs.paste(B, (int(round(v)), 0), B)
    B = np.asarray(Bs).astype(float)
    la = (A[..., :3].mean(2) * A[..., 3] / 255); lb = (B[..., :3].mean(2) * B[..., 3] / 255)
    img = np.zeros(A.shape[:2] + (3,))
    img[..., 0] = np.clip(la * 2.2 + A[..., 3] * 0.25, 0, 255)
    img[..., 1] = np.clip(lb * 2.2 + B[..., 3] * 0.25, 0, 255)
    img[..., 2] = np.clip(lb * 2.2 + B[..., 3] * 0.25, 0, 255)
    t = Image.fromarray(img.astype(np.uint8)).crop((0, y0, A.shape[1], A.shape[0]))
    d = ImageDraw.Draw(t); d.text((4, 4), '%d red / %d cyan' % (a, b), fill=(255, 255, 0))
    tiles.append(t.resize((t.width * 2, t.height * 2), Image.NEAREST))
W = sum(t.width for t in tiles); H = tiles[0].height
o = Image.new('RGB', (W, H)); x = 0
for t in tiles:
    o.paste(t, (x, 0)); x += t.width
o.save(out)
