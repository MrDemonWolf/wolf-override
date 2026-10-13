extends RefCounted
## WOLF's growl, redone: three candidate recipes (A, B, C) for audition. Nothing here is in the game.
## REFINE copy: adds growl_c_r() (recipe C with a living body contour, after the critic's notes).
## Recipes A, B and C are unchanged and still render byte-identical to the first pass.
## Written in SfxBank's style (static recipes that take a seeded RandomNumberGenerator and return a
## PackedFloat32Array, packed to 16-bit mono at a -6 dB peak) but at 44.1 kHz, so the grille, comb
## and crush detail above 5 kHz is not folded back down into the voice.
##
## Shared model, source-filter (Fant 1960; Klatt 1980 parallel formant synthesis): a low glottal
## pulse train (a differentiated Rosenberg 1971 pulse) with per-pulse jitter and shimmer, optional
## period doubling (subharmonics) and chaotic period jumps (nonlinear phenomena in mammal calls,
## Fitch, Neubauer & Herzel 2002), breath noise gated by the glottal flow, and 20-40 Hz amplitude
## modulation for roughness. It runs through a parallel bank of formant band-passes spaced for a
## ~20 cm vocal tract (formant dispersion about 875 Hz: 440, 1310, 2190, 3060 Hz, after Riede &
## Fitch 1999 on dog growls), so the wolf's identity sits at 300 Hz-3.5 kHz where phone speakers play.
## Each recipe then builds the machine body differently (comb resonance, ring modulation, servo,
## bit-crush, chassis modes, grille rattle). Filters are RBJ Audio EQ Cookbook biquads.

const MIX_RATE: int = 44100
const SEED: int = 0x574F4C46
## -6.02 dB, as SfxBank.
const PEAK: float = 0.5
const VARIANTS: Dictionary = {&"warning": 1.2, &"seam": 0.8, &"assertive": 1.0}
## Per variant: f0 contour (start, middle, end Hz), swell and die-away seconds, roughness rate (Hz)
## and depth, how open the mouth is (raises F1 and F2), breath share, subharmonic depth and an
## onset accent (a snapped "grr" before the held growl).
const SHAPES: Dictionary = {
	&"warning": {"f0": [74.0, 83.0, 69.0], "attack": 0.16, "release": 0.34, "rough_hz": 27.0, "rough": 0.5, "open": 0.55, "breath": 0.35, "sub": 0.25, "accent": 0.0},
	&"seam": {"f0": [62.0, 66.0, 56.0], "attack": 0.1, "release": 0.36, "rough_hz": 21.0, "rough": 0.4, "open": 0.0, "breath": 0.28, "sub": 0.12, "accent": 0.0},
	&"assertive": {"f0": [94.0, 108.0, 88.0], "attack": 0.025, "release": 0.26, "rough_hz": 34.0, "rough": 0.7, "open": 0.95, "breath": 0.3, "sub": 0.45, "accent": 1.0},
}
## REFINE contour for recipe C: a slow swell on top of the roughness AM that also sweeps F1, plus
## short intensity bursts (centre s, length s) like the snarl peaks in a real growl. Bursts open the
## mouth further (F1 and F2 up), lift f0 a little and push the grille rattle on.
const CONTOURS: Dictionary = {
	# Tuned on the measurements: whole-clip level SD 4.9 dB and centroid CV 0.28 (critic targets >4 dB, >0.2).
	&"warning": {"swell_hz": 2.4, "swell_db": 5.0, "f1_sweep": 120.0, "bursts": [[0.45, 0.13], [0.8, 0.12]], "burst_db": 6.0, "burst_f2": 400.0, "burst_f0": 0.1, "post": 0.85, "rattle": 0.2, "air": 0.5},
}
## The envelope reaches zero this long before the clip ends, so resonances ring out before the fade.
const TAIL: float = 0.06
const LP: int = 0
const HP: int = 1
const BP: int = 2
const PEAKING: int = 3


# --- Public entry points: deterministic for a given seed and variant --------------------------

