extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")

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
	print("SfxBank generation took %.1f ms" % bank.generation_ms)
	_expect(bank.generation_ms < 250.0, "all clips generate inside the startup budget (took %.1f ms)" % bank.generation_ms)
	for clip: StringName in SfxBank.LENGTHS:
		var wav: AudioStreamWAV = bank.streams.get(clip) as AudioStreamWAV
		if wav == null:
			_expect(false, "%s is generated" % clip)
			continue
		var frames: int = wav.data.size() / 2
		var expected: int = int(float(SfxBank.LENGTHS[clip]) * SfxBank.MIX_RATE)
		_expect(frames == expected, "%s is %d frames (%.2f s at 22.05 kHz)" % [clip, expected, SfxBank.LENGTHS[clip]])
		_expect(wav.format == AudioStreamWAV.FORMAT_16_BITS and wav.mix_rate == SfxBank.MIX_RATE and not wav.stereo, "%s is 16-bit mono at 22.05 kHz" % clip)
		var peak: float = SfxBank.peak_of(wav)
		_expect(peak <= SfxBank.PEAK + 0.001 and peak >= SfxBank.PEAK - 0.02, "%s peaks at -6 dB (%.3f)" % [clip, peak])
		var looping: bool = wav.loop_mode == AudioStreamWAV.LOOP_FORWARD
		_expect(looping == (clip in SfxBank.LOOPS), "%s loop flag matches its role" % clip)
		if looping:
			_expect(wav.loop_begin == 0 and wav.loop_end == frames, "%s loops over its whole buffer" % clip)
	# Same seed, same bytes: a second bank is identical.
	var again: SfxBank = SfxBank.new()
	again.generate()
	for clip: StringName in SfxBank.LENGTHS:
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
	bank.enabled = false
	_expect(bank.play(&"boom") == null, "a disabled bank plays nothing")
	bank.enabled = true
	game.queue_free()
	# The mixer releases a stopped clip a few steps later; give it that time before quitting.
	await create_timer(0.1).timeout
	if failures == 0:
		print("SfxBank checks passed")
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("SfxBank check failed: " + label)
