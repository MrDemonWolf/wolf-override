extends RefCounted
## Case: tr() inside a static function (expected: analyzer error, no self in a static context).
static func line() -> String:
	return tr("HELLO")