## Recipe A, "grille wolf": a mostly organic growl played through a small speaker grille.
static func growl_a(seed: int, variant: StringName = &"warning") -> AudioStreamWAV:
	return _wav(_growl_a(_rng(seed, variant), VARIANTS[variant], SHAPES[variant], variant))


## Recipe B, "ring-mod servo wolf": the machine is forward; inharmonic ring modulation, metal combs,
## a head servo and a coarser crush.
static func growl_b(seed: int, variant: StringName = &"warning") -> AudioStreamWAV:
	return _wav(_growl_b(_rng(seed, variant), VARIANTS[variant], SHAPES[variant], variant))


## Recipe C, "chaotic throat in a resonant chassis": rough subharmonic throat whose pulses ping
## the metal body's modes, with a grille rattle on the loud parts.
static func growl_c(seed: int, variant: StringName = &"warning") -> AudioStreamWAV:
	return _wav(_growl_c(_rng(seed, variant), VARIANTS[variant], SHAPES[variant], variant))


## Recipe C, refined: the same throat and chassis with a contour (swell, F1 sweep, two bursts).
static func growl_c_r(seed: int, variant: StringName = &"warning", overrides: Dictionary = {}) -> AudioStreamWAV:
	var contour: Dictionary = CONTOURS[variant].duplicate()
	contour.merge(overrides, true)
	return _wav(_growl_c_r(_rng(seed, variant), VARIANTS[variant], SHAPES[variant], contour))


static func _rng(seed: int, variant: StringName) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed ^ String(variant).hash()
	return rng


# --- Recipes ----------------------------------------------------------------------------------

static func _growl_a(rng: RandomNumberGenerator, seconds: float, shape: Dictionary, variant: StringName) -> PackedFloat32Array:
	var env: PackedFloat32Array = _env_curve(seconds, shape)
	var sub: float = shape["sub"]
	var src: PackedFloat32Array = _glottal(rng, seconds, shape, env, 0.018, 0.12, sub * 0.6, 0.0)
	var voice: PackedFloat32Array = _formants(src, env, shape, [1.0, 1.2, 1.1, 0.8], 0.15)
	# Light tanh grit, then a negative-feedback comb (1.45 ms: peaks at 345, 1035, 1725 Hz...) as the
	# hollow of the chest plate, and an 8-bit crush blended in as the speaker's digital edge.
	voice = _soft_clip(_normalised(voice), 1.6, 0.0)
	var metal: PackedFloat32Array = _comb(voice, 0.00145, 0.5)
	_add(voice, metal, 0.45 * _rms(voice) / maxf(_rms(metal), 1e-9))
	var crushed: PackedFloat32Array = _crush(voice, 8, 2)
	_blend(voice, crushed, 0.15)
	return _finish(voice, 55.0, 7000.0, 2400.0, 5.0, 2.6)


static func _growl_b(rng: RandomNumberGenerator, seconds: float, shape: Dictionary, variant: StringName) -> PackedFloat32Array:
	var env: PackedFloat32Array = _env_curve(seconds, shape)
	var sub: float = shape["sub"]
	var src: PackedFloat32Array = _glottal(rng, seconds, shape, env, 0.012, 0.08, sub * 0.4, 0.0)
	var voice: PackedFloat32Array = _formants(src, env, shape, [0.9, 1.0, 0.9, 0.6], 0.15)
	voice = _normalised(voice)
	# Ring modulation by a carrier at 1.41x the voice pitch: the sidebands fall between the harmonics,
	# which is what makes a voice read as a machine (the classic ring-modulated robot voice).
	var ring: PackedFloat32Array = _ring(voice, _f0_curve(seconds, shape), 1.41)
	_add(voice, ring, 0.6 * _rms(voice) / maxf(_rms(ring), 1e-9))
	# Two metal combs in series at unrelated delays (plates of different sizes).
	var comb1: PackedFloat32Array = _comb(voice, 0.00113, 0.55)
	_add(voice, comb1, 0.4 * _rms(voice) / maxf(_rms(comb1), 1e-9))
	var comb2: PackedFloat32Array = _comb(voice, 0.00271, 0.4)
	_add(voice, comb2, 0.3 * _rms(voice) / maxf(_rms(comb2), 1e-9))
	voice = _soft_clip(_normalised(voice), 1.3, 0.0)
	# The neck servo: a lift as he squares up, a scan while he reads the seam, a snap when he asserts.
	var servo: PackedFloat32Array
	match variant:
		&"seam":
			servo = _servo(rng, voice.size(), 0.02, 0.62, 900.0, 1350.0, 1000.0)
		&"assertive":
			servo = _servo(rng, voice.size(), 0.0, 0.16, 1700.0, 1250.0, 1100.0)
		_:
			servo = _servo(rng, voice.size(), 0.0, 0.36, 1200.0, 1500.0, 1450.0)
	_add(voice, servo, 0.22 * _rms(voice) / maxf(_rms(servo), 1e-9))
	var crushed: PackedFloat32Array = _crush(voice, 6, 3)
	_blend(voice, crushed, 0.22)
	return _finish(voice, 60.0, 6500.0, 2000.0, 4.0, 3.0)


