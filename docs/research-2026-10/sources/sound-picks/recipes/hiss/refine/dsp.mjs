// Minimal DSP + measurement helpers (pure JS, no deps).
import fs from 'node:fs';

export const SR = 44100;

export function readF32(path) {
  const b = fs.readFileSync(path);
  return new Float32Array(b.buffer.slice(b.byteOffset, b.byteOffset + b.length - (b.length % 4)));
}

export function readWav16(path) {
  const buf = fs.readFileSync(path);
  let off = 12, fmt = null, data = null;
  while (off + 8 <= buf.length) {
    const id = buf.toString('ascii', off, off + 4);
    const size = buf.readUInt32LE(off + 4);
    if (id === 'fmt ') fmt = { format: buf.readUInt16LE(off + 8), channels: buf.readUInt16LE(off + 10), rate: buf.readUInt32LE(off + 12), bits: buf.readUInt16LE(off + 22) };
    if (id === 'data') data = buf.subarray(off + 8, off + 8 + size);
    off += 8 + size + (size & 1);
  }
  const n = data.length / 2;
  const s = new Float32Array(n);
  for (let i = 0; i < n; i++) s[i] = data.readInt16LE(i * 2) / 32768;
  return { fmt, s };
}

// 16-bit mono PCM WAV with optional 'smpl' loop chunk (whole file) for loops.
export function writeWav16(path, s, rate = SR, loop = false) {
  const n = s.length;
  const dataBytes = n * 2;
  const smplBytes = loop ? 8 + 36 + 24 : 0;
  const buf = Buffer.alloc(44 + dataBytes + smplBytes);
  buf.write('RIFF', 0); buf.writeUInt32LE(36 + dataBytes + smplBytes, 4); buf.write('WAVE', 8);
  buf.write('fmt ', 12); buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22);
  buf.writeUInt32LE(rate, 24); buf.writeUInt32LE(rate * 2, 28); buf.writeUInt16LE(2, 32); buf.writeUInt16LE(16, 34);
  buf.write('data', 36); buf.writeUInt32LE(dataBytes, 40);
  // TPDF dither
  let seed = 12345;
  const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
  for (let i = 0; i < n; i++) {
    let v = s[i] * 32767 + (rnd() - rnd());
    v = Math.max(-32768, Math.min(32767, Math.round(v)));
    buf.writeInt16LE(v, 44 + i * 2);
  }
  if (loop) {
    let o = 44 + dataBytes;
    buf.write('smpl', o); buf.writeUInt32LE(36 + 24, o + 4); o += 8;
    const f = [0, 0, Math.round(1e9 / rate), 60, 0, 0, 0, 1, 0];
    for (const v of f) { buf.writeUInt32LE(v, o); o += 4; }
    const l = [0, 0, 0, n - 1, 0, 0];
    for (const v of l) { buf.writeUInt32LE(v >>> 0, o); o += 4; }
  }
  fs.writeFileSync(path, buf);
}

// RBJ biquad
export function biquad(type, f0, q = 0.7071, gainDb = 0, sr = SR) {
  const A = Math.pow(10, gainDb / 40), w = 2 * Math.PI * f0 / sr, c = Math.cos(w), sn = Math.sin(w), al = sn / (2 * q);
  let b0, b1, b2, a0, a1, a2;
  switch (type) {
    case 'lp': b0 = (1 - c) / 2; b1 = 1 - c; b2 = (1 - c) / 2; a0 = 1 + al; a1 = -2 * c; a2 = 1 - al; break;
    case 'hp': b0 = (1 + c) / 2; b1 = -(1 + c); b2 = (1 + c) / 2; a0 = 1 + al; a1 = -2 * c; a2 = 1 - al; break;
    case 'bp': b0 = al; b1 = 0; b2 = -al; a0 = 1 + al; a1 = -2 * c; a2 = 1 - al; break;
    case 'peak': b0 = 1 + al * A; b1 = -2 * c; b2 = 1 - al * A; a0 = 1 + al / A; a1 = -2 * c; a2 = 1 - al / A; break;
    case 'lowshelf': { const s2 = 2 * Math.sqrt(A) * al; b0 = A * ((A + 1) - (A - 1) * c + s2); b1 = 2 * A * ((A - 1) - (A + 1) * c); b2 = A * ((A + 1) - (A - 1) * c - s2); a0 = (A + 1) + (A - 1) * c + s2; a1 = -2 * ((A - 1) + (A + 1) * c); a2 = (A + 1) + (A - 1) * c - s2; break; }
    case 'highshelf': { const s2 = 2 * Math.sqrt(A) * al; b0 = A * ((A + 1) + (A - 1) * c + s2); b1 = -2 * A * ((A - 1) + (A + 1) * c); b2 = A * ((A + 1) + (A - 1) * c - s2); a0 = (A + 1) - (A - 1) * c + s2; a1 = 2 * ((A - 1) - (A + 1) * c); a2 = (A + 1) - (A - 1) * c - s2; break; }
  }
  return { b0: b0 / a0, b1: b1 / a0, b2: b2 / a0, a1: a1 / a0, a2: a2 / a0, x1: 0, x2: 0, y1: 0, y2: 0 };
}
export function tick(f, x) {
  const y = f.b0 * x + f.b1 * f.x1 + f.b2 * f.x2 - f.a1 * f.y1 - f.a2 * f.y2;
  f.x2 = f.x1; f.x1 = x; f.y2 = f.y1; f.y1 = y; return y;
}
export function filt(s, ...filters) {
  const out = new Float32Array(s.length);
  for (let i = 0; i < s.length; i++) { let v = s[i]; for (const f of filters) v = tick(f, v); out[i] = v; }
  return out;
}
// zero-phase-ish: forward then backward (doubles slope, no phase smear on transients)
export function filtfb(s, mk) {
  const a = filt(s, ...mk());
  a.reverse();
  const b = filt(a, ...mk());
  b.reverse();
  return b;
}

