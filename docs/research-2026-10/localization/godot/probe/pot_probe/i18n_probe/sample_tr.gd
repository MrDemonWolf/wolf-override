extends Node
## Scratch-only extraction sample (step research-godot): one of each way the game could mark text, to
## see which ones Godot 4.7.2's built-in POT generator picks up. Never part of the game.

const PLAIN_CONST: String = "A const nobody wraps in tr()."
const WRAPPED_CONST: String = "A const wrapped at its use site."
## Format templates stay whole so translators can move the placeholder.
const FORMAT_CONST: String = "The handle holds where %s left it."


func lines(label: Label, name: String, count: int) -> Array[String]:
	var out: Array[String] = []
	out.append(tr("A literal in tr()."))
	out.append(tr(WRAPPED_CONST))
	out.append(tr(FORMAT_CONST) % name)
	out.append(tr("{name} keeps WOLF's systems running.").format({"name": name}))
	out.append(tr("Open", "verb"))
	out.append(tr_n("%d valve left", "%d valves left", count) % count)
	out.append(atr("A literal in atr()."))
	# TRANSLATORS: Shown on the pause card; keep it under 20 characters.
	out.append(tr("A literal with a translator note."))
	out.append(tr("NOT FOR TRANSLATION")) # NO_TRANSLATE
	out.append(TranslationServer.translate("A literal through TranslationServer.translate()."))
	out.append(tr("Hello %s" % name))
	label.text = "A literal assigned to .text"
	label.tooltip_text = "A literal assigned to .tooltip_text"
	return out