static func _growl_c(rng: RandomNumberGenerator, seconds: float, shape: Dictionary, variant: StringName) -> PackedFloat32Array:
	var env: PackedFloat32Array = _env_curve(seconds, shape)
	var sub: float = shape["sub"]
	var src: PackedFloat32Array = _glottal(rng, seconds, shape, env, 0.025, 0.18, minf(sub * 1.4, 0.75), 0.04)
	var voice: PackedFloat32Array = _formants(src, env, shape, [1.0, 1.0, 0.85, 0.6], 0.2)
	# Chassis modes: high-Q resonators at circular-plate ratios over 520 Hz (decay about 25 ms), so
	# every glottal pulse rings the metal body like a struck plate.
	var chassis: PackedFloat32Array = PackedFloat32Array()
	chassis.resize(src.size())
	var ratios: Array[float] = [1.0, 1.59, 2.14, 2.30, 2.65, 2.92, 3.50]
	for k: int in ratios.size():
		var freq: float = 520.0 * ratios[k]
		var q: float = freq * PI * 0.025
		_add(chassis, _biquad(src, BP, freq, q), 1.0 / (1.0 + 0.35 * k))
	_add(voice, chassis, 0.55 * _rms(voice) / maxf(_rms(chassis), 1e-9))
	# Grille rattle: band-passed noise that only buzzes on the loud parts, fluttering at the roughness rate.
	var rattle: PackedFloat32Array = PackedFloat32Array()
	rattle.resize(src.size())
	var rough_hz: float = shape["rough_hz"]
	for i: int in rattle.size():
		var gate: float = clampf((env[i] - 0.55) / 0.45, 0.0, 1.0)
		var flutter: float = 1.0 if sin(TAU * rough_hz * 2.0 * i / MIX_RATE) > 0.2 else 0.25
		rattle[i] = rng.randf_range(-1.0, 1.0) * gate * flutter
	rattle = _biquad(rattle, BP, 3200.0, 2.5)
	if _rms(rattle) > 0.0:
		_add(voice, rattle, 0.12 * _rms(voice) / _rms(rattle))
	# An over-driven voice coil: asymmetric clipping adds even harmonics.
	voice = _soft_clip(_normalised(voice), 2.2, 0.2)
	if variant == &"seam":
		# A faint optic focus whir while he reads.
		var whir: PackedFloat32Array = _servo(rng, voice.size(), 0.05, 0.5, 2100.0, 2400.0, 2250.0)
		_add(voice, whir, 0.08 * _rms(voice) / maxf(_rms(whir), 1e-9))
	var crushed: PackedFloat32Array = _crush(voice, 7, 1)
	_blend(voice, crushed, 0.12)
	return _finish(voice, 50.0, 7500.0, 2800.0, 5.0, 2.4)


