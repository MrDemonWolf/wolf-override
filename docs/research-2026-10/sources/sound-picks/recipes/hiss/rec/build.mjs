// Steam hiss, recording track. Processes copies of three CC0 LaSonotheque/BigSoundBank recordings
// (Joseph Sardin) into: pressure-line loop x3 gauge levels, vent burst one-shot, coolant-cloud bed loop.
// Usage: node build.mjs <work dir with 0805.f32 1486.f32 0138.f32 (44.1 kHz mono f32)> <out dir>
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { SR, readF32, writeWav16, biquad, tick, filt, slice, rms, peak, gain, normPeak, fadeEdges, mix, xfChain, loopify, measure } from './dsp.mjs';

const [work, out] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const COOKER = readF32(path.join(work, '0805.f32'));   // pressure cooker, 99.5 s
const LEAK = readF32(path.join(work, '1486.f32'));     // air leak, 21.9 s
const AIR = readF32(path.join(work, '0138.f32'));      // compressed-air releases, 14.5 s

// deterministic PRNG
function mulberry(seed) { return () => { seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
const rnd = mulberry(20261010);

// Process a loop cyclically so IIR state wraps: run over [x,x], keep the second copy.
function cyc(x, fn) { const xx = new Float32Array(x.length * 2); xx.set(x); xx.set(x, x.length); const y = fn(xx); return y.slice(x.length); }
const eq = (...mk) => (x) => filt(x, ...mk.map(m => m()));
const lp4 = (f) => [() => biquad('lp', f, 0.54), () => biquad('lp', f, 1.31)];   // 4-pole Butterworth
const hp4 = (f) => [() => biquad('hp', f, 0.54), () => biquad('hp', f, 1.31)];

// Time-varying resonant band-pass (coefficients every 32 samples).
function tvBP(x, fFn, q) {
  const y = new Float32Array(x.length); let f = biquad('bp', fFn(0), q);
  for (let i = 0; i < x.length; i++) {
    if (i % 32 === 0) { const g = biquad('bp', fFn(i), q); g.x1 = f.x1; g.x2 = f.x2; g.y1 = f.y1; g.y2 = f.y2; f = g; }
    y[i] = tick(f, x[i]);
  }
  return y;
}
// Time-varying 2-pole low-pass (for falling-pressure sweeps).
function tvLP(x, fFn, q = 0.7071) {
  const y = new Float32Array(x.length); let f = biquad('lp', fFn(0), q);
  for (let i = 0; i < x.length; i++) {
    if (i % 32 === 0) { const g = biquad('lp', fFn(i), q); g.x1 = f.x1; g.x2 = f.x2; g.y1 = f.y1; g.y2 = f.y2; f = g; }
    y[i] = tick(f, x[i]);
  }
  return y;
}
// Loop-periodic LFO: sum of sines with integer cycles per loop.
function lfo(n, parts) { const o = new Float32Array(n); for (const [cyc_, amp, ph] of parts) for (let i = 0; i < n; i++) o[i] += amp * Math.sin(2 * Math.PI * cyc_ * i / n + ph); return o; }
// Loop-periodic smoothed random signal (cyclic low-pass of seeded noise), unit RMS.
function smoothNoise(n, fc) { const w = new Float32Array(n); for (let i = 0; i < n; i++) w[i] = rnd() * 2 - 1; const y = cyc(w, eq(() => biquad('lp', fc, 0.7071), () => biquad('lp', fc, 0.7071))); const r = rms(y) || 1; return gain(y, 1 / r); }

const unitRms = (x) => gain(x, 0.1 / (rms(x) || 1));

// Build a chunked hiss loop: chunks from both recordings at chosen offsets, each RMS-matched
// (this flattens the slow decay of both sources), joined with equal-power crossfades, then
// the tail is crossfaded into the head.
function chunkLoop(seconds, nChunks, xfS, leakMix, picks) {
  const xf = Math.round(xfS * SR); const total = Math.round(seconds * SR) + xf;
  const clen = Math.ceil((total + (nChunks - 1) * xf) / nChunks);
  const chunks = picks.slice(0, nChunks).map(([tc, tl]) => {
    const c = unitRms(COOKER.slice(Math.round(tc * SR), Math.round(tc * SR) + clen));
    const l = unitRms(LEAK.slice(Math.round(tl * SR), Math.round(tl * SR) + clen));
    return mix(c, gain(l, leakMix));
  });
  let chain = xfChain(chunks, xf).slice(0, total);
  const loop = loopify(chain, xf);
  return loop.slice(0, Math.round(seconds * SR));
}

// Pre-clean whole sources once (DC/rumble high-pass 2x40 Hz + 4-pole 120 Hz: nothing useful below).
function preclean(x) { return filt(x, ...hp4(120).map(m => m())); }
COOKER.set(preclean(COOKER)); LEAK.set(preclean(LEAK)); AIR.set(preclean(AIR));

const results = [];
function save(name, s, { loop = false, recipe, used_for, sources }) {
  const p = path.join(out, name + '.wav'); writeWav16(p, s, SR, loop);
  const m = measure(s, SR, { loop }); results.push({ id: name, wav: p, loop, recipe, used_for, sources, measurements: m });
  if (loop) { // 3x tiled audition copy to hear the seam
    const t = new Float32Array(s.length * 3); t.set(s); t.set(s, s.length); t.set(s, s.length * 2);
    writeWav16(path.join(out, name + '_x3_audition.wav'), t, SR, false);
  }
  // 22.05 kHz copy (game's current rate); loops resampled cyclically so the seam stays clean.
  const raw = path.join(out, '.tmp.f32'), raw2 = path.join(out, '.tmp2.f32');
  const src = loop ? (() => { const t = new Float32Array(s.length * 3); t.set(s); t.set(s, s.length); t.set(s, s.length * 2); return t; })() : s;
  fs.writeFileSync(raw, Buffer.from(src.buffer, src.byteOffset, src.byteLength));
  execFileSync('ffmpeg', ['-v', 'error', '-y', '-f', 'f32le', '-ar', String(SR), '-ac', '1', '-i', raw, '-af', 'aresample=22050:filter_size=64:cutoff=0.95', '-f', 'f32le', raw2]);
  let d = readF32(raw2); const n22 = Math.round(s.length * 22050 / SR);
  d = loop ? d.slice(n22, 2 * n22) : d.slice(0, n22);
  if (!loop) d = fadeEdges(d, 2, 5, 22050);
  writeWav16(path.join(out, name + '_22k.wav'), d, 22050, loop);
  results[results.length - 1].measurements_22k = measure(d, 22050, { loop });
  fs.rmSync(raw); fs.rmSync(raw2);
}

// ---------------------------------------------------------------- pressure-line loop (6 s, 3 gauges)
const L = 6.0, N = Math.round(L * SR);
// chunk picks: [cooker offset s (23..88 = loud steady venting), air-leak offset s]
const picks = [[24.3, 1.2], [37.9, 9.7], [51.2, 4.4], [66.8, 15.1], [44.6, 12.6], [30.5, 18.3]];
const base = chunkLoop(L, 5, 0.3, 0.7, picks);
const baseAlt = chunkLoop(L, 5, 0.3, 0.7, picks.slice(1).concat([picks[0]]));  // decorrelated twin for the spectral morph

const GAUGE = {
  low:  { dark: 1600, bright: 2500, shelfLo: 8, presF: 1000, presG: 4, depth: 0.16, gurgle: 0.45, whistle: 0.0,  hsG: -5 },
  mid:  { dark: 2300, bright: 3500, shelfLo: 7, presF: 1700, presG: 3, depth: 0.22, gurgle: 0.30, whistle: 0.10, hsG: -5 },
  high: { dark: 3000, bright: 4600, shelfLo: 6, presF: 2400, presG: 3, depth: 0.30, gurgle: 0.15, whistle: 0.22, hsG: -5 },
};
// Shared slow turbulence and morph LFOs (integer cycles per 6 s loop => seamless); random phases.
const ph = () => rnd() * 2 * Math.PI;
const turb = lfo(N, [[1, 0.45, ph()], [3, 0.3, ph()], [5, 0.22, ph()], [8, 0.16, ph()], [13, 0.1, ph()]]);
const morph = lfo(N, [[2, 0.6, ph()], [7, 0.3, ph()], [11, 0.1, ph()]]);
const flutter = smoothNoise(N, 9);    // fast turbulence, ~9 Hz bandwidth
const gurgleEnv = smoothNoise(N, 8);

for (const [lvl, g] of Object.entries(GAUGE)) {
  const body = (x, lpF) => cyc(x, eq(
    ...lp4(lpF),
    () => biquad('lowshelf', 700, 0.7, g.shelfLo),
    () => biquad('peak', g.presF, 0.9, g.presG),
    () => biquad('highshelf', 4500, 0.7, g.hsG),
    () => biquad('hp', 40, 0.7071), () => biquad('hp', 40, 0.7071)));
  const dark = body(base, g.dark), bright = body(baseAlt, g.bright);
  // pressure-dependent spectral tilt over time: crossfade dark <-> bright with the morph LFO (equal-power)
  const hiss = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    const w = 0.5 + 0.5 * Math.max(-1, Math.min(1, morph[i]));
    const a = 1 + g.depth * turb[i] + g.depth * 0.35 * flutter[i];
    hiss[i] = a * (dark[i] * Math.cos(w * Math.PI / 2) + bright[i] * Math.sin(w * Math.PI / 2));
  }
  // gurgle: low-mid band of the recorded cooker hiss, gated by a 14 Hz random envelope (condensate spitting)
  const gsrc = cyc(base, eq(...hp4(260), ...lp4(780), () => biquad('peak', 480, 3, 6)));
  const gurgle = new Float32Array(N);
  for (let i = 0; i < N; i++) { const e = Math.max(0, gurgleEnv[i] - 0.35); gurgle[i] = gsrc[i] * e; }
  // soft-limit the gurgle so single spits never set the clip peak
  { const r = rms(gurgle) || 1; for (let i = 0; i < N; i++) gurgle[i] = r * 2.5 * Math.tanh(gurgle[i] / (r * 2.5)); }
  const gScale = g.gurgle * rms(hiss) / (rms(gurgle) || 1);
  // valve whistle: the hiss itself through two resonant band-passes (fundamental + 2nd partial) with slow pitch drift
  let whistle = new Float32Array(N);
  if (g.whistle > 0) {
    const f0 = lvl === 'high' ? 1530 : 1390;
    const drift = lfo(N, [[1, 0.012, ph()], [4, 0.004, ph()]]);
    const wEnv = lfo(N, [[3, 0.5, ph()], [2, 0.3, ph()]]);
    const p1 = cyc(base, (x) => tvBP(x, (i) => f0 * (1 + drift[i % N]), 45));
    const p2 = cyc(base, (x) => tvBP(x, (i) => 2 * f0 * (1 + drift[i % N]), 60));
    const p3 = cyc(base, (x) => tvBP(x, (i) => 3.02 * f0 * (1 + drift[i % N]), 70));
    for (let i = 0; i < N; i++) { const e = Math.max(0, 0.55 + wEnv[i]); whistle[i] = e * (p1[i] + 0.55 * p2[i] + 0.2 * p3[i]); }
    whistle = gain(whistle, g.whistle * rms(hiss) / (rms(whistle) || 1));
  }
  const loopOut = normPeak(mix(hiss, gain(gurgle, gScale), whistle), -6);
  save(`pressure_loop_${lvl}`, loopOut, {
    loop: true,
    recipe: `6.0 s loop. 5 chunks (1.5 s) of the pressure-cooker venting hiss (0805 @ ${picks.slice(0, 5).map(p => p[0]).join('/')} s) + air leak (1486, -3 dB), each RMS-matched, joined with 0.3 s equal-power crossfades and tail->head crossfade. Cyclic EQ: HP 120 Hz (4-pole) + 2x HP 40 Hz, LP 4-pole morphing ${g.dark}->${g.bright} Hz (equal-power blend of two decorrelated chains driven by a 2/7/11-cycle LFO), low shelf +${g.shelfLo} dB @700 Hz, presence +${g.presG} dB @${g.presF} Hz, high shelf ${g.hsG} dB @4.5 kHz. Turbulence: AM depth ${g.depth} from 1/3/5/8/13-cycles-per-loop sines + 9 Hz smoothed noise. Gurgle: 260-780 Hz band of the same hiss gated by an 8 Hz smoothed random envelope (above threshold), tanh soft-limited, at ${g.gurgle}x hiss RMS. ${g.whistle ? `Valve whistle: the hiss through resonant band-passes (Q 45/60/70) at ${lvl === 'high' ? 1530 : 1390} Hz x1/x2/x3.02 with +/-1.2% drift, ${g.whistle}x hiss RMS.` : 'No whistle.'} Peak -6 dBFS.`,
    used_for: `Junction pressure-line loop, gauge ${lvl} (game crossfades/levels -28..-8 dB).`,
    sources: ['0805', '1486'],
  });
}

// ---------------------------------------------------------------- vent burst one-shot (~2.4 s)
{
  const total = Math.round(2.4 * SR); const o = new Float32Array(total);
  // 1) sputter: four short grains cut from the compressed-air release onsets (0138), each 18-45 ms, gaps shrinking
  const grainSrc = [2.27, 4.52, 6.27, 8.49, 9.77, 11.27, 13.52];
  const sputT = [0.0, 0.07, 0.125, 0.165, 0.195]; const sputL = [0.022, 0.03, 0.026, 0.04, 0.035]; const sputG = [0.35, 0.5, 0.45, 0.7, 0.6];
  const sputBP = eq(...hp4(700), ...lp4(5200), () => biquad('peak', 2600, 1.2, 4));
  sputT.forEach((t, k) => {
    const s0 = Math.round(grainSrc[k % grainSrc.length] * SR) + Math.round(rnd() * 0.05 * SR);
    let gr = sputBP(AIR.slice(s0, s0 + Math.round(sputL[k] * SR) + 400)).slice(400);
    gr = fadeEdges(unitRms(gr), 2, 8);
    const at = Math.round(t * SR); for (let i = 0; i < gr.length && at + i < total; i++) o[at + i] += gr[i] * sputG[k] * 4;
  });
  // 2) main body: the pressure-cooker lid release (0805 91.40-93.80 s), with the air-release transient (0138 @2.27) on top
  const bodyStart = Math.round(0.19 * SR);
  let body = slice(COOKER, 91.68, 94.08);
  body = filt(body, ...hp4(180).map(m => m()), biquad('peak', 2400, 0.8, 3), biquad('lowshelf', 600, 0.7, 5));
  // falling pressure: low-pass sweeps 6 kHz -> 1.6 kHz over the decay
  body = tvLP(body, (i) => 1600 + 4400 * Math.exp(-i / (0.9 * SR)), 0.9);
  body = tvLP(body, (i) => 1600 + 4400 * Math.exp(-i / (0.9 * SR)), 0.6);
  // the recording's own swell starts ~0.15 s in; pull forward with a fast attack envelope
  const env = (i) => Math.min(1, i / (0.012 * SR));
  for (let i = 0; i < body.length; i++) body[i] *= env(i);
  body = gain(unitRms(body), 3.2);
  let crack = slice(AIR, 2.24, 2.84);
  crack = filt(crack, ...hp4(500).map(m => m()), ...lp4(5500).map(m => m()), biquad('peak', 3000, 1, 3));
  crack = gain(unitRms(fadeEdges(crack, 1, 300)), 2.0);
  for (let i = 0; i < body.length && bodyStart + i < total; i++) o[bodyStart + i] += body[i];
  for (let i = 0; i < crack.length && bodyStart + i < total; i++) o[bodyStart + i] += crack[i];
  // 3) gentle 40 Hz HP and tail fade
  let v = filt(o, biquad('hp', 40, 0.7071), biquad('hp', 40, 0.7071));
  // exponential tail fade over the last 0.5 s so it dies, not stops
  for (let i = 0; i < v.length; i++) { const t = i / SR; if (t > 1.9) v[i] *= Math.pow(0.5 + 0.5 * Math.cos(Math.PI * (t - 1.9) / 0.5), 1.5); }
  v = fadeEdges(normPeak(v, -6), 1, 20);
  save('vent_burst', v, {
    recipe: 'Sputter: 5 grains (22-40 ms, band-passed 700-5200 Hz, +4 dB @2.6 kHz) cut from the compressed-air release onsets (0138), spaced 70->30 ms over 0.2 s. Body at 0.19 s: pressure-cooker lid release (0805 91.68-94.08 s, 12 ms fade-in), HP 180 Hz 4-pole, low shelf +5 dB @600, +3 dB @2.4 kHz, two time-varying low-passes sweeping 6 kHz -> 1.6 kHz (tau 0.9 s) for falling pressure, air-release transient (0138 2.24-2.84 s, 500-5500 Hz, 300 ms fade) on the onset. 2x HP 40 Hz, raised-cosine tail fade from 1.9 s, peak -6 dBFS.',
    used_for: 'Relief vent letting go (breaker trip at gauge peak); can sit on top of / replace small_boom.',
    sources: ['0138', '0805'],
  });
}

// ---------------------------------------------------------------- coolant-cloud bed (8 s loop)
{
  const LC = 8.0, NC = Math.round(LC * SR);
  const cp = [[28.1, 3.1], [59.4, 11.0], [72.7, 6.6], [41.3, 16.4], [81.0, 0.6], [34.2, 13.2]];
  const a = chunkLoop(LC, 5, 0.45, 0.45, cp), b = chunkLoop(LC, 5, 0.45, 0.45, cp.slice(2).concat(cp.slice(0, 2)));
  const soft = (x, f) => cyc(x, eq(...lp4(f), () => biquad('lowshelf', 520, 0.6, 8), () => biquad('peak', 950, 0.7, 3), () => biquad('highshelf', 3000, 0.7, -6), () => biquad('hp', 40, 0.7071), () => biquad('hp', 40, 0.7071)));
  const d = soft(a, 1300), br = soft(b, 2600);
  const billow = lfo(NC, [[1, 0.2, ph()], [2, 0.4, ph()], [3, 0.3, ph()], [5, 0.15, ph()]]);
  const sw = lfo(NC, [[2, 0.55, ph()], [3, 0.35, ph()], [5, 0.15, ph()]]);
  const fl = smoothNoise(NC, 4);
  const bed = new Float32Array(NC);
  for (let i = 0; i < NC; i++) {
    const w = 0.5 + 0.5 * Math.max(-1, Math.min(1, sw[i]));
    const amp = 1 + 0.32 * billow[i] + 0.08 * fl[i];
    bed[i] = amp * (d[i] * Math.cos(w * Math.PI / 2) + br[i] * Math.sin(w * Math.PI / 2));
  }
  save('coolant_cloud_bed', normPeak(bed, -6), {
    loop: true,
    recipe: '8.0 s loop (not a multiple of the 6 s pressure loop, so the two never lock). 5 chunks of cooker venting hiss (0805) + air leak (1486, -7 dB), RMS-matched, 0.45 s equal-power crossfades, tail->head crossfade. Two decorrelated chains low-passed (4-pole) at 1.3 kHz and 2.6 kHz, equal-power morph on a 2/3/5-cycles-per-loop LFO; low shelf +8 dB @520 Hz, +3 dB @950 Hz, high shelf -6 dB @3 kHz, 2x HP 40 Hz; billowing AM (1/2/3/5 cycles per loop, depth 0.32, weighted to 2-3 cycles) + 4 Hz smoothed-noise flutter. Peak -6 dBFS.',
    used_for: 'Coolant cloud (soft, rolling steam bed; play at low level, fade in/out).',
    sources: ['0805', '1486'],
  });
}

fs.writeFileSync(path.join(out, 'manifest.json'), JSON.stringify(results, null, 1));
for (const r of results) console.log(r.id, JSON.stringify(r.measurements));
