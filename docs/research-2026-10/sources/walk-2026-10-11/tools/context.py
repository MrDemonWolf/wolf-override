"""In-context preview: the engineer idles, walks, then jogs at the game's 190 px/s across the
corridor plates with WOLF following by the game's own rule (m0_actor.gd: target = engineer x - 64,
speed clamped to 220 px/s) and a Camera2D-style smoothed follow (position smoothing speed 5).

Rendered offline in Python at 1920x1080 (gameplay zoom 1.35 -> 2.7 screen px per world px),
60 fps. Animation phase is driven by distance travelled divided by each row's measured no-slide
ground speed, so planted feet stay on the floor. The far plate is scrolled per row: the wall at
parallax 0.6 and the floor rows linearly in y (flat-floor perspective) so the floor row under the
feet (source row 777, the walkway top) moves at exactly 1.0. Plates are mirror-tiled sideways.

usage: context.py
"""
import json, math, os, shutil, subprocess, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from loops import scale_rgba, char_scale, ROWS, INFO, SCREEN_PER_WORLD as SPW

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = os.path.join(ROOT, 'deliver', 'context')
LAY = os.path.abspath(os.path.join(ROOT, '..', '..', 'art', 'layers'))
FPS = 60; T = 6.2; W, H = 1920, 1080
WALK_Y = 777; HORIZON = 690; WALL_P = 0.6
FOLLOW_GAP = 64.0; FOLLOW_SPEED = 220.0; CAM_SMOOTH = 5.0; LEAD = 60.0
V_WALK = ROWS['eng-walk']['world_speed']; V_JOG = ROWS['eng-jog']['world_speed']
# optional: context.py SUFFIX V_WALK V_JOG renders a variant with other engineer speeds
SUFFIX = ''
if __name__ == '__main__' and len(sys.argv) > 3:
    SUFFIX, V_WALK, V_JOG = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])


WOLF_TROT_AT = min(V_WALK * 1.15, FOLLOW_SPEED - 10.0)


def speed(t):
    sm = lambda u: u * u * (3 - 2 * u)
    if t < 0.5: return 0.0
    if t < 0.8: return V_WALK * sm((t - 0.5) / 0.3)
    if t < 2.7: return V_WALK
    if t < 3.1: return V_WALK + (V_JOG - V_WALK) * sm((t - 2.7) / 0.4)
    return V_JOG


def mirror_cols(cols, Wp):
    m = np.mod(cols, 2 * Wp)
    return np.where(m >= Wp, 2 * Wp - 1 - m, m)


def sample_rows(plate, offs):
    """plate HxWxC float; offs per row (source px). Linear interpolation, mirror tiling."""
    Hp, Wp = plate.shape[:2]
    xs = np.arange(W)[None, :] + offs[:, None]
    x0 = np.floor(xs); f = (xs - x0)[..., None]
    c0 = mirror_cols(x0.astype(np.int64), Wp); c1 = mirror_cols(x0.astype(np.int64) + 1, Wp)
    r = np.arange(Hp)[:, None]
    return plate[r, c0] * (1 - f) + plate[r, c1] * f


def load_sprites(row):
    s = char_scale(row)
    n = INFO[row]['n']
    out = []
    for i in range(n):
        im = scale_rgba(np.asarray(Image.open(os.path.join(ROOT, 'deliver', 'sprites', row, f'frame_{i:02d}.png')).convert('RGBA')), s)
        a = im[..., 3:4] / 255.0
        out.append(np.dstack([im[..., :3] * a, a[..., 0]]).astype(np.float32))  # premultiplied
    return out, s


def gw(row, s):
    return ROWS[row]['ground_cell_px_per_frame'] * s / SPW  # world px per animation frame


