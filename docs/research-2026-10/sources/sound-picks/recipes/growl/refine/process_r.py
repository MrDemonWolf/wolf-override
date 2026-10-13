"""REFINE pass (-r files) for two of WOLF's recorded growls, after the critic's fixes.
Copied from growl/rec-tools/process.py; the chain is unchanged except where marked "REFINE".

Usage: python3 -I process_r.py <src_dir with dog2.wav dog_growl.wav bear_02.wav> <out_dir>
All sources are 44.1 kHz mono 16-bit copies decoded by ffmpeg from the downloads.
Deterministic: every random layer uses a fixed seed.
"""
import sys, os, math, random, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dsp import *

SRC, OUT = sys.argv[1], sys.argv[2]
SEED = 0x57A1F


def cut(x, a, b):
    return x[int(a * SR):int(b * SR)]


def declick(x, ratio=6.0, win_ms=10):
    """Replace isolated crackle (2nd difference far above its local RMS) with cubic-ish interpolation."""
    y = list(x); n = len(y); w = int(SR * win_ms / 1000)
    d2 = [0.0] + [y[i + 1] - 2 * y[i] + y[i - 1] for i in range(1, n - 1)] + [0.0]
    cs = [0.0]
    for v in d2:
        cs.append(cs[-1] + v * v)
    for i in range(w, n - w):
        loc = math.sqrt(max(1e-18, (cs[i + w] - cs[i - w] - d2[i] ** 2) / (2 * w - 1)))
        if abs(d2[i]) > ratio * loc:
            a, b = y[i - 2], y[i + 2]
            for j in (-1, 0, 1):
                t = (j + 2) / 4.0
                y[i + j] = a + (b - a) * t
    return y


def clean(x, hp=70):
    """Source cleanup: DC, crackle, rumble/handling noise below the voice, hiss above it."""
    y = declick(remove_dc(x))
    y = hpf4(y, hp)
    y = lpf(lpf(y, 9000), 9000)
    return y


def gate(x, thr_db=-48, floor_db=-14, att_ms=4, rel_ms=90):
    """Soft downward expander so the room floor between growl pulses drops away."""
    env = envelope(x, att_ms, rel_ms); thr = 10 ** (thr_db / 20); fl = 10 ** (floor_db / 20)
    out = []; g = 1.0
    for v, e in zip(x, env):
        tgt = 1.0 if e >= thr else max(fl, (e / thr) ** 1.5)
        g += (tgt - g) * (0.02 if tgt > g else 0.002)
        out.append(v * g)
    return out


def compress(x, thr_db=-24, ratio=3.0, att_ms=6, rel_ms=90, makeup_db=0):
    env = envelope(x, att_ms, rel_ms); thr = 10 ** (thr_db / 20); mk = 10 ** (makeup_db / 20)
    out = []
    for v, e in zip(x, env):
        g = (e / thr) ** (1 / ratio - 1) if e > thr else 1.0
        out.append(v * g * mk)
    return out


def ring(x, fc, depth, phase=0.0):
    w = 2 * math.pi * fc / SR
    return [v * (1 - depth) + depth * v * math.sin(w * i + phase) for i, v in enumerate(x)]


def am_rough(x, rate, depth, rng):
    """20-40 Hz amplitude roughness with a little rate jitter (keeps it organic)."""
    out = []; ph = 0.0; r = rate
    for i, v in enumerate(x):
        if i % 441 == 0:
            r = rate * (1 + 0.12 * (rng.random() - 0.5))
        ph += 2 * math.pi * r / SR
        out.append(v * (1 - depth + depth * (0.5 + 0.5 * math.sin(ph))))
    return out


def chassis(x, delays_ms, fb, damp, wet, tail=0.08):
    """Parallel damped feedback combs at inharmonic delays = resonant metal shell."""
    acc = [0.0] * (len(x) + int(tail * SR))
    for k, d in enumerate(delays_ms):
        c = comb_fb(x, d / 1000.0, fb * (1 - 0.06 * k), damp, tail_s=tail)
        for i, v in enumerate(c):
            acc[i] += v / len(delays_ms)
    dry = list(x) + [0.0] * (len(acc) - len(x))
    return [d * (1 - wet) + a * wet * 1.6 for d, a in zip(dry, acc)]


