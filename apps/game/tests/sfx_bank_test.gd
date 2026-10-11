extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
## The recorded clips: 16-bit mono 44.1 kHz WAV imports, and their lengths in seconds.
const RECORDED_SECONDS: Dictionary = {
	&"hiss_low": 6.0,
	&"hiss_mid": 6.0,
	&"hiss_high": 6.0,
	&"coolant_cloud": 8.0,
	&"vent_burst": 2.4,
	&"growl_seam": 0.9,
	&"growl_refusal": 0.92,
}

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", "user://sfx-bank-test-%s.json" % OS.get_process_id())
	game.set("settings_path", "user://sfx-bank-test-%s.cfg" % OS.get_process_id())
	root.add_child(game)
	var bank: SfxBank = game.get("sfx_bank") as SfxBank
	if bank == null:
		_expect(false, "Main builds the sound bank")
		quit(1)
		return
	_expect(AudioServer.get_bus_index(SfxBank.BUS) >= 0, "the Effects bus exists once Settings has configured the mixer")
	for player: AudioStreamPlayer in bank.players():
		_expect(player.bus == SfxBank.BUS, "%s plays on the Effects bus so the Audio sliders apply" % player.name)
	print("SfxBank startup generation took %.1f ms" % bank.generation_ms)
	# The spec budget is about 50 ms for what renders on the main thread at startup; it measures near
	# 30 ms on the development Mac. Wall-clock time varies with the runner, so this loose bound only
	# catches a recipe that balloons; the length and determinism checks below are the real gate.
	_expect(bank.generation_ms < 400.0, "the startup clips render inside the startup budget (took %.1f ms)" % bank.generation_ms)
	# The detailed clips render on a worker thread; the startup clips and recordings are there at once.
	for clip: StringName in SfxBank.LENGTHS:
		_expect(bank.streams.has(clip), "%s is ready at startup" % clip)
	for clip: StringName in SfxBank.RECORDED:
		_expect(bank.streams.has(clip), "%s is ready at startup" % clip)
	var detail_start: int = Time.get_ticks_usec()
	bank.wait_for_detail()
	print("SfxBank detailed clips were ready %.1f ms later" % (float(Time.get_ticks_usec() - detail_start) / 1000.0))
	var expected_clips: int = SfxBank.LENGTHS.size() + SfxBank.DETAILED.size() + SfxBank.RECORDED.size()
	_expect(bank.streams.size() == expected_clips, "the bank holds exactly the startup, detailed and recorded clips (%d)" % bank.streams.size())
	_check_generated(bank, SfxBank.LENGTHS, SfxBank.MIX_RATE)
	_check_generated(bank, SfxBank.DETAILED, SfxBank.DETAIL_RATE)
	_check_recorded(bank)
	for clip: StringName in SfxBank.LOOPS:
		_expect(bank.streams.has(clip), "loop %s is a known clip" % clip)
	for clip: StringName in SfxBank.HISS_GAUGE:
		_expect((bank.streams[clip] as AudioStreamWAV).data.size() == (bank.streams[SfxBank.HISS_GAUGE[0]] as AudioStreamWAV).data.size(), "%s shares the gauge set's length, so the set loops in step" % clip)
	_expect(float(SfxBank.ARC_PLANS[&"bolt_arc"]["crack_at"]) == SfxBank.BOLT_CRACK_SECONDS and SfxBank.BOLT_CRACK_SECONDS < float(game.get_script().get_script_constant_map()["BOLT_WHINE_SECONDS"]), "the bolt arc's build fits inside the whine")
	var bolt_plan: Dictionary = SfxBank.ARC_PLANS[&"bolt_arc"]
	var records_plan: Dictionary = SfxBank.ARC_PLANS[&"records_arc"]
	_expect(bool(bolt_plan.get("long_ring", false)) and float(bolt_plan.get("ring_send", SfxBank.RING_SEND)) == 0.8 and float(bolt_plan["drive"]) == 3.0, "the bolt arc keeps the housing ring and drive of the clip that was auditioned")
	_expect(not records_plan.get("long_ring", false) and float(records_plan.get("ring_send", SfxBank.RING_SEND)) == 0.4, "the Records exit keeps the refined short housing ring")
	# Same seeds, same bytes: a second bank rendered on this thread is identical, so the worker thread
	# changes nothing either.
	var again: SfxBank = SfxBank.new()
	again.generate()
	for clip: StringName in SfxBank.LENGTHS.keys() + SfxBank.DETAILED.keys():
		_expect((again.streams[clip] as AudioStreamWAV).data == (bank.streams[clip] as AudioStreamWAV).data, "%s is deterministic" % clip)
	again.free()
	var voice: AudioStreamPlayer = bank.play(&"clank", -3.0, 1.1)
	_expect(voice != null and voice.playing and voice.stream == bank.streams[&"clank"] and voice.volume_db == -3.0 and is_equal_approx(voice.pitch_scale, 1.1), "play() starts a voice with the requested clip, volume and pitch")
	var loop: AudioStreamPlayer = bank.play(&"hum", -10.0)
	var loop_again: AudioStreamPlayer = bank.play(&"hum", -4.0)
	_expect(loop != null and loop == loop_again and loop.playing and loop.volume_db == -4.0, "a loop keeps its own player and a second play only retunes it")
	bank.stop(&"hum")
	_expect(not loop.playing, "stop() ends a loop by name")
	_expect(bank.play(&"nothing") == null, "unknown clips are ignored")
	_check_blend(bank)
	# The visual-effects switch leaves sound alone: what is playing keeps playing and new clips start.
	var hiss: AudioStreamPlayer = bank.play(&"coolant_cloud", -10.0)
	var boom: AudioStreamPlayer = bank.play(&"boom")
	_expect(hiss != null and hiss.playing and boom != null and boom.playing, "a loop and a one-shot are sounding before the effects switch goes off")
	game.set("effects_enabled", false)
	_expect(not (game.get("impact") as Impact).enabled, "the effects switch turns the impact kit off")
	_expect(hiss.playing and boom.playing, "switching visual effects off does not stop loops or one-shots already playing")
	var during: AudioStreamPlayer = bank.play(&"thud")
	_expect(during != null and during.playing, "with visual effects off the bank still plays")
	game.set("effects_enabled", true)
	bank.stop_all()
	_expect(not hiss.playing and not boom.playing and not during.playing, "stop_all() silences every player")
	game.queue_free()
	# The mixer thread releases a stopped clip's playback (and with it the clip) some mix steps later;
	# quitting sooner leaks them at exit, which check-game.sh treats as a failure. 0.1 s was not
	# always enough on the headless dummy driver.
	await create_timer(0.5).timeout
	if failures == 0:
		print("SfxBank checks passed")
	quit(1 if failures > 0 else 0)