export function slice(s, t0, t1, sr = SR) { return s.slice(Math.round(t0 * sr), Math.round(t1 * sr)); }
export function peak(s) { let p = 0; for (const x of s) p = Math.max(p, Math.abs(x)); return p; }
export function rms(s) { let a = 0; for (const x of s) a += x * x; return Math.sqrt(a / s.length); }
export function gain(s, g) { const o = new Float32Array(s.length); for (let i = 0; i < s.length; i++) o[i] = s[i] * g; return o; }
export function normPeak(s, db = -6) { return gain(s, Math.pow(10, db / 20) / (peak(s) || 1)); }
export function fadeEdges(s, inMs = 10, outMs = 20, sr = SR) {
  const o = Float32Array.from(s); const ni = Math.round(inMs * sr / 1000), no = Math.round(outMs * sr / 1000);
  for (let i = 0; i < ni && i < o.length; i++) o[i] *= 0.5 - 0.5 * Math.cos(Math.PI * i / ni);
  for (let i = 0; i < no && i < o.length; i++) o[o.length - 1 - i] *= 0.5 - 0.5 * Math.cos(Math.PI * i / no);
  return o;
}
export function mix(...parts) {
  const n = Math.max(...parts.map(p => p.length)); const o = new Float32Array(n);
  for (const p of parts) for (let i = 0; i < p.length; i++) o[i] += p[i];
  return o;
}
// Equal-power crossfade concatenation of chunks (each chunk >= 2*xf).
export function xfChain(chunks, xf) {
  let out = Float32Array.from(chunks[0]);
  for (let k = 1; k < chunks.length; k++) {
    const c = chunks[k]; const n = out.length + c.length - xf; const o = new Float32Array(n);
    o.set(out.subarray(0, out.length - xf));
    for (let i = 0; i < xf; i++) { const t = (i + 0.5) / xf; o[out.length - xf + i] = out[out.length - xf + i] * Math.cos(t * Math.PI / 2) + c[i] * Math.sin(t * Math.PI / 2); }
    o.set(c.subarray(xf), out.length);
    out = o;
  }
  return out;
}
// Make a seamless loop: crossfade the tail (last xf samples) into the head; result length = len - xf.
export function loopify(s, xf) {
  const n = s.length - xf; const o = Float32Array.from(s.subarray(0, n));
  for (let i = 0; i < xf; i++) { const t = (i + 0.5) / xf; o[i] = s[n + i] * Math.cos(t * Math.PI / 2) + s[i] * Math.sin(t * Math.PI / 2); }
  return o;
}

// FFT (radix-2, in place)
export function fft(re, im) {
  const n = re.length;
  for (let i = 1, j = 0; i < n; i++) { let bit = n >> 1; for (; j & bit; bit >>= 1) j ^= bit; j ^= bit; if (i < j) { [re[i], re[j]] = [re[j], re[i]]; [im[i], im[j]] = [im[j], im[i]]; } }
  for (let len = 2; len <= n; len <<= 1) {
    const ang = -2 * Math.PI / len, wr = Math.cos(ang), wi = Math.sin(ang);
    for (let i = 0; i < n; i += len) {
      let cr = 1, ci = 0;
      for (let j = 0; j < len / 2; j++) {
        const ur = re[i + j], ui = im[i + j];
        const vr = re[i + j + len / 2] * cr - im[i + j + len / 2] * ci, vi = re[i + j + len / 2] * ci + im[i + j + len / 2] * cr;
        re[i + j] = ur + vr; im[i + j] = ui + vi; re[i + j + len / 2] = ur - vr; im[i + j + len / 2] = ui - vi;
        const t = cr * wr - ci * wi; ci = cr * wi + ci * wr; cr = t;
      }
    }
  }
}
// Averaged power spectrum (Hann, N=4096, hop N/2)
export function psd(s, N = 4096) {
  const P = new Float64Array(N / 2); let frames = 0;
  const w = new Float64Array(N); for (let i = 0; i < N; i++) w[i] = 0.5 - 0.5 * Math.cos(2 * Math.PI * i / N);
  for (let st = 0; st + N <= s.length || (frames === 0 && st === 0); st += N / 2) {
    const re = new Float64Array(N), im = new Float64Array(N);
    for (let i = 0; i < N; i++) re[i] = (s[st + i] || 0) * w[i];
    fft(re, im);
    for (let k = 0; k < N / 2; k++) P[k] += re[k] * re[k] + im[k] * im[k];
    frames++;
    if (st + N > s.length) break;
  }
  return P;
}
export const BANDS = [[0, 40], [40, 100], [100, 300], [300, 1000], [1000, 2000], [2000, 5000], [5000, 8000], [8000, 22050]];
export function bands(s, sr = SR) {
  const N = 4096; const P = psd(s, N); let tot = 0; const b = BANDS.map(() => 0); let cen = 0;
  for (let k = 1; k < N / 2; k++) { const f = k * sr / N; tot += P[k]; cen += f * P[k]; for (let j = 0; j < BANDS.length; j++) if (f >= BANDS[j][0] && f < BANDS[j][1]) b[j] += P[k]; }
  const out = {}; BANDS.forEach(([a, z], j) => out[`${a}-${z}`] = +(100 * b[j] / tot).toFixed(1));
  return { band_pct: out, centroid_hz: Math.round(cen / tot), id_200_5k_pct: +(100 * bandSum(P, 200, 5000, sr, N) / tot).toFixed(1) };
}
function bandSum(P, a, z, sr, N) { let s = 0; for (let k = 1; k < N / 2; k++) { const f = k * sr / N; if (f >= a && f < z) s += P[k]; } return s; }

