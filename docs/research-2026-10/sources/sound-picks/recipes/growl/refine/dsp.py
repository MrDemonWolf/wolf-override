"""Stdlib-only DSP helpers for the WOLF growl recording track (no numpy available)."""
import math, struct, wave, cmath, random

SR = 44100


def read_wav(path):
    with wave.open(path, "rb") as w:
        sr, ch, sw, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(n)
    assert sw == 2, "16-bit only"
    vals = struct.unpack("<%dh" % (len(raw) // 2), raw)
    if ch > 1:
        vals = [sum(vals[i:i + ch]) / ch for i in range(0, len(vals), ch)]
    return [v / 32768.0 for v in vals], sr


def write_wav(path, x, sr=SR):
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes(struct.pack("<%dh" % len(x), *[max(-32768, min(32767, int(round(v * 32767)))) for v in x]))


# ---------- RBJ biquads ----------
def _biquad(x, b0, b1, b2, a0, a1, a2):
    b0 /= a0; b1 /= a0; b2 /= a0; a1 /= a0; a2 /= a0
    y = [0.0] * len(x); x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x):
        o = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, o
        y[i] = o
    return y


def hpf(x, f, q=0.707, sr=SR):
    w = 2 * math.pi * f / sr; c, s = math.cos(w), math.sin(w); a = s / (2 * q)
    return _biquad(x, (1 + c) / 2, -(1 + c), (1 + c) / 2, 1 + a, -2 * c, 1 - a)


def lpf(x, f, q=0.707, sr=SR):
    w = 2 * math.pi * f / sr; c, s = math.cos(w), math.sin(w); a = s / (2 * q)
    return _biquad(x, (1 - c) / 2, 1 - c, (1 - c) / 2, 1 + a, -2 * c, 1 - a)


def bpf(x, f, q=1.0, sr=SR):
    w = 2 * math.pi * f / sr; c, s = math.cos(w), math.sin(w); a = s / (2 * q)
    return _biquad(x, a, 0, -a, 1 + a, -2 * c, 1 - a)


def peak_eq(x, f, gain_db, q=1.0, sr=SR):
    A = 10 ** (gain_db / 40); w = 2 * math.pi * f / sr; c, s = math.cos(w), math.sin(w); a = s / (2 * q)
    return _biquad(x, 1 + a * A, -2 * c, 1 - a * A, 1 + a / A, -2 * c, 1 - a / A)


def low_shelf(x, f, gain_db, sr=SR):
    A = 10 ** (gain_db / 40); w = 2 * math.pi * f / sr; c, s = math.cos(w), math.sin(w)
    a = s / 2 * math.sqrt(2); sA = 2 * math.sqrt(A) * a
    return _biquad(x, A * ((A + 1) - (A - 1) * c + sA), 2 * A * ((A - 1) - (A + 1) * c), A * ((A + 1) - (A - 1) * c - sA),
                   (A + 1) + (A - 1) * c + sA, -2 * ((A - 1) + (A + 1) * c), (A + 1) + (A - 1) * c - sA)


def high_shelf(x, f, gain_db, sr=SR):
    A = 10 ** (gain_db / 40); w = 2 * math.pi * f / sr; c, s = math.cos(w), math.sin(w)
    a = s / 2 * math.sqrt(2); sA = 2 * math.sqrt(A) * a
    return _biquad(x, A * ((A + 1) + (A - 1) * c + sA), -2 * A * ((A - 1) + (A + 1) * c), A * ((A + 1) + (A - 1) * c - sA),
                   (A + 1) - (A - 1) * c + sA, 2 * ((A - 1) - (A + 1) * c), (A + 1) - (A - 1) * c - sA)


def hpf4(x, f, sr=SR):
    return hpf(hpf(x, f, 0.541, sr), f, 1.307, sr)


# ---------- utilities ----------
def mix(*pairs):
    n = max(len(s) for s, _ in pairs); out = [0.0] * n
    for s, g in pairs:
        for i, v in enumerate(s):
            out[i] += v * g
    return out


def gain(x, g):
    return [v * g for v in x]


def db(v):
    return 20 * math.log10(max(v, 1e-12))


def peak(x):
    return max(abs(v) for v in x)


def rms(x):
    return math.sqrt(sum(v * v for v in x) / max(1, len(x)))


def normalize(x, target_db=-6.0):
    p = peak(x); g = 10 ** (target_db / 20) / p
    return [v * g for v in x]


def remove_dc(x):
    m = sum(x) / len(x); return [v - m for v in x]


def fade(x, fin_ms=8, fout_ms=40, sr=SR):
    y = list(x); n = len(y); a = int(sr * fin_ms / 1000); b = int(sr * fout_ms / 1000)
    for i in range(min(a, n)):
        y[i] *= 0.5 - 0.5 * math.cos(math.pi * i / a)
    for i in range(min(b, n)):
        y[n - 1 - i] *= 0.5 - 0.5 * math.cos(math.pi * i / b)
    y[0] = 0.0; y[-1] = 0.0
    return y


def resample_linear(x, ratio):
    """Read x at speed `ratio` (ratio<1 lowers pitch and lengthens)."""
    n = int((len(x) - 1) / ratio); out = [0.0] * n
    for i in range(n):
        p = i * ratio; k = int(p); f = p - k
        out[i] = x[k] * (1 - f) + x[k + 1] * f
    return out


def resample_varying(x, ratio_fn, sr=SR):
    """Varispeed: ratio_fn(t_seconds_out) -> read speed."""
    out = []; p = 0.0; i = 0
    while p < len(x) - 2:
        k = int(p); f = p - k
        out.append(x[k] * (1 - f) + x[k + 1] * f)
        p += ratio_fn(i / sr); i += 1
    return out


def comb_ff(x, delay_s, g, sr=SR):
    d = delay_s * sr; out = [0.0] * len(x)
    for i in range(len(x)):
        p = i - d; k = int(math.floor(p)); f = p - k
        dv = 0.0
        if k >= 0:
            dv = x[k] * (1 - f) + (x[k + 1] * f if k + 1 < len(x) else 0)
        out[i] = x[i] + g * dv
    return out


def comb_fb(x, delay_s, fb, damp=0.3, sr=SR, tail_s=0.0):
    """Feedback comb with one-pole damping inside the loop (metallic resonance)."""
    d = max(1, int(round(delay_s * sr))); n = len(x) + int(tail_s * sr)
    buf = [0.0] * d; out = [0.0] * n; idx = 0; lp = 0.0
    for i in range(n):
        v = x[i] if i < len(x) else 0.0
        dv = buf[idx]
        lp = lp + (1 - damp) * (dv - lp)
        o = v + fb * lp
        buf[idx] = o; idx = (idx + 1) % d
        out[i] = dv
    return out


def envelope(x, att_ms=5, rel_ms=60, sr=SR):
    a = math.exp(-1 / (sr * att_ms / 1000)); r = math.exp(-1 / (sr * rel_ms / 1000)); e = 0.0; out = []
    for v in x:
        v = abs(v); c = a if v > e else r; e = c * e + (1 - c) * v; out.append(e)
    return out


def crush(x, bits=8, hold=2):
    q = 2 ** (bits - 1); out = []; last = 0.0
    for i, v in enumerate(x):
        if i % hold == 0:
            last = round(v * q) / q
        out.append(last)
    return out


def tanh_drive(x, drive):
    k = math.tanh(drive)
    return [math.tanh(v * drive) / k for v in x]


# ---------- spectrum ----------
def fft(a):
    n = len(a)
    if n == 1:
        return a
    ev = fft(a[0::2]); od = fft(a[1::2])
    tw = [cmath.exp(-2j * math.pi * k / n) * od[k] for k in range(n // 2)]
    return [ev[k] + tw[k] for k in range(n // 2)] + [ev[k] - tw[k] for k in range(n // 2)]


def power_spectrum(x, sr=SR, nfft=4096):
    """Averaged Hann-windowed power spectrum (Welch, 50% overlap)."""
    win = [0.5 - 0.5 * math.cos(2 * math.pi * i / nfft) for i in range(nfft)]
    acc = [0.0] * (nfft // 2); cnt = 0
    xs = list(x) + [0.0] * nfft
    for s in range(0, max(1, len(x) - nfft // 2), nfft // 2):
        seg = xs[s:s + nfft]
        if len(seg) < nfft:
            seg += [0.0] * (nfft - len(seg))
        sp = fft([complex(seg[i] * win[i], 0) for i in range(nfft)])
        for k in range(nfft // 2):
            acc[k] += abs(sp[k]) ** 2
        cnt += 1
    return [v / cnt for v in acc], sr / nfft


BANDS = [(0, 40), (40, 100), (100, 200), (200, 300), (300, 1000), (1000, 2000), (2000, 5000), (5000, 22050)]


def band_split(x, sr=SR):
    ps, df = power_spectrum(x, sr)
    tot = sum(ps) or 1e-20; out = {}
    for lo, hi in BANDS:
        out["%d-%d" % (lo, hi)] = round(100 * sum(p for k, p in enumerate(ps) if lo <= k * df < hi) / tot, 1)
    # spectral centroid
    cen = sum(k * df * p for k, p in enumerate(ps)) / tot
    return out, cen


def autocorr_pitch(seg, sr=SR, fmin=50, fmax=400):
    n = len(seg); best = (0, 0)
    e0 = sum(v * v for v in seg) or 1e-12
    for lag in range(int(sr / fmax), int(sr / fmin)):
        c = sum(seg[i] * seg[i + lag] for i in range(0, n - lag, 2))
        if c > best[0]:
            best = (c, lag)
    return (sr / best[1] if best[1] else 0), 2 * best[0] / e0
