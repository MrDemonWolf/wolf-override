class_name Tweens
extends RefCounted
## The one way a tween that is about to be replaced or cancelled is stopped. It checks is_valid():
## nothing in the game pauses or stops a tween, so a valid tween is a running one and the old
## is_running() guards stopped the same tweens.


## Stops [param tween] if it is still live; a null or finished tween is left alone.
static func kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


## Stops [param tween] and returns a new tween made on [param owner] (bound to it, so it pauses and
## ends with it).
static func restart(owner: Node, tween: Tween) -> Tween:
	kill(tween)
	return owner.create_tween()
