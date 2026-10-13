class_name ArcSynth
extends RefCounted
## Audition recipes for the electrical arc family, written in SfxBank's style (static recipes that
## take a seeded RandomNumberGenerator and return a PackedFloat32Array, packed by _wav to 16-bit mono
## at a -6 dB peak) so one of them can replace SfxBank._arc later. Nothing here is in the game.
## Three recipes (A, B, C) each render the same three deliverables from the same timing plans:
##   relay_spark  - the corridor relay contact: one small snap and a short spit of crackle.
##   bolt_arc     - the junction exit bolt: buzz and crackle build for 0.5 s, then it cracks.
##   records_arc  - the Records exit: the bolt lets go with a crack, a restrike and a sizzle tail.
## Shared rules: 44.1 kHz so the sizzle keeps its air, the buzz sits on 120 Hz (US 60 Hz mains,
## twice-per-cycle magnetostriction and arc reignition) but is carried by its 240 Hz-2.4 kHz
## harmonics so phones hear it, rumble below 40 Hz is high-passed out, everything above about
## 9 kHz is rolled off, and every clip starts and ends on exactly 0.

const MIX_RATE: int = 44100
const SEED: int = 0x574F4C46
## -6.02 dB, the loudest sample any clip reaches before the bus gain.
const PEAK: float = 0.5
const MAINS_HZ: float = 60.0
const BUZZ_HZ: float = 120.0
const RECIPES: Array[StringName] = [&"a", &"b", &"c"]
const CLIPS: Array[StringName] = [&"relay_spark", &"bolt_arc", &"records_arc"]

enum { LOWPASS, HIGHPASS, BANDPASS, HIGHSHELF, PEAKING }

## Timing plans shared by every recipe, so A, B and C differ only in how each layer is made.
## crack_at: the main strike. restrike_at: a smaller second strike (-1 for none).
## build_rate: crackle impulses per second at the start and end of the build (before crack_at).
## post_rate / post_tau: crackle rate right after the strike and how fast it thins.
## buzz_pre: buzz level reached at the end of the build. buzz_post / buzz_hold / buzz_tau: buzz
## after the strike. zap_seconds / zap: the falling high-voltage sweep. tail / tail_tau: sizzle.
const PLANS: Dictionary = {
	&"relay_spark": {
		"seconds": 0.34, "crack_at": 0.004, "crack": 0.65, "restrike_at": 0.055, "restrike": 0.3,
		"build_rate": [0.0, 0.0], "post_rate": 240.0, "post_tau": 0.05,
		"buzz_pre": 0.0, "buzz_post": 0.45, "buzz_hold": 0.025, "buzz_tau": 0.03,
		"zap_seconds": 0.035, "zap": 0.35, "tail": 0.22, "tail_tau": 0.06,
	},
	&"bolt_arc": {
		"seconds": 0.8, "crack_at": 0.5, "crack": 1.0, "restrike_at": 0.585, "restrike": 0.45,
		"build_rate": [15.0, 230.0], "post_rate": 320.0, "post_tau": 0.085,
		"buzz_pre": 0.7, "buzz_post": 0.8, "buzz_hold": 0.05, "buzz_tau": 0.07,
		"zap_seconds": 0.09, "zap": 0.6, "tail": 0.35, "tail_tau": 0.1,
	},
	&"records_arc": {
		"seconds": 0.65, "crack_at": 0.006, "crack": 1.0, "restrike_at": 0.15, "restrike": 0.55,
		"build_rate": [0.0, 0.0], "post_rate": 280.0, "post_tau": 0.15,
		"buzz_pre": 0.0, "buzz_post": 0.75, "buzz_hold": 0.1, "buzz_tau": 0.11,
		"zap_seconds": 0.08, "zap": 0.55, "tail": 0.35, "tail_tau": 0.18,
	},
}


## Renders one deliverable of one recipe from [param seed]; the same arguments give the same bytes.
static func make(recipe: StringName, clip: StringName, seed: int = SEED) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	return _wav(render(rng, recipe, clip), false)


static func render(rng: RandomNumberGenerator, recipe: StringName, clip: StringName) -> PackedFloat32Array:
	var plan: Dictionary = PLANS[clip]
	match recipe:
		&"a":
			return _recipe_a(rng, plan)
		&"b":
			return _recipe_b(rng, plan)
		_:
			return _recipe_c(rng, plan)