def blit(frame, spr, x, y):
    fx, fy = x - math.floor(x), y - math.floor(y)
    sp = np.stack([ndimage.shift(spr[..., c], (fy, fx), order=1, mode='constant') for c in range(4)], -1)
    ix, iy = int(math.floor(x)), int(math.floor(y))
    h, w = sp.shape[:2]
    x0, y0 = max(0, ix), max(0, iy); x1, y1 = min(W, ix + w), min(H, iy + h)
    if x1 <= x0 or y1 <= y0: return
    s = sp[y0 - iy:y1 - iy, x0 - ix:x1 - ix]
    dst = frame[y0:y1, x0:x1]
    dst[...] = s[..., :3] + dst * (1 - s[..., 3:4])


class Anim:
    def __init__(self, idle, moves):
        self.idle = idle; self.moves = moves  # moves: list of (name, threshold_speed)
        self.state = idle; self.phase = 0.0; self.idle_t = 0.0

    def step(self, v, dt, rows_gw, v_state=None):
        # v moves the cycle (distance travelled); v_state (smoothed speed) picks the row, so the
        # game's 2 px follow dead zone (WOLF moves on alternate ticks below ~120 px/s) does not
        # flicker the row between idle and walk
        vs = v if v_state is None else v_state
        if vs < 1.0:
            self.state = self.idle; self.phase = 0.0; self.idle_t += dt
            return
        want = self.moves[0][0]
        for name, thr in self.moves:
            if vs >= thr: want = name
        if self.state == self.idle:
            self.state = want; self.phase = 0.0
        elif want != self.state:
            frac = self.phase / INFO[self.state]['n']
            self.state = want; self.phase = frac * INFO[want]['n']
        self.phase += v * dt / rows_gw[self.state]

    def frame(self):
        if self.state == self.idle:
            durs = ROWS[self.idle]['durations_ms']; t = (self.idle_t * 1000) % sum(durs)
            for i, d in enumerate(durs):
                if t < d: return self.state, i
                t -= d
            return self.state, 0
        return self.state, int(math.floor(self.phase)) % INFO[self.state]['n']