def servo(n, f0, f1, level, env_fn, rng, tick_hz=62.0):
    """Faint servo/actuator whine: geared buzz gliding f0->f1, band-limited to the 1-4 kHz grille band."""
    out = [0.0] * n; ph = 0.0; tph = 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * (0.5 - 0.5 * math.cos(math.pi * min(1.0, t * 1.6)))
        ph += 2 * math.pi * f / SR; tph += 2 * math.pi * tick_hz / SR
        saw = (ph / math.pi) % 2 - 1
        teeth = 0.65 + 0.35 * (0.5 + 0.5 * math.sin(tph)) ** 4
        out[i] = (0.6 * saw + 0.25 * math.sin(2 * ph) + 0.08 * (rng.random() * 2 - 1)) * teeth * env_fn(i / SR)
    out = bpf(bpf(out, 2200, 0.9), 2200, 0.9)
    out = hpf(out, 900)
    p = peak(out) or 1.0
    return [v / p * level for v in out]


def exciter(x, amount):
    """Rasp: distort only the upper voice and keep the 1.2-4.5 kHz products (the 'grr' texture small speakers need)."""
    h = hpf(hpf(x, 700), 700)
    k = 1.0 / (peak(h) or 1.0)
    e = [math.tanh(3.0 * v * k) for v in h]
    e = hpf(e, 1200); e = lpf(lpf(e, 4500), 4500)
    g = amount * rms(x) / (rms(e) or 1.0)
    return [v + g * w for v, w in zip(x, e)]


def grille(x):
    """Small-speaker/grille voicing: formant lift, grille resonance, top-end roll-off."""
    y = peak_eq(x, 560, 3.0, 1.3)       # wolf vocal-tract F1 region, where phones play
    y = peak_eq(y, 1300, 4.0, 1.6)      # F2 presence
    y = peak_eq(y, 2450, 2.5, 3.5)      # grille/panel resonance
    y = low_shelf(y, 130, 2.0)          # keep a little chest
    y = high_shelf(y, 6000, -8.0)
    y = lpf(y, 8000)
    return y


def bitcrush_layer(x, wet, bits=9, hold=3):
    c = crush(x, bits, hold)
    c = bpf(c, 1800, 0.7)
    return [v + wet * w for v, w in zip(x, c)]


def finish(x, fin_ms, fout_ms, target_db=-6.0):
    y = hpf4(x, 42)          # nothing below ~40 Hz
    y = remove_dc(y)
    y = fade(y, fin_ms, fout_ms)
    y = normalize(y, target_db)
    y[0] = 0.0; y[-1] = 0.0
    return y


def robot_voice(x, rng, *, pitch, comb_delays, comb_fb, comb_wet, ring_fc, ring_depth,
                rough_rate, rough_depth, drive, crush_wet, rasp=0.45):
    v = resample_linear(x, pitch)                 # bigger animal: lower pitch, longer body
    v = am_rough(v, rough_rate, rough_depth, rng)  # 20-40 Hz growl roughness
    v = tanh_drive(normalize(v, -3.0), drive)      # harmonics so small speakers imply the low end
    v = ring(v, ring_fc, ring_depth)               # light ring mod -> inharmonic robot sheen
    v = chassis(v, comb_delays, comb_fb, 0.35, comb_wet)
    v = exciter(v, rasp)
    v = grille(v)
    v = bitcrush_layer(v, crush_wet)
    return v




def grille_r(x, low_hz=130, low_db=2.0, high_db=-8.0, extra_low=None):
    """grille() with the shelves exposed. REFINE: extra_low=(freq, dB) adds a second low shelf for body."""
    y = peak_eq(x, 560, 3.0, 1.3)
    y = peak_eq(y, 1300, 4.0, 1.6)
    y = peak_eq(y, 2450, 2.5, 3.5)
    y = low_shelf(y, low_hz, low_db)
    if extra_low:
        y = low_shelf(y, extra_low[0], extra_low[1])
    y = high_shelf(y, 6000, high_db)
    y = lpf(y, 8000)
    return y


def robot_voice_r(x, rng, *, pitch, comb_delays, comb_fb, comb_wet, ring_fc, ring_depth,
                  rough_rate, rough_depth, drive, crush_wet, rasp=0.45, grille_kw=None):
    v = resample_linear(x, pitch)
    v = am_rough(v, rough_rate, rough_depth, rng)
    v = tanh_drive(normalize(v, -3.0), drive)
    v = ring(v, ring_fc, ring_depth)
    v = chassis(v, comb_delays, comb_fb, 0.35, comb_wet)
    v = exciter(v, rasp)
    v = grille_r(v, **(grille_kw or {}))
    v = bitcrush_layer(v, crush_wet)
    return v


P = dict(seam_len=0.90, seam_fout=150, seam_pitch=0.76, seam_shelf=(160, 5.0), asr_b_pitch=0.70, asr_bear_gain=0.16, asr_bear_hp=400,
         asr_shelf=(150, 3.0), asr_high_db=-4.0)