# --- Building blocks --------------------------------------------------------------------------

static func _zeros(frames: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	return out


static func _white(rng: RandomNumberGenerator, frames: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = _zeros(frames)
	for i: int in frames:
		out[i] = rng.randf_range(-1.0, 1.0)
	return out


## RBJ Audio EQ Cookbook biquad (direct form I) over the whole buffer. BANDPASS has a 0 dB peak;
## HIGHSHELF and PEAKING take [param gain_db].
static func _biquad(input: PackedFloat32Array, kind: int, freq: float, q: float, gain_db: float = 0.0) -> PackedFloat32Array:
	var w0: float = TAU * freq / MIX_RATE
	var cw: float = cos(w0)
	var alpha: float = sin(w0) / (2.0 * q)
	var a: float = pow(10.0, gain_db / 40.0)
	var b0: float
	var b1: float
	var b2: float
	var a0: float
	var a1: float
	var a2: float
	match kind:
		LOWPASS:
			b0 = (1.0 - cw) * 0.5
			b1 = 1.0 - cw
			b2 = b0
			a0 = 1.0 + alpha
			a1 = -2.0 * cw
			a2 = 1.0 - alpha
		HIGHPASS:
			b0 = (1.0 + cw) * 0.5
			b1 = -(1.0 + cw)
			b2 = b0
			a0 = 1.0 + alpha
			a1 = -2.0 * cw
			a2 = 1.0 - alpha
		BANDPASS:
			b0 = alpha
			b1 = 0.0
			b2 = -alpha
			a0 = 1.0 + alpha
			a1 = -2.0 * cw
			a2 = 1.0 - alpha
		PEAKING:
			b0 = 1.0 + alpha * a
			b1 = -2.0 * cw
			b2 = 1.0 - alpha * a
			a0 = 1.0 + alpha / a
			a1 = -2.0 * cw
			a2 = 1.0 - alpha / a
		_:
			var sa: float = 2.0 * sqrt(a) * alpha
			b0 = a * ((a + 1.0) + (a - 1.0) * cw + sa)
			b1 = -2.0 * a * ((a - 1.0) + (a + 1.0) * cw)
			b2 = a * ((a + 1.0) + (a - 1.0) * cw - sa)
			a0 = (a + 1.0) - (a - 1.0) * cw + sa
			a1 = 2.0 * ((a - 1.0) - (a + 1.0) * cw)
			a2 = (a + 1.0) - (a - 1.0) * cw - sa
	b0 /= a0
	b1 /= a0
	b2 /= a0
	a1 /= a0
	a2 /= a0
	var out: PackedFloat32Array = _zeros(input.size())
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	for i: int in input.size():
		var x: float = input[i]
		var y: float = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		out[i] = y
	return out


## A band-pass whose centre glides exponentially from [param from_hz] to [param to_hz] over
## [param seconds]; coefficients are refreshed every 16 samples (a swept resonant filter).
static func _swept_bandpass(input: PackedFloat32Array, from_hz: float, to_hz: float, seconds: float, q: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = _zeros(input.size())
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	var b0: float = 0.0
	var a1: float = 0.0
	var a2: float = 0.0
	for i: int in input.size():
		if i % 16 == 0:
			var progress: float = minf(float(i) / (seconds * MIX_RATE), 1.0)
			var freq: float = from_hz * pow(to_hz / from_hz, progress)
			var w0: float = TAU * freq / MIX_RATE
			var alpha: float = sin(w0) / (2.0 * q)
			b0 = alpha / (1.0 + alpha)
			a1 = -2.0 * cos(w0) / (1.0 + alpha)
			a2 = (1.0 - alpha) / (1.0 + alpha)
		var x: float = input[i]
		var y: float = b0 * x - b0 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		out[i] = y
	return out


## One-pole smoothed noise in -1..1 (roughly), for slow wobble and amplitude flicker.
static func _smooth_noise(rng: RandomNumberGenerator, frames: int, cutoff: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = _zeros(frames)
	var dt: float = 1.0 / MIX_RATE
	var alpha: float = dt / (1.0 / (TAU * cutoff) + dt)
	var gain: float = sqrt(3.0 / alpha)
	var state: float = 0.0
	for i: int in frames:
		state += alpha * (rng.randf_range(-1.0, 1.0) - state)
		out[i] = clampf(state * gain * 0.35, -1.0, 1.0)
	return out


## Feedback comb (Farnell's comb1): a short delay that rings the buzz like a metal enclosure.
static func _comb(input: PackedFloat32Array, delay_s: float, feedback: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = _zeros(input.size())
	var d: int = maxi(int(delay_s * MIX_RATE), 1)
	for i: int in input.size():
		out[i] = input[i] + (out[i - d] * feedback if i >= d else 0.0)
	return out


## One period of a 120 Hz harmonic series (amplitude 1 / k^[param tilt], fixed random phases),
## 2048 points, band-limited to [param harmonics] partials so it never aliases.
static func _harmonic_table(rng: RandomNumberGenerator, harmonics: int, tilt: float, odd_boost: float) -> PackedFloat32Array:
	var size: int = 2048
	var table: PackedFloat32Array = _zeros(size)
	for k: int in range(1, harmonics + 1):
		var amp: float = 1.0 / pow(float(k), tilt) * (odd_boost if k % 2 == 1 else 1.0)
		var phase: float = rng.randf() * TAU
		for i: int in size:
			table[i] += amp * sin(TAU * k * float(i) / size + phase)
	var peak: float = 0.0
	for v: float in table:
		peak = maxf(peak, absf(v))
	for i: int in size:
		table[i] /= peak
	return table


static func _table_read(table: PackedFloat32Array, phase: float) -> float:
	var pos: float = phase * table.size()
	var index: int = int(pos) % table.size()
	return lerpf(table[index], table[(index + 1) % table.size()], pos - floorf(pos))


## How far through the build [param t] is (0..1), or 1 after the strike.
static func _progress(t: float, plan: Dictionary) -> float:
	var crack_at: float = plan["crack_at"]
	return 1.0 if t >= crack_at or crack_at < 0.05 else t / crack_at


## Buzz level: swells over the build, holds after the strike, then decays.
static func _buzz_env(t: float, plan: Dictionary) -> float:
	var crack_at: float = plan["crack_at"]
	if t < crack_at:
		return plan["buzz_pre"] * pow(t / crack_at, 1.6) if crack_at >= 0.05 else 0.0
	var d: float = t - crack_at
	var hold: float = plan["buzz_hold"]
	var level: float = plan["buzz_post"]
	return level * minf(d / 0.002, 1.0) * (1.0 if d < hold else exp(-(d - hold) / plan["buzz_tau"]))


## Crackle impulses per second at [param t].
static func _crackle_rate(t: float, plan: Dictionary) -> float:
	var crack_at: float = plan["crack_at"]
	if t < crack_at:
		if crack_at < 0.05:
			return 0.0
		var rates: Array = plan["build_rate"]
		return lerpf(rates[0], rates[1], pow(t / crack_at, 2.0))
	var rate: float = plan["post_rate"] * exp(-(t - crack_at) / plan["post_tau"])
	var restrike_at: float = plan["restrike_at"]
	if restrike_at > 0.0 and t >= restrike_at:
		rate += plan["post_rate"] * 0.6 * exp(-(t - restrike_at) / (plan["post_tau"] * 0.7))
	return rate


## After a strike, later impulses get quieter as well as rarer, so no lone pop sits in the tail.
static func _crackle_level(t: float, plan: Dictionary) -> float:
	var crack_at: float = plan["crack_at"]
	if t < crack_at:
		return 1.0
	var level: float = exp(-(t - crack_at) / (plan["post_tau"] * 2.0))
	var restrike_at: float = plan["restrike_at"]
	if restrike_at > 0.0 and t >= restrike_at:
		level = maxf(level, 0.7 * exp(-(t - restrike_at) / (plan["post_tau"] * 1.4)))
	return 0.03 + 0.97 * level


## Sizzle level: creeps up during a build, blooms after the strike and dies away.
static func _tail_env(t: float, plan: Dictionary) -> float:
	var crack_at: float = plan["crack_at"]
	if t < crack_at:
		return plan["tail"] * 0.35 * pow(t / crack_at, 3.0) if crack_at >= 0.05 else 0.0
	var d: float = t - crack_at
	return plan["tail"] * (1.0 - exp(-d / 0.008)) * exp(-d / plan["tail_tau"])


## Crackle events as [time, amplitude] pairs: a thinned Poisson process following _crackle_rate.
## With [param lock_mains] the impulses bunch near the voltage peaks of the 60 Hz cycle (an arc
## reignites twice per cycle), which is what makes real crackle sound mains-driven.
static func _crackle_events(rng: RandomNumberGenerator, plan: Dictionary, lock_mains: bool) -> Array:
	var events: Array = []
	var seconds: float = plan["seconds"]
	var max_rate: float = 900.0
	var t: float = 0.0
	while true:
		t += -log(maxf(rng.randf(), 1e-6)) / max_rate
		if t >= seconds - 0.035:
			break
		var accept: float = _crackle_rate(t, plan) / max_rate
		if lock_mains:
			accept *= (8.0 / 3.0) * pow(sin(TAU * MAINS_HZ * t), 4.0)
		if rng.randf() < accept:
			var level: float = lerpf(0.3, 1.0, _progress(t, plan)) * _crackle_level(t, plan)
			events.append([t, (0.12 + 0.88 * pow(rng.randf(), 2.4)) * level])
	return events


## Mixes [param layer] into [param out] at [param gain].
static func _mix(out: PackedFloat32Array, layer: PackedFloat32Array, gain: float) -> void:
	for i: int in out.size():
		out[i] += layer[i] * gain


## Shared output stage: 40 Hz high-pass x2, a 9 kHz low-pass and a high shelf that tilts the fizz
## down, then tanh bus saturation last (so no filter overshoot undoes it: it lowers the crest so the
## arc reads as loud as the other clips at the same peak), then raised-cosine edges so the clip
## starts and ends on exactly 0.
static func _finish(samples: PackedFloat32Array, drive: float, shelf_db: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = _biquad(samples, HIGHPASS, 40.0, 0.707)
	out = _biquad(out, HIGHPASS, 40.0, 0.707)
	out = _biquad(out, LOWPASS, 9000.0, 0.707)
	out = _biquad(out, HIGHSHELF, 5000.0, 0.707, shelf_db)
	var peak: float = 0.0
	for v: float in out:
		peak = maxf(peak, absf(v))
	if peak <= 0.0:
		return out
	for i: int in out.size():
		out[i] = tanh(drive * out[i] / peak) / tanh(drive)
	var fade_in: int = int(0.0015 * MIX_RATE)
	var fade_out: int = int(0.025 * MIX_RATE)
	var n: int = out.size()
	for i: int in fade_in:
		out[i] *= 0.5 - 0.5 * cos(PI * float(i) / fade_in)
	for i: int in fade_out:
		out[n - 1 - i] *= 0.5 - 0.5 * cos(PI * float(i) / fade_out)
	out[0] = 0.0
	out[n - 1] = 0.0
	return out


# --- Recipe A: Farnell-style layers -----------------------------------------------------------
# Detuned 119.8 / 120.2 Hz buzz (beating), soft-clipped and rung through a short comb; chirp-impulse
# crackle phase-locked to the mains peaks; a snap made of an FM sine sweep plus a noise burst
# through a formant bank (480 / 720 / 2600 / 4600 / 7200 Hz); a falling zap ring-modulated by
# the 120 Hz buzz; band-passed sizzle with random amplitude flicker.

static func _recipe_a(rng: RandomNumberGenerator, plan: Dictionary) -> PackedFloat32Array:
	var n: int = int(plan["seconds"] * MIX_RATE)
	var dt: float = 1.0 / MIX_RATE
	var crack_at: float = plan["crack_at"]
	var out: PackedFloat32Array = _zeros(n)

	# Buzz.
	var table: PackedFloat32Array = _harmonic_table(rng, 36, 1.0, 1.0)
	var wobble: PackedFloat32Array = _smooth_noise(rng, n, 30.0)
	var buzz: PackedFloat32Array = _zeros(n)
	var ph1: float = 0.0
	var ph2: float = 0.0
	for i: int in n:
		ph1 = fmod(ph1 + (BUZZ_HZ - 0.2) * dt, 1.0)
		ph2 = fmod(ph2 + (BUZZ_HZ + 0.2) * dt, 1.0)
		var s: float = tanh(1.8 * (_table_read(table, ph1) + _table_read(table, ph2)))
		buzz[i] = s * (1.0 + 0.5 * wobble[i])
	buzz = _comb(buzz, 0.0031, 0.35)
	buzz = _biquad(buzz, HIGHPASS, 280.0, 0.707)
	var dark: PackedFloat32Array = _biquad(buzz, LOWPASS, 700.0, 0.707)
	buzz = _biquad(buzz, LOWPASS, 2600.0, 0.707)
	for i: int in n:
		var t: float = i * dt
		var p: float = pow(_progress(t, plan), 1.5)
		buzz[i] = lerpf(dark[i] * 1.6, buzz[i], p) * _buzz_env(t, plan)
	_mix(out, buzz, 0.5)

	# Chirp-impulse crackle.
	var crackle: PackedFloat32Array = _zeros(n)
	for event: Array in _crackle_events(rng, plan, true):
		var start: int = int(event[0] * MIX_RATE)
		var f_hi: float = rng.randf_range(2500.0, 5500.0)
		var f_lo: float = rng.randf_range(600.0, 900.0)
		var tau: float = rng.randf_range(0.0005, 0.0016)
		var phase: float = rng.randf() * TAU
		for k: int in mini(int(tau * 6.0 * MIX_RATE), n - start):
			var tt: float = k * dt
			phase += TAU * (f_lo + (f_hi - f_lo) * exp(-tt / 0.0012)) * dt
			crackle[start + k] += event[1] * cos(phase) * exp(-tt / tau)
	crackle = _biquad(crackle, HIGHPASS, 300.0, 0.707)
	_mix(out, crackle, 0.75)

	# Snap and restrike.
	var snap: PackedFloat32Array = _zeros(n)
	_a_snap(rng, snap, crack_at, plan["crack"])
	if plan["restrike_at"] > 0.0:
		_a_snap(rng, snap, plan["restrike_at"], plan["restrike"])
	var formants: PackedFloat32Array = _zeros(n)
	var bands: Array = [[480.0, 2.0, 0.8], [720.0, 2.0, 0.7], [2600.0, 1.5, 1.0], [4600.0, 3.0, 0.5], [7200.0, 3.0, 0.25]]
	for band: Array in bands:
		_mix(formants, _biquad(snap, BANDPASS, band[0], band[1]), band[2])
	_mix(formants, snap, 0.3)
	_mix(out, formants, 1.0)

	# Zap: a falling sine ring-modulated by the 120 Hz buzz.
	var zap_seconds: float = plan["zap_seconds"]
	var start_zap: int = int(crack_at * MIX_RATE)
	var zphase: float = 0.0
	for k: int in mini(int(zap_seconds * 1.6 * MIX_RATE), n - start_zap):
		var tt: float = k * dt
		zphase += TAU * (350.0 + 2050.0 * exp(-tt / (zap_seconds * 0.35))) * dt
		var ring: float = 0.55 + 0.45 * tanh(4.0 * sin(TAU * BUZZ_HZ * tt))
		var env: float = minf(tt / 0.002, 1.0) * exp(-tt / (zap_seconds * 0.5))
		out[start_zap + k] += sin(zphase) * ring * env * plan["zap"] * 0.6

	# Sizzle.
	var sizzle: PackedFloat32Array = _biquad(_white(rng, n), BANDPASS, 3200.0, 0.8)
	var flicker: PackedFloat32Array = _smooth_noise(rng, n, 70.0)
	for i: int in n:
		var t: float = i * dt
		sizzle[i] *= (0.3 + absf(flicker[i])) * _tail_env(t, plan)
	_mix(out, sizzle, 1.3)
	return _finish(out, 3.2, -2.0)


## Farnell's spark snap: an FM sine dropping from about 7 kHz to 250 Hz in a few milliseconds over
## a fast noise burst with a quieter long tail.
static func _a_snap(rng: RandomNumberGenerator, out: PackedFloat32Array, at: float, amp: float) -> void:
	var start: int = int(at * MIX_RATE)
	var dt: float = 1.0 / MIX_RATE
	var phase: float = 0.0
	for k: int in mini(int(0.25 * MIX_RATE), out.size() - start):
		var tt: float = k * dt
		phase += TAU * (250.0 + 6750.0 * exp(-tt / 0.0025)) * dt
		var tone: float = sin(phase) * exp(-tt / 0.006)
		var noise: float = rng.randf_range(-1.0, 1.0) * (exp(-tt / 0.008) + 0.2 * exp(-tt / 0.08))
		out[start + k] += (tone * 0.8 + noise) * amp * minf(tt / 0.0003, 1.0)


# --- Recipe B: physical discharge -------------------------------------------------------------
# Each micro-discharge is an acoustic N-wave whose width grows with its energy (wider = duller);
# the crack is a big N-wave that strikes the bolt housing's modes (520-3900 Hz); the arc body is
# noise reignited on every half-cycle of the 60 Hz supply (sharp 120 Hz pulses) plus a faint
# magnetostriction hum on 120 Hz harmonics; the zap is noise through a resonant band-pass sweeping
# 4.5 kHz to 450 Hz; the tail is the dying arc still pulsing at 120 Hz.

static func _recipe_b(rng: RandomNumberGenerator, plan: Dictionary) -> PackedFloat32Array:
	var n: int = int(plan["seconds"] * MIX_RATE)
	var dt: float = 1.0 / MIX_RATE
	var crack_at: float = plan["crack_at"]
	var out: PackedFloat32Array = _zeros(n)

	# Arc body: noise pulsed by AC reignition, with a hum of 120 Hz harmonics underneath.
	var body: PackedFloat32Array = _biquad(_white(rng, n), BANDPASS, 1500.0, 0.6)
	body = _biquad(body, HIGHPASS, 400.0, 0.707)
	var jitter: PackedFloat32Array = _smooth_noise(rng, n, 8.0)
	var hum_amps: Array = [0.5, 1.0, 0.7, 0.55, 0.35, 0.25, 0.18, 0.12]
	var hum_phases: Array = []
	for k: int in hum_amps.size():
		hum_phases.append(rng.randf() * TAU)
	var dark: PackedFloat32Array = _biquad(body, LOWPASS, 900.0, 0.707)
	for i: int in n:
		var t: float = i * dt
		var p: float = _progress(t, plan)
		var mains: float = absf(sin(TAU * MAINS_HZ * t + 0.6 * jitter[i]))
		var pulse: float = 0.12 + pow(mains, 6.0)
		var hum: float = 0.0
		for k: int in hum_amps.size():
			hum += hum_amps[k] * sin(TAU * BUZZ_HZ * (k + 1) * t + hum_phases[k])
		var noise: float = lerpf(dark[i] * 1.5, body[i], pow(p, 1.5))
		body[i] = (noise * pulse * 2.2 + hum * 0.15 * lerpf(0.4, 1.0, p)) * _buzz_env(t, plan)
	_mix(out, body, 0.8)

	# N-wave crackle, a little of it rung through two housing resonances.
	var crackle: PackedFloat32Array = _zeros(n)
	for event: Array in _crackle_events(rng, plan, true):
		_n_wave(crackle, event[0], event[1], 0.00009 + 0.00045 * event[1] * rng.randf_range(0.6, 1.0))
	crackle = _biquad(crackle, PEAKING, 2200.0, 0.9, 5.0)
	var ring: PackedFloat32Array = _biquad(crackle, BANDPASS, 1730.0, 9.0)
	_mix(ring, _biquad(crackle, BANDPASS, 2650.0, 9.0), 1.0)
	_mix(crackle, ring, 0.8)
	crackle = _biquad(crackle, HIGHPASS, 350.0, 0.707)
	_mix(out, crackle, 1.3)

	# The crack: a wide N-wave, a short noise burst and the housing modes it excites.
	_b_crack(rng, out, crack_at, plan["crack"])
	if plan["restrike_at"] > 0.0:
		_b_crack(rng, out, plan["restrike_at"], plan["restrike"])

	# Zap: white noise through a resonant band-pass sweeping down.
	var zap_seconds: float = plan["zap_seconds"]
	var start_zap: int = int(crack_at * MIX_RATE)
	var zlen: int = mini(int(zap_seconds * 1.8 * MIX_RATE), n - start_zap)
	var zap: PackedFloat32Array = _swept_bandpass(_white(rng, zlen), 4500.0, 450.0, zap_seconds, 10.0)
	for k: int in zlen:
		var tt: float = k * dt
		out[start_zap + k] += zap[k] * minf(tt / 0.002, 1.0) * exp(-tt / (zap_seconds * 0.55)) * plan["zap"] * 2.2

	# Tail: the dying arc still pulsing on the 120 Hz reignition.
	var tail: PackedFloat32Array = _biquad(_white(rng, n), BANDPASS, 3000.0, 0.7)
	for i: int in n:
		var t: float = i * dt
		tail[i] *= (0.25 + pow(absf(sin(TAU * MAINS_HZ * t)), 3.0)) * _tail_env(t, plan)
	_mix(out, tail, 0.8)
	return _finish(out, 3.0, -1.5)


## Adds an N-wave (the pressure signature of a spark: a jump up, a linear fall through zero to an
## equal negative, a jump back) of [param width] seconds.
static func _n_wave(out: PackedFloat32Array, at: float, amp: float, width: float) -> void:
	var start: int = int(at * MIX_RATE)
	var w: int = maxi(int(width * MIX_RATE), 3)
	for k: int in mini(w, out.size() - start):
		out[start + k] += amp * (1.0 - 2.0 * float(k) / float(w - 1))


static func _b_crack(rng: RandomNumberGenerator, out: PackedFloat32Array, at: float, amp: float) -> void:
	_n_wave(out, at, amp * 1.4, 0.0009)
	var start: int = int(at * MIX_RATE)
	var dt: float = 1.0 / MIX_RATE
	var modes: Array = [[520.0, 0.3, 0.05], [1150.0, 0.45, 0.04], [1730.0, 0.5, 0.035], [2650.0, 0.45, 0.03], [3900.0, 0.3, 0.02]]
	for k: int in mini(int(0.3 * MIX_RATE), out.size() - start):
		var tt: float = k * dt
		var s: float = rng.randf_range(-1.0, 1.0) * exp(-tt / 0.005) * 0.7
		for mode: Array in modes:
			s += sin(TAU * mode[0] * tt) * mode[1] * exp(-tt / mode[2])
		out[start + k] += s * amp


# --- Recipe C: stylised high-voltage zap ------------------------------------------------------
# An FM zap (carrier sweeping 3.2 kHz to 180 Hz, modulated at 120 Hz) driven into tanh; a
# saw-like 120 Hz buzz chopped by a random stutter gate ("zzt-zzt"); granular crackle made of
# Hann-windowed grains of band-limited noise shifted to 1.2-4.8 kHz; a charge-up FM rise during
# the bolt build; a narrow sizzle band at 3.5 kHz; a harder tanh bus.

static func _recipe_c(rng: RandomNumberGenerator, plan: Dictionary) -> PackedFloat32Array:
	var n: int = int(plan["seconds"] * MIX_RATE)
	var dt: float = 1.0 / MIX_RATE
	var crack_at: float = plan["crack_at"]
	var out: PackedFloat32Array = _zeros(n)

	# Stutter-gated buzz.
	var table: PackedFloat32Array = _harmonic_table(rng, 30, 1.0, 1.4)
	var gate: PackedFloat32Array = _zeros(n)
	var cursor: int = 0
	while cursor < n:
		var on: int = int(rng.randf_range(0.008, 0.035) * MIX_RATE)
		var ramp: int = int(0.001 * MIX_RATE)
		for k: int in mini(on, n - cursor):
			gate[cursor + k] = minf(minf(float(k) / ramp, float(on - k) / ramp), 1.0) * rng.randf_range(0.85, 1.0)
		cursor += on + int(rng.randf_range(0.002, 0.014) * MIX_RATE)
	var buzz: PackedFloat32Array = _zeros(n)
	var phase: float = 0.0
	for i: int in n:
		phase = fmod(phase + BUZZ_HZ * dt, 1.0)
		buzz[i] = tanh(2.5 * _table_read(table, phase)) * gate[i] * _buzz_env(i * dt, plan)
	buzz = _biquad(buzz, HIGHPASS, 300.0, 0.707)
	buzz = _biquad(buzz, LOWPASS, 2500.0, 0.707)
	_mix(out, buzz, 0.6)

	# Granular crackle from band-limited noise shifted up by a cosine carrier.
	var grains: PackedFloat32Array = _smooth_noise(rng, n + int(0.01 * MIX_RATE), 700.0)
	var crackle: PackedFloat32Array = _zeros(n)
	for event: Array in _crackle_events(rng, plan, false):
		var start: int = int(event[0] * MIX_RATE)
		var length: int = int(rng.randf_range(0.0015, 0.006) * MIX_RATE)
		var centre: float = rng.randf_range(1200.0, 4800.0)
		var offset: int = rng.randi_range(0, n - 1)
		for k: int in mini(length, n - start):
			var window: float = 0.5 - 0.5 * cos(TAU * float(k) / length)
			crackle[start + k] += event[1] * window * cos(TAU * centre * k * dt) * grains[(offset + k) % n] * 2.0
	_mix(out, crackle, 1.0)

	# Charge-up: an FM rise that only plays during a build.
	if crack_at >= 0.05:
		var cphase: float = 0.0
		for i: int in int(crack_at * MIX_RATE):
			var t: float = i * dt
			var p: float = t / crack_at
			cphase += TAU * lerpf(500.0, 2200.0, p * p) * dt
			out[i] += sin(cphase + (0.5 + 2.0 * p) * sin(TAU * BUZZ_HZ * t)) * 0.22 * p * p * p

	# Crack: a click, a hard-clipped noise burst, then the FM zap.
	_c_crack(rng, out, crack_at, plan["crack"], plan["zap_seconds"], plan["zap"])
	if plan["restrike_at"] > 0.0:
		_c_crack(rng, out, plan["restrike_at"], plan["restrike"], plan["zap_seconds"] * 0.5, plan["zap"] * 0.5)

	# Sizzle: a narrow band of noise at 3.5 kHz, chopped by the same stutter gate.
	for i: int in n:
		var t: float = i * dt
		out[i] += grains[(i + 7919) % n] * cos(TAU * 3500.0 * t) * _tail_env(t, plan) * (0.4 + 0.6 * gate[i]) * 1.6
	return _finish(out, 3.5, -3.0)


static func _c_crack(rng: RandomNumberGenerator, out: PackedFloat32Array, at: float, amp: float, zap_seconds: float, zap_amp: float) -> void:
	var start: int = int(at * MIX_RATE)
	var dt: float = 1.0 / MIX_RATE
	var burst: PackedFloat32Array = _zeros(int(0.03 * MIX_RATE))
	for k: int in burst.size():
		var tt: float = k * dt
		burst[k] = tanh(8.0 * rng.randf_range(-1.0, 1.0) * exp(-tt / 0.004))
	burst = _biquad(burst, BANDPASS, 2500.0, 0.6)
	for k: int in mini(burst.size(), out.size() - start):
		out[start + k] += burst[k] * amp * 1.4
	for k: int in mini(3, out.size() - start):
		out[start + k] += amp * [0.6, 1.0, 0.4][k]
	var phase: float = 0.0
	for k: int in mini(int(zap_seconds * 2.0 * MIX_RATE), out.size() - start):
		var tt: float = k * dt
		phase += TAU * (180.0 + 3000.0 * exp(-tt / (zap_seconds * 0.33))) * dt
		var s: float = tanh(2.5 * sin(phase + 2.5 * sin(TAU * BUZZ_HZ * tt)))
		out[start + k] += s * minf(tt / 0.0015, 1.0) * exp(-tt / (zap_seconds * 0.6)) * zap_amp * 0.55


## Normalises to PEAK and packs little-endian signed 16-bit mono at MIX_RATE (as SfxBank._wav).
static func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var peak: float = 0.0
	for sample: float in samples:
		if not is_finite(sample):
			push_error("ArcSynth produced a non-finite sample")
			return AudioStreamWAV.new()
		peak = maxf(peak, absf(sample))
	var gain: float = PEAK / peak if peak > 0.0 else 0.0
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav
