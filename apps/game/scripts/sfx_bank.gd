class_name SfxBank
extends Node
## Procedural sound effects, generated once at startup into AudioStreamWAV buffers
## (16-bit mono 22.05 kHz, deterministic seed, every clip normalised to a -6 dB peak).
## Nothing is loaded from disk: the recipes below are the whole source, so there is no
## third-party audio to license. Players sit on the Effects bus so the Audio sliders apply.

const MIX_RATE: int = 22050
const SEED: int = 0x574F4C46
## -6.02 dB, the loudest sample any clip reaches before the bus gain.
const PEAK: float = 0.5
const BUS: String = "Effects"
const VOICES: int = 4
## Loops get their own player each so a room can hold and stop them by name.
const LOOPS: Array[StringName] = [&"hiss", &"hum", &"servo", &"winch"]
## Clip lengths in seconds; tests check the buffers against these.
const LENGTHS: Dictionary = {
	&"boom": 0.5,
	&"small_boom": 0.3,
	&"clank": 0.04,
	&"thud": 0.08,
	&"hiss": 0.5,
	&"hum": 1.0,
	&"arc": 0.5,
	&"klaxon": 0.5,
	&"growl": 0.6,
	&"servo": 1.0,
	&"winch": 1.0,
	&"whine": 0.6,
}

## Off means play() does nothing and anything already sounding, loops included, stops;
## Main ties it to effects_enabled.
var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			stop_all()
var streams: Dictionary = {}
## How long generation took, in milliseconds, for the startup budget check.
var generation_ms: float = 0.0
var _voices: Array[AudioStreamPlayer] = []
var _loop_players: Dictionary = {}
var _next_voice: int = 0


func _ready() -> void:
	generate()
	for index: int in VOICES:
		_voices.append(_add_player("Voice%d" % index))
	for loop_name: StringName in LOOPS:
		_loop_players[loop_name] = _add_player(String(loop_name).capitalize() + "Loop")


