extends SceneTree
func _init() -> void:
	var B = load("res://blast_leaf.gd")
	for o: float in [0.0, 0.55, 0.7, 0.85, 1.0]:
		var lead: float = B.lead_at(o)
		print("o=%.2f lead=%.5f foot=%s head=%s edge_light=%.4f light(0.0,1.0)=%.4f" % [o, lead, B.project(lead, 0.0, 0.22), B.project(lead, 3.05, 0.22), B.edge_light(lead), B.light_at(0.0, 1.0)])
	quit()
