extends SceneTree
## Capture the configured startup scene to /work/out/smoke.png in the container.
## See README.md for the render.sh command and host output directory.

## Wait three frames so the scene enters the tree and draws before capture.
const SETTLE_FRAMES: int = 3
var _frame: int = 0


## Load the same scene as a normal game launch.
func _initialize() -> void:
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	if change_scene_to_file(scene) != OK:
		push_error("Could not open startup scene: " + scene)
		quit(1)


## Save the rendered viewport after startup. Report missing pixels or write failure.
func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == SETTLE_FRAMES:
		var image: Image = root.get_texture().get_image()
		if image == null or image.save_png("/work/out/smoke.png") != OK:
			push_error("Could not write /work/out/smoke.png")
			quit(1)
		else:
			quit()
	return false