## Recipe C with a body contour. The contour is a gain curve g(t) in dB: a slow sine swell plus
## raised-cosine bursts. Most of it (1 - post) shapes the excitation, so timbre follows loudness
## (F1 sweeps with the swell, bursts open the mouth, the rattle gate opens only on the bursts); the
## rest is applied after the tanh glue, which would otherwise flatten the level movement again.
static func _growl_c_r(rng: RandomNumberGenerator, seconds: float, shape: Dictionary, contour: Dictionary) -> PackedFloat32Array:
	var base: PackedFloat32Array = _env_curve(seconds, shape)
	var n: int = base.size()
	var swell_hz: float = contour["swell_hz"]
	var swell_db: float = contour["swell_db"]
	var burst_db: float = contour["burst_db"]
	var post: float = contour["post"]
	var bursts: Array = contour["bursts"]
	var swell_phase: float = rng.randf() * TAU
	var gain_db: PackedFloat32Array = PackedFloat32Array()
	var burst: PackedFloat32Array = PackedFloat32Array()
	var swell: PackedFloat32Array = PackedFloat32Array()
	gain_db.resize(n)
	burst.resize(n)
	swell.resize(n)
	var top: float = -INF
	for i: int in n:
		var t: float = float(i) / MIX_RATE
		# The swell rate wanders slowly (+-15%) so it does not read as a tremolo.
		var s: float = sin(TAU * swell_hz * t * (1.0 + 0.15 * sin(TAU * 0.7 * t)) + swell_phase)
		var b: float = 0.0
		for pair: Array in bursts:
			var x: float = (t - float(pair[0])) / float(pair[1])
			# Flat-topped (Tukey) burst: full level over the middle half, raised-cosine ramps either side.
			if absf(x) < 0.5:
				b = maxf(b, 1.0 if absf(x) < 0.25 else 0.5 + 0.5 * cos(PI * (absf(x) - 0.25) / 0.25))
		swell[i] = 0.5 + 0.5 * s
		burst[i] = b
		gain_db[i] = 0.5 * swell_db * s + burst_db * b
		top = maxf(top, gain_db[i])
	var env: PackedFloat32Array = PackedFloat32Array()
	var f0_mul: PackedFloat32Array = PackedFloat32Array()
	var f1_add: PackedFloat32Array = PackedFloat32Array()
	var f2_add: PackedFloat32Array = PackedFloat32Array()
	env.resize(n)
	f0_mul.resize(n)
	f1_add.resize(n)
	f2_add.resize(n)
	var f1_sweep: float = contour["f1_sweep"]
	var burst_f2: float = contour["burst_f2"]
	var burst_f0: float = contour["burst_f0"]
	for i: int in n:
		# Peak-normalised, so env reaches 1 only inside a burst and the rattle gate opens there.
		env[i] = base[i] * pow(10.0, (gain_db[i] - top) * (1.0 - post) / 20.0)
		f0_mul[i] = 1.0 + burst_f0 * burst[i]
		f1_add[i] = f1_sweep * (swell[i] - 0.5) + 0.6 * f1_sweep * burst[i]
		f2_add[i] = burst_f2 * burst[i]
	var sub: float = shape["sub"]
	var src: PackedFloat32Array = _glottal(rng, seconds, shape, env, 0.025, 0.18, minf(sub * 1.4, 0.75), 0.04, f0_mul)
	var voice: PackedFloat32Array = _formants(src, env, shape, [1.0, 1.0, 0.85, 0.6], 0.2, f1_add, f2_add)
	var chassis: PackedFloat32Array = PackedFloat32Array()
	chassis.resize(src.size())
	var ratios: Array[float] = [1.0, 1.59, 2.14, 2.30, 2.65, 2.92, 3.50]
	for k: int in ratios.size():
		var freq: float = 520.0 * ratios[k]
		var q: float = freq * PI * 0.025
		_add(chassis, _biquad(src, BP, freq, q), 1.0 / (1.0 + 0.35 * k))
	_add(voice, chassis, 0.55 * _rms(voice) / maxf(_rms(chassis), 1e-9))
	var rattle: PackedFloat32Array = PackedFloat32Array()
	rattle.resize(n)
	var rough_hz: float = shape["rough_hz"]
	var env_top: float = _peak(env)
	for i: int in n:
		var gate: float = clampf((env[i] / env_top - 0.55) / 0.45, 0.0, 1.0)
		var flutter: float = 1.0 if sin(TAU * rough_hz * 2.0 * i / MIX_RATE) > 0.2 else 0.25
		rattle[i] = rng.randf_range(-1.0, 1.0) * gate * flutter
	rattle = _biquad(rattle, BP, 3200.0, 2.5)
	if _rms(rattle) > 0.0:
		_add(voice, rattle, float(contour["rattle"]) * _rms(voice) / _rms(rattle))
	voice = _soft_clip(_normalised(voice), 2.2, 0.2)
	# Snarl air: the voice's own 1.6 kHz+ band, added only inside the bursts (a mouth opening and
	# the throat tightening), so the bursts get brighter as well as louder.
	var air_amount: float = contour["air"]
	if air_amount > 0.0:
		# Band-limited to 1.6-4.5 kHz so it stays in the speaker band and does not sharpen pulse edges.
		var air: PackedFloat32Array = _biquad(_biquad(voice, HP, 1600.0, 0.7071), HP, 1600.0, 0.7071)
		air = _biquad(_biquad(air, LP, 4500.0, 0.7071), LP, 4500.0, 0.7071)
		for i: int in n:
			air[i] *= burst[i]
		_add(voice, air, air_amount)
	var crushed: PackedFloat32Array = _crush(voice, 7, 1)
	_blend(voice, crushed, 0.12)
	var post_gain: PackedFloat32Array = PackedFloat32Array()
	post_gain.resize(n)
	for i: int in n:
		post_gain[i] = pow(10.0, (gain_db[i] - top) * post / 20.0)
	return _finish(voice, 50.0, 7500.0, 2800.0, 5.0, 2.4, post_gain)