## Every generated clip in [param lengths] is 16-bit mono at [param rate], the planned length,
## peaks at -6 dB and loops only if it is one of the loops.
func _check_generated(bank: SfxBank, lengths: Dictionary, rate: int) -> void:
	for clip: StringName in lengths:
		var wav: AudioStreamWAV = bank.streams.get(clip) as AudioStreamWAV
		if wav == null:
			_expect(false, "%s is generated" % clip)
			continue
		var frames: int = wav.data.size() / 2
		var expected: int = int(float(lengths[clip]) * rate)
		_expect(frames == expected, "%s is %d frames (%.2f s at %d Hz)" % [clip, expected, lengths[clip], rate])
		_expect(wav.format == AudioStreamWAV.FORMAT_16_BITS and wav.mix_rate == rate and not wav.stereo, "%s is 16-bit mono at %d Hz" % [clip, rate])
		var peak: float = SfxBank.peak_of(wav)
		_expect(peak <= SfxBank.PEAK + 0.001 and peak >= SfxBank.PEAK - 0.02, "%s peaks at -6 dB (%.3f)" % [clip, peak])
		var looping: bool = wav.loop_mode == AudioStreamWAV.LOOP_FORWARD
		_expect(looping == (clip in SfxBank.LOOPS), "%s loop flag matches its role" % clip)
		if looping:
			_expect(wav.loop_begin == 0 and wav.loop_end == frames, "%s loops over its whole buffer" % clip)


