"""Loop previews (animated WebP + GIF) at game size (1080p, gameplay zoom 1.35: engineer 190 px
tall, WOLF 310 px long) and 2x. Locomotion rows play at the frame rate where the measured
no-slide ground speed equals the chosen world speed; a ground strip under the feet scrolls at
that speed so any foot slide is visible against it.

usage: loops.py
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = os.path.join(ROOT, 'deliver')
ROWS = json.load(open(os.path.join(ROOT, 'tools', 'rows.json')))
# optional: loops.py SUFFIX '{"eng-walk": 80, ...}' renders the same loops at other world speeds
SUFFIX = sys.argv[1] if len(sys.argv) > 1 and __name__ == '__main__' else ''
if SUFFIX:
    for _k, _v in json.loads(sys.argv[2]).items():
        ROWS[_k]['world_speed'] = float(_v)
INFO = json.load(open(os.path.join(OUT, 'sprites', 'rows-info.json')))
SCREEN_PER_WORLD = 2.7  # 1080 / 540 * 1.35
BG = (12, 20, 30); FLOOR = (22, 34, 48); TICK = (64, 100, 132); LINE = (40, 62, 84)


def lin(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def srgb(l):
    l = np.clip(l, 0, 1)
    return 255 * np.where(l <= 0.0031308, l * 12.92, 1.055 * l ** (1 / 2.4) - 0.055)


def scale_rgba(im, s):
    """Premultiplied linear-light Lanczos resize."""
    a = im[..., 3] / 255.0
    L = lin(im[..., :3].astype(float)) * a[..., None]
    W = int(round(im.shape[1] * s)); H = int(round(im.shape[0] * s))
    r = lambda ch: np.asarray(Image.fromarray(ch.astype(np.float32), 'F').resize((W, H), Image.LANCZOS))
    A = np.clip(r(a), 0, 1); C = np.stack([r(L[..., c]) for c in range(3)], -1)
    rgb = srgb(C / np.maximum(A[..., None], 1e-5))
    return np.dstack([np.clip(rgb, 0, 255), A * 255]).round().astype(np.uint8)


def char_scale(row):
    if row.startswith('eng'):
        return 190.0 / INFO['eng-idle']['opaque_height_median']
    return 310.0 / INFO['wolf-idle']['opaque_length_median']


def timing(row):
    cfg = ROWS[row]
    n = INFO[row]['n']
    if cfg.get('durations_ms'):
        return cfg['durations_ms'], 0.0, None
    s = char_scale(row)
    gw = cfg['ground_cell_px_per_frame'] * s / SCREEN_PER_WORLD  # world px per anim frame
    fps = cfg['world_speed'] / gw
    return [1000.0 / fps] * n, cfg['ground_cell_px_per_frame'], fps


def render(row, mult):
    s = char_scale(row) * mult
    durs, gcell, fps = timing(row)
    n = INFO[row]['n']
    files = [os.path.join(OUT, 'sprites', row, f'frame_{i:02d}.png') for i in range(n)]
    spr = [scale_rgba(np.asarray(Image.open(f).convert('RGBA')), s) for f in files]
    H, W = spr[0].shape[:2]
    base = 311 if row.startswith('eng') else 263
    by = int(round(base * s))
    pad = int(round(10 * mult)); floor_h = int(round(16 * mult))
    CW, CH = W + 2 * pad, max(H, by + floor_h) + pad
    frames = []
    off = 0.0
    tick = 18 * mult
    for i in range(n):
        im = Image.new('RGB', (CW, CH), BG)
        d = ImageDraw.Draw(im)
        gy = pad + by
        d.rectangle([0, gy, CW, CH], fill=FLOOR)
        d.line([(0, gy), (CW, gy)], fill=LINE, width=max(1, int(mult)))
        x = -(off % tick)
        while x < CW:
            d.line([(x, gy + 3 * mult), (x, gy + 9 * mult)], fill=TICK, width=max(1, int(mult)))
            x += tick
        sp = Image.fromarray(spr[i])
        im.paste(sp, (pad, pad), sp)
        frames.append(im)
        off += gcell * s  # ground moves back by the no-slide distance per frame
    return frames, durs, fps


def save(frames, durs, path):
    d = [int(round(x)) for x in durs]
    frames[0].save(path + '.webp', save_all=True, append_images=frames[1:], duration=d, loop=0, lossless=True, method=4)
    # GIF: one global palette for the whole loop, no dither (stable dark gradients)
    mont = Image.new('RGB', (frames[0].width, frames[0].height * len(frames)))
    for i, f in enumerate(frames):
        mont.paste(f, (0, i * f.height))
    pal = mont.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    q = [f.quantize(palette=pal, dither=Image.Dither.NONE) for f in frames]
    # GIF delays are in 1/100 s; distribute rounding so the loop length stays exact
    cs, acc, tot = [], 0.0, 0
    for x in durs:
        acc += x / 10.0; c = int(round(acc)) - tot; cs.append(max(2, c)); tot += cs[-1]
    q[0].save(path + '.gif', save_all=True, append_images=q[1:], duration=[c * 10 for c in cs], loop=0, disposal=1)


def main():
    od = os.path.join(OUT, 'loops'); os.makedirs(od, exist_ok=True)
    rep = {}
    for row in ROWS:
        if SUFFIX and row.endswith('idle'):
            continue
        for mult, tag in ((1, 'game'), (2, '2x')):
            frames, durs, fps = render(row, mult)
            save(frames, durs, os.path.join(od, f'{row}-{tag}{SUFFIX}'))
        rep[row] = dict(frames=INFO[row]['n'], fps=None if fps is None else round(fps, 2),
                        loop_s=round(sum(durs) / 1000.0, 3), world_speed_px_s=ROWS[row].get('world_speed', 0),
                        ground_cell_px_per_frame=ROWS[row].get('ground_cell_px_per_frame'),
                        game_scale=round(char_scale(row), 4), size_game=list(frames[0].size) if False else None)
        print(row, rep[row])
    json.dump(rep, open(os.path.join(od, f'loops{SUFFIX}.json'), 'w'), indent=1)


if __name__ == '__main__':
    main()