# --- Voice --------------------------------------------------------------------------------------

## The glottal excitation: a differentiated Rosenberg pulse train following the f0 contour, with
## per-pulse jitter (period) and shimmer (amplitude), alternate-pulse period doubling for
## [param subharmonic], random period jumps with probability [param chaos] per pulse, breath noise
## gated by the flow, and 20-40 Hz roughness AM; all scaled by [param env].
static func _glottal(rng: RandomNumberGenerator, seconds: float, shape: Dictionary, env: PackedFloat32Array, jitter: float, shimmer: float, subharmonic: float, chaos: float, f0_mul: PackedFloat32Array = PackedFloat32Array()) -> PackedFloat32Array:
	var frames: int = env.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var f0: Array = shape["f0"]
	var breath: float = shape["breath"]
	var rough_hz: float = shape["rough_hz"]
	var rough: float = shape["rough"]
	var phase: float = 0.0
	var freq: float = f0[0]
	var amp: float = 1.0
	var pulse: int = 0
	var prev: float = 0.0
	var am_phase: float = rng.randf() * TAU
	var drift: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		var flow: float = _rosenberg(phase) * amp
		var dflow: float = (flow - prev) * MIX_RATE / freq
		prev = flow
		# The roughness rate wanders a few hertz so the flutter never sounds like a fixed LFO.
		drift += (rng.randf_range(-6.0, 6.0) - drift) * 0.0004
		am_phase += TAU * (rough_hz + drift) * dt
		var am: float = 1.0 - rough * (0.5 + 0.5 * sin(am_phase))
		var noise: float = rng.randf_range(-1.0, 1.0)
		out[i] = (dflow * 0.25 + noise * breath * (0.2 + flow)) * am * env[i]
		phase += freq * dt
		if phase >= 1.0:
			phase -= 1.0
			pulse += 1
			freq = _contour(f0, t / seconds) * (1.0 + jitter * rng.randfn())
			if not f0_mul.is_empty():
				freq *= f0_mul[i]
			amp = maxf(0.2, 1.0 + shimmer * rng.randfn())
			if subharmonic > 0.0 and pulse % 2 == 1:
				freq *= 1.0 - 0.12 * subharmonic
				amp *= 1.0 - 0.6 * subharmonic
			if chaos > 0.0 and rng.randf() < chaos * env[i]:
				freq *= rng.randf_range(0.75, 1.3)
	return out