for kv in sys.argv[3:]:
    k, v = kv.split("=", 1); P[k] = eval(v, {})


def main():
    os.makedirs(OUT, exist_ok=True)
    dog2, _ = read_wav(os.path.join(SRC, "dog2.wav"))
    dgr, _ = read_wav(os.path.join(SRC, "dog_growl.wav"))
    bear, _ = read_wav(os.path.join(SRC, "bear_02.wav"))
    made = {}

    # ---- seam-read rumble, REFINE: varispeed x0.86 -> x0.76 (f0 ~95-100 Hz) and a +5 dB low shelf (critic suggested +4; +5 lands below-200 Hz inside the 12-18% target)
    # at 160 Hz for headphone weight. Same source window, seeds and machine layers as before.
    rng = random.Random(SEED + 2)
    src = clean(cut(dog2, 5.53, 6.22))
    src = gate(src, -52, -14)
    src = compress(src, -34, 3.0)
    v = robot_voice_r(src, rng, pitch=P["seam_pitch"], comb_delays=[3.05, 4.62, 6.71], comb_fb=0.66, comb_wet=0.36,
                      ring_fc=61.0, ring_depth=0.16, rough_rate=24.0, rough_depth=0.18, drive=1.4, crush_wet=0.12, rasp=0.30,
                      grille_kw=dict(extra_low=P["seam_shelf"]))
    v = lpf(v, 5200)
    n = len(v)
    sv = servo(n, 1100, 1700, 0.05, lambda t: min(1, t / 0.08) * (0.6 + 0.4 * math.sin(2 * math.pi * 3.0 * t)) * max(0, 1 - t / 0.85), rng, tick_hz=48.0)
    v = mix((v, 1.0), (sv, 1.0))
    # REFINE: x0.76 stretches the 0.69 s source to ~0.91 s. Trimming back to 0.80 s would cut the
    # growl mid-body, so keep the source's own decay and let the clip run to seam_len seconds.
    v = v[:int(P["seam_len"] * SR)]
    made["wolf_growl_seam-r"] = finish(v, 15, P["seam_fout"])

    # ---- assertive growl, REFINE: one throat leads. Bear chest layer high-passed at 400 Hz and
    # dropped to -16 dB (texture only); Dog 2 voiced layer x0.78 -> x0.70 (f0 near 100 Hz) under the
    # bonebrah rasp; +3 dB low shelf at 150 Hz; the 6 kHz shelf relaxed from -8 to -4 dB.
    rng = random.Random(SEED + 3)
    gk = dict(high_db=P["asr_high_db"], extra_low=P["asr_shelf"])
    a = clean(dgr, 90)
    a = compress(a, -30, 3.0)
    b = clean(cut(dog2, 3.93, 4.47))
    b = gate(b, -48, -18)
    b = compress(b, -30, 3.0)
    c = clean(cut(bear, 0.08, 0.95), 80)
    c = resample_linear(c, 0.62)
    c = c[:int(0.95 * SR)]
    va = robot_voice_r(a, rng, pitch=0.76, comb_delays=[2.03, 3.17, 4.79], comb_fb=0.58, comb_wet=0.28,
                       ring_fc=111.0, ring_depth=0.28, rough_rate=36.0, rough_depth=0.25, drive=2.3, crush_wet=0.14, rasp=0.75,
                       grille_kw=gk)
    vb = robot_voice_r(b, rng, pitch=P["asr_b_pitch"], comb_delays=[2.03, 3.17, 4.79], comb_fb=0.58, comb_wet=0.28,
                       ring_fc=111.0, ring_depth=0.24, rough_rate=36.0, rough_depth=0.22, drive=2.0, crush_wet=0.10, rasp=0.6,
                       grille_kw=gk)
    vc = grille_r(tanh_drive(normalize(c, -3), 1.5), high_db=P["asr_high_db"])
    vc = hpf4(vc, P["asr_bear_hp"])
    # keep the bear at the same level relative to the other layers' RMS as a -16 dB send would give
    lead = 0.03
    pad = [0.0] * int(lead * SR)
    v = mix((pad + va, 0.85), (vb, 0.75), (pad + vc, P["asr_bear_gain"]))
    n = len(v)
    sv = servo(n, 1700, 2300, 0.045, lambda t: min(1, t / 0.03) * max(0, 1 - t / 0.35), rng, tick_hz=75.0)
    v = mix((v, 1.0), (sv, 1.0))
    v = v[:int(0.92 * SR)]
    made["wolf_growl_assertive-r"] = finish(v, 4, 120)

    for name, y in made.items():
        write_wav(os.path.join(OUT, name + ".wav"), y)
        print(name, "%.3f s" % (len(y) / SR))


main()