## Plays [param clip] on a free voice (or that loop's own player) and returns the player, or null
## when the bank is off or the clip is unknown.
func play(clip: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if not enabled or not streams.has(clip):
		return null
	var player: AudioStreamPlayer
	if _loop_players.has(clip):
		player = _loop_players[clip]
		if player.playing:
			player.volume_db = volume_db
			player.pitch_scale = pitch
			return player
	else:
		player = _voices[_next_voice]
		_next_voice = (_next_voice + 1) % VOICES
	player.stream = streams[clip]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	return player


func stop(clip: StringName) -> void:
	if _loop_players.has(clip):
		(_loop_players[clip] as AudioStreamPlayer).stop()


func stop_all() -> void:
	for player: AudioStreamPlayer in _voices:
		player.stop()
	for player: AudioStreamPlayer in _loop_players.values():
		player.stop()


func players() -> Array[AudioStreamPlayer]:
	var all: Array[AudioStreamPlayer] = _voices.duplicate()
	for player: AudioStreamPlayer in _loop_players.values():
		all.append(player)
	return all


func _add_player(player_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = BUS
	add_child(player)
	return player


## Renders every clip from the fixed seed; calling it again produces identical buffers.
func generate() -> void:
	var start: int = Time.get_ticks_usec()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED
	streams[&"boom"] = _wav(_boom(rng, LENGTHS[&"boom"], 55.0, 30.0, 0.18, 0.25, 1400.0, 110.0, 0.9), false)
	streams[&"small_boom"] = _wav(_boom(rng, LENGTHS[&"small_boom"], 90.0, 48.0, 0.09, 0.16, 900.0, 160.0, 0.5), false)
	streams[&"clank"] = _wav(_clank(rng, LENGTHS[&"clank"]), false)
	streams[&"thud"] = _wav(_thud(rng, LENGTHS[&"thud"]), false)
	streams[&"hiss"] = _wav(_hiss(rng, LENGTHS[&"hiss"]), true)
	streams[&"hum"] = _wav(_hum(LENGTHS[&"hum"]), true)
	streams[&"arc"] = _wav(_arc(rng, LENGTHS[&"arc"]), false)
	streams[&"klaxon"] = _wav(_klaxon(LENGTHS[&"klaxon"]), false)
	streams[&"growl"] = _wav(_growl(rng, LENGTHS[&"growl"]), false)
	streams[&"servo"] = _wav(_servo(LENGTHS[&"servo"]), true)
	streams[&"winch"] = _wav(_winch(LENGTHS[&"winch"]), true)
	streams[&"whine"] = _wav(_whine(rng, LENGTHS[&"whine"]), false)
	generation_ms = float(Time.get_ticks_usec() - start) / 1000.0


## A sine sub sweeping [param sub_from] to [param sub_to] Hz under a low-passed noise burst whose
## cutoff falls from [param lp_from] to [param lp_to] Hz, soft-clipped for weight.
static func _boom(rng: RandomNumberGenerator, seconds: float, sub_from: float, sub_to: float, sub_tau: float, noise_seconds: float, lp_from: float, lp_to: float, sub_mix: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var phase: float = 0.0
	var low: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		phase += TAU * lerpf(sub_from, sub_to, t / seconds) * dt
		var sample: float = sin(phase) * exp(-t / sub_tau) * sub_mix
		if t < noise_seconds:
			var cutoff: float = lerpf(lp_from, lp_to, t / noise_seconds)
			var alpha: float = dt / (1.0 / (TAU * cutoff) + dt)
			low += alpha * (rng.randf_range(-1.0, 1.0) - low)
			sample += low * exp(-t / 0.09) * 1.8
		out[i] = tanh(1.8 * sample) * minf(t / 0.004, 1.0)
	return out


## 40 ms of a 420 Hz square ring with a noise tick on top: the breaker clunk and relay contact.
static func _clank(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	for i: int in frames:
		var t: float = i * dt
		var square: float = 1.0 if fmod(t * 420.0, 1.0) < 0.5 else -1.0
		var sample: float = square * 0.6 * exp(-t / 0.012) + rng.randf_range(-1.0, 1.0) * exp(-t / 0.005)
		out[i] = sample * minf(t / 0.003, 1.0)
	return out


## 80 ms, 60 Hz sine with a short low noise knock: the door landing and the knockdown.
static func _thud(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var alpha: float = dt / (1.0 / (TAU * 300.0) + dt)
	var low: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		low += alpha * (rng.randf_range(-1.0, 1.0) - low)
		var sample: float = sin(TAU * 60.0 * t) * exp(-t / 0.03) + low * 0.8 * exp(-t / 0.01)
		out[i] = sample * minf(t / 0.004, 1.0)
	return out


## Looping noise low-passed at 3 kHz with one 2 Hz amplitude wobble per loop.
static func _hiss(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var alpha: float = dt / (1.0 / (TAU * 3000.0) + dt)
	var low: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		low += alpha * (rng.randf_range(-1.0, 1.0) - low)
		out[i] = low * (0.8 + 0.2 * sin(TAU * t / seconds))
	return out


## Looping 110 Hz saw with a 113 Hz detune, softened by a 500 Hz low-pass; both tones complete
## whole cycles in one second so the loop seam is silent.
static func _hum(seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var alpha: float = dt / (1.0 / (TAU * 500.0) + dt)
	var low: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		var saw: float = (fmod(t * 110.0, 1.0) * 2.0 - 1.0) + (fmod(t * 113.0, 1.0) * 2.0 - 1.0)
		low += alpha * (saw * 0.5 - low)
		out[i] = low
	return out


## Half a second of gated, high-passed crackle with a short falling zap: the Records exit arc.
static func _arc(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var gate: PackedByteArray = PackedByteArray()
	gate.resize(frames)
	var cursor: int = 0
	while cursor < frames:
		cursor += int(rng.randf_range(0.004, 0.03) * MIX_RATE)
		var open_until: int = mini(cursor + int(rng.randf_range(0.006, 0.018) * MIX_RATE), frames)
		while cursor < open_until:
			gate[cursor] = 1
			cursor += 1
	var alpha: float = dt / (1.0 / (TAU * 1200.0) + dt)
	var low: float = 0.0
	var phase: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		var noise: float = rng.randf_range(-1.0, 1.0)
		low += alpha * (noise - low)
		var sample: float = (noise - low) * float(gate[i]) * exp(-t / 0.12)
		if t < 0.06:
			phase += TAU * lerpf(2400.0, 500.0, t / 0.06) * dt
			sample += sin(phase) * 0.6 * exp(-t / 0.02)
		out[i] = sample * minf(t / 0.003, 1.0)
	return out


## Three 120 ms square chirps at 880 Hz, 40 ms apart, low-passed so they bark instead of buzz:
## the seal-charged warning.
static func _klaxon(seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var alpha: float = dt / (1.0 / (TAU * 2500.0) + dt)
	var low: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		var cycle: float = fmod(t, 0.16)
		var gate: float = 1.0 if t < 0.48 and cycle < 0.12 else 0.0
		var square: float = 1.0 if fmod(t * 880.0, 1.0) < 0.5 else -1.0
		# A short attack and release on every chirp so none of them clicks.
		var envelope: float = minf(cycle / 0.004, 1.0) * minf((0.12 - cycle) / 0.008, 1.0) if gate > 0.0 else 0.0
		low += alpha * (square * envelope - low)
		out[i] = low
	return out


## A 70 Hz saw with a 9 Hz tremolo under breathy noise, swelling in and dying away: WOLF's growl.
static func _growl(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var alpha: float = dt / (1.0 / (TAU * 900.0) + dt)
	var low: float = 0.0
	var phase: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		phase += TAU * (70.0 - 12.0 * t / seconds) * dt
		var saw: float = fmod(phase / TAU, 1.0) * 2.0 - 1.0
		low += alpha * (saw + rng.randf_range(-0.35, 0.35) - low)
		var tremolo: float = 0.7 + 0.3 * sin(TAU * 9.0 * t)
		var envelope: float = minf(t / 0.08, 1.0) * minf((seconds - t) / 0.2, 1.0)
		out[i] = low * tremolo * envelope
	return out


## A thin 1.2 kHz servo tone with a 6 Hz vibrato and a soft octave, looped: the sentry's motors.
## The vibrato and both tones complete whole cycles in one second, so the loop seam is silent; the
## room raises its pitch when the sentry locks on and lets it fall away when the sentry goes down.
static func _servo(seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	for i: int in frames:
		var t: float = i * dt
		# Phase of a 1200 Hz carrier swung +/-30 Hz at 6 Hz, integrated so it stays continuous.
		var phase: float = TAU * 1200.0 * t + (30.0 / 6.0) * sin(TAU * 6.0 * t)
		out[i] = sin(phase) * 0.7 + sin(phase * 0.5) * 0.3
	return out


## A 90 Hz saw with a 7 Hz wobble, low-passed, looped: the arm's winch hauling the tank back up.
static func _winch(seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var alpha: float = dt / (1.0 / (TAU * 700.0) + dt)
	var low: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		var saw: float = fmod(t * 90.0, 1.0) * 2.0 - 1.0
		low += alpha * (saw - low)
		out[i] = low * (0.75 + 0.25 * sin(TAU * 7.0 * t))
	return out


## A rising electrical whine (a sine sweeping 300 Hz to 1.8 kHz with a buzzing square edge) that
## swells over 0.6 s and cuts off: the exit bolt charging before it arcs.
static func _whine(rng: RandomNumberGenerator, seconds: float) -> PackedFloat32Array:
	var frames: int = int(seconds * MIX_RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(frames)
	var dt: float = 1.0 / MIX_RATE
	var phase: float = 0.0
	for i: int in frames:
		var t: float = i * dt
		var progress: float = t / seconds
		phase += TAU * lerpf(300.0, 1800.0, progress * progress) * dt
		var tone: float = sin(phase) * 0.7 + (1.0 if sin(phase * 0.5) > 0.0 else -1.0) * 0.15
		var envelope: float = minf(t / 0.02, 1.0) * lerpf(0.3, 1.0, progress) * minf((seconds - t) / 0.01, 1.0)
		out[i] = (tone + rng.randf_range(-0.08, 0.08)) * envelope
	return out


## Normalises to PEAK and packs little-endian signed 16-bit mono.
static func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var peak: float = 0.0
	for sample: float in samples:
		if not is_finite(sample):
			push_error("SfxBank produced a non-finite sample")
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


## The loudest sample of a generated clip as a 0..1 fraction, for tests and tuning.
static func peak_of(wav: AudioStreamWAV) -> float:
	var peak: int = 0
	var data: PackedByteArray = wav.data
	for i: int in range(0, data.size(), 2):
		peak = maxi(peak, absi(data.decode_s16(i)))
	return float(peak) / 32767.0
