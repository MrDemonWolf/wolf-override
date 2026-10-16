extends SceneTree
## Static/const tr() probe (step research-godot): loads each case in res://static_cases/ and reports
## whether it compiles and, where it does, what it returns with the Spanish fixture loaded.
## Contract: `godot --headless --path <probe> --script res://probe_static.gd`; errors print to the log.
func _initialize() -> void:
	TranslationServer.add_translation(load("res://po/es.po"))
	TranslationServer.set_locale("es")
	for case: String in ["static_tr", "const_tr", "static_server", "static_named_tr"]:
		var script: GDScript = load("res://static_cases/%s.gd" % case)
		var ok: bool = script != null and script.can_instantiate()
		var value: String = str(script.call("line")) if ok and script.has_method("line") else ("(tr) " + str(script.call("tr", "HELLO")) if ok and case == "static_named_tr" else "-")
		print("RESULT %s compiles=%s value=%s" % [case, ok, value])
	quit(0)
