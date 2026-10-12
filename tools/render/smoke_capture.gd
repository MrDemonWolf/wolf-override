extends SceneTree
## Smoke test for the render container: opens the game's main scene, lets it run for a few
## seconds and saves the frame to /work/out/smoke.png, then quits.
##   mkdir -p /tmp/smoke-driver && cp tools/render/smoke_capture.gd /tmp/smoke-driver/
##   tools/render/render.sh --driver /tmp/smoke-driver apps/game OUT -- --resolution 1280x720 --script res://review_capture/smoke_capture.gd

const FRAMES: int = 150
var _frame: int = 0


func _initialize() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == FRAMES:
		var image: Image = root.get_texture().get_image()
		image.save_png("/work/out/smoke.png")
		print("smoke capture saved: %dx%d" % [image.get_width(), image.get_height()])
		return true
	return false
