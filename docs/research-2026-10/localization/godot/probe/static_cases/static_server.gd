extends RefCounted
## Case: TranslationServer.translate() inside a static function (expected: works).
static func line() -> String:
	return TranslationServer.translate("HELLO")
