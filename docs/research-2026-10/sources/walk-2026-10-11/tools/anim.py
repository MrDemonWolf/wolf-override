"""Animation output helpers: animated GIF/WebP/MP4 writers and a scrolling-floor
loop preview (character fixed, floor ticks move at the no-slide speed)."""
import os, subprocess, tempfile, shutil
import numpy as np
from PIL import Image, ImageDraw


def save_gif(frames, path, fps):
    """frames: list of RGB PIL images. Uses a shared adaptive palette."""
    dur = int(round(1000 / fps))
    # build one palette from a mosaic of all frames so colours stay stable
    w, h = frames[0].size
    mosaic = Image.new('RGB', (w, h * min(len(frames), 8)))
    for i, f in enumerate(frames[:8]):
        mosaic.paste(f, (0, i * h))
    pal = mosaic.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    q = [f.quantize(palette=pal, dither=Image.Dither.NONE) for f in frames]
    q[0].save(path, save_all=True, append_images=q[1:], duration=dur, loop=0, optimize=False, disposal=1)


def save_webp(frames, path, fps, quality=92):
    dur = int(round(1000 / fps))
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=dur, loop=0,
                   quality=quality, method=5, lossless=False)


def save_mp4(frames, path, fps):
    tmp = tempfile.mkdtemp()
    try:
        for i, f in enumerate(frames):
            f.save(os.path.join(tmp, '%05d.png' % i))
        w, h = frames[0].size
        vf = 'scale=trunc(iw/2)*2:trunc(ih/2)*2'
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', str(fps), '-i',
                        os.path.join(tmp, '%05d.png'), '-vf', vf, '-c:v', 'libx264', '-pix_fmt',
                        'yuv420p', '-crf', '16', '-preset', 'slow', '-movflags', '+faststart', path],
                       check=True)
    finally:
        shutil.rmtree(tmp)


def loop_preview(rgba_frames, hip, baseline, px_per_frame, scale, loops=3, bg=(16, 24, 34),
                 floor=(40, 58, 76), tick=(96, 130, 160), pad=(0.55, 0.55), show_floor=True):
    """rgba_frames: list of RGBA PIL images of identical size (cell space).
    hip: (x, y) fixed pivot in cell px. baseline: floor row in cell px.
    px_per_frame: world travel per frame in cell px (floor scrolls by this).
    scale: output scale applied to the cell (game size or 2x)."""
    cw, ch = rgba_frames[0].size
    # crop to union bbox of alpha (plus margin) so previews are tight
    boxes = [f.getchannel('A').getbbox() for f in rgba_frames]
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    mx = int((x1 - x0) * 0.18) + 8; my = int((y1 - y0) * 0.08) + 8
    x0 = max(0, x0 - mx); x1 = min(cw, x1 + mx); y0 = max(0, y0 - my)
    y1 = max(y1, int(baseline)) + my
    W = int(round((x1 - x0) * scale)); H = int(round((y1 - y0) * scale))
    W += W % 2; H += H % 2
    out = []
    n = len(rgba_frames)
    for k in range(n * loops):
        f = rgba_frames[k % n]
        canvas = Image.new('RGB', (W, H), bg)
        d = ImageDraw.Draw(canvas)
        by = (baseline - y0) * scale
        if show_floor:
            d.rectangle([0, by, W, H], fill=floor)
            off = (k * px_per_frame * scale) % (40 * scale)
            x = -off
            while x < W:
                d.line([(x, by), (x, by + 6 * scale)], fill=tick, width=max(1, int(scale)))
                x += 40 * scale
        sub = f.crop((x0, y0, x1, y1)).resize((W, H), Image.LANCZOS)
        canvas.paste(sub, (0, 0), sub)
        out.append(canvas)
    return out
