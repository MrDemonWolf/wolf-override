class_name Impact
extends Node
## The impact kit every spark, boom and knockdown routes through: camera shake, hit-stop, screen
## flash, rumble and haptics. One node under Main owns all of it, so one switch silences it and
## Engine.time_scale always comes back to 1.0, even when the game pauses in the middle of a dip.
## Shake lives on Camera2D.offset, so the camera's position clamp and smoothing are untouched.

## Peak shake at full trauma, in pixels.
const MAX_SHAKE_PX: float = 10.0
const TRAUMA_DECAY_SECONDS: float = 0.6
## How fast the shake noise is sampled, in cycles per second.
const SHAKE_RATE: float = 28.0
const HIT_STOP_SCALE: float = 0.05
const MAX_HIT_STOP_SECONDS: float = 0.1
const WHITE_FLASH_ALPHA: float = 0.55
const RED_WASH_ALPHA: float = 0.3
const RUMBLE_DEVICE: int = 0

## Off silences everything; Main ties it to effects_enabled.
var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			reset()
## Reduced Motion: no shake, no hit-stop, flashes at half length. Rumble and sound stay.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if reduce_motion:
			trauma = 0.0
			_settle_camera()
var rumble_enabled: bool = false
var haptics_enabled: bool = false
var camera: Camera2D
## The existing full-screen overlays: IntroFade carries the white flash, IntroAlarm the red wash.
var white_flash: ColorRect
var red_wash: ColorRect
## 0..1; the shake amplitude is trauma squared so small hits stay small.
var trauma: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0
## Each hit-stop takes a new serial; only the timer that matches it may restore time_scale.
var _stop_serial: int = 0
var _flash_tween: Tween
var _flash_active: bool = false
var _white_rest: Color = Color(0.0, 0.0, 0.0, 0.0)
var _red_rest: float = 0.0


func _init() -> void:
	# Shake settles and hit-stops end while the tree is paused, so nothing stays frozen off-centre.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.seed = 7
	_noise.frequency = 1.0


func setup(target_camera: Camera2D, fade: ColorRect, alarm: ColorRect) -> void:
	camera = target_camera
	white_flash = fade
	red_wash = alarm


func _exit_tree() -> void:
	reset()


## True when shake, hit-stop and knockdown motion may play.
func motion_allowed() -> bool:
	return enabled and not reduce_motion


func _process(delta: float) -> void:
	if trauma <= 0.0:
		return
	_time += delta
	trauma = maxf(trauma - delta / TRAUMA_DECAY_SECONDS, 0.0)
	if camera == null:
		return
	if trauma <= 0.0:
		camera.offset = Vector2.ZERO
		return
	var amplitude: float = trauma * trauma * MAX_SHAKE_PX
	var sample_x: float = _noise.get_noise_2d(_time * SHAKE_RATE + 0.37, 11.3)
	var sample_y: float = _noise.get_noise_2d(_time * SHAKE_RATE + 0.37, 57.9)
	camera.offset = Vector2(sample_x, sample_y) * amplitude


func add_trauma(amount: float) -> void:
	if not motion_allowed():
		return
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Dips Engine.time_scale for up to MAX_HIT_STOP_SECONDS of real time. A later call replaces the
## earlier one instead of nesting, and the restore timer runs while paused and ignores time scale.
func hit_stop(seconds: float) -> void:
	if not motion_allowed() or seconds <= 0.0 or not is_inside_tree():
		return
	Engine.time_scale = HIT_STOP_SCALE
	_stop_serial += 1
	var timer: SceneTreeTimer = get_tree().create_timer(minf(seconds, MAX_HIT_STOP_SECONDS), true, false, true)
	timer.timeout.connect(_end_hit_stop.bind(_stop_serial))


func _end_hit_stop(serial: int) -> void:
	if serial == _stop_serial:
		Engine.time_scale = 1.0


## Ends a dip early; pausing calls this so the menu never opens at 5% speed.
func end_hit_stop() -> void:
	_stop_serial += 1
	Engine.time_scale = 1.0


## A white flash on IntroFade over a red wash on IntroAlarm; either length may be 0 to skip it.
func flash(white_seconds: float, red_seconds: float) -> void:
	if not enabled or not is_inside_tree():
		return
	if reduce_motion:
		white_seconds *= 0.5
		red_seconds *= 0.5
	_end_flash()
	_flash_active = true
	_flash_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_flash_tween.set_ignore_time_scale(true)
	if white_seconds > 0.0 and white_flash != null:
		_white_rest = white_flash.color
		white_flash.color = Color(1.0, 1.0, 1.0, WHITE_FLASH_ALPHA)
		_flash_tween.tween_property(white_flash, "color:a", _white_rest.a, white_seconds)
	if red_seconds > 0.0 and red_wash != null:
		_red_rest = red_wash.color.a
		red_wash.color.a = maxf(_red_rest, RED_WASH_ALPHA)
		_flash_tween.tween_property(red_wash, "color:a", _red_rest, red_seconds)
	_flash_tween.chain().tween_callback(_end_flash)


func _end_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null
	if not _flash_active:
		return
	_flash_active = false
	if white_flash != null:
		white_flash.color = _white_rest
	if red_wash != null:
		red_wash.color.a = _red_rest


## Controller rumble when a controller is in use, handheld vibration when touch is.
func rumble(weak: float, strong: float, seconds: float) -> void:
	if not enabled:
		return
	if rumble_enabled:
		Input.start_joy_vibration(RUMBLE_DEVICE, weak, strong, seconds)
	if haptics_enabled:
		Input.vibrate_handheld(int(seconds * 1000.0), strong)


## Restarts a one-shot particle preset.
func burst(particles: CPUParticles2D) -> void:
	if enabled and particles != null:
		particles.restart()


## Guaranteed return to rest: time scale 1.0, camera centred, overlays at their rest colours.
func reset() -> void:
	_stop_serial += 1
	Engine.time_scale = 1.0
	trauma = 0.0
	_settle_camera()
	_end_flash()


func _settle_camera() -> void:
	if camera != null:
		camera.offset = Vector2.ZERO
