extends SfxBank
## Parity only (never shipped): the sound bank with every play, play_blend and stop call logged by
## frame, so a refactor step can show that the game asks for the same sounds at the same moments.
## capture.gd swaps it onto Main's SfxBank as the node enters the tree, before the bank's _ready.

static var calls: PackedStringArray = []
static var frame: int = 0


func play(clip: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	calls.append("%d\tplay\t%s\t%.2f\t%.3f" % [frame, clip, volume_db, pitch])
	return super(clip, volume_db, pitch)


func play_blend(clips: Array[StringName], blend: float, volume_db: float) -> void:
	calls.append("%d\tblend\t%s\t%.3f\t%.2f" % [frame, ",".join(clips), blend, volume_db])
	super(clips, blend, volume_db)


func stop(clip: StringName) -> void:
	calls.append("%d\tstop\t%s" % [frame, clip])
	super(clip)


func stop_all() -> void:
	calls.append("%d\tstop_all" % frame)
	super()