def main():
    os.makedirs(OUT, exist_ok=True)
    far = np.asarray(Image.open(os.path.join(LAY, 'corridor-far.png')).convert('RGB')).astype(np.float32)
    mid = np.asarray(Image.open(os.path.join(LAY, 'corridor-mid.png')).convert('RGBA')).astype(np.float32)
    mid_p = np.dstack([mid[..., :3] * mid[..., 3:4] / 255.0, mid[..., 3:4] / 255.0])
    y = np.arange(H, dtype=np.float64)
    eye = (HORIZON - WALL_P * WALK_Y) / (1 - WALL_P)
    p_far = np.where(y < HORIZON, WALL_P, (y - eye) / (WALK_Y - eye))
    p_far = np.minimum(p_far, 1.0)  # floor in front of the walkway moves with it (no shear streaks)
    spr = {}; scl = {}
    for row in ('eng-idle', 'eng-walk', 'eng-jog', 'wolf-idle', 'wolf-walk', 'wolf-trot'):
        spr[row], scl[row] = load_sprites(row)
    rgw = {r: gw(r, scl[r]) for r in ('eng-walk', 'eng-jog', 'wolf-walk', 'wolf-trot')}
    eng = Anim('eng-idle', [('eng-walk', 0), ('eng-jog', (V_WALK + V_JOG) / 2)])
    wolf = Anim('wolf-idle', [('wolf-walk', 0), ('wolf-trot', WOLF_TROT_AT)])
    xe, xw = 0.0, -FOLLOW_GAP
    cam0 = xe + LEAD; cam = cam0; vw_s = 0.0
    dt = 1.0 / FPS; nfr = int(round(T * FPS))
    font = ImageFont.load_default(size=26)
    tmp = os.path.join(OUT, '_webp_frames' + SUFFIX); shutil.rmtree(tmp, ignore_errors=True); os.makedirs(tmp)
    mp4 = os.path.join(OUT, f'context{SUFFIX}-1080p60.mp4')
    ff = subprocess.Popen(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-',
                           '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', mp4], stdin=subprocess.PIPE)
    log = []
    for k in range(nfr):
        t = k * dt
        ve = speed(t)
        xe += ve * dt
        target = xe - FOLLOW_GAP
        vw = max(-FOLLOW_SPEED, min(FOLLOW_SPEED, (target - xw) / dt)) if abs(target - xw) > 2.0 else 0.0
        xw += vw * dt
        cam += (xe + LEAD - cam) * (1 - math.exp(-CAM_SMOOTH * dt))
        vw_s += (abs(vw) - vw_s) * (1 - math.exp(-dt / 0.15))
        eng.step(ve, dt, rgw); wolf.step(abs(vw), dt, rgw, vw_s)
        d = (cam - cam0) * SPW
        frame = sample_rows(far, d * p_far)
        m = sample_rows(mid_p, np.full(H, d))
        frame = m[..., :3] + frame * (1 - m[..., 3:4])
        for anim, pivot, base in ((wolf, 293, 263), (eng, 128, 311)):
            row, fi = anim.frame()
            s = scl[row]
            wx = xw if anim is wolf else xe
            sx = (wx - cam) * SPW + W / 2 - pivot * s
            sy = WALK_Y - base * s
            blit(frame, spr[row][fi], sx, sy)
        img = Image.fromarray(np.clip(frame, 0, 255).astype(np.uint8))
        dr = ImageDraw.Draw(img)
        label = {'eng-idle': 'idle', 'eng-walk': f'walk  {ve:.0f} px/s', 'eng-jog': f'jog  {ve:.0f} px/s'}[eng.frame()[0]]
        dr.text((28, 24), f'engineer: {label}    WOLF: {wolf.frame()[0][5:]}', font=font, fill=(150, 190, 215))
        ff.stdin.write(img.tobytes())
        if k % 2 == 0:
            img.resize((1280, 720), Image.LANCZOS).save(os.path.join(tmp, f'{k // 2:04d}.png'), compress_level=1)
        log.append(dict(t=round(t, 4), xe=round(xe, 2), xw=round(xw, 2), cam=round(cam, 2), ve=round(ve, 1), vw=round(vw, 1),
                        eng=eng.frame(), wolf=wolf.frame()))
    ff.stdin.close(); ff.wait()
    json.dump(dict(fps=FPS, seconds=T, walk_speed=V_WALK, jog_speed=V_JOG, gw_world_px_per_anim_frame=rgw,
                   anim_fps_at_speed={'eng-walk': V_WALK / rgw['eng-walk'], 'eng-jog': V_JOG / rgw['eng-jog'],
                                      'wolf-walk': V_WALK / rgw['wolf-walk'], 'wolf-trot': V_JOG / rgw['wolf-trot']},
                   frames=log), open(os.path.join(OUT, f'context{SUFFIX}-log.json'), 'w'), indent=0)
    # WebP (1280x720, 30 fps) via img2webp; GIF (960x540, 25 fps) via ffmpeg palette
    files = sorted(os.listdir(tmp))
    args = ['img2webp', '-loop', '0', '-lossy', '-q', '78', '-m', '4', '-d', '33']
    for f in files: args.append(os.path.join(tmp, f))
    subprocess.run(args + ['-o', os.path.join(OUT, f'context{SUFFIX}-720p30.webp')], check=True, capture_output=True)
    gif = os.path.join(OUT, f'context{SUFFIX}-360p20.gif')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', mp4, '-vf',
                    'fps=20,scale=640:360:flags=lanczos,split[a][b];[a]palettegen=max_colors=192:stats_mode=full[p];[b][p]paletteuse=dither=none',
                    '-loop', '0', gif], check=True)
    for k in (0, 100, 180, 260, 340):
        Image.open(os.path.join(tmp, files[min(k // 2, len(files) - 1)])).save(os.path.join(OUT, f'still{SUFFIX}-{k:03d}.png'))
    shutil.rmtree(tmp)
    print('done', mp4)


if __name__ == '__main__':
    main()
