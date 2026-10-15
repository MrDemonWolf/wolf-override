extends SceneTree
## Fix round 4 (review r4, M1): every swing leaf at every degree, through the game's own SwingLeaf (the face the
## room's camera sees, shade() at mid-leaf 1.0 m up, near the head by the hinge 2.0 m up, and low 0.4 m up),
## as the reviewer's leafswing.py sampled it. Prints the lowest level against the shut leaf's. Scratch only.
func _initialize() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var records: Node = main.get("records_room")
	var junction: Node = main.get("junction_room")
	for pair: Array in [["records exit", records.get("exit_leaf")], ["records entry", records.get("entry_leaf")], ["junction entry", junction.get("entry_leaf")]]:
		var leaf: SwingLeaf = pair[1]
		var shut: Array = _levels(leaf, 0.0)
		var low: Array = [INF, INF, INF]
		var at: Array = [0, 0, 0]
		var rows: PackedStringArray = []
		for deg: int in range(0, 91):
			var l: Array = _levels(leaf, deg_to_rad(float(deg)))
			for k: int in 3:
				if l[k] / shut[k] < low[k]:
					low[k] = l[k] / shut[k]
					at[k] = deg
			if deg % 10 == 0 or deg in [15, 25, 35]:
				rows.append("  %2d deg face=%s head %.4f mid %.4f low %.4f" % [deg, "room" if leaf.room_face_shows(deg_to_rad(float(deg))) else "out ", l[0], l[1], l[2]])
		print(pair[0])
		print("\n".join(rows))
		print("  lowest / shut: head %.2f at %d deg, mid %.2f at %d deg, low %.2f at %d deg" % [low[0], at[0], low[1], at[1], low[2], at[2]])
	quit()


func _levels(leaf: SwingLeaf, theta: float) -> Array:
	var room: bool = leaf.room_face_shows(theta)
	var n_room: Vector3 = leaf.room_normal(theta)
	var base: Vector3 = leaf.hinge if room else leaf.hinge - n_room * SwingLeaf.LEAF_T
	var nrm: Vector3 = n_room if room else -n_room
	var d: Vector3 = leaf.leaf_dir(theta)
	var out: Array = []
	for p: Vector3 in [base + d * 0.1 + Vector3(0, 2.0, 0), base + d * 0.45 + Vector3(0, 1.0, 0), base + d * 0.45 + Vector3(0, 0.4, 0)]:
		var c: Color = leaf.shade(p, nrm)
		# shade() returns sRGB(lit)/sRGB(paint); back to linear lit paint luminance
		var lit: Vector3 = Vector3(pow(c.r * _s(0.18), 2.2), pow(c.g * _s(0.195), 2.2), pow(c.b * _s(0.235), 2.2))
		out.append(0.2126 * lit.x + 0.7152 * lit.y + 0.0722 * lit.z)
	return out


func _s(v: float) -> float:
	return pow(v, 1.0 / 2.2)