## Rosenberg's glottal flow pulse over one period: a 36% opening, a 19% closing, then closed.
static func _rosenberg(phase: float) -> float:
	const OPEN: float = 0.36
	const CLOSE: float = 0.19
	if phase < OPEN:
		return 0.5 - 0.5 * cos(PI * phase / OPEN)
	if phase < OPEN + CLOSE:
		return cos(0.5 * PI * (phase - OPEN) / CLOSE)
	return 0.0


## Parallel formant bank (F1-F4 band-passes with [param gains]) plus a low body band. F1 and F2
## open with the envelope and the shape's mouth opening.
static func _formants(src: PackedFloat32Array, env: PackedFloat32Array, shape: Dictionary, gains: Array, body: float, f1_add: PackedFloat32Array = PackedFloat32Array(), f2_add: PackedFloat32Array = PackedFloat32Array()) -> PackedFloat32Array:
	var open: float = shape["open"]
	var f1: PackedFloat32Array = PackedFloat32Array()
	var f2: PackedFloat32Array = PackedFloat32Array()
	f1.resize(src.size())
	f2.resize(src.size())
	for i: int in src.size():
		f1[i] = 360.0 + 240.0 * open * (0.4 + 0.6 * env[i])
		f2[i] = 1150.0 + 320.0 * open * (0.5 + 0.5 * env[i])
		if not f1_add.is_empty():
			f1[i] += f1_add[i]
			f2[i] += f2_add[i]
	var out: PackedFloat32Array = _biquad_tv(src, BP, f1, 4.5)
	_scale(out, gains[0])
	_add(out, _biquad_tv(src, BP, f2, 6.0), gains[1])
	_add(out, _biquad(src, BP, 2190.0, 8.0), gains[2])
	_add(out, _biquad(src, BP, 3060.0, 8.0), gains[3])
	# Chest body around the 2nd-3rd harmonics; the fundamental itself is left to headphones.
	_add(out, _biquad(src, BP, 190.0, 0.9), body)
	return out


static func _contour(points: Array, p: float) -> float:
	var a: float = points[0]
	var b: float = points[1]
	var c: float = points[2]
	return lerpf(lerpf(a, b, p), lerpf(b, c, p), p)


static func _f0_curve(seconds: float, shape: Dictionary) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(int(seconds * MIX_RATE))
	var f0: Array = shape["f0"]
	for i: int in out.size():
		out[i] = _contour(f0, float(i) / out.size())
	return out


## Raised-cosine swell and die-away (ending TAIL before the clip end), a gentle mid swell, and for
## the assertive shape a snapped onset accent followed by a short dip.
static func _env_curve(seconds: float, shape: Dictionary) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(int(seconds * MIX_RATE))
	var attack: float = shape["attack"]
	var release: float = shape["release"]
	var accent: float = shape["accent"]
	var end: float = seconds - TAIL
	for i: int in out.size():
		var t: float = float(i) / MIX_RATE
		var rise: float = 0.5 - 0.5 * cos(PI * clampf(t / attack, 0.0, 1.0))
		var fall: float = 0.5 - 0.5 * cos(PI * clampf((end - t) / release, 0.0, 1.0))
		var body: float = 0.82 + 0.18 * sin(PI * clampf(t / end, 0.0, 1.0))
		if accent > 0.0:
			body += accent * 0.3 * exp(-pow((t - 0.07) / 0.05, 2.0))
			body *= 1.0 - accent * 0.4 * exp(-pow((t - 0.24) / 0.07, 2.0))
		out[i] = rise * fall * body
	return out


# --- Machine layers --------------------------------------------------------------------------

## Negative-feedback comb: y[n] = x[n] - feedback * y[n - D]. Peaks at odd multiples of 1 / (2 D),
## so it rings metallic in the mids without boosting DC.
static func _comb(x: PackedFloat32Array, delay: float, feedback: float) -> PackedFloat32Array:
	var d: int = maxi(1, int(delay * MIX_RATE))
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(x.size())
	for i: int in x.size():
		out[i] = x[i] - (feedback * out[i - d] if i >= d else 0.0)
	return out