## The recordings import as uncompressed 16-bit mono 44.1 kHz at a -6 dB peak; the loops wrap over
## their whole buffer and the one-shots do not loop.
func _check_recorded(bank: SfxBank) -> void:
	_expect(RECORDED_SECONDS.size() == SfxBank.RECORDED.size(), "every recorded clip is checked here")
	for clip: StringName in SfxBank.RECORDED:
		var wav: AudioStreamWAV = bank.streams.get(clip) as AudioStreamWAV
		if not _expect(wav != null, "%s loads as an AudioStreamWAV" % clip):
			continue
		var frames: int = wav.data.size() / 2
		_expect(wav.format == AudioStreamWAV.FORMAT_16_BITS and wav.mix_rate == 44100 and not wav.stereo, "%s imports as uncompressed 16-bit mono at 44.1 kHz" % clip)
		_expect(frames == roundi(float(RECORDED_SECONDS.get(clip, 0.0)) * 44100.0), "%s is %.2f s long" % [clip, RECORDED_SECONDS.get(clip, 0.0)])
		var peak: float = SfxBank.peak_of(wav)
		_expect(peak <= SfxBank.PEAK + 0.002 and peak >= SfxBank.PEAK - 0.02, "%s peaks at -6 dB (%.3f)" % [clip, peak])
		var looping: bool = wav.loop_mode == AudioStreamWAV.LOOP_FORWARD
		_expect(looping == (clip in SfxBank.LOOPS), "%s loop flag matches its role" % clip)
		if looping:
			_expect(wav.loop_begin == 0 and wav.loop_end == frames, "%s loops over its whole buffer (%d..%d of %d)" % [clip, wav.loop_begin, wav.loop_end, frames])


## play_blend runs the gauge set in step and crossfades with equal power.
func _check_blend(bank: SfxBank) -> void:
	var players: Array[AudioStreamPlayer] = []
	bank.play_blend(SfxBank.HISS_GAUGE, 0.0, -10.0)
	for clip: StringName in SfxBank.HISS_GAUGE:
		for player: AudioStreamPlayer in bank.players():
			if player.stream == bank.streams[clip]:
				players.append(player)
	if not _expect(players.size() == 3 and players[0].playing and players[1].playing and players[2].playing, "play_blend starts every loop of the gauge set"):
		return
	_expect(is_equal_approx(players[0].volume_db, -10.0) and players[1].volume_db <= -79.0 and players[2].volume_db <= -79.0, "at the bottom of the gauge only the low loop is heard")
	bank.play_blend(SfxBank.HISS_GAUGE, 0.25, -10.0)
	_expect(absf(players[0].volume_db + 13.01) < 0.05 and absf(players[1].volume_db + 13.01) < 0.05 and players[2].volume_db <= -79.0, "a quarter up the gauge, low and mid share it at -3 dB each (equal power)")
	bank.play_blend(SfxBank.HISS_GAUGE, 0.5, -6.0)
	_expect(is_equal_approx(players[1].volume_db, -6.0) and players[0].volume_db <= -79.0 and players[2].volume_db <= -79.0, "at mid gauge only the mid loop is heard, at the new level")
	bank.play_blend(SfxBank.HISS_GAUGE, 1.0, -6.0)
	_expect(is_equal_approx(players[2].volume_db, -6.0) and players[1].volume_db <= -79.0, "at the top only the high loop is heard")
	_expect(players[0].playing and players[1].playing and players[2].playing, "retuning keeps every loop of the set running")
	bank.stop(SfxBank.HISS_GAUGE[1])
	bank.play_blend(SfxBank.HISS_GAUGE, 0.5, -6.0)
	_expect(players[0].playing and players[1].playing and players[2].playing, "if one loop stopped, the set restarts together")
	bank.stop_each(SfxBank.HISS_GAUGE)
	_expect(not players[0].playing and not players[1].playing and not players[2].playing, "stop_each() ends the whole set")


func _expect(condition: bool, label: String) -> bool:
	if not condition:
		failures += 1
		push_error("SfxBank check failed: " + label)
	return condition
