extends RefCounted
## Case: a class's own static helper named tr_static, and an attempt to declare a static func named tr.
static func tr(message: String) -> String:
	return TranslationServer.translate(message)
