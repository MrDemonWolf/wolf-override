extends SceneTree
## FxKit: the rooms' glows, shafts, haze, shadows and particle textures and ramps (the blast door's
## streaks, chips and dust jets among them) share one resource per distinct gradient, ramp and blend
## while Main is up; nothing writes to a shared
## resource after it is made (the game plays through effects and motion switches, bursts, the blast
## and a scene sync, and every one still matches what it was made as); and the kit lets go of all of
## it when Main leaves. Without a kit every call makes a fresh resource, as before.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_without_kit()
	await _check_scene()
	if failures == 0:
		print("FxKit checks passed")
	quit(1 if failures > 0 else 0)


func _check_without_kit() -> void:
	_expect(FxKit.cached_count() == 0, "with no Main up there is no kit and nothing cached")
	var first: GradientTexture2D = _glow_texture()
	var second: GradientTexture2D = _glow_texture()
	_expect(first != second and first.width == 128 and first.fill == GradientTexture2D.FILL_RADIAL, "without a kit every call makes a fresh texture")
	_expect(FxKit.additive() != FxKit.additive(), "without a kit every call makes a fresh material")
	_expect(FxKit.cached_count() == 0, "and none of it is kept")


func _check_scene() -> void:
	var path: String = "user://fx-kit-test-%s.json" % OS.get_process_id()
	_remove(path)
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await process_frame
	var kit: FxKit = game.get("fx_kit") as FxKit
	_expect(kit != null and FxKit.cached_count() > 0 and kit._cache.size() == FxKit.cached_count(), "Main's kit is the open one, and the rooms built from it")
	var records: RecordsRoom = game.get("records_room") as RecordsRoom
	var junction: JunctionRoom = game.get("junction_room") as JunctionRoom
	var corridor: RoomDepth = game.get_node("CorridorDepth") as RoomDepth
	# Every glow in the game draws the one glow texture with the one additive blend.
	var glows: Array[Sprite2D] = [corridor.lamp_glows[0], records.purge_glow, records.mirror_glow, junction.breaker_glow, junction.vent_glow, junction.door_lamp.halo, junction.sentry.visual.lens_glow, (game.get("seal_lamp") as DoorKit.Lamp).halo, game.get("breaker_status_glow") as Sprite2D]
	var glow_texture: GradientTexture2D = _glow_texture()
	for glow: Sprite2D in glows:
		_expect(glow.texture == glow_texture and glow.material == FxKit.additive(), "%s shares the kit's glow texture and additive blend" % glow.name)
	_expect(junction.vent_steam.texture == junction.coolant_cloud.texture and junction.vent_steam.color_ramp == (game.get("relay_sparks") as CPUParticles2D).color_ramp, "particles of one preset share their dot texture, and every preset its fade ramp")
	# The doors' particles: both streak showers (the blast's and the bolt's) share one streak texture and
	# ramp, the blast's dust jet and the landing's share the presets' dot texture, and the thrown chips'
	# texture and ramp are the kit's too.
	_expect(junction.blast_sparks.texture == junction.bolt_sparks.texture and junction.blast_sparks.color_ramp == junction.bolt_sparks.color_ramp, "the blast's and the bolt's streaks share one texture and ramp")
	_expect(junction.landing_dust.texture == junction.vent_steam.texture and junction.landing_dust.color_ramp == junction.vent_steam.color_ramp, "the dust jets share the presets' dot texture and fade ramp")
	_expect(kit._cache.values().has(junction.blast_debris.texture) and kit._cache.values().has(junction.blast_debris.color_ramp), "the thrown chips' texture and ramp come from the kit")
	# Everything generated on screen is one of the kit's: count the distinct ones.
	var shared: Array[Resource] = []
	var stray: Array[String] = []
	for node: Node in game.find_children("*", "", true, false):
		var used: Array[Resource] = []
		if node is Sprite2D:
			used.append((node as Sprite2D).texture)
		if node is CPUParticles2D:
			used.append((node as CPUParticles2D).texture)
			used.append((node as CPUParticles2D).color_ramp)
		if node is CanvasItem and (node as CanvasItem).material is CanvasItemMaterial:
			used.append((node as CanvasItem).material)
		for resource: Resource in used:
			if not (resource is GradientTexture2D or resource is Gradient or resource is CanvasItemMaterial):
				continue
			if not kit._cache.values().has(resource):
				stray.append("%s %s" % [node.name, resource.get_class()])
			elif not shared.has(resource):
				shared.append(resource)
	_expect(stray.is_empty(), "every generated texture, ramp and blend in the scene is the kit's (not: %s)" % ", ".join(stray))
	# (18 since art swap PR 3: the blown doorway's soot texture and its multiply blend.)
	_expect(shared.size() >= 8 and FxKit.cached_count() <= 18, "a handful of shared resources stand in for one per sprite (%d in use, %d cached)" % [shared.size(), FxKit.cached_count()])
	var made: Dictionary = _describe_all(kit)
	# Play through what moves the light: effects and Reduced Motion both ways, bursts, the blast, the
	# hatch, a knockdown restore and a scene sync, with frames between.
	game.call("debug_new_game", true)
	for frame: int in 5:
		await process_frame
	for effects: bool in [false, true]:
		game.set("effects_enabled", effects)
		game.call("_apply_effects")
		game.call("_on_reduced_motion_changed", not effects)
		await process_frame
	junction.visible = true
	records.visible = true
	junction.vent_blows()
	junction.door_blast()
	junction.tank_hit(DropArm.MARK_X)
	junction.bolt_arc()
	records.refresh_state()
	for frame: int in 30:
		await process_frame
	junction.reset_transient()
	game.call("_sync_scene")
	await process_frame
	var after: Dictionary = _describe_all(kit)
	var changed: Array[String] = []
	for key: Variant in made:
		if after.get(key) != made[key]:
			changed.append(str(key))
	_expect(changed.is_empty() and after.size() == made.size(), "nothing writes to a shared resource after it is made (changed: %s)" % ", ".join(changed))
	_remove(path)
	_remove("%s-settings.cfg" % path)
	game.call("_stop_junction_loops")
	game.queue_free()
	await create_timer(0.2).timeout
	_expect(FxKit.cached_count() == 0, "the kit lets go of every shared resource when Main leaves")


## The glow every room draws (RoomDepth.make_glow).
func _glow_texture() -> GradientTexture2D:
	return FxKit.radial(128, [0.0, 0.4, 1.0], [Color.WHITE, Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)])


## What each cached resource was made as: its gradient, size, fill and blend.
func _describe_all(kit: FxKit) -> Dictionary:
	var described: Dictionary = {}
	for key: Variant in kit._cache:
		described[key] = _describe(kit._cache[key] as Resource)
	return described


func _describe(resource: Resource) -> Array:
	if resource is GradientTexture2D:
		var texture: GradientTexture2D = resource as GradientTexture2D
		return [texture.width, texture.height, texture.fill, texture.fill_from, texture.fill_to, texture.repeat, texture.use_hdr, _describe(texture.gradient)]
	if resource is Gradient:
		var gradient: Gradient = resource as Gradient
		return [gradient.offsets, gradient.colors, gradient.interpolation_mode, gradient.interpolation_color_space]
	if resource is CanvasItemMaterial:
		var material: CanvasItemMaterial = resource as CanvasItemMaterial
		return [material.blend_mode, material.light_mode, material.particles_animation]
	return [resource.get_class()]


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FxKit check failed: " + label)