## Ring modulation by a sine whose frequency is [param ratio] times the voice's f0 curve.
static func _ring(x: PackedFloat32Array, f0: PackedFloat32Array, ratio: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(x.size())
	var phase: float = 0.0
	for i: int in x.size():
		phase += TAU * f0[i] * ratio / MIX_RATE
		out[i] = x[i] * sin(phase)
	return out


## A servo whine between [param from] and [param to] seconds: a tone gliding start -> peak -> end
## with a 7 Hz wobble, a soft second harmonic and gear grit, under a raised-cosine window.
static func _servo(rng: RandomNumberGenerator, frames: int, from: float, to: float, f_start: float, f_peak: float, f_end: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var a: int = int(from * MIX_RATE)
	var b: int = mini(frames, int(to * MIX_RATE))
	var phase: float = 0.0
	for i: int in range(a, b):
		var p: float = float(i - a) / maxf(b - a, 1)
		var t: float = float(i) / MIX_RATE
		var freq: float = lerpf(lerpf(f_start, f_peak, p), lerpf(f_peak, f_end, p), p) + 18.0 * sin(TAU * 7.0 * t)
		phase += TAU * freq / MIX_RATE
		var window: float = 0.5 - 0.5 * cos(TAU * p)
		var grit: float = 1.0 + 0.25 * rng.randf_range(-1.0, 1.0)
		out[i] = (sin(phase) * 0.75 + sin(phase * 2.0) * 0.25) * grit * window
	return out


## Bit-depth and sample-rate reduction relative to the clip's own peak.
static func _crush(x: PackedFloat32Array, bits: int, hold: int) -> PackedFloat32Array:
	var peak: float = _peak(x)
	var steps: float = pow(2.0, bits - 1)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(x.size())
	var held: float = 0.0
	for i: int in x.size():
		if i % hold == 0:
			held = roundf(x[i] / maxf(peak, 1e-9) * steps) / steps * peak
		out[i] = held
	return out


## tanh saturation with an optional bias (asymmetry, so even harmonics), DC-corrected.
static func _soft_clip(x: PackedFloat32Array, drive: float, bias: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(x.size())
	var offset: float = tanh(bias)
	for i: int in x.size():
		out[i] = (tanh(drive * x[i] + bias) - offset) / tanh(drive + bias)
	return out


## The speaker-safe finish: 4th-order high-pass (rumble), a presence peak, a low-pass, then tanh
## glue at [param drive] (tames the glottal pulse peaks so the growl is loud on small speakers),
## then raised-cosine edges (4 ms in, 15 ms out) so the first and last samples are exactly zero.
## REFINE: an optional [param post_gain] curve is applied after the glue (so the glue cannot flatten
## it), followed by a second 2nd-order high-pass at [param hp_hz] that removes the slow DC the gain
## curve and the asymmetric clip leave behind; the edge fades still come last.
static func _finish(x: PackedFloat32Array, hp_hz: float, lp_hz: float, presence_hz: float, presence_db: float, drive: float, post_gain: PackedFloat32Array = PackedFloat32Array()) -> PackedFloat32Array:
	var out: PackedFloat32Array = _biquad(x, HP, hp_hz, 0.5412)
	out = _biquad(out, HP, hp_hz, 1.3066)
	out = _biquad(out, PEAKING, presence_hz, 1.0, presence_db)
	out = _biquad(out, LP, lp_hz, 0.7071)
	out = _soft_clip(_normalised(out), drive, 0.0)
	if not post_gain.is_empty():
		for i: int in out.size():
			out[i] *= post_gain[i]
		out = _biquad(out, HP, hp_hz, 0.7071)
	var fade_in: int = int(0.004 * MIX_RATE)
	var fade_out: int = int(0.015 * MIX_RATE)
	var n: int = out.size()
	for i: int in fade_in:
		out[i] *= 0.5 - 0.5 * cos(PI * i / fade_in)
	for i: int in fade_out:
		out[n - 1 - i] *= 0.5 - 0.5 * cos(PI * i / fade_out)
	return out


# --- Filters and helpers -----------------------------------------------------------------------

## RBJ cookbook coefficients [b0, b1, b2, a1, a2], normalised by a0. BP is the 0 dB-peak band-pass.
static func _coeffs(kind: int, freq: float, q: float, gain_db: float) -> PackedFloat64Array:
	var w0: float = TAU * clampf(freq, 10.0, MIX_RATE * 0.45) / MIX_RATE
	var cw: float = cos(w0)
	var alpha: float = sin(w0) / (2.0 * q)
	var b0: float
	var b1: float
	var b2: float
	var a0: float = 1.0 + alpha
	var a1: float = -2.0 * cw
	var a2: float = 1.0 - alpha
	match kind:
		LP:
			b0 = (1.0 - cw) * 0.5
			b1 = 1.0 - cw
			b2 = b0
		HP:
			b0 = (1.0 + cw) * 0.5
			b1 = -(1.0 + cw)
			b2 = b0
		BP:
			b0 = alpha
			b1 = 0.0
			b2 = -alpha
		_:
			var big_a: float = pow(10.0, gain_db / 40.0)
			b0 = 1.0 + alpha * big_a
			b1 = -2.0 * cw
			b2 = 1.0 - alpha * big_a
			a0 = 1.0 + alpha / big_a
			a2 = 1.0 - alpha / big_a
	return PackedFloat64Array([b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0])


static func _biquad(x: PackedFloat32Array, kind: int, freq: float, q: float, gain_db: float = 0.0) -> PackedFloat32Array:
	var c: PackedFloat64Array = _coeffs(kind, freq, q, gain_db)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(x.size())
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	for i: int in x.size():
		var y: float = c[0] * x[i] + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2
		x2 = x1
		x1 = x[i]
		y2 = y1
		y1 = y
		out[i] = y
	return out


## A biquad whose centre follows [param freqs] (coefficients refreshed every 16 samples).
static func _biquad_tv(x: PackedFloat32Array, kind: int, freqs: PackedFloat32Array, q: float) -> PackedFloat32Array:
	var c: PackedFloat64Array
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(x.size())
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	for i: int in x.size():
		if i % 16 == 0:
			c = _coeffs(kind, freqs[i], q, 0.0)
		var y: float = c[0] * x[i] + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2
		x2 = x1
		x1 = x[i]
		y2 = y1
		y1 = y
		out[i] = y
	return out


static func _add(dst: PackedFloat32Array, src: PackedFloat32Array, gain: float) -> void:
	for i: int in mini(dst.size(), src.size()):
		dst[i] += src[i] * gain


static func _blend(dst: PackedFloat32Array, wet: PackedFloat32Array, amount: float) -> void:
	for i: int in dst.size():
		dst[i] = lerpf(dst[i], wet[i], amount)


static func _scale(x: PackedFloat32Array, gain: float) -> void:
	for i: int in x.size():
		x[i] *= gain


static func _peak(x: PackedFloat32Array) -> float:
	var peak: float = 0.0
	for sample: float in x:
		peak = maxf(peak, absf(sample))
	return peak


static func _rms(x: PackedFloat32Array) -> float:
	var sum: float = 0.0
	for sample: float in x:
		sum += sample * sample
	return sqrt(sum / maxf(x.size(), 1))


static func _normalised(x: PackedFloat32Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = x.duplicate()
	var peak: float = _peak(out)
	if peak > 0.0:
		_scale(out, 1.0 / peak)
	return out


## Little-endian signed 16-bit mono PCM at PEAK.
static func pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var peak: float = 0.0
	for sample: float in samples:
		if not is_finite(sample):
			push_error("growl recipe produced a non-finite sample")
			return PackedByteArray()
		peak = maxf(peak, absf(sample))
	var gain: float = PEAK / peak if peak > 0.0 else 0.0
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in samples.size():
		bytes.encode_s16(i * 2, int(roundf(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0)))
	return bytes


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = pcm16(samples)
	return wav