// Measurements matching the audition pass (peak, RMS, seam jump, median/p99 step) + extras.
export function measure(s, sr = SR, { loop = false } = {}) {
  let pk = 0, sum = 0; for (const x of s) { pk = Math.max(pk, Math.abs(x)); sum += x * x; }
  const steps = new Float32Array(s.length - 1); for (let i = 1; i < s.length; i++) steps[i - 1] = Math.abs(s[i] - s[i - 1]);
  const sorted = Float32Array.from(steps).sort();
  const median = sorted[Math.floor(sorted.length / 2)], p99 = sorted[Math.floor(sorted.length * 0.99)];
  // 50 ms RMS envelope for dynamics / loop-level continuity
  const W = Math.round(0.05 * sr); const env = [];
  for (let i = 0; i + W <= s.length; i += W) env.push(20 * Math.log10(rms(s.subarray(i, i + W)) + 1e-9));
  const head = env[0], tail = 20 * Math.log10(rms(s.subarray(s.length - W)) + 1e-9);  // true last 50 ms
  const m = {
    seconds: +(s.length / sr).toFixed(3), rate: sr,
    peak_db: +(20 * Math.log10(pk || 1e-9)).toFixed(2),
    rms_db: +(20 * Math.log10(Math.sqrt(sum / s.length) || 1e-9)).toFixed(2),
    crest_db: +(20 * Math.log10(pk / Math.sqrt(sum / s.length))).toFixed(1),
    seam_jump: +Math.abs(s[s.length - 1] - s[0]).toFixed(4),
    first_sample: +s[0].toFixed(4), last_sample: +s[s.length - 1].toFixed(4),
    median_step: +median.toFixed(4), p99_step: +p99.toFixed(4),
    env50ms_head_tail_db: [+head.toFixed(1), +tail.toFixed(1)],
    env50ms_min_max_db: [+Math.min(...env).toFixed(1), +Math.max(...env).toFixed(1)],
    ...bands(s, sr),
  };
  if (loop) {
    // seam relative to typical step, and level step across the wrap (50 ms either side)
    m.seam_vs_median = +(m.seam_jump / (median || 1e-9)).toFixed(2);
    { let below = 0; for (const v of steps) if (v < m.seam_jump) below++; m.seam_step_percentile = +(100 * below / steps.length).toFixed(1); }
    m.wrap_level_step_db = +Math.abs(tail - head).toFixed(2);
    // self-similarity: max normalised correlation of 0.25 s envelope at lags 0.5..(len/2) s — detects audible repetition
    const W2 = Math.round(0.02 * sr), e2 = [];
    for (let i = 0; i + W2 <= s.length; i += W2) e2.push(rms(s.subarray(i, i + W2)));
    // detrend: subtract a cyclic 1 s moving average so slow designed swells don't read as repetition
    const H = 25; const d = e2.map((v, i) => { let a = 0; for (let k = -H; k <= H; k++) a += e2[(i + k + e2.length) % e2.length]; return v - a / (2 * H + 1); });
    let best = 0, bestLag = 0; const den = d.reduce((a, b) => a + b * b, 0) || 1;
    for (let lag = Math.round(0.5 / 0.02); lag < d.length / 2; lag++) { let c = 0; for (let i = 0; i < d.length; i++) c += d[i] * d[(i + lag) % d.length]; c /= den; if (c > best) { best = c; bestLag = lag; } }
    m.envelope_selfcorr_max = +best.toFixed(3); m.envelope_selfcorr_lag_s = +(bestLag * 0.02).toFixed(2);
  }
  return m;
}
